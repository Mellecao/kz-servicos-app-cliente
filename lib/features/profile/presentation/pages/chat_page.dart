import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;

  const ChatPage({super.key, required this.conversationId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  RealtimeChannel? _channel;
  RealtimeChannel? _tripChannel;
  String? _tripId;
  String _chatTitle = 'Chat';
  String? _tripDetails;

  static const _presetMessages = [
    'Estou chegando',
    'Vou me atrasar',
    'Pode confirmar o endereço?',
    'Obrigado(a)!',
  ];

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadConversationDetails();
    _loadMessages();
    _markMessagesRead();
    _subscribeToMessages();
    _subscribeToTripCancellation();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _tripChannel?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversationDetails() async {
    try {
      final room = await _supabase
          .from('chat_rooms')
          .select('trip_id')
          .eq('id', widget.conversationId)
          .maybeSingle();
      final tripId = room?['trip_id'] as String?;
      if (tripId == null || tripId.isEmpty) return;

      final trip = await _supabase
          .from('trips')
          .select(
            'pickup:addresses!pickup_address_id(formatted_address),'
            'dropoff:addresses!dropoff_address_id(formatted_address)',
          )
          .eq('id', tripId)
          .maybeSingle();
      final pickup =
          trip?['pickup']?['formatted_address'] as String? ?? 'Origem';
      final dropoff =
          trip?['dropoff']?['formatted_address'] as String? ?? 'Destino';
      if (!mounted) return;
      setState(() {
        _tripId = tripId;
        _chatTitle = 'Chat da corrida';
        _tripDetails = '$pickup → $dropoff';
      });
    } catch (_) {}
  }

  Future<void> _subscribeToTripCancellation() async {
    var tripId = _tripId ?? widget.conversationId;
    try {
      final room = await _supabase
          .from('chat_rooms')
          .select('trip_id')
          .eq('id', widget.conversationId)
          .maybeSingle();
      tripId = room?['trip_id'] as String? ?? tripId;
    } catch (_) {}

    if (!mounted || tripId.isEmpty) return;
    _tripChannel = _supabase
        .channel('chat-trip-cancel-$tripId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trips',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: tripId,
          ),
          callback: (payload) {
            if (payload.eventType == PostgresChangeEvent.delete ||
                payload.newRecord['status'] == 'cancelled') {
              _handleRemoteCancellation();
            }
          },
        )
        .subscribe();
  }

  void _handleRemoteCancellation() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Esta corrida foi cancelada pela KZ.')),
    );
    context.go('/trip');
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/messages');
  }

  Future<void> _loadMessages() async {
    try {
      final data = await _supabase
          .from('chat_messages')
          .select('id, sender_id, message, created_at')
          .eq('chat_room_id', widget.conversationId)
          .order('created_at', ascending: true);
      if (!mounted) return;
      setState(() {
        _messages = List<Map<String, dynamic>>.from(data as List);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markMessagesRead() async {
    if (_currentUserId.isEmpty) return;
    try {
      await _supabase
          .from('chat_messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('chat_room_id', widget.conversationId)
          .neq('sender_id', _currentUserId)
          .eq('is_read', false);
    } catch (_) {}
  }

  void _subscribeToMessages() {
    _channel = _supabase
        .channel('chat-${widget.conversationId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_room_id',
            value: widget.conversationId,
          ),
          callback: (payload) {
            if (!mounted) return;
            final newMsg = payload.newRecord;
            // avoid duplicates if we inserted it ourselves
            final alreadyExists = _messages.any((m) => m['id'] == newMsg['id']);
            if (alreadyExists) return;
            setState(() => _messages.add(Map<String, dynamic>.from(newMsg)));
            if (newMsg['sender_id'] != _currentUserId) {
              unawaited(_markMessagesRead());
            }
            _scrollToBottom();
          },
        )
        .subscribe();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _messageController.clear();
    try {
      await _supabase.from('chat_messages').insert({
        'chat_room_id': widget.conversationId,
        'sender_id': _currentUserId,
        'message': text.trim(),
        'message_type': 'text',
      });
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: _goBack,
        ),
        title: Text(
          _chatTitle,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          if (_tripDetails != null) _TripDetailsHeader(details: _tripDetails!),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhuma mensagem ainda.\nEnvie a primeira!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black45, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender_id'] == _currentUserId;
                      return _MessageBubble(
                        text: msg['message'] as String? ?? '',
                        isMe: isMe,
                      );
                    },
                  ),
          ),
          _buildPresetMessages(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildPresetMessages() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: _presetMessages.map((msg) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _sendMessage(msg),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.highlight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.highlight.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  msg,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.highlight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding + 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Digite uma mensagem...',
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_messageController.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.highlight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripDetailsHeader extends StatelessWidget {
  final String details;

  const _TripDetailsHeader({required this.details});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.highlight.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.highlight.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.route_rounded,
              color: AppColors.highlight,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              details,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;

  const _MessageBubble({required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.highlight : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isMe ? Colors.white : Colors.black87,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

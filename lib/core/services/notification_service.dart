import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _NotificationHelper.showLocalNotification(message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'kz_trip_channel';
  static const _channelName = 'Viagens KZ';

  Future<void> initialize({
    required SupabaseClient client,
    String? userId,
  }) async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _setupLocalNotifications();
    await _requestPermissions();
    await _listenForeground();

    if (userId != null) {
      await _saveTokenToSupabase(client: client, userId: userId);
      _fcm.onTokenRefresh.listen((token) {
        _saveTokenToSupabase(client: client, userId: userId, token: token);
      });
    }

    client.auth.onAuthStateChange.listen((event) {
      final signedUserId = event.session?.user.id;
      if (signedUserId == null) return;
      _saveTokenToSupabase(client: client, userId: signedUserId);
    });
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: darwinInit),
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Atualizações de viagens e serviços',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _listenForeground() async {
    FirebaseMessaging.onMessage.listen((message) {
      _NotificationHelper.showLocalNotification(message);
    });
  }

  Future<void> _saveTokenToSupabase({
    required SupabaseClient client,
    required String userId,
    String? token,
  }) async {
    try {
      final fcmToken = token ?? await _fcm.getToken();
      if (fcmToken == null) return;
      await client
          .from('users')
          .update({
            'fcm_token': fcmToken,
            'fcm_token_updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);
    } on Exception catch (e) {
      debugPrint('[NotificationService] Token save failed: $e');
    }
  }
}

abstract final class _NotificationHelper {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? _titleFromData(data);
    final body = notification?.body ?? _bodyFromData(data);
    if (title == null || body == null) return;

    await _plugin.show(
      notification.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'kz_trip_channel',
          'Viagens KZ',
          channelDescription: 'Atualizações de viagens e serviços',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  static String? _titleFromData(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    return switch (type) {
      'trip_under_review' => 'Solicitação recebida',
      'searching_drivers' => 'Buscando motoristas',
      'awaiting_confirmation' => 'Motorista encontrado!',
      'trip_scheduled' => 'Viagem confirmada!',
      'trip_started' => 'Viagem iniciada!',
      'trip_finished' => 'Viagem concluída!',
      'trip_cancelled' => 'Viagem cancelada',
      'trip_rejected' => 'Solicitação recusada',
      'service_assigned' => 'Prestador encontrado!',
      'service_started' => 'Serviço iniciado!',
      'service_finished' => 'Serviço concluído!',
      'service_cancelled' => 'Serviço cancelado',
      _ => data['title'] as String?,
    };
  }

  static String? _bodyFromData(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    return switch (type) {
      'trip_under_review' => 'Sua viagem está em análise pela equipe KZ.',
      'searching_drivers' => 'Estamos procurando motoristas disponíveis.',
      'awaiting_confirmation' => 'Um motorista aceitou. Confirme a viagem no app.',
      'trip_scheduled' => 'Sua viagem está confirmada.',
      'trip_started' => 'Seu motorista iniciou a viagem.',
      'trip_finished' => 'Sua viagem foi concluída. Avalie sua experiência!',
      'trip_cancelled' => 'Sua viagem foi cancelada.',
      'trip_rejected' => 'Sua solicitação de viagem foi recusada.',
      'service_assigned' => 'Um prestador foi atribuído ao seu serviço.',
      'service_started' => 'Seu prestador iniciou o serviço.',
      'service_finished' => 'Seu serviço foi concluído com sucesso.',
      'service_cancelled' => 'Seu serviço foi cancelado.',
      _ => data['body'] as String?,
    };
  }
}

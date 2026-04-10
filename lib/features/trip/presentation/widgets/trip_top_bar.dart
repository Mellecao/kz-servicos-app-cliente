import 'package:flutter/material.dart';

class TripTopBar extends StatelessWidget {
  const TripTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: _buildChatButton(),
    );
  }

  Widget _buildChatButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.notifications_outlined,
        color: Colors.black87,
        size: 22,
      ),
    );
  }
}

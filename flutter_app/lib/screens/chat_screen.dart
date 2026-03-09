// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Chat screen placeholder — direct messaging & course circles
/// Full implementation connects to Firestore direct_chats & direct_messages collections
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Messages 💬')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.blue.withOpacity(0.2)),
              ),
              child: const Icon(Icons.forum_rounded, color: AppColors.blue, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Messages', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Chat with classmates and course circles.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text('Coming soon in the full release! 🚀', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

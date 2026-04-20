import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/session_manager.dart';
import '../models/user_notification_model.dart';

class NotificationIconButton extends StatelessWidget {
  const NotificationIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    final email = SessionManager.email;
    if (email == null || email.isEmpty) return const SizedBox.shrink();

    final stream = Supabase.instance.client
        .from('user_notifications')
        .stream(primaryKey: ['id'])
        .eq('user_email', email.trim().toLowerCase())
        .order('created_at', ascending: false);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const <Map<String, dynamic>>[];
        var unread = 0;
        for (final r in rows) {
          final n = UserNotificationModel.fromMap(Map<String, dynamic>.from(r));
          if (n.isUnread) unread++;
        }
        return IconButton(
          onPressed: () => Navigator.pushNamed(context, '/notifications'),
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 9 ? '9+' : '$unread'),
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
    );
  }
}

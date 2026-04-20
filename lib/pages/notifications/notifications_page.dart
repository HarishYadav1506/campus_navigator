import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session_manager.dart';
import '../../models/user_notification_model.dart';
import '../../services/user_notifications_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final UserNotificationsService _svc;

  @override
  void initState() {
    super.initState();
    _svc = UserNotificationsService(Supabase.instance.client);
  }

  @override
  Widget build(BuildContext context) {
    final email = SessionManager.email;
    if (email == null || email.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Sign in to see notifications.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => _svc.markAllRead(email),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _svc.streamForEmail(email),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snapshot.data!;
          if (rows.isEmpty) {
            return const Center(
              child: Text('No notifications yet.', style: TextStyle(color: Colors.white70)),
            );
          }
          final items = rows
              .map((r) => UserNotificationModel.fromMap(Map<String, dynamic>.from(r)))
              .toList();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final n = items[i];
              return Card(
                child: ListTile(
                  title: Text(n.title),
                  subtitle: n.body == null ? null : Text(n.body!),
                  trailing: n.isUnread
                      ? TextButton(
                          onPressed: () => _svc.markRead(n.id),
                          child: const Text('Read'),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

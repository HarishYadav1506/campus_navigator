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
  final _supabase = Supabase.instance.client;

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
        stream: _supabase
            .from('announcements')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, announcementSnapshot) {
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _svc.streamForEmail(email),
            builder: (context, notificationSnapshot) {
              if (!announcementSnapshot.hasData || !notificationSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final announcements = announcementSnapshot.data!;
              final rows = notificationSnapshot.data!;
              final items = rows
                  .map((r) => UserNotificationModel.fromMap(Map<String, dynamic>.from(r)))
                  .toList();

              if (announcements.isEmpty && items.isEmpty) {
                return const Center(
                  child: Text('No notifications yet.', style: TextStyle(color: Colors.white70)),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (announcements.isNotEmpty) ...[
                    const Text(
                      'Admin Announcements',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ...announcements.map((a) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.campaign_outlined),
                            title: Text((a['title'] ?? '').toString()),
                            subtitle: Text((a['body'] ?? '').toString()),
                            trailing: (a['category'] ?? '').toString().isEmpty
                                ? null
                                : Chip(label: Text((a['category'] ?? '').toString())),
                          ),
                        )),
                    const SizedBox(height: 12),
                  ],
                  if (items.isNotEmpty) ...[
                    const Text(
                      'Personal Notifications',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ...items.map((n) => Card(
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
                        )),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

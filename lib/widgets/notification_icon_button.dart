import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/session_manager.dart';
import '../models/user_notification_model.dart';

class NotificationIconButton extends StatefulWidget {
  const NotificationIconButton({super.key});

  @override
  State<NotificationIconButton> createState() => _NotificationIconButtonState();
}

class _NotificationIconButtonState extends State<NotificationIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popController;
  late final Animation<double> _scale;
  int _lastUnread = 0;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 55),
    ]).animate(CurvedAnimation(parent: _popController, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

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
        if (unread > _lastUnread) {
          _popController.forward(from: 0);
        }
        _lastUnread = unread;
        return ScaleTransition(
          scale: _scale,
          child: IconButton(
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 9 ? '9+' : '$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        );
      },
    );
  }
}

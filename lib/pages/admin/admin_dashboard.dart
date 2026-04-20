import 'package:flutter/material.dart';
import '../../core/session_manager.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final role = SessionManager.role ?? '';
    final canAccess = role == 'admin' || role == 'prof' || role == 'professor';
    if (!canAccess) {
      return const Scaffold(
        body: Center(child: Text('Admin only')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          TextButton(
            onPressed: () {
              SessionManager.clear();
              Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (role == 'admin') ...[
            _AdminTile(
              icon: Icons.campaign_outlined,
              title: 'Announcements',
              subtitle: 'Add and filter by sports/events/seminars/notices',
              onTap: () => Navigator.pushNamed(context, '/admin_announcements'),
            ),
            _AdminTile(
              icon: Icons.event_note_outlined,
              title: 'Manage events / seminars',
              subtitle: 'Add new event and seminar details',
              onTap: () => Navigator.pushNamed(context, '/admin_events'),
            ),
            _AdminTile(
              icon: Icons.person_add_alt_1_outlined,
              title: 'Manage professors',
              subtitle: 'Add new professor information',
              onTap: () => Navigator.pushNamed(context, '/admin_professors'),
            ),
            _AdminTile(
              icon: Icons.sports_soccer_outlined,
              title: 'Sports approvals',
              subtitle: 'Approve queued sports bookings',
              onTap: () => Navigator.pushNamed(context, '/admin_sports'),
            ),
            _AdminTile(
              icon: Icons.approval_outlined,
              title: 'Request approvals',
              subtitle: 'Approve or reject pending requests',
              onTap: () => Navigator.pushNamed(context, '/admin_approvals'),
            ),
            _AdminTile(
              icon: Icons.feedback_outlined,
              title: 'View feedback',
              subtitle: 'Course/app feedback with filtering',
              onTap: () => Navigator.pushNamed(context, '/admin_feedback'),
            ),
          ] else if (role == 'prof' || role == 'professor') ...[
            _AdminTile(
              icon: Icons.event_note_outlined,
              title: 'Manage events / seminars',
              subtitle: 'Add new event and seminar details',
              onTap: () => Navigator.pushNamed(context, '/admin_events'),
            ),
            _AdminTile(
              icon: Icons.person_add_alt_1_outlined,
              title: 'Update Profile',
              subtitle: 'Update your professor details',
              onTap: () => Navigator.pushNamed(context, '/admin_professors'),
            ),
          ]
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

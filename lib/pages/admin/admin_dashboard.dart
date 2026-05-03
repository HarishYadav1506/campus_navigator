import 'package:flutter/material.dart';
import '../../core/session_manager.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final role = (SessionManager.role ?? '').trim().toLowerCase();
    if (role != 'admin') {
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
            icon: Icons.monitor_heart_outlined,
            title: 'Student activity',
            subtitle: 'Monitor recent user actions',
            onTap: () => Navigator.pushNamed(context, '/admin_activity'),
          ),
          _AdminTile(
            icon: Icons.feedback_outlined,
            title: 'View feedback',
            subtitle: 'Course/app feedback with filtering',
            onTap: () => Navigator.pushNamed(context, '/admin_feedback'),
          ),
          _AdminTile(
            icon: Icons.work_outline,
            title: 'TPO postings',
            subtitle: 'Add placements and internships',
            onTap: () => Navigator.pushNamed(context, '/admin_tpo'),
          ),
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

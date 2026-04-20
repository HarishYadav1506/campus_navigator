import 'package:flutter/material.dart';
import '../../core/session_manager.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final role = SessionManager.role ?? 'student';
    final isProf = role == 'prof' || role == 'professor';
    final isStudent = role == 'student' || isProf;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Welcome, ${SessionManager.email ?? 'user'}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (isStudent) ...[
            _dashCard(context, 'Professor Slots', 'Book office slots', '/prof_slots'),
            _dashCard(context, 'TPO / Placements', 'Apply for jobs and internships', '/tpo'),
            _dashCard(context, 'Feedback', 'Course and app feedback', '/feedback'),
            _dashCard(context, 'Sports', 'Book sports facilities', '/sports'),
          ],


          if (role == 'admin') ...[
            _dashCard(context, 'Admin Panel', 'Open admin dashboard', '/admin'),
            _dashCard(context, 'TPO Admin', 'Add placements/internships', '/admin_tpo'),
            _dashCard(context, 'Activity Monitor', 'Track student activity', '/admin_activity'),
          ],
          _dashCard(context, 'Safety & Support', 'Emergency and support links', '/campus_support'),
        ],
      ),
    );
  }

  Widget _dashCard(BuildContext context, String title, String subtitle, String route) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}

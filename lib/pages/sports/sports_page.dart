import 'package:flutter/material.dart';
import '../../core/session_manager.dart';
import 'sports_status_page.dart';

class SportsPage extends StatelessWidget {
  const SportsPage({super.key});

  static const List<String> arenas = [
    "Basketball Court",
    "Football Ground",
    "Cricket Nets",
    "Badminton Hall",
    "Table Tennis Room",
  ];

  @override
  Widget build(BuildContext context) {
    final role = SessionManager.role;

    final bool canBook = SessionManager.isLoggedIn &&
        (role == 'student' || role == 'prof' || role == 'professor');

    final light = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFE8EEF5),
    );

    return Theme(
      data: light,
      child: Builder(
        builder: (context) {
          final onSurface = Theme.of(context).colorScheme.onSurface;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Sports Booking'),
              backgroundColor: Colors.white,
              foregroundColor: onSurface,
              surfaceTintColor: Colors.white,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book sports blocks',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey.shade900,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    canBook
                        ? 'Logged in as ${role ?? 'user'}. Select an arena to book for 1 hour.\nYou must reach in 10 minutes or the slot will be auto-cancelled.'
                        : 'Login as student or prof to book sports blocks.',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!canBook)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/auth');
                      },
                      child: const Text('Login to book'),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: arenas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final arena = arenas[index];
                        return Card(
                          color: Colors.white,
                          child: ListTile(
                            title: Text(
                              arena,
                              style: TextStyle(
                                color: Colors.grey.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Tap to view status and request booking',
                              style: TextStyle(color: Colors.grey.shade800),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade900,
                            ),
                            onTap: canBook
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SportsStatusPage(
                                          arenaName: arena,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


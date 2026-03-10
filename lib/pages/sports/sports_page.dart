import 'package:flutter/material.dart';
import '../../core/session_manager.dart';
import 'book_court_page.dart';

class SportsPage extends StatelessWidget {
  SportsPage({super.key});

  final List<String> arenas = const [
    "Basketball Court",
    "Football Ground",
    "Cricket Nets",
    "Badminton Hall",
    "Table Tennis Room",
  ];

  @override
  Widget build(BuildContext context) {
    final role = SessionManager.role;

    final bool canBook =
        SessionManager.isLoggedIn && (role == 'student' || role == 'prof');

    return Scaffold(
      appBar: AppBar(title: const Text('Sports Booking')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Book sports blocks",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              canBook
                  ? "Logged in as ${role ?? 'user'}. Select an arena to book for 1 hour.\nYou must reach in 10 minutes or the slot will be auto-cancelled."
                  : "Login as student or prof to book sports blocks.",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (!canBook)
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/auth');
                },
                child: const Text("Login to book"),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: arenas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final arena = arenas[index];
                  return Card(
                    child: ListTile(
                      title: Text(arena),
                      subtitle: const Text("Tap to book a 1-hour slot"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: canBook
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookCourtPage(
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
  }
}


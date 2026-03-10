import 'package:flutter/material.dart';

class EventsPage extends StatelessWidget {
  EventsPage({super.key});

  final List<_Event> events = [
    _Event(
      title: "AI Research Symposium",
      date: "12 March, 4:00 PM",
      location: "Auditorium",
      type: "Research",
    ),
    _Event(
      title: "Cyber Security Seminar",
      date: "15 March, 2:00 PM",
      location: "C-202",
      type: "Seminar",
    ),
    _Event(
      title: "BTP Poster Session",
      date: "20 March, 11:00 AM",
      location: "Innovation Lab",
      type: "Research",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Research Events & Seminars')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final e = events[index];
          return Card(
            child: ListTile(
              title: Text(e.title),
              subtitle: Text("${e.type} • ${e.date}\n${e.location}"),
              isThreeLine: true,
              trailing: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Marked as interested: ${e.title}"),
                    ),
                  );
                },
                child: const Text("Interested"),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/seminars');
        },
        icon: const Icon(Icons.event_note),
        label: const Text("More seminars"),
      ),
    );
  }
}

class _Event {
  final String title;
  final String date;
  final String location;
  final String type;

  _Event({
    required this.title,
    required this.date,
    required this.location,
    required this.type,
  });
}


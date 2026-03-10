import 'package:flutter/material.dart';

class SeminarsPage extends StatelessWidget {
  SeminarsPage({super.key});

  final List<_Seminar> seminars = [
    _Seminar(
      title: "Deep Learning for Vision",
      speaker: "Prof. Sharma",
      time: "22 March, 5:00 PM",
      venue: "Room B-103",
    ),
    _Seminar(
      title: "Quantum Computing 101",
      speaker: "Dr. Mehta",
      time: "25 March, 3:00 PM",
      venue: "Seminar Hall",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Seminars')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: seminars.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final s = seminars[index];
          return Card(
            child: ListTile(
              title: Text(s.title),
              subtitle: Text(
                  "${s.speaker}\n${s.time}\n${s.venue}"),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}

class _Seminar {
  final String title;
  final String speaker;
  final String time;
  final String venue;

  _Seminar({
    required this.title,
    required this.speaker,
    required this.time,
    required this.venue,
  });
}


import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SeminarsPage extends StatefulWidget {
  const SeminarsPage({super.key});

  @override
  State<SeminarsPage> createState() => _SeminarsPageState();
}

class _SeminarsPageState extends State<SeminarsPage> {
  final _supabase = Supabase.instance.client;
  late Future<List<_Seminar>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadSeminars();
  }

  Future<List<_Seminar>> _loadSeminars() async {
    final res = await _supabase
        .from('seminars')
        .select()
        .order('date_time', ascending: true);

    return (res as List)
        .map((e) => _Seminar.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Seminars')),
      body: FutureBuilder<List<_Seminar>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Failed to load seminars\n${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }
          final seminars = List<_Seminar>.from(snapshot.data ?? []);
          
          // Add hardcoded seminars for today and upcoming
          seminars.addAll([
            _Seminar(
              id: 'local_sem_1',
              title: 'Advances in Deep Learning',
              speaker: 'Dr. John Doe',
              dateTime: DateTime.now().add(const Duration(hours: 3)),
              venue: 'C-01, R&D Block',
            ),
            _Seminar(
              id: 'local_sem_2',
              title: 'Future of Cloud Computing',
              speaker: 'Prof. Jane Smith',
              dateTime: DateTime.now().add(const Duration(days: 1)),
              venue: 'C-02, R&D Block',
            ),
            _Seminar(
              id: 'local_sem_3',
              title: 'Quantum Algorithms',
              speaker: 'Dr. Alan Turing',
              dateTime: DateTime.now().add(const Duration(days: 3)),
              venue: 'Main Auditorium',
            ),
          ]);
          seminars.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          if (seminars.isEmpty) {
            return const Center(
              child: Text("No seminars found. Add rows in the 'seminars' table."),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: seminars.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final s = seminars[index];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.speaker,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            s.dateString,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.place_outlined, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              s.venue,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Seminar {
  final String id;
  final String title;
  final String speaker;
  final DateTime dateTime;
  final String venue;

  _Seminar({
    required this.id,
    required this.title,
    required this.speaker,
    required this.dateTime,
    required this.venue,
  });

  String get dateString =>
      "${dateTime.day}/${dateTime.month} • ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

  factory _Seminar.fromMap(Map<String, dynamic> map) {
    return _Seminar(
      id: map['id'].toString(),
      title: map['title'] as String,
      speaker: (map['speaker'] ?? '') as String,
      dateTime: DateTime.parse(map['date_time'] as String),
      venue: (map['venue'] ?? '') as String,
    );
  }
}


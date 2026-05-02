import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/session_manager.dart';

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

  Future<void> _openAddSeminarDialog() async {
    final titleCtrl = TextEditingController();
    final speakerCtrl = TextEditingController();
    final venueCtrl = TextEditingController();
    DateTime when = DateTime.now().add(const Duration(days: 1));
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Add seminar'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 8),
                TextField(controller: speakerCtrl, decoration: const InputDecoration(labelText: 'Speaker')),
                const SizedBox(height: 8),
                TextField(controller: venueCtrl, decoration: const InputDecoration(labelText: 'Venue')),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date and time'),
                  subtitle: Text('${when.day}/${when.month}/${when.year}  ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}'),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: when,
                    );
                    if (pickedDate == null) return;
                    final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(when));
                    if (pickedTime == null) return;
                    setLocalState(() {
                      when = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                await _supabase.from('seminars').insert({
                  'title': titleCtrl.text.trim(),
                  'speaker': speakerCtrl.text.trim(),
                  'venue': venueCtrl.text.trim(),
                  'date_time': when.toUtc().toIso8601String(),
                  'created_by': SessionManager.email,
                });
                if (!mounted) return;
                setState(() {
                  _future = _loadSeminars();
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    titleCtrl.dispose();
    speakerCtrl.dispose();
    venueCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = SessionManager.role ?? '';
    final isProf = role == 'professor' || role == 'prof' || role == 'admin';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Seminars'),
        actions: [
          if (isProf)
            IconButton(
              tooltip: 'Add seminar',
              onPressed: _openAddSeminarDialog,
              icon: const Icon(Icons.add),
            ),
        ],
      ),
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
          final seminars = snapshot.data ?? [];
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


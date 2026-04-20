import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentActivityPage extends StatefulWidget {
  const StudentActivityPage({super.key});

  @override
  State<StudentActivityPage> createState() => _StudentActivityPageState();
}

class _StudentActivityPageState extends State<StudentActivityPage> {
  final _supabase = Supabase.instance.client;
  final _search = TextEditingController();
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _supabase
        .from('student_activity')
        .select()
        .order('created_at', ascending: false)
        .limit(200);
    if (!mounted) return;
    setState(() => _rows = List<Map<String, dynamic>>.from(data as List));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _rows
        : _rows.where((r) {
            final u = (r['user_email'] ?? '').toString().toLowerCase();
            final a = (r['action'] ?? '').toString().toLowerCase();
            return u.contains(q) || a.contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Student activity')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search by email or action',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 8),
          ...filtered.map(
            (r) => Card(
              child: ListTile(
                title: Text((r['user_email'] ?? '').toString()),
                subtitle: Text((r['action'] ?? '').toString()),
                trailing: Text(
                  (r['created_at'] ?? '').toString().replaceFirst('T', '\n'),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../services/feedback_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackAdminPage extends StatefulWidget {
  const FeedbackAdminPage({super.key});

  @override
  State<FeedbackAdminPage> createState() => _FeedbackAdminPageState();
}

class _FeedbackAdminPageState extends State<FeedbackAdminPage> {
  final _svc = FeedbackService(Supabase.instance.client);
  String _type = 'all';
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _svc.fetch();
  }

  void _reload() {
    setState(() {
      _future = _type == 'all' ? _svc.fetch() : _svc.fetch(type: _type);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'course', child: Text('Course')),
                  DropdownMenuItem(value: 'app', child: Text('App')),
                ],
                onChanged: (v) {
                  _type = v ?? 'all';
                  _reload();
                },
                decoration: const InputDecoration(labelText: 'Filter by type'),
              ),
              const SizedBox(height: 8),
              ...rows.map(
                (f) => Card(
                  child: ListTile(
                    title: Text('${f['feedback_type']} • ${f['subject']}'),
                    subtitle: Text('${f['user_email']}\n${f['message']}'),
                    isThreeLine: true,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

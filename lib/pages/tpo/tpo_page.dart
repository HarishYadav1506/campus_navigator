import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session_manager.dart';
import '../../services/activity_service.dart';
import '../../services/tpo_service.dart';

class TpoPage extends StatefulWidget {
  const TpoPage({super.key});

  @override
  State<TpoPage> createState() => _TpoPageState();
}

class _TpoPageState extends State<TpoPage> {
  final _svc = TpoService(Supabase.instance.client);
  final _activity = ActivityService(Supabase.instance.client);
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _svc.fetchPostings();
  }

  Future<void> _apply(String id) async {
    final email = (SessionManager.email ?? '').trim().toLowerCase();
    if (email.isEmpty) return;
    try {
      await _svc.apply(id, email);
      await _activity.log(
        userEmail: email,
        action: 'tpo_apply',
        meta: {'posting_id': id},
      );
      if (!mounted) return;
      setState(() => _future = _svc.fetchPostings());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TPO / Placements')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snap.data!;
          if (rows.isEmpty) return const Center(child: Text('No postings yet'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final p = rows[i];
              final slots = (p['available_slots'] as num?)?.toInt() ?? 0;
              return Card(
                child: ListTile(
                  title: Text('${p['company_name']} • ${p['role']}'),
                  subtitle: Text(
                    'Eligibility: ${p['eligibility'] ?? 'N/A'}\n${p['description']}',
                  ),
                  isThreeLine: true,
                  trailing: ElevatedButton(
                    onPressed: slots > 0 ? () => _apply(p['id'].toString()) : null,
                    child: Text(slots > 0 ? 'Apply ($slots)' : 'Closed'),
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

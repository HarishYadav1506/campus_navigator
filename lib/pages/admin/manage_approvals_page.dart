import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageApprovalsPage extends StatefulWidget {
  const ManageApprovalsPage({super.key});

  @override
  State<ManageApprovalsPage> createState() => _ManageApprovalsPageState();
}

class _ManageApprovalsPageState extends State<ManageApprovalsPage> {
  final _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await _supabase
        .from('approval_requests')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> _setStatus(String id, String status) async {
    await _supabase.from('approval_requests').update({
      'status': status,
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
    if (!mounted) return;
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage approvals')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snap.data!;
          if (rows.isEmpty) return const Center(child: Text('No pending approvals'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final r = rows[i];
              return Card(
                child: ListTile(
                  title: Text('${r['request_type']} • ${r['requester_email']}'),
                  subtitle: Text((r['reference_id'] ?? '').toString()),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      TextButton(
                        onPressed: () => _setStatus(r['id'].toString(), 'rejected'),
                        child: const Text('Reject'),
                      ),
                      ElevatedButton(
                        onPressed: () => _setStatus(r['id'].toString(), 'approved'),
                        child: const Text('Approve'),
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

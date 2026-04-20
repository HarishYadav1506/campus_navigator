import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageSports extends StatefulWidget {
  const ManageSports({super.key});

  @override
  State<ManageSports> createState() => _ManageSportsState();
}

class _ManageSportsState extends State<ManageSports> {
  final _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadPending();
  }

  Future<List<Map<String, dynamic>>> _loadPending() async {
    final rows = await _supabase
        .from('sports_bookings')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _approve(Map<String, dynamic> b) async {
    final now = DateTime.now().toUtc();
    await _supabase.from('sports_bookings').update({
      'status': 'approved',
      'approved_at': now.toIso8601String(),
      'checkin_deadline': now.add(const Duration(minutes: 10)).toIso8601String(),
      'ends_at': now.add(const Duration(hours: 1)).toIso8601String(),
    }).eq('id', b['id']);

    await _supabase.from('sports_arenas').upsert({
      'name': b['arena_name'],
      'is_occupied': true,
      'occupied_by_email': b['user_email'],
      'occupied_by_name': b['user_name'],
    }, onConflict: 'name');

    await _supabase.from('user_notifications').insert({
      'user_email': b['user_email'],
      'title': 'Sports booking approved',
      'body': 'Your slot at ${b['arena_name']} is approved. Reach in 10 min.',
      'kind': 'sports',
    });

    if (!mounted) return;
    setState(() => _future = _loadPending());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sports approvals')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final pending = snap.data!;
          if (pending.isEmpty) return const Center(child: Text('No pending bookings'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pending.length,
            itemBuilder: (context, i) {
              final b = pending[i];
              return Card(
                child: ListTile(
                  title: Text((b['arena_name'] ?? '').toString()),
                  subtitle: Text('${b['user_name']} • ${b['user_email']}'),
                  trailing: ElevatedButton(
                    onPressed: () => _approve(b),
                    child: const Text('Approve'),
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

/* old placeholder
class ManageSports extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Sports')),
      body: Center(child: Text('Manage Sports')),
    );
  }
}
*/

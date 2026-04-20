import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageSports extends StatefulWidget {
  const ManageSports({super.key});

  @override
  State<ManageSports> createState() => _ManageSportsState();
}

class _ManageSportsState extends State<ManageSports> {
  final _supabase = Supabase.instance.client;
  bool _loading = false;
  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _occupied = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final pRows = await _supabase
          .from('sports_bookings')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: true);
      
      final oRows = await _supabase
          .from('sports_arenas')
          .select()
          .eq('is_occupied', true);
      
      if (!mounted) return;
      setState(() {
        _pending = List<Map<String, dynamic>>.from(pRows);
        _occupied = List<Map<String, dynamic>>.from(oRows);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

    _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sports Approvals'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Pending Approvals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                if (_pending.isEmpty)
                  const Text('No pending bookings.')
                else
                  ..._pending.map((b) => Card(
                    child: ListTile(
                      title: Text((b['arena_name'] ?? '').toString()),
                      subtitle: Text('${b['user_name']} • ${b['user_email']}'),
                      trailing: ElevatedButton(
                        onPressed: () => _approve(b),
                        child: const Text('Approve'),
                      ),
                    ),
                  )),
                const Divider(height: 32),
                const Text('Active Courts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                if (_occupied.isEmpty)
                  const Text('No courts are currently occupied.')
                else
                  ..._occupied.map((a) => Card(
                    child: ListTile(
                      title: Text((a['name'] ?? '').toString()),
                      subtitle: Text('Occupied by: ${a['occupied_by_name'] ?? 'Unknown'} (${a['occupied_by_email'] ?? 'Unknown'})'),
                      trailing: TextButton.icon(
                        icon: const Icon(Icons.timer_off_outlined),
                        label: const Text('Free Court'),
                        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                        onPressed: () async {
                           await _supabase.from('sports_arenas').update({
                             'is_occupied': false,
                             'occupied_by_email': null,
                             'occupied_by_name': null,
                           }).eq('name', a['name']);
                           _loadAll();
                        },
                      ),
                    ),
                  )),
              ],
            ),
    );
  }
}

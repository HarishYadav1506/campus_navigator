import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageSports extends StatefulWidget {
  const ManageSports({super.key});

  @override
  State<ManageSports> createState() => _ManageSportsState();
}

class _ManageSportsState extends State<ManageSports> {
  final _supabase = Supabase.instance.client;

  String _fmt(DateTime dt) {
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  DateTime _nextAvailableForArena(String arena, List<Map<String, dynamic>> all) {
    final now = DateTime.now().toUtc();
    DateTime? latestApprovedOrActive;
    for (final b in all) {
      if ((b['arena_name'] ?? '').toString() != arena) continue;
      final status = (b['status'] ?? '').toString();
      if (status != 'approved' && status != 'active') continue;
      final t = DateTime.tryParse((b['booking_time'] ?? '').toString());
      if (t == null) continue;
      if (latestApprovedOrActive == null || t.isAfter(latestApprovedOrActive)) {
        latestApprovedOrActive = t;
      }
    }
    if (latestApprovedOrActive == null) return now;
    final slotEnd = latestApprovedOrActive.add(const Duration(hours: 1));
    return slotEnd.isAfter(now) ? slotEnd : now;
  }

  Future<void> _approve(Map<String, dynamic> b) async {
    final now = DateTime.now().toUtc();
    try {
      await _supabase.from('sports_bookings').update({
        'status': 'approved',
        'booking_time': now.toIso8601String(),
      }).eq('id', b['id']);

      await _supabase.from('user_notifications').insert({
        'user_email': b['user_email'],
        'title': 'Sports booking approved',
        'body': 'Your slot at ${b['arena_name']} is approved. Reach in 10 min.',
        'kind': 'sports',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking approved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approval failed: $e')),
      );
    }
  }

  Future<void> _reject(Map<String, dynamic> b) async {
    try {
      await _supabase.from('sports_bookings').update({
        'status': 'rejected',
      }).eq('id', b['id']);
      await _supabase.from('user_notifications').insert({
        'user_email': b['user_email'],
        'title': 'Sports booking rejected',
        'body': 'Your request at ${b['arena_name']} was rejected. Please try another slot.',
        'kind': 'sports',
      });
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reject failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sports approvals')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('sports_bookings')
            .stream(primaryKey: ['id'])
            .order('booking_time', ascending: true),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final all = List<Map<String, dynamic>>.from(snap.data!);
          final pending = all.where((b) => (b['status'] ?? '') == 'pending').toList();
          if (pending.isEmpty) return const Center(child: Text('No pending bookings'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pending.length,
            itemBuilder: (context, i) {
              final b = pending[i];
              final arena = (b['arena_name'] ?? '').toString();
              final next = _nextAvailableForArena(arena, all);
              return Card(
                child: ListTile(
                  title: Text(arena),
                  subtitle: Text(
                    '${(b['user_email'] ?? '').toString()}\nNext available: ${_fmt(next)}',
                  ),
                  isThreeLine: true,
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => _reject(b),
                        child: const Text('Reject'),
                      ),
                      ElevatedButton(
                        onPressed: () => _approve(b),
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

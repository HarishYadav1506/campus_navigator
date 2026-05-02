import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageSports extends StatefulWidget {
  const ManageSports({super.key});

  @override
  State<ManageSports> createState() => _ManageSportsState();
}

class _ManageSportsState extends State<ManageSports> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _allBookings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _supabase
          .from('sports_bookings')
          .select()
          .order('created_at', ascending: true);
      if (!mounted) return;
      setState(() {
        _allBookings = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

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
    final id = b['id'];
    try {
      await _supabase.from('sports_bookings').update({
        'status': 'approved',
        'booking_time': now.toIso8601String(),
        'approved_at': now.toIso8601String(),
      }).eq('id', id);

      try {
        await _supabase.from('user_notifications').insert({
          'user_email': b['user_email'],
          'title': 'Sports booking approved',
          'body':
              'Your slot at ${b['arena_name']} is approved. Reach in 10 min.',
          'kind': 'sports',
        });
      } catch (_) {
        // Booking update succeeded; notification is optional
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking approved')),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approval failed: $e')),
      );
    }
  }

  Future<void> _reject(Map<String, dynamic> b) async {
    final id = b['id'];
    try {
      await _supabase.from('sports_bookings').update({
        'status': 'rejected',
      }).eq('id', id);
      try {
        await _supabase.from('user_notifications').insert({
          'user_email': b['user_email'],
          'title': 'Sports booking rejected',
          'body':
              'Your request at ${b['arena_name']} was rejected. Please try another slot.',
          'kind': 'sports',
        });
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking rejected')),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reject failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = _allBookings;
    final pending =
        all.where((b) => (b['status'] ?? '').toString() == 'pending').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sports approvals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _reload,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load bookings.\n$_error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : pending.isEmpty
                  ? const Center(child: Text('No pending bookings'))
                  : RefreshIndicator(
                      onRefresh: _reload,
                      child: ListView.builder(
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
                                '${(b['user_email'] ?? '').toString()}\n'
                                'Next available: ${_fmt(next)}',
                              ),
                              isThreeLine: true,
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  TextButton(
                                    onPressed: _loading ? null : () => _reject(b),
                                    child: const Text('Reject'),
                                  ),
                                  ElevatedButton(
                                    onPressed: _loading ? null : () => _approve(b),
                                    child: const Text('Approve'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
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

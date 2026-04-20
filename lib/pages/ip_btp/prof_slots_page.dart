import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session_manager.dart';
import '../../services/activity_service.dart';

class ProfSlotsPage extends StatefulWidget {
  const ProfSlotsPage({super.key});

  @override
  State<ProfSlotsPage> createState() => _ProfSlotsPageState();
}

class _ProfSlotsPageState extends State<ProfSlotsPage> {
  final _supabase = Supabase.instance.client;
  final _activity = ActivityService(Supabase.instance.client);
  final _search = TextEditingController();
  final _profName = TextEditingController();
  final _day = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();

  List<Map<String, dynamic>> _slots = [];
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = false;

  bool get _isProf =>
      (SessionManager.role == 'professor' || SessionManager.role == 'prof');
  String get _email => (SessionManager.email ?? '').trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _supabase
        .from('prof_slots')
        .select()
        .order('day', ascending: true)
        .order('start_time', ascending: true);
    final bookings = await _supabase
        .from('prof_slot_bookings')
        .select()
        .order('requested_at', ascending: false)
        .limit(200);
    if (!mounted) return;
    setState(() {
      _slots = List<Map<String, dynamic>>.from(rows);
      _bookings = List<Map<String, dynamic>>.from(bookings);
    });
  }

  Future<void> _createSlot() async {
    if (_day.text.trim().isEmpty || _start.text.trim().isEmpty || _end.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await _supabase.from('prof_slots').insert({
        'prof_email': _email,
        'prof_name': _profName.text.trim().isEmpty ? _email : _profName.text.trim(),
        'day': _day.text.trim(),
        'start_time': _start.text.trim(),
        'end_time': _end.text.trim(),
        'is_open': true,
      });
      _day.clear();
      _start.clear();
      _end.clear();
      await _load();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _replicate(Map<String, dynamic> slot) async {
    await _supabase.from('prof_slots').insert({
      'prof_email': slot['prof_email'],
      'prof_name': slot['prof_name'],
      'day': _day.text.trim().isEmpty ? slot['day'] : _day.text.trim(),
      'start_time': slot['start_time'],
      'end_time': slot['end_time'],
      'is_open': true,
    });
    await _load();
  }

  Future<void> _book(Map<String, dynamic> slot) async {
    await _supabase.from('prof_slot_bookings').insert({
      'slot_id': slot['id'],
      'student_email': _email,
      'status': 'requested',
    });
    await _supabase.from('approval_requests').insert({
      'request_type': 'prof_slot',
      'reference_id': slot['id'].toString(),
      'requester_email': _email,
      'status': 'pending',
    });
    await _activity.log(
      userEmail: _email,
      action: 'slot_request',
      meta: {'slot_id': slot['id'].toString()},
    );
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Slot requested. Waiting for professor approval.')),
    );
  }

  Future<void> _reviewBooking(Map<String, dynamic> booking, String status) async {
    await _supabase.from('prof_slot_bookings').update({
      'status': status,
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', booking['id']);
    await _activity.log(
      userEmail: _email,
      action: 'slot_request_$status',
      meta: {'booking_id': booking['id'].toString()},
    );
    await _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _profName.dispose();
    _day.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.toLowerCase();
    final items = _slots.where((s) {
      final prof = (s['prof_name'] ?? s['prof_email'] ?? '').toString().toLowerCase();
      return q.isEmpty || prof.contains(q);
    }).toList();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final previousDay = _bookings.where((b) {
      final t = DateTime.tryParse((b['requested_at'] ?? '').toString());
      if (t == null) return false;
      return t.day == yesterday.day && t.month == yesterday.month && t.year == yesterday.year;
    }).toList();
    final myBookings = _bookings.where((b) => (b['student_email'] ?? '') == _email).toList();
    final pendingForProf = _isProf
        ? _bookings.where((b) {
            final slotId = (b['slot_id'] ?? '').toString();
            final mine = _slots.any(
              (s) => s['id'].toString() == slotId && s['prof_email'] == _email,
            );
            return mine && b['status'] == 'requested';
          }).toList()
        : const <Map<String, dynamic>>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Professor Office Slots')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search professor',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          if (_isProf) ...[
            TextField(controller: _profName, decoration: const InputDecoration(labelText: 'Professor name')),
            const SizedBox(height: 8),
            TextField(controller: _day, decoration: const InputDecoration(labelText: 'Day (e.g. Monday)')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: _start, decoration: const InputDecoration(labelText: 'Start (10:00)'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _end, decoration: const InputDecoration(labelText: 'End (11:00)'))),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loading ? null : _createSlot,
              child: Text(_loading ? 'Saving...' : 'Create slot'),
            ),
            const SizedBox(height: 14),
          ],
          const Text('Available slots', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...items.map((slot) {
            final open = (slot['is_open'] ?? true) == true;
            return Card(
              child: ListTile(
                title: Text('${slot['prof_name'] ?? slot['prof_email']} • ${slot['day']}'),
                subtitle: Text('${slot['start_time']} - ${slot['end_time']} • ${open ? 'Open' : 'Closed'}'),
                trailing: _isProf
                    ? IconButton(
                        tooltip: 'Replicate',
                        onPressed: () => _replicate(slot),
                        icon: const Icon(Icons.copy_all_outlined),
                      )
                    : ElevatedButton(
                        onPressed: open ? () => _book(slot) : null,
                        child: const Text('Request'),
                      ),
              ),
            );
          }),
          const SizedBox(height: 16),
          if (_isProf) ...[
            const Text('Pending requests', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (pendingForProf.isEmpty)
              const Text('No pending requests.')
            else
              ...pendingForProf.map((b) => Card(
                    child: ListTile(
                      title: Text((b['student_email'] ?? '').toString()),
                      subtitle: Text('Slot ID: ${b['slot_id']}'),
                      trailing: Wrap(
                        spacing: 6,
                        children: [
                          TextButton(
                            onPressed: () => _reviewBooking(b, 'rejected'),
                            child: const Text('Reject'),
                          ),
                          ElevatedButton(
                            onPressed: () => _reviewBooking(b, 'approved'),
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                    ),
                  )),
          ] else ...[
            const Text('My slot requests', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...myBookings.take(10).map((b) => Card(
                  child: ListTile(
                    title: Text('Slot ${b['slot_id']}'),
                    subtitle: Text('Status: ${b['status']}'),
                  ),
                )),
          ],
          const SizedBox(height: 16),
          const Text('Previous day history', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (previousDay.isEmpty)
            const Text('No previous day records.')
          else
            ...previousDay.map((b) => ListTile(
                  leading: const Icon(Icons.history),
                  title: Text((b['student_email'] ?? '').toString()),
                  subtitle: Text('Status: ${b['status']}'),
                )),
        ],
      ),
    );
  }
}

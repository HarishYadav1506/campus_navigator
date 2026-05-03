import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session_manager.dart';
import '../../services/activity_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _supabase = Supabase.instance.client;
  late final _activity = ActivityService(_supabase);

  DateTime _selectedDay = DateTime.now();
  final TextEditingController _profSearch = TextEditingController();

  /// All `prof_slots` rows for the selected weekday (e.g. Monday).
  List<Map<String, dynamic>> _daySlots = [];
  final Map<String, Map<String, dynamic>> _approvedBookingBySlotId = {};
  bool _loading = false;

  String get _email => (SessionManager.email ?? '').trim().toLowerCase();

  bool get _isProf {
    final r = (SessionManager.role ?? '').trim().toLowerCase();
    return r == 'prof' || r == 'professor';
  }

  static String _weekdayName(DateTime d) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[d.weekday - 1];
  }

  static String _shortWeekday(DateTime d) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[d.weekday - 1];
  }

  @override
  void initState() {
    super.initState();
    _profSearch.addListener(() => setState(() {}));
    _loadSlotsForSelectedDay();
  }

  @override
  void dispose() {
    _profSearch.dispose();
    super.dispose();
  }

  Future<void> _loadSlotsForSelectedDay() async {
    setState(() => _loading = true);
    try {
      final day = _weekdayName(_selectedDay);
      final rows = await _supabase
          .from('prof_slots')
          .select()
          .eq('day', day)
          .order('start_time', ascending: true);
      final slots = List<Map<String, dynamic>>.from(rows as List);
      final slotIds = slots.map((s) => s['id']).whereType<Object>().toList();
      final bookings = slotIds.isEmpty
          ? <Map<String, dynamic>>[]
          : List<Map<String, dynamic>>.from(
              await _supabase
                  .from('prof_slot_bookings')
                  .select('id,slot_id,student_email,status')
                  .inFilter('slot_id', slotIds)
                  .eq('status', 'approved'),
            );
      final bySlot = <String, Map<String, dynamic>>{};
      for (final b in bookings) {
        final sid = (b['slot_id'] ?? '').toString();
        if (sid.isEmpty || bySlot.containsKey(sid)) continue;
        bySlot[sid] = b;
      }
      if (!mounted) return;
      setState(() {
        _daySlots = slots;
        _approvedBookingBySlotId
          ..clear()
          ..addAll(bySlot);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load slots: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _visibleSlots {
    if (_isProf) return _daySlots;
    final q = _profSearch.text.trim().toLowerCase();
    if (q.isEmpty) return _daySlots;
    return _daySlots.where((s) {
      final label =
          '${s['prof_name'] ?? ''} ${s['prof_email'] ?? ''}'.toLowerCase();
      return label.contains(q);
    }).toList();
  }

  bool get _canRequestSlots => !_isProf;

  Future<void> _requestSlot(Map<String, dynamic> slot) async {
    if (_email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book')),
      );
      return;
    }
    final open = (slot['is_open'] ?? true) == true;
    if (!open) return;

    try {
      final slotId = (slot['id'] ?? '').toString();
      if (slotId.isEmpty) {
        throw Exception('Invalid slot');
      }
      final existingApproved = _approvedBookingBySlotId[slotId];
      final bookedBy = (existingApproved?['student_email'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      if (existingApproved != null && bookedBy == _email) {
        await _supabase
            .from('prof_slot_bookings')
            .delete()
            .eq('id', existingApproved['id']);
        await _activity.log(
          userEmail: _email,
          action: 'slot_booking_removed',
          meta: {'slot_id': slotId},
        );
        await _loadSlotsForSelectedDay();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking removed.')),
        );
        return;
      }
      if (existingApproved != null) {
        throw Exception('This slot is already booked');
      }
      await _supabase.from('prof_slot_bookings').insert({
        'slot_id': slotId,
        'student_email': _email,
        'status': 'approved',
        'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      });
      await _activity.log(
        userEmail: _email,
        action: 'slot_booked',
        meta: {'slot_id': slotId.toString()},
      );
      await _loadSlotsForSelectedDay();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot booked successfully.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not book: $e')),
        );
      }
    }
  }

  Future<void> _copyPreviousWeekdaySlotsForProf() async {
    if (!_isProf || _email.isEmpty) return;
    final prev = _selectedDay.subtract(const Duration(days: 1));
    final fromDay = _weekdayName(prev);
    final toDay = _weekdayName(_selectedDay);

    setState(() => _loading = true);
    try {
      final rows = await _supabase
          .from('prof_slots')
          .select()
          .eq('day', fromDay)
          .eq('prof_email', _email);

      final list = List<Map<String, dynamic>>.from(rows as List);
      if (list.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No slots on $fromDay to copy to $toDay'),
            ),
          );
        }
        return;
      }

      for (final s in list) {
        await _supabase.from('prof_slots').insert({
          'prof_email': _email,
          'prof_name': (s['prof_name'] ?? _email).toString(),
          'day': toDay,
          'start_time': (s['start_time'] ?? '').toString(),
          'end_time': (s['end_time'] ?? '').toString(),
          'is_open': true,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied ${list.length} slot(s): $fromDay → $toDay'),
          ),
        );
      }
      await _loadSlotsForSelectedDay();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copy failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddSlotDialog() async {
    if (!_isProf) return;
    final nameCtrl = TextEditingController(
      text: _email.split('@').first,
    );
    final startCtrl = TextEditingController(text: '10:00');
    final endCtrl = TextEditingController(text: '11:00');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add office slot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Day: ${_weekdayName(_selectedDay)}'),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Display name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: startCtrl,
              decoration: const InputDecoration(
                labelText: 'Start (HH:MM)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: endCtrl,
              decoration: const InputDecoration(
                labelText: 'End (HH:MM)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final day = _weekdayName(_selectedDay);
              try {
                await _supabase.from('prof_slots').insert({
                  'prof_email': _email,
                  'prof_name': nameCtrl.text.trim().isEmpty
                      ? _email
                      : nameCtrl.text.trim(),
                  'day': day,
                  'start_time': startCtrl.text.trim(),
                  'end_time': endCtrl.text.trim(),
                  'is_open': true,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadSlotsForSelectedDay();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Slot created')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOwnSlot(Map<String, dynamic> slot) async {
    final owner = (slot['prof_email'] ?? '').toString().trim().toLowerCase();
    if (owner != _email) return;
    try {
      await _supabase.from('prof_slots').delete().eq('id', slot['id']);
      await _loadSlotsForSelectedDay();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = SessionManager.role ?? 'guest';
    final visible = _visibleSlots;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar & Slots')),
      floatingActionButton: SessionManager.isLoggedIn && _isProf
          ? FloatingActionButton.extended(
              onPressed: _loading ? null : _showAddSlotDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add slot'),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Logged in as $role",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _buildDateRow(),
            const SizedBox(height: 16),
            if (_isProf)
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _copyPreviousWeekdaySlotsForProf,
                  icon: const Icon(Icons.copy_all_outlined),
                  label: const Text('Copy previous calendar day'),
                ),
              ),
            if (_isProf) const SizedBox(height: 8),
            if (!_isProf) ...[
              TextField(
                controller: _profSearch,
                decoration: const InputDecoration(
                  hintText: 'Search professor name or email',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              "Slots for ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year} (${_weekdayName(_selectedDay)})",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            if (_loading) const SizedBox(height: 8),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Text(
                        !_isProf && _profSearch.text.trim().isNotEmpty
                            ? 'No professor slots match your search for this day.'
                            : 'No professor slots for this day yet.',
                      ),
                    )
                  : ListView.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final s = visible[i];
                        final name =
                            (s['prof_name'] ?? s['prof_email'] ?? '—').toString();
                        final email = (s['prof_email'] ?? '').toString();
                        final open = (s['is_open'] ?? true) == true;
                        final mine = email.trim().toLowerCase() == _email;
                        final slotId = (s['id'] ?? '').toString();
                        final existingApproved = _approvedBookingBySlotId[slotId];
                        final bookedBy = (existingApproved?['student_email'] ?? '')
                            .toString()
                            .trim()
                            .toLowerCase();
                        final bookedByMe = bookedBy.isNotEmpty && bookedBy == _email;
                        final bookedByOther = bookedBy.isNotEmpty && bookedBy != _email;

                        return Card(
                          child: ListTile(
                            title: Text(name),
                            subtitle: Text(
                              '${s['day']} • ${s['start_time']} – ${s['end_time']}\n$email',
                            ),
                            isThreeLine: true,
                            trailing: _isProf
                                ? mine
                                    ? IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () => _deleteOwnSlot(s),
                                      )
                                    : null
                                : ElevatedButton(
                                    onPressed: open && _canRequestSlots && !bookedByOther
                                        ? (_email.isNotEmpty
                                            ? () => _requestSlot(s)
                                            : null)
                                        : null,
                                    child: Text(
                                      bookedByMe
                                          ? 'Booked'
                                          : !open
                                          ? 'Closed'
                                          : bookedByOther
                                              ? 'Booked'
                                          : _email.isEmpty
                                              ? 'Log in'
                                              : 'Book',
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/prof_slots');
                },
                child: const Text('Open full professor slots page'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow() {
    final dates = List<DateTime>.generate(
      7,
      (index) => DateTime.now().add(Duration(days: index)),
    );

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.day == _selectedDay.day &&
              date.month == _selectedDay.month &&
              date.year == _selectedDay.year;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = date;
              });
              _loadSlotsForSelectedDay();
            },
            child: Container(
              width: 70,
              decoration: BoxDecoration(
                color: isSelected ? Colors.indigo : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _shortWeekday(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.indigo,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.indigo,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

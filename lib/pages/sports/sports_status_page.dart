import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session_manager.dart';
import '../../services/engagement_service.dart';

class SportsStatusPage extends StatefulWidget {
  final String arenaName;
  const SportsStatusPage({super.key, required this.arenaName});

  @override
  State<SportsStatusPage> createState() => _SportsStatusPageState();
}

class _SportsStatusPageState extends State<SportsStatusPage> {
  final supabase = Supabase.instance.client;
  final nameController = TextEditingController();

  RealtimeChannel? _realtimeChannel;
  bool _loading = false;
  Map<String, dynamic>? _arena;
  Map<String, dynamic>? _myBooking;
  List<Map<String, dynamic>> _pendingBookings = [];
  List<Map<String, dynamic>> _waitlist = [];

  String get _email => (SessionManager.email ?? '').trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    final arena = widget.arenaName;
    _realtimeChannel = supabase.channel('sports_arena_${arena.hashCode}');

    void refreshIfArena(PostgresChangePayload payload) {
      final n = payload.newRecord;
      final o = payload.oldRecord;
      bool matches(Map<String, dynamic> row) =>
          (row['arena_name'] ?? row['name'] ?? '').toString() == arena;
      if (matches(n) || matches(o)) _load(silent: true);
    }

    _realtimeChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sports_bookings',
          callback: refreshIfArena,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sports_waitlist',
          callback: refreshIfArena,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sports_arenas',
          callback: refreshIfArena,
        )
        .subscribe();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final arena = await supabase
          .from('sports_arenas')
          .select()
          .eq('name', widget.arenaName)
          .maybeSingle();

      final myBooking = _email.isEmpty
          ? null
          : await supabase
              .from('sports_bookings')
              .select()
              .eq('arena_name', widget.arenaName)
              .eq('user_email', _email)
              .inFilter('status', ['pending', 'approved', 'active'])
              .order('booking_time', ascending: false)
              .maybeSingle();

      final pendingBookings = await supabase
          .from('sports_bookings')
          .select('id,user_email,booking_time,status')
          .eq('arena_name', widget.arenaName)
          .eq('status', 'pending')
          .order('booking_time', ascending: true);

      final waitlist = await supabase
          .from('sports_waitlist')
          .select('id,user_email,created_at')
          .eq('arena_name', widget.arenaName)
          .order('created_at', ascending: true);

      if (!mounted) return;
      setState(() {
        _arena = arena == null ? null : Map<String, dynamic>.from(arena);
        _myBooking = myBooking == null ? null : Map<String, dynamic>.from(myBooking);
        _pendingBookings = List<Map<String, dynamic>>.from(pendingBookings);
        _waitlist = List<Map<String, dynamic>>.from(waitlist);
      });
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _ensureArenaRow() async {
    final existing = await supabase
        .from('sports_arenas')
        .select('id')
        .eq('name', widget.arenaName)
        .maybeSingle();
    if (existing != null) return;
    await supabase.from('sports_arenas').insert({'name': widget.arenaName});
  }

  Future<void> _requestBooking() async {
    final name = nameController.text.trim();
    if (_email.isEmpty) return;
    setState(() => _loading = true);
    try {
      await _ensureArenaRow();
      final cooldown = await supabase
          .from('sports_cooldowns')
          .select('cooldown_until')
          .eq('user_email', _email)
          .maybeSingle();
      if (cooldown != null) {
        final until = DateTime.tryParse('${cooldown['cooldown_until']}');
        if (until != null && until.isAfter(DateTime.now().toUtc())) {
          throw Exception('Booking blocked until ${until.toLocal()}');
        }
      }
      await supabase.from('sports_bookings').insert({
        'arena_name': widget.arenaName,
        'user_email': _email,
        'status': 'pending',
      });
      await supabase.from('sports_admin_notifications').insert({
        'arena_name': widget.arenaName,
        'user_email': _email,
        'message': 'New booking request for ${widget.arenaName}',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent to admin.')),
      );
      _load(silent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinWaitlist() async {
    if (_email.isEmpty) return;
    await _ensureArenaRow();
    await supabase.from('sports_waitlist').insert({
      'arena_name': widget.arenaName,
      'user_email': _email,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to queue')),
      );
    }
  }

  Future<void> _checkIn() async {
    final booking = _myBooking;
    if (booking == null) return;
    await supabase.from('sports_bookings').update({
      'checked_in_at': DateTime.now().toUtc().toIso8601String(),
      'status': 'active',
    }).eq('id', booking['id']);
    try {
      await EngagementService(supabase).awardPoints(_email, 5, 'sports_checkin');
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checked in. +5 points')),
      );
    }
  }

  @override
  void dispose() {
    final ch = _realtimeChannel;
    if (ch != null) supabase.removeChannel(ch);
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final currentlyRunningApproved = _pendingBookings.isNotEmpty
        ? false
        : (_myBooking != null &&
            ((_myBooking!['status'] ?? '') == 'approved' || (_myBooking!['status'] ?? '') == 'active') &&
            DateTime.tryParse((_myBooking!['booking_time'] ?? '').toString())
                    ?.add(const Duration(hours: 1))
                    .isAfter(now) ==
                true);
    final occupied = currentlyRunningApproved;
    final my = _myBooking;
    final myStatus = (my?['status'] ?? '').toString();
    final myPendingIndex = _pendingBookings.indexWhere((w) =>
        (w['user_email'] ?? '').toString().toLowerCase() == _email);
    final myWaitIndex = _waitlist.indexWhere((w) =>
        (w['user_email'] ?? '').toString().toLowerCase() == _email);
    return Scaffold(
      appBar: AppBar(title: Text(widget.arenaName)),
      body: RefreshIndicator(
        onRefresh: () => _load(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            if (_loading) const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(occupied ? Icons.lock_clock : Icons.check_circle_outline),
                title: Text(occupied ? 'Occupied' : 'Free'),
                subtitle: Text(
                  occupied ? 'Currently active booking is running' : 'Court free: you can request 1-hour booking',
                ),
                trailing: IconButton(
                  onPressed: _loading ? null : () => _load(),
                  icon: const Icon(Icons.refresh),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Rule: if approved and not checked-in within 10 min, booking is cancelled and cooldown applies.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Your name',
                hintText: 'Enter full name',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _loading ? null : _requestBooking,
              icon: const Icon(Icons.event_available),
              label: const Text('Request booking'),
            ),
            OutlinedButton.icon(
              onPressed: _loading ? null : _joinWaitlist,
              icon: const Icon(Icons.queue),
              label: const Text('Join queue'),
            ),
            if (my != null) ...[
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  title: Text('Your booking: $myStatus'),
                  subtitle: const Text('Admin approval is required before check-in.'),
                  trailing: myStatus == 'approved'
                      ? ElevatedButton(
                          onPressed: _checkIn,
                          child: const Text('Check-in'),
                        )
                      : null,
                ),
              ),
            ],
            if (myPendingIndex >= 0) ...[
              const SizedBox(height: 4),
              Text(
                'Your pending request position: ${myPendingIndex + 1}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            if (myWaitIndex >= 0) ...[
              const SizedBox(height: 4),
              Text(
                'Your waitlist position: ${myWaitIndex + 1}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            const Divider(),
            const Text('Pending requests queue', style: TextStyle(fontWeight: FontWeight.w700)),
            if (_pendingBookings.isEmpty)
              const Text('No pending requests')
            else
              ..._pendingBookings.asMap().entries.map(
                (entry) {
                  final idx = entry.key;
                  final w = entry.value;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 12,
                      child: Text('${idx + 1}', style: const TextStyle(fontSize: 11)),
                    ),
                    title: Text((w['user_email'] ?? '').toString()),
                    subtitle: Text((w['booking_time'] ?? '').toString()),
                  );
                },
              ),
            const SizedBox(height: 8),
            const Text('Waitlist', style: TextStyle(fontWeight: FontWeight.w700)),
            if (_waitlist.isEmpty)
              const Text('No one in waitlist')
            else
              ..._waitlist.asMap().entries.map(
                (entry) {
                  final idx = entry.key;
                  final w = entry.value;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 12,
                      child: Text('${idx + 1}', style: const TextStyle(fontSize: 11)),
                    ),
                    title: Text((w['user_email'] ?? '').toString()),
                    subtitle: Text((w['created_at'] ?? '').toString()),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

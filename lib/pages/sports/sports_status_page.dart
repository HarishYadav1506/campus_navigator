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
  Map<String, dynamic>? _myBooking;
  List<Map<String, dynamic>> _pendingBookings = [];
  List<Map<String, dynamic>> _waitlist = [];
  /// True when any approved/active slot for this arena is still inside its 1-hour window.
  bool _arenaOccupied = false;

  /// Set when this user already has a sports booking elsewhere (or pending) that blocks a new one.
  String? _globalSportsBlockReason;

  String get _email => (SessionManager.email ?? '').trim().toLowerCase();

  Future<String?> _computeGlobalSportsBlockReason() async {
    if (_email.isEmpty) return null;
    try {
      final rows =
          await supabase.from('sports_bookings').select().eq('user_email', _email);
      final now = DateTime.now().toUtc();
      for (final raw in rows as List) {
        final r = Map<String, dynamic>.from(raw as Map);
        final st = (r['status'] ?? '').toString();
        if (st == 'rejected') continue;
        final arena = (r['arena_name'] ?? '').toString();
        if (st == 'pending') {
          return 'You already have a pending sports request'
              '${arena.isNotEmpty ? " ($arena)" : ""}. '
              'Wait until it is approved, rejected, or expires before booking another facility.';
        }
        if (st == 'approved' || st == 'active') {
          final bt = DateTime.tryParse((r['booking_time'] ?? '').toString());
          if (bt == null) {
            return 'You have an active sports booking'
                '${arena.isNotEmpty ? " at $arena" : ""}. '
                'You can book again after that slot ends.';
          }
          final end = bt.add(const Duration(hours: 1));
          if (end.isAfter(now)) {
            final localEnd = end.toLocal();
            return 'You already have a booking in progress'
                '${arena.isNotEmpty ? " ($arena)" : ""} until '
                '${localEnd.hour.toString().padLeft(2, '0')}:'
                '${localEnd.minute.toString().padLeft(2, '0')}. '
                'You can request another arena only after it ends or is rejected.';
          }
        }
      }
    } catch (_) {}
    return null;
  }

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
      final now = DateTime.now().toUtc();

      Map<String, dynamic>? myBooking;
      if (_email.isNotEmpty) {
        final myRows = await supabase
            .from('sports_bookings')
            .select()
            .eq('arena_name', widget.arenaName)
            .eq('user_email', _email)
            .inFilter('status', ['pending', 'approved', 'active'])
            .order('created_at', ascending: false)
            .limit(1);
        final raw = myRows as List;
        myBooking = raw.isEmpty
            ? null
            : Map<String, dynamic>.from(raw.first as Map);
      }

      final pendingBookings = await supabase
          .from('sports_bookings')
          .select('id,user_email,booking_time,status')
          .eq('arena_name', widget.arenaName)
          .eq('status', 'pending')
          .order('booking_time', ascending: true);

      final activeRows = await supabase
          .from('sports_bookings')
          .select('booking_time,status')
          .eq('arena_name', widget.arenaName)
          .inFilter('status', ['approved', 'active']);

      var arenaOccupied = false;
      for (final row in activeRows as List) {
        final m = Map<String, dynamic>.from(row as Map);
        final t = DateTime.tryParse((m['booking_time'] ?? '').toString());
        if (t != null && t.add(const Duration(hours: 1)).isAfter(now)) {
          arenaOccupied = true;
          break;
        }
      }

      final waitlist = await supabase
          .from('sports_waitlist')
          .select('id,user_email,created_at')
          .eq('arena_name', widget.arenaName)
          .order('created_at', ascending: true);

      final globalBlock = await _computeGlobalSportsBlockReason();

      if (!mounted) return;
      setState(() {
        _myBooking = myBooking;
        _pendingBookings = List<Map<String, dynamic>>.from(pendingBookings);
        _waitlist = List<Map<String, dynamic>>.from(waitlist);
        _arenaOccupied = arenaOccupied;
        _globalSportsBlockReason = globalBlock;
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
    if (_email.isEmpty) return;
    setState(() => _loading = true);
    try {
      final block = await _computeGlobalSportsBlockReason();
      if (block != null) {
        throw Exception(block);
      }

      await _ensureArenaRow();
      final cooldown = await supabase
          .from('sports_cooldowns')
          .select('blocked_until')
          .eq('user_email', _email)
          .maybeSingle();
      if (cooldown != null) {
        final until =
            DateTime.tryParse('${cooldown['blocked_until'] ?? ''}');
        if (until != null && until.isAfter(DateTime.now().toUtc())) {
          throw Exception('Booking blocked until ${until.toLocal()}');
        }
      }
      final requestedAt = DateTime.now().toUtc();
      await supabase.from('sports_bookings').insert({
        'arena_name': widget.arenaName,
        'user_email': _email,
        'status': 'pending',
        'booking_time': requestedAt.toIso8601String(),
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
      await _load(silent: true);
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
    final occupied = _arenaOccupied;
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
            if (_globalSportsBlockReason != null) ...[
              Card(
                color: Colors.orange.withValues(alpha: 0.15),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _globalSportsBlockReason!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
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
              onPressed: _loading || _globalSportsBlockReason != null
                  ? null
                  : _requestBooking,
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

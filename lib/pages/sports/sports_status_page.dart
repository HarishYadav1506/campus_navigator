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
  bool _joiningWaitlist = false;
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

  /// Active cooldown end time, or null. Uses `select()` so missing `blocked_until` column does not break the query.
  Future<DateTime?> _activeSportsCooldownUntil() async {
    if (_email.isEmpty) return null;
    try {
      final cooldown = await supabase
          .from('sports_cooldowns')
          .select()
          .eq('user_email', _email)
          .maybeSingle();
      if (cooldown == null) return null;
      final m = Map<String, dynamic>.from(cooldown as Map);
      final raw = m['blocked_until'] ?? m['blocked_until_at'];
      if (raw == null) return null;
      final until = DateTime.tryParse(raw.toString());
      if (until == null) return null;
      final utc = until.toUtc();
      if (utc.isAfter(DateTime.now().toUtc())) return utc;
      return null;
    } catch (e, st) {
      debugPrint('sports_cooldowns: $e\n$st');
      return null;
    }
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
      final cooldownUntil = await _activeSportsCooldownUntil();
      if (cooldownUntil != null) {
        throw Exception('Booking blocked until ${cooldownUntil.toLocal()}');
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
    if (_email.isEmpty || _joiningWaitlist) return;
    setState(() => _joiningWaitlist = true);
    try {
      final alreadyInLocalQueue = _waitlist.any(
        (w) => (w['user_email'] ?? '').toString().trim().toLowerCase() == _email,
      );
      if (alreadyInLocalQueue) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are already in this queue')),
          );
        }
        return;
      }

      final block = await _computeGlobalSportsBlockReason();
      if (block != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(block)),
          );
        }
        return;
      }
      final cooldownUntil = await _activeSportsCooldownUntil();
      if (cooldownUntil != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Booking blocked until ${cooldownUntil.toLocal()}',
              ),
            ),
          );
        }
        return;
      }
      await _ensureArenaRow();
      final existingRows = await supabase
          .from('sports_waitlist')
          .select('id,user_email')
          .eq('arena_name', widget.arenaName);
      final alreadyJoined = (existingRows as List).any((r) {
        final m = Map<String, dynamic>.from(r as Map);
        return (m['user_email'] ?? '').toString().trim().toLowerCase() == _email;
      });
      if (alreadyJoined) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are already in this queue')),
          );
        }
        return;
      }
      await supabase.from('sports_waitlist').insert({
        'arena_name': widget.arenaName,
        'user_email': _email,
      });
      await _load(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to queue')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _joiningWaitlist = false);
      }
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

    final light = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFE8EEF5),
    );

    return Theme(
      data: light,
      child: Builder(
        builder: (context) {
          final onSurface = Theme.of(context).colorScheme.onSurface;
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.arenaName),
              backgroundColor: Colors.white,
              foregroundColor: onSurface,
              surfaceTintColor: Colors.white,
            ),
            body: RefreshIndicator(
              onRefresh: () => _load(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_loading) const LinearProgressIndicator(minHeight: 2),
                  if (_loading) const SizedBox(height: 8),
                  if (_globalSportsBlockReason != null) ...[
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade800),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _globalSportsBlockReason!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Card(
                    color: Colors.white,
                    child: ListTile(
                      leading: Icon(
                        occupied ? Icons.lock_clock : Icons.check_circle_outline,
                        color: onSurface,
                      ),
                      title: Text(
                        occupied ? 'Occupied' : 'Free',
                        style: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        occupied
                            ? 'Currently active booking is running'
                            : 'Court free: you can request 1-hour booking',
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                      trailing: IconButton(
                        onPressed: _loading ? null : () => _load(),
                        icon: Icon(Icons.refresh, color: onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rule: if approved and not checked-in within 10 min, booking is cancelled and cooldown applies.',
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: onSurface),
                    decoration: InputDecoration(
                      labelText: 'Your name',
                      hintText: 'Enter full name',
                      filled: true,
                      fillColor: Colors.white,
                      labelStyle: TextStyle(color: Colors.grey.shade800),
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      border: const OutlineInputBorder(),
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
                    onPressed: _loading ||
                            _joiningWaitlist ||
                            _globalSportsBlockReason != null
                        ? null
                        : _joinWaitlist,
                    icon: const Icon(Icons.queue),
                    label: Text(_joiningWaitlist ? 'Joining...' : 'Join queue'),
                  ),
                  if (my != null) ...[
                    const SizedBox(height: 10),
                    Card(
                      color: Colors.white,
                      child: ListTile(
                        title: Text(
                          'Your booking: $myStatus',
                          style: TextStyle(
                            color: onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Admin approval is required before check-in.',
                          style: TextStyle(color: Colors.grey.shade800),
                        ),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ],
                  if (myWaitIndex >= 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Your waitlist position: ${myWaitIndex + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ],
                  Divider(color: Colors.grey.shade400),
                  Text(
                    'Pending requests queue',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  if (_pendingBookings.isEmpty)
                    Text(
                      'No pending requests',
                      style: TextStyle(color: Colors.grey.shade800),
                    )
                  else
                    ..._pendingBookings.asMap().entries.map(
                      (entry) {
                        final idx = entry.key;
                        final w = entry.value;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.indigo.shade100,
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade900,
                              ),
                            ),
                          ),
                          title: Text(
                            (w['user_email'] ?? '').toString(),
                            style: TextStyle(color: Colors.grey.shade900),
                          ),
                          subtitle: Text(
                            (w['booking_time'] ?? '').toString(),
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Waitlist',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  if (_waitlist.isEmpty)
                    Text(
                      'No one in waitlist',
                      style: TextStyle(color: Colors.grey.shade800),
                    )
                  else
                    ..._waitlist.asMap().entries.map(
                      (entry) {
                        final idx = entry.key;
                        final w = entry.value;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.indigo.shade100,
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade900,
                              ),
                            ),
                          ),
                          title: Text(
                            (w['user_email'] ?? '').toString(),
                            style: TextStyle(color: Colors.grey.shade900),
                          ),
                          subtitle: Text(
                            (w['created_at'] ?? '').toString(),
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        );
                      },
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

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session_manager.dart';

class ManageSports extends StatefulWidget {
  const ManageSports({super.key});

  @override
  State<ManageSports> createState() => _ManageSportsState();
}

class _ManageSportsState extends State<ManageSports> {
  final _supabase = Supabase.instance.client;
  final _blockEmailCtrl = TextEditingController();

  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> _cooldowns = [];
  bool _loading = true;
  bool _loadingCooldowns = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
    _reloadCooldowns();
  }

  @override
  void dispose() {
    _blockEmailCtrl.dispose();
    super.dispose();
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

  Future<void> _reloadCooldowns() async {
    setState(() => _loadingCooldowns = true);
    try {
      final data = await _supabase.from('sports_cooldowns').select();
      if (!mounted) return;
      final list = List<Map<String, dynamic>>.from(data as List);
      list.sort((a, b) {
        final ta = DateTime.tryParse('${a['blocked_until'] ?? ''}');
        final tb = DateTime.tryParse('${b['blocked_until'] ?? ''}');
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });
      if (!mounted) return;
      setState(() {
        _cooldowns = list;
        _loadingCooldowns = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCooldowns = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load blocks: $e')),
      );
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_reload(), _reloadCooldowns()]);
  }

  String _fmt(DateTime dt) {
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _fmtDateTime(DateTime dt) {
    final l = dt.toLocal();
    return '${l.day}/${l.month}/${l.year} ${_fmt(l)}';
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
      } catch (_) {}

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

  Future<void> _pickBlockUntilAndApply() async {
    final email = _blockEmailCtrl.text.trim().toLowerCase();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a user email')),
      );
      return;
    }

    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;

    final local = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final untilUtc = local.toUtc();

    if (!untilUtc.isAfter(DateTime.now().toUtc())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Block end must be in the future')),
      );
      return;
    }

    try {
      await _supabase.from('sports_cooldowns').upsert({
        'user_email': email,
        'blocked_until': untilUtc.toIso8601String(),
      });
      if (!mounted) return;
      _blockEmailCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User cannot request sports until ${_fmtDateTime(untilUtc.toLocal())}',
          ),
        ),
      );
      await _reloadCooldowns();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save block: $e')),
      );
    }
  }

  Future<void> _clearCooldown(String userEmail) async {
    try {
      await _supabase
          .from('sports_cooldowns')
          .delete()
          .eq('user_email', userEmail);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Block removed')),
      );
      await _reloadCooldowns();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Remove failed: $e')),
      );
    }
  }

  Widget _buildApprovalsBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load bookings.\n$_error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final pending = _allBookings
        .where((b) => (b['status'] ?? '').toString() == 'pending')
        .toList();

    if (pending.isEmpty) {
      return RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No pending bookings')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pending.length,
        itemBuilder: (context, i) {
          final b = pending[i];
          final arena = (b['arena_name'] ?? '').toString();
          final next = _nextAvailableForArena(arena, _allBookings);
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
    );
  }

  Widget _buildBlocksBody() {
    if (_loadingCooldowns) {
      return const Center(child: CircularProgressIndicator());
    }

    final now = DateTime.now().toUtc();

    return RefreshIndicator(
      onRefresh: _reloadCooldowns,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Blocked users cannot request new sports bookings until the end time below (same rule as missed check-in cooldowns).',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _blockEmailCtrl,
            decoration: const InputDecoration(
              labelText: 'Student / staff email',
              border: OutlineInputBorder(),
              hintText: 'user@example.edu',
            ),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _pickBlockUntilAndApply,
              icon: const Icon(Icons.block),
              label: const Text('Block until date & time…'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Active blocks (${_cooldowns.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_cooldowns.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('No manual blocks. Users only see cooldowns after a missed check-in.')),
            )
          else
            ..._cooldowns.map((row) {
              final email = (row['user_email'] ?? '').toString();
              final until = DateTime.tryParse(
                '${row['blocked_until'] ?? ''}',
              );
              final untilUtc = until?.toUtc();
              final active =
                  untilUtc != null && untilUtc.isAfter(now);
              return Card(
                child: ListTile(
                  title: Text(email.isEmpty ? '—' : email),
                  subtitle: Text(
                    untilUtc == null
                        ? 'Invalid date'
                        : 'Until ${_fmtDateTime(untilUtc.toLocal())} (${active ? 'active' : 'expired'})',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove block',
                    onPressed: email.isEmpty
                        ? null
                        : () => _clearCooldown(email),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = (SessionManager.role ?? '').trim().toLowerCase();
    final canApprove = role == 'admin';
    if (!canApprove) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sports approvals')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Only administrators can manage sports approvals and booking blocks.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sports'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Approvals'),
              Tab(text: 'Booking blocks'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: (_loading && _loadingCooldowns) ? null : _refreshAll,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildApprovalsBody(),
            _buildBlocksBody(),
          ],
        ),
      ),
    );
  }
}

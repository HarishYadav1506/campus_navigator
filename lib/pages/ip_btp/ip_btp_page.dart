import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/session_manager.dart';

class IpBtpPage extends StatefulWidget {
  const IpBtpPage({super.key});

  @override
  State<IpBtpPage> createState() => _IpBtpPageState();
}

class _IpBtpPageState extends State<IpBtpPage> {

  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> slots = [];
  /// Applications to this professor's IP/BTP announcements (`ip_btp_requests`).
  List<Map<String, dynamic>> _myApplications = [];

  /// Logged-in student's own applications (same table, filtered by email).
  List<Map<String, dynamic>> _myStudentApplications = [];
  String? _requestStatusBusyId;

  final titleController = TextEditingController();
  final detailsController = TextEditingController();
  final cgpaCapController = TextEditingController();

  bool loading = false;
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    loadSlots();
    _loadMyApplications();
    _loadStudentApplications();
  }

  // LOAD SLOTS FROM SUPABASE
  Future<void> loadSlots() async {
    try {

      final data = await supabase
          .from('ip_btp_slots')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        slots = List<Map<String, dynamic>>.from(data);
      });

    } catch (e) {
      print("Error loading slots: $e");
    }
  }

  String _slotTitleForId(Object? slotId) {
    if (slotId == null) return 'Unknown slot';
    final id = slotId.toString();
    for (final s in slots) {
      if (s['id'].toString() == id) {
        return (s['title'] ?? 'Slot').toString();
      }
    }
    return 'Slot $id';
  }

  /// Student applications where this prof is linked (by `professor_email` or by owning the slot).
  Future<void> _loadMyApplications() async {
    final role = SessionManager.role;
    final isProf = role == 'professor' || role == 'prof';
    if (!isProf) return;

    final profEmail = (SessionManager.email ?? '').trim().toLowerCase();
    if (profEmail.isEmpty) return;

    try {
      final byEmail = await supabase
          .from('ip_btp_requests')
          .select()
          .eq('professor_email', profEmail);

      final mySlotRows = await supabase
          .from('ip_btp_slots')
          .select('id')
          .eq('professor_email', profEmail);
      final slotIds = (mySlotRows as List)
          .map((r) => (r as Map)['id'])
          .where((id) => id != null)
          .toList();

      List<Map<String, dynamic>> bySlot = [];
      if (slotIds.isNotEmpty) {
        final rows = await supabase
            .from('ip_btp_requests')
            .select()
            .inFilter('slot_id', slotIds);
        bySlot = List<Map<String, dynamic>>.from(rows as List);
      }

      final emailList = List<Map<String, dynamic>>.from(byEmail as List);
      final seen = <String>{};
      final merged = <Map<String, dynamic>>[];
      void addUnique(Map<String, dynamic> row) {
        final id = (row['id'] ?? '').toString();
        if (id.isEmpty) return;
        if (seen.add(id)) merged.add(row);
      }

      for (final r in emailList) {
        addUnique(Map<String, dynamic>.from(r));
      }
      for (final r in bySlot) {
        addUnique(Map<String, dynamic>.from(r));
      }

      merged.sort((a, b) {
        final ta = (a['created_at'] ?? a['id'] ?? '').toString();
        final tb = (b['created_at'] ?? b['id'] ?? '').toString();
        return tb.compareTo(ta);
      });

      if (!mounted) return;
      setState(() => _myApplications = merged);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load applications: $e')),
        );
      }
    }
  }

  Future<void> _loadStudentApplications() async {
    if (SessionManager.role != 'student') return;

    final email = (SessionManager.email ?? '').trim().toLowerCase();
    if (email.isEmpty) return;

    try {
      final rows = await supabase
          .from('ip_btp_requests')
          .select()
          .eq('student_email', email)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _myStudentApplications =
            List<Map<String, dynamic>>.from(rows as List);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load your applications: $e')),
        );
      }
    }
  }

  Future<void> _setApplicationStatus(String id, String status) async {
    setState(() => _requestStatusBusyId = id);
    try {
      await supabase.from('ip_btp_requests').update({
        'status': status,
        'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);

      if (!mounted) return;
      await _loadMyApplications();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved'
                ? 'Application approved'
                : 'Application rejected',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _requestStatusBusyId = null);
      }
    }
  }

  // ADD SLOT (PROFESSOR)
  Future<void> addSlot() async {

    final title = titleController.text.trim();
    final details = detailsController.text.trim();
    final capText = cgpaCapController.text.trim();
    final cap = double.tryParse(capText);

    if (title.isEmpty || details.isEmpty || capText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter title, details, and CGPA cap")),
      );
      return;
    }

    if (cap == null || cap < 0 || cap > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid CGPA cap (0-10)")),
      );
      return;
    }

    final profEmail = SessionManager.email;
    if (profEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login again.")),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {

      await supabase.from('ip_btp_slots').insert({
        'title': title,
        'details': details,
        'professor_email': profEmail,
        'cgpa_cap': cap,
      });

      titleController.clear();
      detailsController.clear();
      cgpaCapController.clear();

      await loadSlots();
      await _loadMyApplications();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Slot added successfully")),
      );

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );

    }

    setState(() {
      loading = false;
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    detailsController.dispose();
    cgpaCapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final role = SessionManager.role;
    final isProf = role == 'professor' || role == 'prof';
    final isStudent = role == 'student';
    final filtered = _search.isEmpty
        ? slots
        : slots.where((s) {
            final title = (s['title'] ?? '').toString().toLowerCase();
            final details = (s['details'] ?? '').toString().toLowerCase();
            final prof = (s['professor_email'] ?? '').toString().toLowerCase();
            final q = _search.toLowerCase();
            return title.contains(q) || details.contains(q) || prof.contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("IP / BTP"),
        actions: [
          if (isProf || isStudent)
            IconButton(
              tooltip: isProf ? 'Refresh slots & applications' : 'Refresh',
              onPressed: () async {
                await loadSlots();
                if (isProf) await _loadMyApplications();
                if (isStudent) await _loadStudentApplications();
              },
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                  Row(
                    children: [
                      Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.school_outlined,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "IP / BTP",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              isProf
                                  ? "Announce IP/BTP topics with minimum CGPA."
                                  : "Browse announcements and apply if you meet the CGPA.",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Search
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _search = v.trim()),
                    decoration: const InputDecoration(
                      hintText: "Search slots, professor, details...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Professor office slots'),
                        avatar: const Icon(Icons.schedule, size: 18),
                        onPressed: () => Navigator.pushNamed(context, '/prof_slots'),
                      ),
                      if (isProf)
                        const Chip(
                          label: Text('Prof: create & replicate slots'),
                        ),
                      if (isStudent)
                        const Chip(
                          label: Text('Student: search & book professor slot'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (isStudent) ...[
                    _StudentApplicationsCard(
                      applications: _myStudentApplications,
                      slotTitleForId: _slotTitleForId,
                    ),
                    const SizedBox(height: 10),
                  ],

                  // PROFESSOR FORM
                  if (isProf) ...[
                    buildProfForm(),
                    const SizedBox(height: 10),
                    _ProfApplicationsCard(
                      applications: _myApplications,
                      slotTitleForId: _slotTitleForId,
                      onDecision: _setApplicationStatus,
                      busyRequestId: _requestStatusBusyId,
                    ),
                    const SizedBox(height: 10),
                  ],

                  // ANNOUNCEMENT LIST (scrolls with the rest of the page)
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text("No IP/BTP slots announced yet"),
                      ),
                    )
                  else
                    for (var index = 0; index < filtered.length; index++) ...[
                      if (index > 0) const SizedBox(height: 10),
                      _IpBtpSlotCard(
                        slot: filtered[index],
                        isStudent: isStudent,
                        onApply: () async {
                          await Navigator.pushNamed(
                            context,
                            '/apply_ip',
                            arguments: filtered[index],
                          );
                          if (mounted) {
                            await _loadStudentApplications();
                          }
                        },
                      ),
                    ],
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }

  // PROFESSOR SLOT CREATION FORM
  Widget buildProfForm() {

    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  "Release a new slot",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Slot title",
                prefixIcon: Icon(Icons.title_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: detailsController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Details",
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: cgpaCapController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Minimum CGPA required",
                hintText: "e.g. 7.5",
                prefixIcon: Icon(Icons.bar_chart_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : addSlot,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: loading
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.add_circle_outline,
                            key: ValueKey('icon'),
                            size: 18,
                          ),
                  ),
                  label: const Text("Publish announcement"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _ipBtpRequestStatus(Map<String, dynamic> r) {
  final s = (r['status'] ?? 'pending').toString().trim().toLowerCase();
  if (s == 'approved' || s == 'rejected' || s == 'pending') return s;
  return 'pending';
}

class _StudentApplicationsCard extends StatelessWidget {
  const _StudentApplicationsCard({
    required this.applications,
    required this.slotTitleForId,
  });

  final List<Map<String, dynamic>> applications;
  final String Function(Object? slotId) slotTitleForId;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'My applications',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Chip(
                  label: Text('${applications.length}'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Status of your IP/BTP applications to announced slots.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            if (applications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'You have not applied yet.',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: applications.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final r = applications[i];
                  final status = _ipBtpRequestStatus(r);
                  final title = slotTitleForId(r['slot_id']);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        _IpBtpStatusChip(status: status),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfApplicationsCard extends StatelessWidget {
  const _ProfApplicationsCard({
    required this.applications,
    required this.slotTitleForId,
    required this.onDecision,
    required this.busyRequestId,
  });

  final List<Map<String, dynamic>> applications;
  final String Function(Object? slotId) slotTitleForId;
  final Future<void> Function(String id, String status) onDecision;
  final String? busyRequestId;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inbox_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Student applications',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Chip(
                  label: Text('${applications.length}'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Applications submitted to your announcements (from ip_btp_requests).',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            if (applications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'No applications yet.',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: applications.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final r = applications[i];
                  final id = (r['id'] ?? '').toString();
                  final name = (r['student_name'] ?? '—').toString();
                  final email = (r['student_email'] ?? '—').toString();
                  final cg = r['student_cg'];
                  final desc = (r['description'] ?? '').toString();
                  final slotId = r['slot_id'];
                  final title = slotTitleForId(slotId);
                  final status = _ipBtpRequestStatus(r);
                  final busy = busyRequestId == id;
                  // Avoid ListTile here: its fixed subtitle height overflows when
                  // stacking email, topic, CGPA, description, chip, and actions.
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(email, style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('Topic: $title'),
                        if (cg != null) ...[
                          const SizedBox(height: 2),
                          Text('CGPA: $cg'),
                        ],
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            desc,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                        const SizedBox(height: 10),
                        _IpBtpStatusChip(status: status),
                        if (status == 'pending' && id.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          if (busy)
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                height: 28,
                                width: 28,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 4,
                              runSpacing: 0,
                              alignment: WrapAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => onDecision(id, 'approved'),
                                  child: const Text('Approve'),
                                ),
                                TextButton(
                                  onPressed: () => onDecision(id, 'rejected'),
                                  child: const Text('Reject'),
                                ),
                              ],
                            ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _IpBtpStatusChip extends StatelessWidget {
  const _IpBtpStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = status[0].toUpperCase() + status.substring(1);
    Color bg;
    Color fg = Colors.white;
    switch (status) {
      case 'approved':
        bg = Colors.green.withOpacity(0.25);
        fg = Colors.lightGreenAccent.shade100;
        break;
      case 'rejected':
        bg = Colors.red.withOpacity(0.25);
        fg = Colors.redAccent.shade100;
        break;
      default:
        bg = Colors.orange.withOpacity(0.25);
        fg = Colors.orange.shade100;
    }
    return Chip(
      label: Text(label, style: TextStyle(color: fg, fontSize: 12)),
      backgroundColor: bg,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _IpBtpSlotCard extends StatelessWidget {
  const _IpBtpSlotCard({
    required this.slot,
    required this.isStudent,
    required this.onApply,
  });

  final Map<String, dynamic> slot;
  final bool isStudent;
  final Future<void> Function() onApply;

  @override
  Widget build(BuildContext context) {
    final cap = slot['cgpa_cap'];
    final capText = cap == null ? '—' : '$cap';
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    (slot['title'] ?? '').toString(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (isStudent)
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () async => onApply(),
                      child: const Text('Apply'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              (slot['details'] ?? '').toString(),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: Icons.person_outline,
                  label: (slot['professor_email'] ?? '—').toString(),
                ),
                _MetaChip(
                  icon: Icons.bar_chart_outlined,
                  label: 'CGPA cap: $capText',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
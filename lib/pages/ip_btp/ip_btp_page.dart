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
    final isProf = role == 'professor';
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
      appBar: AppBar(title: const Text("IP / BTP")),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
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
                                  ? "Release slots with a CGPA cap."
                                  : "Browse slots and apply if you meet the cap.",
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

                  // PROFESSOR FORM
                  if (isProf) ...[
                    buildProfForm(),
                    const SizedBox(height: 10),
                  ],

                  // SLOT LIST
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text("No IP/BTP slots announced yet"))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {

                              final slot = filtered[index];
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              (slot['title'] ?? '').toString(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                          if (isStudent)
                                            SizedBox(
                                              height: 38,
                                              child: ElevatedButton(
                                                onPressed: () {

                                                  Navigator.pushNamed(
                                                    context,
                                                    '/apply_ip',
                                                    arguments: slot,
                                                  );

                                                },
                                                child: const Text("Apply"),
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
                                            label:
                                                (slot['professor_email'] ?? '—')
                                                    .toString(),
                                          ),
                                          _MetaChip(
                                            icon: Icons.bar_chart_outlined,
                                            label: "CGPA cap: $capText",
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
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
                  label: const Text("Publish slot"),
                ),
              ),
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
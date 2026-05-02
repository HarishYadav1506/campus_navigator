import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/session_manager.dart';

class ApplyIpPage extends StatefulWidget {
  const ApplyIpPage({super.key});

  @override
  State<ApplyIpPage> createState() => _ApplyIpPageState();
}

class _ApplyIpPageState extends State<ApplyIpPage> {
  final supabase = Supabase.instance.client;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final cgController = TextEditingController();
  final descController = TextEditingController();

  bool loading = false;
  bool _submitted = false;

  Future<void> submitApplication() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final cgText = cgController.text.trim();
    final desc = descController.text.trim();

    if (name.isEmpty || email.isEmpty || cgText.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    double? cg = double.tryParse(cgText);

    if (cg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid CGPA")),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is! Map) {
        throw Exception("Missing slot details");
      }
      final slot = Map<String, dynamic>.from(args);
      final slotId = slot['id'];
      final professorEmail = (slot['professor_email'] ?? '').toString();
      final capRaw = slot['cgpa_cap'];
      final cap = capRaw is num ? capRaw.toDouble() : double.tryParse('$capRaw');

      if (slotId == null) {
        throw Exception("Missing slot id");
      }
      if (cap != null && cg < cap) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Your CGPA ($cg) is below the required cap ($cap) for this slot.",
            ),
          ),
        );
        return;
      }

      await supabase.from('ip_btp_requests').insert({
        'student_name': name,
        'student_email': email,
        'student_cg': cg,
        'description': desc,
        'slot_id': slotId,
        'professor_email': professorEmail.isEmpty ? null : professorEmail,
      });

      emailController.clear();
      cgController.clear();
      descController.clear();

      if (mounted) {
        setState(() => _submitted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Application submitted successfully")),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission failed: $e")),
      );
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    cgController.dispose();
    descController.dispose();
    super.dispose();
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    int minLines = 1,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionEmail = SessionManager.email;
    if (nameController.text.isEmpty) {
      nameController.text = sessionEmail == null ? '' : sessionEmail.split('@').first;
    }
    if (emailController.text.isEmpty && sessionEmail != null) {
      emailController.text = sessionEmail;
    }

    final args = ModalRoute.of(context)?.settings.arguments;
    final slot = args is Map ? Map<String, dynamic>.from(args) : null;
    final capRaw = slot?['cgpa_cap'];
    final cap = capRaw is num ? capRaw.toDouble() : double.tryParse('$capRaw');
    final profEmail = (slot?['professor_email'] ?? '—').toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Apply for IP / BTP"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (slot != null)
              Card(
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
                      Text(
                        (slot['title'] ?? 'Slot').toString(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Professor: $profEmail",
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white70),
                      ),
                      if (cap != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Minimum CGPA required: $cap",
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (slot != null) const SizedBox(height: 12),
            buildTextField(
              controller: nameController,
              label: "Name",
            ),
            const SizedBox(height: 16),
            buildTextField(
              controller: emailController,
              label: "College Email",
            ),

            const SizedBox(height: 16),

            buildTextField(
              controller: cgController,
              label: "CGPA",
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            buildTextField(
              controller: descController,
              label: "Description",
              minLines: 3,
              maxLines: 5,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: loading ? null : submitApplication,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: loading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          _submitted ? Icons.check_circle_outline : Icons.send,
                          key: const ValueKey('icon'),
                          size: 18,
                        ),
                ),
                label: const Text(
                  "Submit Application",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
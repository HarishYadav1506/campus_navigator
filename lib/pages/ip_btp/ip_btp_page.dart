import 'package:flutter/material.dart';
import '../../core/session_manager.dart';

class IpBtpPage extends StatefulWidget {
  const IpBtpPage({super.key});

  @override
  State<IpBtpPage> createState() => _IpBtpPageState();
}

class _IpBtpPageState extends State<IpBtpPage> {
  final List<_ProfSlot> _slots = [];

  final titleController = TextEditingController();
  final detailsController = TextEditingController();

  void _addSlot() {
    if (titleController.text.isEmpty || detailsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter title and details")),
      );
      return;
    }
    setState(() {
      _slots.add(
        _ProfSlot(
          title: titleController.text,
          details: detailsController.text,
        ),
      );
      titleController.clear();
      detailsController.clear();
    });
  }

  void _bookSlot(_ProfSlot slot) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Requested IP/BTP slot: ${slot.title}")),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = SessionManager.role;
    final isProf = role == 'prof';
    final isStudent = role == 'student';

    return Scaffold(
      appBar: AppBar(title: const Text("IP / BTP")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "IP/BTP slots & announcements",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              isProf
                  ? "Add your daily slots and announcements. Students will see them below."
                  : "Browse professor IP/BTP slots and request one.",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (!SessionManager.isLoggedIn)
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/auth'),
                child: const Text("Login to manage / book IP/BTP"),
              ),
            const SizedBox(height: 12),
            if (isProf) _buildProfForm(),
            const SizedBox(height: 12),
            Expanded(
              child: _slots.isEmpty
                  ? const Center(
                      child: Text("No IP/BTP slots announced yet."),
                    )
                  : ListView.separated(
                      itemCount: _slots.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final slot = _slots[index];
                        return Card(
                          child: ListTile(
                            title: Text(slot.title),
                            subtitle: Text(slot.details),
                            trailing: isStudent
                                ? TextButton(
                                    onPressed: () => _bookSlot(slot),
                                    child: const Text("Book"),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Add new slot / announcement",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: "Title (e.g. IP slot 4–5pm)",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: detailsController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: "Details / instructions",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _addSlot,
            child: const Text("Add slot"),
          ),
        ),
      ],
    );
  }
}

class _ProfSlot {
  final String title;
  final String details;

  _ProfSlot({required this.title, required this.details});
}


import 'package:flutter/material.dart';
import '../../core/session_manager.dart';

class BookSlotPage extends StatefulWidget {
  const BookSlotPage({super.key});

  @override
  State<BookSlotPage> createState() => _BookSlotPageState();
}

class _BookSlotPageState extends State<BookSlotPage> {
  TimeOfDay? _from;
  TimeOfDay? _to;
  bool _repeatDaily = true;
  final purposeController = TextEditingController();

  final List<_CalBooking> _bookings = [];

  Future<void> _pickTime(bool isFrom) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _from = picked;
        } else {
          _to = picked;
        }
      });
    }
  }

  void _book() {
    if (_from == null || _to == null || purposeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select from, to, and purpose")),
      );
      return;
    }

    final booking = _CalBooking(
      from: _from!,
      to: _to!,
      purpose: purposeController.text,
      by: SessionManager.email ?? "demo@iiitd.ac.in",
      repeatDaily: _repeatDaily,
    );

    setState(() {
      _bookings.add(booking);
    });

    // Here you can integrate Google Calendar API by creating an event
    // for [booking]. This requires OAuth credentials configured separately.

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Slot booked${_repeatDaily ? " (repeating daily)" : ""} in calendar",
        ),
      ),
    );
  }

  @override
  void dispose() {
    purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detailed Slot Booking')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select time and purpose",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(true),
                    child: Text(
                      _from == null
                          ? "From time"
                          : "From: ${_from!.format(context)}",
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(false),
                    child: Text(
                      _to == null
                          ? "To time"
                          : "To: ${_to!.format(context)}",
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Switch(
                  value: _repeatDaily,
                  onChanged: (v) {
                    setState(() {
                      _repeatDaily = v;
                    });
                  },
                ),
                const SizedBox(width: 4),
                const Text("Repeat daily (office hours)"),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: purposeController,
              decoration: const InputDecoration(
                labelText: "Purpose (class, meet, sports, etc.)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _book,
                child: const Text("Book in calendar"),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Your demo bookings",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _bookings.isEmpty
                  ? const Center(
                      child: Text("No bookings yet."),
                    )
                  : ListView.separated(
                      itemCount: _bookings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final b = _bookings[index];
                        return ListTile(
                          leading: const Icon(Icons.schedule),
                          title: Text(
                              "${b.from.format(context)} - ${b.to.format(context)}"),
                          subtitle: Text(
                            "${b.purpose}\nBy: ${b.by}${b.repeatDaily ? "\nRepeats daily" : ""}",
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalBooking {
  final TimeOfDay from;
  final TimeOfDay to;
  final String purpose;
  final String by;
  final bool repeatDaily;

  _CalBooking({
    required this.from,
    required this.to,
    required this.purpose,
    required this.by,
    required this.repeatDaily,
  });
}


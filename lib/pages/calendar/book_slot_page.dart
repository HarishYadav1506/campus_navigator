import 'package:flutter/material.dart';
import '../../core/session_manager.dart';

class BookSlotPage extends StatefulWidget {
  const BookSlotPage({super.key});

  @override
  State<BookSlotPage> createState() => _BookSlotPageState();
}

class _BookSlotPageState extends State<BookSlotPage> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _from;
  TimeOfDay? _to;
  bool _repeatDaily = true;
  final purposeController = TextEditingController();

  final List<_CalBooking> _bookings = [];
  bool get _isProf => SessionManager.role == 'prof' || SessionManager.role == 'professor';

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
      date: _selectedDate,
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

  void _copyFromPreviousDay() {
    final prev = _selectedDate.subtract(const Duration(days: 1));
    final previousBookings = _bookings.where((b) =>
        b.date.year == prev.year && b.date.month == prev.month && b.date.day == prev.day);
    if (previousBookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No slots on previous day to copy")),
      );
      return;
    }
    setState(() {
      _bookings.addAll(
        previousBookings.map((b) => _CalBooking(
              from: b.from,
              to: b.to,
              date: _selectedDate,
              purpose: b.purpose,
              by: b.by,
              repeatDaily: b.repeatDaily,
            )),
      );
    });
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
              "Select date, time, and purpose",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
              ),
            ),
            if (_isProf) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _copyFromPreviousDay,
                  icon: const Icon(Icons.copy_all_outlined),
                  label: const Text("Copy previous day"),
                ),
              ),
            ],
            const SizedBox(height: 8),
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
              "Day schedule",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
                child: _bookings.where((b) =>
                            b.date.year == _selectedDate.year &&
                            b.date.month == _selectedDate.month &&
                            b.date.day == _selectedDate.day)
                        .isEmpty
                  ? const Center(
                      child: Text("No bookings yet."),
                    )
                  : ListView.separated(
                      itemCount: _bookings
                          .where((b) =>
                              b.date.year == _selectedDate.year &&
                              b.date.month == _selectedDate.month &&
                              b.date.day == _selectedDate.day)
                          .length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final dayBookings = _bookings
                            .where((b) =>
                                b.date.year == _selectedDate.year &&
                                b.date.month == _selectedDate.month &&
                                b.date.day == _selectedDate.day)
                            .toList();
                        final b = dayBookings[index];
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
  final DateTime date;
  final String purpose;
  final String by;
  final bool repeatDaily;

  _CalBooking({
    required this.from,
    required this.to,
    required this.date,
    required this.purpose,
    required this.by,
    required this.repeatDaily,
  });
}


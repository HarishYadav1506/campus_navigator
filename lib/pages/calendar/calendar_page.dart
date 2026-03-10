import 'package:flutter/material.dart';
import '../../core/session_manager.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDay = DateTime.now();

  // Simple in-memory demo slots map: date (yyyy-mm-dd) -> list of strings
  final Map<String, List<String>> _slots = {};

  String _keyForDate(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  void _addSlot() {
    final key = _keyForDate(_selectedDay);
    setState(() {
      _slots.putIfAbsent(key, () => []);
      _slots[key]!.add("Meeting / class at ${_selectedDay.hour.toString().padLeft(2, '0')}:00");
    });
  }

  @override
  Widget build(BuildContext context) {
    final key = _keyForDate(_selectedDay);
    final todaySlots = _slots[key] ?? [];
    final role = SessionManager.role ?? 'guest';

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar & Slots')),
      floatingActionButton: SessionManager.isLoggedIn
          ? FloatingActionButton.extended(
              onPressed: _addSlot,
              icon: const Icon(Icons.add),
              label: const Text("Add slot"),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Logged in as $role",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _buildDateRow(),
            const SizedBox(height: 16),
            Text(
              "Slots for ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: todaySlots.isEmpty
                  ? const Center(
                      child: Text("No slots booked for this day."),
                    )
                  : ListView.separated(
                      itemCount: todaySlots.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final slot = todaySlots[index];
                        return ListTile(
                          leading: const Icon(Icons.event_available),
                          title: Text(slot),
                          subtitle: const Text("Demo calendar entry"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              setState(() {
                                todaySlots.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/book_slot');
                },
                child: const Text("Open detailed slot booking"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow() {
    final dates = List<DateTime>.generate(
      7,
      (index) => DateTime.now().add(Duration(days: index)),
    );

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.day == _selectedDay.day &&
              date.month == _selectedDay.month &&
              date.year == _selectedDay.year;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = date;
              });
            },
            child: Container(
              width: 70,
              decoration: BoxDecoration(
                color: isSelected ? Colors.indigo : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][date.weekday % 7],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.indigo,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.indigo,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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


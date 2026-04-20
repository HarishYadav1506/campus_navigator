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

  void _addSlot() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    
    final key = _keyForDate(_selectedDay);
    setState(() {
      _slots.putIfAbsent(key, () => []);
      _slots[key]!.add("Meeting at ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}");
    });
  }

  void _copyPreviousDay() {
    final prevDay = _selectedDay.subtract(const Duration(days: 1));
    final prevKey = _keyForDate(prevDay);
    final currKey = _keyForDate(_selectedDay);
    
    final prevSlots = _slots[prevKey] ?? [];
    if (prevSlots.isNotEmpty) {
      setState(() {
        _slots.putIfAbsent(currKey, () => []);
        // Avoid adding exact duplicates if copied multiple times
        for (var s in prevSlots) {
          if (!_slots[currKey]!.contains(s)) {
            _slots[currKey]!.add(s);
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Copied ${prevSlots.length} slots from yesterday.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No slots to copy from yesterday.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = _keyForDate(_selectedDay);
    final todaySlots = _slots[key] ?? [];
    final role = SessionManager.role ?? 'guest';
    final isProf = role == 'prof' || role == 'professor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar & Slots'),
        actions: [
          if (isProf)
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: "Copy from previous day",
              onPressed: _copyPreviousDay,
            ),
        ],
      ),
      floatingActionButton: isProf
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
              child: ListView.builder(
                itemCount: 24,
                itemBuilder: (context, index) {
                  final hourStr = index.toString().padLeft(2, '0');
                  
                  // Simple check: if the event string contains "at HH:", it belongs here
                  final eventsInHour = todaySlots.where((s) => s.contains("at $hourStr:")).toList();
                  
                  return Container(
                    constraints: const BoxConstraints(minHeight: 60),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.white12),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 60,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "$hourStr:00",
                              style: const TextStyle(color: Colors.white60),
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1, color: Colors.white12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: eventsInHour.map((e) => Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(e, style: const TextStyle(fontSize: 13))),
                                    if (isProf)
                                      InkWell(
                                        child: const Icon(Icons.close, size: 14),
                                        onTap: () {
                                          setState(() {
                                            todaySlots.remove(e);
                                          });
                                        },
                                      )
                                  ],
                                ),
                              )).toList(),
                            ),
                          ),
                        ),
                      ],
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
      14, // show 14 days
      (index) => DateTime.now().subtract(const Duration(days: 3)).add(Duration(days: index)),
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
                color: isSelected ? Colors.indigo : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade200.withOpacity(isSelected ? 1.0 : 0.2)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][date.weekday % 7],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white,
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

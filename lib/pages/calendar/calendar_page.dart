import 'package:flutter/material.dart';
import '../../core/session_manager.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDay = DateTime.now();
  final Map<String, List<_DaySlot>> _slots = {};

  String _keyForDate(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  bool get _isProf => SessionManager.role == 'prof' || SessionManager.role == 'professor';

  void _addSlot() {
    final key = _keyForDate(_selectedDay);
    setState(() {
      _slots.putIfAbsent(key, () => []);
      _slots[key]!.add(
        _DaySlot(
          title: _isProf ? 'Office hour / class' : 'Meeting / class',
          startHour: 10,
          endHour: 11,
        ),
      );
    });
  }

  void _copyPreviousDayToToday() {
    final prev = _selectedDay.subtract(const Duration(days: 1));
    final prevKey = _keyForDate(prev);
    final currentKey = _keyForDate(_selectedDay);
    final prevSlots = _slots[prevKey] ?? [];
    if (prevSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No slots found on previous day')),
      );
      return;
    }
    setState(() {
      _slots[currentKey] = prevSlots
          .map((s) => _DaySlot(title: s.title, startHour: s.startHour, endHour: s.endHour))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final key = _keyForDate(_selectedDay);
    final todaySlots = _slots[key] ?? <_DaySlot>[];
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
            if (_isProf)
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _copyPreviousDayToToday,
                  icon: const Icon(Icons.copy_all_outlined),
                  label: const Text('Copy previous day'),
                ),
              ),
            if (_isProf) const SizedBox(height: 8),
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
                      itemCount: 24,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final active = todaySlots.where((s) => index >= s.startHour && index < s.endHour).toList();
                        return ListTile(
                          leading: const Icon(Icons.schedule),
                          title: Text('${index.toString().padLeft(2, '0')}:00 - ${(index + 1).toString().padLeft(2, '0')}:00'),
                          subtitle: active.isEmpty ? const Text("Free") : Text(active.map((e) => e.title).join(', ')),
                          trailing: active.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () {
                                    setState(() {
                                      _slots[key]!.removeWhere((s) => index >= s.startHour && index < s.endHour);
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

class _DaySlot {
  final String title;
  final int startHour;
  final int endHour;

  _DaySlot({
    required this.title,
    required this.startHour,
    required this.endHour,
  });
}


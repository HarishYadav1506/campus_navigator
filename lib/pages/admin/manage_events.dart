import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageEvents extends StatefulWidget {
  const ManageEvents({super.key});

  @override
  State<ManageEvents> createState() => _ManageEventsState();
}

class _ManageEventsState extends State<ManageEvents> {
  final _supabase = Supabase.instance.client;
  final _title = TextEditingController();
  final _type = TextEditingController(text: 'Seminar');
  final _location = TextEditingController();
  final _desc = TextEditingController();
  DateTime _dateTime = DateTime.now().add(const Duration(days: 1));
  bool _loading = false;

  Future<void> _addEvent() async {
    if (_title.text.trim().isEmpty || _location.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await _supabase.from('events').insert({
        'title': _title.text.trim(),
        'type': _type.text.trim(),
        'location': _location.text.trim(),
        'description': _desc.text.trim(),
        'date_time': _dateTime.toUtc().toIso8601String(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event added')),
      );
      _title.clear();
      _location.clear();
      _desc.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _type.dispose();
    _location.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Events')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 10),
          TextField(controller: _type, decoration: const InputDecoration(labelText: 'Type')),
          const SizedBox(height: 10),
          TextField(controller: _location, decoration: const InputDecoration(labelText: 'Location')),
          const SizedBox(height: 10),
          TextField(
            controller: _desc,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text('Date: ${_dateTime.toLocal()}'),
            trailing: TextButton(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDate: _dateTime,
                );
                if (d == null || !mounted) return;
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_dateTime),
                );
                if (t == null) return;
                setState(() {
                  _dateTime = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                });
              },
              child: const Text('Pick'),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loading ? null : _addEvent,
            child: Text(_loading ? 'Saving...' : 'Add event / seminar'),
          ),
        ],
      ),
    );
  }
}

/* old placeholder
class ManageEvents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Events')),
      body: Center(child: Text('Manage Events')),
    );
  }
}
*/

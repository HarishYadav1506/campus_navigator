import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session_manager.dart';

/// Professor creates a **one-hour office hour** chat room. Students join with [class_code].
class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _classCodeController = TextEditingController();
  final TextEditingController _maxMembersController = TextEditingController(text: '40');
  bool _creating = false;
  DateTime? _startLocal;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _classCodeController.dispose();
    _maxMembersController.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (!mounted || time == null) return;
    setState(() {
      _startLocal = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _create() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter room name')),
      );
      return;
    }
    if (_classCodeController.text.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join code must be at least 4 characters')),
      );
      return;
    }
    if (_startLocal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a start date and time')),
      );
      return;
    }
    final maxMembers = int.tryParse(_maxMembersController.text.trim());
    if (maxMembers == null || maxMembers < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Max participants must be at least 2')),
      );
      return;
    }

    final profEmail = (SessionManager.email ?? '').trim().toLowerCase();
    if (profEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again')),
      );
      return;
    }

    final startUtc = _startLocal!.toUtc();
    final endUtc = startUtc.add(const Duration(hours: 1));

    setState(() => _creating = true);
    try {
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('email', profEmail)
          .maybeSingle();
      if (profile == null) {
        throw Exception('Professor profile not found. Log in again.');
      }
      final room = await _supabase
          .from('chat_rooms')
          .insert({
            'name': _nameController.text.trim(),
            'description': _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
            'is_group': true,
            'type': 'office_hours',
            'class_code': _classCodeController.text.trim().toUpperCase(),
            'created_by_email': profEmail,
            'max_members': maxMembers,
            'office_hours_start': startUtc.toIso8601String(),
            'office_hours_end': endUtc.toIso8601String(),
          })
          .select('id')
          .single();

      await _supabase.from('chat_room_members').insert({
        'room_id': room['id'],
        'user_id': profile['id'],
        'role': 'owner',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Office hour room created. Share code ${_classCodeController.text.trim().toUpperCase()}',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create room: $e')),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  String get _startLabel {
    final s = _startLocal;
    if (s == null) return 'Not set';
    return '${s.year}-${s.month.toString().padLeft(2, '0')}-${s.day.toString().padLeft(2, '0')} '
        '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')} (local)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New office hour room')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Chat unlocks at the start time and locks automatically after one hour. '
            'Students add the room with the join code (no global directory).',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Room title (e.g. COL106 — Week 5 doubts)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _classCodeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Join code',
              hintText: 'e.g. COL106W5',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Start (local time)'),
            subtitle: Text(_startLabel),
            trailing: TextButton(
              onPressed: _pickStart,
              child: const Text('Choose'),
            ),
          ),
          const Text(
            'Session length is fixed at 1 hour after start.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maxMembersController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Max participants',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _creating ? null : _create,
              child: Text(_creating ? 'Creating…' : 'Create office hour room'),
            ),
          ),
        ],
      ),
    );
  }
}

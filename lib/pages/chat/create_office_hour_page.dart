import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/session_manager.dart';

class CreateOfficeHourPage extends StatefulWidget {
  const CreateOfficeHourPage({super.key});

  @override
  State<CreateOfficeHourPage> createState() => _CreateOfficeHourPageState();
}

class _CreateOfficeHourPageState extends State<CreateOfficeHourPage> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final code = _codeController.text.trim();
    final name = _nameController.text.trim();
    final capacityText = _capacityController.text.trim();
    
    if (code.isEmpty || name.isEmpty || capacityText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter Class Code, Group Name, and Max Capacity")),
      );
      return;
    }
    
    final capacity = int.tryParse(capacityText);
    if (capacity == null || capacity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid numeric capacity")),
      );
      return;
    }

    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End time must be after start time")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final email = SessionManager.email;
      if (email == null) throw Exception("Not logged in");

      final userRes = await _supabase
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      if (userRes == null) throw Exception("User profile not found in 'users'");
      final userId = userRes['id'];

      final encodedName = jsonEncode({
        'code': code,
        'name': name,
        'capacity': capacity,
      });

      // Create room
      final roomRes = await _supabase.from('chat_rooms').insert({
        'name': encodedName,
        'type': 'office_hours',
        'is_group': true,
        'office_hours_start': startDateTime.toUtc().toIso8601String(),
        'office_hours_end': endDateTime.toUtc().toIso8601String(),
      }).select().single();

      final roomId = roomRes['id'];

      // Add prof as member
      await _supabase.from('chat_room_members').insert({
        'room_id': roomId,
        'user_id': userId,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Office Hour '$name' created!")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Office Hour')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Share the Class Code with your students so they can join."),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: "Class Code (e.g., CS101)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Group Name (e.g., Intro to CS)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _capacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Max Capacity (e.g., 50)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("Start: ${_startDate.toString().split(' ')[0]} ${_startTime.format(context)}"),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d == null) return;
                final t = await showTimePicker(
                  context: context,
                  initialTime: _startTime,
                );
                if (t == null) return;
                setState(() {
                  _startDate = d;
                  _startTime = t;
                  _endDate = d; // Sync end date for convenience
                });
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("End: ${_endDate.toString().split(' ')[0]} ${_endTime.format(context)}"),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _endDate,
                  firstDate: _startDate,
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d == null) return;
                final t = await showTimePicker(
                  context: context,
                  initialTime: _endTime,
                );
                if (t == null) return;
                setState(() {
                  _endDate = d;
                  _endTime = t;
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _create,
                child: Text(_loading ? "Creating..." : "Create Office Hour"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

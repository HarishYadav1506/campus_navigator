import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session_manager.dart';

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
  final TextEditingController _startHourController = TextEditingController(text: '8');
  final TextEditingController _endHourController = TextEditingController(text: '20');
  final TextEditingController _maxMembersController = TextEditingController(text: '80');
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _classCodeController.dispose();
    _startHourController.dispose();
    _endHourController.dispose();
    _maxMembersController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter group name")),
      );
      return;
    }
    if (_classCodeController.text.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Class code must be at least 4 characters")),
      );
      return;
    }
    final startHour = int.tryParse(_startHourController.text.trim());
    final endHour = int.tryParse(_endHourController.text.trim());
    final maxMembers = int.tryParse(_maxMembersController.text.trim());
    if (startHour == null || endHour == null || startHour < 0 || endHour > 23 || startHour >= endHour) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid messaging hours (0-23)")),
      );
      return;
    }
    if (maxMembers == null || maxMembers < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Max chat size must be at least 2")),
      );
      return;
    }

    final profEmail = (SessionManager.email ?? '').trim().toLowerCase();
    if (profEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login again")),
      );
      return;
    }

    setState(() => _creating = true);
    try {
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('email', profEmail)
          .maybeSingle();
      if (profile == null) {
        throw Exception('Professor profile not found');
      }
      final room = await _supabase
          .from('chat_rooms')
          .insert({
            'name': _nameController.text.trim(),
            'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
            'is_group': true,
            'type': 'classroom',
            'class_code': _classCodeController.text.trim().toUpperCase(),
            'created_by_email': profEmail,
            'message_start_hour': startHour,
            'message_end_hour': endHour,
            'max_members': maxMembers,
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
        SnackBar(content: Text("Class group '${_nameController.text.trim()}' created")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not create class group: $e")),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Class Group')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Group name (course)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _classCodeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: "Class code",
                hintText: "e.g. IP101A",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Description (optional)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startHourController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Start hour",
                      hintText: "8",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _endHourController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "End hour",
                      hintText: "20",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maxMembersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Chat size limit",
                hintText: "80",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _creating ? null : _create,
                child: Text(_creating ? "Creating..." : "Create class group"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


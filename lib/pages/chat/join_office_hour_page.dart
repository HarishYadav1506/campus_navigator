import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/session_manager.dart';

class JoinOfficeHourPage extends StatefulWidget {
  const JoinOfficeHourPage({super.key});

  @override
  State<JoinOfficeHourPage> createState() => _JoinOfficeHourPageState();
}

class _JoinOfficeHourPageState extends State<JoinOfficeHourPage> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _codeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a Class Code")),
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

      // Fetch all office hours rooms
      final roomsRes = await _supabase
          .from('chat_rooms')
          .select('id, name')
          .eq('type', 'office_hours');

      Map<String, dynamic>? targetRoom;
      int maxCapacity = 999;
      String groupName = code;

      for (var room in roomsRes) {
        try {
          final decoded = jsonDecode(room['name']);
          if (decoded['code'] == code) {
            targetRoom = room;
            maxCapacity = decoded['capacity'] ?? 999;
            groupName = decoded['name'] ?? code;
            break;
          }
        } catch (_) {
          // Fallback if not JSON
          if (room['name'] == code) {
            targetRoom = room;
            break;
          }
        }
      }

      if (targetRoom == null) {
        throw Exception("Invalid Class Code. Room not found.");
      }

      final roomId = targetRoom['id'];

      // Check capacity
      final membersRes = await _supabase
          .from('chat_room_members')
          .select('id')
          .eq('room_id', roomId);
      
      final currentMembersCount = membersRes.length;

      // Check if already joined
      final checkRes = await _supabase
          .from('chat_room_members')
          .select()
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .maybeSingle();

      if (checkRes == null) {
        if (currentMembersCount >= maxCapacity) {
            throw Exception("This Office Hour chat has reached its maximum capacity of $maxCapacity.");
        }
        // Join room
        await _supabase.from('chat_room_members').insert({
          'room_id': roomId,
          'user_id': userId,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Successfully joined '$groupName'")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Join failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Office Hour')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Enter the Class Code provided by your professor to join their Office Hour chat."),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: "Class Code",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _join,
                child: Text(_loading ? "Joining..." : "Join Chat"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

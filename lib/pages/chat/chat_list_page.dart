import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/session_manager.dart';
import 'chat_screen.dart';
import 'create_office_hour_page.dart';
import 'join_office_hour_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final _supabase = Supabase.instance.client;
  List<_ChatItem> _chats = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final email = SessionManager.email ?? "demo@iiitd.ac.in";

    final userRes = await _supabase
        .from('users')
        .select('id')
        .eq('email', email)
        .maybeSingle();
    if (userRes == null) return;
    final userId = userRes['id'];

    final rooms = await _supabase
        .from('chat_rooms')
        .select('id,name,is_group,type,office_hours_start,office_hours_end,chat_room_members!inner(user_id)')
        .eq('chat_room_members.user_id', userId)
        .eq('type', 'office_hours');

    final list = (rooms as List).map((r) {
      final map = r as Map<String, dynamic>;
      
      String parsedName = map['name'] as String;
      String parsedCode = parsedName;
      int parsedCapacity = 999;
      
      try {
        final decoded = jsonDecode(parsedName);
        parsedName = decoded['name'] ?? parsedName;
        parsedCode = decoded['code'] ?? parsedCode;
        parsedCapacity = decoded['capacity'] ?? 999;
      } catch (_) {}

      return _ChatItem(
        id: map['id'].toString(),
        name: parsedName,
        code: parsedCode,
        capacity: parsedCapacity,
        isGroup: (map['is_group'] ?? true) as bool,
        type: (map['type'] ?? 'normal') as String,
        officeHoursStart: map['office_hours_start'] == null
            ? null
            : DateTime.tryParse(map['office_hours_start'].toString()),
        officeHoursEnd: map['office_hours_end'] == null
            ? null
            : DateTime.tryParse(map['office_hours_end'].toString()),
      );
    }).toList();

    setState(() {
      _chats = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = SessionManager.email ?? "demo@iiitd.ac.in";
    final role = SessionManager.role ?? 'student';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Office Hour Chats'),
      ),
      body: _chats.isEmpty
          ? const Center(child: Text("No office hour chats yet."))
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: _chats.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final chat = _chats[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(chat.name.isNotEmpty
                        ? chat.name[0].toUpperCase()
                        : '?'),
                  ),
                  title: Text(chat.name),
                  subtitle: Text("Class Code: ${chat.code} | Max Size: ${chat.capacity}"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatId: chat.id,
                          chatName: chat.name,
                          currentUserEmail: email,
                          isGroup: true,
                          chatType: 'office_hours',
                          officeHoursStart: chat.officeHoursStart,
                          officeHoursEnd: chat.officeHoursEnd,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (role == 'prof' || role == 'professor') {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateOfficeHourPage()),
            );
          } else {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JoinOfficeHourPage()),
            );
          }
          _loadChats();
        },
        icon: Icon(role == 'prof' || role == 'professor'
            ? Icons.add
            : Icons.group_add),
        label: Text(role == 'prof' || role == 'professor'
            ? "Create Office Hour"
            : "Join Office Hour"),
      ),
    );
  }
}

class _ChatItem {
  final String id;
  final String name;
  final String code;
  final int capacity;
  final bool isGroup;
  final String type;
  final DateTime? officeHoursStart;
  final DateTime? officeHoursEnd;

  _ChatItem({
    required this.id,
    required this.name,
    required this.code,
    required this.capacity,
    required this.isGroup,
    required this.type,
    this.officeHoursStart,
    this.officeHoursEnd,
  });
}

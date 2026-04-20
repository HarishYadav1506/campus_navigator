import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/session_manager.dart';
import 'chat_screen.dart';
import 'create_group_page.dart';

class ChatListPage extends StatefulWidget {
  ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final _supabase = Supabase.instance.client;
  List<_ChatItem> _chats = [];
  List<_ChatItem> _filtered = [];
  String _search = '';
  String _filter = 'all'; // all, groups, personal, office

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final email = SessionManager.email ?? "demo@iiitd.ac.in";
    final role = SessionManager.role ?? 'student';

    // Expect tables: chat_rooms, chat_room_members.
    final userRes = await _supabase
        .from('profiles')
        .select('id')
        .eq('email', email)
        .maybeSingle();
    if (userRes == null) return;
    final userId = userRes['id'];

    final rooms = await _supabase
        .from('chat_rooms')
        .select('id,name,is_group,type,office_hours_start,office_hours_end,chat_room_members!inner(user_id)')
        .eq('chat_room_members.user_id', userId);

    final list = (rooms as List)
        .map((r) => _ChatItem.fromMap(r as Map<String, dynamic>))
        .where((chat) {
      if (role == 'student') {
        // Students: only personal + office hours
        return !chat.isGroup || chat.type == 'office_hours';
      }
      return true;
    }).toList();

    setState(() {
      _chats = list;
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filtered = _chats.where((c) {
      if (_filter == 'groups' && !c.isGroup) return false;
      if (_filter == 'personal' && c.isGroup) return false;
      if (_filter == 'office' && c.type != 'office_hours') return false;
      if (_search.isNotEmpty &&
          !c.name.toLowerCase().contains(_search.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final email = SessionManager.email ?? "demo@iiitd.ac.in";
    final role = SessionManager.role ?? 'student';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          if (role == 'prof' || role == 'professor')
            IconButton(
              icon: const Icon(Icons.group_add),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateGroupPage()),
                );
                _loadChats();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search chats or users",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _search = value;
                  _applyFilters();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', 'all'),
                  _filterChip('Groups', 'groups'),
                  _filterChip('Personal', 'personal'),
                  _filterChip('Office hours', 'office'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text("No chats yet."))
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final chat = _filtered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(chat.name.isNotEmpty
                              ? chat.name[0].toUpperCase()
                              : '?'),
                        ),
                        title: Text(chat.name),
                        subtitle: Text(
                          chat.isGroup
                              ? (chat.type == 'office_hours'
                                  ? "Office hours group"
                                  : "Group chat")
                              : "Direct message",
                        ),
                        trailing: chat.isPinned
                            ? const Icon(Icons.push_pin, size: 18)
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chatId: chat.id,
                                chatName: chat.name,
                                currentUserEmail: email,
                                isGroup: chat.isGroup,
                                chatType: chat.type,
                                officeHoursStart: chat.officeHoursStart,
                                officeHoursEnd: chat.officeHoursEnd,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _filter = value;
            _applyFilters();
          });
        },
      ),
    );
  }
}

class _ChatItem {
  final String id;
  final String name;
  final bool isGroup;
  final String type; // normal, office_hours
  final bool isPinned;
  final DateTime? officeHoursStart;
  final DateTime? officeHoursEnd;

  _ChatItem({
    required this.id,
    required this.name,
    required this.isGroup,
    required this.type,
    this.isPinned = false,
    this.officeHoursStart,
    this.officeHoursEnd,
  });

  factory _ChatItem.fromMap(Map<String, dynamic> map) {
    return _ChatItem(
      id: map['id'].toString(),
      name: map['name'] as String,
      isGroup: (map['is_group'] ?? true) as bool,
      type: (map['type'] ?? 'normal') as String,
      isPinned: (map['is_pinned'] ?? false) as bool,
      officeHoursStart: map['office_hours_start'] == null
          ? null
          : DateTime.tryParse(map['office_hours_start'].toString()),
      officeHoursEnd: map['office_hours_end'] == null
          ? null
          : DateTime.tryParse(map['office_hours_end'].toString()),
    );
  }
}


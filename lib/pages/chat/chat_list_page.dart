import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session_manager.dart';
import 'chat_screen.dart';
import 'create_group_page.dart';

/// Code-based chats only: [classroom] (legacy) and [office_hours]. No global lobby.
class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final _supabase = Supabase.instance.client;
  List<_ChatItem> _chats = [];
  List<_ChatItem> _filtered = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final email = (SessionManager.email ?? '').trim().toLowerCase();
    if (email.isEmpty) {
      setState(() {
        _chats = [];
        _applyFilters();
      });
      return;
    }

    try {
      final userRes = await _supabase
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      if (userRes == null) {
        setState(() {
          _chats = [];
          _applyFilters();
        });
        return;
      }
      final userId = userRes['id'];

      final rooms = await _supabase
          .from('chat_rooms')
          .select(
            'id,name,is_group,type,class_code,max_members,message_start_hour,message_end_hour,office_hours_start,office_hours_end,created_by_email,chat_room_members!inner(user_id)',
          )
          .eq('chat_room_members.user_id', userId);

      final list = (rooms as List)
          .map((r) => _ChatItem.fromMap(r as Map<String, dynamic>))
          .where((chat) {
            final t = chat.type;
            return t == 'classroom' || t == 'office_hours';
          }).toList();

      if (!mounted) return;
      setState(() {
        _chats = list;
        _applyFilters();
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _chats = [];
          _applyFilters();
        });
      }
    }
  }

  Future<String?> _currentProfileId() async {
    final email = (SessionManager.email ?? '').trim().toLowerCase();
    if (email.isEmpty) return null;
    final me = await _supabase
        .from('profiles')
        .select('id')
        .eq('email', email)
        .maybeSingle();
    if (me == null) return null;
    return me['id']?.toString();
  }

  Future<void> _leaveChat(_ChatItem chat) async {
    final role = (SessionManager.role ?? '').trim().toLowerCase();
    final isProf = role == 'prof' || role == 'professor';
    final email = (SessionManager.email ?? '').trim().toLowerCase();
    if (email.isEmpty) return;

    final profOwnsRoom =
        isProf && chat.createdByEmail.trim().toLowerCase() == email;
    final msg = profOwnsRoom
        ? 'You are the professor for this room. Leaving will delete the entire chat room for everyone. Continue?'
        : 'Leave "${chat.name}"?';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave chat'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(profOwnsRoom ? 'Delete room' : 'Leave'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;

    try {
      final messenger = ScaffoldMessenger.of(context);
      if (profOwnsRoom) {
        await _supabase.from('chat_rooms').delete().eq('id', chat.id);
      } else {
        final profileId = await _currentProfileId();
        if (profileId == null) throw Exception('Profile not found');
        await _supabase
            .from('chat_room_members')
            .delete()
            .eq('room_id', chat.id)
            .eq('user_id', profileId);
      }
      if (!mounted) return;
      await _loadChats();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            profOwnsRoom
                ? 'Professor left. Room deleted.'
                : 'You left the chat room.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not leave chat: $e')),
      );
    }
  }

  Future<void> _joinByCode() async {
    final codeCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Join with code'),
        content: TextField(
          controller: codeCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Join code',
            hintText: 'From your professor',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeCtrl.text.trim().toUpperCase();
              if (code.isEmpty) return;
              try {
                final email = (SessionManager.email ?? '').trim().toLowerCase();
                final me = await _supabase
                    .from('profiles')
                    .select('id')
                    .eq('email', email)
                    .maybeSingle();
                if (me == null) {
                  throw Exception('Profile not found. Log in again.');
                }
                final room = await _supabase
                    .from('chat_rooms')
                    .select('id,max_members,type')
                    .eq('class_code', code)
                    .maybeSingle();
                if (room == null) throw Exception('Invalid code');
                final t = (room['type'] ?? '').toString();
                if (t != 'classroom' && t != 'office_hours') {
                  throw Exception('This code is not valid for student chat');
                }
                final countRes = await _supabase
                    .from('chat_room_members')
                    .select('id')
                    .eq('room_id', room['id']);
                final memberCount = (countRes as List).length;
                final cap = (room['max_members'] is num)
                    ? (room['max_members'] as num).toInt()
                    : 100;
                if (memberCount >= cap) throw Exception('Room is full');
                await _supabase.from('chat_room_members').upsert({
                  'room_id': room['id'],
                  'user_id': me['id'],
                  'role': 'student',
                });
                if (!mounted) return;
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                await _loadChats();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Joined room')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not join: $e')),
                );
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    _filtered = _chats.where((c) {
      if (_search.isNotEmpty &&
          !c.name.toLowerCase().contains(_search.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  String _subtitle(_ChatItem chat) {
    if (chat.type == 'office_hours') {
      final a = chat.officeHoursStart;
      final b = chat.officeHoursEnd;
      if (a != null && b != null) {
        return 'Office hours • ${_fmt(a)} – ${_fmt(b)}';
      }
      return 'Office hours (timed)';
    }
    return 'Course chat • hours ${chat.messageStartHour ?? '?'}-${chat.messageEndHour ?? '?'}';
  }

  String _fmt(DateTime dt) {
    final l = dt.toLocal();
    return '${l.month}/${l.day} ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final email = (SessionManager.email ?? '').trim().toLowerCase();
    final role = (SessionManager.role ?? '').trim().toLowerCase();
    final isProf = role == 'prof' || role == 'professor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          if (!isProf)
            IconButton(
              icon: const Icon(Icons.key_outlined),
              tooltip: 'Join with code',
              onPressed: _joinByCode,
            ),
          if (isProf)
            IconButton(
              icon: const Icon(Icons.add_comment_outlined),
              tooltip: 'New office hour room',
              onPressed: () async {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const CreateGroupPage(),
                  ),
                );
                _loadChats();
              },
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search your rooms',
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              isProf
                  ? 'Create a timed office hour room, then share the join code.'
                  : 'Use the key icon or “Join with code” to enter a room.',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
          if (!isProf)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: OutlinedButton.icon(
                onPressed: _joinByCode,
                icon: const Icon(Icons.key, size: 18),
                label: const Text('Join with code'),
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        isProf
                            ? 'No rooms yet. Create an office hour room to get a join code.'
                            : 'No chats yet. Join with a code from your professor.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final chat = _filtered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            chat.name.isNotEmpty
                                ? chat.name[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(chat.name),
                        subtitle: Text(_subtitle(chat)),
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => ChatScreen(
                                chatId: chat.id,
                                chatName: chat.name,
                                currentUserEmail: email,
                                isGroup: chat.isGroup,
                                chatType: chat.type,
                                createdByEmail: chat.createdByEmail,
                                maxMembers: chat.maxMembers,
                                messageStartHour: chat.messageStartHour,
                                messageEndHour: chat.messageEndHour,
                                officeHoursStart: chat.officeHoursStart,
                                officeHoursEnd: chat.officeHoursEnd,
                              ),
                            ),
                          ).then((_) => _loadChats());
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.exit_to_app),
                          tooltip: 'Leave chat',
                          onPressed: () => _leaveChat(chat),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChatItem {
  final String id;
  final String name;
  final bool isGroup;
  final String type;
  final bool isPinned;
  final int? maxMembers;
  final int? messageStartHour;
  final int? messageEndHour;
  final DateTime? officeHoursStart;
  final DateTime? officeHoursEnd;
  final String createdByEmail;

  _ChatItem({
    required this.id,
    required this.name,
    required this.isGroup,
    required this.type,
    this.isPinned = false,
    this.maxMembers,
    this.messageStartHour,
    this.messageEndHour,
    this.officeHoursStart,
    this.officeHoursEnd,
    this.createdByEmail = '',
  });

  factory _ChatItem.fromMap(Map<String, dynamic> map) {
    return _ChatItem(
      id: map['id'].toString(),
      name: map['name'] as String,
      isGroup: (map['is_group'] ?? true) as bool,
      type: (map['type'] ?? 'normal') as String,
      isPinned: (map['is_pinned'] ?? false) as bool,
      maxMembers: map['max_members'] is num
          ? (map['max_members'] as num).toInt()
          : null,
      messageStartHour: map['message_start_hour'] is num
          ? (map['message_start_hour'] as num).toInt()
          : null,
      messageEndHour: map['message_end_hour'] is num
          ? (map['message_end_hour'] as num).toInt()
          : null,
      officeHoursStart: map['office_hours_start'] == null
          ? null
          : DateTime.tryParse(map['office_hours_start'].toString()),
      officeHoursEnd: map['office_hours_end'] == null
          ? null
          : DateTime.tryParse(map['office_hours_end'].toString()),
      createdByEmail: (map['created_by_email'] ?? '').toString(),
    );
  }
}

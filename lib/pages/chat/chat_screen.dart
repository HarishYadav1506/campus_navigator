import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/session_manager.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final String currentUserEmail;
  final bool isGroup;
  final String chatType;
  final int? maxMembers;
  final int? messageStartHour;
  final int? messageEndHour;
  final DateTime? officeHoursStart;
  final DateTime? officeHoursEnd;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.currentUserEmail,
    required this.isGroup,
    this.chatType = 'normal',
    this.maxMembers,
    this.messageStartHour,
    this.messageEndHour,
    this.officeHoursStart,
    this.officeHoursEnd,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _muted = false;
  bool _pinned = false;
  String _search = '';

  bool get _isStudent {
    final r = (SessionManager.role ?? '').trim().toLowerCase();
    return r == 'student';
  }

  bool get _canStudentSend {
    if (!_isStudent) return true;
    if (widget.chatType == 'classroom') {
      final start = widget.messageStartHour;
      final end = widget.messageEndHour;
      if (start == null || end == null) return true;
      final hour = DateTime.now().hour;
      return hour >= start && hour <= end;
    }
    if (widget.chatType != 'office_hours') return true;
    final start = widget.officeHoursStart;
    final end = widget.officeHoursEnd;
    if (start == null || end == null) return true;
    final now = DateTime.now().toUtc();
    return now.isAfter(start.toUtc()) && now.isBefore(end.toUtc());
  }

  Future<void> _sendMessage() async {
    if (!_canStudentSend) return;
    if (_controller.text.trim().isEmpty) return;
    try {
      await supabase.from('chat_messages').insert({
        'room_id': widget.chatId,
        'sender_email': widget.currentUserEmail.trim().toLowerCase(),
        'content': _controller.text.trim(),
      });
      if (mounted) {
        setState(() {
          _controller.clear();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final msgStream = supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', widget.chatId)
        .order('created_at', ascending: true);

    final studentBanner = ((widget.chatType == 'office_hours' || widget.chatType == 'classroom') && _isStudent)
        ? Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 18, color: Colors.white70),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.chatType == 'classroom'
                          ? (_canStudentSend
                              ? 'Class chat is active right now.'
                              : 'Message window closed. Student messages are time-restricted.')
                          : (_canStudentSend
                              ? 'Office hours are active. Send your doubts now.'
                              : 'Office hours have ended. You cannot send doubts now.'),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.chatName),
            if (widget.isGroup) const SizedBox(width: 6),
            if (widget.isGroup)
              const Icon(Icons.groups_2_outlined, size: 18),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_muted ? Icons.notifications_off : Icons.notifications),
            tooltip: _muted ? "Unmute" : "Mute chat",
            onPressed: () {
              setState(() {
                _muted = !_muted;
              });
            },
          ),
          IconButton(
            icon: Icon(_pinned ? Icons.push_pin : Icons.push_pin_outlined),
            tooltip: "Pin chat",
            onPressed: () {
              setState(() {
                _pinned = !_pinned;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          studentBanner,
          if (widget.chatType == 'classroom')
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Text(
                'Group capacity: ${widget.maxMembers ?? '-'} • Time window: ${widget.messageStartHour ?? '-'}:00 to ${widget.messageEndHour ?? '-'}:00',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search messages in this chat",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: msgStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snapshot.data ?? const <Map<String, dynamic>>[];
                final filtered = _search.trim().isEmpty
                    ? all
                    : all.where((m) {
                        final c = (m['content'] ?? '').toString().toLowerCase();
                        return c.contains(_search.trim().toLowerCase());
                      }).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  reverse: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final msg = filtered[filtered.length - 1 - index];
                    final sender = (msg['sender_email'] ?? '').toString();
                    final text = (msg['content'] ?? '').toString();
                    final createdAtRaw = msg['created_at'];
                    final createdAt = createdAtRaw == null
                        ? null
                        : DateTime.tryParse(createdAtRaw.toString());
                    final isMe = sender.toLowerCase() ==
                        widget.currentUserEmail.trim().toLowerCase();
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.indigo : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(
                                sender,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            Text(text, style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 2),
                            Text(
                              createdAt == null
                                  ? ''
                                  : '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.white60, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: _canStudentSend,
                    decoration: InputDecoration(
                      hintText: _canStudentSend ? 'Type a message...' : 'Office hours ended',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _canStudentSend ? _sendMessage : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


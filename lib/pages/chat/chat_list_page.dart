import 'package:flutter/material.dart';
import '../../core/session_manager.dart';
import 'chat_screen.dart';
import 'create_group_page.dart';

class ChatListPage extends StatelessWidget {
  ChatListPage({super.key});

  final List<_ChatItem> chats = [
    _ChatItem(name: "Campus Announcements", isGroup: true),
    _ChatItem(name: "Sports Committee", isGroup: true),
    _ChatItem(name: "Prof. Sharma", isGroup: false),
  ];

  @override
  Widget build(BuildContext context) {
    final email = SessionManager.email ?? "demo@iiitd.ac.in";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateGroupPage()),
              );
            },
          )
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: chats.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final chat = chats[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(chat.name[0]),
            ),
            title: Text(chat.name),
            subtitle: Text(chat.isGroup ? "Group chat" : "Direct message"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chatName: chat.name,
                    currentUserEmail: email,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatItem {
  final String name;
  final bool isGroup;

  _ChatItem({required this.name, required this.isGroup});
}


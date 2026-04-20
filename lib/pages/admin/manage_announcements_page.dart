import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session_manager.dart';

class ManageAnnouncementsPage extends StatefulWidget {
  const ManageAnnouncementsPage({super.key});

  @override
  State<ManageAnnouncementsPage> createState() => _ManageAnnouncementsPageState();
}

class _ManageAnnouncementsPageState extends State<ManageAnnouncementsPage> {
  final _supabase = Supabase.instance.client;
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _category = 'notices';
  String _filter = 'all';
  bool _loading = false;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = _filter == 'all'
        ? await _supabase
            .from('announcements')
            .select()
            .order('created_at', ascending: false)
        : await _supabase
            .from('announcements')
            .select()
            .eq('category', _filter)
            .order('created_at', ascending: false);
    if (!mounted) return;
    setState(() => _items = List<Map<String, dynamic>>.from(rows));
  }

  Future<void> _add() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await _supabase.from('announcements').insert({
        'title': _title.text.trim(),
        'body': _body.text.trim(),
        'category': _category,
        'created_by': SessionManager.email ?? 'admin',
      });
      _title.clear();
      _body.clear();
      await _load();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    await _supabase.from('announcements').delete().eq('id', id);
    await _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage announcements')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 8),
          TextField(
            controller: _body,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Body'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _category,
            items: const [
              DropdownMenuItem(value: 'sports', child: Text('Sports')),
              DropdownMenuItem(value: 'events', child: Text('Events')),
              DropdownMenuItem(value: 'seminars', child: Text('Seminars')),
              DropdownMenuItem(value: 'notices', child: Text('Notices')),
            ],
            onChanged: (v) => setState(() => _category = v ?? 'notices'),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _loading ? null : _add,
            child: Text(_loading ? 'Saving...' : 'Add announcement'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _filter,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All categories')),
              DropdownMenuItem(value: 'sports', child: Text('Sports')),
              DropdownMenuItem(value: 'events', child: Text('Events')),
              DropdownMenuItem(value: 'seminars', child: Text('Seminars')),
              DropdownMenuItem(value: 'notices', child: Text('Notices')),
            ],
            onChanged: (v) {
              setState(() => _filter = v ?? 'all');
              _load();
            },
            decoration: const InputDecoration(labelText: 'Filter'),
          ),
          const SizedBox(height: 8),
          ..._items.map(
            (a) => Card(
              child: ListTile(
                title: Text((a['title'] ?? '').toString()),
                subtitle: Text('[${a['category']}] ${a['body']}'),
                trailing: IconButton(
                  onPressed: () => _delete(a['id'].toString()),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

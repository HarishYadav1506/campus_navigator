import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _supabase = Supabase.instance.client;
  final _name = TextEditingController();
  final _newPass = TextEditingController();
  bool _loading = false;

  String get _email => (SessionManager.email ?? '').trim().toLowerCase();
  bool get _isProf =>
      SessionManager.role == 'prof' || SessionManager.role == 'professor';

  Future<void> _updateName() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await _supabase
          .from('users')
          .update({'name': _name.text.trim()})
          .eq('email', _email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_newPass.text.trim().length < 4) return;
    setState(() => _loading = true);
    try {
      await _supabase
          .from('users')
          .update({'password': _newPass.text.trim()})
          .eq('email', _email);
      _newPass.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _newPass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.alternate_email),
              title: Text(_email.isEmpty ? 'Not logged in' : _email),
              subtitle: Text('Role: ${SessionManager.role ?? 'unknown'}'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Change name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loading ? null : _updateName,
            child: const Text('Save name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPass,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Change password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loading ? null : _updatePassword,
            child: const Text('Update password'),
          ),
          const SizedBox(height: 12),
          if (_isProf)
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/admin'),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Open admin panel'),
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              SessionManager.clear();
              Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

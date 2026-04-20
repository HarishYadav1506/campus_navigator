import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageProfessors extends StatefulWidget {
  const ManageProfessors({super.key});

  @override
  State<ManageProfessors> createState() => _ManageProfessorsState();
}

class _ManageProfessorsState extends State<ManageProfessors> {
  final _supabase = Supabase.instance.client;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _department = TextEditingController();
  bool _loading = false;

  Future<void> _addProfessor() async {
    final name = _name.text.trim();
    final email = _email.text.trim().toLowerCase();
    if (name.isEmpty || email.isEmpty) return;
    setState(() => _loading = true);
    try {
      await _supabase.from('professors_login').insert({
        'name': name,
        'email': email,
        'department': _department.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Professor added')),
      );
      _name.clear();
      _email.clear();
      _department.clear();
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
    _email.dispose();
    _department.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Professors')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Professor name')),
          const SizedBox(height: 10),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'College email')),
          const SizedBox(height: 10),
          TextField(controller: _department, decoration: const InputDecoration(labelText: 'Department')),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _loading ? null : _addProfessor,
            child: Text(_loading ? 'Adding...' : 'Add professor'),
          ),
        ],
      ),
    );
  }
}

/* old placeholder
class ManageProfessors extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Professors')),
      body: Center(child: Text('Manage Professors')),
    );
  }
}
*/

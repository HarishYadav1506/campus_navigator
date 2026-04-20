import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session_manager.dart';
import '../../services/tpo_service.dart';

class TpoAdminPage extends StatefulWidget {
  const TpoAdminPage({super.key});

  @override
  State<TpoAdminPage> createState() => _TpoAdminPageState();
}

class _TpoAdminPageState extends State<TpoAdminPage> {
  final _svc = TpoService(Supabase.instance.client);
  final _company = TextEditingController();
  final _role = TextEditingController();
  final _desc = TextEditingController();
  final _eligibility = TextEditingController();
  final _slots = TextEditingController(text: '10');
  bool _loading = false;

  Future<void> _add() async {
    final slots = int.tryParse(_slots.text.trim()) ?? 0;
    if (_company.text.trim().isEmpty || _role.text.trim().isEmpty || slots < 0) return;
    setState(() => _loading = true);
    try {
      await _svc.addPosting(
        companyName: _company.text.trim(),
        role: _role.text.trim(),
        description: _desc.text.trim(),
        eligibility: _eligibility.text.trim(),
        availableSlots: slots,
        createdBy: SessionManager.email ?? 'admin',
      );
      if (!mounted) return;
      _company.clear();
      _role.clear();
      _desc.clear();
      _eligibility.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Posting added')),
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
    _company.dispose();
    _role.dispose();
    _desc.dispose();
    _eligibility.dispose();
    _slots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TPO Admin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _company, decoration: const InputDecoration(labelText: 'Company')),
          const SizedBox(height: 8),
          TextField(controller: _role, decoration: const InputDecoration(labelText: 'Role')),
          const SizedBox(height: 8),
          TextField(controller: _eligibility, decoration: const InputDecoration(labelText: 'Eligibility')),
          const SizedBox(height: 8),
          TextField(controller: _slots, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Available slots')),
          const SizedBox(height: 8),
          TextField(
            controller: _desc,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loading ? null : _add,
            child: Text(_loading ? 'Saving...' : 'Add posting'),
          ),
        ],
      ),
    );
  }
}

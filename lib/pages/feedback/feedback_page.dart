import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session_manager.dart';
import '../../services/activity_service.dart';
import '../../services/feedback_service.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _svc = FeedbackService(Supabase.instance.client);
  final _activity = ActivityService(Supabase.instance.client);
  final _email = TextEditingController(
    text: (SessionManager.email ?? '').trim().toLowerCase(),
  );
  final _message = TextEditingController();
  String _type = 'issue';
  int _rating = 4;
  bool _loading = false;

  Future<void> _submit() async {
    final email = _email.text.trim().toLowerCase();
    if (email.isEmpty) return;
    if (_message.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await _svc.submit(
        userEmail: email,
        type: 'app',
        subject: _type,
        message: _message.text.trim(),
        rating: _rating,
      );
      await _activity.log(
        userEmail: email,
        action: 'feedback_submit',
        meta: {'type': _type},
      );
      _message.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Your email'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _type,
            items: const [
              DropdownMenuItem(value: 'issue', child: Text('Issue')),
              DropdownMenuItem(value: 'praise', child: Text('Praise')),
            ],
            onChanged: (v) => setState(() => _type = v ?? 'issue'),
            decoration: const InputDecoration(labelText: 'Type'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _message,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Describe your feedback'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Rating:'),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _rating.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '$_rating',
                  onChanged: (v) => setState(() => _rating = v.round()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: Text(_loading ? 'Submitting...' : 'Submit feedback'),
          ),
        ],
      ),
    );
  }
}

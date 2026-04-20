import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _message = TextEditingController();
  String _type = 'issue';
  int _rating = 4;
  bool _loading = false;

  Future<void> _submit() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }
    final userId = user.id;
    if (_message.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await _svc.submit(
        userId: userId,
        type: 'app',
        subject: _type,
        message: _message.text.trim(),
        rating: _rating,
      );
      await _activity.log(
        userId: userId,
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

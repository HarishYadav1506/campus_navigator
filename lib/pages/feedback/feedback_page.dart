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
  final _profEmail = TextEditingController();
  final _courseCode = TextEditingController();
  final _message = TextEditingController();
  String _subjectKind = 'issue';
  int _rating = 4;
  bool _loading = false;

  bool get _isProf {
    final r = (SessionManager.role ?? '').trim().toLowerCase();
    return r == 'prof' || r == 'professor';
  }

  Future<void> _submitStudent() async {
    final email = _email.text.trim().toLowerCase();
    final prof = _profEmail.text.trim().toLowerCase();
    final code = _courseCode.text.trim();
    if (email.isEmpty || prof.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email, professor email, and course code'),
        ),
      );
      return;
    }
    if (_message.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await _svc.submit(
        userEmail: email,
        type: 'course',
        subject: _subjectKind,
        message: _message.text.trim(),
        courseCode: code,
        professorEmail: prof,
        rating: _rating,
      );
      await _activity.log(
        userEmail: email,
        action: 'feedback_submit',
        meta: {'type': 'course', 'course': code},
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
    _profEmail.dispose();
    _courseCode.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isProf) {
      final me = (SessionManager.email ?? '').trim().toLowerCase();
      return Scaffold(
        appBar: AppBar(title: const Text('Course feedback')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: me.isEmpty
              ? Future.value(const [])
              : _svc.fetchForProfessor(me),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = snap.data ?? [];
            if (rows.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No course feedback yet for your email. '
                    'Feedback is matched using the professor email students enter.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              itemBuilder: (context, i) {
                final f = rows[i];
                return Card(
                  child: ListTile(
                    title: Text(
                      '${f['course_code'] ?? '—'} • ${f['subject'] ?? ''}',
                    ),
                    subtitle: Text(
                      '${f['user_email']}\n${f['message']}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Course feedback')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Share feedback about a specific course and professor. '
            'General app issues are reviewed by administrators separately.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Your email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _profEmail,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Professor email (for this course)',
              hintText: 'prof@iiitd.ac.in',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _courseCode,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Course code',
              hintText: 'e.g. COL106',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _subjectKind,
            items: const [
              DropdownMenuItem(value: 'issue', child: Text('Issue / concern')),
              DropdownMenuItem(value: 'praise', child: Text('Praise / positive')),
            ],
            onChanged: (v) => setState(() => _subjectKind = v ?? 'issue'),
            decoration: const InputDecoration(
              labelText: 'Feedback type',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _message,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Your feedback',
              border: OutlineInputBorder(),
            ),
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
            onPressed: _loading ? null : _submitStudent,
            child: Text(_loading ? 'Submitting...' : 'Submit course feedback'),
          ),
        ],
      ),
    );
  }
}

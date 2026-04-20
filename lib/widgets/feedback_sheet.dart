import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/session_manager.dart';
import '../services/engagement_service.dart';

Future<void> showCampusFeedbackSheet(BuildContext context) async {
  final email = TextEditingController(
    text: (SessionManager.email ?? '').trim().toLowerCase(),
  );
  final message = TextEditingController();
  var feedbackType = 'issue';
  int? rating;
  final svc = EngagementService(Supabase.instance.client);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0f172a),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Campus feedback',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: email,
                  decoration: const InputDecoration(
                    labelText: 'Your email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: feedbackType,
                  items: const [
                    DropdownMenuItem(value: 'issue', child: Text('Issue')),
                    DropdownMenuItem(value: 'praise', child: Text('Praise')),
                  ],
                  onChanged: (v) {
                    setModalState(() => feedbackType = v ?? 'issue');
                  },
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: message,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Describe your feedback',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Rating: '),
                    ...List.generate(5, (i) {
                      final v = i + 1;
                      return IconButton(
                        onPressed: () => setModalState(() => rating = v),
                        icon: Icon(
                          rating != null && v <= rating!
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                        ),
                      );
                    }),
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (email.text.trim().isEmpty || message.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fill email and message')),
                      );
                      return;
                    }
                    try {
                      await svc.submitFeedback(
                        email: email.text.trim().toLowerCase(),
                        subject: feedbackType,
                        message: message.text,
                        rating: rating,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Feedback submitted')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        ),
      );
    },
  ).whenComplete(() {
    email.dispose();
    message.dispose();
  });
}

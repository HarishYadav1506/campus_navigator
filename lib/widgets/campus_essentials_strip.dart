import 'package:flutter/material.dart';

import 'feedback_sheet.dart';

class CampusEssentialsStrip extends StatelessWidget {
  const CampusEssentialsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.red.withOpacity(0.35),
                Colors.indigo.withOpacity(0.25),
              ],
            ),
            border: Border.all(color: Colors.white24),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.health_and_safety, color: Colors.white),
            title: const Text('Safety & support', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Emergency, security, medical, report issues'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/campus_support'),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: const Text('Feedback'),
              avatar: const Icon(Icons.feedback_outlined, size: 18),
              onPressed: () => showCampusFeedbackSheet(context),
            ),
            ActionChip(
              label: const Text('Events'),
              avatar: const Icon(Icons.event_note_outlined, size: 18),
              onPressed: () => Navigator.pushNamed(context, '/events'),
            ),
          ],
        ),
      ],
    );
  }
}

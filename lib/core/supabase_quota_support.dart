import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// True when Supabase has restricted the project (storage quota, billing, etc.).
/// Covers Postgrest (DB) and Auth (OTP) error shapes.
bool isSupabaseProjectRestrictedError(Object e) {
  final raw = e.toString();
  return raw.contains('exceed_storage_size_quota') ||
      raw.contains('statusCode: 402') ||
      raw.contains('code: 402') ||
      raw.contains('"code":402');
}

/// Full-screen friendly explanation; use from SnackBar "How to fix" or directly.
Future<void> showSupabaseRestrictedHelpDialog(BuildContext context) async {
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Supabase project is restricted'),
      content: const SingleChildScrollView(
        child: Text(
          'The app is fine — your Supabase backend is paused because storage or disk '
          'is over the project limit (exceed_storage_size_quota, HTTP 402).\n\n'
          'That blocks everything: OTP signup, auth, and database.\n\n'
          'Fix in the browser:\n'
          '1) supabase.com → Dashboard → your project.\n'
          '2) Settings → Usage: check Database vs Storage.\n'
          '3) Free space: Storage → delete unused files; Database → trim large tables.\n'
          '4) Or upgrade / contact Supabase support.\n\n'
          'Until then, use Login with demo@iiitd.ac.in / password123 to try the UI only.',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        FilledButton.icon(
          onPressed: () async {
            Navigator.pop(ctx);
            final ok = await launchUrl(
              Uri.parse('https://supabase.com/dashboard/projects'),
              mode: LaunchMode.externalApplication,
            );
            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Open supabase.com/dashboard in your browser manually.'),
                ),
              );
            }
          },
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Open Supabase'),
        ),
      ],
    ),
  );
}

void showSupabaseRestrictedSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text(
        'Supabase quota exceeded — project is paused. Tap “How to fix”.',
      ),
      action: SnackBarAction(
        label: 'How to fix',
        onPressed: () => showSupabaseRestrictedHelpDialog(context),
      ),
      duration: const Duration(seconds: 8),
    ),
  );
}

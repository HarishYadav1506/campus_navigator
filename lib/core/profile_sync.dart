import 'package:supabase_flutter/supabase_flutter.dart';

/// Ensures a [profiles] row exists for chat membership (join-by-code flow).
Future<void> ensureProfileRow(SupabaseClient client, String email) async {
  final e = email.trim().toLowerCase();
  if (e.isEmpty) return;
  try {
    final existing =
        await client.from('profiles').select('id').eq('email', e).maybeSingle();
    if (existing != null) return;
    await client.from('profiles').insert({'email': e});
  } catch (_) {
    // Table missing or duplicate; ignore so login still works.
  }
}

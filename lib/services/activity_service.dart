import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityService {
  ActivityService(this._client);
  final SupabaseClient _client;

  Future<void> log({
    String? userEmail,
    String? userId,
    required String action,
    Map<String, dynamic>? meta,
  }) async {
    final actor = (userId ?? userEmail ?? '').trim();
    if (actor.isEmpty) return;
    await _client.from('student_activity').insert({
      'user_email': actor,
      'action': action,
      'meta': meta ?? <String, dynamic>{},
    });
  }
}

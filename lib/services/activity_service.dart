import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityService {
  ActivityService(this._client);
  final SupabaseClient _client;

  Future<void> log({
    required String userEmail,
    required String action,
    Map<String, dynamic>? meta,
  }) async {
    await _client.from('student_activity').insert({
      'user_email': userEmail,
      'action': action,
      'meta': meta ?? <String, dynamic>{},
    });
  }
}

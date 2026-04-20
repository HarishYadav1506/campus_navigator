import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackService {
  FeedbackService(this._client);
  final SupabaseClient _client;

  Future<void> submit({
    required String userId,
    required String type,
    required String subject,
    required String message,
    String? courseCode,
    int? rating,
  }) async {
    await _client.from('feedback_entries').insert({
      'user_id': userId,
      'feedback_type': type,
      'subject': subject,
      'message': message,
      'course_code': courseCode,
      'rating': rating,
    });
  }

  Future<List<Map<String, dynamic>>> fetch({String? type}) async {
    final rows = (type != null && type.isNotEmpty)
        ? await _client
            .from('feedback_entries')
            .select()
            .eq('feedback_type', type)
            .order('created_at', ascending: false)
        : await _client
            .from('feedback_entries')
            .select()
            .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }
}

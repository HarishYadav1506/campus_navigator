import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackService {
  FeedbackService(this._client);
  final SupabaseClient _client;

  Future<void> submit({
    required String userEmail,
    required String type,
    required String subject,
    required String message,
    String? courseCode,
    String? professorEmail,
    int? rating,
  }) async {
    await _client.from('feedback_entries').insert({
      'user_email': userEmail,
      'feedback_type': type,
      'subject': subject,
      'message': message,
      'course_code': courseCode,
      'professor_email': professorEmail?.trim().toLowerCase(),
      'rating': rating,
    });
  }

  Future<List<Map<String, dynamic>>> fetchForProfessor(
    String professorEmail,
  ) async {
    final e = professorEmail.trim().toLowerCase();
    final rows = await _client
        .from('feedback_entries')
        .select()
        .eq('feedback_type', 'course')
        .eq('professor_email', e)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
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

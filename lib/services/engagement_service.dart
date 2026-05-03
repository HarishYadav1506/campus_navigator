import 'package:supabase_flutter/supabase_flutter.dart';

class EngagementService {
  EngagementService(this._client);

  final SupabaseClient _client;

  String _e(String email) => email.trim().toLowerCase();

  Stream<List<Map<String, dynamic>>> watchUserStats(String email) {
    return _client
        .from('user_stats')
        .stream(primaryKey: ['user_email'])
        .eq('user_email', _e(email));
  }

  Future<void> awardPoints(String email, int delta, String reason) async {
    await _client.rpc('engagement_award_points', params: {
      'p_email': _e(email),
      'p_delta': delta,
      'p_reason': reason,
    });
  }

  Future<void> recordInterest(String email, String tag) async {
    final t = tag.trim().toLowerCase();
    if (t.isEmpty) return;
    final e = _e(email);
    final now = DateTime.now().toUtc().toIso8601String();
    final existing = await _client
        .from('user_interests')
        .select('weight')
        .eq('user_email', e)
        .eq('tag', t)
        .maybeSingle();
    if (existing == null) {
      await _client.from('user_interests').insert({
        'user_email': e,
        'tag': t,
        'weight': 1,
        'updated_at': now,
      });
    } else {
      final w = (existing['weight'] as num?)?.toInt() ?? 1;
      await _client.from('user_interests').update({
        'weight': w + 1,
        'updated_at': now,
      }).eq('user_email', e).eq('tag', t);
    }
  }

  Future<Map<String, int>> fetchInterestWeights(String email) async {
    final res = await _client
        .from('user_interests')
        .select('tag,weight')
        .eq('user_email', _e(email));
    final out = <String, int>{};
    for (final r in res as List) {
      final m = Map<String, dynamic>.from(r as Map);
      out[(m['tag'] ?? '').toString().toLowerCase()] =
          (m['weight'] as num?)?.toInt() ?? 1;
    }
    return out;
  }

  Future<void> submitFeedback({
    required String email,
    required String subject,
    required String message,
    int? rating,
  }) async {
    final e = _e(email);
    final sub = subject.trim();
    final msg = message.trim();

    // Prefer feedback_entries (admin UI + migrations); campus_feedback is optional legacy.
    try {
      await _client.from('feedback_entries').insert({
        'user_email': e,
        'feedback_type': 'app',
        'subject': sub,
        'message': msg,
        'rating': rating,
      });
    } catch (_) {
      await _client.from('campus_feedback').insert({
        'user_email': e,
        'subject': sub,
        'message': msg,
        'rating': rating,
      });
    }

    try {
      await awardPoints(email, 3, 'feedback_submitted');
    } catch (_) {
      // Points RPC/tables optional — feedback row should still count as success.
    }
  }
}

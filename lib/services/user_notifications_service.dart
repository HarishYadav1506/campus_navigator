import 'package:supabase_flutter/supabase_flutter.dart';

class UserNotificationsService {
  UserNotificationsService(this._client);

  final SupabaseClient _client;

  Stream<List<Map<String, dynamic>>> streamForEmail(String email) {
    final e = email.trim().toLowerCase();
    return _client
        .from('user_notifications')
        .stream(primaryKey: ['id'])
        .eq('user_email', e)
        .order('created_at', ascending: false);
  }

  Future<void> markRead(String id) async {
    await _client.from('user_notifications').update({
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> markAllRead(String email) async {
    final e = email.trim().toLowerCase();
    await _client.from('user_notifications').update({
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('user_email', e);
  }
}

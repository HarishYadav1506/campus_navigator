import 'package:supabase_flutter/supabase_flutter.dart';

class TpoService {
  TpoService(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchPostings() async {
    final rows = await _client
        .from('tpo_postings')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> addPosting({
    required String companyName,
    required String role,
    required String description,
    required String eligibility,
    required int availableSlots,
    required String createdBy,
  }) async {
    await _client.from('tpo_postings').insert({
      'company_name': companyName,
      'role': role,
      'description': description,
      'eligibility': eligibility,
      'available_slots': availableSlots,
      'created_by': createdBy,
    });
  }

  Future<void> apply(String postingId, String studentEmail) async {
    final posting = await _client
        .from('tpo_postings')
        .select('available_slots')
        .eq('id', postingId)
        .maybeSingle();
    if (posting == null) throw Exception('Posting not found');
    final slots = (posting['available_slots'] as num?)?.toInt() ?? 0;
    if (slots <= 0) throw Exception('No slots available');

    await _client.from('tpo_applications').insert({
      'posting_id': postingId,
      'student_email': studentEmail,
      'status': 'applied',
    });
    await _client.from('tpo_postings').update({
      'available_slots': slots - 1,
    }).eq('id', postingId);
  }

  Future<List<Map<String, dynamic>>> applicationsForStudent(String email) async {
    final rows = await _client
        .from('tpo_applications')
        .select('id,posting_id,status,created_at,tpo_postings(company_name,role)')
        .eq('student_email', email)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }
}

import '../core/supabase_client.dart';

class EventService {

  Future<List<Map<String, dynamic>>> fetchEvents() async {

    final response = await supabase
        .from('events')
        .select();

    return List<Map<String, dynamic>>.from(response);

  }

}
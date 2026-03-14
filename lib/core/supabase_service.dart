import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SupabaseService {

  static Future<List<Map<String, dynamic>>> getPlaces() async {
    final data = await supabase.from('places').select();
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getNodes() async {
    final data = await supabase.from('nodes').select();
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getEdges() async {
    final data = await supabase.from('edges').select();
    return List<Map<String, dynamic>>.from(data);
  }
}
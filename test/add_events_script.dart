import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Get admin', () async {
    final supabase = SupabaseClient(
      "https://vhitzhcepylbwwrcylre.supabase.co",
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZoaXR6aGNlcHlsYnd3cmN5bHJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2MTk1OTgsImV4cCI6MjA5MjE5NTU5OH0.ZeY98dYpnUbx9k6WvLRFby_1N_N6aqRYRDye4ixA1WI",
    );

    final res = await supabase.from('admin_login').select();
    print('Admins: $res');
  });
}

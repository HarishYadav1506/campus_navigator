import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/auth/auth_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/signup_page.dart';
import 'pages/auth/otp_page.dart';
import 'pages/home/home_page.dart';
import 'pages/home/splash_page.dart';
import 'pages/home/dashboard_page.dart';
import 'pages/navigation/navigation_page.dart';
import 'pages/chat/chat_list_page.dart';
import 'pages/chat/chat_screen.dart';
import 'pages/chat/create_group_page.dart';
import 'pages/calendar/calendar_page.dart';
import 'pages/calendar/book_slot_page.dart';
import 'pages/ip_btp/ip_btp_page.dart';
import 'pages/ip_btp/apply_ip_page.dart';
import 'pages/sports/sports_page.dart';
import 'pages/sports/book_court_page.dart';
import 'pages/sports/sports_status_page.dart';
import 'pages/events/events_page.dart';
import 'pages/events/seminars_page.dart';
import 'pages/navigation/street_view_page.dart';
import 'pages/notifications/notifications_page.dart';
import 'pages/campus/campus_support_page.dart';
import 'pages/admin/admin_dashboard.dart';
import 'pages/admin/manage_events.dart';
import 'pages/admin/manage_professors.dart';
import 'pages/admin/manage_sports.dart';
import 'pages/admin/manage_announcements_page.dart';
import 'pages/admin/manage_approvals_page.dart';
import 'pages/admin/student_activity_page.dart';
import 'pages/admin/feedback_admin_page.dart';
import 'pages/admin/tpo_admin_page.dart';
import 'pages/ip_btp/prof_slots_page.dart';
import 'pages/settings/settings_page.dart';
import 'pages/tpo/tpo_page.dart';
import 'pages/feedback/feedback_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://vhitzhcepylbwwrcylre.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZoaXR6aGNlcHlsYnd3cmN5bHJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2MTk1OTgsImV4cCI6MjA5MjE5NTU5OH0.ZeY98dYpnUbx9k6WvLRFby_1N_N6aqRYRDye4ixA1WI",
  );

  // `SupabaseClient` has no `supabaseUrl` getter in this SDK; REST URL is the same host.
  if (kDebugMode) {
    debugPrint('Supabase REST URL: ${Supabase.instance.client.rest.url}');
  }

  runApp(const CampusNavigator());
}

class CampusNavigator extends StatelessWidget {
  const CampusNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Campus Navigator",

      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF020617),
        fontFamily: 'SF Pro Text',
        useMaterial3: true,
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
      ),

      routes: {
        '/': (context) => const SplashPage(),
        '/auth': (context) => const AuthPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        // OTP page reads email from route arguments internally
        '/otp': (context) => const OTPPage(),
        '/home': (context) => const HomePage(),
        '/dashboard': (context) => DashboardPage(),
        '/settings': (context) => const SettingsPage(),
        '/admin': (context) => AdminDashboard(),
        '/admin_events': (context) => ManageEvents(),
        '/admin_professors': (context) => ManageProfessors(),
        '/admin_sports': (context) => ManageSports(),
        '/admin_announcements': (context) => const ManageAnnouncementsPage(),
        '/admin_approvals': (context) => const ManageApprovalsPage(),
        '/admin_activity': (context) => const StudentActivityPage(),
        '/admin_feedback': (context) => const FeedbackAdminPage(),
        '/admin_tpo': (context) => const TpoAdminPage(),
        '/chat_list': (context) => ChatListPage(),
        // Default demo chat screen (most real navigations use arguments)
        '/chat_screen': (context) => const ChatScreen(
              chatId: 'demo',
              chatName: 'Campus Announcements',
              currentUserEmail: 'demo@iiitd.ac.in',
              isGroup: true,
            ),
        '/create_group': (context) => const CreateGroupPage(),
        '/calendar': (context) => const CalendarPage(),
        '/book_slot': (context) => const BookSlotPage(),
        '/ip_btp': (context) => const IpBtpPage(),
        '/prof_slots': (context) => const ProfSlotsPage(),
        '/apply_ip': (context) => const ApplyIpPage(),
        '/sports': (context) => SportsPage(),
        '/tpo': (context) => const TpoPage(),
        '/feedback': (context) => const FeedbackPage(),
        '/notifications': (context) => const NotificationsPage(),
        '/campus_support': (context) => const CampusSupportPage(),
        // Default demo arena for direct route usage (real flow passes arenaName)
        '/book_court': (context) => const BookCourtPage(arenaName: 'Basketball Court'),
        '/sports_status': (context) => const SportsStatusPage(arenaName: 'Basketball Court'),
        '/events': (context) => EventsPage(),
        '/seminars': (context) => SeminarsPage(),
        '/streetview': (context) => const StreetViewPage(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/navigator') {
          final args = settings.arguments;
          final map = args is Map ? Map<String, dynamic>.from(args) : const <String, dynamic>{};
          final from = (map['from'] ?? '').toString();
          final to = (map['to'] ?? '').toString();

          return MaterialPageRoute(
            builder: (context) => NavigationPage(
              from: from,
              to: to,
            ),
          );
        }
        return null;
      },
    );
  }
}
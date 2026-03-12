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
import 'pages/events/events_page.dart';
import 'pages/events/seminars_page.dart';
import 'pages/navigation/street_view_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://doeqgarryoxbyknlqbzg.supabase.co",
    anonKey: "eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvZXFnYXJyeW94YnlrbmxxYnpnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MzY0NDQsImV4cCI6MjA4ODIxMjQ0NH0",
  );

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
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/otp': (context) => OTPPage(),
        '/home': (context) => const HomePage(),
        '/dashboard': (context) => DashboardPage(),
        '/navigator': (context) => const NavigationPage(from: '', to: ''),
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
        '/apply_ip': (context) => const ApplyIpPage(),
        '/sports': (context) => SportsPage(),
        // Default demo arena for direct route usage (real flow passes arenaName)
        '/book_court': (context) => const BookCourtPage(arenaName: 'Basketball Court'),
        '/events': (context) => EventsPage(),
        '/seminars': (context) => SeminarsPage(),
        '/streetview': (context) => const StreetViewPage(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/navigator') {
          final args = settings.arguments as Map;

          return MaterialPageRoute(
            builder: (context) => NavigationPage(
              from: args['from'],
              to: args['to'],
            ),
          );
        }
        return null;
      },
    );
  }
}
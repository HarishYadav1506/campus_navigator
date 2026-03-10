import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'login_page.dart';
import '../../core/session_manager.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Text(
                "Campus Navigator",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: const Text("Login"),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupPage(),
                      ),
                    );
                  },
                  child: const Text("Sign Up"),
                ),
              ),
              const SizedBox(height: 20),

              // Guest mode: direct entry as demo student
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    SessionManager.setUser(
                      newEmail: 'guest@iiitd.ac.in',
                      newRole: 'student',
                    );
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  child: const Text("Continue as Guest (student)"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

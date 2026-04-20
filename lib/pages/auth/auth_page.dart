import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'login_page.dart';

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
              // Branded logo on auth screen
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  "assets/logo.jpg",
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 8),
              const Text(
                "Use your college account to continue.",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

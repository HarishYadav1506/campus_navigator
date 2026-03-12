import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OTPPage extends StatefulWidget {
  const OTPPage({super.key});

  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  final otp = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final supabase = Supabase.instance.client;

  bool _loading = false;

  Future<void> verifyAndCreateUser(String email) async {
    if (password.text.isEmpty || confirmPassword.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter and confirm your password")),
      );
      return;
    }
    if (password.text != confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // 1. Verify OTP with Supabase (you already configured OTP in Supabase)
      await supabase.auth.verifyOTP(
        email: email,
        token: otp.text,
        type: OtpType.email,
      );

      // 2. Store user details in your "users" table
      await supabase.from('users').insert({
        'email': email,
        'password': password.text, // consider hashing later
      });

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Verification failed: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(title: const Text("OTP Verification")),
      body: Center(
        child: SizedBox(
          width: 350,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "OTP sent to $email",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: otp,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "OTP",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Create Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirm Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : () => verifyAndCreateUser(email),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text("Verify & Create Account"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


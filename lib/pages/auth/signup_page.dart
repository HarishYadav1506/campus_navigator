import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_quota_support.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final email = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _loading = false;

  Future<void> signup() async {
    final trimmedEmail = email.text.trim().toLowerCase();

    if (!trimmedEmail.endsWith("@iiitd.ac.in")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Use IIITD Email")),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // Same API for Magic Link and email OTP. Which email you get is decided in the
      // Supabase Dashboard → Authentication → Email Templates → "Magic Link":
      // - Include `{{ .Token }}` to send a 6-digit code (OTP).
      // - If the template only uses `{{ .ConfirmationURL }}`, users get a link, not a code.
      // Do not set [emailRedirectTo] here unless you need deep links for magic links.
      await supabase.auth.signInWithOtp(
        email: trimmedEmail,
      );

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/otp',
        arguments: trimmedEmail,
      );
    } catch (e) {
      if (!mounted) return;
      if (isSupabaseProjectRestrictedError(e)) {
        showSupabaseRestrictedSnackBar(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP: $e')),
        );
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Signup"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (_) => false,
          ),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: 350,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Institute Email",
                  hintText: "you@iiitd.ac.in",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : signup,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text("Send OTP"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


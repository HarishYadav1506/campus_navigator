import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/profile_sync.dart';
import '../../core/session_manager.dart';
import '../../core/supabase_quota_support.dart';

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
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

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

      // 2. Determine whether this email belongs to a professor or a student
      //    by checking the "professors_login" table (list of all professors) first.
      final professor = await supabase
          .from('professors_login')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      final role = professor != null ? 'professor' : 'student';

      // 3. Profile row: use RPC so it works even when RLS blocks direct INSERT on public.users.
      //    DB function sets email from JWT only (see migration create_user_after_otp).
      await supabase.rpc<void>(
        'create_user_after_otp',
        params: {
          'p_password': password.text,
          'p_role': role,
        },
      );

      final em = email.trim().toLowerCase();
      SessionManager.setUser(newEmail: em, newRole: role);
      await ensureProfileRow(supabase, em);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      if (isSupabaseProjectRestrictedError(e)) {
        showSupabaseRestrictedSnackBar(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e')),
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
                obscureText: _hidePassword,
                decoration: InputDecoration(
                  labelText: "Create Password",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _hidePassword ? 'Show password' : 'Hide password',
                    onPressed: () {
                      setState(() => _hidePassword = !_hidePassword);
                    },
                    icon: Icon(
                      _hidePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassword,
                obscureText: _hideConfirmPassword,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _hideConfirmPassword
                        ? 'Show confirm password'
                        : 'Hide confirm password',
                    onPressed: () {
                      setState(
                        () => _hideConfirmPassword = !_hideConfirmPassword,
                      );
                    },
                    icon: Icon(
                      _hideConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
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


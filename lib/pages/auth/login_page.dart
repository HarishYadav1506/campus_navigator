import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session_manager.dart';
import '../../core/supabase_quota_support.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  final supabase = Supabase.instance.client;
  bool _loading = false;
  bool _hidePassword = true;

  Future<void> login() async {
    if (email.text.isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter email and password")),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final normalizedEmail = email.text.trim().toLowerCase();

      // DEMO USER: allows you to test screen after login without Supabase data
      if (email.text == 'demo@iiitd.ac.in' && password.text == 'password123') {
        const role = 'student';
        SessionManager.setUser(newEmail: email.text, newRole: role);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Logged in as demo student")),
        );
        return;
      }

      // Admin login (admin_login table + password admin123)
      final adminRes = await supabase
          .from('admin_login')
          .select('email')
          .eq('email', normalizedEmail)
          .maybeSingle();
      if (adminRes != null && password.text == 'admin123') {
        SessionManager.setUser(newEmail: normalizedEmail, newRole: 'admin');
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/admin');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged in as admin')),
        );
        return;
      }

      // 1. Check user credentials in "users" table
      final userRes = await supabase
          .from('users')
          .select()
          .eq('email', normalizedEmail)
          .eq('password', password.text)
          .maybeSingle();

      if (userRes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid email or password")),
        );
        return;
      }

      // 2. Read role directly from the "users" table.
      //    It is set at signup time by checking "professors_login".
      final role = ((userRes['role'] as String?) ?? 'student').trim().toLowerCase();
      SessionManager.setUser(newEmail: normalizedEmail, newRole: role);

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        role == 'admin' ? '/admin' : '/home',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logged in as $role")),
      );
    } catch (e) {
      if (!mounted) return;
      if (isSupabaseProjectRestrictedError(e)) {
        showSupabaseRestrictedSnackBar(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
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
  void dispose() {
    email.dispose();
    password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (_) => false,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Colors.white12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Welcome back',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sign in with your college email to continue.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: email,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                        decoration: const InputDecoration(
                          labelText: "Email",
                          hintText: "you@college.edu",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: password,
                        focusNode: _passwordFocus,
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!_loading) login();
                        },
                        decoration: InputDecoration(
                          labelText: "Password",
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _hidePassword ? 'Show password' : 'Hide password',
                            onPressed: () => setState(() => _hidePassword = !_hidePassword),
                            icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : login,
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text("Login"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


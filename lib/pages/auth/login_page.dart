import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/session_manager.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  final supabase = Supabase.instance.client;
  bool _loading = false;
  String? _role; // student / prof / admin

  Future<void> login() async {
    if (email.text.isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter email and password")),
      );
      return;
    }

    setState(() {
      _loading = true;
      _role = null;
    });

    try {
      // DEMO USER: allows you to test screen after login without Supabase data
      if (email.text == 'demo@iiitd.ac.in' && password.text == 'password123') {
        const role = 'student';
        SessionManager.setUser(newEmail: email.text, newRole: role);
        setState(() {
          _role = role;
        });
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Logged in as demo student")),
        );
        return;
      }

      // 1. Check user credentials in "user" table
      final userRes = await supabase
          .from('user')
          .select()
          .eq('email', email.text)
          .eq('password', password.text)
          .maybeSingle();

      if (userRes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid email or password")),
        );
        return;
      }

      // 2. Determine role from prof/admin tables based on email
      String role = 'student';

      final adminRes = await supabase
          .from('admin')
          .select('email')
          .eq('email', email.text)
          .maybeSingle();

      if (adminRes != null) {
        role = 'admin';
      } else {
        final profRes = await supabase
            .from('prof')
            .select('email')
            .eq('email', email.text)
            .maybeSingle();

        if (profRes != null) {
          role = 'prof';
        }
      }

      SessionManager.setUser(newEmail: email.text, newRole: role);
      setState(() {
        _role = role;
      });

      if (!mounted) return;

      // You can later route to different dashboards based on role here.
      Navigator.pushReplacementNamed(context, '/home');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logged in as $role")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
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
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Center(
        child: SizedBox(
          width: 350,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
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
              if (_role != null) ...[
                const SizedBox(height: 12),
                Text(
                  "Role detected: $_role",
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


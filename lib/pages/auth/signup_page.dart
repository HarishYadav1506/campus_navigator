import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {

  final email = TextEditingController();
  final supabase = Supabase.instance.client;

  void signup() async {
    if (!email.text.endsWith("@iiitd.ac.in")) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Use IIITD Email")));
      return;
    }
    await supabase.auth.signInWithOtp(
      email: email.text,
    );
    Navigator.pushNamed(
      context,
      '/otp',
      arguments: email.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Signup")),
      body: Center(
        child: SizedBox(
          width: 350,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ... add your signup form fields here ...
            ],
          ),
        ),
      ),
    );
  }
}

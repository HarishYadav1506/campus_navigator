import 'package:flutter/material.dart';

class ApplyIpPage extends StatelessWidget {
  const ApplyIpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Apply IP")),
      body: const Center(
        child: Text(
          "Apply IP Page",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

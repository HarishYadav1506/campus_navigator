import 'package:flutter/material.dart';

class IpBtpPage extends StatelessWidget {
  const IpBtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("IP/BTP")),
      body: const Center(
        child: Text(
          "IP/BTP Page",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.pushReplacementNamed(context, "/home");
        },
        child: Stack(
          children: [
            /// Background Image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/old_academic.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            /// Dark Overlay
            Container(
              color: Colors.black.withOpacity(0.55),
            ),

            /// Logo + Text
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/logo_new.png",
                    height: 130,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Campus Navigator",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Tap anywhere to enter campus",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


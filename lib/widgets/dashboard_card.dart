import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  final Widget child;

  DashboardCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: child,
      elevation: 4,
      margin: EdgeInsets.all(8),
    );
  }
}

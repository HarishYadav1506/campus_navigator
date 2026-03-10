import 'package:flutter/material.dart';

class NavigationPage extends StatelessWidget {
  final String from;
  final String to;

  const NavigationPage({Key? key, required this.from, required this.to}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Navigation')),
      body: Center(
        child: Text('Navigation from $from to $to'),
      ),
    );
  }
}

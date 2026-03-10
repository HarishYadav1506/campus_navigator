import 'package:flutter/material.dart';

class EventCard extends StatelessWidget {
  final String title;
  final DateTime date;

  EventCard({required this.title, required this.date});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(date.toString()),
      ),
      elevation: 4,
      margin: EdgeInsets.all(8),
    );
  }
}

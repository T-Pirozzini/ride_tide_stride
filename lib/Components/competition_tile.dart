import 'package:flutter/material.dart';

class CompetitionTile extends StatelessWidget {
  final String title;

  CompetitionTile({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        // Add other competition details and actions here
      ),
    );
  }
}

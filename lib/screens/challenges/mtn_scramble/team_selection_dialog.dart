import 'package:flutter/material.dart';

class TeamSelectionDialog extends StatelessWidget {
  final Function(String) onTeamSelected;

  TeamSelectionDialog({required this.onTeamSelected});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Join a Team'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () {
              onTeamSelected('Team 1');
            },
            child: Text('Join Team 1'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              onTeamSelected('Team 2');
            },
            child: Text('Join Team 2'),
          ),
        ],
      ),
    );
  }
}

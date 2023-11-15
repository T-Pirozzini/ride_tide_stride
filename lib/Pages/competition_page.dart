import 'package:flutter/material.dart';

class CompetitionPage extends StatefulWidget {
  final bool showTeamChoiceDialog;
  const CompetitionPage({super.key, this.showTeamChoiceDialog = false});

  @override
  State<CompetitionPage> createState() => _CompetitionPageState();
}

class _CompetitionPageState extends State<CompetitionPage> {
  void _showTeamChoiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Join a Team'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Team 1'),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Add logic to handle team selection here
                    },
                    child: const Text('Join Team 1'),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Team 2'),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Add logic to handle team selection here
                    },
                    child: const Text('Join Team 2'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text('Competition Page'),
      persistentFooterButtons: [
        ElevatedButton(
          onPressed: () {
            _showTeamChoiceDialog(context);
          },
          child: const Text('Join a Team'),
        ),
      ],
    );
  }
}

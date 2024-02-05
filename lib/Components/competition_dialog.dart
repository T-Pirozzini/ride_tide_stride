import 'package:flutter/material.dart';
import 'package:ride_tide_stride/models/challenge.dart';

class AddCompetitionDialog extends StatefulWidget {
  @override
  State<AddCompetitionDialog> createState() => _AddCompetitionDialogState();
}

class _AddCompetitionDialogState extends State<AddCompetitionDialog> {
  bool _isPublic = true;
  bool _isVisible = true;
  String _selectedChallenge = "Mtn Scramble";

  final List<Challenge> _challenges = [
    Challenge(name: "Mtn Scramble", assetPath: 'assets/images/mtn.png'),
    Challenge(name: "Snow2Surf", assetPath: 'assets/images/snow2surf.png'),
    Challenge(
        name: "Team Traverse", assetPath: 'assets/images/teamTraverse.png'),
  ];

  void toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  void togglePrivacy() {
    setState(() {
      _isPublic = !_isPublic;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(child: Text('Create a Challenge')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _challenges
                  .map((challenge) => GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedChallenge = challenge.name;
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: _selectedChallenge == challenge.name
                              ? Colors.blue
                              : Colors.grey,
                          maxRadius: 30,
                          child: ClipOval(
                            child: Image.asset(challenge.assetPath),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            SizedBox(height: 20),
            Text(_selectedChallenge,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextFormField(
              decoration: InputDecoration(labelText: 'Competition Name'),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    ButtonTheme(
                      minWidth:
                          64.0, // Ensure the buttons have a consistent width
                      height: 64.0,
                      child: OutlinedButton(
                        onPressed: toggleVisibility,
                        style: OutlinedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(15),
                        ),
                        child: Icon(_isVisible
                            ? Icons.visibility
                            : Icons.visibility_off),
                      ),
                    ),
                    Text(_isVisible ? 'Spectators' : 'No Spectators'),
                  ],
                ),
                Column(
                  children: [
                    ButtonTheme(
                      minWidth:
                          64.0, // Ensure the buttons have a consistent width
                      height: 64.0,
                      child: OutlinedButton(
                        onPressed: togglePrivacy,
                        style: OutlinedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(15),
                        ),
                        child: Icon(_isPublic ? Icons.lock_open : Icons.lock),
                      ),
                    ),
                    Text(_isPublic ? 'Public' : 'Private'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Add'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class CompetitionLearnMore extends StatelessWidget {
  final String challengeName;
  final String challengeImage;
  final bool isPublic;
  final bool isVisible;
  final String description;

  CompetitionLearnMore(
      {super.key,
      required this.challengeName,
      required this.challengeImage,
      required this.isPublic,
      required this.isVisible,
      required this.description});

  @override
  Widget build(BuildContext context) {
    void spectateChallenge() {
      print('Spectating $challengeName');
    }

    return AlertDialog(
      title: Center(child: Text(challengeName)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Add this line
          children: [
            Image.asset(challengeImage),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            isVisible
                ? Row(
                    children: [
                      Icon(Icons.visibility),
                      const SizedBox(width: 5),
                      Text('Spectators Allowed'),
                    ],
                  )
                : Row(
                    children: [
                      Icon(Icons.visibility_off),
                      const SizedBox(width: 5),
                      Text('No Spectators'),
                    ],
                  ),
            isPublic
                ? Row(
                    children: [
                      Icon(Icons.lock_open),
                      const SizedBox(width: 5),
                      Text('No Password Required'),
                    ],
                  )
                : Row(
                    children: [
                      Icon(Icons.lock),
                      const SizedBox(width: 5),
                      Text('Password Required'),
                    ],
                  ),
            const SizedBox(height: 10),
            TextButton(
                onPressed: spectateChallenge,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.blue),
                  maximumSize: MaterialStateProperty.all(Size(200, 50)),
                ),
                child: Text(
                  'Spectate Challenge',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ))
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class CompetitionLearnMore extends StatelessWidget {
  final String challengeName;
  final String challengeImage;
  final bool isPublic;
  final bool isVisible;
  final String description;
  final VoidCallback onSpectate;

  CompetitionLearnMore(
      {super.key,
      required this.challengeName,
      required this.challengeImage,
      required this.isPublic,
      required this.isVisible,
      required this.description,
      required this.onSpectate});

  @override
  Widget build(BuildContext context) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    if (isPublic) {
                      onSpectate();
                    } else {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext bc) {
                          return Container(
                            child: Wrap(
                              children: <Widget>[
                                ListTile(
                                  leading: Icon(Icons.warning),
                                  title: Text('Sorry, no spectators allowed.'),
                                  onTap: () => {},
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }
                  },
                  style: isPublic
                      ? ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                              Theme.of(context).primaryColor),
                          maximumSize: MaterialStateProperty.all(Size(200, 50)),
                        )
                      : ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                              Theme.of(context).primaryColor.withOpacity(0.5)),
                          maximumSize: MaterialStateProperty.all(Size(200, 50)),
                        ),
                  child: Text(
                    'Spectate Challenge',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ButtonStyle(
                    maximumSize: MaterialStateProperty.all(Size(200, 50)),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

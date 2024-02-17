import 'package:flutter/material.dart';

class TeamTraversePage extends StatelessWidget {
  final String challengeId;

  const TeamTraversePage({Key? key, required this.challengeId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // The Scaffold widget provides a consistent visual structure to your app.
    return Scaffold(
      // AppBar displays information and actions relating to the current screen.
      appBar: AppBar(
        title: Text("Team Traverse Challenge"),
        // Allows the user to return to the previous screen.
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // The body of the screen is wrapped in a SingleChildScrollView to handle overflow
      // and make the screen scrollable if needed.
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0), // Adds padding around the content.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "Challenge ID:",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10), // Adds space between text widgets.
            Text(
              challengeId, // Displays the challenge ID passed to the page.
              style: TextStyle(fontSize: 20, color: Colors.grey[700]),
            ),
            // Add more widgets here to display other challenge details.
          ],
        ),
      ),
    );
  }
}

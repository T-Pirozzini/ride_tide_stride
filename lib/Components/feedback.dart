import 'package:flutter/material.dart';
import 'package:mailto/mailto.dart';
import 'package:url_launcher/url_launcher.dart';

class UserFeedback extends StatelessWidget {
  final String? userName;
  final String? userEmail;
  final feedbackController = TextEditingController();

  UserFeedback({Key? key, required this.userName, required this.userEmail})
      : super(key: key);

  launchMailto() async {
    final mailtoLink = Mailto(
      to: ['tpirozzini@gmail.com'],
      subject: 'App Feedback from $userName, $userEmail',
      body: feedbackController.text,
    );

    await launch('$mailtoLink');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            "Suggestions/Feedback?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.0),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: feedbackController,
                decoration: InputDecoration(
                  hintText: 'Share your thoughts...',
                  border: InputBorder.none,
                ),
                maxLines: 5,
              ),
            ),
          ),
          Text("Help me improve the app!",
              style: TextStyle(fontStyle: FontStyle.italic)),
          SizedBox(height: 20.0),
          ElevatedButton(
            onPressed: launchMailto,
            style: ElevatedButton.styleFrom(
              primary: Color(0xFF283D3B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              child: Text(
                'Submit Feedback',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

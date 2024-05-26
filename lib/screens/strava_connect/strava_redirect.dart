import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void showStravaDialog(BuildContext context, int activityId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/strava.png',
              height: 24.0, // Adjust the size as required
              width: 24.0,
            ),
            SizedBox(width: 10),
            Text('View Activity on Strava?'),
          ],
        ),
        content: Text('Please Note: You will be leaving R.T.S'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                child: Text('Cancel', style: TextStyle(fontSize: 18)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              SizedBox(width: 10),
              TextButton(
                child: Text('Open',
                    style: TextStyle(color: Colors.deepOrange, fontSize: 18)),
                onPressed: () {
                  _openStravaActivity(activityId);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

   Future<void> _openStravaActivity(int activityId) async {
    final Uri url = Uri.https('www.strava.com', '/activities/$activityId');

    bool canOpen = await canLaunchUrl(url);
    if (canOpen) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Handle the inability to launch the URL.
      print('Could not launch $url');
    }
  }

  
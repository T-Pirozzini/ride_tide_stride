import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';


void showSuccessDialog(context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Challenge Completed!"),
        content: Stack(
          children: <Widget>[
            Lottie.asset(
              'assets/lottie/win_animation.json',
              frameRate: FrameRate.max,
              repeat: true,
              reverse: false,
              animate: true,
            ),
            Lottie.asset(
              'assets/lottie/firework_animation.json',
              frameRate: FrameRate.max,
              repeat: true,
              reverse: false,
              animate: true,
            ),
            const Text(
              "Congratulations! You have successfully completed the challenge.",
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Widget getUserName(String email) {
    // Check if email is "Empty Slot", and avoid fetching from Firestore
    if (email == "Empty Slot") {
      return Text(email);
    }

    // Proceed with fetching the username
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('Users').doc(email).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Loading..."); // Show loading text or a spinner
        }
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return Text(email); // Fallback to email if user data is not available
        }
        var data = snapshot.data!.data() as Map<String, dynamic>;
        return Text(data['username'] ?? email);
      },
    );
  }

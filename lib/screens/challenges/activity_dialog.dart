import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ride_tide_stride/screens/challenges/challenge_helpers.dart';
import 'package:ride_tide_stride/shared/activity_icons.dart';

Future<void> showUserActivitiesDialog(
    BuildContext context, String userEmail, DateTime startDate) async {
  DateTime adjustedStartDate =
      DateTime(startDate.year, startDate.month, startDate.day);
  String adjustedStartDateString = adjustedStartDate.toIso8601String();
  // Fetch activities for the given user email
  QuerySnapshot activitiesSnapshot = await FirebaseFirestore.instance
      .collection('activities')
      .where('user_email', isEqualTo: userEmail)
      .where('start_date_local',
          isGreaterThanOrEqualTo: adjustedStartDateString)
      .orderBy('start_date_local', descending: true)
      .get();

  // Parse activities data
  List<Map<String, dynamic>> activities = activitiesSnapshot.docs
      .map((doc) => doc.data() as Map<String, dynamic>)
      .toList();

  // Now show the dialog with the activities data
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Center(child: getUserName(userEmail)),
        titleTextStyle: GoogleFonts.tektur(
            textStyle: TextStyle(
                fontSize: 24,
                color: Colors.black,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.2)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: activities.length,
            itemBuilder: (BuildContext context, int index) {
              var activity = activities[index];
              IconData? iconData = activityIcons[activity['type']];
              return Card(
                color: Color(0xFF283D3B).withOpacity(.6),
                elevation: 2,
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    iconData ?? Icons.error_outline,
                    color: Colors.tealAccent.shade400,
                    size: 32,
                  ),
                  title: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      activity['name'] ?? 'Unnamed activity',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('yyyy-MM-dd')
                        .format((activity['timestamp'] as Timestamp).toDate()),
                    style:
                        TextStyle(fontSize: 12.0, color: Colors.grey.shade200),
                  ),
                  trailing: Text(
                    '${(activity['distance'] / 1000).toStringAsFixed(2)} km',
                    style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.tealAccent),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

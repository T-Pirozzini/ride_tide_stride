import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeamTraversePage extends StatefulWidget {
  final String challengeId;
  final List<dynamic> participantsEmails;
  final Timestamp startDate;

  const TeamTraversePage(
      {Key? key,
      required this.challengeId,
      required this.participantsEmails,
      required this.startDate})
      : super(key: key);

  @override
  State<TeamTraversePage> createState() => _TeamTraversePageState();
}

class _TeamTraversePageState extends State<TeamTraversePage> {
  Future<Map<String, double>> fetchParticipantDistances() async {
    Map<String, double> participantDistances = {};

    // Calculate the end date as 30 days after the start date
    DateTime startDate = widget.startDate.toDate();
    DateTime adjustedStartDate =
        DateTime(startDate.year, startDate.month, startDate.day);

    DateTime endDate = adjustedStartDate.add(Duration(days: 30));

    print("Challenge Start Date: $startDate");
    print("Challenge End Date: $endDate");

    for (String email in widget.participantsEmails) {
      double totalDistance = 0.0;
      var activitiesSnapshot = await FirebaseFirestore.instance
          .collection('activities')
          .where('user_email', isEqualTo: email)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(adjustedStartDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Check if activities are found
      print("Found ${activitiesSnapshot.docs.length} activities for $email");

      for (var doc in activitiesSnapshot.docs) {
        DateTime activityDate = (doc.data()['timestamp'] as Timestamp).toDate();
        print("Activity Timestamp for $email: $activityDate");
        totalDistance += (doc.data()['distance'] as num).toDouble();
      }
      participantDistances[email] = totalDistance;
    }
    return participantDistances;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Team Traverse Challenge"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "Challenge ID:",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              widget.challengeId,
              style: TextStyle(fontSize: 20, color: Colors.grey[700]),
            ),
            FutureBuilder<Map<String, double>>(
              future: fetchParticipantDistances(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return Text("No participant data available");
                }
                Map<String, double> distances = snapshot.data!;
                double totalDistance =
                    distances.values.fold(0.0, (a, b) => a + b);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...distances.keys.map((email) => ListTile(
                          title: Text(email),
                          subtitle: Text(
                            'Distance: ${(distances[email]! / 1000).toStringAsFixed(2)} km',
                          ),
                        )),
                    // Also format the total distance similarly
                    Text(
                        "Total Distance: ${(totalDistance / 1000).toStringAsFixed(2)}km",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

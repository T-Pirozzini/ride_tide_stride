import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeamTraversePage extends StatefulWidget {
  final String challengeId;
  final List<dynamic> participantsEmails;
  final Timestamp startDate;
  final String challengeType;
  final String challengeName;
  final String mapDistance;

  const TeamTraversePage(
      {Key? key,
      required this.challengeId,
      required this.participantsEmails,
      required this.startDate,
      required this.challengeType,
      required this.challengeName,
      required this.mapDistance})
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

    for (String email in widget.participantsEmails) {
      double totalDistance = 0.0;
      var activitiesSnapshot = await FirebaseFirestore.instance
          .collection('activities')
          .where('user_email', isEqualTo: email)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(adjustedStartDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      for (var doc in activitiesSnapshot.docs) {
        DateTime activityDate = (doc.data()['timestamp'] as Timestamp).toDate();
        print("Activity Timestamp for $email: $activityDate");
        totalDistance += (doc.data()['distance'] as num).toDouble();
      }
      participantDistances[email] = totalDistance;
    }
    return participantDistances;
  }

  Future<Map<String, dynamic>> fetchChallengeMapDetails() async {
    var challengeSnapshot = await FirebaseFirestore.instance
        .collection('Challenges')
        .doc(widget.challengeId)
        .get();
    if (!challengeSnapshot.exists) {
      throw Exception("Challenge not found");
    }
    var data = challengeSnapshot.data();
    if (data == null) {
      throw Exception("Challenge data is null");
    }
    return {
      'mapDistance': data['mapDistance'],
      'mapAssetUrl': data['currentMap'],
    };
  }

  Future<Map<String, dynamic>> fetchChallengeDetailsAndTotalDistance() async {
    // Fetch participant distances first
    Map<String, double> participantDistances =
        await fetchParticipantDistances();
    double totalDistance =
        participantDistances.values.fold(0.0, (a, b) => a + b);

    // Then fetch challenge map details
    var mapDetails = await fetchChallengeMapDetails();

    // Convert 'mapDistance' to a numeric value for calculations
    String mapDistanceStr = widget
        .mapDistance; // Assuming this is your map distance string with 'kms'
    String numericPart = mapDistanceStr.replaceAll(RegExp(r'[^0-9.]'), '');
    double mapDistance = double.parse(numericPart);

    // Return a composite result containing both sets of data
    return {
      'totalDistance': totalDistance, // Total distance from participants
      'mapDistance': mapDistance, // Numeric map distance
      'mapAssetUrl': mapDetails['mapAssetUrl'], // URL or asset path for the map
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.challengeType),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Text(
              widget.challengeName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              "Start Date: ${widget.startDate.toDate().toLocal()}",
              style: TextStyle(fontSize: 16),
            ),
          ),
          Text('Goal: ${widget.mapDistance}'),
          Expanded(
            flex:
                1, // Adjust flex to change how space is allocated between the map and participant list
            child: FutureBuilder<Map<String, dynamic>>(
              future: fetchChallengeDetailsAndTotalDistance(),
              builder: (context, snapshot) {
                // Handle loading and error states as before
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return Text("Details not available");
                }

                // Unchanged logic for handling fetched data
                double totalDistanceKM = snapshot.data!['totalDistance'] / 1000;
                double mapDistance = snapshot.data!['mapDistance'];
                String mapAssetUrl = snapshot.data!['mapAssetUrl'];
                double progress =
                    (totalDistanceKM / mapDistance).clamp(0.0, 1.0);

                return Column(
                  children: [
                    Expanded(
                      child: Image.asset(mapAssetUrl,
                          fit: BoxFit
                              .cover), // Adjusted map to be within an Expanded widget
                    ),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    Text(
                      "${(progress * 100).toStringAsFixed(2)}% Completed",
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
          ),          
          Container(
            height: 400, // Adjust this value as needed
            child: FutureBuilder<Map<String, double>>(
              future: fetchParticipantDistances(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return Text("No participant data available");
                }

                // Ensure we display up to 10 slots, showing "Empty Slot" as needed
                int itemCount = max(10, widget.participantsEmails.length);
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Number of columns
                    childAspectRatio: 3 / 1, // Adjust the size ratio of items
                    crossAxisSpacing: 4, // Spacing between items horizontally
                    mainAxisSpacing: 4, // Spacing between items vertically
                  ),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    String email = index < widget.participantsEmails.length
                        ? widget.participantsEmails[index]
                        : "Empty Slot";
                    double distance = index < widget.participantsEmails.length
                        ? snapshot.data![email] ?? 0.0
                        : 0.0;

                    return Card(
                      // Using Card for better UI presentation
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: getUserName(
                                  email), // Username or "Empty Slot"
                            ),
                            Text(
                              index < widget.participantsEmails.length
                                  ? 'Distance: ${(distance / 1000).toStringAsFixed(2)} km'
                                  : '',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget getUserName(String email) {
    // Check if email is "Empty Slot", and avoid fetching from Firestore
    if (email == "Empty Slot") {
      return Text(
          email); // Or return SizedBox.shrink() if you don't want to show anything
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
        var data = snapshot.data!.data()
            as Map<String, dynamic>; // Cast the data to the correct type
        return Text(
            data['username'] ?? email); // Show username or email as a fallback
      },
    );
  }
}

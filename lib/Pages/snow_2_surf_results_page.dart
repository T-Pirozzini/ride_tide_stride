import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Snow2SurfResultsPage extends StatefulWidget {
  final IconData icon;
  final String category;
  final List<String> types;
  final double distance;

  Snow2SurfResultsPage({
    Key? key,
    required this.icon,
    required this.category,
    required this.types,
    required this.distance,
  }) : super(key: key);

  @override
  _Snow2SurfResultsPageState createState() => _Snow2SurfResultsPageState();
}

class _Snow2SurfResultsPageState extends State<Snow2SurfResultsPage> {
  Stream<QuerySnapshot> getCurrentMonthData() {
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;

    final firstDayOfMonth = DateTime(currentYear, currentMonth, 1);
    final lastDayOfMonth = DateTime(currentYear, currentMonth + 1, 0);

    return FirebaseFirestore.instance
        .collection('activities')
        .where('start_date',
            isGreaterThanOrEqualTo: firstDayOfMonth.toUtc().toIso8601String())
        .where('start_date',
            isLessThanOrEqualTo: lastDayOfMonth.toUtc().toIso8601String())
        .snapshots();
  }

  String formatTime(double totalTime) {
    int totalTimeInSeconds = totalTime.toInt();
    int hours = totalTimeInSeconds ~/ 3600;
    int minutes = (totalTimeInSeconds % 3600) ~/ 60;
    int seconds = totalTimeInSeconds % 60;
    return totalTimeInSeconds > 0
        ? "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}"
        : "0:00";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results for: ${widget.category}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: 75,
            ),
            Divider(thickness: 2),
            StreamBuilder<QuerySnapshot>(
              stream: getCurrentMonthData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final activityDocs = snapshot.data?.docs ?? [];
                List<Widget> activityWidgets = [];

                for (var doc in activityDocs) {
                  var data = doc.data() as Map<String, dynamic>;
                  String type = data['type'];
                  double activityDistance =
                      data['distance'] / 1000; // Convert to kilometers
                  String fullName = data['fullname'];
                  double averageSpeed =
                      data['average_speed']; // Speed in meters per second

                  double speedKph = averageSpeed * 3.6; // Convert to km/h
                  double pace = 60 / speedKph; // Pace in minutes per kilometer
                  int minutes = pace.floor();
                  int seconds = ((pace - minutes) * 60).round();

                  // Format pace as mm:ss per kilometer
                  String paceFormatted =
                      "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} min/km";

                  double totalTimeInSeconds = averageSpeed > 0
                      ? (widget.distance * 1000) / averageSpeed
                      : 0.0;
                  String displayTime = formatTime(totalTimeInSeconds);

                  // Check if the activity's type is in the types list and if its distance meets the requirement
                  if (widget.types.contains(type) &&
                      activityDistance >= widget.distance) {
                    activityWidgets.add(
                      ListTile(
                        title: Text(fullName),
                        subtitle: Text(
                            '${widget.distance} km at $paceFormatted = $displayTime'),
                      ),
                    );
                  }
                }

                return Expanded(
                  child: ListView(
                    children: activityWidgets,
                  ),
                );
              },
            )

            // Add more details as needed
          ],
        ),
      ),
    );
  }
}

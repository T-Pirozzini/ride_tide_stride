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
        .where('sport_type',
            whereIn: widget.types) // Filter by the specific types
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
            Icon(widget.icon, size: 75),
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

                List<DocumentSnapshot> activityDocs = snapshot.data?.docs ?? [];
                // Filter and sort activities by total time or pace
                List<Map<String, dynamic>> filteredSortedActivities =
                    activityDocs
                        .map((doc) => doc.data() as Map<String, dynamic>)
                        .where((data) {
                  double activityDistance = data['distance'] / 1000;
                  return widget.types.contains(data['sport_type']) &&
                      activityDistance >= widget.distance;
                }).toList();
                filteredSortedActivities.sort((a, b) {
                  double totalTimeA = a['average_speed'] > 0
                      ? (widget.distance * 1000) / a['average_speed']
                      : double.infinity;
                  double totalTimeB = b['average_speed'] > 0
                      ? (widget.distance * 1000) / b['average_speed']
                      : double.infinity;
                  return totalTimeA.compareTo(totalTimeB);
                });

                return Expanded(
                  child: ListView.builder(
                    itemCount: filteredSortedActivities.length,
                    itemBuilder: (context, index) {
                      var data = filteredSortedActivities[index];
                      String fullName = data['fullname'];
                      double totalTimeInSeconds = data['average_speed'] > 0
                          ? (widget.distance * 1000) / data['average_speed']
                          : 0.0;
                      String displayTime = formatTime(totalTimeInSeconds);
                      return Card(
                        elevation: 2,
                        child: ListTile(
                          title: Text(fullName),
                          subtitle:
                              Text('${widget.distance} km at $displayTime'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

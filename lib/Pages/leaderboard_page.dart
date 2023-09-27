import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:google_fonts/google_fonts.dart';

class Leaderboard extends StatefulWidget {
  const Leaderboard({Key? key}) : super(key: key);

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  final currentUser = FirebaseAuth.instance.currentUser;

  // Create a variable to represent the current date
  DateTime currentDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final endTime = endOfMonth.millisecondsSinceEpoch;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leaderboard',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.2)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Time'),
              Tab(text: 'Distance'),
              Tab(text: 'Elevation'),
            ],
          ),
          actions: [
            CountdownTimerWidget(endTime: endTime),
          ],
        ),
        body: const TabBarView(
          children: [
            LeaderboardTab(title: 'Moving Time'),
            LeaderboardTab(title: 'Total Distance (km)'),
            LeaderboardTab(title: 'Total Elevation'),
          ],
        ),
      ),
    );
  }
}

class LeaderboardTab extends StatelessWidget {
  final String title;

  const LeaderboardTab({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: getCurrentMonthData(), // Fetch data for the current month
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final activityDocs = snapshot.data?.docs ?? [];
        final activityData = groupAndAggregateData(activityDocs, title);

        return ListView.builder(
          itemCount: activityData[title]!.length,
          itemBuilder: (context, index) {
            final entry = activityData[title]![index];
            final currentPlace = index + 1;

            // Helper function to format duration
            String formatDuration(int seconds) {
              final Duration duration = Duration(seconds: seconds);
              final int hours = duration.inHours;
              final int minutes = (duration.inMinutes % 60);
              final int remainingSeconds = (duration.inSeconds % 60);
              return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
            }

            // Helper function to build list tile
            Widget buildListTile(String title, String trailingText) {
              return ListTile(
                title: Text('${entry['full_name']}'),
                leading: customPlaceWidget('$currentPlace'),
                subtitle: Text(title),
                trailing: customTotalWidget(trailingText),
              );
            }

            // Decide which list tile to build based on the title
            Widget dataWidget;
            if (title == 'Moving Time') {
              dataWidget = buildListTile('Total Moving Time',
                  formatDuration(entry['total_moving_time']));
            } else if (title == 'Total Distance (km)') {
              dataWidget = buildListTile('Total Distance',
                  '${(entry['total_distance'] / 1000).toStringAsFixed(2)} km');
            } else if (title == 'Total Elevation') {
              dataWidget = buildListTile(
                  'Total Elevation', '${entry['total_elevation']} m');
            } else {
              dataWidget = const SizedBox();
            }

            return Column(
              children: [
                dataWidget,
                const Divider(
                  color: Colors.grey,
                  thickness: 1.0,
                  height: 0.0,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Map<String, List<Map<String, dynamic>>> groupAndAggregateData(
      List<QueryDocumentSnapshot> activityDocs, String title) {
    // Create a map to group and aggregate data by full name for the given title
    final Map<String, Map<String, dynamic>> dataByTitle = {};

    // Iterate through activity documents and aggregate data for the given title
    for (final doc in activityDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final fullName = data['fullname'] as String;

      // Convert elevation_gain to a number (if it's stored as a string)
      final elevationGain = data['elevation_gain'] is String
          ? double.tryParse(data['elevation_gain'] ?? '') ?? 0.0
          : (data['elevation_gain'] ?? 0.0);

      // Check if full name exists for the given title and update accordingly
      if (title == 'Moving Time') {
        if (dataByTitle.containsKey(fullName)) {
          dataByTitle[fullName]!['total_moving_time'] += data['moving_time'];
        } else {
          dataByTitle[fullName] = {
            'full_name': fullName,
            'total_moving_time': data['moving_time'],
          };
        }
      } else if (title == 'Total Distance (km)') {
        if (dataByTitle.containsKey(fullName)) {
          dataByTitle[fullName]!['total_distance'] += data['distance'];
        } else {
          dataByTitle[fullName] = {
            'full_name': fullName,
            'total_distance': data['distance'],
          };
        }
      } else if (title == 'Total Elevation') {
        if (dataByTitle.containsKey(fullName)) {
          dataByTitle[fullName]!['total_elevation'] += elevationGain;
        } else {
          dataByTitle[fullName] = {
            'full_name': fullName,
            'total_elevation': elevationGain,
          };
        }
      }
    }

    // Convert the map to a list
    final List<Map<String, dynamic>> dataList = dataByTitle.values.toList();

    // Sort the list by the appropriate field based on the title
    if (title == 'Moving Time') {
      dataList.sort(
          (a, b) => b['total_moving_time'].compareTo(a['total_moving_time']));
    } else if (title == 'Total Distance (km)') {
      dataList
          .sort((a, b) => b['total_distance'].compareTo(a['total_distance']));
    } else if (title == 'Total Elevation') {
      dataList
          .sort((a, b) => b['total_elevation'].compareTo(a['total_elevation']));
    }

    // Return the sorted list for the given title
    return {title: dataList};
  }

  Widget customPlaceWidget(String place) {
    const color = Color(0xFFA09A6A); // Customize the color as needed

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.0),
      ),
      padding: const EdgeInsets.all(10.0), // Adjust padding as needed
      child: Text(
        place,
        style: const TextStyle(
          fontSize: 24, // Adjust font size as needed
          color: color, // Text color
          fontWeight: FontWeight.bold, // Bold text
        ),
      ),
    );
  }

  Widget customTotalWidget(String total) {
    const color = Color(0xFF283D3B); // Customize the color as needed

    return Container(
      padding: const EdgeInsets.all(10.0), // Adjust padding as needed
      child: Text(
        total,
        style: const TextStyle(
          fontSize: 20, // Adjust font size as needed
          color: color, // Text color
          fontWeight: FontWeight.bold, // Bold text
        ),
      ),
    );
  }

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
}

class CountdownTimerWidget extends StatelessWidget {
  final int endTime;
  const CountdownTimerWidget({Key? key, required this.endTime})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Text('Competition ends in... '),
          CountdownTimer(
            endTime: endTime,
            textStyle: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

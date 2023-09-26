import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Leaderboard extends StatefulWidget {
  const Leaderboard({Key? key}) : super(key: key);

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leaderboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Time'),
              Tab(text: 'Distance'),
              Tab(text: 'Elevation'),
            ],
          ),
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

  const LeaderboardTab({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Define a function to calculate current totals
    Future<void> updateCurrentTotals(String email) async {
      // Get all activities for the user
      final userActivitiesQuery = await FirebaseFirestore.instance
          .collection('activities')
          .where('user_email', isEqualTo: email)
          .get();

      double totalMovingTime = 0;
      double totalDistance = 0;
      double totalElevation = 0;

// Calculate totals from user activities
      for (final activity in userActivitiesQuery.docs) {
        final activityData = activity.data() as Map<String, dynamic>;
        totalMovingTime += activityData['moving_time'];
        totalDistance += activityData['distance'];

        // Convert elevation_gain to a number (if it's stored as a string)
        final elevationGain = activityData['elevation_gain'] is String
            ? double.tryParse(activityData['elevation_gain'] ?? '')?.toInt() ??
                0
            : (activityData['elevation_gain'] ?? 0);
        totalElevation += elevationGain;
      }

// Update the currentTotals in the user's document
      await FirebaseFirestore.instance.collection('Users').doc(email).update({
        'currentTotals.time': totalMovingTime,
        'currentTotals.distance': totalDistance,
        'currentTotals.elevation': totalElevation,
      });
    }

    String formatDuration(int seconds) {
      final Duration duration = Duration(seconds: seconds);
      final int hours = duration.inHours;
      final int minutes = (duration.inMinutes % 60);
      final int remainingSeconds = (duration.inSeconds % 60);
      return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }

    return Scaffold(
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('activities').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(); // Loading indicator while data is being fetched
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          // Process and aggregate data based on the title (full name) of activities
          final activityDocs = snapshot.data!.docs;
          final activityData = groupAndAggregateData(activityDocs, title);

          return ListView.builder(
            itemCount: activityData[title]!.length,
            itemBuilder: (context, index) {
              final entry = activityData[title]![index];
              final currentPlace = index + 1;
              Widget dataWidget;

              if (title == 'Moving Time') {
                dataWidget = ListTile(
                  title: Text('${entry['full_name']}'),
                  leading: Text('Place: $currentPlace'),
                  subtitle: Text(
                      'Moving Time: ${formatDuration(entry['total_moving_time'])}'),
                );
              } else if (title == 'Total Distance (km)') {
                dataWidget = ListTile(
                  title: Text('${entry['full_name']}'),
                  leading: Text('Place: $currentPlace'),
                  subtitle: Text(
                    'Total Distance: ${(entry['total_distance'] / 1000).toStringAsFixed(2)} km',
                  ),
                );
              } else if (title == 'Total Elevation') {
                dataWidget = ListTile(
                  title: Text('${entry['full_name']}'),
                  leading: Text('Place: $currentPlace'),
                  subtitle:
                      Text('Total Elevation: ${entry['total_elevation']} m'),
                );
              } else {
                dataWidget = const SizedBox();
              }

              return dataWidget;
            },
          );
        },
      ),
    );
  }

  Widget buildListTile(Map<String, dynamic> entry, String field, String unit) {
    final currentPlace = calculateCurrentPlace(entry, field);
    final arrowIcon =
        currentPlace > 0 ? Icons.arrow_upward : Icons.arrow_downward;

    return ListTile(
      leading: Text('Place: ${currentPlace.abs()}'),
      title: Text('Full Name: ${entry['full_name']}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title: ${entry[field]} $unit'),
          Icon(
            arrowIcon,
            color: currentPlace > 0 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  int calculateCurrentPlace(Map<String, dynamic> entry, String field) {
    // Implement your logic to calculate the current place based on the field.
    // Compare the entry with others and return the difference in places.
    // For example:
    // return entry['current_place'] - entry['previous_place'];

    // Replace the placeholder with your actual logic
    return 0;
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
}

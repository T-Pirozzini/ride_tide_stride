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
      length: 3, // Number of tabs
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
            // Add your leaderboard widgets for each tab here
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

    Future<void> updateLeaderboardWithNewEntry(String email, int newMovingTime,
        int newDistance, int newElevation) async {
      // Get the current leaderboard data for 'moving_time'
      final leaderboardData = await FirebaseFirestore.instance
          .collection('Leaderboard')
          .doc('moving_time')
          .get();

      // Extract the current leaderboard data
      final data = leaderboardData.data() as Map<String, dynamic>;
      print(data);

      // Calculate the current place for the new entry
      int currentTimePlace = 1;
      for (final entry in data.entries) {
        final int existingMovingTime = entry.value;
        if (newMovingTime < existingMovingTime) {
          currentTimePlace++;
        }
      }
      int currentDistancePlace = 1;
      for (final entry in data.entries) {
        final int existingDistance = entry.value;
        if (newDistance < existingDistance) {
          currentDistancePlace++;
        }
      }
      int currentElevationPlace = 1;
      for (final entry in data.entries) {
        final int existingElevation = entry.value;
        if (newElevation < existingElevation) {
          currentElevationPlace++;
        }
      }

      // Update the user's current place for 'moving_time' in Firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser?.email)
          .update({'leaderboard_places.moving_time': currentTimePlace});

      // Update the leaderboard data with the new entry
      data['movingTime'] = newMovingTime;
      await FirebaseFirestore.instance
          .collection('Leaderboard')
          .doc('moving_time')
          .set(data);

      // Update the user's current place for 'moving_time' in Firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser?.email)
          .update({'leaderboard_places.distance': currentDistancePlace});

      // Update the leaderboard data with the new entry
      data['movingTime'] = newMovingTime;
      await FirebaseFirestore.instance
          .collection('Leaderboard')
          .doc('distance')
          .set(data);

      // Update the user's current place for 'moving_time' in Firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser?.email)
          .update({'leaderboard_places.elevation_gain': currentElevationPlace});

      // Update the leaderboard data with the new entry
      data['movingTime'] = newMovingTime;
      await FirebaseFirestore.instance
          .collection('Leaderboard')
          .doc('elevation_gain')
          .set(data);
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
          final activityData = groupAndAggregateData(activityDocs);

          return ListView.builder(
            itemCount: activityData.length,
            itemBuilder: (context, index) {
              final entry = activityData[index];
              final currentPlace = index + 1;
              Widget dataWidget;

              if (title == 'Moving Time') {
                dataWidget = ListTile(
                  title: Text('${entry['full_name']}'),
                  leading: Text('Place: $currentPlace'),
                  subtitle: Text(
                      'Moving Time: ${formatDuration(entry['total_moving_time'])}'),
                  trailing: Icon(
                    currentPlace > 0
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: currentPlace > 0 ? Colors.green : Colors.red,
                  ),
                );
              } else if (title == 'Total Distance (km)') {
                dataWidget = ListTile(
                  title: Text('${entry['full_name']}'),
                  leading: Text('Place: $currentPlace'),
                  subtitle: Text(
                    'Total Distance: ${(entry['total_distance'] / 1000).toStringAsFixed(2)} km',
                  ),
                  trailing: Icon(
                    currentPlace > 0
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: currentPlace > 0 ? Colors.green : Colors.red,
                  ),
                );
              } else if (title == 'Total Elevation') {
                dataWidget = ListTile(
                  title: Text('${entry['full_name']}'),
                  leading: Text('Place: $currentPlace'),
                  subtitle:
                      Text('Total Elevation: ${entry['total_elevation']} m'),
                  trailing: Icon(
                    currentPlace > 0
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: currentPlace > 0 ? Colors.green : Colors.red,
                  ),
                );
              } else {
                dataWidget = const SizedBox();
              }

              return dataWidget;
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Get the current user's email
          final currentUser = FirebaseAuth.instance.currentUser;
          final email = currentUser?.email;

          // Get the current user's moving time
          final userDoc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(email)
              .get();
          final userData = userDoc.data() as Map<String, dynamic>;
          final movingTime = userData['moving_time'];
          final distance = userData['distance'];
          final elevation = userData['elevation_gain'];

          // Update the leaderboard with the new entry
          await updateLeaderboardWithNewEntry(
              email!, movingTime, distance, elevation);
        },
        child: const Icon(Icons.add),
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

  Future<QuerySnapshot> fetchDataBasedOnTitle(String title) async {
    // Fetch data based on the title (full name) of activities
    final querySnapshot = await FirebaseFirestore.instance
        .collection('activities')
        .where('fullname', isEqualTo: title) // Adjust this condition as needed
        .get();
    return querySnapshot;
  }

  List<Map<String, dynamic>> groupAndAggregateData(
      List<QueryDocumentSnapshot> activityDocs) {
    // Create a map to group and aggregate data by full name
    final Map<String, Map<String, dynamic>> aggregatedData = {};

    // Iterate through activity documents and aggregate data
    for (final doc in activityDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final fullName = data['fullname'] as String;

      // Convert elevation_gain to a number (if it's stored as a string)
      final elevationGain = data['elevation_gain'] is String
          ? double.tryParse(data['elevation_gain'] ?? '') ?? 0.0
          : (data['elevation_gain'] ?? 0.0);

      if (aggregatedData.containsKey(fullName)) {
        // If full name already exists, update aggregated data
        aggregatedData[fullName]!['total_moving_time'] += data['moving_time'];
        aggregatedData[fullName]!['total_distance'] += data['distance'];
        aggregatedData[fullName]!['total_elevation'] += elevationGain;
      } else {
        // If full name doesn't exist, create a new entry
        aggregatedData[fullName] = {
          'full_name': fullName,
          'total_moving_time': data['moving_time'],
          'total_distance': data['distance'],
          'total_elevation': elevationGain,
        };
      }
    }

    // Convert the map to a list
    final aggregatedList = aggregatedData.values.toList();

    // Sort the list by a specific field, e.g., total moving time
    aggregatedList.sort(
        (a, b) => b['total_moving_time'].compareTo(a['total_moving_time']));

    return aggregatedList;
  }
}

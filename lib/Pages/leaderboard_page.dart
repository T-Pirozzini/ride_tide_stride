import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Leaderboard extends StatefulWidget {
  const Leaderboard({Key? key}) : super(key: key);

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text('Leaderboard'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Moving Time'),
              Tab(text: 'Total Distance (km)'),
              Tab(text: 'Total Elevation'),
            ],
          ),
        ),
        body: TabBarView(
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

  const LeaderboardTab({required this.title});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(      
      future: FirebaseFirestore.instance.collection('activities').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Loading indicator while data is being fetched
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
            Widget dataWidget;
            
            if (title == 'Moving Time') {
              dataWidget = ListTile(
                title: Text('Full Name: ${entry['full_name']}'),
                subtitle:
                    Text('Moving Time: ${entry['total_moving_time']} seconds'),
              );
            } else if (title == 'Total Distance (km)') {
              dataWidget = ListTile(
                title: Text('Full Name: ${entry['full_name']}'),
                subtitle: Text('Total Distance: ${entry['total_distance']} km'),
              );
            } else if (title == 'Total Elevation') {
              dataWidget = ListTile(
                title: Text('Full Name: ${entry['full_name']}'),
                subtitle: Text('Total Elevation: ${entry['total_elevation']}'),
              );
            } else {
              dataWidget = SizedBox();
            }

            return dataWidget;
          },
        );
      },
    );
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

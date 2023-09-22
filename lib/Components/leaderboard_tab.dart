import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardTab extends StatelessWidget {
  final String title;

  const LeaderboardTab({required this.title});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      // Replace 'activities' with the name of your Firestore collection
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
            return ListTile(
              title: Text('Full Name: ${entry['full_name']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Moving Time: ${entry['total_moving_time']} seconds'),
                  Text('Total Distance: ${entry['total_distance']} km'),
                  Text('Total Elevation: ${entry['total_elevation']}'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> groupAndAggregateData(List<QueryDocumentSnapshot> activityDocs) {
    // Create a map to group and aggregate data by full name
    final Map<String, Map<String, dynamic>> aggregatedData = {};

    // Iterate through activity documents and aggregate data
    for (final doc in activityDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final fullName = data['full_name'] as String;

      if (aggregatedData.containsKey(fullName)) {
        // If full name already exists, update aggregated data
        aggregatedData[fullName]!['total_moving_time'] += data['moving_time'];
        aggregatedData[fullName]!['total_distance'] += data['distance'];
        aggregatedData[fullName]!['total_elevation'] += data['elevation_gain'];
      } else {
        // If full name doesn't exist, create a new entry
        aggregatedData[fullName] = {
          'full_name': fullName,
          'total_moving_time': data['moving_time'],
          'total_distance': data['distance'],
          'total_elevation': data['elevation_gain'],
        };
      }
    }

    // Convert the map to a list
    final aggregatedList = aggregatedData.values.toList();

    // Sort the list by a specific field, e.g., total moving time
    aggregatedList.sort((a, b) => b['total_moving_time'].compareTo(a['total_moving_time']));

    return aggregatedList;
  }
}
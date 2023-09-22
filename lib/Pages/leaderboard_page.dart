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
    return Scaffold(
      body: FutureBuilder<QuerySnapshot>(
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
              final currentPlace = index + 1;
              Widget dataWidget;

              if (title == 'Moving Time') {
                dataWidget = ListTile(
                  title: Text('Full Name: ${entry['full_name']}'),
                  leading: Text('Place: $currentPlace'),
                  subtitle: Text(
                      'Moving Time: ${entry['total_moving_time']} seconds'),
                  trailing: Icon(
                    currentPlace > 0
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: currentPlace > 0 ? Colors.green : Colors.red,
                  ),
                );
              } else if (title == 'Total Distance (km)') {
                dataWidget = ListTile(
                  title: Text('Full Name: ${entry['full_name']}'),
                  leading: Text('Place: $currentPlace'),
                  subtitle:
                      Text('Total Distance: ${entry['total_distance']} km'),
                  trailing: Icon(
                    currentPlace > 0
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: currentPlace > 0 ? Colors.green : Colors.red,
                  ),
                );
              } else if (title == 'Total Elevation') {
                dataWidget = ListTile(
                  title: Text('Full Name: ${entry['full_name']}'),
                  leading: Text('Place: $currentPlace'),
                  subtitle:
                      Text('Total Elevation: ${entry['total_elevation']}'),
                  trailing: Icon(
                    currentPlace > 0
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: currentPlace > 0 ? Colors.green : Colors.red,
                  ),
                );
              } else {
                dataWidget = SizedBox();
              }

              return dataWidget;
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        // child: Icon(Icons.refresh),
        onPressed: () async {
          //   try {
          //                 final previousPlace = entry['previous_place'];

          //                 if (currentPlace < previousPlace) {
          //                   // The current position is better (closer to 1)

          //                   // Update Firestore document
          //                   final docId = entry[
          //                       'activity_id']; // Replace with the actual document ID
          //                   final firestore = FirebaseFirestore.instance;
          //                   await firestore
          //                       .collection('activities')
          //                       .doc(docId)
          //                       .update({
          //                     'previous_place': currentPlace,
          //                     // You can update other fields as needed
          //                   });

          //                   // Optionally, display a success message or perform other actions
          //                 } else {
          //                   // The current position is not better (or equal)
          //                   // You can display a message or take other actions as needed
          //                 }
          //               } catch (e) {
          //                 print('Error in reset button onPressed: $e');
          //               }
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

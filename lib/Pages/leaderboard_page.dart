import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:intl/intl.dart';
// import 'package:google_fonts/google_fonts.dart';

class Leaderboard extends StatefulWidget {
  const Leaderboard({Key? key}) : super(key: key);

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  final currentUser = FirebaseAuth.instance.currentUser;

  // Create a variable to represent the current date
  DateTime currentDate = DateTime.now();
  // Define a flag to track whether the user is an admin
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();

    // Check the user's role when the widget is initialized
    checkUserRole();
  }

  // Function to check the user's role
  void checkUserRole() async {
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser?.email)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final userRole = userData['role'];

        // Check if the user's role is 'admin'
        if (userRole == 'admin') {
          setState(() {
            isAdmin = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final endTime = endOfMonth.millisecondsSinceEpoch;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFDFD3C3),
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
            CountdownTimerWidget(
              endTime: endTime,
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            LeaderboardTab(title: 'Moving Time'),
            LeaderboardTab(title: 'Total Distance (km)'),
            LeaderboardTab(title: 'Total Elevation'),
          ],
        ),
        floatingActionButton: isAdmin
            ? FloatingActionButton(
                onPressed: () {
                  // Only show the button and handle the action if the user is an admin
                  _saveResultsToFirestore();
                },
                child: const Icon(Icons.save),
              )
            : null, // Set to null if the user is not an admin
      ),
    );
  }
}

// Function to save results to Firestore
void _saveResultsToFirestore() async {
  final currentMonth = DateTime.now().month;
  final currentYear = DateTime.now().year;
  final firstDayOfMonth = DateTime(currentYear, currentMonth, 1);
  final lastDayOfMonth = DateTime(currentYear, currentMonth + 1, 0);

  // Fetch data for the current month
  final snapshot = await FirebaseFirestore.instance
      .collection('activities')
      .where('start_date',
          isGreaterThanOrEqualTo: firstDayOfMonth.toUtc().toIso8601String())
      .where('start_date',
          isLessThanOrEqualTo: lastDayOfMonth.toUtc().toIso8601String())
      .get();

  // Extract the relevant data (e.g., fullname and totals) and save it to the Results collection
  final resultsData = snapshot.docs.map((doc) {
    final data = doc.data();

    // Create a results object with the desired structure
    final results = {
      'moving_time': data['moving_time'],
      'distance': data['distance'],
      'elevation_gain': data['elevation_gain'],
    };

    return {
      'fullname': data['fullname'],
      'totals': results,
    };
  }).toList();

  // Save the data to the Results collection
  await FirebaseFirestore.instance.collection('Results').add({
    'timestamp': Timestamp.now(),
    'data': resultsData,
  });
}

class LeaderboardTab extends StatelessWidget {
  final String title;

  const LeaderboardTab({Key? key, required this.title}) : super(key: key);

  // Function to fetch user activities
  Future<List<Map<String, dynamic>>> fetchUserActivities(
      String fullName) async {
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;
    final firstDayOfMonth = DateTime(currentYear, currentMonth, 1);
    final lastDayOfMonth = DateTime(currentYear, currentMonth + 1, 0);

    final snapshot = await FirebaseFirestore.instance
        .collection('activities')
        .where('fullname', isEqualTo: fullName)
        .get();

    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .where((data) {
      final startDate = DateTime.parse(data['start_date']);
      return startDate.isAfter(firstDayOfMonth) &&
          startDate.isBefore(lastDayOfMonth);
    }).toList();
  }

  // Function to build activities list
  Widget buildActivitiesList(List<Map<String, dynamic>> activities) {
    // Sort the activities list by 'start_date' in descending order (most recent first).
    activities.sort((a, b) => DateTime.parse(b['start_date'])
        .compareTo(DateTime.parse(a['start_date'])));

    return SingleChildScrollView(
      child: Column(
        children: activities.map((activity) {
          //calculation for pace
          double speedMps =
              activity['average_speed']; // Speed in meters per second
          double speedKph = speedMps * 3.6; // Convert to km/h
          double pace = 60 / speedKph;
          int minutes = pace.floor();
          int seconds = ((pace - minutes) * 60).round();
          // Helper function to format duration
          String formatDuration(int seconds) {
            final Duration duration = Duration(seconds: seconds);
            final int hours = duration.inHours;
            final int minutes = (duration.inMinutes % 60);
            final int remainingSeconds = (duration.inSeconds % 60);
            return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
          }

          // Helper function to format the date
          String formatDate(String startDate) {
            final DateTime date = DateTime.parse(startDate);
            return DateFormat.yMMMd().format(date); // e.g., Sep 26, 2023
          }

          return Card(
            margin: const EdgeInsets.all(2),
            elevation: 1,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF283d3b),
                foregroundColor: Colors.white,
                child: getIconForActivityType(activity['type']),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatDate(activity['start_date']),
                    style: const TextStyle(
                        fontSize: 8.0,
                        color: Colors.grey,
                        fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    activity['name'],
                    style: const TextStyle(
                        fontSize: 14.0, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              subtitle: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatDuration(activity['moving_time']),
                    style: const TextStyle(fontSize: 12.0),
                  ),
                  Text(
                    '${(activity['distance'] / 1000).toStringAsFixed(2)} km',
                    style: const TextStyle(fontSize: 12.0),
                  ),
                  Text(
                    '${activity['elevation_gain']} m',
                    style: const TextStyle(fontSize: 12.0),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flash_on,
                          color: Colors.yellow[600], size: 20.0),
                      const SizedBox(width: 4.0),
                      Text(
                        '${activity['average_watts'].toString()} W',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.speed_outlined,
                          color: Colors.red[600], size: 20.0),
                      const SizedBox(width: 4.0),
                      Text(
                        '$minutes:${seconds.toString().padLeft(2, '0')} /km',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        }).toList(),
      ),
    );
  }

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
                tileColor: Colors.white,
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

            return GestureDetector(
              onTap: () {
                final localContext = context;
                fetchUserActivities(entry['full_name']).then(
                  (activities) {
                    showDialog(
                      context: localContext,
                      builder: (context) => AlertDialog(
                        title: Text('${entry['full_name']}\'s Activities'),
                        content: SizedBox(
                            height: 400,
                            width: 300,
                            child: buildActivitiesList(activities)),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Close'),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
              child: Column(
                children: [
                  dataWidget,
                  const Divider(
                    color: Colors.grey,
                    thickness: 1.0,
                    height: 0.0,
                  ),
                ],
              ),
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

  Widget getIconForActivityType(String type) {
    switch (type) {
      case 'Run':
        return const Icon(Icons.directions_run_outlined);
      case 'Ride':
        return const Icon(Icons.directions_bike_outlined);
      case 'Swim':
        return const Icon(Icons.pool_outlined);
      case 'Walk':
        return const Icon(Icons.directions_walk_outlined);
      case 'Hike':
        return const Icon(Icons.terrain_outlined);
      case 'AlpineSki':
        return const Icon(Icons.downhill_skiing_outlined);
      case 'BackcountrySki':
        return const Icon(Icons.downhill_skiing_outlined);
      case 'Canoeing':
        return const Icon(Icons.kayaking_outlined);
      case 'Crossfit':
        return const Icon(Icons.fitness_center_outlined);
      case 'EBikeRide':
        return const Icon(Icons.electric_bike_outlined);
      case 'Elliptical':
        return const Icon(Icons.fitness_center_outlined);
      case 'Handcycle':
        return const Icon(Icons.directions_bike_outlined);
      case 'IceSkate':
        return const Icon(Icons.ice_skating_outlined);
      case 'InlineSkate':
        return const Icon(Icons.roller_skating_outlined);
      case 'Kayaking':
        return const Icon(Icons.kayaking_outlined);
      case 'Kitesurf':
        return const Icon(Icons.kitesurfing_outlined);
      case 'NordicSki':
        return const Icon(Icons.snowboarding_outlined);
      case 'RockClimbing':
        return const Icon(Icons.terrain_outlined);
      case 'RollerSki':
        return const Icon(Icons.directions_bike_outlined);
      case 'Rowing':
        return const Icon(Icons.kayaking_outlined);
      case 'Snowboard':
        return const Icon(Icons.snowboarding_outlined);
      case 'Snowshoe':
        return const Icon(Icons.snowshoeing_outlined);
      case 'StairStepper':
        return const Icon(Icons.fitness_center_outlined);
      case 'StandUpPaddling':
        return const Icon(Icons.kayaking_outlined);
      case 'Surfing':
        return const Icon(Icons.surfing_outlined);
      case 'VirtualRide':
        return const Icon(Icons.directions_bike_outlined);
      case 'VirtualRun':
        return const Icon(Icons.directions_run_outlined);
      case 'WeightTraining':
        return const Icon(Icons.fitness_center_outlined);
      case 'Windsurf':
        return const Icon(Icons.surfing_outlined);
      case 'Workout':
        return const Icon(Icons.fitness_center_outlined);
      case 'Yoga':
        return const Icon(Icons.fitness_center_outlined);
      default:
        return Text(type);
    }
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

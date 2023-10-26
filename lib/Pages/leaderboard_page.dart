import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ride_tide_stride/components/timer.dart';
import 'package:url_launcher/url_launcher.dart';

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
    // final testTime =
    //     DateTime.now().millisecondsSinceEpoch + 5000; // 5 seconds from now

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
              onTimerEnd: _saveResultsToFirestore,
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
  String formattedDate =
      DateFormat('MMMM yyyy').format(DateTime(currentYear, currentMonth));

  // Fetch data for the current month
  final snapshot = await FirebaseFirestore.instance
      .collection('activities')
      .where('start_date',
          isGreaterThanOrEqualTo: firstDayOfMonth.toUtc().toIso8601String())
      .where('start_date',
          isLessThanOrEqualTo: lastDayOfMonth.toUtc().toIso8601String())
      .get();

  Map<String, Map<String, dynamic>> aggregatedData = {};

  for (var doc in snapshot.docs) {
    final data =
        doc.data() as Map<String, dynamic>; // Cast to Map<String, dynamic>
    final fullname = data['fullname'];

    if (!aggregatedData.containsKey(fullname)) {
      aggregatedData[fullname] = {
        'fullname': fullname,
        'totals': {
          'moving_time': 0.0,
          'distance': 0.0,
          'elevation_gain': 0.0,
        }
      };
    }

    aggregatedData[fullname]?['totals']['moving_time'] += data['moving_time'];
    aggregatedData[fullname]?['totals']['distance'] += data['distance'];
    aggregatedData[fullname]?['totals']['elevation_gain'] +=
        data['elevation_gain'];
  }

  for (var user in aggregatedData.keys) {
    final userData = aggregatedData[user];

    DocumentReference userRef =
        FirebaseFirestore.instance.collection('UserTopStats').doc(user);
    DocumentSnapshot userSnapshot = await userRef.get();
    Map<String, dynamic> userDoc;

    if (userSnapshot.data() is Map) {
      userDoc = Map<String, dynamic>.from(userSnapshot.data() as Map);
    } else {
      userDoc = {};
    }

    bool shouldUpdate = false;

    if (userData?['totals']['distance'] > (userDoc['top_distance'] ?? 0.0)) {
      userDoc['top_distance'] = userData?['totals']['distance'];
      userDoc['top_distance_month'] = formattedDate;
      shouldUpdate = true;
    }

    if (userData?['totals']['moving_time'] >
        (userDoc['top_moving_time'] ?? 0.0)) {
      userDoc['top_moving_time'] = userData?['totals']['moving_time'];
      userDoc['top_moving_time_month'] = formattedDate;
      shouldUpdate = true;
    }

    if (userData?['totals']['elevation_gain'] >
        (userDoc['top_elevation'] ?? 0.0)) {
      userDoc['top_elevation'] = userData?['totals']['elevation_gain'];
      userDoc['top_elevation_month'] = formattedDate;
      shouldUpdate = true;
    }

    if (shouldUpdate) {
      await userRef.set(userDoc, SetOptions(merge: true));
    }
  }

  // Convert the map into a list
  final resultsData = aggregatedData.values.toList();

  // Sort and extract rankings
  final rankingsByTime = List.from(resultsData)
    ..sort((a, b) =>
        b['totals']['moving_time'].compareTo(a['totals']['moving_time']));

  final rankingsByDistance = List.from(resultsData)
    ..sort(
        (a, b) => b['totals']['distance'].compareTo(a['totals']['distance']));

  final rankingsByElevation = List.from(resultsData)
    ..sort((a, b) =>
        b['totals']['elevation_gain'].compareTo(a['totals']['elevation_gain']));

  final currentDate = DateTime.now();
  final month = DateFormat('MMMM').format(currentDate);
  final year = currentDate.year.toString();
  final documentName = '$month $year';
  // Save the data and rankings to the Results collection
  await FirebaseFirestore.instance.collection('Results').doc(documentName).set({
    'timestamp': Timestamp.now(),
    'data': resultsData,
    'rankings_by_time': rankingsByTime,
    'rankings_by_distance': rankingsByDistance,
    'rankings_by_elevation': rankingsByElevation,
  });
}

class LeaderboardTab extends StatelessWidget {
  final String title;

  const LeaderboardTab({Key? key, required this.title}) : super(key: key);

  // strava dialog
  void _showStravaDialog(BuildContext context, int activityId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/strava.png',
              height: 24.0, // Adjust the size as required
              width: 24.0,
            ),
            SizedBox(width: 10),
            Text('View Activity on Strava?'),
          ],
        ),
        content: Text('Please Note: You will be leaving R.T.S'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                child: Text('Cancel', style: TextStyle(fontSize: 18)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              SizedBox(width: 10),
              TextButton(
                child: Text('Open',
                    style: TextStyle(color: Colors.deepOrange, fontSize: 18)),
                onPressed: () {
                  _openStravaActivity(activityId);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // redirect to Strava
  Future<void> _openStravaActivity(int activityId) async {
    final Uri url = Uri.https('www.strava.com', '/activities/$activityId');

    bool canOpen = await canLaunchUrl(url);
    if (canOpen) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Handle the inability to launch the URL.
      print('Could not launch $url');
    }
  }

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

    return LayoutBuilder(
      builder: (context, constraints) {
        double deviceHeight = constraints.maxHeight;
        double deviceWidth = constraints.maxWidth;
        double topPadding = MediaQuery.of(context).padding.top;
        double bottomPadding = MediaQuery.of(context).padding.bottom;
        double usableHeight = deviceHeight - topPadding - bottomPadding;

        double fontSizeForDate = usableHeight * 0.015;
        double fontSizeForName = usableHeight * 0.02;

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

              return GestureDetector(
                onTap: () {
                  if (activity['activity_id'] != null) {
                    _showStravaDialog(context, activity['activity_id']!);
                  } else {
                    print('Activity does not have an ID.');
                  }
                },
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color.fromARGB(167, 40, 61, 59),
                      foregroundColor: Colors.white,
                      child: getIconForActivityType(activity['type']),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatDate(activity['start_date']),
                          style: TextStyle(
                              fontSize: fontSizeForDate,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          activity['name'],
                          style: TextStyle(
                              fontSize: fontSizeForName,
                              fontWeight: FontWeight.w600),
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
                            activity['average_watts'] != null
                                ? Text(
                                    '${activity['average_watts'].toString()} W',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  )
                                : Text('0 W'),
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
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
                double deviceHeight = MediaQuery.of(localContext).size.height;
                double deviceWidth = MediaQuery.of(localContext).size.width;
                double dialogHeight = deviceHeight * 0.6;
                double dialogWidth = deviceWidth * 0.95;
                fetchUserActivities(entry['full_name']).then(
                  (activities) {
                    showDialog(
                      context: localContext,
                      builder: (context) => AlertDialog(
                        title: Text('${entry['full_name']}\'s Activities'),
                        content: SizedBox(
                            height: dialogHeight,
                            width: dialogWidth,
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

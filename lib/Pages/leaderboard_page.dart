import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ride_tide_stride/components/leaderboard_dialog.dart';
import 'package:ride_tide_stride/components/timer.dart';

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
    final endOfMonth =
        DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
    final endTime =
        DateTime(endOfMonth.year, endOfMonth.month, endOfMonth.day, 23, 59, 59)
            .millisecondsSinceEpoch;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFDFD3C3),
        appBar: AppBar(
          title: Text(
            'Leaderboard',
            style: GoogleFonts.tektur(
                textStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.2,
                    color: Colors.white)),
          ),
          bottom: TabBar(
            labelStyle:
                GoogleFonts.tektur(textStyle: TextStyle(color: Colors.white)),
            tabs: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timelapse),
                  SizedBox(width: 4),
                  Tab(text: 'Time'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.straighten),
                  SizedBox(width: 4),
                  Tab(text: 'Distance'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.landscape),
                  SizedBox(width: 4),
                  Tab(text: 'Elevation'),
                ],
              ),
            ],
          ),
          actions: [
            CountdownTimerWidget(
              endTime: endTime,
              onTimerEnd: _saveResultsToFirestore,
            ),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          color: Colors
              .white, // This sets the background color of the BottomAppBar
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              // Place your buttons here
              // ElevatedButton(
              //   onPressed: () {
              //     Navigator.of(context).pushNamed('/resultsPage');
              //   },
              //   child: const Text('View Past Results'),
              // ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/awardsPage');
                },
                child: const Text('View Awards'),
              ),              
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

// Function to save results to Firestore
void _saveResultsToFirestore() async {
  final currentMonth = DateTime.now().month;
  final currentYear = DateTime.now().year;
  final firstDayOfMonth = DateTime(currentYear, currentMonth, 1);
  final lastDayOfMonth = DateTime(currentYear, currentMonth + 1, 1)
      .subtract(const Duration(days: 1));

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

  // Function to fetch user activities
  Future<List<Map<String, dynamic>>> fetchUserActivities(
      String fullName) async {
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;
    final firstDayOfMonth = DateTime(currentYear, currentMonth, 1);
    final lastDayOfMonth =
        DateTime(currentYear, currentMonth + 1, 1, 23, 59, 59)
            .subtract(const Duration(days: 1));

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
              dataWidget = buildListTile('Total Elevation',
                  '${entry['total_elevation'].toStringAsFixed(1)} m');
            } else {
              dataWidget = const SizedBox();
            }

            return GestureDetector(
              onTap: () {
                final localContext = context;
                double deviceHeight = MediaQuery.of(localContext).size.height;
                double deviceWidth = MediaQuery.of(localContext).size.width;
                double dialogHeight = deviceHeight * 0.6;
                double dialogWidth = deviceWidth * 0.9;
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _showProfileDialog(
                                      context, entry['full_name']);
                                },
                                child: Text('View Profile'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Close'),
                              ),
                            ],
                          ),
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
    const color = Color(0xFFA09A6A);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.0),
      ),
      padding: const EdgeInsets.all(8.0),
      constraints: const BoxConstraints(
        minWidth: 40.0,
        minHeight: 40.0,
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Text(
            place,
            style: const TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
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
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime.utc(now.year, now.month + 1, 1, 23, 59, 59)
        .subtract(const Duration(days: 1));

    return FirebaseFirestore.instance
        .collection('activities')
        .where('start_date',
            isGreaterThanOrEqualTo: firstDayOfMonth.toUtc().toIso8601String())
        .where('start_date',
            isLessThanOrEqualTo: endOfMonth.toUtc().toIso8601String())
        .snapshots();
  }

  void _showProfileDialog(context, fullName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder(
          future: findHighestAverageWatts(fullName),
          builder:
              (BuildContext context, AsyncSnapshot<double?> avgWattsSnapshot) {
            if (avgWattsSnapshot.hasError) {
              return const Text('Something went wrong');
            }
            if (avgWattsSnapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading');
            }

            final highestAverageWatts = avgWattsSnapshot.data;

            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(fullName,
                      style: GoogleFonts.syne(
                          textStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black))),
                  ClipOval(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                              200), // Adjust the radius value as needed
                          child: Container(
                            width: 400,
                            height: 300,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(
                                    'assets/images/power_level_3.png'),
                                fit: BoxFit.fitHeight,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(20),
                            child: Container(
                              color: Colors.black,
                              child: Column(
                                children: [
                                  Text('Power Level',
                                      style: GoogleFonts.syne(
                                          textStyle: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white))),
                                  Text(
                                    '${highestAverageWatts ?? "N/A"}', // Display highest average watts
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.syne(
                                      textStyle: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<double?> findHighestAverageWatts(String fullName) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('activities')
        .where('fullname', isEqualTo: fullName)
        .get();

    final activities =
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    if (activities.isEmpty) {
      return null; // No activities found for the user
    }

    double? highestAverageWatts;

    for (final activity in activities) {
      final averageWatts = activity['average_watts'] as double?;

      if (averageWatts != null) {
        if (highestAverageWatts == null || averageWatts > highestAverageWatts) {
          highestAverageWatts = averageWatts;
        }
      }
    }

    return highestAverageWatts;
  }
}

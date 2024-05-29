import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ride_tide_stride/screens/leaderboard/leaderboard_tab.dart';
import 'package:ride_tide_stride/screens/leaderboard/timer.dart';
import 'package:ride_tide_stride/theme.dart';

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
      length: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondaryColor,
              AppColors.backgroundColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Leaderboard',
                  style: GoogleFonts.tektur(
                    textStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.2,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
            bottom: TabBar(
              labelStyle:
                  GoogleFonts.tektur(textStyle: TextStyle(color: Colors.white)),
              tabs: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stars),
                    SizedBox(width: 4),
                    Tab(text: 'Overall'),
                  ],
                ),
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
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/awardsPage');
                  },
                  child: const Text('View Awards'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/usersPage');
                  },
                  child: const Text('View Users'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/activitiesPage');
                  },
                  child: const Text('View Monthly Activities'),
                ),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              LeaderboardTab(title: 'Overall'),
              LeaderboardTab(title: 'Moving Time'),
              LeaderboardTab(title: 'Total Distance (km)'),
              LeaderboardTab(title: 'Total Elevation'),
            ],
          ),
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

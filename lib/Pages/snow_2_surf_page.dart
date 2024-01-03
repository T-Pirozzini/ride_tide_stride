import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

class Snow2Surf extends StatefulWidget {
  const Snow2Surf({super.key});

  @override
  State<Snow2Surf> createState() => _Snow2SurfState();
}

class _Snow2SurfState extends State<Snow2Surf> {
  List<Map<String, dynamic>> categories = [
    {
      'name': 'Alpine Ski',
      'type': ['Snowboard', 'AlpineSki'],
      'icon': Icons.downhill_skiing_outlined,
      'info': 'fastest 5km time',
      'current': {
        'user': 'User',
        'time': 'Time',
      },
      'record': {
        'user': 'User',
        'time': 'Time',
      }
    },
    {
      'name': 'Cross Country Ski',
      'type': ['NordicSki'],
      'icon': Icons.downhill_skiing_outlined,
      'info': 'fastest 5km time',
      'current': {
        'user': 'User',
        'time': 'Time',
      },
      'record': {
        'user': 'User',
        'time': 'Time',
      }
    },
    {
      'name': 'Road Run',
      'type': ['VirtualRun', 'Run'],
      'icon': Icons.directions_run_outlined,
      'info': 'fastest 5km time',
      'current': {
        'user': 'User',
        'time': 'Time',
      },
      'record': {
        'user': 'User',
        'time': 'Time',
      }
    },
    {
      'name': 'Trail Run',
      'type': ['Run'],
      'icon': Icons.directions_run_outlined,
      'info': 'fastest 5km time',
      'current': {
        'user': 'User',
        'time': 'Time',
      },
      'record': {
        'user': 'User',
        'time': 'Time',
      }
    },
    {
      'name': 'Mountain Bike',
      'type': ['Ride'],
      'icon': Icons.directions_bike_outlined,
      'info': 'fastest 5km time',
      'current': {
        'user': 'User',
        'time': 'Time',
      },
      'record': {
        'user': 'User',
        'time': 'Time',
      }
    },
    {
      'name': 'Kayak',
      'type': ['Kayaking'],
      'icon': Icons.kayaking_outlined,
      'info': 'fastest 5km time',
      'current': {
        'user': 'User',
        'time': 'Time',
      },
      'record': {
        'user': 'User',
        'time': 'Time',
      }
    },
    {
      'name': 'Road Bike',
      'type': ['VirtualRide', 'Ride'],
      'icon': Icons.directions_bike_outlined,
      'info': 'fastest 5km time',
      'current': {
        'user': 'User',
        'time': 'Time',
      },
      'record': {
        'user': 'User',
        'time': 'Time',
      }
    },
    {
      'name': 'Canoe',
      'type': ['Canoeing'],
      'icon': Icons.rowing_outlined,
      'info': 'fastest 5km time',
      'current': {
        'user': 'User',
        'time': 'Time',
      },
      'record': {
        'user': 'User',
        'time': 'Time',
      }
    },
  ];

  String formattedCurrentMonth = '';

  void getCurrentMonth() {
    final DateTime currentDateTime = DateTime.now();
    String formattedCurrentMonth =
        DateFormat('MMMM yyyy').format(currentDateTime);
    setState(() {
      this.formattedCurrentMonth = formattedCurrentMonth;
    });
  }

  // // Function to fetch user activities
  // Future<List<Map<String, dynamic>>> fetchUserActivities(
  //     String fullName) async {
  //   final currentMonth = DateTime.now().month;
  //   final currentYear = DateTime.now().year;
  //   final firstDayOfMonth = DateTime(currentYear, currentMonth, 1);
  //   final lastDayOfMonth = DateTime(currentYear, currentMonth + 1, 0);

  //   final snapshot = await FirebaseFirestore.instance
  //       .collection('activities')
  //       .where('fullname', isEqualTo: fullName)
  //       .get();

  //   return snapshot.docs
  //       .map((doc) => doc.data() as Map<String, dynamic>)
  //       .where((data) {
  //     final startDate = DateTime.parse(data['start_date']);
  //     return startDate.isAfter(firstDayOfMonth) &&
  //         startDate.isBefore(lastDayOfMonth);
  //   }).toList();
  // }

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

  Map<String, String> calculatePace(List<DocumentSnapshot> docs, String type) {
    List<double> speeds = [];

    for (final doc in docs) {
      if (doc['type'] == type) {
        double averageSpeed = doc['average_speed'];
        speeds.add(averageSpeed);
      }
    }

    if (speeds.isEmpty) {
      return {'pace': 'N/A', 'time': 'N/A'};
    }

    double avgSpeed = speeds.reduce((a, b) => a + b) / speeds.length;
    double speedKph = avgSpeed * 3.6;
    double pace = 60 / speedKph;
    int minutes = pace.floor();
    int seconds = ((pace - minutes) * 60).round();
    String paceString = '$minutes:${seconds.toString().padLeft(2, '0')}';

    double totalTime = pace * 5;
    int totalMinutes = totalTime.floor();
    int totalSeconds = ((totalTime - totalMinutes) * 60).round();
    String timeString =
        '$totalMinutes:${totalSeconds.toString().padLeft(2, '0')}';

    return {'pace': paceString, 'time': timeString};
  }

  Map<String, List<String>> activityTypeToCategory = {
    'RoadBike': ['VirtualRide', 'Ride'],
    'MountainBike': ['Ride'],
    'RoadRun': ['VirtualRun', 'Run'],
    'TrailRun': ['Run'],
    'AlpineSki': ['Snowboard', 'AlpineSki'],
    'CrossCountrySki': ['NordicSki'],
    'Kayak': ['Kayaking'],
    'Canoe': ['Canoeing'],
  };

  Map<String, double> sportDistances = {
    'Run': 5.0,
    'RoadBike': 25.0,
    'MountainBike': 25.0,
    'RoadRun': 5.0,
    'TrailRun': 5.0,
    'AlpineSki': 5.0,
    'CrossCountrySki': 5.0,
    'Kayak': 5.0,
    'Canoe': 5.0,
  };

  void initState() {
    super.initState();
    getCurrentMonth();
  }

  Widget buildCategoryCard(
      List<Map<String, dynamic>> categories, String title) {
    Icon getNumberIcon(int index) {
      switch (index) {
        case 0:
          return Icon(
            Symbols.counter_1_rounded,
            size: 32,
          );
        case 1:
          return Icon(
            Symbols.counter_2_rounded,
            size: 32,
          );
        case 2:
          return Icon(
            Symbols.counter_3_rounded,
            size: 32,
          );
        case 3:
          return Icon(
            Symbols.counter_4_rounded,
            size: 32,
          );
        case 4:
          return Icon(
            Symbols.counter_5_rounded,
            size: 32,
          );
        case 5:
          return Icon(
            Symbols.counter_6_rounded,
            size: 32,
          );
        case 6:
          return Icon(
            Symbols.counter_7_rounded,
            size: 32,
          );
        case 7:
          return Icon(
            Symbols.counter_8_rounded,
            size: 32,
          );
        default:
          return Icon(Icons.looks_one);
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'The top stats for each sport this month - from all user submitted leaderboard entries',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: getCurrentMonthData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              final activityDocs = snapshot.data?.docs ?? [];
              Map<String, Map<String, dynamic>> bestTimes = {};
              for (final doc in activityDocs) {
                String type = doc['type'];
                double averageSpeed = doc['average_speed']; // in m/s
                String fullname = doc['fullname'];
                double distance = sportDistances[type] ??
                    0; // Get the specific distance for the sport
                double timeInSeconds = (distance * 1000) / averageSpeed;
                print(timeInSeconds);

                if (!bestTimes.containsKey(type) ||
                    timeInSeconds < bestTimes[type]?['time']) {
                  bestTimes[type] = {
                    'fullname': fullname,
                    'time': timeInSeconds,
                  };
                  print(bestTimes);
                }
              }              

              return ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  var category = categories[index];
                  List<String> sportTypes = List<String>.from(
                      category['type']); 
                  Map<String, dynamic>? bestTimeEntry;

                  for (String type in sportTypes) {
                    if (bestTimes.containsKey(type)) {
                      if (bestTimeEntry == null ||
                          bestTimes[type]!['time'] < bestTimeEntry['time']) {
                        bestTimeEntry = bestTimes[type];
                      }
                    }
                  }

                  String displayName = bestTimeEntry != null
                      ? bestTimeEntry['fullname']
                      : "User";
                  double totalTime =
                      bestTimeEntry != null ? bestTimeEntry['time'] : 0.0;

                  int totalTimeInSeconds =
                      totalTime.toInt(); 

                  int hours = totalTimeInSeconds ~/ 3600;
                  int minutes = (totalTimeInSeconds % 3600) ~/ 60;
                  int seconds = totalTimeInSeconds % 60;

                  String displayTime = totalTimeInSeconds > 0
                      ? "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}"
                      : "0:00";

                  return ListTile(
                    visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        getNumberIcon(index),
                        SizedBox(width: 8),
                        Icon(categories[index]['icon']),
                      ],
                    ), // Replace with actual icon
                    title: Text(categories[index]['name']),
                    subtitle: Text(displayName),
                    trailing: Text(displayTime),
                  );
                },
              );
            },
          ),
        ),
        Text(
          "Cumulative Time: 00:00:00",
          style: TextStyle(fontSize: 24),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width,
            child: buildCategoryCard(categories, formattedCurrentMonth),
          ),
        ),
      ),
    );
  }
}

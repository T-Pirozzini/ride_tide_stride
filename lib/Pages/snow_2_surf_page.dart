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
              List<double> roadBikeSpeeds = [];
              List<double> runSpeeds = [];

              categories.forEach((category) {
                String categoryName = category['name'];
                List<String> typesToCheck =
                    activityTypeToCategory[categoryName] ?? [];
                Map<String, String> results = {'pace': 'N/A', 'time': 'N/A'};

                for (String type in typesToCheck) {
                  Map<String, String> calcResults =
                      calculatePace(activityDocs, type);
                  // Logic to combine results if needed
                  results['pace'] =
                      calcResults['pace']!; // Or some logic to choose the best
                  results['time'] = calcResults['time']!;
                  results['user'] = 'User';
                }

                category['current']['time'] = results['time'];
                category['current']['user'] = 'User';
              });

              for (final doc in activityDocs) {
                double averageSpeed = doc['average_speed'];
                String fullname = doc['fullname'];
                String date = doc['start_date'];
                String type = doc['type'];
                double distance = doc['distance'];
                print(averageSpeed);
                print(fullname);
                print(date);
                print(type);
                print(distance);
                if (type == 'VirtualRide') {
                  roadBikeSpeeds.add(averageSpeed);
                }
                if (type == 'Run') {
                  runSpeeds.add(averageSpeed);
                }
              }

              double avgRoadBikeSpeed = roadBikeSpeeds.isNotEmpty
                  ? roadBikeSpeeds.reduce((a, b) => a + b) /
                      roadBikeSpeeds.length
                  : 0.0;

              double avgRunSpeed = runSpeeds.isNotEmpty
                  ? runSpeeds.reduce((a, b) => a + b) / runSpeeds.length
                  : 0.0;

              //calculation for pace
              double speedKph = avgRunSpeed * 3.6; // Convert to km/h
              double pace = 60 / speedKph;
              double totalTime = pace * 5; // Total time for 5km
              int totalMinutes = totalTime.floor();
              int totalSeconds = ((totalTime - totalMinutes) * 60).round();
              String runTime =
                  '$totalMinutes:${totalSeconds.toString().padLeft(2, '0')}';

              return ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
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
                    subtitle: Text(categories[index]['current']
                        ['user']), // Replace with actual data
                    trailing: Text(runTime), // Replace with actual data
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

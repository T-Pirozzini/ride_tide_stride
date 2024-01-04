import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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
      'distance': 2.0,
    },
    {
      'name': 'Cross Country Ski',
      'type': ['NordicSki'],
      'icon': Icons.downhill_skiing_outlined,
      'distance': 8.0,
    },
    {
      'name': 'Road Run',
      'type': ['VirtualRun', 'Run'],
      'icon': Icons.directions_run_outlined,
      'distance': 7.0,
    },
    {
      'name': 'Trail Run',
      'type': ['Run'],
      'icon': Icons.directions_run_outlined,
      'distance': 6.0,
    },
    {
      'name': 'Mountain Bike',
      'type': ['Ride'],
      'icon': Icons.directions_bike_outlined,
      'distance': 15.0,
    },
    {
      'name': 'Kayak',
      'type': ['Kayaking'],
      'icon': Icons.kayaking_outlined,
      'distance': 5.0,
    },
    {
      'name': 'Road Bike',
      'type': ['VirtualRide', 'Ride'],
      'icon': Icons.directions_bike_outlined,
      'distance': 25.0,
    },
    {
      'name': 'Canoe',
      'type': ['Canoeing'],
      'icon': Icons.rowing_outlined,
      'distance': 5.0,
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

  String formatTime(double totalTime) {
    int totalTimeInSeconds = totalTime.toInt();
    int hours = totalTimeInSeconds ~/ 3600;
    int minutes = (totalTimeInSeconds % 3600) ~/ 60;
    int seconds = totalTimeInSeconds % 60;
    return totalTimeInSeconds > 0
        ? "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}"
        : "0:00";
  }

  double totalTime = 0.0;

  Future<String> calculateCumulativeTime(List<double> cumulativeTimes) async {
    for (double time in cumulativeTimes) {
      totalTime += time;
    }
    String formattedTime = formatTime(totalTime);

    // Retrieve the current value from Firestore
    DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('Competitions')
        .doc(formattedCurrentMonth)
        .get();

    // Extract the current Snow2SurfTotalTime from the snapshot
    String? currentSnow2SurfTotalTime = snapshot.data()?['Snow2SurfTotalTime'];

    // Check if the times are different and update if necessary
    if (formattedTime != currentSnow2SurfTotalTime) {
      await FirebaseFirestore.instance
          .collection('Competitions')
          .doc(formattedCurrentMonth)
          .update({'Snow2SurfTotalTime': formattedTime});
    }

    return formattedTime;
  }

  Future<String> fetchTotalTime() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('Competitions')
          .doc(formattedCurrentMonth)
          .get();

      String? fetchedTotalTime = snapshot.data()?['Snow2SurfTotalTime'];
      return fetchedTotalTime ?? "0:00";
    } catch (e) {
      print("Error fetching total time: $e");
      return "0:00";
    }
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

              Map<String, double> typeToDistanceMap = {};
              categories.forEach((category) {
                category['type'].forEach((type) {
                  typeToDistanceMap[type] = category['distance'];
                });
              });

              for (final doc in activityDocs) {
                String type = doc['type'];
                double averageSpeed = doc['average_speed'];
                String fullname = doc['fullname'];

                double originalDistance = typeToDistanceMap[type] ?? 0.0;
                double timeInSeconds = (originalDistance * 1000) / averageSpeed;

                if (!bestTimes.containsKey(type) ||
                    timeInSeconds < bestTimes[type]!['time']) {
                  bestTimes[type] = {
                    'fullname': fullname,
                    'time': timeInSeconds,
                    'speed': averageSpeed,
                  };
                }
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        var category = categories[index];
                        List<String> sportTypes =
                            List<String>.from(category['type']);
                        Map<String, dynamic>? bestTimeEntry;
                        double categoryDistance = category['distance'];

                        for (String type in sportTypes) {
                          if (bestTimes.containsKey(type)) {
                            if (bestTimeEntry == null ||
                                bestTimes[type]!['time'] <
                                    bestTimeEntry['time']) {
                              bestTimeEntry = bestTimes[type];
                            }
                          }
                        }

                        String displayName = bestTimeEntry != null
                            ? bestTimeEntry['fullname']
                            : "User";

                        double bestSpeed = bestTimeEntry != null
                            ? bestTimeEntry['speed']
                            : 0.0;

                        // Adjust the distance based on the category name
                        if (category['name'] == 'Trail Run') {
                          categoryDistance = 6.0; // Distance for Trail Run
                        } else if (category['name'] == 'Road Run') {
                          categoryDistance = 7.0; // Distance for Road Run
                        }
                        if (category['name'] == 'Road Bike') {
                          categoryDistance = 25.0; // Distance for Road Bike
                        } else if (category['name'] == 'Mountain Bike') {
                          categoryDistance = 15.0; // Distance for Mountain Bike
                        }
                        List cumulativeTimes = [];
                        double totalTimeInSeconds = bestSpeed > 0
                            ? (categoryDistance * 1000) / bestSpeed
                            : 0.0;
                        String displayTime = formatTime(totalTimeInSeconds);
                        cumulativeTimes.add(totalTimeInSeconds);

                        // calculateCumulativeTime(cumulativeTimes);

                        return ListTile(
                          visualDensity:
                              VisualDensity(horizontal: 0, vertical: -4),
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
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(displayTime),
                              Text(categoryDistance.toString() + " km"),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              Expanded(
                  child: buildCategoryCard(categories, formattedCurrentMonth)),
              FutureBuilder<String>(
                future: fetchTotalTime(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  }
                  return Text("Total Time: ${snapshot.data}",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

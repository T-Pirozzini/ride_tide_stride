import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ride_tide_stride/pages/snow_2_surf_results_page.dart';

class Snow2Surf extends StatefulWidget {
  const Snow2Surf({super.key});

  @override
  State<Snow2Surf> createState() => _Snow2SurfState();
}

class _Snow2SurfState extends State<Snow2Surf> {
  final currentUser = FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> categories = [
    {
      'name': 'Alpine Ski',
      'type': ['Snowboard', 'AlpineSki'],
      'icon': Icons.downhill_skiing_outlined,
      'distance': 2.0,
      'bestTime': '0:00',
    },
    {
      'name': 'Cross Country Ski',
      'type': ['NordicSki'],
      'icon': Icons.downhill_skiing_outlined,
      'distance': 8.0,
      'bestTime': '0:00',
    },
    {
      'name': 'Road Run',
      'type': ['VirtualRun', 'Run'],
      'icon': Icons.directions_run_outlined,
      'distance': 7.0,
      'bestTime': '0:00',
    },
    {
      'name': 'Trail Run',
      'type': ['Run'],
      'icon': Icons.directions_run_outlined,
      'distance': 6.0,
      'bestTime': '0:00',
    },
    {
      'name': 'Mountain Bike',
      'type': ['Ride'],
      'icon': Icons.directions_bike_outlined,
      'distance': 15.0,
      'bestTime': '0:00',
    },
    {
      'name': 'Kayak',
      'type': ['Kayaking'],
      'icon': Icons.kayaking_outlined,
      'distance': 5.0,
      'bestTime': '0:00',
    },
    {
      'name': 'Road Bike',
      'type': ['VirtualRide', 'Ride'],
      'icon': Icons.directions_bike_outlined,
      'distance': 25.0,
      'bestTime': '0:00',
    },
    {
      'name': 'Canoe',
      'type': ['Canoeing'],
      'icon': Icons.rowing_outlined,
      'distance': 5.0,
      'bestTime': '0:00',
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

  Future<void> _showLegsChoiceDialog(BuildContext context) async {
    bool hasAlreadySelectedLegs = await checkIfUserAlreadSelectedLegs();
    if (hasAlreadySelectedLegs) {
      SnackBar snackBar = SnackBar(
        content: Text('You already selected legs this month!'),
        duration: Duration(seconds: 2),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }
    Set<String> selectedLegs = {};
    Set<String> selectedTypes = {};

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Center(child: const Text('Select up to 3 legs!')),
            content: SingleChildScrollView(
              child: ListBody(
                children: categories.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> category = entry.value;
                  String legTitle = 'Leg ${index + 1} - ${category['name']}';

                  return CheckboxListTile(
                    title: Text(legTitle, style: TextStyle(fontSize: 12)),
                    value: selectedLegs.contains(legTitle),
                    onChanged: (bool? value) {
                      setState(() {
                        // Add this call to setState
                        if (value == true) {
                          if (selectedLegs.length < 3) {
                            // Check for running or biking category conflict
                            if ((selectedTypes.contains('Run') &&
                                    category['type'].contains('Run')) ||
                                (selectedTypes.contains('Ride') &&
                                    category['type'].contains('Ride'))) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Cannot select two legs of the same type (Run or Ride).'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                              return;
                            }

                            selectedLegs.add(legTitle);
                            category['type']
                                .forEach((type) => selectedTypes.add(type));
                          }
                        } else {
                          selectedLegs.remove(legTitle);
                          category['type']
                              .forEach((type) => selectedTypes.remove(type));
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                child: Text('Submit'),
                onPressed: () {
                  submitUserLegs(selectedLegs);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
      },
    );
  }

  void submitUserLegs(Set<String> selectedLegs) async {
    String userEmail = currentUser?.email ?? '';
    final competitionDocId = formattedCurrentMonth;
    var competitionDoc = FirebaseFirestore.instance
        .collection('Competitions')
        .doc(competitionDocId);

    await competitionDoc.set({
      'users': {
        userEmail: {
          'selected_legs': selectedLegs.toList(),
          'hasCompletedSelection': true,
        },
      },
    }, SetOptions(merge: true));
  }

  Future<bool> checkIfUserAlreadSelectedLegs() async {
    String userEmail = currentUser?.email ?? '';
    final competitionDocId = formattedCurrentMonth;
    var competitionDoc = FirebaseFirestore.instance
        .collection('Competitions')
        .doc(competitionDocId);

    var snapshot = await competitionDoc.get();
    if (!snapshot.exists) {
      print('Competition document does not exist for $competitionDocId');
      return false;
    }

    var data = snapshot.data() as Map<String, dynamic>;
    var usersData = data['users'] ?? {};
    var userData = usersData[userEmail] ?? {};

    return userData['hasCompletedSelection'] ?? false;
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

    List<double> bestTimesInSeconds = [];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: GoogleFonts.syne(textStyle: TextStyle(fontSize: 20)),
        ),
        Text('Snow2Surf',
            style: GoogleFonts.tektur(
                textStyle:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),        
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
              print("type to distance map: $typeToDistanceMap");

              for (final doc in activityDocs) {
                String type = doc['type'];
                double averageSpeed = doc['average_speed'];
                double activityDistance = doc['distance'] / 1000;
                print('Activity Distance: $activityDistance');
                String fullname = doc['fullname'];

                double categoryDistance = typeToDistanceMap[type] ?? 0.0;
                // Check if the activity's distance is greater than or equal to the category distance
                if (activityDistance >= categoryDistance) {
                  double timeInSeconds =
                      (activityDistance * 1000) / averageSpeed;

                  if (!bestTimes.containsKey(type) ||
                      timeInSeconds < bestTimes[type]!['time']) {
                    bestTimes[type] = {
                      'fullname': fullname,
                      'time': timeInSeconds,
                      'speed': averageSpeed,
                    };
                  }
                }
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: categories.length + 1,
                      itemBuilder: (context, index) {
                        // Check if this index is for the total time display
                        if (index == categories.length) {
                          // Calculate the total time
                          double totalTime = bestTimesInSeconds.fold(
                              0, (prev, curr) => prev + curr);

                          // Return a widget to display the total time
                          return ListTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Total Time: ',
                                  style: GoogleFonts.syne(
                                      textStyle: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold)),
                                ),
                                Text(
                                  '${formatTime(totalTime)}',
                                  style: GoogleFonts.syne(
                                      textStyle: TextStyle(fontSize: 24)),
                                ),
                              ],
                            ),
                            // Adjust the styling as needed
                          );
                        } else {
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
                            categoryDistance =
                                15.0; // Distance for Mountain Bike
                          }

                          double totalTimeInSeconds = bestSpeed > 0
                              ? (categoryDistance * 1000) / bestSpeed
                              : 0.0;
                          String displayTime = formatTime(totalTimeInSeconds);

// Add to your list of best times
                          bestTimesInSeconds.add(totalTimeInSeconds);

                          return Padding(
                            padding: const EdgeInsets.all(1.0),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Snow2SurfResultsPage(
                                      icon: categories[index]['icon'],
                                      category: category['type'].toString(),
                                      types: categories[index]['type'],
                                      distance: category['distance'],
                                    ),
                                  ),
                                );
                              },
                              child: ListTile(
                                tileColor: Colors.white,

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
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            // Place your buttons here
            ElevatedButton(
              onPressed: () {
                _showLegsChoiceDialog(context);
              },
              child: Column(
                children: [
                  const Text('Select your legs'),
                  const Text('max 3 legs per month',
                      style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ],
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
            ],
          ),
        ),
      ),
    );
  }
}

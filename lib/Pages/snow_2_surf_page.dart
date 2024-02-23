import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ride_tide_stride/pages/snow_2_surf_results_page.dart';

class Snow2Surf extends StatefulWidget {
  final String challengeId;
  final List<dynamic> participantsEmails;
  final Timestamp startDate;
  final String challengeType;
  final String challengeName;
  final String challengeDifficulty;
  final List challengeLegs;

  const Snow2Surf({
    super.key,
    required this.challengeId,
    required this.participantsEmails,
    required this.startDate,
    required this.challengeType,
    required this.challengeName,
    required this.challengeDifficulty,
    required this.challengeLegs,
  });

  @override
  State<Snow2Surf> createState() => _Snow2SurfState();
}

class _Snow2SurfState extends State<Snow2Surf> {
  final currentUser = FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> categories = [
    {
      'name': 'Alpine Skiing',
      'type': ['Snowboard', 'AlpineSki'],
      'icon': Icons.downhill_skiing_outlined,
      'distance': 2.0,
      'bestTime': '0:00',
    },
    {
      'name': 'Nordic Skiing',
      'type': ['NordicSki'],
      'icon': Symbols.nordic_walking,
      'distance': 8.0,
      'bestTime': '0:00',
    },
    {
      'name': 'Road Running',
      'type': ['VirtualRun', 'Road Run', 'Run'],
      'icon': Symbols.sprint,
      'distance': 7.0,
      'bestTime': '0:00',
    },
    {
      'name': 'Trail Running',
      'type': ['Trail Run'],
      'icon': Icons.directions_run_outlined,
      'distance': 6.0,
      'bestTime': '0:00',
    },
    {
      'name': 'Mountain Biking',
      'type': ['Mtn Bike'],
      'icon': Icons.directions_bike_outlined,
      'distance': 15.0,
      'bestTime': '0:00',
    },
    {
      'name': 'Kayaking',
      'type': ['Kayaking'],
      'icon': Icons.kayaking_outlined,
      'distance': 5.0,
      'bestTime': '0:00',
    },
    {
      'name': 'Road Cycling',
      'type': ['VirtualRide', 'Road Bike', 'Ride'],
      'icon': Icons.directions_bike_outlined,
      'distance': 25.0,
      'bestTime': '0:00',
    },
    {
      'name': 'Canoeing',
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

    // Fetch activities for the current month
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

  Map<String, dynamic> opponents = {
    "Intro": {
      "name": ["Mike", "Leo", "Raph", "Don"],
      "image": [
        "assets/images/mike.jpg",
        "assets/images/leo.jpg",
        "assets/images/raph.jpg",
        "assets/images/don.jpg"
      ],
      "bestTime": ["0:00", "0:00", "0:00", "0:00"],
    },
    "Advanced": {
      "name": ["Crash", "Todd", "Noise", "Baldy"],
      "image": [
        "assets/images/crash.png",
        "assets/images/todd.png",
        "assets/images/noise.png",
        "assets/images/baldy.png"
      ],
      "bestTime": ["0:00", "0:00", "0:00", "0:00"],
    },
    "Expert": {
      "name": ["Mike", "Leo", "Raph", "Don"],
      "image": [
        "assets/images/mike.jpg",
        "assets/images/leo.jpg",
        "assets/images/raph.jpg",
        "assets/images/don.jpg"
      ],
      "bestTime": ["0:00", "0:00", "0:00", "0:00"],
    },
  };

  Widget buildCategoryCard(
    List<Map<String, dynamic>> categories,
    String title,
  ) {
    // Filter categories to only include selected legs
    List<Map<String, dynamic>> selectedCategories =
        categories.where((category) {
      print("Checking category: ${category['name']}");
      return widget.challengeLegs.contains(category['name']);
    }).toList();

    print("Selected categories: $selectedCategories");

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
        default:
          return Icon(Icons.looks_one);
      }
    }

    List<double> bestTimesInSeconds = [];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
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
                var data = doc.data() as Map<String, dynamic>;
                String sportType = data['sport_type'] ?? data['type'];
                double averageSpeed = doc['average_speed'];
                double activityDistance = doc['distance'] / 1000;
                print('Activity Distance: $activityDistance');
                String fullname = doc['fullname'];

                double categoryDistance = typeToDistanceMap[sportType] ?? 0.0;
                // Check if the activity's distance is greater than or equal to the category distance
                if (activityDistance >= categoryDistance) {
                  double timeInSeconds =
                      (activityDistance * 1000) / averageSpeed;

                  if (!bestTimes.containsKey(sportType) ||
                      timeInSeconds < bestTimes[sportType]!['time']) {
                    bestTimes[sportType] = {
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
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        childAspectRatio: MediaQuery.of(context).size.width /
                            (MediaQuery.of(context).size.height / 2),
                      ),
                      itemCount: selectedCategories.length + 1,
                      itemBuilder: (context, index) {
                        // Check if this index is for the total time display
                        if (index == selectedCategories.length) {
                          // Calculate the total time
                          double totalTime = bestTimesInSeconds.fold(
                              0, (prev, curr) => prev + curr);

                          // Return a widget to display the total time
                          return Card(
                            child: ListTile(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Total Time: ',
                                    style: GoogleFonts.syne(
                                        textStyle: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Text(
                                    '${formatTime(totalTime)}',
                                    style: GoogleFonts.syne(
                                        textStyle: TextStyle(fontSize: 18)),
                                  ),
                                ],
                              ),
                              // Adjust the styling as needed
                            ),
                          );
                        } else {
                          var category = selectedCategories[index];
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
                                      category: category['name'],
                                      types: categories[index]['type'],
                                      distance: category['distance'],
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(selectedCategories[index]
                                              ['icon']),
                                          Text(
                                            selectedCategories[index]['name'],
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        displayName.split(
                                            ' ')[0], // Display the first name
                                        style: TextStyle(fontSize: 18),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Best Time: $displayTime'),
                                          Text(
                                              "Min Distance: ${categoryDistance.toString()} km"),
                                        ],
                                      ),
                                    ],
                                  ),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double aspectRatio = MediaQuery.of(context).size.width /
        (MediaQuery.of(context).size.height / 2);

    return Scaffold(
      backgroundColor: const Color(0xFFDFD3C3),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.challengeType,
          style: GoogleFonts.tektur(
              textStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.2)),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              Text(widget.challengeDifficulty,
                  style: GoogleFonts.tektur(
                      textStyle: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold))),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: buildCategoryCard(
                            categories, formattedCurrentMonth)),
                    Expanded(
                      // If you want the middle column to be narrower, use a smaller flex value.
                      flex: 1,
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          childAspectRatio: aspectRatio,
                        ),
                        itemCount:
                            opponents[widget.challengeDifficulty]!["name"]
                                .length,
                        itemBuilder: (context, index) {
                          return Container(
                            // Adjust padding or margins if necessary
                            padding: const EdgeInsets.all(1.0),
                            child: Center(
                              child: Text(
                                'VS',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          childAspectRatio: aspectRatio,
                        ),
                        itemCount:
                            opponents[widget.challengeDifficulty]!["name"]
                                .length,
                        itemBuilder: (context, index) {
                          var difficulty =
                              opponents[widget.challengeDifficulty];

                          return Padding(
                            padding: const EdgeInsets.all(1.0),
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: Column(
                                  children: <Widget>[
                                    Expanded(
                                      child: CircleAvatar(
                                        backgroundColor: Colors.grey.shade400,
                                        // Set the radius to limit the size of the CircleAvatar
                                        radius:
                                            52, // Adjust the radius to fit within the ListTile properly
                                        child: ClipOval(
                                          child: Image.asset(
                                            difficulty["image"][index],
                                            fit: BoxFit
                                                .fill, // This ensures the image covers the clip area well
                                            width:
                                                100, // Match this width to the overall size constraint of the CircleAvatar
                                            height:
                                                100, // Match this height as well
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      difficulty["name"][
                                          index], // Accessing the name by index
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "${difficulty["bestTime"][index]}",
                                      style: TextStyle(fontSize: 12),
                                    ), // Accessing the best time by index
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey, size: 32),
                    SizedBox(width: 8),
                    Text(
                      'To Qualify: Current month & min distance (as posted).',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          overflow: null),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

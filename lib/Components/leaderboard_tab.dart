import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_tide_stride/components/leaderboard_dialog.dart';

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
                title: Text('${entry['full_name']}',
                    style: Theme.of(context).textTheme.bodyMedium),
                leading: customPlaceWidget('$currentPlace'),
                subtitle:
                    Text(title, style: Theme.of(context).textTheme.bodySmall),
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

      // Check if 'public' property exists and is true, or if it doesn't exist
      final bool isPublic = data.containsKey('public') ? data['public'] : true;

      if (!isPublic) {
        continue; // Skip this entry if it's not public
      }

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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_tide_stride/helpers/helper_functions.dart';
import 'package:ride_tide_stride/screens/leaderboard/custom_list_tile.dart';
import 'package:ride_tide_stride/screens/leaderboard/leaderboard_dialog.dart';

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
      stream: getCurrentMonthData(),
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

            // Decide which list tile to build based on the title
            Widget dataWidget;
            if (title == 'Moving Time') {
              dataWidget = CustomListTile(
                  title: 'Total Moving Time',
                  trailingText: formatMovingTimeInt(entry['total_moving_time']),
                  entry: entry,
                  currentPlace: currentPlace);
            } else if (title == 'Total Distance (km)') {
              dataWidget = CustomListTile(
                  title: 'Total Distance',
                  trailingText:
                      '${(entry['total_distance'] / 1000).toStringAsFixed(0)} km',
                  entry: entry,
                  currentPlace: currentPlace);
            } else if (title == 'Total Elevation') {
              dataWidget = CustomListTile(
                  title: 'Total Elevation',
                  trailingText:
                      '${entry['total_elevation'].toStringAsFixed(0)} m',
                  entry: entry,
                  currentPlace: currentPlace);
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

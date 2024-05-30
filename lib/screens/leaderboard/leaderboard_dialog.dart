 import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

  Widget buildActivitiesList(List<Map<String, dynamic>> activities) {
    // Sort the activities list by 'start_date' in descending order (most recent first).
    activities.sort((a, b) => DateTime.parse(b['start_date'])
        .compareTo(DateTime.parse(a['start_date'])));

    return LayoutBuilder(
      builder: (context, constraints) {
        double deviceHeight = constraints.maxHeight;
        double topPadding = MediaQuery.of(context).padding.top;
        double bottomPadding = MediaQuery.of(context).padding.bottom;
        double usableHeight = deviceHeight - topPadding - bottomPadding;

        double fontSizeForDate = usableHeight * 0.018;
        double fontSizeForName = usableHeight * 0.017;

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
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          formatDate(activity['start_date']),
                          style: TextStyle(
                              fontSize: fontSizeForDate,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400),
                        ),
                        Text(
                          activity['name'],
                          style: TextStyle(
                              fontSize: fontSizeForName,
                              fontWeight: FontWeight.w600),
                        ),
                        CircleAvatar(
                          backgroundColor: Color.fromARGB(167, 40, 61, 59),
                          foregroundColor: Colors.white,
                          child: getIconForActivityType(activity['type']),
                        ),
                      ],
                    ),
                    leading: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timelapse,
                                color: Colors.purple[600], size: 12.0),
                            const SizedBox(width: 4.0),
                            Text(
                              formatDuration(activity['moving_time']),
                              style: const TextStyle(fontSize: 12.0),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.straighten,
                                color: Colors.blue[600], size: 12.0),
                            const SizedBox(width: 4.0),
                            Text(
                              '${(activity['distance'] / 1000).toStringAsFixed(2)} km',
                              style: const TextStyle(fontSize: 12.0),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.landscape,
                                color: Colors.green[600], size: 12.0),
                            const SizedBox(width: 4.0),
                            Text(
                              '${activity['elevation_gain']} m',
                              style: const TextStyle(fontSize: 12.0),
                            ),
                          ],
                        ),
                      ],
                    ),
                    subtitle: Center(
                      child: Text('Tap to view on Strava',
                          style: TextStyle(
                              fontSize: 8.0, fontStyle: FontStyle.italic)),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flash_on,
                                color: Colors.yellow[600], size: 12.0),
                            const SizedBox(width: 4.0),
                            activity['average_watts'] != null
                                ? Text(
                                    '${activity['average_watts'].toString()} W',
                                    style: const TextStyle(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w500),
                                  )
                                : Text('0 W', style: TextStyle(fontSize: 12.0)),
                          ],
                        ),
                        const SizedBox(height: 4.0),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.speed_outlined,
                                color: Colors.red[600], size: 12.0),
                            const SizedBox(width: 4.0),
                            Text(
                              '$minutes:${seconds.toString().padLeft(2, '0')} /km',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12.0,
                              ),
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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ride_tide_stride/helpers/helper_functions.dart';
import 'package:ride_tide_stride/screens/strava_connect/strava_page.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
    required this.automaticSubmit,
    required this.activityName,
    required this.activityTime,
    required this.activityElevation,
    required this.activityDistance,
    required this.activityId,
    required this.activityType,
    required this.movingTimeSeconds,
    required this.athleteData,
    required this.submitActivityToFirestore,
  });

  final Map<String, dynamic> activity;
  final String activityName;
  final int activityId;
  final String activityTime;
  final String activityType;
  final int movingTimeSeconds;
  final double activityDistance;
  final double activityElevation;
  final bool automaticSubmit;
  final Map<String, dynamic> athleteData;
  final Function(Map<String, dynamic> activity, Map<String, dynamic> athlete)
      submitActivityToFirestore;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  activityName,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            // Date and activity type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM d, yyyy (EEE)')
                      .format(DateTime.parse(activityTime)),
                  style: TextStyle(
                    fontSize: 14, // Adjusted font size
                    color: Colors.grey.shade700, // Made it a bit darker
                  ),
                ),
                // Activity type with icon
                _activityIcon(activityType),
              ],
            ),
            const SizedBox(height: 5),
            // Metrics with icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 20, color: Colors.teal.shade500),
                    SizedBox(width: 5),
                    Text('${formatDurationSeconds(movingTimeSeconds)}'),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.straighten_outlined,
                        size: 20, color: Colors.teal.shade500),
                    SizedBox(width: 5),
                    Text('${(activityDistance / 1000).toStringAsFixed(2)} km'),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.landscape_outlined,
                        size: 20, color: Colors.teal.shade500),
                    SizedBox(width: 5),
                    Text('${activityElevation} m'),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 5),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('activities')
                  .where('activity_id', isEqualTo: activityId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final List<DocumentSnapshot> documents = snapshot.data!.docs;
                bool isSubmitted = false;

                if (documents.isNotEmpty) {
                  final DocumentSnapshot document = documents.first;
                  isSubmitted = document.get('submitted') ?? false;
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: isSubmitted || automaticSubmit
                          ? null
                          : () {
                              // Call the function to submit activity data to Firestore
                              submitActivityToFirestore(activity, athleteData!);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSubmitted
                            ? Colors.grey
                            : const Color(
                                0xFF283D3B), // Change color when submitted
                      ),
                      child: const Text("Submit to Leaderboard"),
                    ),
                    if (isSubmitted)
                      IconButton(
                        icon: Icon(Icons.undo),
                        onPressed: () {
                          deleteActivityFromFirestore(activityId);
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

final activityIcons = {
  'Run': Icons.directions_run_outlined,
  'Ride': Icons.directions_bike_outlined,
  'Swim': Icons.pool_outlined,
  'Walk': Icons.directions_walk_outlined,
  'Hike': Icons.terrain_outlined,
  'AlpineSki': Icons.snowboarding_outlined,
  'BackcountrySki': Icons.snowboarding_outlined,
  'Canoeing': Icons.kayaking_outlined,
  'Crossfit': Icons.fitness_center_outlined,
  'EBikeRide': Icons.electric_bike_outlined,
  'Elliptical': Icons.fitness_center_outlined,
  'Handcycle': Icons.directions_bike_outlined,
  'IceSkate': Icons.ice_skating_outlined,
  'InlineSkate': Icons.ice_skating_outlined,
  'Kayaking': Icons.kayaking_outlined,
  'Kitesurf': Icons.kitesurfing_outlined,
  'NordicSki': Icons.snowboarding_outlined,
  'RockClimbing': Icons.terrain_outlined,
  'RollerSki': Icons.directions_bike_outlined,
  'Rowing': Icons.kayaking_outlined,
  'Snowboard': Icons.snowboarding_outlined,
  'Snowshoe': Icons.snowshoeing_outlined,
  'StairStepper': Icons.fitness_center_outlined,
  'StandUpPaddling': Icons.kayaking_outlined,
  'Surfing': Icons.surfing_outlined,
  'VirtualRide': Icons.directions_bike_outlined,
  'VirtualRun': Icons.directions_run_outlined,
  'WeightTraining': Icons.fitness_center_outlined,
  'Windsurf': Icons.surfing_outlined,
  'Workout': Icons.fitness_center_outlined,
  'Yoga': Icons.fitness_center_outlined,
};

Widget _activityIcon(String activityType) {
  var iconData = activityIcons[activityType] ??
      Icons.help_outline; // Default icon if not found
  return Row(
    children: [
      Icon(iconData, color: Colors.teal.shade100, size: 36),
    ],
  );
}

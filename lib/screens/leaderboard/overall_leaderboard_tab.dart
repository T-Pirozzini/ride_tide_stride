import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_tide_stride/helpers/helper_functions.dart';
import 'package:ride_tide_stride/providers/activity_provider.dart';
import 'package:ride_tide_stride/screens/leaderboard/custom_place.dart';
import 'package:ride_tide_stride/screens/leaderboard/leaderboard_dialog.dart';

class OverallLeaderboardTab extends ConsumerWidget {
  const OverallLeaderboardTab({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allMonthlyActivitiesAsyncValue = ref.watch(monthlyActivitiesProvider);

    return allMonthlyActivitiesAsyncValue.when(
      data: (activities) {
        final uniqueParticipants = <String>{};
        final elevationGains = <String, double>{};
        final distanceGains = <String, double>{};
        final movingTimes = <String, int>{};

        // Aggregate data by participant
        for (var activity in activities) {
          final fullName = activity.fullname;
          if (uniqueParticipants.add(fullName)) {
            elevationGains[fullName] = activity.elevationGain;
            distanceGains[fullName] = activity.distance;
            movingTimes[fullName] = activity.movingTime;
          } else {
            elevationGains[fullName] =
                elevationGains[fullName]! + activity.elevationGain;
            distanceGains[fullName] =
                distanceGains[fullName]! + activity.distance;
            movingTimes[fullName] =
                movingTimes[fullName]! + activity.movingTime;
          }
        }

        // Sort participants based on metrics
        final sortedByElevation = elevationGains.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final sortedByDistance = distanceGains.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final sortedByMovingTime = movingTimes.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Create maps to store ranks
        final elevationRanks = {
          for (var i = 0; i < sortedByElevation.length; i++)
            sortedByElevation[i].key: i + 1
        };
        final distanceRanks = {
          for (var i = 0; i < sortedByDistance.length; i++)
            sortedByDistance[i].key: i + 1
        };
        final movingTimeRanks = {
          for (var i = 0; i < sortedByMovingTime.length; i++)
            sortedByMovingTime[i].key: i + 1
        };

        // Calculate overall scores
        final overallScores = uniqueParticipants.map((participant) {
          final score = elevationRanks[participant]! +
              distanceRanks[participant]! +
              movingTimeRanks[participant]!;
          return {
            'fullName': participant,
            'score': score,
            'elevation': elevationGains[participant],
            'distance': distanceGains[participant],
            'movingTime': movingTimes[participant],
          };
        }).toList();

        // Sort by overall scores
        overallScores
            .sort((a, b) => (a['score'] as int).compareTo(b['score'] as int));

        // Assign overall places
        var currentPlace = 1;
        for (var i = 0; i < overallScores.length; i++) {
          if (i > 0 &&
              overallScores[i]['score'] != overallScores[i - 1]['score']) {
            currentPlace = i + 1;
          }
          overallScores[i]['place'] = currentPlace.toString();
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: overallScores.length,
                itemBuilder: (context, index) {
                  final participant = overallScores[index];
                  final fullName = participant['fullName'] as String;
                  final place = participant['place'] as String;
                  final totalElevation = participant['elevation'] as double;
                  final totalDistance = participant['distance'] as double;
                  final totalMovingTime = participant['movingTime'] as int;

                  return GestureDetector(
                    onTap: () {
                      // Update the fullNameProvider before showing the dialog
                      ref.read(fullNameProvider.state).state = fullName;
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('$fullName\'s Activities'),
                            content: Consumer(
                              builder: (context, ref, _) {
                                // Use the userCurrentMonthActivitiesProvider with fullName
                                final userActivitiesAsyncValue = ref.watch(
                                    userCurrentMonthActivitiesProvider(
                                        fullName));
                                return userActivitiesAsyncValue.when(
                                  data: (userActivities) {
                                    return Container(
                                      height: 400,
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        itemCount: userActivities.length,
                                        itemBuilder: (context, index) {
                                          final activity =
                                              userActivities[index];

                                          double speedMps = activity
                                              .averageSpeed; // Speed in meters per second
                                          double speedKph =
                                              speedMps * 3.6; // Convert to km/h
                                          double pace = 60 / speedKph;
                                          int minutes = pace.floor();
                                          int seconds =
                                              ((pace - minutes) * 60).round();
                                          return Card(
                                            elevation: 1,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0)),
                                            child: ListTile(
                                              title: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    formatDate(activity
                                                        .startDateLocal),
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey,
                                                        fontWeight:
                                                            FontWeight.w400),
                                                  ),
                                                  Text(
                                                    activity.name,
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                  CircleAvatar(
                                                    backgroundColor:
                                                        Color.fromARGB(
                                                            167, 40, 61, 59),
                                                    foregroundColor:
                                                        Colors.white,
                                                    child:
                                                        getIconForActivityType(
                                                            activity.type),
                                                  ),
                                                ],
                                              ),
                                              leading: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.timelapse,
                                                          color: Colors
                                                              .purple[600],
                                                          size: 12.0),
                                                      const SizedBox(
                                                          width: 4.0),
                                                      Text(
                                                        formatDurationSeconds(
                                                            activity
                                                                .movingTime),
                                                        style: const TextStyle(
                                                            fontSize: 12.0),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.straighten,
                                                          color:
                                                              Colors.blue[600],
                                                          size: 12.0),
                                                      const SizedBox(
                                                          width: 4.0),
                                                      Text(
                                                        '${(activity.distance / 1000).toStringAsFixed(2)} km',
                                                        style: const TextStyle(
                                                            fontSize: 12.0),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.landscape,
                                                          color:
                                                              Colors.green[600],
                                                          size: 12.0),
                                                      const SizedBox(
                                                          width: 4.0),
                                                      Text(
                                                        '${activity.elevationGain} m',
                                                        style: const TextStyle(
                                                            fontSize: 12.0),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              subtitle: Center(
                                                child: Text(
                                                    'Tap to view on Strava',
                                                    style: TextStyle(
                                                        fontSize: 8.0,
                                                        fontStyle:
                                                            FontStyle.italic)),
                                              ),
                                              trailing: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.flash_on,
                                                          color: Colors
                                                              .yellow[600],
                                                          size: 12.0),
                                                      const SizedBox(
                                                          width: 4.0),
                                                      Text(
                                                        '${activity.power} W',
                                                        style: const TextStyle(
                                                            fontSize: 12.0,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4.0),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.speed_outlined,
                                                          color:
                                                              Colors.red[600],
                                                          size: 12.0),
                                                      const SizedBox(
                                                          width: 4.0),
                                                      Text(
                                                        '$minutes:${seconds.toString().padLeft(2, '0')} /km',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 12.0,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              isThreeLine: true,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  loading: () => Center(
                                      child: CircularProgressIndicator()),
                                  error: (error, stack) =>
                                      Text('Error: $error'),
                                );
                              },
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Close'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: ListTile(
                      tileColor: Colors.white,
                      title: Text(fullName,
                          style: Theme.of(context).textTheme.bodyLarge),
                      leading: CustomPlaceWidget(place: place),
                      subtitle: Text("Click to view this month's activities",
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(fontStyle: FontStyle.italic)),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '#${elevationRanks[fullName]}: ${totalElevation.toStringAsFixed(0)} m'),
                          Text(
                              '#${distanceRanks[fullName]}: ${(totalDistance / 1000).toStringAsFixed(0)} km'),
                          Text(
                              '#${movingTimeRanks[fullName]}: ${formatMovingTimeInt(totalMovingTime)}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}




 // Text(
                            //   '$minutes:${seconds.toString().padLeft(2, '0')} /km',
                            //   style: const TextStyle(
                            //     fontWeight: FontWeight.w500,
                            //     fontSize: 12.0,
                            //   ),
                            // ),


// child: ListTile(
//                       tileColor: Colors.white,
//                       title: Text(fullName,
//                           style: Theme.of(context).textTheme.bodyLarge),
//                       leading: CustomPlaceWidget(place: place),
//                       subtitle: Text("Click to view this month's activities",
//                           style: Theme.of(context)
//                               .textTheme
//                               .bodySmall!
//                               .copyWith(fontStyle: FontStyle.italic)),
//                       trailing: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                               '#${elevationRanks[fullName]}: ${totalElevation.toStringAsFixed(0)} m'),
//                           Text(
//                               '#${distanceRanks[fullName]}: ${(totalDistance / 1000).toStringAsFixed(0)} km'),
//                           Text(
//                               '#${movingTimeRanks[fullName]}: ${formatMovingTimeInt(totalMovingTime)}'),
//                         ],
//                       ),
//                     ),
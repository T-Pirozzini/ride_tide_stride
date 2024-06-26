import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_tide_stride/helpers/helper_functions.dart';
import 'package:ride_tide_stride/providers/activity_provider.dart';
import 'package:ride_tide_stride/screens/activities/activities_page.dart';
import 'package:ride_tide_stride/screens/leaderboard/custom_place.dart';
import 'package:ride_tide_stride/screens/leaderboard/leaderboard_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
        final userEmail = <String, String>{};

        // Aggregate data by participant
        for (var activity in activities) {
          final fullName = activity.fullname;
          if (uniqueParticipants.add(fullName)) {
            elevationGains[fullName] = activity.elevationGain;
            distanceGains[fullName] = activity.distance;
            movingTimes[fullName] = activity.movingTime;
            userEmail[fullName] = activity.email;
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
            'email': userEmail[participant],
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
                  final email = participant['email'] as String;

                  return GestureDetector(
                    onTap: () {
                      // Update the fullNameProvider before showing the dialog
                      ref.read(fullNameProvider.state).state = fullName;
                      ref.read(emailProvider.state).state = email;

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
                                      height:
                                          MediaQuery.of(context).size.height /
                                              1,
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
                                          return GestureDetector(
                                            onTap: () {
                                              if (activity.id != null) {
                                                _showStravaDialog(
                                                    context, activity.id!);
                                              } else {
                                                print(
                                                    'Activity does not have an ID.');
                                              }
                                            },
                                            child: Card(
                                              elevation: 1,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0)),
                                              child: ListTile(
                                                title: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      formatDate(activity
                                                          .startDateLocal),
                                                      style: TextStyle(
                                                          fontSize: 8,
                                                          color: Colors.grey,
                                                          fontWeight:
                                                              FontWeight.w400),
                                                    ),
                                                    Text(
                                                      activity.name,
                                                      style: TextStyle(
                                                          fontSize: 10,
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
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      10.0),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.straighten,
                                                            color: Colors
                                                                .blue[600],
                                                            size: 12.0),
                                                        const SizedBox(
                                                            width: 4.0),
                                                        Text(
                                                          '${(activity.distance / 1000).toStringAsFixed(2)} km',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      10.0),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.landscape,
                                                            color: Colors
                                                                .green[600],
                                                            size: 12.0),
                                                        const SizedBox(
                                                            width: 4.0),
                                                        Text(
                                                          '${activity.elevationGain} m',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      10.0),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                subtitle: Center(
                                                  child: Row(
                                                    children: [
                                                      FaIcon(
                                                        FontAwesomeIcons.strava,
                                                        color:
                                                            Colors.orange[600],
                                                        size: 12,
                                                      ),
                                                      const SizedBox(
                                                          width: 4.0),
                                                      Flexible(
                                                        child: Text(
                                                          'View on Strava',
                                                          style: TextStyle(
                                                              fontSize: 8.0,
                                                              fontStyle:
                                                                  FontStyle
                                                                      .italic),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
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
                                                              fontSize: 10.0,
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
                                                        Icon(
                                                            Icons
                                                                .speed_outlined,
                                                            color:
                                                                Colors.red[600],
                                                            size: 12.0),
                                                        const SizedBox(
                                                            width: 4.0),
                                                        Text(
                                                          '$minutes:${seconds.toString().padLeft(2, '0')} /km',
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize: 10.0,
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      if (email != null && email.isNotEmpty) {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ActivitiesListPage(
                                                      userEmail: email),
                                            ));
                                      } else {
                                        // Handle the scenario where email is null or empty, perhaps notify the user
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('Error'),
                                            content: Text(
                                                "No email available for $fullName. Cannot navigate to activities page."),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                                child: Text('OK'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
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
                          );
                        },
                      );
                    },
                    child: Column(
                      children: [
                        ListTile(
                          tileColor: Colors.white,
                          title: Text(fullName,
                              style: Theme.of(context).textTheme.bodyLarge),
                          leading: CustomPlaceWidget(place: place),
                          subtitle: Text(
                              "Click to view this month's activities",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(fontStyle: FontStyle.italic)),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '#${movingTimeRanks[fullName]}: ${formatMovingTimeInt(totalMovingTime)}',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  Icon(Icons.timelapse,
                                      color: Colors.purple[600], size: 14.0),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '#${elevationRanks[fullName]}: ',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  Text(
                                    '${totalElevation.toStringAsFixed(0)} m',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  Icon(Icons.landscape,
                                      color: Colors.green[600], size: 14.0),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '#${distanceRanks[fullName]}: ${(totalDistance / 1000).toStringAsFixed(0)} km',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  Icon(Icons.straighten,
                                      color: Colors.blue[600], size: 14.0),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                          color: Colors.grey,
                          thickness: 1.0,
                          height: 0.0,
                        ),
                      ],
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

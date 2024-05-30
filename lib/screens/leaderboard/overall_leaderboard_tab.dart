import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_tide_stride/helpers/helper_functions.dart';
import 'package:ride_tide_stride/providers/activity_provider.dart';
import 'package:ride_tide_stride/screens/leaderboard/custom_place.dart';

class OverallLeaderboardTab extends ConsumerWidget {
  const OverallLeaderboardTab({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsyncValue = ref.watch(monthlyActivitiesProvider);
    return activitiesAsyncValue.when(
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
            Text('Overall Leaderboard Tab: ${activities.length} activities'),
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

                  return Card(
                    color: Colors.blue,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomPlaceWidget(place: place),
                        Text(fullName),
                        Column(
                          children: [
                            Text(
                                '#${elevationRanks[fullName]}: ${totalElevation.toStringAsFixed(0)} m'),
                            Text(
                                '#${distanceRanks[fullName]}: ${totalDistance.toStringAsFixed(0)} km'),
                            Text(
                                '#${movingTimeRanks[fullName]}: ${formatMovingTimeInt(totalMovingTime)}'),
                          ],
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

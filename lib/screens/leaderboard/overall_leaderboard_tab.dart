import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_tide_stride/providers/activity_provider.dart';

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

        return Column(
          children: [
            Text('Overall Leaderboard Tab: ${activities.length} activities'),
            Expanded(
              child: ListView.builder(
                itemCount: uniqueParticipants.length,
                itemBuilder: (context, index) {
                  final fullName = uniqueParticipants.elementAt(index);
                  final totalElevation = elevationGains[fullName]!;

                  return ListTile(
                    title: Text(fullName),
                    subtitle: Column(
                      children: [
                        Text(
                            'Total Elevation: ${totalElevation.toStringAsFixed(2)} meters'),
                        Text(
                            'Total Distance: ${distanceGains[fullName]!.toStringAsFixed(2)} meters'),
                        Text(
                            'Total Moving Time: ${movingTimes[fullName]!} seconds')
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

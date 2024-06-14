import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ride_tide_stride/models/activity.dart';
import 'package:ride_tide_stride/providers/activity_provider.dart';
import 'package:ride_tide_stride/theme.dart';

final team1Provider = StateProvider<List<double>>((ref) => []);
final team2Provider = StateProvider<List<double>>((ref) => []);

class TrackPage extends ConsumerWidget {
  final List<dynamic> participantEmails;

  TrackPage({required this.participantEmails});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startDate = DateTime.now().subtract(Duration(days: 12));
    final activitiesByEmail = participantEmails
        .map((email) => ref.watch(userSpecificRangeActivitiesProvider(email)))
        .toList();

    // Check if all activities are loaded
    bool allLoaded =
        activitiesByEmail.every((asyncValue) => asyncValue is AsyncData);

    // Filter out only the data from AsyncValues
    List<List<Activity>> allActivities = activitiesByEmail
        .where((asyncValue) => asyncValue is AsyncData)
        .map((asyncValue) => (asyncValue as AsyncData<List<Activity>>).value)
        .toList();

    if (allLoaded) {
      // All activities are loaded, process the data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processActivities(ref, allActivities);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: allLoaded
          ? _buildContent(context, ref)
          : Center(child: CircularProgressIndicator()),
    );
  }

  void _processActivities(WidgetRef ref, List<List<Activity>> allActivities) {
    // Aggregate distances by date for the past 12 days
    Map<String, double> aggregatedDistances = {};

    for (var activities in allActivities) {
      for (var activity in activities) {
        String date = activity.startDateLocal.split('T')[0];
        if (!aggregatedDistances.containsKey(date)) {
          aggregatedDistances[date] = 0;
        }
        // Divide the distance by 1000 before adding
        aggregatedDistances[date] =
            aggregatedDistances[date]! + (activity.distance / 1000);
      }
    }

    // Initialize the team distances with 0.0 for each of the past 12 days
    List<double> team1Distances = List.filled(12, 0.0);
    List<double> team2Distances = List.filled(12, 0.0);

    // Fill the team distances with aggregated data
    for (int i = 0; i < 12; i++) {
      String date = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(Duration(days: 11 - i)));
      if (aggregatedDistances.containsKey(date)) {
        team1Distances[i] = aggregatedDistances[date]!;
        team2Distances[i] = aggregatedDistances[
            date]!; // Assuming same data for both teams for now
      }
    }

    // Update the providers
    ref.read(team1Provider.notifier).state = team1Distances;
    ref.read(team2Provider.notifier).state = team2Distances;

    // Print out the result
    // print('Team 1 Distances: $team1Distances');
    // print('Team 2 Distances: $team2Distances');
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final team1Distances = ref.watch(team1Provider);
    final team2Distances = ref.watch(team2Provider);

    return Column(
      children: [
        Expanded(
          child: TrackComponent(
            team1Distances: team1Distances,
            team2Distances: team2Distances,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () => submitActivity(ref, 1, 2.5),
                child: Text('Team 1: +2.5km'),
              ),
              ElevatedButton(
                onPressed: () => submitActivity(ref, 2, 5.0),
                child: Text('Team 2: +5.0km'),
              ),
            ],
          ),
        ),
        Container(
          height: 200,
          color: Colors.grey[200],
          child: ListView.builder(
            itemCount: participantEmails.length,
            itemBuilder: (context, index) {
              final email = participantEmails[index];
              // print('Building ListTile for $email');
              final activitiesAsyncValue =
                  ref.watch(userSpecificRangeActivitiesProvider(email));

              return activitiesAsyncValue.when(
                data: (activities) {
                  // print('Email: $email');
                  // print('Activities in the past 12 days: ${activities.length}');
                  // for (var activity in activities) {
                  //   print(
                  //       'Activity: ${activity.startDateLocal}, Distance: ${activity.distance}');
                  // }

                  // Ensure activities are from the past 12 days
                  activities = activities.where((activity) {
                    final activityDate =
                        DateTime.parse(activity.startDateLocal);
                    return activityDate
                        .isAfter(DateTime.now().subtract(Duration(days: 12)));
                  }).toList();

                  double totalDistance = activities.fold(
                      0, (sum, activity) => sum + activity.distance / 1000);
                  Map<String, List<Activity>> activitiesByDate = {};

                  for (var activity in activities) {
                    String date = activity.startDateLocal.split('T')[0];
                    if (!activitiesByDate.containsKey(date)) {
                      activitiesByDate[date] = [];
                    }
                    activitiesByDate[date]!.add(activity);
                  }

                  return ListTile(
                    title: Text(email),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Total Distance: ${totalDistance.toStringAsFixed(2)} km'),
                        ...activitiesByDate.entries.map((entry) {
                          double dateTotalDistance = entry.value.fold(
                              0,
                              (sum, activity) =>
                                  sum + activity.distance / 1000);
                          return Text(
                              '${entry.key}: ${entry.value.length} activities, ${dateTotalDistance.toStringAsFixed(2)} km');
                        }).toList(),
                      ],
                    ),
                  );
                },
                loading: () => CircularProgressIndicator(),
                error: (error, stack) => Text('Error: $error'),
              );
            },
          ),
        ),
      ],
    );
  }

  void submitActivity(WidgetRef ref, int team, double distance) {
    if (team == 1) {
      ref.read(team1Provider.notifier).update((state) => [...state, distance]);
    } else {
      ref.read(team2Provider.notifier).update((state) => [...state, distance]);
    }
  }
}

class TrackComponent extends StatelessWidget {
  final List<double> team1Distances;
  final List<double> team2Distances;

  TrackComponent({required this.team1Distances, required this.team2Distances});

  @override
  Widget build(BuildContext context) {
    // Generate cumulative distances
    List<double> cumulativeTeam1Distances =
        _getCumulativeDistances(team1Distances);
    List<double> cumulativeTeam2Distances =
        _getCumulativeDistances(team2Distances);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          backgroundColor: AppColors.primaryAccent,
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()} km',
                      style: TextStyle(fontSize: 12, color: Colors.white));
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt() + 1}',
                      style: TextStyle(fontSize: 12, color: Colors.white));
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(width: 2, color: Colors.white),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: _getSpots(cumulativeTeam1Distances),
              isCurved: true,
              color: Colors.greenAccent,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: _getSpots(cumulativeTeam2Distances),
              isCurved: true,
              color: Colors.redAccent,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get cumulative distances
  List<double> _getCumulativeDistances(List<double> distances) {
    List<double> cumulativeDistances = [];
    double total = 0;
    for (var distance in distances) {
      total += distance;
      cumulativeDistances.add(total);
    }
    return cumulativeDistances;
  }

  // Helper method to convert distances to FlSpots
  List<FlSpot> _getSpots(List<double> distances) {
    List<FlSpot> spots = [];
    for (int i = 0; i < distances.length; i++) {
      spots.add(FlSpot(i.toDouble(), distances[i]));
    }
    return spots;
  }
}

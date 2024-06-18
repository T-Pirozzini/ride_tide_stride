import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ride_tide_stride/models/activity.dart';
import 'package:ride_tide_stride/models/participant_activity.dart';
import 'package:ride_tide_stride/providers/activity_provider.dart';
import 'package:ride_tide_stride/screens/challenges/chaos_circuit/progress_display.dart';
import 'package:ride_tide_stride/screens/challenges/chaos_circuit/track_chart.dart';
import 'package:ride_tide_stride/theme.dart';

final team1Provider = StateProvider<List<double>>((ref) => []);
final team2Provider = StateProvider<List<double>>((ref) => []);

class TrackComponent extends ConsumerWidget {
  final List<dynamic> participantEmails;
  final Timestamp timestamp;

  TrackComponent({required this.participantEmails, required this.timestamp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      backgroundColor: AppColors.primaryAccent,
      body: FutureBuilder<List<List<Activity>>>(
        future: _fetchActivities(ref),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            List<ParticipantActivity> allActivities =
                _aggregateActivities(participantEmails, snapshot.data!);
            allActivities.sort((a, b) =>
                DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));
            return _buildContent(context, allActivities, ref);
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error.toString()}"));
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
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

  Future<List<List<Activity>>> _fetchActivities(WidgetRef ref) async {
    List<Future<List<Activity>>> futures = participantEmails.map((email) {
      return ref.read(userSpecificRangeActivitiesProvider(email).future);
    }).toList();
    return await Future.wait(futures);
  }

  List<ParticipantActivity> _aggregateActivities(
      List<dynamic> emails, List<List<Activity>> allActivitiesData) {
    List<ParticipantActivity> allActivities = [];
    for (int i = 0; i < emails.length; i++) {
      String email = emails[i];
      List<Activity> activities = allActivitiesData[i];
      Map<String, List<Activity>> activitiesByDate = {};
      activities.forEach((activity) {
        String date = activity.startDateLocal.split('T')[0];
        activitiesByDate.putIfAbsent(date, () => []).add(activity);
      });

      activitiesByDate.forEach((date, activities) {
        double totalDistance = activities.fold(
            0, (sum, activity) => sum + activity.distance / 1000);
        allActivities.add(ParticipantActivity(
          email: email,
          date: date,
          totalDistance: totalDistance,
          activityCount: activities.length,
        ));
      });
    }
    return allActivities;
  }

  Widget _buildContent(BuildContext context,
      List<ParticipantActivity> activities, WidgetRef ref) {
    final team1Distances = ref.watch(team1Provider);
    final team2Distances = ref.watch(team2Provider);

    return Column(
      children: [
        Container(
          height: 60,
          child: ProgressDisplay(activities: activities),
        ),
        Container(
          height: 300,
          child: TrackChart(
            team1Distances: team1Distances,
            team2Distances: team2Distances,
          ),
        ),
      ],
    );
  }
}

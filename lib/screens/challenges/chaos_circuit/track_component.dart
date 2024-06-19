import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ride_tide_stride/models/activity.dart';
import 'package:ride_tide_stride/models/participant_activity.dart';
import 'package:ride_tide_stride/providers/activity_provider.dart';
import 'package:ride_tide_stride/providers/opponent_provider.dart';
import 'package:ride_tide_stride/screens/challenges/chaos_circuit/progress_display.dart';
import 'package:ride_tide_stride/screens/challenges/chaos_circuit/track_chart.dart';
import 'package:ride_tide_stride/theme.dart';

final team1Provider =
    StateProvider<Map<String, Map<String, double>>>((ref) => {});
final team2Provider =
    StateProvider<Map<String, Map<String, double>>>((ref) => {});

class TrackComponent extends ConsumerWidget {
  final List<dynamic> participantEmails;
  final Timestamp timestamp;
  final String challengeId;
  final String difficulty;

  TrackComponent({
    required this.participantEmails,
    required this.timestamp,
    required this.challengeId,
    required this.difficulty,
  });

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
        _processOpponentDistances(ref);
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
    // Aggregate distances by date from the start date to the current date
    Map<String, Map<String, double>> team1Distances = {};

    for (var activities in allActivities) {
      for (var activity in activities) {
        String date = activity.startDateLocal.split('T')[0];
        if (!team1Distances.containsKey(date)) {
          team1Distances[date] = {};
        }
        if (!team1Distances[date]!.containsKey(activity.email)) {
          team1Distances[date]![activity.email] = 0;
        }
        // Divide the distance by 1000 before adding
        team1Distances[date]![activity.email] =
            team1Distances[date]![activity.email]! + (activity.distance / 1000);
      }
    }

    // Update the team1 provider
    ref.read(team1Provider.notifier).state = team1Distances;

    // Save the distances to Firestore
    _saveDistancesToFirestore(ref, team1Distances, 'team1Distances');
  }

  Future<void> _saveDistancesToFirestore(WidgetRef ref,
      Map<String, Map<String, double>> distances, String fieldName) async {
    final challengeDoc =
        FirebaseFirestore.instance.collection('Challenges').doc(challengeId);
    await challengeDoc.update({
      fieldName: distances,
    });
  }

  Future<void> _processOpponentDistances(WidgetRef ref) async {
    final opponents = ref.read(opponentsProvider);
    final challengeDoc =
        FirebaseFirestore.instance.collection('challenges').doc(challengeId);
    final challengeData = await challengeDoc.get();

    if (!challengeData.exists) {
      // If document doesn't exist, handle accordingly
      print('Challenge document does not exist');
      return;
    }

    final data = challengeData.data();
    if (data == null || !data.containsKey('timestamp')) {
      // If timestamp field is missing, handle accordingly
      print('Challenge timestamp is missing');
      return;
    }

    final challengeStartDate = (data['timestamp'] as Timestamp).toDate();
    final today = DateTime.now();
    final dates = _generateDatesList(challengeStartDate, today);

    // Fetch existing Team2Distances
    Map<String, Map<String, double>> team2Distances = {};
    if (data.containsKey('Team2Distances')) {
      final existingTeam2Distances =
          data['Team2Distances'] as Map<String, dynamic>;
      existingTeam2Distances.forEach((key, value) {
        team2Distances[key] = Map<String, double>.from(value as Map);
      });
    }

    final opponentTeam = opponents[difficulty];
    if (opponentTeam == null) {
      print('No opponents found for difficulty: $difficulty');
      return;
    }

    Random random = Random();

    for (var date in dates) {
      if (!team2Distances.containsKey(date)) {
        Map<String, double> opponentDistances = {};
        for (var name in opponentTeam.name) {
          opponentDistances[name] =
              random.nextDouble() * opponentTeam.distanceMax;
        }
        team2Distances[date] = opponentDistances;
      }
    }

    // Update the team2 provider with opponent distances
    ref.read(team2Provider.notifier).state = team2Distances;

    // Save the opponent distances to Firestore
    await _saveDistancesToFirestore(ref, team2Distances, 'Team2Distances');
  }

  List<String> _generateDatesList(DateTime startDate, DateTime endDate) {
    List<String> dates = [];
    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      dates.add(DateFormat('yyyy-MM-dd').format(currentDate));
      currentDate = currentDate.add(Duration(days: 1));
    }
    return dates;
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
            team1Distances: _getAggregatedTeamDistances(team1Distances),
            team2Distances: _getAggregatedTeamDistances(team2Distances),
          ),
        ),
      ],
    );
  }

  List<double> _getAggregatedTeamDistances(
      Map<String, Map<String, double>> teamDistances) {
    List<double> aggregatedDistances = [];
    teamDistances.forEach((date, distances) {
      aggregatedDistances
          .add(distances.values.fold(0.0, (sum, distance) => sum + distance));
    });
    return aggregatedDistances;
  }
}

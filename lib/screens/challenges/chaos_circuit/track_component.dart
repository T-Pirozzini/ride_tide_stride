import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ride_tide_stride/helpers/helper_functions.dart';
import 'package:ride_tide_stride/models/activity.dart';
import 'package:ride_tide_stride/models/opponent.dart';
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

class TrackComponent extends ConsumerStatefulWidget {
  final List<dynamic> participantEmails;
  final Timestamp timestamp;
  final String challengeId;
  final String difficulty;
  final String category;
  final String categoryActivity;

  TrackComponent({
    required this.participantEmails,
    required this.timestamp,
    required this.challengeId,
    required this.difficulty,
    required this.category,
    required this.categoryActivity,
  });

  @override
  _TrackComponentState createState() => _TrackComponentState();
}

class _TrackComponentState extends ConsumerState<TrackComponent> {
  bool _isProcessing = false;
  List<ParticipantActivity> _activities = [];
  List<String> _dates = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
    checkAndFinalizeChallenge();
  }

  Future<void> _initializeData() async {
    if (!_isProcessing) {
      _isProcessing = true;
      await _processActivities();
      await _processOpponentDistances();
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> checkAndFinalizeChallenge() async {
    final challengeDoc = FirebaseFirestore.instance
        .collection('Challenges')
        .doc(widget.challengeId);

    final team1DistancesMap = ref.read(team1Provider);
    final team2DistancesMap = ref.read(team2Provider);

    final team1TotalDistance = _calculateTotalDistance(team1DistancesMap);
    final team2TotalDistance = _calculateTotalDistance(team2DistancesMap);

    final now = DateTime.now();
    final challengeStartDate = widget.timestamp.toDate();
    final challengeEndDate = challengeStartDate.add(Duration(days: 30));

    if (now.isAfter(challengeEndDate)) {
      if (team1TotalDistance > team2TotalDistance) {
        await challengeDoc.update({
          'active': false,
          'success': true,
          'team1TotalDistance': team1TotalDistance,
          'team2TotalDistance': team2TotalDistance,
          'endDate': Timestamp.fromDate(now),
        });
      } else {
        await challengeDoc.update({
          'active': false,
          'success': false,
          'team1TotalDistance': team1TotalDistance,
          'team2TotalDistance': team2TotalDistance,
          'endDate': Timestamp.fromDate(now),
        });
      }
    }
  }

  double _calculateTotalDistance(
      Map<String, Map<String, double>> distancesMap) {
    double totalDistance = 0.0;
    distancesMap.forEach((date, distanceMap) {
      distanceMap.forEach((participant, distance) {
        totalDistance += distance;
      });
    });
    return totalDistance;
  }

  Future<void> _processActivities() async {
    final DateTime startDate = widget.timestamp.toDate();
    final activitiesByEmail =
        await Future.wait(widget.participantEmails.map((email) async {
      if (widget.category == 'Specific') {
        final categoryActivities =
            mapCategoryToActivityTypes(widget.categoryActivity);
        final args = ActivityArgs(email, startDate, categoryActivities);
        return await ref
            .read(userSpecificRangeAndCategoryActivitiesProvider(args).future);
      } else {
        final args = {'email': email, 'startDate': startDate};
        return ref.read(userSpecificRangeActivitiesProvider(args).future);
      }
    }).toList());

    // Aggregate distances by date from the start date to the current date
    Map<String, Map<String, double>> team1Distances = {};

    for (var activities in activitiesByEmail) {
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
    await _saveDistancesToFirestore(team1Distances, 'team1Distances');

    // Aggregate activities for ProgressDisplay
    _activities =
        _aggregateActivities(widget.participantEmails, activitiesByEmail);
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

  Future<void> _processOpponentDistances() async {
    final opponents = ref.read(opponentsProvider);
    final challengeDoc = FirebaseFirestore.instance
        .collection('Challenges')
        .doc(widget.challengeId);
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
    _dates = _generateDatesList(challengeStartDate, today);

    // Fetch existing Team2Distances
    Map<String, Map<String, double>> team2Distances = {};
    if (data.containsKey('Team2Distances')) {
      final existingTeam2Distances =
          data['Team2Distances'] as Map<String, dynamic>;
      existingTeam2Distances.forEach((key, value) {
        team2Distances[key] = Map<String, double>.from(value as Map);
      });
    }

    final opponentTeam = opponents[widget.difficulty];
    if (opponentTeam == null) {
      print('No opponents found for difficulty: ${widget.difficulty}');
      return;
    }

    Random random = Random();

    for (var date in _dates) {
      if (!team2Distances.containsKey(date)) {
        Map<String, double> opponentDistances = {};
        for (var name in opponentTeam.name) {
          // 50% chance that an opponent won't post an activity
          if (random.nextBool()) {
            opponentDistances[name] =
                1 + random.nextDouble() * (opponentTeam.distanceMax - 1);
          }
        }
        team2Distances[date] = opponentDistances;
      }
    }

    // Update the team2 provider with opponent distances
    ref.read(team2Provider.notifier).state = team2Distances;

    // Save the opponent distances to Firestore
    await _saveDistancesToFirestore(team2Distances, 'Team2Distances');

    // Aggregate opponent activities for ProgressDisplay
    _activities
        .addAll(_aggregateOpponentActivities(team2Distances, opponentTeam));

    // Sort activities by date to mix user and opponent activities
    _activities.sort(
        (a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));
  }

  List<ParticipantActivity> _aggregateOpponentActivities(
      Map<String, Map<String, double>> team2Distances, Opponent opponentTeam) {
    List<ParticipantActivity> opponentActivities = [];
    team2Distances.forEach((date, distances) {
      distances.forEach((name, distance) {
        opponentActivities.add(ParticipantActivity(
          email: name,
          date: date,
          totalDistance: distance,
          activityCount: 1,
          isOpponent: true,
          avatarUrl: opponentTeam.image[opponentTeam.name.indexOf(name)],
        ));
      });
    });
    return opponentActivities;
  }

  Future<void> _saveDistancesToFirestore(
      Map<String, Map<String, double>> distances, String fieldName) async {
    final challengeDoc = FirebaseFirestore.instance
        .collection('Challenges')
        .doc(widget.challengeId);
    await challengeDoc.update({
      fieldName: distances,
    });
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

  @override
  Widget build(BuildContext context) {
    final team1DistancesMap = ref.watch(team1Provider);
    final team2DistancesMap = ref.watch(team2Provider);

    List<double> team1Distances =
        _getAggregatedTeamDistances(team1DistancesMap);
    List<double> team2Distances =
        _getAggregatedTeamDistances(team2DistancesMap);

    return Scaffold(
      backgroundColor: AppColors.primaryAccent,
      body: Column(
        children: [
          Container(
            height: 70,
            child: ProgressDisplay(activities: _activities),
          ),
          Container(
            height: 300,
            child: TrackChart(
              team1Distances: team1Distances,
              team2Distances: team2Distances,
              dates: _dates,
            ),
          ),
        ],
      ),
    );
  }

  List<double> _getAggregatedTeamDistances(
      Map<String, Map<String, double>> teamDistances) {
    List<double> aggregatedDistances = [];
    _dates.forEach((date) {
      if (teamDistances.containsKey(date)) {
        aggregatedDistances.add(teamDistances[date]!
            .values
            .fold(0.0, (sum, distance) => sum + distance));
      } else {
        aggregatedDistances.add(0.0);
      }
    });
    return aggregatedDistances;
  }
}

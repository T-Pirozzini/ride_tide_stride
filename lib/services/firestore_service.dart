import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ride_tide_stride/helpers/helper_functions.dart';
import 'package:ride_tide_stride/models/activity.dart';
import 'package:ride_tide_stride/models/challengeDb.dart';
import 'package:ride_tide_stride/models/user_details.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final currentMonth = DateTime.now().month;

// fetch all user information
  Future<List<UserDetails>> fetchAllUsers() async {
    final QuerySnapshot result = await _db.collection('Users').get();
    final List<DocumentSnapshot> documents = result.docs;

    return documents.map((doc) {
      return UserDetails(
        username: doc['username'],
        email: doc['email'],
        role: doc['role'],
        dateCreated: (doc['dateCreated'] as Timestamp).toDate(),
        color: doc['color'],
      );
    }).toList();
  }

// fetch all activities
  Future<List<Activity>> fetchAllActivities() async {
    final QuerySnapshot result = await _db.collection('activities').get();
    final List<DocumentSnapshot> documents = result.docs;

    return documents.map((doc) {
      return Activity(
        id: doc['id'],
        startDateLocal: doc['start_date_local'],
        elevationGain: doc['elevation_gain'],
        distance: doc['distance'],
        movingTime: doc['moving_time'],
        fullname: doc['fullname'],
        name: doc['name'],
        type: doc['type'],
        power: doc['average_watts'] != null
            ? (doc['average_watts'] is int
                ? (doc['average_watts'] as int).toDouble()
                : doc['average_watts'] as double)
            : 0.0,
        averageSpeed: doc['average_speed'],
        email: doc['user_email'],
      );
    }).toList();
  }

// fetch all activities for the current user
  Future<List<Activity>> fetchAllUserActivities(String email) async {
    if (email.isEmpty) {
      throw Exception('Email is required to fetch activities.');
    }

    final QuerySnapshot result = await _db
        .collection('activities')
        .where('user_email', isEqualTo: email)
        .get();

    final List<DocumentSnapshot> documents = result.docs;

    return documents.map((doc) => Activity.fromDocument(doc)).toList();
  }

  // Fetch all activities for the current user within a specific date range
  Future<List<Activity>> fetchAllUserActivitiesWithinSpecificDateRange(
      String email, Timestamp startDate) async {
    if (email.isEmpty) {
      throw Exception('Email is required to fetch activities.');
    }
    final Timestamp endDateRange = Timestamp.fromMillisecondsSinceEpoch(
        startDate.millisecondsSinceEpoch + Duration(days: 30).inMilliseconds);

    final QuerySnapshot result = await _db
        .collection('activities')
        .where('user_email', isEqualTo: email)
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .where('timestamp', isLessThanOrEqualTo: endDateRange)
        .get();

    final List<DocumentSnapshot> documents = result.docs;

    return documents.map((doc) => Activity.fromDocument(doc)).toList();
  }

  // TEMPORARY FUNCTION
  // Fetch all activities for the current user within the past 2 months
  Future<List<Activity>> fetchAllUserActivitiesWithinSixMonths(
      String email) async {
    if (email.isEmpty) {
      throw Exception('Email is required to fetch activities.');
    }

    final Timestamp startDate =
        Timestamp.fromDate(DateTime.now().subtract(Duration(days: 60)));

    final QuerySnapshot result = await _db
        .collection('activities')
        .where('user_email', isEqualTo: email)
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .get();

    final List<DocumentSnapshot> documents = result.docs;

    return documents.map((doc) => Activity.fromDocument(doc)).toList();
  }

// fetch all user current month activities
  Future<List<Activity>> fetchAllUserCurrentMonthActivities(fullName) async {
    final startOfMonth = formatDateTimeToIso8601(getStartOfMonth());
    final endOfMonth = formatDateTimeToIso8601(getEndOfMonth());

    final QuerySnapshot result = await _db
        .collection('activities')
        .where('start_date_local', isGreaterThanOrEqualTo: startOfMonth)
        .where('start_date_local', isLessThanOrEqualTo: endOfMonth)
        .where('fullname', isEqualTo: fullName)
        .orderBy('start_date_local', descending: true)
        .get();

    final List<DocumentSnapshot> documents = result.docs;

    return documents.map((doc) => Activity.fromDocument(doc)).toList();
  }

// fetch all activities for the current month
  Future<List<Activity>> fetchCurrentMonthActivities() async {
    final startOfMonth = formatDateTimeToIso8601(getStartOfMonth());
    final endOfMonth = formatDateTimeToIso8601(getEndOfMonth());

    final QuerySnapshot result = await _db
        .collection('activities')
        .where('start_date_local', isGreaterThanOrEqualTo: startOfMonth)
        .where('start_date_local', isLessThanOrEqualTo: endOfMonth)
        .get();
    final List<DocumentSnapshot> documents = result.docs;

    return documents.map((doc) {
      return Activity(
        id: doc['activity_id'],
        startDateLocal: doc['start_date_local'],
        elevationGain: doc['elevation_gain'],
        distance: doc['distance'],
        movingTime: doc['moving_time'],
        fullname: doc['fullname'],
        name: doc['name'],
        type: doc['type'],
        power: doc['average_watts'] != null
            ? (doc['average_watts'] is int
                ? (doc['average_watts'] as int).toDouble()
                : doc['average_watts'] as double)
            : 0.0,
        averageSpeed: doc['average_speed'],
        email: doc['user_email'],
      );
    }).toList();
  }

  // fetch current challenge details
  Future<Map<String, dynamic>> fetchCurrentChallengeDetails(challengeId) async {
    final DocumentSnapshot result =
        await _db.collection('Challenges').doc(challengeId).get();
    ChallengeDb challenge = ChallengeDb(
      participantsEmails: List<dynamic>.from(result['participants'] ?? []),
      timestamp: result['timestamp'] ?? Timestamp.now(),
      name: result['name'] ?? '',
      description: result['description'] ?? '',
      difficulty: result['difficulty'] ?? '',
      createdBy: result['createdBy'] ?? '',
    );
    print("Challenge object: ${challenge.toMap()}");

    return challenge.toMap();
  }
}

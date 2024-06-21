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
        avatarUrl: doc['avatarUrl'] ?? "",
      );
    }).toList();
  }

// Fetch all user information as a stream
  Stream<List<UserDetails>> usersStream() {
    return _db.collection('Users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserDetails(
          username: doc['username'],
          email: doc['email'],
          role: doc['role'],
          dateCreated: (doc['dateCreated'] as Timestamp).toDate(),
          color: doc['color'],
          avatarUrl:
              doc.data().containsKey('avatarUrl') ? doc['avatarUrl'] : "",
        );
      }).toList();
    });
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
      String email, DateTime startDate) async {
    if (email.isEmpty) {
      throw Exception('Email is required to fetch activities.');
    }
    final DateTime endDate = DateTime.now();
    final String startDateString = startDate.toIso8601String();
    final String endDateString = endDate.toIso8601String();

    final QuerySnapshot result = await _db
        .collection('activities')
        .where('user_email', isEqualTo: email)
        .where('start_date_local', isGreaterThanOrEqualTo: startDateString)
        .where('start_date_local', isLessThanOrEqualTo: endDateString)
        .get();

    final List<DocumentSnapshot> documents = result.docs;

    return documents.map((doc) => Activity.fromDocument(doc)).toList();
  }

  // Fetch all activities for the current user within a specific date range
  Future<List<Activity>> fetchAllUserActivitiesWithinSpecificDateRangeAndActivityTypes(
      String email, DateTime startDate, List<String> activityTypes) async {
    if (email.isEmpty) {
      throw Exception('Email is required to fetch activities.');
    }
    final DateTime endDate = DateTime.now();
    final String startDateString = startDate.toIso8601String();
    final String endDateString = endDate.toIso8601String();

    final QuerySnapshot result = await _db
        .collection('activities')
        .where('user_email', isEqualTo: email)
        .where('type', whereIn: activityTypes)
        .where('start_date_local', isGreaterThanOrEqualTo: startDateString)
        .where('start_date_local', isLessThanOrEqualTo: endDateString)
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
      category: result['category'] ?? '',
      categoryActivity: result['categoryActivity'] ?? '',
    );
    print("Challenge object: ${challenge.toMap()}");

    return challenge.toMap();
  }
}

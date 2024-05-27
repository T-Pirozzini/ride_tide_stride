import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ride_tide_stride/helpers/helper_functions.dart';
import 'package:ride_tide_stride/models/activity.dart';
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
      );
    }).toList();
  }

// fetch all activities for the current user
  Future<List<Activity>> fetchAllUserActivities() async {
    final String? email = _auth.currentUser?.email;
    if (email == null) {
      throw Exception('User not logged in');
    }

    final QuerySnapshot result = await _db
        .collection('activities')
        .where('user_email', isEqualTo: email)
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
      );
    }).toList();
  }
}

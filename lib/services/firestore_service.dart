import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ride_tide_stride/helpers/helper_functions.dart';
import 'package:ride_tide_stride/models/activity.dart';
import 'package:ride_tide_stride/models/user.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final currentMonth = DateTime.now().month;

  Future<List<User>> fetchAllUsers() async {
    final QuerySnapshot result = await _db.collection('Users').get();
    final List<DocumentSnapshot> documents = result.docs;

    return documents.map((doc) {
      return User(
        username: doc['username'],
        email: doc['email'],
        role: doc['role'],
        dateCreated: (doc['dateCreated'] as Timestamp).toDate(),
        color: doc['color'],
      );
    }).toList();
  }

  Future<List<Activity>> fetchAllActivities() async {
    final QuerySnapshot result = await _db.collection('activities').get();
    final List<DocumentSnapshot> documents = result.docs;

    return documents.map((doc) {
      return Activity(
        id: doc['id'],
        startDateLocal: doc['start_date_local'],
      );
    }).toList();
  }

  Future<List<Activity>> fetchMonthlyActivities() async {
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
      );
    }).toList();
  }
}

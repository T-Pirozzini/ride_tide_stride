import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_tide_stride/models/activity.dart';
import 'package:ride_tide_stride/services/firestore_service.dart';

final allActivitiesProvider = FutureProvider<List<Activity>>((ref) {
  final firestoreService = FirestoreService();
  return firestoreService.fetchAllActivities();
});

final monthlyActivitiesProvider = FutureProvider<List<Activity>>((ref) {
  final firestoreService = FirestoreService();
  return firestoreService.fetchMonthlyActivities();
});

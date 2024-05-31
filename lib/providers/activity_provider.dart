import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_tide_stride/models/activity.dart';
import 'package:ride_tide_stride/services/firestore_service.dart';

final allActivitiesProvider = FutureProvider<List<Activity>>((ref) {
  final firestoreService = FirestoreService();
  return firestoreService.fetchAllActivities();
});

final monthlyActivitiesProvider = FutureProvider<List<Activity>>((ref) {
  final firestoreService = FirestoreService();
  return firestoreService.fetchCurrentMonthActivities();
});

// Define a Provider for fullName
final emailProvider = StateProvider<String>((ref) {
  return ''; // Default value, you should provide the actual email value
});

final userActivitiesProvider = FutureProvider.family<List<Activity>, String>((ref, email) {
  final firestoreService = FirestoreService();
  return firestoreService.fetchAllUserActivities(email);
});

// Define a Provider for fullName
final fullNameProvider = StateProvider<String>((ref) {
  return ''; // Default value, you should provide the actual fullName value
});

final userCurrentMonthActivitiesProvider =
    FutureProvider.family<List<Activity>, String>((ref, fullName) {
  final firestoreService = FirestoreService();
  return firestoreService.fetchAllUserCurrentMonthActivities(fullName);
});

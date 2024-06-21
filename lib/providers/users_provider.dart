import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_tide_stride/models/user_details.dart';
import 'package:ride_tide_stride/services/firestore_service.dart';

final usersProvider = FutureProvider<List<UserDetails>>((ref) async {
  final firestoreService = FirestoreService();
  return firestoreService.fetchAllUsers();
});

final usersStreamProvider = StreamProvider.autoDispose<List<UserDetails>>((ref) {
  final firestoreService = FirestoreService();
  return firestoreService.usersStream();
});


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_tide_stride/models/user.dart';
import 'package:ride_tide_stride/services/firestore_service.dart';

final usersProvider = FutureProvider<List<User>>((ref) async {
  final firestoreService = FirestoreService();
  return firestoreService.fetchAllUsers();
});

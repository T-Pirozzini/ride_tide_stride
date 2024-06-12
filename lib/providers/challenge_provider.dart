import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_tide_stride/models/challengeDb.dart';
import 'package:ride_tide_stride/services/firestore_service.dart';

final challengeDetailsProvider =
    FutureProvider.family<ChallengeDb, String>((ref, challengeId) async {
  final firestoreService = FirestoreService();
  final challengeData =
      await firestoreService.fetchCurrentChallengeDetails(challengeId);
  return ChallengeDb(
    name: challengeData['name'],
    description: challengeData['description'],
    difficulty: challengeData['difficulty'],
    createdBy: challengeData['createdBy'],
    timestamp: challengeData['startDate'],
    participantsEmails: List<dynamic>.from(challengeData['participantsEmails'] ?? []),
  );
});

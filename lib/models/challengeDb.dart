import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeDb {
  final String name;
  final String description;
  final String difficulty;
  final String createdBy;
  final Timestamp timestamp;
  final List<dynamic> participantsEmails;

  ChallengeDb({
    required this.name,
    required this.description,
    required this.difficulty,
    required this.createdBy,
    required this.timestamp,
    required this.participantsEmails,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'difficulty': difficulty,
      'createdBy': createdBy,
      'startDate': timestamp,
      'participantsEmails': participantsEmails,
    };
  }
}
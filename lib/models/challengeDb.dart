import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeDb {
  final String name;
  final String description;
  final String difficulty;
  final String createdBy;
  final Timestamp timestamp;
  final List<dynamic> participantsEmails;
  final String category;
  final String categoryActivity;
  final double team1TotalDistance;
  final double team2TotalDistance;

  ChallengeDb({
    required this.name,
    required this.description,
    required this.difficulty,
    required this.createdBy,
    required this.timestamp,
    required this.participantsEmails,
    required this.category,
    required this.categoryActivity,
    required this.team1TotalDistance,
    required this.team2TotalDistance,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'difficulty': difficulty,
      'createdBy': createdBy,
      'startDate': timestamp,
      'participantsEmails': participantsEmails,
      'category': category,
      'categoryActivity': categoryActivity,
      'team1TotalDistance': team1TotalDistance,
      'team2TotalDistance': team2TotalDistance,
    };
  }
}

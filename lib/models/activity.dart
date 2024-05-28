import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  const Activity({
    required this.id,
    required this.startDateLocal,
    required this.elevationGain,
  });

  final int id;
  final String startDateLocal;
  final double elevationGain;

  factory Activity.fromDocument(DocumentSnapshot doc) {
    return Activity(
      id: doc['activity_id'],
      startDateLocal: doc['start_date_local'],
      elevationGain: (doc['elevation_gain'] is int)
          ? (doc['elevation_gain'] as int).toDouble()
          : doc['elevation_gain'] as double,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  const Activity({
    required this.id,
    required this.startDateLocal,
    required this.elevationGain,
    required this.distance,
    required this.movingTime,
    required this.fullname,
    required this.name,
    required this.type,
    required this.power,
    required this.averageSpeed,
    required this.email,
  });

  final int id;
  final String startDateLocal;
  final double elevationGain;
  final double distance;
  final int movingTime;
  final String fullname;
  final String name;
  final String type;
  final double power;
  final double averageSpeed;
  final String email;

  factory Activity.fromDocument(DocumentSnapshot doc) {
    return Activity(
      id: doc['activity_id'],
      startDateLocal: doc['start_date_local'],
      elevationGain: (doc['elevation_gain'] is int)
          ? (doc['elevation_gain'] as int).toDouble()
          : doc['elevation_gain'] as double,
      distance: (doc['distance'] is int)
          ? (doc['distance'] as int).toDouble()
          : doc['distance'] as double,
      movingTime: doc['moving_time'],
      fullname: doc['fullname'],
      name: doc['name'],
      type: doc['type'],
      power: (doc['average_watts'] != null)
          ? (doc['average_watts'] is int
              ? (doc['average_watts'] as int).toDouble()
              : doc['average_watts'] as double)
          : 0.0,
      averageSpeed: doc['average_speed'],
      email: doc['user_email'],
    );
  }
}

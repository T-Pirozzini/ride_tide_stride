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
    final data = doc.data() as Map<String, dynamic>;

    // print('Parsing document: $data');

    return Activity(
      id: data['activity_id'] ?? 0,
      startDateLocal: data['start_date_local'] ?? '',
      elevationGain: (data['elevation_gain'] is int)
          ? (data['elevation_gain'] as int).toDouble()
          : data['elevation_gain'] as double,
      distance: (data['distance'] is int)
          ? (data['distance'] as int).toDouble()
          : data['distance'] as double,
      movingTime: data['moving_time'] ?? 0,
      fullname: data['fullname'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      power: (data['average_watts'] != null)
          ? (data['average_watts'] is int
              ? (data['average_watts'] as int).toDouble()
              : data['average_watts'] as double)
          : 0.0,
      averageSpeed: (data['average_speed'] is int)
          ? (data['average_speed'] as int).toDouble()
          : data['average_speed'] as double,
      email: data['user_email'] ?? '',
    );
  }
}

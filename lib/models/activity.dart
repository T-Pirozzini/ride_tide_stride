import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  const Activity({required this.id, required this.startDateLocal});
  final int id;
  final String startDateLocal;
}

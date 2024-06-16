import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ride_tide_stride/models/participant_activity.dart';

class ProgressDisplay extends StatelessWidget {
  final List<ParticipantActivity> activities;

  const ProgressDisplay({Key? key, required this.activities}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sorting should ideally be done where the list is managed, not in the build method
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: activities
            .map((activity) => _buildActivityDisplay(activity))
            .toList(),
      ),
    );
  }

  Widget _buildActivityDisplay(ParticipantActivity activity) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          CircleAvatar(
            child: Text(activity.email[0].toUpperCase()),
            backgroundColor: Colors.blue,
          ),
          Text('${activity.totalDistance.toStringAsFixed(2)} km'),
          Text(DateFormat('MM/dd').format(DateTime.parse(activity.date))),
          Text('${activity.activityCount} activities'),
        ],
      ),
    );
  }
}

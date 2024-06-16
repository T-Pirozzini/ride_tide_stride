import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ride_tide_stride/models/participant_activity.dart';

class ProgressDisplay extends StatelessWidget {
  final List<ParticipantActivity> activities;

  const ProgressDisplay({Key? key, required this.activities}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sort activities by date
    activities.sort((a, b) => a.date.compareTo(b.date));

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: activities.map((activity) => _buildActivityDisplay(activity)).toList(),
    );
  }

  Widget _buildActivityDisplay(ParticipantActivity activity) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          CircleAvatar(
            child: Text('${activity.totalDistance.toStringAsFixed(2)} km'),
            backgroundColor: Colors.blue,  // Customize based on more criteria if needed
          ),
          SizedBox(height: 4),
          Text(DateFormat('MM/dd').format(DateTime.parse(activity.date))),
          Text('${activity.activityCount} activities'),
        ],
      ),
    );
  }
}



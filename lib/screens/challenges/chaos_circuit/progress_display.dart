import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:ride_tide_stride/helpers/helper_functions.dart';
import 'package:ride_tide_stride/models/participant_activity.dart';
import 'package:badges/badges.dart' as badges;

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
          Text(
            DateFormat('MM/dd').format(DateTime.parse(activity.date)),
            style: TextStyle(fontSize: 8, color: Colors.white),
          ),
          FutureBuilder<Map<String, dynamic>>(
            future: getAvatarUrl(activity.email),
            builder: (BuildContext context,
                AsyncSnapshot<Map<String, dynamic>> snapshot) {
              Widget avatarChild = const Text('Loading...');
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) {
                  avatarChild = badges.Badge(
                    badgeContent: Text(
                      '${activity.totalDistance.toStringAsFixed(0)}km',
                      style: TextStyle(
                        color:
                            Colors.greenAccent, // Text color inside the badge
                        fontSize: 10,
                      ),
                    ),
                    badgeStyle: badges.BadgeStyle(
                      badgeColor: Colors.black,
                      shape: badges.BadgeShape.circle,
                      borderRadius: BorderRadius.circular(
                          8), // Optional, if you want rounded corners
                    ),
                    position:
                        badges.BadgePosition.bottomEnd(bottom: -4, end: -12),
                    child: CircleAvatar(
                      backgroundColor: hexToColor(snapshot.data!['color']),
                      radius: 15,
                      child: snapshot.data!['avatarUrl'] != "No Avatar"
                          ? ClipOval(
                              child: SvgPicture.network(
                                snapshot.data!['avatarUrl'],
                                width: 30,
                                height: 30,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(activity.email[0].toUpperCase()),
                    ),
                  );
                } else if (snapshot.hasError) {
                  avatarChild = CircleAvatar(
                    child: Text(activity.email[0].toUpperCase()),
                    backgroundColor: Colors.red,
                  );
                }
              }
              return avatarChild;
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_tide_stride/helpers/helper_functions.dart';
import 'package:ride_tide_stride/models/activity_type.dart';
import 'package:ride_tide_stride/providers/activity_provider.dart';
import 'package:ride_tide_stride/screens/activities/activity_controller.dart';
import 'package:ride_tide_stride/screens/activities/activity_chart.dart';
import 'package:ride_tide_stride/theme.dart';

class ActivitiesListPage extends ConsumerStatefulWidget {
  @override
  _ActivitiesListPageState createState() => _ActivitiesListPageState();
}

class _ActivitiesListPageState extends ConsumerState<ActivitiesListPage> {
  final ActivityController activityController = ActivityController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<MapEntry<String, Map<String, dynamic>>> currentActivities = [];
  String currentTitle = '';
  String currentActivityType = '';

  void openBottomSheet(
      List<MapEntry<String, Map<String, dynamic>>> activities, String title) {
    setState(() {
      currentActivities = activities;
      currentTitle = title;
    });
    showActivityDetails(context, activities, title);
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsyncValue = ref.watch(userActivitiesProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryColor,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text('Activities List')),
        body: activitiesAsyncValue.when(
          data: (activities) {
            final activitiesByMonth =
                activityController.groupActivitiesByMonth(activities);
            final elevationData =
                activityController.getElevationData(activities);
            final distanceData = activityController.getDistanceData(activities);
            final timeData = activityController.getMovingTimeData(activities);
            final months = activityController.getMonths(activities);

            return Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    // onTap: () => openBottomSheet(activitiesByMonth, 'Elevation'),
                    child: ActivityChart(
                      activityData: elevationData,
                      months: months,
                      title: 'Elevation',
                      activityType: ActivityDataType.elevation,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    // onTap: () => openBottomSheet(activitiesByMonth, 'Distance'),
                    child: ActivityChart(
                      activityData: distanceData,
                      months: months,
                      title: 'Distance',
                      activityType: ActivityDataType.distance,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    // onTap: () => openBottomSheet(activitiesByMonth, 'Time'),
                    child: ActivityChart(
                      activityData: timeData,
                      months: months,
                      title: 'Time',
                      activityType: ActivityDataType.movingTime,
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  void showActivityDetails(
      BuildContext context,
      List<MapEntry<String, Map<String, dynamic>>> activities,
      String activityType) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final entry = activities[index];
            final month = entry.key;
            final count = entry.value['count'] as int;
            final totalElevation = entry.value['totalElevation'] as double;
            final totalDistance = entry.value['totalDistance'] as double;
            final totalMovingTime = entry.value['totalMovingTime'] as double;

            return ListTile(
              title: Text('$month: $count'),
              subtitle: activityType == "Elevation"
                  ? Text(
                      'Total Elevation: ${totalElevation.toStringAsFixed(0)} m')
                  : activityType == "Distance"
                      ? Text(
                          'Total Distance: ${(totalDistance / 1000).toStringAsFixed(0)} km')
                      : Text(
                          'Total Moving Time: ${formatMovingTime(totalMovingTime)}'),
            );
          },
        );
      },
    );
  }
}

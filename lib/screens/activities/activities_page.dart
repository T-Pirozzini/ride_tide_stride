import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_tide_stride/models/activity_type.dart';
import 'package:ride_tide_stride/providers/activity_provider.dart';
import 'package:ride_tide_stride/screens/activities/activity_controller.dart';
import 'package:ride_tide_stride/screens/activities/activity_chart.dart';
import 'package:ride_tide_stride/theme.dart';

class ActivitiesListPage extends ConsumerWidget {
  final ActivityController activityController = ActivityController();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text('Activities List')),
        body: activitiesAsyncValue.when(
          data: (activities) {
            final activitiesByMonth =
                activityController.groupActivitiesByMonth(activities);
            final elevationData =
                activityController.getElevationData(activities);
            final distanceData = activityController.getDistanceData(activities);
            final months = activityController.getMonths(activities);

            return Column(
              children: [
                SizedBox(
                  height: 300,
                  child: ActivityChart(
                    activityData: elevationData,
                    months: months,
                    title: 'Elevation',
                    activityType: ActivityDataType.elevation,
                  ),
                ),
                SizedBox(
                  height: 300,
                  child: ActivityChart(
                    activityData: distanceData,
                    months: months,
                    title: 'Distance',
                    activityType: ActivityDataType.distance,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: activitiesByMonth.length,
                    itemBuilder: (context, index) {
                      final entry = activitiesByMonth[index];
                      final month = entry.key;
                      final count = entry.value['count'] as int;
                      final totalElevation =
                          entry.value['totalElevation'] as double;
                      return ListTile(
                        title: Text('$month: $count'),
                        subtitle: Text(
                            'Total Elevation: ${totalElevation.toStringAsFixed(2)} m'),
                      );
                    },
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
}

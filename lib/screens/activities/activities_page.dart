import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_tide_stride/providers/activity_provider.dart';
import 'package:ride_tide_stride/screens/activities/activity_controller.dart';
import 'package:ride_tide_stride/screens/activities/elevation_chart.dart';

class ActivitiesListPage extends ConsumerWidget {
  final ActivityController activityController = ActivityController();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsyncValue = ref.watch(userActivitiesProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Activities List')),
      body: activitiesAsyncValue.when(
        data: (activities) {
          final activitiesByMonth =
              activityController.groupActivitiesByMonth(activities);
          final elevationData = activityController.getElevationData(activities);
          final months = activityController.getMonths(activities);

          return Column(
            children: [
              SizedBox(
                height: 300,
                child: ElevationChart(
                  elevationData: elevationData,
                  months: months,
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
    );
  }
}

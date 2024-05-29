import 'package:intl/intl.dart';
import 'package:ride_tide_stride/models/activity.dart';

class ActivityController {
  List<MapEntry<String, Map<String, dynamic>>> groupActivitiesByMonth(
      List<Activity> activities) {
    final Map<String, Map<String, dynamic>> activitiesByMonth = {};

    final DateTime now = DateTime.now();
    final DateTime oneYearAgo = DateTime(now.year, now.month - 11, 1);

    for (var activity in activities) {
      final DateTime date = DateTime.parse(activity.startDateLocal);
      if (date.isBefore(oneYearAgo)) {
        continue; // Skip activities older than 12 months
      }
      final String month = DateFormat('yyyy-MM').format(date);

      if (!activitiesByMonth.containsKey(month)) {
        activitiesByMonth[month] = {
          'count': 0,
          'totalElevation': 0.0,
          'totalDistance': 0.0,
        };
      }

      activitiesByMonth[month]!['count'] =
          (activitiesByMonth[month]!['count'] as int) + 1;
      activitiesByMonth[month]!['totalElevation'] =
          (activitiesByMonth[month]!['totalElevation'] as double) +
              activity.elevationGain;
      activitiesByMonth[month]!['totalDistance'] =
          (activitiesByMonth[month]!['totalDistance'] as double) +
              activity.distance;
    }

    // Convert the map to a list of entries and sort by the key in ascending order
    final sortedActivitiesByMonth = activitiesByMonth.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Return only the last 12 months of data
    final int startIndex = sortedActivitiesByMonth.length > 12
        ? sortedActivitiesByMonth.length - 12
        : 0;

    return sortedActivitiesByMonth.sublist(startIndex);
  }

  List<double> getElevationData(List<Activity> activities) {
    final groupedData = groupActivitiesByMonth(activities);
    return groupedData
        .map((entry) => entry.value['totalElevation'] as double)
        .toList();
  }

  List<double> getDistanceData(List<Activity> activities) {
    final groupedData = groupActivitiesByMonth(activities);
    return groupedData
        .map((entry) => (entry.value['totalDistance'] / 1000) as double)
        .toList();
  }

  List<String> getMonths(List<Activity> activities) {
    final groupedData = groupActivitiesByMonth(activities);
    return groupedData.map((entry) {
      final DateTime date = DateFormat('yyyy-MM').parse(entry.key);
      return DateFormat('MMM').format(date); // Returns abbreviated month name
    }).toList();
  }
}

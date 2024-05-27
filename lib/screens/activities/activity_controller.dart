import 'package:intl/intl.dart';
import 'package:ride_tide_stride/models/activity.dart';

class ActivityController {
  List<MapEntry<String, Map<String, dynamic>>> groupActivitiesByMonth(
      List<Activity> activities) {
    final Map<String, Map<String, dynamic>> activitiesByMonth = {};

    for (var activity in activities) {
      final DateTime date = DateTime.parse(activity.startDateLocal);
      final String month = DateFormat('yyyy-MM').format(date);

      if (!activitiesByMonth.containsKey(month)) {
        activitiesByMonth[month] = {'count': 0, 'totalElevation': 0.0};
      }

      activitiesByMonth[month]!['count'] =
          (activitiesByMonth[month]!['count'] as int) + 1;
      activitiesByMonth[month]!['totalElevation'] =
          (activitiesByMonth[month]!['totalElevation'] as double) +
              activity.elevationGain;
    }

    // Convert the map to a list of entries and sort by the key in descending order
    final sortedActivitiesByMonth = activitiesByMonth.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return sortedActivitiesByMonth;
  }

  List<double> getElevationData(List<Activity> activities) {
    final groupedData = groupActivitiesByMonth(activities);
    return groupedData
        .map((entry) => entry.value['totalElevation'] as double)
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

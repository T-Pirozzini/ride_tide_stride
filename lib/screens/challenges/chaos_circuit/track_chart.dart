import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrackChart extends StatelessWidget {
  final List<double> team1Distances;
  final List<double> team2Distances;
  final List<String> dates;

  TrackChart({
    required this.team1Distances,
    required this.team2Distances,
    required this.dates,
  });

  @override
  Widget build(BuildContext context) {
    // Generate cumulative distances
    List<double> cumulativeTeam1Distances =
        _getCumulativeDistances(team1Distances);
    List<double> cumulativeTeam2Distances =
        _getCumulativeDistances(team2Distances);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          backgroundColor: Colors.black45,
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}km',
                      style: TextStyle(fontSize: 10, color: Colors.white));
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < dates.length) {
                    return Text(
                      DateFormat('dd').format(DateTime.parse(dates[index])),
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    );
                  } else {
                    return Container();
                  }
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(width: 2, color: Colors.white),
          ),
          lineBarsData: [
            LineChartBarData(
              belowBarData: BarAreaData(
                show: false,
                gradient: LinearGradient(
                  colors: [
                    Colors.greenAccent.withOpacity(0.3),
                    Colors.greenAccent,
                  ],
                ),
              ),
              spots: _getDateSpots(cumulativeTeam1Distances, dates),
              isCurved: true,
              color: Colors.greenAccent,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
            ),
            LineChartBarData(
              spots: _getDateSpots(cumulativeTeam2Distances, dates),
              isCurved: true,
              color: Colors.redAccent,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: false,
                gradient: LinearGradient(colors: [
                  Colors.redAccent.withOpacity(0.3),
                  Colors.redAccent,
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get cumulative distances
  List<double> _getCumulativeDistances(List<double> distances) {
    List<double> cumulativeDistances = [];
    double total = 0;
    for (var distance in distances) {
      total += distance;
      cumulativeDistances.add(total);
    }
    return cumulativeDistances;
  }

  // Helper method to convert distances to FlSpots with dates
  List<FlSpot> _getDateSpots(List<double> distances, List<String> dates) {
    List<FlSpot> spots = [];
    for (int i = 0; i < distances.length; i++) {
      spots.add(FlSpot(i.toDouble(), distances[i]));
    }
    return spots;
  }
}

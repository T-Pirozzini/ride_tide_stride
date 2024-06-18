import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ride_tide_stride/theme.dart';

class TrackChart extends StatelessWidget {
  final List<double> team1Distances;
  final List<double> team2Distances;

  TrackChart({required this.team1Distances, required this.team2Distances});

  @override
  Widget build(BuildContext context) {
    // Generate cumulative distances
    List<double> cumulativeTeam1Distances =
        _getCumulativeDistances(team1Distances);
    List<double> cumulativeTeam2Distances =
        _getCumulativeDistances(team2Distances);

    List<double> opponentTestData = [0, 3, 13, 30, 33, 40, 53, 70, 81, 90];

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
                  return Text('${value.toInt()} km',
                      style: TextStyle(fontSize: 12, color: Colors.white));
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
                  return Text('${value.toInt() + 1}',
                      style: TextStyle(fontSize: 12, color: Colors.white));
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
              spots: _getSpots(cumulativeTeam1Distances),
              isCurved: true,
              color: Colors.greenAccent,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
            ),
            LineChartBarData(
              // spots: _getSpots(cumulativeTeam2Distances),
              spots: _getSpots(opponentTestData),
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
                  ])),
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

  // Helper method to convert distances to FlSpots
  List<FlSpot> _getSpots(List<double> distances) {
    List<FlSpot> spots = [];
    for (int i = 0; i < distances.length; i++) {
      spots.add(FlSpot(i.toDouble(), distances[i]));
    }
    return spots;
  }
}

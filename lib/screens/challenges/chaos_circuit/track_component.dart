import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// final team1Provider = StateProvider<List<double>>((ref) => []);
// final team2Provider = StateProvider<List<double>>((ref) => []);

final team1Provider =
    StateProvider<List<double>>((ref) => [2.5, 3.0, 1.5, 2.0]);
final team2Provider =
    StateProvider<List<double>>((ref) => [3.0, 2.0, 1.0, 4.0, 5.0, 10.0, 20.0]);

class TrackPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team1Distances = ref.watch(team1Provider);
    final team2Distances = ref.watch(team2Provider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Track and Field'),
      ),
      body: Column(
        children: [
          Expanded(
            child: TrackComponent(
              team1Distances: team1Distances,
              team2Distances: team2Distances,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => submitActivity(ref, 1, 2.5),
                  child: Text('Team 1: +2.5km'),
                ),
                ElevatedButton(
                  onPressed: () => submitActivity(ref, 2, 5.0),
                  child: Text('Team 2: +3.0km'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void submitActivity(WidgetRef ref, int team, double distance) {
    if (team == 1) {
      ref.read(team1Provider.notifier).update((state) => [...state, distance]);
    } else {
      ref.read(team2Provider.notifier).update((state) => [...state, distance]);
    }
  }
}

class TrackComponent extends StatelessWidget {
  final List<double> team1Distances;
  final List<double> team2Distances;

  TrackComponent({required this.team1Distances, required this.team2Distances});

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
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
              // leftTitles: SideTitles(showTitles: true),
              // bottomTitles: SideTitles(showTitles: true),
              ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: _getSpots(cumulativeTeam1Distances),
              isCurved: true,
              color: Colors.blue,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: _getSpots(cumulativeTeam2Distances),
              isCurved: true,
              color: Colors.red,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
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

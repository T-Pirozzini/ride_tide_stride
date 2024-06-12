import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// final team1Provider = StateProvider<List<double>>((ref) => []);
// final team2Provider = StateProvider<List<double>>((ref) => []);

final team1Provider =
    StateProvider<List<double>>((ref) => [2.5, 3.0, 1.5, 2.0]);
final team2Provider =
    StateProvider<List<double>>((ref) => [3.0, 2.0, 1.0, 4.0]);

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
    return SfCartesianChart(
      primaryXAxis: NumericAxis(minimum: 0, maximum: 10, interval: 1),
      primaryYAxis: NumericAxis(minimum: 0, maximum: 1, isVisible: false),
      series: <CartesianSeries>[
        LineSeries<double, double>(
          dataSource: team1Distances,
          xValueMapper: (double distance, int index) => distance % 10,
          yValueMapper: (double distance, int index) => 0.5,
          markerSettings: MarkerSettings(isVisible: true),
          color: Colors.blue,
        ),
        LineSeries<double, double>(
          dataSource: team2Distances,
          xValueMapper: (double distance, int index) => distance % 10,
          yValueMapper: (double distance, int index) => 0.5,
          markerSettings: MarkerSettings(isVisible: true),
          color: Colors.red,
        ),
      ],
    );
  }
}

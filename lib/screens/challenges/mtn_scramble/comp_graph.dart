import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CompGraph extends StatelessWidget {
  final double team1Progress;
  final double team2Progress;
  

  const CompGraph(
      {super.key,
      required this.team1Progress,
      required this.team2Progress,
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        children: [
          
          PieChart(
            PieChartData(
              startDegreeOffset: -360,
              sections: _getSections(),
              borderData: FlBorderData(show: false),
              sectionsSpace: 0,
              centerSpaceRadius: 100,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    "Team 1",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${(team1Progress * 100).toStringAsFixed(1)}%",
                    style: TextStyle(fontSize: 10),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Column(
                children: [
                  Text(
                    "Team 2",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${(team2Progress * 100).toStringAsFixed(1)}%",
                    style: TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getSections() {
    return [
      PieChartSectionData(
        color: Colors.lightGreenAccent[200],
        value: team1Progress * 100,
        radius: 20,
        title: '',
        showTitle: false,
      ),
      PieChartSectionData(
        color: Colors.blueAccent[200],
        value: team2Progress * 100,
        radius: 20,
        title: '',
        showTitle: false,
      ),
      PieChartSectionData(
        color: Colors.transparent,
        value: 100 - team1Progress * 100,
        radius: 100,
        title: '',
        showTitle: false,
      ),
      PieChartSectionData(
        color: Colors.transparent,
        value: 100 - team2Progress * 100,
        radius: 100,
        title: '',
        showTitle: false,
      ),
    ];
  }
}

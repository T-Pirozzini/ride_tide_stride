import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CompGraph extends StatefulWidget {
  final double team1Progress;
  final double team2Progress;

  const CompGraph({
    Key? key,
    required this.team1Progress,
    required this.team2Progress,
  }) : super(key: key);

  @override
  _CompGraphState createState() => _CompGraphState();
}

class _CompGraphState extends State<CompGraph>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    )..addListener(() {
        setState(() {});
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                "Team 1",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                "${(widget.team1Progress * 100 * _animation.value).toStringAsFixed(1)}%",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightGreenAccent[200]),
              ),
              SizedBox(height: 10),
              Container(
                height: 150, // Fixed height for the chart
                width: 25, // Fixed width for the chart
                decoration: BoxDecoration(
                  color: Colors.grey[200]!.withOpacity(.6),
                ),
                child: LineChart(
                  _getLineChartData(widget.team1Progress * _animation.value,
                      Colors.lightGreenAccent[200]!.withOpacity(.6)),
                ),
              ),
            ],
          ),
          SizedBox(width: 20), // Spacing between the two charts
          Column(
            children: [
              Text(
                "Team 2",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                "${(widget.team2Progress * 100 * _animation.value).toStringAsFixed(1)}%",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlueAccent[200]),
              ),
              SizedBox(height: 10),
              Container(
                height: 150, // Fixed height for the chart
                width: 25, // Fixed width for the chart
                decoration: BoxDecoration(
                  color: Colors.grey[200]!.withOpacity(.6),
                ),
                child: LineChart(
                  _getLineChartData(widget.team2Progress * _animation.value,
                      Colors.lightBlueAccent[200]!.withOpacity(.6)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  LineChartData _getLineChartData(double progress, Color color) {
    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          color: color,
          spots: [
            FlSpot(0, 0),
            FlSpot(0, progress * 10), // Adjust the scaling factor as needed
          ],
          isCurved: true,
          barWidth: 15,
          belowBarData: BarAreaData(show: false),
          dotData: FlDotData(show: false),
          isStrokeCapRound: true,
        ),
      ],
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(show: false),
      lineTouchData: LineTouchData(enabled: false),
      minX: -1,
      maxX: 1,
      minY: 0,
      maxY: 10, // Adjust the scaling factor as needed
    );
  }
}

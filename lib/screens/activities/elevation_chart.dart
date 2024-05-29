import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ride_tide_stride/theme.dart';

class ElevationChart extends StatelessWidget {
  final List<double> elevationData;
  final List<String> months;

  ElevationChart({required this.elevationData, required this.months});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Elevation',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium!
                    .copyWith(color: Colors.white),
              ),
            ],
          ),
          Positioned.fill(
              child: FittedBox(
                  fit: BoxFit.cover,
                  child: Icon(Icons.landscape, color: Colors.white10))),
          Padding(
            padding: const EdgeInsets.only(
                top: 50.0), // Adjust top padding if needed
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final style = TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                        );
                        Widget text;
                        if (value.toInt() < months.length) {
                          text = Text(months[value.toInt()], style: style);
                        } else {
                          text = Text('', style: style);
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 4,
                          child: text,
                        );
                      },
                      reservedSize: 32,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final style = TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                        );
                        Widget text =
                            Text('${value.toStringAsFixed(0)} m', style: style);
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 4,
                          child: text,
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: elevationData
                    .asMap()
                    .map((index, elevation) => MapEntry(
                          index,
                          BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: elevation,
                                color: Colors.tealAccent,
                                width: 14,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          ),
                        ))
                    .values
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

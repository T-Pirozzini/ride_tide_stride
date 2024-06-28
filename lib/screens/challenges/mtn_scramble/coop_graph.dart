import 'package:flutter/material.dart';

class CoopGraph extends StatelessWidget {
  final double progress;
  final double totalElevationM;
  final double mapElevation;
  final double totalDistanceKM;
  final double mapDistance;
  final String elevationOrDistance;

  const CoopGraph({
    super.key,
    required this.progress,
    required this.totalElevationM,
    required this.mapElevation,
    required this.totalDistanceKM,
    required this.mapDistance,
    required this.elevationOrDistance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              minHeight: 10,
              valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.lightGreenAccent[200]!),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              elevationOrDistance == "Elevation"
                  ? Text(
                      "${totalElevationM.toStringAsFixed(2)} m / $mapElevation m",
                      textAlign: TextAlign.center,
                    )
                  : Text(
                      "${totalDistanceKM.toStringAsFixed(2)} m / $mapDistance m",
                      textAlign: TextAlign.center,
                    ),
              Text(
                "${(progress * 100).toStringAsFixed(2)}% Completed",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

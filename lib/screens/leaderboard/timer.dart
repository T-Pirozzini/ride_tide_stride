import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';

class CountdownTimerWidget extends StatelessWidget {
  final int endTime;
  final VoidCallback? onTimerEnd;

  const CountdownTimerWidget(
      {Key? key, required this.endTime, required this.onTimerEnd})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Text(
            'Competition ends in... ',
            style: TextStyle(color: Colors.white),
          ),
          CountdownTimer(
            endTime: endTime,
            textStyle: const TextStyle(fontSize: 12, color: Colors.white),
            onEnd: onTimerEnd,
          ),
        ],
      ),
    );
  }
}

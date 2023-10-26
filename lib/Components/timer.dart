import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';

class CountdownTimerWidget extends StatelessWidget {
  final int endTime;
  final VoidCallback? onTimerEnd;

  const CountdownTimerWidget({Key? key, required this.endTime, required this.onTimerEnd})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Text('Competition ends in... '),
          CountdownTimer(
            endTime: endTime,
            textStyle: const TextStyle(fontSize: 18),
            onEnd: onTimerEnd,
          ),
        ],
      ),
    );
  }
}

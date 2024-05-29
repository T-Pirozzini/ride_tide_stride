import 'package:flutter/material.dart';

class CustomTotalWidget extends StatelessWidget {
  const CustomTotalWidget({super.key, required this.total});

  final String total;

  static Color color = const Color(0xFF283D3B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: Text(
        total,
        style: TextStyle(
          fontSize: 20,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

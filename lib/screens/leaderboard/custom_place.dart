import 'package:flutter/material.dart';

class CustomPlaceWidget extends StatelessWidget {
  const CustomPlaceWidget({super.key, required this.place});

  final String place;
  static Color color = Color(0xFFA09A6A);
  static Color firstColor = Color(0xFFFFD700); // Gold
  static Color secondColor = Color(0xFFC0C0C0); // Silver
  static Color thirdColor = Color(0xFFCD7F32); // Bronze

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: place == "1"
                ? firstColor
                : place == "2"
                    ? secondColor
                    : place == "3"
                        ? thirdColor
                        : color,
            width: 2.0),
      ),
      padding: const EdgeInsets.all(8.0),
      constraints: const BoxConstraints(
        minWidth: 40.0,
        minHeight: 40.0,
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Text(
            place,
            style: TextStyle(
              fontSize: 16,
              color: place == "1"
                  ? firstColor
                  : place == "2"
                      ? secondColor
                      : place == "3"
                          ? thirdColor
                          : color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

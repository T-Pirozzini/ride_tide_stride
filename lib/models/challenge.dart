import 'package:flutter/material.dart';

class Challenge {
  final String name;
  final String assetPath;
  final String description;
  final List previewPaths;

  Challenge(
      {required this.name, required this.assetPath, required this.description, required this.previewPaths});
}

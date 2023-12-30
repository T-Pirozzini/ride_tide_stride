import 'package:flutter/material.dart';

class Snow2Surf extends StatefulWidget {
  const Snow2Surf({super.key});

  @override
  State<Snow2Surf> createState() => _Snow2SurfState();
}

class _Snow2SurfState extends State<Snow2Surf> {
  List<Map<String, dynamic>> categories = [
    {
      'name': 'Alpine Ski',
      'icon': Icons.abc,
    },
    {
      'name': 'Cross Country Ski',
      'icon': Icons.abc,
    },
    {
      'name': 'Road Run',
      'icon': Icons.abc,
    },
    {
      'name': 'Trail Run',
      'icon': Icons.abc,
    },
    {
      'name': 'Mountain Bike',
      'icon': Icons.abc,
    },
    {
      'name': 'Kayak',
      'icon': Icons.abc,
    },
    {
      'name': 'Road Bike',
      'icon': Icons.abc,
    },
    {
      'name': 'Canoe',
      'icon': Icons.abc,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Icon(categories[index]['icon']),
                title: Text(categories[index]['name']),
                // Add other properties if needed, like subtitle
              );
            },
          ),
          ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Icon(categories[index]['icon']),
                title: Text(categories[index]['name']),
                // Add other properties if needed, like subtitle
              );
            },
          ),
        ],
      ),
    );
  }
}

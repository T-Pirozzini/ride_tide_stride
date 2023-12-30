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
      'info': 'fastest 5km time',
      'current': {
        'user': 'User',
        'time': 'Time',
      },
      'record': {
        'user': 'User',
        'time': 'Time',
      }
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

  Widget buildCurrentCategoryCard(List<Map<String, dynamic>> categories) {
    return Container(
      width: 300,
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              Text('Team Name'),
              ListTile(
                leading: Icon(categories[index]['icon']),
                title: Text(categories[index]['name']),
                subtitle: Text('User'), // Replace with actual data
                trailing: Text('Time'), // Replace with actual data
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildRecordCategoryCard(List<Map<String, dynamic>> categories) {
    return Container(
      width: 300,
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              Text('Current Record'),
              ListTile(
                leading: Icon(categories[index]['icon']),
                title: Text(categories[index]['name']),
                subtitle: Text('User'), // Replace with actual data
                trailing: Text('Time'), // Replace with actual data
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: screenHeight,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Card(
                    child: buildCurrentCategoryCard(
                        categories)), // Current stats card
                Card(
                    child: buildRecordCategoryCard(
                        categories)), // Record stats card
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
      'name': 'Road Run',
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
      'name': 'Trail Run',
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
      'name': 'Mountain Bike',
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
      'name': 'Kayak',
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
      'name': 'Road Bike',
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
      'name': 'Canoe',
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
  ];

  Widget buildCategoryCard(
      List<Map<String, dynamic>> categories, String title) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading:
                    Icon(categories[index]['icon']), // Replace with actual icon
                title: Text(categories[index]['name']),
                subtitle: Text(categories[index]['current']
                    ['user']), // Replace with actual data
                trailing: Text(categories[index]['current']
                    ['time']), // Replace with actual data
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Container(
                width: 300, // Define a fixed width for each container
                child: buildCategoryCard(categories, 'Current Stats'),
              ),
              Container(
                width: 300, // Define a fixed width for each container
                child: buildCategoryCard(categories, 'Record Stats'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

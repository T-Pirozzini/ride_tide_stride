import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

class Snow2Surf extends StatefulWidget {
  const Snow2Surf({super.key});

  @override
  State<Snow2Surf> createState() => _Snow2SurfState();
}

class _Snow2SurfState extends State<Snow2Surf> {
  List<Map<String, dynamic>> categories = [
    {
      'name': 'Alpine Ski',
      'icon': Icons.downhill_skiing_outlined,
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
      'icon': Icons.downhill_skiing_outlined,
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
      'icon': Icons.directions_run_outlined,
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
      'icon': Icons.directions_run_outlined,
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
      'icon': Icons.directions_bike_outlined,
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
      'icon': Icons.kayaking_outlined,
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
      'icon': Icons.directions_bike_outlined,
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
      'icon': Icons.rowing_outlined,
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

  String formattedCurrentMonth = '';

  void getCurrentMonth() {
    final DateTime currentDateTime = DateTime.now();
    String formattedCurrentMonth =
        DateFormat('MMMM yyyy').format(currentDateTime);
    setState(() {
      this.formattedCurrentMonth = formattedCurrentMonth;
    });
  }

  void initState() {
    super.initState();
    getCurrentMonth();
  }

  Widget buildCategoryCard(
      List<Map<String, dynamic>> categories, String title) {
    Icon getNumberIcon(int index) {
      switch (index) {
        case 0:
          return Icon(
            Symbols.counter_1_rounded,
            size: 32,
          );
        case 1:
          return Icon(
            Symbols.counter_2_rounded,
            size: 32,
          );
        case 2:
          return Icon(
            Symbols.counter_3_rounded,
            size: 32,
          );
        case 3:
          return Icon(
            Symbols.counter_4_rounded,
            size: 32,
          );
        case 4:
          return Icon(
            Symbols.counter_5_rounded,
            size: 32,
          );
        case 5:
          return Icon(
            Symbols.counter_6_rounded,
            size: 32,
          );
        case 6:
          return Icon(
            Symbols.counter_7_rounded,
            size: 32,
          );
        case 7:
          return Icon(
            Symbols.counter_8_rounded,
            size: 32,
          );
        default:
          return Icon(Icons.looks_one);
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'The top stats for each sport this month - from all user submitted leaderboard entries',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return ListTile(
                visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    getNumberIcon(index),
                    SizedBox(width: 8),
                    Icon(categories[index]['icon']),
                  ],
                ), // Replace with actual icon
                title: Text(categories[index]['name']),
                subtitle: Text(categories[index]['current']
                    ['user']), // Replace with actual data
                trailing: Text(categories[index]['current']
                    ['time']), // Replace with actual data
              );
            },
          ),
        ),
        Text(
          "Cumulative Time: 00:00:00",
          style: TextStyle(fontSize: 24),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width,
            child: buildCategoryCard(categories, formattedCurrentMonth),
          ),
        ),
      ),
    );
  }
}

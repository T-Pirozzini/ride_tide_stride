import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Snow2SurfResultsPage extends StatefulWidget {
  final IconData icon;
  final String category;
  final List<String> types;

  Snow2SurfResultsPage({
    Key? key,
    required this.icon,
    required this.category,
    required this.types,
  }) : super(key: key);

  @override
  _Snow2SurfResultsPageState createState() => _Snow2SurfResultsPageState();
}

class _Snow2SurfResultsPageState extends State<Snow2SurfResultsPage> {
  Stream<QuerySnapshot> getCurrentMonthData() {
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;

    final firstDayOfMonth = DateTime(currentYear, currentMonth, 1);
    final lastDayOfMonth = DateTime(currentYear, currentMonth + 1, 0);

    return FirebaseFirestore.instance
        .collection('activities')
        .where('start_date',
            isGreaterThanOrEqualTo: firstDayOfMonth.toUtc().toIso8601String())
        .where('start_date',
            isLessThanOrEqualTo: lastDayOfMonth.toUtc().toIso8601String())
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results for: ${widget.category}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon),
            StreamBuilder<QuerySnapshot>(
              stream: getCurrentMonthData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final activityDocs = snapshot.data?.docs ?? [];
                List<Widget> activityWidgets = [];

                for (var doc in activityDocs) {
                  var data = doc.data() as Map<String, dynamic>;
                  String type = data['type'];
                  double distance = data['distance'] / 1000;
                  String fullName = data['fullname'];
                  double averageSpeed = data['average_speed'];

                  if (widget.types.contains(type)) {
                    // Adjusted filtering logic
                    activityWidgets.add(
                      ListTile(
                        title: Text(fullName),
                        subtitle: Text(
                            'Distance: $distance km, Speed: $averageSpeed m/s'),
                      ),
                    );
                  }
                }
                return Expanded(
                  child: ListView(
                    children: activityWidgets,
                  ),
                );
              },
            )

            // Add more details as needed
          ],
        ),
      ),
    );
  }
}

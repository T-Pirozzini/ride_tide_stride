import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Result {
  final String fullname;
  final Map<String, dynamic> totals;

  Result({required this.fullname, required this.totals});

  factory Result.fromMap(Map<String, dynamic> map) {
    return Result(
      fullname: map['fullname'],
      totals: Map<String, dynamic>.from(map['totals']),
    );
  }
}

class ResultsPage extends StatefulWidget {
  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final _firestore = FirebaseFirestore.instance;

  void showUserStatsDialog(
      BuildContext context, Result result, String category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('UserTopStats')
              .doc(result.fullname)
              .get(),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              Map<String, dynamic> userTopStats =
                  snapshot.data!.data() as Map<String, dynamic>;

              // Format moving time
              final int seconds = (result.totals['moving_time'] as num).toInt();
              final Duration duration = Duration(seconds: seconds);
              final String movingTime =
                  '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')} hrs';

              // Format distance
              final double distanceKm =
                  (result.totals['distance'] as double) / 1000.0;
              final String distance = '${distanceKm.toStringAsFixed(2)} km';

              // Format elevation gain
              final double elevationM =
                  (result.totals['elevation_gain'] as double);
              final String elevation = '${elevationM.toStringAsFixed(1)} m';

              List<Widget> children = [
                ListTile(
                  leading: Icon(Icons.timer_outlined),
                  title: Text('Top Time'),
                  subtitle: Text(userTopStats['top_moving_time_month'] ?? ''),
                  trailing: Text(movingTime),
                ),
                ListTile(
                  leading: Icon(Icons.straighten_outlined),
                  title: Text('Top Distance'),
                  subtitle: Text(userTopStats['top_distance_month'] ?? ''),
                  trailing: Text(distance),
                ),
                ListTile(
                  leading: Icon(Icons.landscape_outlined),
                  title: Text('Top Elevation'),
                  subtitle: Text(userTopStats['top_elevation_month'] ?? ''),
                  trailing: Text(elevation),
                ),
              ];

              return AlertDialog(
                titlePadding: EdgeInsets.all(16.0),
                title: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    result.fullname,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                content: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.25,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  ),
                ),
                actions: [
                  TextButton(
                    child: Text(
                      'Close',
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                title: Text('Loading...'),
              );
            } else {
              return AlertDialog(
                title: Text('Error!'),
                content: Text('There was an error fetching the stats.'),
                actions: [
                  TextButton(
                    child: Text('Close'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFD3C3),
      appBar: AppBar(
        title: const Text('Past Results',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w300, letterSpacing: 1.2)),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _firestore.collection('Results').get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          // Sort the documents by name in descending order (latest month first)
          List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
          docs.sort((a, b) => a.id.compareTo(b.id));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _buildMonthResults(docs[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildMonthResults(QueryDocumentSnapshot doc) {
    List<Result> distanceResults =
        _mapToResultsList(doc['rankings_by_distance']);
    List<Result> timeResults = _mapToResultsList(doc['rankings_by_elevation']);
    List<Result> elevationResults = _mapToResultsList(doc['rankings_by_time']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(2.0),
          child: Center(
            child: Text(doc.id,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
        ),
        const Divider(),
        Text(
          'Total Moving Time:',
          style: TextStyle(fontSize: 18),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3, // Adjust for the desired width-to-height ratio
            crossAxisSpacing: 0,
            mainAxisSpacing: 0,
          ),
          itemCount: timeResults.length,
          itemBuilder: (context, index) {
            return _buildResultGridItem(
                'moving_time', timeResults[index], index + 1);
          },
        ),
        const Divider(),
        Text(
          'Total Distance:',
          style: TextStyle(fontSize: 18),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 0,
            mainAxisSpacing: 0,
          ),
          itemCount: distanceResults.length,
          itemBuilder: (context, index) {
            return _buildResultGridItem(
                'distance', distanceResults[index], index + 1);
          },
        ),
        const Divider(),
        Text(
          'Total Elevation:',
          style: TextStyle(fontSize: 18),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3, // Adjust for the desired width-to-height ratio
            crossAxisSpacing: 0,
            mainAxisSpacing: 0,
          ),
          itemCount: elevationResults.length,
          itemBuilder: (context, index) {
            return _buildResultGridItem(
                'elevation_gain', elevationResults[index], index + 1);
          },
        ),
      ],
    );
  }

  List<Result> _mapToResultsList(List<dynamic>? rankingsList) {
    if (rankingsList == null) {
      return [];
    }

    return rankingsList.map((map) => Result.fromMap(map)).toList();
  }

  Widget _buildResultGridItem(String category, Result result, int rank) {
    IconData iconData;
    String displayValue;
    String formatDuration(int seconds) {
      final Duration duration = Duration(seconds: seconds);
      final int hours = duration.inHours;
      final int minutes = (duration.inMinutes % 60);
      final int remainingSeconds = (duration.inSeconds % 60);
      return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }

    switch (category) {
      case 'distance':
        iconData = Icons.straighten;
        displayValue =
            '${((result.totals[category] as double) / 1000).toStringAsFixed(2)} km';

        break;
      case 'moving_time':
        iconData = Icons.timer_outlined;
        displayValue = formatDuration((result.totals[category] as num).toInt());
        break;
      case 'elevation_gain':
        iconData = Icons.landscape_outlined;
        displayValue =
            '${(result.totals[category] as double).toStringAsFixed(1)} m';
        break;
      default:
        iconData = Icons.directions_run;
        displayValue = result.totals[category].toString();
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            showUserStatsDialog(context, result, category);
          },
          child: Card(
            elevation: 2,
            child: ListTile(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
              leading: customPlaceWidget(rank.toString()),
              title: Text(result.fullname, style: TextStyle(fontSize: 12)),
              trailing: Text(displayValue,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget customPlaceWidget(String place) {
    Color color = Color(0xFFA09A6A);
    switch (place) {
      case "1":
        color = Colors.yellow[700]!;
        break;
      case "2":
        color = Colors.grey[400]!;
        break;
      case "3":
        color = Color.fromARGB(255, 180, 119, 97);
        break;
      default:
        Colors.blueGrey; // No color for other ranks
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.0),
      ),
      padding: const EdgeInsets.all(10.0), // Adjust padding as needed
      child: Text(
        place,
        style: TextStyle(
          fontSize: 24, // Adjust font size as needed
          color: color, // Text color
          fontWeight: FontWeight.bold, // Bold text
        ),
      ),
    );
  }
}

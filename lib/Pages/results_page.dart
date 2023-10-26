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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          docs.sort((a, b) => b.id.compareTo(a.id));

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
          child: Text(doc.id,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const Divider(),
        Text('Total Moving Time:'),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio:
                2.5, // Adjust for the desired width-to-height ratio
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
        Text('Total Distance:'),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
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
        Text('Total Elevation:'),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio:
                2.5, // Adjust for the desired width-to-height ratio
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
    switch (category) {
      case 'distance':
        iconData = Icons.straighten;
        break;
      case 'moving_time':
        iconData = Icons.timer_outlined;
        break;
      case 'elevation_gain':
        iconData = Icons.landscape_outlined;
        break;
      default:
        iconData = Icons.directions_run;
    }

    return Column(
      children: [
        // Text(leaderboardTitle),
        Card(
          elevation: 2,
          child: ListTile(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
            leading: customPlaceWidget(rank.toString()),            
            title: Text(result.fullname, style: TextStyle(fontSize: 12)),
            subtitle: Text('${result.totals[category]}',
                style: TextStyle(fontSize: 10)),
            trailing: Icon(iconData),
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

  Color _getCircleColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.yellow[700]!;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Color.fromARGB(255, 180, 119,
            97); // You may need to define a bronze color if not available
      default:
        return Colors.blueGrey; // No color for other ranks
    }
  }

  Color _getTextColor(int rank) {
    if (rank <= 3) {
      return Colors
          .black; // or another color that contrasts well with gold/silver/bronze
    }
    return Colors.grey; // Default text color for other ranks
  }
}

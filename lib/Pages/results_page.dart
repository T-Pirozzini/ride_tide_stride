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
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3, // Adjust for the desired width-to-height ratio
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
                'distance', timeResults[index], index + 1);
          },
        ),
        const Divider(),
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
                'distance', elevationResults[index], index + 1);
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
        iconData = Icons.directions_run;
        break;
      // Add other categories and respective icons here.
      default:
        iconData = Icons.directions_run; // Default icon
    }

    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
        leading: CircleAvatar(
          backgroundColor: _getCircleColor(
              rank), // this function returns the appropriate color
          child: Text(
            '#${rank}',
            style: TextStyle(
                fontSize: 14,
                color: _getTextColor(
                    rank)), // this function returns the text color
          ),
        ),
        title: Text(result.fullname, style: TextStyle(fontSize: 12)),
        subtitle:
            Text('${result.totals[category]}', style: TextStyle(fontSize: 10)),
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

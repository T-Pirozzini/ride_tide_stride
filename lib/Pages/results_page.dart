import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ResultsPage extends StatefulWidget {
  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  late Stream<QuerySnapshot> resultsStream;

  @override
  void initState() {
    super.initState();
    resultsStream = FirebaseFirestore.instance
        .collection('Results')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Monthly Results')),
      body: StreamBuilder<QuerySnapshot>(
        stream: resultsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return Center(child: Text('No results found.'));
          }

          final results = snapshot.data!.docs;

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              final monthYear = result.id; // this will be like "October 2023"

              return Card(
                child: Column(
                  children: [
                    Text(monthYear),
                    // Display rankings by time as an example:
                    _buildRankingList(result['rankings_by_time']),
                    // You can also add rankings by distance and elevation similarly
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRankingList(List rankings) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: rankings.length,
      itemBuilder: (context, index) {
        final ranking = rankings[index];
        final fullName = ranking['fullname'];
        IconData? trophyIcon;

        switch (index) {
          case 0:
            trophyIcon = Icons.star; // Gold trophy icon
            break;
          case 1:
            trophyIcon = Icons.star_half; // Silver trophy icon
            break;
          case 2:
            trophyIcon = Icons.star_border; // Bronze trophy icon
            break;
        }

        return ListTile(
          leading: trophyIcon != null ? Icon(trophyIcon) : null,
          title: Text(fullName),
        );
      },
    );
  }
}

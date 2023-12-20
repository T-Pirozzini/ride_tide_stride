import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AwardsPage extends StatefulWidget {
  const AwardsPage({Key? key}) : super(key: key);

  @override
  State<AwardsPage> createState() => _AwardsPageState();
}

class _AwardsPageState extends State<AwardsPage> {
  List<AwardWinner> awardWinners = [];
  List<AwardWinner> diverseAwardWinners = [];

  @override
  void initState() {
    super.initState();
    fetchAwards();
  }

  Future<void> fetchAwards() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('Results').get();
    Map<String, AwardWinner> bestAwards = {
      'distance':
          AwardWinner(name: '', category: 'distance', month: '', value: 0),
      'elevation_gain': AwardWinner(
          name: '', category: 'elevation_gain', month: '', value: 0),
      'moving_time':
          AwardWinner(name: '', category: 'moving_time', month: '', value: 0),
    };

    for (var doc in snapshot.docs) {
      final month = doc.id;
      final List<dynamic> usersData = doc.get('data');

      for (var userData in usersData) {
        final fullname = userData['fullname'];
        final Map<String, dynamic> totals = userData['totals'];

        for (var category in ['distance', 'elevation_gain', 'moving_time']) {
          if (totals[category] > bestAwards[category]!.value) {
            bestAwards[category] = AwardWinner(
              name: fullname,
              category: category,
              month: month,
              value: totals[category],
            );
          }
        }
      }
    }

    setState(() {
      awardWinners = bestAwards.values.toList();
    });
    await fetchActivityAwards('2023-11');
  }

  Future<void> fetchActivityAwards(String month) async {
    final startOfMonth = DateTime.parse('$month-01T00:00:00Z');
    final endOfMonth = DateTime(startOfMonth.year, startOfMonth.month + 1, 1);

    final activitiesSnapshot = await FirebaseFirestore.instance
        .collection('activities')
        .where('start_date',
            isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .where('start_date', isLessThan: endOfMonth.toIso8601String())
        .get();

    Map<String, Set<String>> userActivities = {};

    for (var doc in activitiesSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final fullName = data['fullname'];
      final activityType = data['sport_type'];
      print('$fullName $activityType');

      // Initialize the set of activities for the user if it's their first activity
      userActivities.putIfAbsent(fullName, () => <String>{});

      // Add the activity type to the user's set
      userActivities[fullName]?.add(activityType);
    }

    // Find the user with the most diverse set of activities
    String topUser = '';
    int maxActivityTypes = 0;

    userActivities.forEach((fullName, activities) {
      if (activities.length > maxActivityTypes) {
        maxActivityTypes = activities.length;
        topUser = fullName;
      }
    });

    if (topUser.isNotEmpty) {
      final diverseActivityAward = AwardWinner(
        name: topUser,
        category: 'Diverse Activities',
        month: month,
        value: maxActivityTypes.toDouble(),
      );

      setState(() {
        diverseAwardWinners = [
          diverseActivityAward
        ]; // Replace the existing list with the new winner
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLoading = awardWinners.isEmpty && diverseAwardWinners.isEmpty;

    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFDFD3C3),
      appBar: AppBar(
        title: const Text(
          'Awards',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        // Use SingleChildScrollView to allow the page to be scrollable
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 20),
            const Text(
              'Awards Page',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            // Call buildAwardListView and buildDiverseAwardListView separately
            buildAwardListView(awardWinners),
            buildDiverseAwardListView(diverseAwardWinners),
          ],
        ),
      ),
    );
  }

  Widget buildAwardListView(List<AwardWinner> awards) {
    return Container(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: awards.length,
        itemBuilder: (context, index) {
          final award = awards[index];
          return Card(
            elevation: 4.0,
            child: Container(
              width: 160,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/power_level_3.png', // Replace with your asset
                    height: 100,
                  ),
                  Text(
                    award.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${award.category}: ${award.value}',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Month: ${award.month}',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildDiverseAwardListView(List<AwardWinner> awards) {
    return Container(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: awards.length,
        itemBuilder: (context, index) {
          final award = awards[index];
          return Card(
            elevation: 4.0,
            child: Container(
              width: 160,
              padding: EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/power_level_3.png', // Replace with your asset
                    height: 100,
                  ),
                  Text(
                    award.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${award.category}: ${award.value.toInt()} types',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Month: ${award.month}',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AwardWinner {
  final String name;
  final String category;
  final String month;
  final double value;

  AwardWinner({
    required this.name,
    required this.category,
    required this.month,
    required this.value,
  });
}

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
    fetchAwards().then((_) {
      print('Awards fetched successfully.');
    }).catchError((e) {
      print('An error occurred while fetching awards: $e');
    });
  }

  Future<void> fetchAwards() async {
    final resultsSnapshot =
        await FirebaseFirestore.instance.collection('Results').get();

    Map<String, AwardWinner> bestAwards = {
      'distance':
          AwardWinner(name: '', category: 'distance', month: '', value: 0),
      'elevation_gain': AwardWinner(
          name: '', category: 'elevation_gain', month: '', value: 0),
      'moving_time':
          AwardWinner(name: '', category: 'moving_time', month: '', value: 0),
    };

    for (var monthDoc in resultsSnapshot.docs) {
      final month = monthDoc.id; // e.g., "November 2023"
      final List<dynamic> usersData = monthDoc.get('data');

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

    List<Future<AwardWinner?>> fetchTasks = [];
    for (var monthDoc in resultsSnapshot.docs) {
      final String monthYear = monthDoc.id; // "November 2023"
      final DateTime startOfMonth = getFirstDayOfMonthFromString(monthYear);
      final DateTime endOfMonth =
          DateTime(startOfMonth.year, startOfMonth.month + 1, 1);

      fetchTasks.add(fetchActivityAwards(startOfMonth, endOfMonth, monthYear));
    }

    List<AwardWinner?> fetchedDiverseAwards = await Future.wait(fetchTasks);

    // Filter out any nulls from fetchedDiverseAwards
    List<AwardWinner> validDiverseAwards =
        fetchedDiverseAwards.whereType<AwardWinner>().toList();

    // Update the state with the best awards and the new diverse awards
    setState(() {
      awardWinners = bestAwards.values.toList();
      diverseAwardWinners = validDiverseAwards;
    });
  }

  Future<AwardWinner?> fetchActivityAwards(
      DateTime startOfMonth, DateTime endOfMonth, String monthYear) async {
    try {
      // Format the start and end dates to match the ISO 8601 format used in your Firestore collection
      String formattedStart = startOfMonth.toUtc().toIso8601String();
      String formattedEnd = endOfMonth.toUtc().toIso8601String();

      final activitiesSnapshot = await FirebaseFirestore.instance
          .collection('activities')
          .where('start_date', isGreaterThanOrEqualTo: formattedStart)
          .where('start_date', isLessThan: formattedEnd)
          .get();

      Map<String, Set<String>> userActivities = {};

      for (var doc in activitiesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final fullName = data['fullname'] as String;
        final activityType = data['sport_type'] as String;
        print('Activity: $fullName, $activityType');

        userActivities.putIfAbsent(fullName, () => <String>{});
        userActivities[fullName]?.add(activityType);
      }

      String topUser = '';
      int maxActivityTypes = 0;

      userActivities.forEach((fullName, activities) {
        if (activities.length > maxActivityTypes) {
          maxActivityTypes = activities.length;
          topUser = fullName;
        }
      });

      if (topUser.isNotEmpty) {
        print(
            'Top user for diverse activities in $monthYear: $topUser with $maxActivityTypes activities.');
        return AwardWinner(
          name: topUser,
          category: 'Diverse Activities',
          month: monthYear,
          value: maxActivityTypes.toDouble(),
        );
      }
    } catch (e) {
      print('Error fetching diverse activities for $monthYear: $e');
    }
    return null;
  }

  DateTime getFirstDayOfMonthFromString(String monthYear) {
    final Map<String, String> monthMappings = {
      'January': '01',
      'February': '02',
      'March': '03',
      'April': '04',
      'May': '05',
      'June': '06',
      'July': '07',
      'August': '08',
      'September': '09',
      'October': '10',
      'November': '11',
      'December': '12',
    };

    final parts = monthYear.split(' ');
    if (parts.length != 2) return DateTime.now(); // Handle invalid format

    final month = monthMappings[parts[0]];
    final year = parts[1];

    if (month == null) return DateTime.now(); // Handle invalid month

    return DateTime.parse('$year-$month-01T00:00:00');
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
            if (awardWinners.isNotEmpty) buildAwardListView(awardWinners),
            if (diverseAwardWinners.isNotEmpty)
              buildDiverseAwardListView(diverseAwardWinners),
          ],
        ),
      ),
    );
  }

  Widget buildAwardListView(List<AwardWinner> awards) {
    return Container(
      height: 300,
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
      height: 300,
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

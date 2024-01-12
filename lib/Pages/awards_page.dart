import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  String formatAwardValue(AwardWinner award) {
    switch (award.category) {
      case 'Total Distance':
        // Convert meters to kilometers and format to 2 decimal places
        return '${(award.value / 1000).toStringAsFixed(2)} km';
      case 'Total Elevation':
        // Format to 2 decimal places with m at the end
        return '${award.value.toStringAsFixed(2)} m';
      case 'Total Time':
        // Convert seconds to hours and minutes
        int totalSeconds = award.value.toInt();
        int hours = totalSeconds ~/ 3600;
        int minutes = (totalSeconds % 3600) ~/ 60;
        return '${hours}hr ${minutes}mins';
      default:
        return '${award.value}';
    }
  }

  String getImageForAwardType(String awardType) {
    switch (awardType) {
      case 'distance':
        return 'assets/images/award_distance.png';
      case 'elevation_gain':
        return 'assets/images/award_elevation.png';
      case 'moving_time':
        return 'assets/images/award_time.png';
      default:
        return 'assets/images/mtn.png';
    }
  }

  Future<void> fetchAwards() async {
    final resultsSnapshot =
        await FirebaseFirestore.instance.collection('Results').get();

    Map<String, AwardWinner> bestAwards = {
      'distance': AwardWinner(
          name: '',
          category: 'Total Distance',
          month: '',
          value: 0,
          image: 'assets/images/award_distance.png'),
      'elevation_gain': AwardWinner(
          name: '',
          category: 'Total Elevation',
          month: '',
          value: 0,
          image: 'assets/images/award_elevation.png'),
      'moving_time': AwardWinner(
          name: '',
          category: 'Total Time',
          month: '',
          value: 0,
          image: 'assets/images/award_time.png'),
    };

    for (var monthDoc in resultsSnapshot.docs) {
      final month = monthDoc.id;
      final List<dynamic> usersData = monthDoc.get('data');

      for (var userData in usersData) {
        final fullname = userData['fullname'];
        final Map<String, dynamic> totals = userData['totals'];

        for (var categoryKey in bestAwards.keys) {
          final categoryValue = bestAwards[categoryKey]!.value;
          if (totals[categoryKey] > categoryValue) {
            bestAwards[categoryKey] = AwardWinner(
              name: fullname,
              category: bestAwards[categoryKey]!.category,
              month: month,
              value: totals[categoryKey],
              image: getImageForAwardType(categoryKey),
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
          image: 'assets/images/award_diverse.png',
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
          'Awards: A work in progress :)',
          style: TextStyle(
            fontSize: 18,
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
            Text('Congratulations!',
                style: GoogleFonts.tektur(textStyle: TextStyle(fontSize: 28))),
            const Text(
              'You are among the best in the Universe!',
              style: TextStyle(
                fontSize: 18,
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
              width: 200,
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Image.asset(
                      award.image,
                      fit: BoxFit.contain,
                      height: 100,
                    ),
                  ),
                  Text(
                    award.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${award.category}: ${formatAwardValue(award)}', // Use the helper method here
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    'Month: ${award.month}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
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
              width: 200,
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly, // Improved spacing
                children: [
                  Expanded(
                    child: Image.asset(
                      'assets/images/award_diverse.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  Text(
                    award.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${award.category}: ${award.value.toInt()} types',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    'Month: ${award.month}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
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
  final String image;

  AwardWinner({
    required this.name,
    required this.category,
    required this.month,
    required this.value,
    required this.image,
  });
}

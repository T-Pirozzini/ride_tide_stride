import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';

class CompetitionPage extends StatefulWidget {
  final bool showTeamChoiceDialog;
  const CompetitionPage({super.key, this.showTeamChoiceDialog = false});

  @override
  State<CompetitionPage> createState() => _CompetitionPageState();
}

class _CompetitionPageState extends State<CompetitionPage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  String getFormattedCurrentMonth() {
    final DateTime currentDateTime = DateTime.now();
    String formattedCurrentMonth =
        DateFormat('MMMM yyyy').format(currentDateTime);
    return formattedCurrentMonth;
  }

  Future<Map<String, dynamic>?> getStravaUserDetails() async {
    if (currentUser?.email == null) {
      return null;
    }

    try {
      final userActivities = await getFilteredActivities();

      if (userActivities.isEmpty) {
        print(
            'No documents found for the user with email: ${currentUser!.email}');
        return null;
      }

      double totalElevation = 0.0;
      for (var doc in userActivities) {
        var data = doc.data() as Map<String, dynamic>;
        // Convert elevation_gain to double no matter what type it is stored as
        var elevationGain = data['elevation_gain'] is int
            ? (data['elevation_gain'] as int).toDouble()
            : (data['elevation_gain'] as double? ?? 0.0);
        totalElevation += elevationGain;
      }

      final userData = {
        'fullname': (userActivities.first.data()
                as Map<String, dynamic>)['fullname'] as String? ??
            '',
        // Force total_elevation to be a double
        'total_elevation': totalElevation,
      };

      return userData;
    } catch (e) {
      print('Error getting user details: $e');
      return null;
    }
  }

  Future<List<QueryDocumentSnapshot>> getFilteredActivities() async {
    final firstDayOfMonth =
        DateTime(DateTime.now().year, DateTime.now().month, 1);
    final lastDayOfMonth =
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

    // Fetch activities within the date range
    final querySnapshot = await FirebaseFirestore.instance
        .collection('activities')
        .where('start_date',
            isGreaterThanOrEqualTo: firstDayOfMonth.toUtc().toIso8601String())
        .where('start_date',
            isLessThanOrEqualTo: lastDayOfMonth.toUtc().toIso8601String())
        .get();

    // Filter activities by user's email
    final userActivities = querySnapshot.docs
        .where((doc) => doc.data()['user_email'] == currentUser!.email)
        .toList();

    return userActivities;
  }

  void _showTeamChoiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Join a Team'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Team 1'),
                  ElevatedButton(
                    onPressed: () async {
                      Map<String, dynamic>? stravaUsername =
                          await getStravaUserDetails();
                      print(stravaUsername);
                      if (stravaUsername != null) {
                        final competitionsCollection = FirebaseFirestore
                            .instance
                            .collection('Competitions');
                        await competitionsCollection
                            .doc(getFormattedCurrentMonth())
                            .update({
                          'team_1': FieldValue.arrayUnion([stravaUsername]),
                          'total_elevation':
                              stravaUsername['total_elevation'].toDouble(),
                        });
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Text('Join Team 1'),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Team 2'),
                  ElevatedButton(
                    onPressed: () async {
                      Map<String, dynamic>? stravaUsername =
                          await getStravaUserDetails();
                      print(stravaUsername);
                      if (stravaUsername != null) {
                        final competitionsCollection = FirebaseFirestore
                            .instance
                            .collection('Competitions');
                        await competitionsCollection
                            .doc(getFormattedCurrentMonth())
                            .update({
                          'team_2': FieldValue.arrayUnion([stravaUsername]),
                          'total_elevation':
                              stravaUsername['total_elevation'].toDouble(),
                        });
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Text('Join Team 2'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot> getCompetitionsData() {
    return FirebaseFirestore.instance.collection('Competitions').snapshots();
  }

  List<dynamic> team1Members = [];
  List<dynamic> team2Members = [];

  @override
  void initState() {
    super.initState();

    // Fetch and set the competition document for the current month
    final competitionDocId = getFormattedCurrentMonth();
    FirebaseFirestore.instance
        .collection('Competitions')
        .doc(competitionDocId)
        .snapshots()
        .listen((docSnapshot) {
      if (docSnapshot.exists) {
        setState(() {
          team1Members = List.from(docSnapshot.data()?['team_1'] ?? []);
          team2Members = List.from(docSnapshot.data()?['team_2'] ?? []);
          print('Team 1: $team1Members');
          print('Team 2: $team2Members');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the total elevation for each team
    double team1TotalElevation = team1Members.fold(
      0.0,
      (sum, member) => sum + (member['total_elevation'] as double? ?? 0.0),
    );

    double team2TotalElevation = team2Members.fold(
      0.0,
      (sum, member) => sum + (member['total_elevation'] as double? ?? 0.0),
    );

    Color getShadeForTeamMember(int baseColorValue, int memberIndex) {
      // This function assumes that baseColorValue is a valid color value like Colors.blue.value or Colors.red.value.
      // The shadeOffset ensures that the color stays within a reasonable range and does not overflow valid color values.
      int shadeOffset = 100 * (memberIndex + 1);
      int newColorValue = (baseColorValue + shadeOffset) % 0xFFFFFF;
      return Color(newColorValue).withOpacity(1.0);
    }

// Team 1 cumulative percent calculation
    List<Widget> team1Indicators = team1Members.map((member) {
      double membersPercentTeam1 = team1TotalElevation / 5000;
      return CircularPercentIndicator(
        radius: 175.0,
        lineWidth: 10.0,
        percent: membersPercentTeam1 >= 1.0 ? 1.0 : membersPercentTeam1,
        backgroundColor: Colors.grey.shade200,
        progressColor: Colors.lightBlueAccent[member['shade'] as int? ?? 100],
        startAngle: 180,
        circularStrokeCap: CircularStrokeCap.butt,
        reverse: false,
      );
    }).toList();

// Team 2 cumulative percent calculation
    List<Widget> team2Indicators = team2Members.map((member) {
      double membersPercentTeam2 = team2TotalElevation / 5000;
      return CircularPercentIndicator(
        radius: 160.0,
        lineWidth: 10.0,
        percent: membersPercentTeam2 >= 1.0 ? 1.0 : membersPercentTeam2,
        backgroundColor: Colors.grey.shade200,
        progressColor: Colors.lightGreenAccent[member['shade'] as int? ?? 100],
        startAngle: 180,
        circularStrokeCap: CircularStrokeCap.butt,
        reverse: true,
      );
    }).toList();

    List<Widget> team1MemberLineIndicators =
        team1Members.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> member = entry.value;

      double elevation = member['total_elevation'] as double? ?? 0.0;
      double memberContributionPercent = elevation / team1TotalElevation;
      memberContributionPercent = memberContributionPercent.clamp(0.0, 1.0);

      int shadeIndex = 100 * (index + 1); // Generate 100, 200, ..., 900
      shadeIndex =
          shadeIndex <= 900 ? shadeIndex : 900; // Cap shadeIndex at 900

      // Ensure a non-null color is always assigned
      Color progressColor =
          Colors.lightBlueAccent[shadeIndex] ?? Colors.blue[400]!;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Row(
          children: [
            Text('${member['fullname']}',
                style: GoogleFonts.syne(textStyle: TextStyle(fontSize: 12))),
            LinearPercentIndicator(
              width: MediaQuery.of(context).size.width * 0.3,
              lineHeight: 6.0,
              percent: memberContributionPercent,
              backgroundColor: Colors.grey.shade200,
              progressColor: progressColor, // Use the computed progress color
            ),
          ],
        ),
      );
    }).toList();

    List<Widget> team2MemberLineIndicators =
        team2Members.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> member = entry.value;

      double elevation = member['total_elevation'] as double? ?? 0.0;
      double memberContributionPercent = elevation / team2TotalElevation;
      memberContributionPercent = memberContributionPercent.clamp(0.0, 1.0);

      int shadeIndex = 100 * (index + 1); // Generate 100, 200, ..., 900
      shadeIndex =
          shadeIndex <= 900 ? shadeIndex : 900; // Cap shadeIndex at 900

      // Ensure a non-null color is always assigned
      Color progressColor =
          Colors.lightGreenAccent[shadeIndex] ?? Colors.lightGreenAccent[400]!;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Row(
          children: [
            Text('${member['fullname']}',
                style: GoogleFonts.syne(textStyle: TextStyle(fontSize: 12))),
            LinearPercentIndicator(
              width: MediaQuery.of(context).size.width * 0.3,
              lineHeight: 6.0,
              percent: memberContributionPercent,
              backgroundColor: Colors.grey.shade200,
              progressColor: progressColor, // Use the computed progress color
            ),
          ],
        ),
      );
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFDFD3C3),
      body: StreamBuilder(
          stream: getCompetitionsData(),
          // Add stream builder here
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasError) {
              return const Text('Something went wrong');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading');
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('${getFormattedCurrentMonth()}',
                    style:
                        GoogleFonts.syne(textStyle: TextStyle(fontSize: 18))),
                const SizedBox(height: 15.0),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Elevation Challenge',
                      style: GoogleFonts.sriracha(
                          textStyle: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold))),
                ),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ...team1Indicators,
                      ...team2Indicators,
                      // The mountain image in the center
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage('assets/images/mtn.png'),
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Team 1',
                            style: GoogleFonts.syne(
                                textStyle: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600))),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ...team1MemberLineIndicators,
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Team 2',
                            style: GoogleFonts.syne(
                                textStyle: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600))),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ...team2MemberLineIndicators,
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          }),
      bottomNavigationBar: BottomAppBar(
        color:
            Colors.white, // This sets the background color of the BottomAppBar
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            // Place your buttons here
            ElevatedButton(
              onPressed: () {
                _showTeamChoiceDialog(context);
              },
              child: const Text('Join a Team'),
            ),
          ],
        ),
      ),
    );
  }
}

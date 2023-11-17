import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class CompetitionPage extends StatefulWidget {
  const CompetitionPage({super.key});

  @override
  State<CompetitionPage> createState() => CompetitionPageState();
}

class CompetitionPageState extends State<CompetitionPage>
    with TickerProviderStateMixin {
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
        'email': currentUser!.email,
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
          title: Center(child: const Text('Choose a team!')),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () async {
                      Map<String, dynamic>? stravaUsername =
                          await getStravaUserDetails();
                      if (stravaUsername != null) {
                        final competitionsCollection = FirebaseFirestore
                            .instance
                            .collection('Competitions');
                        double updatedElevation =
                            (stravaUsername['total_elevation'] as double? ??
                                    0.0) +
                                0.2;

                        // Update the user's total elevation
                        stravaUsername['total_elevation'] = updatedElevation;

                        // Only update the team array
                        await competitionsCollection
                            .doc(getFormattedCurrentMonth())
                            .update({
                          'team_1': FieldValue.arrayUnion([stravaUsername]),
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
                  ElevatedButton(
                    onPressed: () async {
                      Map<String, dynamic>? stravaUsername =
                          await getStravaUserDetails();
                      if (stravaUsername != null) {
                        final competitionsCollection = FirebaseFirestore
                            .instance
                            .collection('Competitions');
                        double updatedElevation =
                            (stravaUsername['total_elevation'] as double? ??
                                    0.0) +
                                0.2;

                        // Update the user's total elevation
                        stravaUsername['total_elevation'] = updatedElevation;

                        // Only update the team array
                        await competitionsCollection
                            .doc(getFormattedCurrentMonth())
                            .update({
                          'team_2': FieldValue.arrayUnion([stravaUsername]),
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

  late final AnimationController _winningAnimationController;
  bool _hasCheckedWinner = false;
  bool hasJoinedTeam = false;

  List<dynamic> team1Members = [];
  List<dynamic> team2Members = [];

  @override
  void initState() {
    super.initState();
    _winningAnimationController = AnimationController(vsync: this);
    getCurrentMonthData().listen((querySnapshot) {
      // Reset total elevations
      double team1TotalElevation = 0.0;
      double team2TotalElevation = 0.0;

      // Process each activity document
      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        double elevationGain = data['elevation_gain'] as double? ?? 0.0;
        String userEmail = data['user_email'];

        // Determine which team the user belongs to and update their elevation
        updateTeamMemberElevation(userEmail, elevationGain);
      }
    });
    // Fetch and set the competition document for the current month
    final competitionDocId = getFormattedCurrentMonth();
    FirebaseFirestore.instance
        .collection('Competitions')
        .doc(competitionDocId)
        .snapshots()
        .listen((docSnapshot) {
      if (docSnapshot.exists) {
        var data = docSnapshot.data();
        List<dynamic> team1 = data?['team_1'] ?? [];
        List<dynamic> team2 = data?['team_2'] ?? [];
        String userEmail = currentUser?.email ?? '';
        setState(() {
          team1Members = List.from(docSnapshot.data()?['team_1'] ?? []);
          team2Members = List.from(docSnapshot.data()?['team_2'] ?? []);
          hasJoinedTeam = team1.any((member) => member['email'] == userEmail) ||
              team2.any((member) => member['email'] == userEmail);
        });
      }
    });
    if (!_hasCheckedWinner) {
      checkForWinner();
      _hasCheckedWinner = true;
    }
  }

  @override
  void dispose() {
    _winningAnimationController.dispose();
    _hasCheckedWinner = false;
    super.dispose();
  }

  void updateTeamMemberElevation(String userEmail, double elevationGain) async {
    final competitionDocId = getFormattedCurrentMonth();
    var competitionDoc = FirebaseFirestore.instance
        .collection('Competitions')
        .doc(competitionDocId);
    var snapshot = await competitionDoc.get();

    if (!snapshot.exists) {
      print('Competition document does not exist');
      return;
    }

    var data = snapshot.data();
    List<dynamic> team1 = data?['team_1'] ?? [];
    List<dynamic> team2 = data?['team_2'] ?? [];

    bool updated = false;
    // Update elevation in team 1
    for (var member in team1) {
      if (member['email'] == userEmail) {
        member['total_elevation'] += elevationGain;
        updated = true;
        break;
      }
    }

    // Update elevation in team 2 if not updated in team 1
    if (!updated) {
      for (var member in team2) {
        if (member['email'] == userEmail) {
          member['total_elevation'] += elevationGain;
          break;
        }
      }
    }

    // Write back the updated data
    await competitionDoc.update({'team_1': team1, 'team_2': team2});
  }

  void checkForWinner() {
    double team1TotalElevation = team1Members.fold(
      0.0,
      (sum, member) => sum + (member['total_elevation'] as double? ?? 0.0),
    );

    double team2TotalElevation = team2Members.fold(
      0.0,
      (sum, member) => sum + (member['total_elevation'] as double? ?? 0.0),
    );

    if (team1TotalElevation >= 5000) {
      playWinningAnimation('Team 1');
    } else if (team2TotalElevation >= 5000) {
      playWinningAnimation('Team 2');
    }
  }

  void playWinningAnimation(String winningTeam) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Lottie.asset(
          'assets/lottie/win_animation.json',
          controller: _winningAnimationController,
          onLoaded: (composition) {
            _winningAnimationController
              ..duration = composition
                  .duration // You can set a longer duration here if needed
              ..repeat(); // Make the animation repeat indefinitely
          },
          repeat: true, // Play animation in a loop
          fit: BoxFit.contain, // Make sure the entire animation is visible
        ),
        title: Center(
          child: Text('$winningTeam Wins!',
              style: GoogleFonts.syne(textStyle: TextStyle(fontSize: 32))),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              _winningAnimationController
                  .stop(); // Stop the animation when the dialog is closed
              Navigator.of(context).pop(); // Closes the dialog
            },
          ),
        ],
      ),
    );
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

// Team 1 cumulative percent calculation
    List<Widget> team1Indicators = team1Members.map((member) {
      double membersPercentTeam1 = team1TotalElevation / 5000;
      return CircularPercentIndicator(
        radius: 180.0,
        lineWidth: 10.0,
        percent: membersPercentTeam1 >= 1.0 ? 1.0 : membersPercentTeam1,
        backgroundColor: Colors.grey.shade200,
        progressColor: Colors.lightBlueAccent[member['shade'] as int? ?? 100],
        startAngle: 180,
        circularStrokeCap: CircularStrokeCap.butt,
        reverse: false,
        animation: true,
        animationDuration: 1500,
        footer: Text(team1TotalElevation.toStringAsFixed(0) + ' m'),
      );
    }).toList();

// Team 2 cumulative percent calculation
    List<Widget> team2Indicators = team2Members.map((member) {
      double membersPercentTeam2 = team2TotalElevation / 5000;
      return CircularPercentIndicator(
        radius: 150.0,
        lineWidth: 10.0,
        percent: membersPercentTeam2 >= 1.0 ? 1.0 : membersPercentTeam2,
        backgroundColor: Colors.grey.shade200,
        progressColor: Colors.lightGreenAccent[member['shade'] as int? ?? 100],
        startAngle: 180,
        circularStrokeCap: CircularStrokeCap.butt,
        reverse: true,
        animation: true,
        animationDuration: 1500,
        footer: Text(team2TotalElevation.toStringAsFixed(0) + ' m'),
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
            Stack(
              children: [
                LinearPercentIndicator(
                  width: MediaQuery.of(context).size.width * 0.3,
                  lineHeight: 10.0,
                  percent: memberContributionPercent,
                  backgroundColor: Colors.grey.shade200,
                  progressColor:
                      progressColor, // Use the computed progress color
                  animation: true,
                  animationDuration: 1500,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.only(left: 4),
                    color: Colors.grey.shade200,
                    child: Text(
                      '${member['total_elevation'].toStringAsFixed(0)} m',
                      style: TextStyle(fontSize: 8),
                    ),
                  ),
                ),
              ],
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
            Stack(
              children: [
                LinearPercentIndicator(
                  width: MediaQuery.of(context).size.width * 0.3,
                  lineHeight: 10.0,
                  percent: memberContributionPercent,
                  backgroundColor: Colors.grey.shade200,
                  progressColor:
                      progressColor, // Use the computed progress color
                  animation: true,
                  animationDuration: 1500,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.only(left: 4),
                    color: Colors.grey.shade200,
                    child: Text(
                      '${member['total_elevation'].toStringAsFixed(0)} m',
                      style: TextStyle(fontSize: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFDFD3C3),
      body: StreamBuilder(
          stream: getCurrentMonthData(),
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

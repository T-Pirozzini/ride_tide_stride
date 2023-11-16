import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

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
        // Ensure that elevation_gain is treated as a double.
        var elevationGain = (data['elevation_gain'] ?? 0).toDouble();
        totalElevation += elevationGain;
      }

      final userData = {
        'fullname': (userActivities.first.data()
                as Map<String, dynamic>)['fullname'] as String? ??
            '',
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
                          'team_1': FieldValue.arrayUnion([stravaUsername])
                        });

                        final snackBar = SnackBar(
                          content: const Text('You joined Team 1'),
                          duration: const Duration(seconds: 1),
                        );
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
                          'team_2': FieldValue.arrayUnion([stravaUsername])
                        });

                        final snackBar = SnackBar(
                          content: const Text('You joined Team 2'),
                          duration: const Duration(seconds: 1),
                        );
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

  Stream<Map<String, double>> getMonthlyElevationStream() {
    // Calculate the first and last day of the current month
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    return FirebaseFirestore.instance
        .collection('activities')
        .where('start_date',
            isGreaterThanOrEqualTo: firstDayOfMonth.toUtc().toIso8601String())
        .where('start_date',
            isLessThanOrEqualTo: lastDayOfMonth.toUtc().toIso8601String())
        .snapshots()
        .map((snapshot) {
      // Aggregate the data
      Map<String, double> elevationGains = {};
      for (var doc in snapshot.docs) {
        var data = doc.data();
        var fullname = data['fullname'];
        var elevationGain = data['elevation_gain'] ?? 0.0;
        elevationGains.update(fullname, (value) => value + elevationGain,
            ifAbsent: () => elevationGain);
      }
      return elevationGains;
    });
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

    getMonthlyElevationStream().listen((elevationGains) {
      // Use the elevation gains to update the Competitions collection
      var competitionDocId = getFormattedCurrentMonth();
      FirebaseFirestore.instance
          .collection('Competitions')
          .doc(competitionDocId)
          .update({
        'team_1_elevation': elevationGains['Team 1'] ?? 0,
        'team_2_elevation': elevationGains['Team 2'] ?? 0,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // List<dynamic> team1Members = [
    //   {'name': 'John', 'elevation': 2500.0, 'shade': 200},
    //   {'name': 'Jane', 'elevation': 500.0, 'shade': 400},
    //   {'name': 'Joe', 'elevation': 500.0, 'shade': 800},
    // ];

    // List<dynamic> team2Members = [
    //   {'name': 'Jim', 'elevation': 2000.0, 'shade': 400},
    //   {'name': 'George', 'elevation': 2000.0, 'shade': 600},
    //   {'name': 'Sarah', 'elevation': 500.0, 'shade': 200},
    // ];

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
        radius: 175.0,
        lineWidth: 10.0,
        percent: membersPercentTeam1 >= 1.0 ? 1.0 : membersPercentTeam1,
        backgroundColor: Colors.grey.shade200,
        progressColor: Colors.blue[member['shade'] as int? ?? 200],
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
        progressColor: Colors.red[member['shade'] as int? ?? 200],
        startAngle: 180,
        circularStrokeCap: CircularStrokeCap.butt,
        reverse: true,
      );
    }).toList();

    List<Widget> team1MemberLineIndicators = team1Members.map((member) {
      // Safe casting with a default value
      double elevation = member['total_elevation'] as double? ?? 0.0;

      double memberContributionPercent = elevation / team1TotalElevation;
      // Ensuring the percent is within the range of 0.0 to 1.0
      memberContributionPercent = memberContributionPercent.clamp(0.0, 1.0);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Row(
          children: [
            Text('${member['fullname']}'),
            LinearPercentIndicator(
              width: MediaQuery.of(context).size.width * 0.3,
              lineHeight: 6.0,
              percent: memberContributionPercent,
              backgroundColor: Colors.grey.shade200,
              progressColor: Colors.blue[(member['shade'] as int? ?? 200)],
            ),
          ],
        ),
      );
    }).toList();

    Stream<List<Map<String, dynamic>>> getTeamMemberElevations() {
      // Calculate the first and last day of the current month
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

      return FirebaseFirestore.instance
          .collection('activities')
          .where('start_date',
              isGreaterThanOrEqualTo: firstDayOfMonth.toUtc().toIso8601String())
          .where('start_date',
              isLessThanOrEqualTo: lastDayOfMonth.toUtc().toIso8601String())
          .snapshots()
          .map((snapshot) {
        // Aggregate the data for each team member
        Map<String, Map<String, dynamic>> aggregatedData = {};
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final fullname = data['fullname'] as String;
          final elevationGain = data['elevation_gain'] as double? ?? 0.0;

          if (!aggregatedData.containsKey(fullname)) {
            aggregatedData[fullname] = {
              'fullname': fullname,
              'elevation_gain': 0.0,
            };
          }

          aggregatedData[fullname]!['elevation_gain'] += elevationGain;
        }

        // Convert to a list of maps for easier use in the UI
        return aggregatedData.values.toList();
      });
    }

    return Scaffold(
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

            final competitionDocs = snapshot.data.docs;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('${getFormattedCurrentMonth()}'),
                const SizedBox(height: 20.0),
                Text('Elevation Challenge'),
                const SizedBox(height: 20.0),
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
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Team 1'),
                        ...team1MemberLineIndicators,
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Team 2'),
                        ...team1MemberLineIndicators,
                      ],
                    ),
                  ],
                ),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: getTeamMemberElevations(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Text('No data found for the current month.');
                      }

                      List<Widget> memberWidgets =
                          snapshot.data!.map((memberData) {
                        return Text(
                            '${memberData['fullname']}: ${memberData['elevation_gain'].toInt()}m');
                      }).toList();

                      return ListView(
                        children: memberWidgets,
                      );
                    },
                  ),
                ),
              ],
            );
          }),
      persistentFooterButtons: [
        ElevatedButton(
          onPressed: () {
            _showTeamChoiceDialog(context);
          },
          child: const Text('Join a Team'),
        ),
      ],
    );
  }
}
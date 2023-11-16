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

  Future<String?> getStravaUsername() async {
    if (currentUser?.email == null) {
      return null;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('activities')
          .where('user_email', isEqualTo: currentUser!.email)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print(
            'No documents found for the user with email: ${currentUser!.email}');
        return null;
      }

      final firstDocData = querySnapshot.docs.first.data();

      final stravaFullName = firstDocData['fullname'] as String?;

      return stravaFullName;
    } catch (e) {
      print('Error getting username: $e');
      return null;
    }
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
                      String? stravaUsername = await getStravaUsername();
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
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Add logic to handle team selection here
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

  @override
  Widget build(BuildContext context) {
    List<dynamic> team1Members = [
      {'name': 'John', 'elevation': 1500.0, 'shade': 600},
      {'name': 'Jane', 'elevation': 500.0, 'shade': 400},
      {'name': 'Joe', 'elevation': 2000.0, 'shade': 600},
    ];

    List<dynamic> team2Members = [
      {'name': 'Jim', 'elevation': 2000.0, 'shade': 400},
      {'name': 'George', 'elevation': 2000.0, 'shade': 600},
      {'name': 'Sarah', 'elevation': 500.0, 'shade': 200},
    ];

    // Calculate the total elevation for each team
    double team1TotalElevation = team1Members.fold(
        0.0, (sum, member) => sum + (member['elevation'] as double));
    double team2TotalElevation = team2Members.fold(
        0.0, (sum, member) => sum + (member['elevation'] as double));

// Team 1 cumulative percent calculation
    List<Widget> team1Indicators = team1Members.map((member) {
      double membersPercentTeam1 = team1TotalElevation / 5000;
      print(membersPercentTeam1);
      print(team1TotalElevation);

      return CircularPercentIndicator(
        radius: 175.0,
        lineWidth: 10.0,
        percent: membersPercentTeam1 >= 1.0 ? 1.0 : membersPercentTeam1,
        backgroundColor: Colors.grey.shade200,
        progressColor: Colors.blue[(member['shade'] as int)],
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
        progressColor: Colors.red[(member['shade'] as int)],
        startAngle: 180,
        circularStrokeCap: CircularStrokeCap.butt,
        reverse: true,
      );
    }).toList();

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
                Column(
                  children: <Widget>[
                    Text('Team 1: ${competitionDocs[0]['team_1']}'),
                    Text('Team 2: ${competitionDocs[0]['team_2']}'),
                  ],
                ),
                Text('formattedCurrentMonth: ${getFormattedCurrentMonth()}'),
                Text('Team 1: ${competitionDocs[0]['team_1']}'),
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

            // Iterate through activity documents and aggregate data for the given title
            for (final doc in competitionDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final date = data['start_date'] as String;
              final team1 = data['start_date'] as String;

              return Column(
                children: <Widget>[
                  const Text('Competition Page'),
                  Text('Date: $date'),
                  Text('Team: ${snapshot.data}'),
                  Text('${competitionDocs[0]['start_date']}'),
                  Text('${competitionDocs[0]['team_1']}'),
                  Text('formattedCurrentMonth: ${getFormattedCurrentMonth()}'),
                ],
              );
            }
            return const Text('No data found');
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

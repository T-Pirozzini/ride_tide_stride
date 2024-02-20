import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_tide_stride/components/competition_dialog.dart';
import 'package:ride_tide_stride/components/competition_learn_more.dart';
import 'package:ride_tide_stride/pages/snow_2_surf_page.dart';
import 'package:ride_tide_stride/pages/team_traverse_page.dart';

class CompetitionLobbyPage extends StatefulWidget {
  const CompetitionLobbyPage({super.key});

  @override
  State<CompetitionLobbyPage> createState() => _CompetitionLobbyPageState();
}

class _CompetitionLobbyPageState extends State<CompetitionLobbyPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool hasJoinedChallenge(List participants) {
    String? currentUserEmail = _auth.currentUser?.email;
    return participants.contains(currentUserEmail);
  }

// Method to join a challenge
  Future<void> joinChallenge(String challengeId) async {
    String? currentUserEmail = _auth.currentUser?.email;
    if (currentUserEmail == null) return;

    // Reference to the challenge document
    DocumentReference challengeRef =
        FirebaseFirestore.instance.collection('Challenges').doc(challengeId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(challengeRef);
      if (!snapshot.exists) {
        throw Exception("Challenge does not exist!");
      }

      List participants = List.from(snapshot['participants'] ?? []);
      if (!participants.contains(currentUserEmail)) {
        participants.add(currentUserEmail);
        transaction.update(challengeRef, {'participants': participants});
      }
    }).catchError((error) {
      print("Failed to join challenge: $error");
    });
  }

  // add a new competition
  void addCompetition() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddCompetitionDialog(); // Show the custom dialog
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'The Challenge Hub',
                  style: GoogleFonts.tektur(
                      textStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.2)),
                ),
                centerTitle: true,
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Join a challenge or create your own!',
                      style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.2)),
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Challenges')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                      child: Text('Error: ${snapshot.error}'));
                }

                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()));
                  default:
                    // Extract data from snapshot
                    final challenges = snapshot.data!.docs;

                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          var challengeData =
                              challenges[index].data() as Map<String, dynamic>;
                          String challengeId = challenges[index].id;
                          List participants =
                              challengeData['participants'] ?? [];
                          String? currentUserEmail = _auth.currentUser?.email;
                          // Determine if the current user has joined this challenge
                          bool hasJoined =
                              participants.contains(currentUserEmail);

                          String challengeName =
                              challengeData['name'] ?? 'Unnamed Challenge';
                          String challengeImage = challengeData['currentMap'];
                          bool isVisible = challengeData['isVisible'];
                          bool isPublic = challengeData['isPublic'];
                          String description =
                              challengeData['description'] ?? 'No description';

                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                if (hasJoined) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) {
                                      // Determine which page to navigate to based on the challenge type
                                      switch (challengeData['type']) {
                                        case 'Snow2Surf':
                                          return Snow2Surf(
                                              challengeId: challengeId);
                                        case 'Mtn Scramble':
                                          return Snow2Surf(
                                              challengeId: challengeId);
                                        case 'Team Traverse':
                                          return TeamTraversePage(
                                            challengeId: challengeId,
                                            participantsEmails: participants,
                                            startDate: challengeData['timestamp'],
                                            challengeName: challengeName,
                                            challengeType: challengeData['type'],
                                            mapDistance: challengeData['mapDistance'],

                                          );
                                        default:
                                          // Handle unknown challenge type if necessary
                                          return Snow2Surf(
                                              challengeId: challengeId);
                                      }
                                    }),
                                  );
                                } else {
                                  // Show the learn more dialog if not joined
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return CompetitionLearnMore(
                                        challengeName: challengeName,
                                        challengeImage: challengeImage,
                                        isPublic: isPublic,
                                        isVisible: isVisible,
                                        description: description,
                                      );
                                    },
                                  );
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Expanded(
                                    child: Image.asset(
                                      challengeImage,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  ListTile(
                                    title: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: Text(
                                          challengeName,
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    subtitle: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        isPublic
                                            ? Icon(Icons.lock_open)
                                            : Icon(Icons.lock),
                                        isVisible
                                            ? Icon(Icons.visibility)
                                            : Icon(Icons.visibility_off),
                                        Row(
                                          children: [
                                            Icon(Icons.person),
                                            Text('0'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      hasJoined
                                          ? 'Tap to view'
                                          : 'Tap to learn more',
                                      style: TextStyle(
                                          color: hasJoined
                                              ? Colors.blueAccent
                                              : Colors.grey,
                                          fontSize: hasJoined ? 14 : 12,
                                          fontStyle: hasJoined
                                              ? FontStyle.normal
                                              : FontStyle.italic),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ElevatedButton(
                                      onPressed: hasJoined
                                          ? null
                                          : () => joinChallenge(challengeId),
                                      child: Text(hasJoined
                                          ? 'Challenge Active'
                                          : 'Join'),
                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty
                                            .resolveWith<Color>(
                                          (Set<MaterialState> states) {
                                            if (states.contains(
                                                MaterialState.disabled))
                                              return Colors.grey;
                                            return Theme.of(context)
                                                .primaryColor; // Use the default button color
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: challenges.length,
                      ),
                    );
                }
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: addCompetition,
          child: Icon(Icons.add),
        ));
  }
}

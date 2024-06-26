import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_tide_stride/screens/challenges/chaos_circuit/chaos_circuit.dart';
import 'package:ride_tide_stride/screens/challenges/create_challenge/competition_dialog.dart';
import 'package:ride_tide_stride/screens/challenges/competition_learn_more.dart';
import 'package:ride_tide_stride/screens/challenges/passwordDialog.dart';
import 'package:ride_tide_stride/screens/challenges/mtn_scramble/mtn_scramble_page.dart';
import 'package:ride_tide_stride/screens/challenges/snow2surf/snow_2_surf_page.dart';
import 'package:ride_tide_stride/screens/challenges/team_traverse/team_traverse_page.dart';
import 'package:ride_tide_stride/theme.dart';

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
  Future<void> joinChallenge(
      String challengeId, String challengePassword, String coopOrComp) async {
    String? currentUserEmail = _auth.currentUser?.email;
    if (currentUserEmail == null) return;

    // If a password is required, prompt the user
    if (challengePassword.isNotEmpty) {
      // Show password dialog and wait for the result
      bool isPasswordCorrect = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return PasswordDialog(challengePassword: challengePassword);
            },
          ) ??
          false;

      // If the password is incorrect, stop the process
      if (!isPasswordCorrect) {
        print("Incorrect password");
        return;
      }
    }

    // Reference to the challenge document
    DocumentReference challengeRef =
        FirebaseFirestore.instance.collection('Challenges').doc(challengeId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(challengeRef);
      if (!snapshot.exists) {
        throw Exception("Challenge does not exist!");
      }

      List participants = List.from(snapshot['participants'] ?? []);
      // Check if the challenge is already full
      if (snapshot['type'] == 'Chaos Circuit' && participants.length >= 4) {
        print("Challenge is full");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sorry, the challenge is currently full.'),
        ));
        // Optionally, show a dialog or a snackbar to inform the user
        return;
      }
      if (participants.length >= 8) {
        print("Challenge is full");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sorry, the challenge is currently full.'),
        ));
        // Optionally, show a dialog or a snackbar to inform the user
        return;
      }
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
        backgroundColor: const Color(0xFFDFD3C3),
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
                // centerTitle: true,
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
                  .where(
                    'active',
                    isEqualTo: true,
                  )
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
                          String challengeCoopOrComp =
                              challengeData['coopOrComp'];
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
                          String challengeType = challengeData['type'];
                          String challengeDifficulty =
                              challengeData['difficulty'] ?? 'No difficulty';
                          String challengeCategory =
                              challengeData['category'] ?? 'No category';
                          String challengePassword = challengeData['password'];
                          String challengeUserDescription =
                              challengeData['userDescription'] ?? '';

                          void navigateToChallengeDetail(
                              String challengeType, String challengeId) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  switch (challengeData['type']) {
                                    case 'Snow2Surf':
                                      return Snow2Surf(
                                          challengeId: challengeId,
                                          participantsEmails: participants,
                                          startDate: challengeData['timestamp'],
                                          challengeName: challengeName,
                                          challengeType: challengeData['type'],
                                          challengeDifficulty:
                                              challengeData['difficulty'] ??
                                                  'No difficulty',
                                          challengeLegs:
                                              challengeData['legsSelected']);
                                    case 'Mtn Scramble':
                                      return MtnScramblePage(
                                        challengeId: challengeId,
                                        participantsEmails: participants,
                                        startDate: challengeData['timestamp'],
                                        challengeName: challengeName,
                                        challengeType: challengeData['type'],
                                        mapElevation:
                                            challengeData['mapElevation'],
                                        challengeCategory:
                                            challengeData['category'],
                                        challengeActivity:
                                            challengeData['categoryActivity'] ??
                                                'No activity',
                                        challengeCreator:
                                            challengeData['userEmail'] ??
                                                'No creator',
                                        coopOrComp:
                                            challengeData['coopOrComp'] ??
                                                'No coopOrComp',
                                      );
                                    case 'Team Traverse':
                                      return TeamTraversePage(
                                        challengeId: challengeId,
                                        participantsEmails: participants,
                                        startDate: challengeData['timestamp'],
                                        challengeName: challengeName,
                                        challengeType: challengeData['type'],
                                        mapDistance:
                                            challengeData['mapDistance'],
                                        challengeCategory:
                                            challengeData['category'],
                                        challengeActivity:
                                            challengeData['categoryActivity'] ??
                                                'No activity',
                                        challengeCreator:
                                            challengeData['userEmail'] ??
                                                'No creator',
                                        coopOrComp:
                                            challengeData['coopOrComp'] ??
                                                'No coopOrComp',
                                      );
                                    case 'Snow2Surf':
                                      return Snow2Surf(
                                        challengeId: challengeId,
                                        participantsEmails: participants,
                                        startDate: challengeData['timestamp'],
                                        challengeName: challengeName,
                                        challengeType: challengeData['type'],
                                        challengeDifficulty:
                                            challengeData['difficulty'] ??
                                                'No difficulty',
                                        challengeLegs:
                                            challengeData['legsSelected'],
                                      );
                                    default:
                                      // Handle unknown challenge type if necessary
                                      return ChaosCircuit(
                                        challengeId: challengeId,
                                      );
                                  }
                                },
                              ),
                            );
                          }

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
                                            challengeId: challengeId,
                                            participantsEmails: participants,
                                            startDate:
                                                challengeData['timestamp'],
                                            challengeName: challengeName,
                                            challengeType:
                                                challengeData['type'],
                                            challengeDifficulty:
                                                challengeData['difficulty'] ??
                                                    'No difficulty',
                                            challengeLegs:
                                                challengeData['legsSelected'],
                                          );
                                        case 'Mtn Scramble':
                                          return MtnScramblePage(
                                            challengeId: challengeId,
                                            participantsEmails: participants,
                                            startDate:
                                                challengeData['timestamp'],
                                            challengeName: challengeName,
                                            challengeType:
                                                challengeData['type'],
                                            mapElevation:
                                                challengeData['mapElevation'],
                                            challengeCategory:
                                                challengeData['category'],
                                            challengeActivity: challengeData[
                                                    'categoryActivity'] ??
                                                'No activity',
                                            challengeCreator:
                                                challengeData['userEmail'] ??
                                                    'No creator',
                                            coopOrComp:
                                                challengeData['coopOrComp'] ??
                                                    'No coopOrComp',
                                          );
                                        case 'Team Traverse':
                                          return TeamTraversePage(
                                            challengeId: challengeId,
                                            participantsEmails: participants,
                                            startDate:
                                                challengeData['timestamp'],
                                            challengeName: challengeName,
                                            challengeType:
                                                challengeData['type'],
                                            mapDistance:
                                                challengeData['mapDistance'],
                                            challengeCategory:
                                                challengeData['category'],
                                            challengeActivity: challengeData[
                                                    'categoryActivity'] ??
                                                'No activity',
                                            challengeCreator:
                                                challengeData['userEmail'] ??
                                                    'No creator',
                                            coopOrComp:
                                                challengeData['coopOrComp'] ??
                                                    'No coopOrComp',
                                          );
                                        case 'Snow2Surf':
                                          return Snow2Surf(
                                            challengeId: challengeId,
                                            participantsEmails: participants,
                                            startDate:
                                                challengeData['timestamp'],
                                            challengeName: challengeName,
                                            challengeType:
                                                challengeData['type'],
                                            challengeDifficulty:
                                                challengeData['difficulty'] ??
                                                    'No difficulty',
                                            challengeLegs:
                                                challengeData['legsSelected'],
                                          );
                                        default:
                                          // Handle unknown challenge type if necessary
                                          return ChaosCircuit(
                                            challengeId: challengeId,
                                          );
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
                                        onSpectate: () =>
                                            navigateToChallengeDetail(
                                                challengeType, challengeId),
                                      );
                                    },
                                  );
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 18.0),
                                          child: Center(
                                            child: Image.asset(
                                              challengeImage,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4.0, vertical: 2.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                challengeDifficulty,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 4.0),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryColor,
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                                child: Text(
                                                  challengeCoopOrComp,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ListTile(
                                    title: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Center(
                                        child: Text(
                                          challengeName,
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 4.0),
                                          child: Center(
                                            child: Text(
                                              challengeUserDescription,
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontStyle: FontStyle.italic),
                                            ),
                                          ),
                                        ),
                                        Row(
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
                                                Text(participants.length
                                                    .toString()),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      hasJoined
                                          ? 'Active Challenge'
                                          : 'Tap to learn more',
                                      style: TextStyle(
                                          color: hasJoined
                                              ? AppColors.primaryColor
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
                                          : () => joinChallenge(
                                              challengeId,
                                              challengePassword,
                                              challengeCoopOrComp),
                                      child: Text(
                                        hasJoined ? 'Tap to View' : 'Join',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty
                                            .resolveWith<Color>(
                                          (Set<MaterialState> states) {
                                            if (states.contains(
                                                MaterialState.disabled))
                                              return AppColors.primaryAccent;
                                            return AppColors
                                                .secondaryAccent; // Use the default button color
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
        bottomNavigationBar: BottomAppBar(
          color: Colors
              .white, // This sets the background color of the BottomAppBar
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/challengeResultsPage');
                },
                child: const Text('View Past Challenge Results'),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: addCompetition,
          child: Icon(Icons.add),
          heroTag: null,
        ));
  }
}

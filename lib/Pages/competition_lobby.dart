import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_tide_stride/components/competition_dialog.dart';
import 'package:ride_tide_stride/components/competition_learn_more.dart';

class CompetitionLobbyPage extends StatefulWidget {
  const CompetitionLobbyPage({super.key});

  @override
  State<CompetitionLobbyPage> createState() => _CompetitionLobbyPageState();
}

class _CompetitionLobbyPageState extends State<CompetitionLobbyPage> {
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
                                      'Tap to learn more',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Join challenge logic here
                                      },
                                      child: Text('Join'),
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

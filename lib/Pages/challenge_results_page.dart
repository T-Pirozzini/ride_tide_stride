import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ride_tide_stride/helpers/helper_functions.dart';

class ChallengeResultsPage extends StatefulWidget {
  const ChallengeResultsPage({super.key});

  @override
  State<ChallengeResultsPage> createState() => _ChallengeResultsPageState();
}

class _ChallengeResultsPageState extends State<ChallengeResultsPage> {
  late Future<List<QueryDocumentSnapshot>> challengeResults;

  @override
  void initState() {
    super.initState();
    challengeResults = getChallengeResults();
  }

  Future<List<QueryDocumentSnapshot>> getChallengeResults() async {
    // get the challenge results
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('Challenges').get();

    // convert to a list for sorting
    List<QueryDocumentSnapshot> challengeDocs = querySnapshot.docs;

    // sort the documents by the timestamp field
    challengeDocs.sort((b, a) {
      Timestamp aTimestamp = a['timestamp'];
      Timestamp bTimestamp = b['timestamp'];
      return aTimestamp.compareTo(bTimestamp);
    });

    // return challenge documents
    return challengeDocs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFD3C3),
      appBar: AppBar(
        title: Text('Challenge Results'),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: challengeResults,
        builder: (context, snapshot) {
          // check for errors
          if (snapshot.hasError) {
            return Center(child: Text('Error: $snapshot.error'));
          }

          // show a loading spinner while waiting for challenge data
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // display the challenge data
          var challenges = snapshot.data!;

          return ListView.builder(
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              // convert snapshot to a Map
              var challenge = challenges[index].data() as Map<String, dynamic>;

              String challengeName = challenge['name'];
              bool isActive = challenge['active'] ?? false;
              bool isSuccess = challenge['success'] ?? false;
              String challengeImage = challenge['currentMap'];
              Timestamp timestamp = challenge['timestamp'];
              DateTime myDateTime = timestamp.toDate();
              String formattedDate =
                  DateFormat('MMM d, yyyy').format(myDateTime);
              String mapName = challenge['mapName'] ?? challenge['type'];
              String mapType = challenge['type'];
              String mapSpecs = mapType == 'Team Traverse'
                  ? '${challenge['mapDistance']}'
                  : mapType == 'Mtn Scramble'
                      ? '${challenge['mapElevation']} m'
                      : challenge['difficulty'];

              // Determine background color based on challenge status
              Color backgroundColor;
              if (isSuccess) {
                backgroundColor = Color(0xBB283D3B); // Success color
              } else if (isActive) {
                backgroundColor = Colors.white;
                // Active (pending) color
              } else {
                backgroundColor = Color(0xBBF45B69); // Failed or inactive color
              }

              return Padding(
                padding: const EdgeInsets.all(2.0),
                child: Card(
                  color: backgroundColor,
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Start Date: $formattedDate',
                              textAlign: TextAlign.center,
                            ),
                            isSuccess
                                ? FittedBox(
                                    child: Text(
                                      'Success!',
                                      style: GoogleFonts.luckiestGuy(
                                        textStyle: TextStyle(
                                          letterSpacing: 4,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                : isActive
                                    ? FittedBox(
                                        child: Text(
                                          'Pending. . .',
                                          style: GoogleFonts.luckiestGuy(
                                            textStyle: TextStyle(
                                              letterSpacing: 2,
                                              fontSize: 12,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      )
                                    : FittedBox(
                                        child: Text(
                                          'Failed',
                                          style: GoogleFonts.luckiestGuy(
                                            textStyle: TextStyle(
                                              letterSpacing: 4,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                          ],
                        ),
                      ),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(challengeImage,
                              height: 80, width: 80, fit: BoxFit.cover),
                        ),
                        title: Text(
                          challengeName,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '$mapName',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          '$mapSpecs',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          challengeResultsDialog(context, challenge);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void challengeResultsDialog(
      BuildContext context, Map<String, dynamic> challenge) {
    List participants = challenge['participants'];
    List<Future<String>> usernameFutures = participants
        .map((participant) => getUserNameString(participant))
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text(challenge['name'])),
          content: FutureBuilder<List<String>>(
            future: Future.wait(usernameFutures),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                // Show loading state while waiting for usernames
                return CircularProgressIndicator();
              }
              // Data is loaded
              List<String> participantUsernames = snapshot.data ?? [];
              return Stack(
                children: [
                  Opacity(
                      opacity: .5,
                      child: Image.asset(challenge['currentMap'],
                          fit: BoxFit.fill)),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${challenge['userDescription']}'),
                      Text('Challenge: ${challenge['type']}'),
                      // Display each username in its own Text widget
                      if (participantUsernames.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Center(child: Text('Participants:')),
                        ),
                      ...participantUsernames
                          .map((username) => Card(
                                color: Colors.black54,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      username,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      'distance',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

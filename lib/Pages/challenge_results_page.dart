import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
                child: Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(challengeImage,
                          height: 50, width: 50, fit: BoxFit.cover),
                    ),
                    title: Text(challengeName),
                    subtitle: FittedBox(
                        child: Text('$mapName - $mapSpecs - $formattedDate')),
                    trailing: isSuccess
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
                    onTap: () {
                      challengeResultsDialog(context, challenge);
                    },
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(challenge['name']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${challenge['type']}'),
              Text('Map: ${challenge['mapName']}'),
              Text('Distance: ${challenge['mapDistance']}'),
              Text('Elevation: ${challenge['mapElevation']}'),
              Text('Difficulty: ${challenge['difficulty']}'),
              Text('Success: ${challenge['success']}'),
              Text('Active: ${challenge['active']}'),
              Text('Timestamp: ${challenge['timestamp']}'),
            ],
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

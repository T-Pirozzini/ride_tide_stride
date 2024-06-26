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
  bool showTopFinishes = true;

  @override
  void initState() {
    super.initState();
    updateChallengePoints();
    challengeResults = getChallengeResults();
  }

  Future<void> updateChallengePoints() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('Challenges').get();

    for (var doc in querySnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      Timestamp? endDate = data['endDate'];
      Timestamp startDate = data['timestamp'];
      String difficulty = data['difficulty'];
      List participants = data['participants'];
      bool success = data['success'] ?? false;

      double points = 0;
      if (endDate != null && success) {
        int daysTaken = endDate.toDate().difference(startDate.toDate()).inDays;
        double timeMultiplier = getTimeMultiplier(daysTaken);
        double participantDeduction =
            getParticipantDeduction(participants.length);
        points =
            getBasePoints(difficulty) * timeMultiplier * participantDeduction;
      }

      // Update the document with calculated points
      await FirebaseFirestore.instance
          .collection('Challenges')
          .doc(doc.id)
          .update({'calculatedPoints': points});
    }
  }

  Future<List<QueryDocumentSnapshot>> getChallengeResults() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('Challenges').get();
    List<QueryDocumentSnapshot> challengeDocs = querySnapshot.docs;

    if (showTopFinishes) {
      challengeDocs.sort((a, b) {
        double aPoints =
            (a.data() as Map<String, dynamic>)['calculatedPoints'] as double? ??
                0.0;
        double bPoints =
            (b.data() as Map<String, dynamic>)['calculatedPoints'] as double? ??
                0.0;
        return bPoints.compareTo(aPoints);
      });
      // Print to confirm the order after sorting
      challengeDocs.forEach((doc) {
        print((doc.data() as Map<String, dynamic>)['calculatedPoints']);
      });
    } else {
      // Sort by timestamp in ascending order for the most recently started
      challengeDocs.sort((a, b) {
        Timestamp aTimestamp =
            (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
        Timestamp bTimestamp =
            (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
        return aTimestamp.compareTo(bTimestamp);
      });
    }

    return challengeDocs;
  }

  int getBasePoints(String difficulty) {
    switch (difficulty) {
      case 'Intro':
        return 100;
      case 'Advanced':
        return 200;
      case 'Expert':
        return 300;
      default:
        return 0;
    }
  }

  double getTimeMultiplier(int daysTaken) {
    if (daysTaken <= 5) return 1.0;
    if (daysTaken <= 10) return 0.9;
    if (daysTaken <= 15) return 0.8;
    if (daysTaken <= 20) return 0.7;
    if (daysTaken <= 25) return 0.6;
    if (daysTaken <= 30) return 0.5;
    return 0.7; // If more than 30 days are taken
  }

  double getParticipantDeduction(int numParticipants) {
    return numParticipants > 1
        ? 0.95
        : 1.0; // 5% reduction per extra participant
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFD3C3),
      appBar: AppBar(
        title: Text(
          'Challenge Results',
          style: GoogleFonts.tektur(
              textStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.2)),
        ),
      ),
      bottomSheet: GestureDetector(
        onTap: () => showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Center(
              child: Text('Points Breakdown',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Base Points:',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            'Intro (100), Advanced (200), Expert (300)',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      )),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.timer, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Time Multiplyer:',
                              style: Theme.of(context).textTheme.headlineSmall),
                          Text(
                            'Points are reduced based on how many days it took to complete the challenge.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      )),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.group, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Participant Deduction:',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            'Total points are reduced by 5% per additional participant.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      )),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
                style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
              ),
            ],
          ),
        ),
        child: Container(
          color: Color(0xFF283D3B),
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white,
              ),
              SizedBox(width: 4),
              Text(
                'Click here for points breakdown.',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
        child: Column(
          children: [
            SwitchListTile(
              tileColor: Colors.white,
              title: Text(
                !showTopFinishes ? 'All Challenges' : 'Top Finishes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                !showTopFinishes
                    ? 'Show all challenges, including those in progress'
                    : 'Show only completed challenges, sorted by points',
                style: TextStyle(fontSize: 12),
              ),
              activeThumbImage: AssetImage('assets/images/trophy.png'),
              inactiveThumbImage: AssetImage('assets/images/all.png'),
              value: showTopFinishes,
              onChanged: (bool value) {
                setState(() {
                  showTopFinishes = value;
                  challengeResults =
                      getChallengeResults(); // Re-fetch with new sort order
                });
              },
            ),
            Expanded(
              child: FutureBuilder<List<QueryDocumentSnapshot>>(
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
                  if (showTopFinishes) {
                    // Filter and sort for top finishes
                    challenges = challenges.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return !(data['active'] as bool? ??
                          false); // Use '??' to provide a default value if null
                    }).toList();
                    challenges.sort((a, b) {
                      var dataA = a.data() as Map<String, dynamic>;
                      var dataB = b.data() as Map<String, dynamic>;
                      var aPoints = dataA['calculatedPoints'] as double? ?? 0;
                      var bPoints = dataB['calculatedPoints'] as double? ?? 0;
                      return aPoints.compareTo(bPoints);
                    });
                  }
                  challenges = challenges.reversed.toList();

                  return ListView.builder(
                    itemCount: challenges.length,
                    itemBuilder: (context, index) {
                      // convert snapshot to a Map
                      var challenge =
                          challenges[index].data() as Map<String, dynamic>;

                      String challengeName = challenge['name'];
                      bool isActive = challenge['active'] ?? false;
                      bool isSuccess = challenge['success'] ?? false;
                      String challengeImage = challenge['currentMap'];
                      Timestamp timestamp = challenge['timestamp'];
                      Timestamp? endDate = challenge['endDate'];
                      List participants = challenge['participants'];
                      String difficulty = challenge['difficulty'];

                      // Convert Timestamp to DateTime and formatting
                      DateTime startDate = timestamp.toDate();
                      String formattedStartDate =
                          DateFormat('MMM d, yyyy').format(startDate);
                      String formattedEndDate = endDate != null
                          ? DateFormat('MMM d, yyyy').format(endDate.toDate())
                          : 'In Progress';
                      String daysTakenText = endDate != null
                          ? '${endDate.toDate().difference(startDate).inDays} days'
                          : 'In Progress';

                      // Points calculation
                      double points = 0;
                      if (endDate != null) {
                        int daysTaken =
                            endDate.toDate().difference(startDate).inDays;
                        double timeMultiplier = getTimeMultiplier(daysTaken);
                        double participantDeduction =
                            getParticipantDeduction(participants.length);
                        points = getBasePoints(difficulty) *
                            timeMultiplier *
                            participantDeduction;
                      }

                      String mapName =
                          challenge['mapName'] ?? challenge['type'];
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
                        backgroundColor = Colors.grey[300]!;
                        // Active (pending) color
                      } else {
                        backgroundColor =
                            Color(0xBBF45B69); // Failed or inactive color
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0, vertical: 2.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Start Date:',
                                          style: !isActive
                                              ? TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white)
                                              : TextStyle(color: Colors.black),
                                        ),
                                        SizedBox(width: 5),
                                        Text('$formattedStartDate',
                                            textAlign: TextAlign.center,
                                            style: !isActive
                                                ? TextStyle(color: Colors.white)
                                                : TextStyle(
                                                    color: Colors.black)),
                                      ],
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
                                                  style:
                                                      GoogleFonts.luckiestGuy(
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
                                                  style:
                                                      GoogleFonts.luckiestGuy(
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
                                dense: true,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                leading: Column(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.asset(challengeImage,
                                            fit: BoxFit.cover),
                                      ),
                                    ),
                                    Text(
                                      '$mapSpecs',
                                      style: !isActive
                                          ? TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)
                                          : TextStyle(color: Colors.black),
                                    )
                                  ],
                                ),
                                title: Text(
                                  challengeName,
                                  style: !isActive
                                      ? TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)
                                      : TextStyle(color: Colors.black),
                                ),
                                subtitle: Row(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_month_outlined),
                                        Text(daysTakenText,
                                            textAlign: TextAlign.center),
                                      ],
                                    ),
                                    SizedBox(width: 5),
                                    Row(
                                      children: [
                                        Icon(Icons.person_outlined),
                                        Text(participants.length.toString()),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                    isSuccess
                                        ? '${points.toStringAsFixed(0)} pts'
                                        : isActive
                                            ? 'In Progress'
                                            : '0 pts',
                                    style: isSuccess || !isActive
                                        ? GoogleFonts.tektur(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.tealAccent,
                                            fontSize: 18)
                                        : GoogleFonts.tektur(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            fontSize: 18)),
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
            ),
          ],
        ),
      ),
    );
  }

  void challengeResultsDialog(
      BuildContext context, Map<String, dynamic> challenge) {
    List participants = challenge['participants'];
    List<Future<Map<String, dynamic>>> usernameFutures =
        participants.map((email) async {
      // Assuming getUserNameString returns a Future of the username given an email
      String username = await getUserNameString(email);
      double result = challenge['participantProgress'][email] ?? 0;
      return {'username': username, 'participantResult': result};
    }).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text(challenge['name'])),
          content: FutureBuilder<List<Map<String, dynamic>>>(
            future: Future.wait(usernameFutures),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return CircularProgressIndicator();
              }
              // Data is loaded
              List<Map<String, dynamic>> participantData = snapshot.data ?? [];
              return Stack(
                children: [
                  Opacity(
                      opacity: .5,
                      child: Image.asset(challenge['currentMap'],
                          fit: BoxFit.fill)),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Color(0xFF283D3B).withOpacity(0.6),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${challenge['userDescription']}',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.white),
                            ),
                            Text(
                              'Challenge: ${challenge['type']}',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      if (participantData.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Participants:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      Container(
                        color: Colors.black54,
                        child: Column(
                          children: [
                            ...participantData
                                .map((data) => Card(
                                      color: Colors.transparent,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              data[
                                                  'username'], // Display the username
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            challenge['type'] == 'Team Traverse'
                                                ? Text(
                                                    '${(data['participantResult'] / 1000).toStringAsFixed(2)} km',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  )
                                                : challenge['type'] ==
                                                        'Mtn Scramble'
                                                    ? Text(
                                                        '${data['participantResult'].toStringAsFixed(0)} m',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      )
                                                    : Text(
                                                        '${data['participantResult'].toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      )
                                          ],
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ],
                        ),
                      ),
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

class Snow2Surf extends StatefulWidget {
  final String challengeId;
  final List<dynamic> participantsEmails;
  final Timestamp startDate;
  final String challengeType;
  final String challengeName;
  final String challengeDifficulty;
  final List challengeLegs;

  const Snow2Surf({
    super.key,
    required this.challengeId,
    required this.participantsEmails,
    required this.startDate,
    required this.challengeType,
    required this.challengeName,
    required this.challengeDifficulty,
    required this.challengeLegs,
  });

  @override
  State<Snow2Surf> createState() => _Snow2SurfState();
}

class _Snow2SurfState extends State<Snow2Surf> {
  final currentUser = FirebaseAuth.instance.currentUser;
  DateTime? endDate;

  initState() {
    super.initState();
    DateTime startDate = widget.startDate.toDate();
    DateTime adjustedStartDate =
        DateTime(startDate.year, startDate.month, startDate.day);
    endDate = adjustedStartDate.add(Duration(days: 30));
  }

  List<Map<String, dynamic>> categories = [
    {
      'name': 'Alpine Skiing',
      'type': ['Snowboard', 'AlpineSki'],
      'icon': Icons.downhill_skiing_outlined,
      'distance': 2.0,
      'bestTime': '0:00',
    },
    {
      'name': 'Nordic Skiing',
      'type': ['NordicSki'],
      'icon': Symbols.nordic_walking,
      'distance': 8.0,
      'bestTime': '0:00',
    },
    {
      'name': 'Road Running',
      'type': ['VirtualRun', 'Road Run', 'Run'],
      'icon': Symbols.sprint,
      'distance': 7.0,
      'bestTime': '0:00',
    },
    {
      'name': 'Trail Running',
      'type': ['Trail Run'],
      'icon': Icons.directions_run_outlined,
      'distance': 6.0,
      'bestTime': '0:00',
    },
    {
      'name': 'Mountain Biking',
      'type': ['Mtn Bike'],
      'icon': Icons.directions_bike_outlined,
      'distance': 15.0,
      'bestTime': '0:00',
    },
    {
      'name': 'Kayaking',
      'type': ['Kayaking'],
      'icon': Icons.kayaking_outlined,
      'distance': 5.0,
      'bestTime': '0:00',
    },
    {
      'name': 'Road Cycling',
      'type': ['VirtualRide', 'Road Bike', 'Ride'],
      'icon': Icons.directions_bike_outlined,
      'distance': 25.0,
      'bestTime': '0:00',
    },
    {
      'name': 'Canoeing',
      'type': ['Canoeing'],
      'icon': Icons.rowing_outlined,
      'distance': 5.0,
      'bestTime': '0:00',
    },
  ];

  Map<String, dynamic> opponents = {
    "Intro": {
      "name": ["Mike", "Leo", "Raph", "Don"],
      "image": [
        "assets/images/mike.jpg",
        "assets/images/leo.jpg",
        "assets/images/raph.jpg",
        "assets/images/don.jpg"
      ],
      "bestTime": ["0:00", "0:00", "0:00", "0:00"],
    },
    "Advanced": {
      "name": ["Crash", "Todd", "Noise", "Baldy"],
      "image": [
        "assets/images/crash.png",
        "assets/images/todd.png",
        "assets/images/noise.png",
        "assets/images/baldy.png"
      ],
      "bestTime": ["0:00", "0:00", "0:00", "0:00"],
    },
    "Expert": {
      "name": ["Mike", "Leo", "Raph", "Don"],
      "image": [
        "assets/images/mike.jpg",
        "assets/images/leo.jpg",
        "assets/images/raph.jpg",
        "assets/images/don.jpg"
      ],
      "bestTime": ["0:00", "0:00", "0:00", "0:00"],
    },
  };

  String formattedCurrentMonth = '';
  bool hasJoined = false;
  String joinedLeg = '';

  bool isUserInAnyLeg(Map<String, dynamic> legParticipants) {
    return legParticipants.entries.any(
      (entry) => entry.value.contains(currentUser?.email),
    );
  }

  // Add a method to check if the current user is in the participants list.
  bool isCurrentUserInParticipants(String legName) {
    final String? participantEmail = currentUser?.email;
    if (participantEmail != null) {
      final participants = widget.participantsEmails;
      return participants.contains(participantEmail) && joinedLeg == legName;
    }
    return false;
  }

  Stream<DocumentSnapshot> getChallengeData() {
    return FirebaseFirestore.instance
        .collection('Challenges')
        .doc(widget.challengeId)
        .snapshots();
  }

  Future<String> getUsername(String userEmail) async {
    try {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userEmail)
          .get();

      // Cast the userDoc.data() to Map<String, dynamic> before using containsKey.
      final userData = userDoc.data() as Map<String, dynamic>?;

      if (userDoc.exists &&
          userData != null &&
          userData.containsKey('username')) {
        return userData['username'] ?? 'No username';
      } else {
        return 'No username';
      }
    } catch (e) {
      print("Error getting username: $e");
      return 'No username';
    }
  }

  void joinTeam(String legName) async {
    final String? participantEmail = currentUser?.email;

    // Check for null email
    if (participantEmail == null) {
      print("User email is null. Cannot join leg.");
      return;
    }

    final DocumentReference challengeRef = FirebaseFirestore.instance
        .collection('Challenges')
        .doc(widget.challengeId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(challengeRef);
        if (!snapshot.exists) {
          throw Exception("Challenge does not exist!");
        }
        Map<String, dynamic> legParticipants =
            snapshot['legParticipants'] ?? {};
        List<dynamic> participantsForLeg =
            List.from(legParticipants[legName] ?? []);
        if (!participantsForLeg.contains(participantEmail)) {
          participantsForLeg.add(participantEmail);
          legParticipants[legName] = participantsForLeg;
          transaction
              .update(challengeRef, {'legParticipants': legParticipants});
          setState(() {
            hasJoined = true;
            joinedLeg = legName;
          });
        }
      });

      print("Joined leg successfully.");
    } catch (e) {
      print("Failed to join leg: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFD3C3),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.challengeType,
          style: GoogleFonts.tektur(
            textStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.2,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      widget.challengeName,
                      style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1.2)),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        '${DateFormat('MMMM dd, yyyy').format(widget.startDate.toDate())} - ${DateFormat('MMMM dd, yyyy').format(endDate!)}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: getChallengeData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Center(child: Text("Challenge not found"));
                  }

                  // Extract the data once from the snapshot
                  Map<String, dynamic> challengeData =
                      snapshot.data?.data() as Map<String, dynamic>;
                  Map<String, dynamic> legParticipants =
                      challengeData['legParticipants'] ?? {};
                  bool isAlreadyInAMatchup = isUserInAnyLeg(legParticipants);

                  return Container(
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      children: [
                        // Header, etc.
                        Expanded(
                          child: ListView.builder(
                            itemCount: widget.challengeLegs.length,
                            itemBuilder: (context, index) {
                              var currentLeg = widget.challengeLegs[index];
                              var category = categories.firstWhere(
                                (cat) => cat['name'] == currentLeg,
                                orElse: () =>
                                    {'name': 'Unknown', 'icon': Icons.error},
                              );

                              var opponent =
                                  opponents[widget.challengeDifficulty]!;

                              bool isUserInThisLeg = legParticipants[currentLeg]
                                      ?.contains(currentUser?.email) ??
                                  false;

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // User Card with challenge leg icon and name
                                  Expanded(
                                    flex: 2,
                                    child: Card(
                                      child: Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Column(
                                          children: <Widget>[
                                            Icon(category['icon'], size: 52),
                                            Text(category['name']),
                                            if (!isUserInThisLeg &&
                                                !isAlreadyInAMatchup)
                                              ElevatedButton(
                                                onPressed: () =>
                                                    joinTeam(currentLeg),
                                                child: Text('Join'),
                                              ),
                                            if (isAlreadyInAMatchup)
                                              Text('Best Time: 0:00'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // "VS" text
                                  Expanded(
                                    flex: 1,
                                    child: Center(
                                      child: Text(
                                        'VS',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Opponent Card
                                  Expanded(
                                    flex: 2,
                                    child: Card(
                                      child: Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Column(
                                          children: <Widget>[
                                            CircleAvatar(
                                              backgroundImage: AssetImage(
                                                  opponent["image"][index]),
                                            ),
                                            Text(opponent["name"][index]),
                                            Text(
                                                "Best Time: ${opponent["bestTime"][index]}"),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}




//               for (final doc in activityDocs) {
//                 var data = doc.data() as Map<String, dynamic>;
//                 String sportType = data['sport_type'] ?? data['type'];
//                 double averageSpeed = doc['average_speed'];
//                 double activityDistance = doc['distance'] / 1000;
//                 print('Activity Distance: $activityDistance');
//                 String fullname = doc['fullname'];

//                 double categoryDistance = typeToDistanceMap[sportType] ?? 0.0;
//                 // Check if the activity's distance is greater than or equal to the category distance
//                 if (activityDistance >= categoryDistance) {
//                   double timeInSeconds =
//                       (activityDistance * 1000) / averageSpeed;

//                   if (!bestTimes.containsKey(sportType) ||
//                       timeInSeconds < bestTimes[sportType]!['time']) {
//                     bestTimes[sportType] = {
//                       'fullname': fullname,
//                       'time': timeInSeconds,
//                       'speed': averageSpeed,
//                     };
//                   }
//                 }
//               }

//               return Column(
//                 children: [
//                   Expanded(
//                     child: GridView.builder(
//                       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                         crossAxisCount: 1,
//                         childAspectRatio: MediaQuery.of(context).size.width /
//                             (MediaQuery.of(context).size.height / 2),
//                       ),
//                       itemCount: selectedCategories.length + 1,
//                       itemBuilder: (context, index) {
//                         // Check if this index is for the total time display
//                         if (index == selectedCategories.length) {
//                           // Calculate the total time
//                           double totalTime = bestTimesInSeconds.fold(
//                               0, (prev, curr) => prev + curr);

//                           // Return a widget to display the total time
//                           return Card(
//                             child: ListTile(
//                               title: Row(
//                                 mainAxisAlignment: MainAxisAlignment.end,
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Text(
//                                     'Total Time: ',
//                                     style: GoogleFonts.syne(
//                                         textStyle: TextStyle(
//                                             fontSize: 18,
//                                             fontWeight: FontWeight.bold)),
//                                   ),
//                                   Text(
//                                     '${formatTime(totalTime)}',
//                                     style: GoogleFonts.syne(
//                                         textStyle: TextStyle(fontSize: 18)),
//                                   ),
//                                 ],
//                               ),
//                               // Adjust the styling as needed
//                             ),
//                           );
//                         } else {
//                           var category = selectedCategories[index];
//                           List<String> sportTypes =
//                               List<String>.from(category['type']);

//                           Map<String, dynamic>? bestTimeEntry;
//                           double categoryDistance = category['distance'];

//                           for (String type in sportTypes) {
//                             if (bestTimes.containsKey(type)) {
//                               if (bestTimeEntry == null ||
//                                   bestTimes[type]!['time'] <
//                                       bestTimeEntry['time']) {
//                                 bestTimeEntry = bestTimes[type];
//                               }
//                             }
//                           }

//                           String displayName = bestTimeEntry != null
//                               ? bestTimeEntry['fullname']
//                               : "User";

//                           double bestSpeed = bestTimeEntry != null
//                               ? bestTimeEntry['speed']
//                               : 0.0;

//                           // Adjust the distance based on the category name
//                           if (category['name'] == 'Trail Run') {
//                             categoryDistance = 6.0; // Distance for Trail Run
//                           } else if (category['name'] == 'Road Run') {
//                             categoryDistance = 7.0; // Distance for Road Run
//                           }
//                           if (category['name'] == 'Road Bike') {
//                             categoryDistance = 25.0; // Distance for Road Bike
//                           } else if (category['name'] == 'Mountain Bike') {
//                             categoryDistance =
//                                 15.0; // Distance for Mountain Bike
//                           }

//                           double totalTimeInSeconds = bestSpeed > 0
//                               ? (categoryDistance * 1000) / bestSpeed
//                               : 0.0;
//                           String displayTime = formatTime(totalTimeInSeconds);

// // Add to your list of best times
//                           bestTimesInSeconds.add(totalTimeInSeconds);

//                           return Padding(
//                             padding: const EdgeInsets.all(1.0),
//                             child: GestureDetector(
//                               onTap: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (context) => Snow2SurfResultsPage(
//                                       icon: categories[index]['icon'],
//                                       category: category['name'],
//                                       types: categories[index]['type'],
//                                       distance: category['distance'],
//                                     ),
//                                   ),
//                                 );
//                               },
//                               child: Card(
//                                 elevation: 2,
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(8.0),
//                                   child: Column(
//                                     mainAxisAlignment:
//                                         MainAxisAlignment.spaceEvenly,
//                                     children: <Widget>[
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           Icon(selectedCategories[index]
//                                               ['icon']),
//                                           Text(
//                                             selectedCategories[index]['name'],
//                                             style: TextStyle(
//                                                 fontSize: 14,
//                                                 fontWeight: FontWeight.bold),
//                                           ),
//                                         ],
//                                       ),
//                                       Text(
//                                         displayName.split(
//                                             ' ')[0], // Display the first name
//                                         style: TextStyle(fontSize: 18),
//                                       ),
//                                       Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           Text('Best Time: $displayTime'),
//                                           Text(
//                                               "Min Distance: ${categoryDistance.toString()} km"),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           );
//                         }
//                       },
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
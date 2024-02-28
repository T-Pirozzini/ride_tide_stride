import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ride_tide_stride/pages/chat_widget.dart';
import 'package:ride_tide_stride/models/chat_message.dart';

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
  final GlobalKey<ScaffoldState> _snow2SurfScaffoldKey =
      GlobalKey<ScaffoldState>();
  final currentUser = FirebaseAuth.instance.currentUser;
  DateTime? endDate;
  String formattedCurrentMonth = '';
  bool hasJoined = false;
  String joinedLeg = '';

  void _sendMessage(String messageText) async {
    if (messageText.isEmpty) {
      return; // Avoid sending empty messages
    }
    final messageData = {
      'time': FieldValue.serverTimestamp(), // Firestore server timestamp
      'user': currentUser?.email ?? 'Anonymous',
      'message': messageText
    };

    // Write the message to Firestore
    try {
      await FirebaseFirestore.instance
          .collection('Challenges')
          .doc(widget.challengeId)
          .collection('messages')
          .add(messageData);
    } catch (e) {
      print('Error saving message: $e');
    }
  }

  initState() {
    super.initState();
    DateTime startDate = widget.startDate.toDate();
    DateTime adjustedStartDate =
        DateTime(startDate.year, startDate.month, startDate.day);
    endDate = adjustedStartDate.add(Duration(days: 30));

    getActivitiesWithinDateRange().listen((activities) {
      processActivities(activities);
    });
    checkAndFinalizeChallenge();
    _messagesStream = FirebaseFirestore.instance
        .collection('Challenges')
        .doc(widget.challengeId)
        .collection('messages')
        .orderBy('time',
            descending: false) // Assuming 'time' is your timestamp field
        .snapshots();
  }

  Stream<QuerySnapshot>? _messagesStream;

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
      'distance': 3.0,
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
      "name": ["Dipsy", "La La", "Poe", "Tinky"],
      "image": [
        "assets/images/dipsy.jpg",
        "assets/images/lala.jpg",
        "assets/images/poe.jpg",
        "assets/images/tinky.jpg"
      ],
      "bestTimes": {
        "Alpine Skiing": "0:15:00",
        "Nordic Skiing": "0:50:00",
        "Road Running": "0:45:00",
        "Trail Running": "0:50:00",
        "Mountain Biking": "01:10:00",
        "Kayaking": "0:50:00",
        "Road Cycling": "01:15:00",
        "Canoeing": "1:15:00",
      },
      "teamName": "Teletubbies",
    },
    "Advanced": {
      "name": ["Crash", "Todd", "Noise", "Baldy"],
      "image": [
        "assets/images/crash.png",
        "assets/images/todd.png",
        "assets/images/noise.png",
        "assets/images/baldy.png"
      ],
      "bestTimes": {
        "Alpine Skiing": "0:10:00",
        "Nordic Skiing": "0:40:00",
        "Road Running": "0:35:00",
        "Trail Running": "0:40:00",
        "Mountain Biking": "0:50:00",
        "Kayaking": "0:40:00",
        "Road Cycling": "00:50:00",
        "Canoeing": "0:55:00",
      },
      "teamName": "Crash N' The Boys",
    },
    "Expert": {
      "name": ["Mike", "Leo", "Raph", "Don"],
      "image": [
        "assets/images/mike.jpg",
        "assets/images/leo.jpg",
        "assets/images/raph.jpg",
        "assets/images/don.jpg"
      ],
      "bestTimes": {
        "Alpine Skiing": "0:07:00",
        "Nordic Skiing": "0:30:00",
        "Road Running": "0:22:00",
        "Trail Running": "0:25:00",
        "Mountain Biking": "0:40:00",
        "Kayaking": "0:30:00",
        "Road Cycling": "0:40:00",
        "Canoeing": "0:45:00",
      },
      "teamName": "TMNT",
    },
  };

  void joinTeam(String legName) async {
    final String? participantEmail = currentUser?.email;

    // Check for null email
    if (participantEmail == null) {
      print("User email is null. Cannot join leg.");
      return;
    }

    // Ensure user is a participant
    if (!widget.participantsEmails.contains(participantEmail)) {
      print("User is not a participant in this challenge. Cannot join leg.");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("You are not a participant in this challenge."),
      ));
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

        // Check if user has already joined any leg
        bool alreadyInALeg = legParticipants.values.any((legParticipant) {
          return legParticipant['participant'] == participantEmail;
        });

        if (alreadyInALeg) {
          print("User has already joined a leg.");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("You have already joined a leg."),
          ));
          return;
        }

        // Prepare the participant record
        Map<String, dynamic> participantRecord = {
          'participant': participantEmail,
          'best_time': '0:00:00' // Default best time
        };

        // Add the participant to the leg
        legParticipants[legName] = participantRecord;

        // Update the challenge with the new participant
        transaction.update(challengeRef, {'legParticipants': legParticipants});

        setState(() {
          hasJoined = true;
          joinedLeg = legName;
        });
      });

      print("Joined leg successfully.");
    } catch (e) {
      print("Failed to join leg: $e");
    }
  }

  bool isUserInAnyLeg(Map<String, dynamic> legParticipants) {
    return legParticipants.entries.any(
      (entry) =>
          entry.value is List<dynamic> &&
          entry.value.contains(currentUser?.email),
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

  Stream<List<DocumentSnapshot>> getActivitiesWithinDateRange() {
    // Create a controller for a stream of lists of DocumentSnapshots.
    var controller = StreamController<List<DocumentSnapshot>>();

    // This will keep track of the list of all document snapshots from all streams.
    List<DocumentSnapshot> allDocuments = [];

    DateTime startDate = widget.startDate.toDate();
    DateTime adjustedStartDate =
        DateTime(startDate.year, startDate.month, startDate.day);
    endDate = adjustedStartDate.add(Duration(days: 30));

    // Subscribe to the snapshot stream for each email.
    for (String email in widget.participantsEmails) {
      FirebaseFirestore.instance
          .collection('activities')
          .where('user_email', isEqualTo: email)
          .where('timestamp', isGreaterThanOrEqualTo: adjustedStartDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .snapshots()
          .listen((snapshot) {
        // When a new snapshot is emitted, add all documents to the allDocuments list.
        allDocuments.addAll(snapshot.docs);

        // Add the updated allDocuments list to the stream.
        controller.add(allDocuments);
      });
    }

    // Return the stream from the controller. This stream will now emit updates
    // whenever any of the subscribed streams emit.
    return controller.stream;
  }

  void processActivities(List<DocumentSnapshot> activities) async {
    DocumentReference challengeRef = FirebaseFirestore.instance
        .collection('Challenges')
        .doc(widget.challengeId);

    DocumentSnapshot challengeSnapshot = await challengeRef.get();
    if (!challengeSnapshot.exists) {
      print("Challenge does not exist!");
      return;
    }
    Map<String, dynamic> challengeData =
        challengeSnapshot.data() as Map<String, dynamic>;
    Map<String, dynamic> legParticipants =
        challengeData['legParticipants'] ?? {};

    for (var category in categories) {
      var matchingActivities = activities.where((activity) {
        Map<String, dynamic> activityData =
            activity.data() as Map<String, dynamic>;
        return category['type'].contains(activityData['sport_type']) &&
            (activityData['distance'] / 1000) >= category['distance'];
      }).toList();

      if (matchingActivities.isNotEmpty) {
        var bestActivity = matchingActivities.reduce((curr, next) =>
            (curr.data() as Map<String, dynamic>)['average_speed'] >
                    (next.data() as Map<String, dynamic>)['average_speed']
                ? curr
                : next);

        Map<String, dynamic> bestActivityData =
            bestActivity.data() as Map<String, dynamic>;
        double bestAverageSpeed = bestActivityData['average_speed'];
        double activityDistance = category['distance'] * 1000;

        double bestTimeInSeconds = activityDistance / bestAverageSpeed;
        String formattedBestTime = formatTime(bestTimeInSeconds);

        // Check if the user has joined this category's leg before attempting to update
        if (legParticipants.containsKey(category['name']) &&
            legParticipants[category['name']]['participant'] ==
                currentUser?.email) {
          // Update only the best time, preserving the participant field
          Map<String, dynamic> legInfo = legParticipants[category['name']];
          legInfo['best_time'] = formattedBestTime;

          // Construct the path for the update operation
          String updatePath = 'legParticipants.${category['name']}';
          Map<String, dynamic> update = {updatePath: legInfo};

          // Perform the update operation
          challengeRef
              .update(update)
              .then((_) => print("Best time updated successfully."))
              .catchError(
                  (error) => print("Failed to update best time: $error"));
        }
      }
    }
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
        return userData['username'] ?? 'No participant';
      } else {
        return 'No username';
      }
    } catch (e) {
      print("Error getting username: $e");
      return 'No username';
    }
  }

  Duration parseBestTime(String bestTime) {
    List<String> parts = bestTime.split(':');
    return Duration(
        hours: int.parse(parts[0]),
        minutes: int.parse(parts[1]),
        seconds: int.parse(parts[2]));
  }

  Widget timeDifferenceWidget(
      String participantBestTime, String opponentBestTime) {
    // Parse the times to Duration, handling "N/A" as zero for the participant
    Duration participantDuration = participantBestTime != "N/A"
        ? parseBestTime(participantBestTime)
        : Duration.zero;
    Duration opponentDuration = parseBestTime(opponentBestTime);

    // If participant has no time, show full opponent lead
    if (participantBestTime == "N/A") {
      return Text(
        "- ${formatDuration(opponentDuration)}",
        style: TextStyle(
          color: Colors.red, // Or any color that signifies this condition
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Calculate the difference otherwise
    Duration difference = opponentDuration - participantDuration;
    String differenceFormatted = difference.isNegative
        ? '-${formatDuration(difference.abs())}'
        : '+${formatDuration(difference)}';

    return Text(
      differenceFormatted,
      style: TextStyle(
        color: difference.isNegative ? Colors.red : Colors.green,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Duration getTotalOpponentTime(
      String difficultyLevel, List<dynamic> selectedLegs) {
    final opponentTimes = opponents[difficultyLevel]?['bestTimes'];
    if (opponentTimes == null) return Duration.zero;

    return opponentTimes.entries.fold<Duration>(Duration.zero,
        (Duration total, MapEntry<String, String> entry) {
      if (selectedLegs.contains(entry.key)) {
        // Check if the leg is selected
        final timeParts = entry.value.split(':').map(int.parse).toList();
        final duration = Duration(
            hours: timeParts[0], minutes: timeParts[1], seconds: timeParts[2]);
        return total + duration;
      }
      return total; // Return total as-is if the leg is not selected
    });
  }

  Future<Map<String, dynamic>> getTotalParticipantTimeAndLegsInfo(
      String challengeId) async {
    final challengeRef =
        FirebaseFirestore.instance.collection('Challenges').doc(challengeId);
    final challengeSnapshot = await challengeRef.get();

    if (!challengeSnapshot.exists) {
      return {"totalTime": Duration.zero, "legsCompleted": 0};
    }

    final challengeData = challengeSnapshot.data() as Map<String, dynamic>;
    final legParticipants = challengeData['legParticipants'] ?? {};
    int legsCompleted = 0;

    Duration totalTime = legParticipants.entries.fold<Duration>(Duration.zero,
        (Duration total, MapEntry<String, dynamic> entry) {
      final bestTime = entry.value['best_time'];
      if (bestTime != null && bestTime != '0:00') {
        final timeParts = bestTime.split(':').map(int.parse).toList();
        final duration = Duration(
            hours: timeParts[0],
            minutes: timeParts[1],
            seconds: timeParts.length > 2 ? timeParts[2] : 0);
        legsCompleted++;
        return total + duration;
      }
      return total;
    });

    return {
      "totalTime": totalTime,
      "legsCompleted": legsCompleted,
      "legsRemaining": 4 - legsCompleted // Assuming 4 legs are required
    };
  }

  String calculateTimeDifference(
      Duration participantTime, String formattedOpponentTime) {
    Duration opponentTime = parseBestTime(formattedOpponentTime);
    Duration timeDifference = opponentTime - participantTime;

    // Format time difference
    String formattedTimeDifference = formatDuration(timeDifference.abs());

    // Determine the sign based on if the participant is winning or losing
    // If participant time is less (better), then timeDifference is negative
    bool participantIsWinning = timeDifference.isNegative;
    String sign = participantIsWinning ? '-' : '+'; // Corrected this line

    return '$sign$formattedTimeDifference';
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

// Helper function to format time in seconds into a readable string
  String formatTime(double seconds) {
    int hours = seconds ~/ 3600;
    int minutes = ((seconds % 3600) ~/ 60);
    int remainingSeconds = seconds.toInt() % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> checkAndFinalizeChallenge() async {
    DateTime now = DateTime.now();

    var participantTotalTimeInfo =
        await getTotalParticipantTimeAndLegsInfo(widget.challengeId);
    Duration participantTotalTime = participantTotalTimeInfo["totalTime"];
    Duration opponentTotalTime =
        getTotalOpponentTime(widget.challengeDifficulty, widget.challengeLegs);

    // Check if the challenge has ended
    if (endDate != null && now.isAfter(endDate!)) {
      // Calculate the time difference
      String formattedOpponentTotalTime = formatDuration(opponentTotalTime);
      String timeDifferenceDisplay = calculateTimeDifference(
          participantTotalTime, formattedOpponentTotalTime);

      bool isParticipantWinning = timeDifferenceDisplay.startsWith('-');

      // Update the challenge as completed with success or fail based on the total times
      await FirebaseFirestore.instance
          .collection('Challenges')
          .doc(widget.challengeId)
          .update({'active': false, 'success': isParticipantWinning});

      // Show the dialog after the state update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isParticipantWinning) {
          _showSuccessDialog();
        }
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Challenge Completed!"),
          content: Stack(
            children: <Widget>[
              Lottie.asset(
                'assets/lottie/win_animation.json',
                frameRate: FrameRate.max,
                repeat: true,
                reverse: false,
                animate: true,
              ),
              Lottie.asset(
                'assets/lottie/firework_animation.json',
                frameRate: FrameRate.max,
                repeat: true,
                reverse: false,
                animate: true,
              ),
              const Text(
                "Congratulations! You have successfully completed the challenge.",
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Duration totalOpponentTime =
        getTotalOpponentTime(widget.challengeDifficulty, widget.challengeLegs);
    final String formattedOpponentTotalTime =
        formatTime(totalOpponentTime.inSeconds.toDouble());

    return Scaffold(
      key: _snow2SurfScaffoldKey,
      resizeToAvoidBottomInset: true,
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
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.chat),
            onPressed: () =>
                _snow2SurfScaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      "Difficulty Level: ${widget.challengeDifficulty}",
                      style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.2,
                        ),
                      ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.challengeName}',
                    style: GoogleFonts.audiowide(
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w100,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Text(
                    '${opponents[widget.challengeDifficulty]['teamName']}',
                    style: GoogleFonts.audiowide(
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w100,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

                  Map<String, dynamic> challengeData =
                      snapshot.data?.data() as Map<String, dynamic>;
                  Map<String, dynamic> legParticipants =
                      challengeData['legParticipants'] ?? {};

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Align(
                      alignment: Alignment.center,
                      child: ListView.builder(
                        itemCount: widget.challengeLegs.length,
                        itemBuilder: (context, index) {
                          var currentLeg = widget.challengeLegs[index];
                          var category = categories.firstWhere(
                            (cat) => cat['name'] == currentLeg,
                            orElse: () =>
                                {'name': 'Unknown', 'icon': Icons.error},
                          );

                          var opponent = opponents[widget.challengeDifficulty]!;
                          var difficultyLevel = widget.challengeDifficulty;
                          var opponentBestTime = opponents[difficultyLevel]
                                  ["bestTimes"][currentLeg] ??
                              "N/A";

                          String participantBestTime =
                              legParticipants[currentLeg] != null
                                  ? legParticipants[currentLeg]['best_time'] ??
                                      'N/A'
                                  : 'N/A';

                          Map<String, dynamic> participantsForLeg =
                              legParticipants[currentLeg] ?? {};
                          String bestTime =
                              participantsForLeg['best_time'] ?? 'N/A';
                          String participant =
                              participantsForLeg['participant'] ?? 'N/A';

                          bool isUserInThisLeg =
                              participant == (currentUser?.email ?? '');

                          print(participant);

                          return Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Card(
                                          child: Padding(
                                            padding: EdgeInsets.all(2),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    Text(
                                                      category['name'],
                                                      style: TextStyle(
                                                          fontSize: 12),
                                                    ),
                                                    Text(
                                                      '${category['distance'].toString()} km',
                                                      style: TextStyle(
                                                          fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                                FutureBuilder<String>(
                                                  future:
                                                      getUsername(participant),
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return CircularProgressIndicator();
                                                    }
                                                    if (snapshot.hasError) {
                                                      return Text(
                                                          'Error loading username');
                                                    }
                                                    String username =
                                                        snapshot.data ?? '';
                                                    bool showJoinButton =
                                                        username ==
                                                                "No username" &&
                                                            (bestTime ==
                                                                    "N/A" ||
                                                                bestTime
                                                                    .isEmpty);
                                                    List<Widget>
                                                        columnChildren = [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                              category['icon']),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            username.isNotEmpty
                                                                ? username
                                                                : 'No username',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                        ],
                                                      ),
                                                      Text(
                                                          'Best Time: ${bestTime.isNotEmpty ? bestTime : "N/A"}'),
                                                    ];
                                                    if (showJoinButton) {
                                                      columnChildren.add(
                                                        ElevatedButton(
                                                          onPressed: () =>
                                                              joinTeam(
                                                                  currentLeg),
                                                          child: Text('Join'),
                                                        ),
                                                      );
                                                    } else {
                                                      columnChildren
                                                          .add(SizedBox());
                                                    }
                                                    return Column(
                                                      children: columnChildren,
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Center(
                                      child: Text(
                                        'VS',
                                        style: GoogleFonts.blackOpsOne(
                                          textStyle: TextStyle(
                                            fontSize: 32,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    timeDifferenceWidget(
                                        participantBestTime, opponentBestTime)
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        CircleAvatar(
                                          backgroundImage: AssetImage(
                                              opponent["image"][index]),
                                        ),
                                        Text(opponent["name"][index]),
                                        Text("Best Time: ${opponentBestTime}"),
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
                  );
                },
              ),
            ),
            FutureBuilder<Map<String, dynamic>>(
              future: getTotalParticipantTimeAndLegsInfo(widget.challengeId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(); // Show loading indicator while waiting
                }

                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}"); // Show error if any
                }

                if (snapshot.hasData) {
                  final int legsCompleted = snapshot.data!['legsCompleted'];
                  final int legsRemaining = snapshot.data!['legsRemaining'];

                  if (legsCompleted < 4) {
                    // Not all legs have times
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context)
                              .errorColor, // Or any color that fits your design
                        ),
                        SizedBox(
                            width:
                                8), // Provides spacing between the icon and the text
                        Text(
                          "Please complete all legs. $legsRemaining remaining.",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors
                                .black54, // Or any color that fits your design
                          ),
                        ),
                      ],
                    );
                  }
                  // Extract the necessary data
                  final Duration totalTime = snapshot.data!['totalTime'];

                  // All legs have times
                  final String formattedTotalParticipantTime =
                      formatDuration(totalTime);
                  final String timeDifferenceDisplay = calculateTimeDifference(
                      totalTime, formattedOpponentTotalTime);

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                '$formattedTotalParticipantTime',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                '$formattedOpponentTotalTime',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: RichText(
                            text: TextSpan(
                              text: '',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                              children: <TextSpan>[
                                TextSpan(
                                  text: timeDifferenceDisplay,
                                  style: TextStyle(
                                      color:
                                          timeDifferenceDisplay.startsWith('-')
                                              ? Colors.red
                                              : Colors.green),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Text("No data available");
                }
              },
            ),
            StreamBuilder<List<DocumentSnapshot>>(
              stream: getActivitiesWithinDateRange(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return Center(
                      child:
                          Text("No activities found in the given date range"));
                }

                // Once activities are fetched
                List<DocumentSnapshot> activities = snapshot.data!;
                return Container(
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(2),
                  child: IconButton(
                    icon: Icon(Icons.refresh, size: 20),
                    onPressed: () => processActivities(activities),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      endDrawer: Drawer(
        child: StreamBuilder<QuerySnapshot>(
          stream: _messagesStream,
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text('Something went wrong');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Loading');
            }
            final messages = snapshot.data?.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ChatMessage(
                    user: data['user'] ?? 'Anonymous',
                    message: data['message'] ?? '',
                    time: (data['time'] as Timestamp).toDate(),
                  );
                }).toList() ??
                [];

            final random = Random(currentUser!.email.hashCode);
            final participantColors = {
              for (var email in widget.participantsEmails)
                if (email is String)
                  email: Color((random.nextInt(0xFFFFFF) << 8) | 0xFF)
            };

            return ChatWidget(
              key: ValueKey(messages.length),
              messages: messages,
              currentUserEmail: currentUser?.email ?? '',
              participantColors: participantColors,
              onSend: (String message) {
                if (message.isNotEmpty) {
                  _sendMessage(message);
                }
              },
              teamColor: Color((random.nextInt(0xFFFFFF) << 8) | 0xFF),
            );
          },
        ),
      ),
    );
  }
}

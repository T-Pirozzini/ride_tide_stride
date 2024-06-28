import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ride_tide_stride/screens/challenges/activity_dialog.dart';
import 'package:ride_tide_stride/screens/challenges/challenge_helpers.dart';
import 'package:ride_tide_stride/screens/challenges/comp_graph.dart';
import 'package:ride_tide_stride/screens/challenges/mtn_scramble/coop_graph.dart';
import 'package:ride_tide_stride/screens/challenges/mtn_scramble/team_selection_dialog.dart';
import 'package:ride_tide_stride/models/chat_message.dart';
import 'package:ride_tide_stride/screens/chat/chat_widget.dart';
import 'package:badges/badges.dart' as badges;

class TeamTraversePage extends StatefulWidget {
  final String challengeId;
  final List<dynamic> participantsEmails;
  final Timestamp startDate;
  final String challengeType;
  final String challengeName;
  final String mapDistance;
  final String challengeCategory;
  final String challengeActivity;
  final String challengeCreator;
  final String coopOrComp;

  const TeamTraversePage(
      {Key? key,
      required this.challengeId,
      required this.participantsEmails,
      required this.startDate,
      required this.challengeType,
      required this.challengeName,
      required this.mapDistance,
      required this.challengeCategory,
      required this.challengeActivity,
      required this.challengeCreator,
      required this.coopOrComp})
      : super(key: key);

  @override
  State<TeamTraversePage> createState() => _TeamTraversePageState();
}

class _TeamTraversePageState extends State<TeamTraversePage> {
  final GlobalKey<ScaffoldState> _teamTraverseScaffoldKey =
      GlobalKey<ScaffoldState>();
  final currentUser = FirebaseAuth.instance.currentUser;
  Map<String, Color> participantColors = {};
  DateTime? endDate;
  bool unread = false;
  int unreadMessageCount = 0;
  List<String> team1Emails = [];
  List<String> team2Emails = [];

  Stream<QuerySnapshot>? _messagesStream;

  @override
  void initState() {
    super.initState();
    DateTime startDate = widget.startDate.toDate();
    DateTime adjustedStartDate =
        DateTime(startDate.year, startDate.month, startDate.day);
    endDate = adjustedStartDate.add(Duration(days: 30));
    checkAndFinalizeChallenge();
    _messagesStream = FirebaseFirestore.instance
        .collection('Challenges')
        .doc(widget.challengeId)
        .collection('messages')
        .orderBy('time', descending: true)
        .snapshots();

    fetchInitialReadByData();
    fetchTeamEmails().then((_) {
      setState(() {}); // Refresh the UI after fetching team emails
    });
  }

  void _sendMessage(String messageText) async {
    if (messageText.isEmpty) {
      return;
    }
    final messageData = {
      'time': FieldValue.serverTimestamp(),
      'user': currentUser?.email ?? 'Anonymous',
      'message': messageText,
      'readBy': [currentUser?.email],
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

  void _markMessagesAsRead(List<DocumentSnapshot> messageDocs) {
    for (var doc in messageDocs) {
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      if (data != null &&
          !(data['readBy'] as List<dynamic>? ?? [])
              .contains(currentUser?.email)) {
        FirebaseFirestore.instance
            .collection('Challenges')
            .doc(widget.challengeId)
            .collection('messages')
            .doc(doc.id)
            .update({
          'readBy': FieldValue.arrayUnion([currentUser?.email])
        }).then((_) {
          print(
              "Message marked as read for: ${currentUser?.email}"); // Debug output
        }).catchError((error) {
          print("Failed to mark message as read: $error"); // Debug output
        });
      }
    }
  }

  void updateUnreadStatus(List<DocumentSnapshot> messageDocs) {
    int newUnreadCount = 0;
    for (var doc in messageDocs) {
      var data = doc.data() as Map<String, dynamic>;
      if (!(data['readBy'] as List<dynamic>).contains(currentUser?.email)) {
        newUnreadCount++;
      }
    }

    Future.microtask(() {
      if (unreadMessageCount != newUnreadCount) {
        setState(() {
          unreadMessageCount = newUnreadCount;
        });
      }
    });
  }

  void fetchInitialReadByData() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('Challenges')
          .doc(widget.challengeId)
          .collection('messages')
          .orderBy('time', descending: true)
          .get();

      updateUnreadStatus(snapshot.docs);
    } catch (e) {
      print('Error fetching messages: $e');
    }
  }

  Future<void> fetchTeamEmails() async {
    DocumentSnapshot challengeDoc = await FirebaseFirestore.instance
        .collection('Challenges')
        .doc(widget.challengeId)
        .get();

    if (challengeDoc.exists) {
      var data = challengeDoc.data() as Map<String, dynamic>?;

      if (data != null && data.containsKey('team1')) {
        team1Emails = List<String>.from(data['team1']).take(4).toList();
      }
      if (data != null && data.containsKey('team2')) {
        team2Emails = List<String>.from(data['team2']).take(4).toList();
      }
    }
  }

  Future<Map<String, double>> fetchParticipantDistances() async {
    Map<String, double> participantDistances = {};
    List<Color> colors = [
      Colors.redAccent,
      Colors.greenAccent,
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.cyanAccent,
      Colors.pinkAccent,
      Colors.amberAccent,
    ];
    int colorIndex = 0;

    // Mapping challenge activities to Firestore activity types
    Map<String, List<String>> activityTypeMappings = {
      'Running': ['Run', 'VirtualRun'],
      'Cycling': ['EBikeRide', 'Ride', 'VirtualRide'],
      'Paddling': ['Canoeing', 'Rowing', 'Kayaking', 'StandUpPaddling'],
    };

    DateTime startDate = widget.startDate.toDate();
    DateTime adjustedStartDate =
        DateTime(startDate.year, startDate.month, startDate.day);
    String adjustedStartDateString = adjustedStartDate.toIso8601String();
    Map<String, double> participantProgress = {};

    for (String email in widget.participantsEmails) {
      double totalDistance = 0.0;

      Query query = FirebaseFirestore.instance
          .collection('activities')
          .where('user_email', isEqualTo: email)
          .where('start_date_local',
              isGreaterThanOrEqualTo: adjustedStartDateString);

      // Adjust query for Competitive challenges
      if (widget.challengeCategory == "Specific" &&
          activityTypeMappings.containsKey(widget.challengeActivity)) {
        List<String> relevantActivityTypes =
            activityTypeMappings[widget.challengeActivity]!;
        for (String activityType in relevantActivityTypes) {
          var activitiesSnapshot =
              await query.where('type', isEqualTo: activityType).get();
          activitiesSnapshot.docs.forEach((doc) {
            Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
            if (data != null) {
              totalDistance += (data['distance'] as num?)?.toDouble() ?? 0.0;
            }
          });
        }
      } else {
        // For non-competitive, fetch all activities without filtering by type
        var activitiesSnapshot = await query.get();
        activitiesSnapshot.docs.forEach((doc) {
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            totalDistance += (data['distance'] as num?)?.toDouble() ?? 0.0;
          }
        });
      }

      participantProgress[email] = totalDistance / 1000;
      participantDistances[email] = totalDistance;
      participantColors[email] = colors[colorIndex % colors.length];
      colorIndex++;
    }
    await FirebaseFirestore.instance
        .collection('Challenges')
        .doc(widget.challengeId)
        .update({'participantProgress': participantProgress});

    return participantDistances;
  }

  Widget buildPieChart(Map<String, double> participantDistances) {
    double totalDistance =
        participantDistances.values.fold(0.0, (a, b) => a + b);
    List<PieChartSectionData> sections =
        participantDistances.entries.map((entry) {
      final isLarge =
          totalDistance > 0 ? (entry.value / totalDistance) > 0.1 : false;
      Color color = participantColors[entry.key] ?? Colors.grey;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${(entry.value / totalDistance * 100).toStringAsFixed(1)}%',
        radius: isLarge ? 50 : 50,
        titleStyle: TextStyle(
            fontSize: isLarge ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: Colors.white),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 20,
        sectionsSpace: 2,
      ),
    );
  }

  Future<Map<String, dynamic>> fetchChallengeMapDetails() async {
    var challengeSnapshot = await FirebaseFirestore.instance
        .collection('Challenges')
        .doc(widget.challengeId)
        .get();
    if (!challengeSnapshot.exists) {
      throw Exception("Challenge not found");
    }
    var data = challengeSnapshot.data();
    if (data == null) {
      throw Exception("Challenge data is null");
    }
    return {
      'mapDistance': data['mapDistance'],
      'mapAssetUrl': data['currentMap'],
    };
  }

  Future<Map<String, dynamic>> fetchChallengeDetailsAndTotalDistance() async {
    // Fetch participant distances first
    Map<String, double> participantDistances =
        await fetchParticipantDistances();
    double totalDistance =
        participantDistances.values.fold(0.0, (a, b) => a + b);

    // Fetch team progress for competitive challenges
    double team1Progress = 0.0;
    double team2Progress = 0.0;

    // Fetch team participant emails
    DocumentSnapshot challengeDoc = await FirebaseFirestore.instance
        .collection('Challenges')
        .doc(widget.challengeId)
        .get();
    // Ensure team1 and team2 fields are present, else default to empty list
    List<String> team1Emails = [];
    List<String> team2Emails = [];

    if (challengeDoc.exists) {
      var data = challengeDoc.data() as Map<String, dynamic>?;

      if (data != null && data.containsKey('team1')) {
        team1Emails = List<String>.from(data['team1']);
      }
      if (data != null && data.containsKey('team2')) {
        team2Emails = List<String>.from(data['team2']);
      }
    }

    // Calculate total distance for Team 1
    for (String email in team1Emails) {
      if (participantDistances.containsKey(email)) {
        team1Progress += participantDistances[email]!;
      }
    }

    // Calculate total distance for Team 2
    for (String email in team2Emails) {
      if (participantDistances.containsKey(email)) {
        team2Progress += participantDistances[email]!;
      }
    }

    // Then fetch challenge map details
    var mapDetails = await fetchChallengeMapDetails();

    // Convert 'mapDistance' to a numeric value for calculations
    String mapDistanceStr = widget
        .mapDistance; // Assuming this is your map distance string with 'kms'
    String numericPart = mapDistanceStr.replaceAll(RegExp(r'[^0-9.]'), '');
    double mapDistance = double.parse(numericPart);

    // Return a composite result containing both sets of data
    return {
      'totalDistance': totalDistance, // Total distance from participants
      'mapDistance': mapDistance, // Numeric map distance
      'mapAssetUrl': mapDetails['mapAssetUrl'], // URL or asset path for the map
      'team1Distance': team1Progress,
      'team2Distance': team2Progress,
    };
  }

  Future<void> checkAndFinalizeChallenge() async {
    final challengeDetails = await fetchChallengeDetailsAndTotalDistance();
    final double totalDistance = challengeDetails['totalDistance'] / 1000;
    final double goalDistance = challengeDetails['mapDistance'];
    final double team1Progress = challengeDetails['team1Distance'] / 1000;
    final double team2Progress = challengeDetails['team2Distance'] / 1000;
    final now = DateTime.now();

    // Check if the goal has been met or exceeded
    if (widget.coopOrComp == "Cooperative") {
      if (totalDistance >= goalDistance) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showSuccessDialog(context);
        });
        await FirebaseFirestore.instance
            .collection('Challenges')
            .doc(widget.challengeId)
            .update({
          'active': false,
          'success': true,
          'teamDistance': totalDistance,
          'endDate': Timestamp.fromDate(now),
        });
      }
    } else if (widget.coopOrComp == "Competitive") {
      if (team1Progress >= goalDistance || team2Progress >= goalDistance) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showSuccessDialog(context);
        });
        await FirebaseFirestore.instance
            .collection('Challenges')
            .doc(widget.challengeId)
            .update({
          'active': false,
          'success': true,
          'team1Distance': team1Progress,
          'team2Distance': team2Progress,
          'teamDistance': totalDistance,
          'endDate': Timestamp.fromDate(now),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _teamTraverseScaffoldKey,
      backgroundColor: const Color(0xFFDFD3C3),
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.challengeType,
              style: GoogleFonts.tektur(
                  textStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2)),
            ),
            const SizedBox(width: 10),
            widget.challengeCategory == "Specific"
                ? Icon(
                    widget.challengeActivity == "Running"
                        ? Icons.directions_run
                        : widget.challengeActivity == "Cycling"
                            ? Icons.directions_bike
                            : widget.challengeActivity == "Paddling"
                                ? Icons.kayaking
                                : Icons.directions_walk, // Default icon
                  )
                : SizedBox.shrink(),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: <Widget>[
          IconButton(
            icon: badges.Badge(
              badgeContent: Text(
                unreadMessageCount.toString(),
                style: TextStyle(color: Colors.white),
              ),
              showBadge: unreadMessageCount > 0,
              child: Icon(
                Icons.chat,
                color: unread ? Colors.red : Colors.white,
              ),
            ),
            onPressed: () {
              // Optimistically set unread to false
              setState(() {
                unread = false;
                unreadMessageCount = 0;
              });
              _teamTraverseScaffoldKey.currentState?.openEndDrawer();
            },
          )
        ],
      ),
      body: Column(
        children: <Widget>[
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
                      'Start Date: ${DateFormat('MMMM dd, yyyy').format(widget.startDate.toDate())}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Stack(
              children: [
                FutureBuilder<Map<String, dynamic>>(
                  future: fetchChallengeDetailsAndTotalDistance(),
                  builder: (context, snapshot) {
                    // Handle loading and error states as before
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData) {
                      return Text("Details not available");
                    }

                    // Unchanged logic for handling fetched data
                    double totalDistanceKM =
                        snapshot.data!['totalDistance'] / 1000;
                    double mapDistance = snapshot.data!['mapDistance'];
                    String mapAssetUrl = snapshot.data!['mapAssetUrl'];
                    double progress =
                        (totalDistanceKM / mapDistance).clamp(0.0, 1.0);
                    double team1Progress =
                        snapshot.data!['team1Distance'] / 1000;
                    double team2Progress =
                        snapshot.data!['team2Distance'] / 1000;

                    return Column(
                      children: [
                        widget.coopOrComp == "Competitive"
                            ? Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(15, 30, 15, 0),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Image.asset(mapAssetUrl,
                                              fit: BoxFit.cover),
                                        ),
                                      ),
                                      CompGraph(
                                        team1Progress:
                                            team1Progress / mapDistance,
                                        team2Progress:
                                            team2Progress / mapDistance,
                                      ),
                                    ],
                                  ),
                                ), // Adjusted map to be within an Expanded widget
                              )
                            : Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(15, 30, 15, 0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(mapAssetUrl,
                                        fit: BoxFit.cover),
                                  ),
                                ),
                              ),
                        widget.coopOrComp == "Cooperative"
                            ? CoopGraph(
                                progress: progress,
                                totalElevationM: 0.0,
                                mapElevation: 0.0,
                                totalDistanceKM: totalDistanceKM,
                                mapDistance: mapDistance,
                                elevationOrDistance: "distance",
                              )
                            : SizedBox(),
                      ],
                    );
                  },
                ),
                widget.coopOrComp == "Cooperative"
                    ? Positioned(
                        top: 75,
                        right: 75,
                        child: Opacity(
                          opacity: 0.6,
                          child: FutureBuilder<Map<String, double>>(
                            future: fetchParticipantDistances(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Text("No data available for chart");
                              }
                              return Container(
                                width: 20, // Specify the width of the chart
                                height: 20, // Specify the height of the chart
                                child: buildPieChart(snapshot
                                    .data!), // Your method to build the chart
                              );
                            },
                          ),
                        ),
                      )
                    : SizedBox(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Card(
                      elevation: 2,
                      child: Text(
                        'Goal: ${widget.mapDistance}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 5),
          Divider(
            thickness: 2,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: [
                Icon(Icons.verified_outlined),
                SizedBox(width: 2),
                Text('Challenge Creator'),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FutureBuilder<Map<String, double>>(
                future: fetchParticipantDistances(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData) {
                    return Text("No participant data available");
                  }

                  // Ensure we display up to 8 slots, showing "Empty Slot" as needed
                  int coopItemCount = max(8, widget.participantsEmails.length);
                  int compMaxParticipants = 4;
                  int compItemCount = compMaxParticipants * 2;
                  return widget.coopOrComp == "Cooperative"
                      ? GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // Number of columns
                            childAspectRatio:
                                7 / 2, // Adjust the size ratio of items
                            crossAxisSpacing:
                                2, // Spacing between items horizontally
                            mainAxisSpacing:
                                2, // Spacing between items vertically
                          ),
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: coopItemCount,
                          itemBuilder: (context, index) {
                            String email =
                                index < widget.participantsEmails.length
                                    ? widget.participantsEmails[index]
                                    : "Empty Position";
                            double distance =
                                index < widget.participantsEmails.length
                                    ? snapshot.data![email] ?? 0.0
                                    : 0.0;

                            Color avatarColor =
                                participantColors[email] ?? Colors.grey;

                            return GestureDetector(
                              onTap: () {
                                if (email != "Empty Position") {
                                  showUserActivitiesDialog(context, email,
                                      widget.startDate.toDate());
                                }
                              },
                              child: Card(
                                elevation: 1,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Row(
                                    children: [
                                      email != "Empty Position"
                                          ? CircleAvatar(
                                              backgroundColor: avatarColor,
                                              radius:
                                                  10, // Adjust the size of the avatar as needed
                                            )
                                          : SizedBox.shrink(),
                                      SizedBox(
                                          width:
                                              8), // Provides some spacing between the avatar and the text
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            getUserName(
                                                email), // Username or "Empty Slot"
                                            Text(
                                              index <
                                                      widget.participantsEmails
                                                          .length
                                                  ? '${(distance / 1000).toStringAsFixed(2)} km'
                                                  : '',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      email == widget.challengeCreator
                                          ? Icon(Icons.verified_outlined)
                                          : SizedBox.shrink(),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text(
                                  'Team 1',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                VerticalDivider(
                                    thickness: 1,
                                    color: Colors.black), // Center Divider
                                Text(
                                  'Team 2',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Expanded(
                              child: GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2, // Number of columns
                                  childAspectRatio:
                                      7 / 2, // Adjust the size ratio of items
                                  crossAxisSpacing:
                                      2, // Spacing between items horizontally
                                  mainAxisSpacing:
                                      2, // Spacing between items vertically
                                ),
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: compItemCount,
                                itemBuilder: (context, index) {
                                  String email =
                                      index < widget.participantsEmails.length
                                          ? widget.participantsEmails[index]
                                          : "Empty Position";
                                  double distance =
                                      index < widget.participantsEmails.length
                                          ? snapshot.data![email] ?? 0.0
                                          : 0.0;

                                  Color avatarColor =
                                      participantColors[email] ?? Colors.grey;

                                  Color cardColor;

                                  if (index % 2 == 0) {
                                    // Left side (team1)
                                    int team1Index = index ~/ 2;
                                    cardColor = Colors.lightGreenAccent;
                                    if (team1Index < team1Emails.length) {
                                      email = team1Emails[team1Index];
                                      distance = snapshot.data![email] ?? 0.0;
                                      avatarColor = participantColors[email] ??
                                          Colors.grey;
                                    } else {
                                      email = "Empty Position";
                                      distance = 0.0;
                                      avatarColor = Colors.grey;
                                    }
                                  } else {
                                    // Right side (team2)
                                    int team2Index = index ~/ 2;
                                    cardColor = Colors.lightBlueAccent;
                                    if (team2Index < team2Emails.length) {
                                      email = team2Emails[team2Index];
                                      distance = snapshot.data![email] ?? 0.0;
                                      avatarColor = participantColors[email] ??
                                          Colors.grey;
                                    } else {
                                      email = "Empty Position";
                                      distance = 0.0;
                                      avatarColor = Colors.grey;
                                    }
                                  }

                                  return GestureDetector(
                                    onTap: () {
                                      if (email != "Empty Position") {
                                        showUserActivitiesDialog(context, email,
                                            widget.startDate.toDate());
                                      }
                                    },
                                    child: Card(
                                      shape: ShapeBorder.lerp(
                                        RoundedRectangleBorder(
                                          side: BorderSide(
                                              color: cardColor, width: 1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        RoundedRectangleBorder(
                                          side: BorderSide(
                                            color: cardColor,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        0.5,
                                      ),
                                      elevation: 1,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: Row(
                                          children: [
                                            email != "Empty Position"
                                                ? CircleAvatar(
                                                    backgroundColor:
                                                        avatarColor,
                                                    radius:
                                                        10, // Adjust the size of the avatar as needed
                                                  )
                                                : SizedBox.shrink(),
                                            SizedBox(
                                                width:
                                                    8), // Provides some spacing between the avatar and the text
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  getUserName(
                                                      email), // Username or "Empty Slot"
                                                  Text(
                                                    '${(distance / 1000).toStringAsFixed(2)} km',
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            email == widget.challengeCreator
                                                ? Icon(Icons.verified_outlined)
                                                : SizedBox.shrink(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                },
              ),
            ),
          ),
          widget.coopOrComp == "Competitive"
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.teal),
                        foregroundColor:
                            MaterialStateProperty.all(Colors.white),
                      ),
                      onPressed: () {
                        joinTeam(widget.challengeId, widget.coopOrComp);
                      },
                      child: Text('Join a Team'),
                    ),
                  ],
                )
              : SizedBox(),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                      "Click on a participant to view activities contributing to the challenge"),
                ),
              ],
            ),
          ),
        ],
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
              return Column(
                children: [
                  CircularProgressIndicator(),
                  Text('Loading'),
                ],
              );
            }
            print('Number of messages: ${snapshot.data?.docs.length}');

            // Handle message reading logic
            List<DocumentSnapshot> messageDocs = snapshot.data?.docs ?? [];
            updateUnreadStatus(messageDocs);
            _markMessagesAsRead(messageDocs);

            final messages = snapshot.data?.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  Timestamp? timestamp = data['time'] as Timestamp?;

                  // Create a default time if 'time' is null
                  DateTime messageTime =
                      timestamp != null ? timestamp.toDate() : DateTime.now();

                  return ChatMessage(
                    user: data['user'] ?? 'Anonymous',
                    message: data['message'] ?? '',
                    time: messageTime,
                    readBy: data['readBy'] as List? ?? [],
                  );
                }).toList() ??
                [];

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
              teamColor: Colors.primaries[
                  currentUser!.email.hashCode % Colors.primaries.length],
            );
          },
        ),
      ),
    );
  }

  Future<void> joinTeam(String challengeId, String coopOrComp) async {
    String? currentUserEmail = currentUser?.email;
    if (currentUserEmail == null) return;

    // Reference to the challenge document
    DocumentReference challengeRef =
        FirebaseFirestore.instance.collection('Challenges').doc(challengeId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(challengeRef);
      if (!snapshot.exists) {
        throw Exception("Challenge does not exist!");
      }

      // Initialize team1 and team2 if they don't exist
      List<dynamic> team1 =
          (snapshot.data() as Map<String, dynamic>)['team1'] ?? [];
      List<dynamic> team2 =
          (snapshot.data() as Map<String, dynamic>)['team2'] ?? [];

      // Check if the user is already on a team
      if (team1.contains(currentUserEmail) ||
          team2.contains(currentUserEmail)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('You are already on a team.'),
        ));
        return;
      }

      // Check if the challenge is already full
      if (team1.length + team2.length >= 8) {
        print("Challenge is full");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sorry, the challenge is currently full.'),
        ));
        return;
      }

      String selectedTeam = await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return TeamSelectionDialog(
                onTeamSelected: (team) {
                  Navigator.of(context).pop(team);
                },
              );
            },
          ) ??
          'Team 1'; // Default to 'Team 1' if no selection

      if (selectedTeam == 'Team 1') {
        if (team1.length >= 4) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Team 1 is full. How about Team 2?'),
          ));
          return;
        }
        if (!team1.contains(currentUserEmail)) {
          team1.add(currentUserEmail);
          transaction.update(challengeRef, {'team1': team1});
        }
      } else {
        if (team2.length >= 4) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Team 2 is full. How about Team 1?'),
          ));
          return;
        }
        if (!team2.contains(currentUserEmail)) {
          team2.add(currentUserEmail);
          transaction.update(challengeRef, {'team2': team2});
        }
      }
      setState(() {
        team1Emails = team1.cast<String>();
        team2Emails = team2.cast<String>();
      });
    }).catchError((error) {
      print("Failed to join challenge: $error");
    });
  }
}

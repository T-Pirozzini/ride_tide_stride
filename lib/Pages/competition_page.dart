import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:ride_tide_stride/pages/chat_widget.dart';
import 'package:ride_tide_stride/pages/elevation_page.dart';
import 'package:ride_tide_stride/pages/snow_2_surf_page.dart';

class CompetitionPage extends StatefulWidget {
  const CompetitionPage({super.key});

  @override
  State<CompetitionPage> createState() => CompetitionPageState();
}

class CompetitionPageState extends State<CompetitionPage>
    with TickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser;

  final List<String> messages = [];
  final TextEditingController _textController = TextEditingController();

  void _sendMessage(String messageText) async {
    if (messageText.isEmpty) {
      return; // Avoid sending empty messages
    }
    final messageData = {
      'time': FieldValue.serverTimestamp(), // Firestore server timestamp
      'user': currentUser?.email ?? 'Anonymous',
      'message': messageText
    };

    String currentMonthDoc = getFormattedCurrentMonth();

    // Write the message to Firestore
    try {
      await FirebaseFirestore.instance
          .collection('Competitions')
          .doc(currentMonthDoc)
          .collection('messages')
          .add(messageData);

      // setState(() {
      //   // messages.add(messageText);
      // });
    } catch (e) {
      print('Error saving message: $e');
    }
  }

  String getFormattedCurrentMonth() {
    final DateTime currentDateTime = DateTime.now();
    String formattedCurrentMonth =
        DateFormat('MMMM yyyy').format(currentDateTime);
    return formattedCurrentMonth;
  }

  Future<Map<String, dynamic>?> getStravaUserDetails() async {
    if (currentUser?.email == null) {
      return null;
    }

    try {
      final userActivities = await getFilteredActivities();

      if (userActivities.isEmpty) {
        print(
            'No documents found for the user with email: ${currentUser!.email}');
        return null;
      }

      double totalElevation = 0.0;
      for (var doc in userActivities) {
        var data = doc.data() as Map<String, dynamic>;
        // Convert elevation_gain to double no matter what type it is stored as
        var elevationGain = data['elevation_gain'] is int
            ? (data['elevation_gain'] as int).toDouble()
            : (data['elevation_gain'] as double? ?? 0.0);
        totalElevation += elevationGain;
      }

      final userData = {
        'fullname': (userActivities.first.data()
                as Map<String, dynamic>)['fullname'] as String? ??
            '',
        // Force total_elevation to be a double
        'total_elevation': totalElevation,
        'email': currentUser!.email,
      };

      return userData;
    } catch (e) {
      print('Error getting user details: $e');
      return null;
    }
  }

  Future<List<QueryDocumentSnapshot>> getFilteredActivities() async {
    final firstDayOfMonth =
        DateTime(DateTime.now().year, DateTime.now().month, 1);
    final lastDayOfMonth =
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

    // Fetch activities within the date range
    final querySnapshot = await FirebaseFirestore.instance
        .collection('activities')
        .where('start_date',
            isGreaterThanOrEqualTo: firstDayOfMonth.toUtc().toIso8601String())
        .where('start_date',
            isLessThanOrEqualTo: lastDayOfMonth.toUtc().toIso8601String())
        .get();

    // Filter activities by user's email
    final userActivities = querySnapshot.docs
        .where((doc) => doc.data()['user_email'] == currentUser!.email)
        .toList();

    return userActivities;
  }

  Future<bool> checkIfUserIsOnATeam() async {
    String userEmail = currentUser?.email ?? '';
    final competitionDocId = getFormattedCurrentMonth();
    var competitionDoc = FirebaseFirestore.instance
        .collection('Competitions')
        .doc(competitionDocId);

    var snapshot = await competitionDoc.get();
    if (!snapshot.exists) {
      print('Competition document does not exist for $competitionDocId');
      return false;
    }

    var data = snapshot.data() as Map<String, dynamic>;
    List<dynamic> team1 = data['team_1'] ?? [];
    List<dynamic> team2 = data['team_2'] ?? [];

    bool isOnTeam1 = team1.any((member) => member['email'] == userEmail);
    bool isOnTeam2 = team2.any((member) => member['email'] == userEmail);

    return isOnTeam1 || isOnTeam2;
  }

  Color getUserTeamColor() {
    String userEmail = currentUser?.email ?? '';
    bool isOnTeam1 = team1Members.any((member) => member['email'] == userEmail);
    bool isOnTeam2 = team2Members.any((member) => member['email'] == userEmail);

    if (isOnTeam1) {
      return Colors.blue[100]!; // Color for Team 1
    } else if (isOnTeam2) {
      return Colors.lightGreenAccent[100]!; // Color for Team 2
    } else {
      return Colors.grey; // Default color if not on any team
    }
  }

  Future<void> _showTeamChoiceDialog(BuildContext context) async {
    // Check if the user is already on a team
    bool isAlreadyOnATeam = await checkIfUserIsOnATeam();
    if (isAlreadyOnATeam) {
      SnackBar snackBar = SnackBar(
        content: Text('You are already on a team!'),
        duration: Duration(seconds: 2),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Center(child: const Text('Choose a team!')),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () async {
                        Map<String, dynamic>? stravaUsername =
                            await getStravaUserDetails();
                        if (stravaUsername != null) {
                          final competitionsCollection = FirebaseFirestore
                              .instance
                              .collection('Competitions');
                          double updatedElevation =
                              (stravaUsername['total_elevation'] as double? ??
                                      0.0) +
                                  0.2;

                          // Update the user's total elevation
                          stravaUsername['total_elevation'] = updatedElevation;

                          // Only update the team array
                          await competitionsCollection
                              .doc(getFormattedCurrentMonth())
                              .set({
                            'team_1': FieldValue.arrayUnion([stravaUsername]),
                          });
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
                    ElevatedButton(
                      onPressed: () async {
                        Map<String, dynamic>? stravaUsername =
                            await getStravaUserDetails();
                        if (stravaUsername != null) {
                          final competitionsCollection = FirebaseFirestore
                              .instance
                              .collection('Competitions');
                          double updatedElevation =
                              (stravaUsername['total_elevation'] as double? ??
                                      0.0) +
                                  0.2;

                          // Update the user's total elevation
                          stravaUsername['total_elevation'] = updatedElevation;

                          // Only update the team array
                          await competitionsCollection
                              .doc(getFormattedCurrentMonth())
                              .set({
                            'team_2': FieldValue.arrayUnion([stravaUsername]),
                          });
                        }
                        Navigator.of(context).pop();
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
  }

  Stream<QuerySnapshot> getCompetitionsData() {
    return FirebaseFirestore.instance.collection('Competitions').snapshots();
  }

  Stream<QuerySnapshot> listenToActivityChanges() {
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;

    final firstDayOfMonth = DateTime(currentYear, currentMonth, 1);
    final lastDayOfMonth = DateTime(currentYear, currentMonth + 1, 0);

    return FirebaseFirestore.instance
        .collection('activities')
        .where('start_date',
            isGreaterThanOrEqualTo: firstDayOfMonth.toUtc().toIso8601String())
        .where('start_date',
            isLessThanOrEqualTo: lastDayOfMonth.toUtc().toIso8601String())
        .snapshots();
  }

  void processActivityChange(DocumentSnapshot activityDoc) async {
    // Extract user email and elevation gain
    var activityData = activityDoc.data() as Map<String, dynamic>?;

    String userEmail = activityData?['user_email'] as String? ?? '';
    double elevationGain =
        (activityData?['elevation_gain'] as num?)?.toDouble() ?? 0.0;
    print('elevationGain: $elevationGain');

    // Fetch the user's current total elevation and update it
    updateTeamMemberElevation(userEmail);
  }

  late final AnimationController _winningAnimationController;
  bool _hasCheckedWinner = false;
  bool hasJoinedTeam = false;

  List<dynamic> team1Members = [];
  List<dynamic> team2Members = [];

  late StreamSubscription<QuerySnapshot> _activitySubscription;
  Stream<QuerySnapshot>? _messagesStream;

  @override
  void initState() {
    super.initState();
    _winningAnimationController = AnimationController(vsync: this);
    // Fetch and set the competition document for the current month
    final competitionDocId = getFormattedCurrentMonth();
    FirebaseFirestore.instance
        .collection('Competitions')
        .doc(competitionDocId)
        .snapshots()
        .listen((docSnapshot) {
      if (docSnapshot.exists) {
        var data = docSnapshot.data();
        List<dynamic> team1 = data?['team_1'] ?? [];
        List<dynamic> team2 = data?['team_2'] ?? [];
        String userEmail = currentUser?.email ?? '';
        setState(() {
          team1Members = List.from(docSnapshot.data()?['team_1'] ?? []);
          team2Members = List.from(docSnapshot.data()?['team_2'] ?? []);
          hasJoinedTeam = team1.any((member) => member['email'] == userEmail) ||
              team2.any((member) => member['email'] == userEmail);
        });
      }
    });
    if (!_hasCheckedWinner) {
      checkForWinner();
      _hasCheckedWinner = true;
    }

    _activitySubscription =
        listenToActivityChanges().listen((QuerySnapshot snapshot) {
      snapshot.docChanges.forEach((change) {
        if (change.type == DocumentChangeType.added ||
            change.type == DocumentChangeType.modified) {
          // Process the change
          processActivityChange(change.doc);
        }
      });
    });
    _messagesStream = FirebaseFirestore.instance
        .collection('Competitions')
        .doc(getFormattedCurrentMonth())
        .collection('messages')
        .orderBy('time',
            descending: true) // Assuming 'time' is your timestamp field
        .snapshots();
  }

  @override
  void dispose() {
    _winningAnimationController.dispose();
    _hasCheckedWinner = false;
    _activitySubscription.cancel();
    _textController.dispose();
    super.dispose();
  }

  Future<List<QueryDocumentSnapshot>> getActivitiesForUser(
      String userEmail) async {
    final firstDayOfMonth =
        DateTime(DateTime.now().year, DateTime.now().month, 1);
    final lastDayOfMonth =
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

    // Fetch activities within the date range and for the specified user
    final querySnapshot = await FirebaseFirestore.instance
        .collection('activities')
        .where('start_date',
            isGreaterThanOrEqualTo: firstDayOfMonth.toUtc().toIso8601String())
        .where('start_date',
            isLessThanOrEqualTo: lastDayOfMonth.toUtc().toIso8601String())
        .where('user_email', isEqualTo: userEmail)
        .get();

    return querySnapshot.docs;
  }

  void updateTeamMemberElevation(String userEmail) async {
    final competitionDocId = getFormattedCurrentMonth();
    var competitionDoc = FirebaseFirestore.instance
        .collection('Competitions')
        .doc(competitionDocId);

    var snapshot = await competitionDoc.get();

    if (!snapshot.exists) {
      print('Competition document does not exist for $competitionDocId');
      return;
    }

    var userActivities = await getActivitiesForUser(userEmail);

    double totalElevation = 0.0;
    for (var doc in userActivities) {
      var data = doc.data() as Map<String, dynamic>;
      double elevationGain =
          (data['elevation_gain'] as num?)?.toDouble() ?? 0.0;
      totalElevation += elevationGain;
    }

    // Update the total elevation in the Competitions collection
    var data = snapshot.data() as Map<String, dynamic>;
    List<dynamic> team1 = data['team_1'] ?? [];
    List<dynamic> team2 = data['team_2'] ?? [];

    bool updated = false;

    // Update elevation in team 1
    for (var i = 0; i < team1.length; i++) {
      if (team1[i]['email'] == userEmail) {
        team1[i]['total_elevation'] = totalElevation; // Set the total elevation
        updated = true;
        break;
      }
    }

    // Update elevation in team 2 if not updated in team 1
    if (!updated) {
      for (var i = 0; i < team2.length; i++) {
        if (team2[i]['email'] == userEmail) {
          team2[i]['total_elevation'] =
              totalElevation; // Set the total elevation
          break;
        }
      }
    }

    // Write back the updated data
    await competitionDoc.update({'team_1': team1, 'team_2': team2});
  }

  void checkForWinner() {
    double team1TotalElevation = team1Members.fold(
      0.0,
      (sum, member) => sum + (member['total_elevation'] as double? ?? 0.0),
    );

    double team2TotalElevation = team2Members.fold(
      0.0,
      (sum, member) => sum + (member['total_elevation'] as double? ?? 0.0),
    );

    if (team1TotalElevation >= 5000) {
      playWinningAnimation('Team 1');
    } else if (team2TotalElevation >= 5000) {
      playWinningAnimation('Team 2');
    }
  }

  void playWinningAnimation(String winningTeam) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Lottie.asset(
          'assets/lottie/win_animation.json',
          controller: _winningAnimationController,
          onLoaded: (composition) {
            _winningAnimationController
              ..duration = composition
                  .duration // You can set a longer duration here if needed
              ..repeat(); // Make the animation repeat indefinitely
          },
          repeat: true, // Play animation in a loop
          fit: BoxFit.contain, // Make sure the entire animation is visible
        ),
        title: Center(
          child: Text('$winningTeam Wins!',
              style: GoogleFonts.syne(textStyle: TextStyle(fontSize: 32))),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              _winningAnimationController
                  .stop(); // Stop the animation when the dialog is closed
              Navigator.of(context).pop(); // Closes the dialog
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    // Calculate the total elevation for each team
    double team1TotalElevation = team1Members.fold(
      0.0,
      (sum, member) => sum + (member['total_elevation'] as double? ?? 0.0),
    );

    double team2TotalElevation = team2Members.fold(
      0.0,
      (sum, member) => sum + (member['total_elevation'] as double? ?? 0.0),
    );

// Team 1 cumulative percent calculation
    List<Widget> team1Indicators = team1Members.map((member) {
      double membersPercentTeam1 = team1TotalElevation / 5000;
      return CircularPercentIndicator(
        radius: 180.0,
        lineWidth: 10.0,
        percent: membersPercentTeam1 >= 1.0 ? 1.0 : membersPercentTeam1,
        backgroundColor: Colors.grey.shade200,
        progressColor: Colors.lightBlueAccent[member['shade'] as int? ?? 100],
        startAngle: 180,
        circularStrokeCap: CircularStrokeCap.butt,
        reverse: false,
        animation: true,
        animationDuration: 1500,
        footer: Text(team1TotalElevation.toStringAsFixed(0) + ' m'),
      );
    }).toList();

// Team 2 cumulative percent calculation
    List<Widget> team2Indicators = team2Members.map((member) {
      double membersPercentTeam2 = team2TotalElevation / 5000;
      return CircularPercentIndicator(
        radius: 150.0,
        lineWidth: 10.0,
        percent: membersPercentTeam2 >= 1.0 ? 1.0 : membersPercentTeam2,
        backgroundColor: Colors.grey.shade200,
        progressColor: Colors.lightGreenAccent[member['shade'] as int? ?? 100],
        startAngle: 180,
        circularStrokeCap: CircularStrokeCap.butt,
        reverse: true,
        animation: true,
        animationDuration: 1500,
        footer: Text(team2TotalElevation.toStringAsFixed(0) + ' m'),
      );
    }).toList();

    List<Widget> team1MemberLineIndicators =
        team1Members.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> member = entry.value;

      double elevation = member['total_elevation'] as double? ?? 0.0;
      double memberContributionPercent = elevation / team1TotalElevation;
      memberContributionPercent = memberContributionPercent.clamp(0.0, 1.0);

      int shadeIndex = 100 * (index + 1); // Generate 100, 200, ..., 900
      shadeIndex =
          shadeIndex <= 900 ? shadeIndex : 900; // Cap shadeIndex at 900

      // Ensure a non-null color is always assigned
      Color progressColor =
          Colors.lightBlueAccent[shadeIndex] ?? Colors.blue[400]!;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Row(
          children: [
            Text('${member['fullname']}',
                style: GoogleFonts.syne(textStyle: TextStyle(fontSize: 12))),
            Stack(
              children: [
                LinearPercentIndicator(
                  width: MediaQuery.of(context).size.width * 0.3,
                  lineHeight: 10.0,
                  percent: memberContributionPercent,
                  backgroundColor: Colors.grey.shade200,
                  progressColor:
                      progressColor, // Use the computed progress color
                  animation: true,
                  animationDuration: 1500,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.only(left: 4),
                    color: Colors.grey.shade200,
                    child: Text(
                      '${member['total_elevation'].toStringAsFixed(0)} m',
                      style: TextStyle(fontSize: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();

    List<Widget> team2MemberLineIndicators =
        team2Members.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> member = entry.value;

      double elevation = member['total_elevation'] as double? ?? 0.0;
      double memberContributionPercent = elevation / team2TotalElevation;
      memberContributionPercent = memberContributionPercent.clamp(0.0, 1.0);

      int shadeIndex = 100 * (index + 1); // Generate 100, 200, ..., 900
      shadeIndex =
          shadeIndex <= 900 ? shadeIndex : 900; // Cap shadeIndex at 900

      // Ensure a non-null color is always assigned
      Color progressColor =
          Colors.lightGreenAccent[shadeIndex] ?? Colors.lightGreenAccent[400]!;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Row(
          children: [
            Text('${member['fullname']}',
                style: GoogleFonts.syne(textStyle: TextStyle(fontSize: 12))),
            Stack(
              children: [
                LinearPercentIndicator(
                  width: MediaQuery.of(context).size.width * 0.3,
                  lineHeight: 10.0,
                  percent: memberContributionPercent,
                  backgroundColor: Colors.grey.shade200,
                  progressColor:
                      progressColor, // Use the computed progress color
                  animation: true,
                  animationDuration: 1500,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.only(left: 4),
                    color: Colors.grey.shade200,
                    child: Text(
                      '${member['total_elevation'].toStringAsFixed(0)} m',
                      style: TextStyle(fontSize: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();

    return DefaultTabController(
        length: 2,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFDFD3C3),
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: Text(
              'The Challenge Hub',
              style: GoogleFonts.tektur(
                  textStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2)),
            ),
            centerTitle: true,
            bottom: TabBar(
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.landscape_outlined),
                      Text('Mtn Scramble', style: GoogleFonts.tektur()),
                      Icon(Icons.hiking_rounded),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.downhill_skiing),
                      Text(
                        'Snow2Surf',
                        style: GoogleFonts.tektur(),
                      ),
                      Icon(Icons.rowing),
                    ],
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.chat),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
            ],
          ),
          body: TabBarView(
            children: [
              SingleChildScrollView(
                child: StreamBuilder(
                    stream: getCompetitionsData(),
                    // Add stream builder here
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.hasError) {
                        return const Text('Something went wrong');
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Loading');
                      }

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('${getFormattedCurrentMonth()}',
                              style: GoogleFonts.syne(
                                textStyle: TextStyle(fontSize: 20),
                              )),
                          SizedBox(height: 15.0),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Mtn Scramble',
                                style: GoogleFonts.tektur(
                                    textStyle: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold))),
                          ),
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ...team1Indicators,
                                ...team2Indicators,
                                // The mountain image in the center
                                Container(
                                  width: 250,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image:
                                          AssetImage('assets/images/mtn.png'),
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text('Team 1',
                                      style: GoogleFonts.syne(
                                          textStyle: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600))),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      ...team1MemberLineIndicators,
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text('Team 2',
                                      style: GoogleFonts.syne(
                                          textStyle: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600))),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      ...team2MemberLineIndicators,
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              // Place your buttons here
                              ElevatedButton(
                                onPressed: () {
                                  _showTeamChoiceDialog(context);
                                },
                                child: const Text('Join a Team'),
                              ),
                              // ElevatedButton(
                              //   onPressed: () {
                              //     _showProfileDialog(context);
                              //   },
                              //   child: const Text('Show Profile'),
                              // ),
                            ],
                          ),
                        ],
                      );
                    }),
              ),
              Snow2Surf(),
            ],
          ),
          // bottomNavigationBar: BottomAppBar(
          //   color: Colors
          //       .white, // This sets the background color of the BottomAppBar
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //     children: <Widget>[
          //       // Place your buttons here
          //       ElevatedButton(
          //         onPressed: () {
          //           _showTeamChoiceDialog(context);
          //         },
          //         child: const Text('Join a Team'),
          //       ),
          //       ElevatedButton(
          //         onPressed: () {
          //           _showProfileDialog(context);
          //         },
          //         child: const Text('Show Profile'),
          //       ),
          //     ],
          //   ),
          // ),
          endDrawer: Drawer(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Something went wrong');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text('Loading');
                }
                final messages = snapshot.data?.docs
                        .map((doc) =>
                            doc['message'] as String) // Extract 'message' field
                        .toList() ??
                    [];
                return ChatWidget(
                  key: ValueKey(messages.length),
                  messages: messages,
                  currentUserEmail: currentUser?.email ?? '',
                  onSend: (String message) {
                    if (message.isNotEmpty) {
                      _sendMessage(message);
                    }
                  },
                  teamColor: getUserTeamColor(),
                );
              },
            ),
          ),
        ));
  }

  // void _showProfileDialog(context) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return FutureBuilder(
  //         future: Future.wait([
  //           getStravaUserDetails(),
  //         ]),
  //         builder:
  //             (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
  //           if (snapshot.hasError) {
  //             return const Text('Something went wrong');
  //           }
  //           if (snapshot.connectionState == ConnectionState.waiting) {
  //             return const Text('Loading');
  //           }

  //           final userDetails = snapshot.data?[0] as Map<String, dynamic>?;
  //           final fullName = userDetails?['fullname'] as String?;

  //           if (userDetails == null || fullName == null) {
  //             return const Text('No user data found');
  //           }

  //           return FutureBuilder(
  //             future: findHighestAverageWatts(fullName),
  //             builder: (BuildContext context,
  //                 AsyncSnapshot<double?> avgWattsSnapshot) {
  //               if (avgWattsSnapshot.hasError) {
  //                 return const Text('Something went wrong');
  //               }
  //               if (avgWattsSnapshot.connectionState ==
  //                   ConnectionState.waiting) {
  //                 return const Text('Loading');
  //               }

  //               final highestAverageWatts = avgWattsSnapshot.data;

  //               return AlertDialog(
  //                 content: Column(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     Text(fullName,
  //                         style: GoogleFonts.syne(
  //                             textStyle: TextStyle(
  //                                 fontSize: 18,
  //                                 fontWeight: FontWeight.w600,
  //                                 color: Colors.black))),
  //                     ClipOval(
  //                       child: Stack(
  //                         alignment: Alignment.center,
  //                         children: [
  //                           ClipRRect(
  //                             borderRadius: BorderRadius.circular(
  //                                 200), // Adjust the radius value as needed
  //                             child: Container(
  //                               width: 400,
  //                               height: 300,
  //                               decoration: BoxDecoration(
  //                                 image: DecorationImage(
  //                                   image: AssetImage(
  //                                       'assets/images/power_level_3.png'),
  //                                   fit: BoxFit.fitHeight,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                           Positioned(
  //                             bottom: 0,
  //                             left: 0,
  //                             right: 0,
  //                             child: Container(
  //                               padding: EdgeInsets.all(20),
  //                               child: Container(
  //                                 color: Colors.black,
  //                                 child: Column(
  //                                   children: [
  //                                     Text('Power Level',
  //                                         style: GoogleFonts.syne(
  //                                             textStyle: TextStyle(
  //                                                 fontSize: 18,
  //                                                 fontWeight: FontWeight.w600,
  //                                                 color: Colors.white))),
  //                                     Text(
  //                                       '${highestAverageWatts ?? "N/A"}', // Display highest average watts
  //                                       textAlign: TextAlign.center,
  //                                       style: GoogleFonts.syne(
  //                                         textStyle: TextStyle(
  //                                           fontSize: 24,
  //                                           fontWeight: FontWeight.w600,
  //                                           color: Colors.white,
  //                                         ),
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 actions: <Widget>[
  //                   TextButton(
  //                     child: const Text('Close'),
  //                     onPressed: () {
  //                       Navigator.of(context).pop();
  //                     },
  //                   ),
  //                 ],
  //               );
  //             },
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  // Future<double?> findHighestAverageWatts(String fullName) async {
  //   final snapshot = await FirebaseFirestore.instance
  //       .collection('activities')
  //       .where('fullname', isEqualTo: fullName)
  //       .get();

  //   final activities =
  //       snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

  //   if (activities.isEmpty) {
  //     return null; // No activities found for the user
  //   }

  //   double? highestAverageWatts;

  //   for (final activity in activities) {
  //     final averageWatts = activity['average_watts'] as double?;

  //     if (averageWatts != null) {
  //       if (highestAverageWatts == null || averageWatts > highestAverageWatts) {
  //         highestAverageWatts = averageWatts;
  //       }
  //     }
  //   }

  //   return highestAverageWatts;
  // }
}

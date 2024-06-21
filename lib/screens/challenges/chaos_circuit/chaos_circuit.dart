import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_tide_stride/models/chat_message.dart';
import 'package:ride_tide_stride/providers/challenge_provider.dart';
import 'package:ride_tide_stride/providers/opponent_provider.dart';
import 'package:ride_tide_stride/screens/challenges/chaos_circuit/matchup_display.dart';
import 'package:ride_tide_stride/screens/challenges/chaos_circuit/taunt_display.dart';
import 'package:ride_tide_stride/screens/challenges/chaos_circuit/track_component.dart';
import 'package:ride_tide_stride/screens/chat/chat_widget.dart';
import 'package:ride_tide_stride/screens/leaderboard/timer.dart';
import 'package:ride_tide_stride/theme.dart';
import 'package:badges/badges.dart' as badges;

class ChaosCircuit extends ConsumerStatefulWidget {
  final String challengeId;

  const ChaosCircuit({
    super.key,
    required this.challengeId,
  });

  @override
  _ChaosCircuitState createState() => _ChaosCircuitState();
}

class _ChaosCircuitState extends ConsumerState<ChaosCircuit> {
  final GlobalKey<ScaffoldState> _chaosCircuitScaffoldKey =
      GlobalKey<ScaffoldState>();
  final currentUser = FirebaseAuth.instance.currentUser;
  bool unread = false;
  int unreadMessageCount = 0;
  List<String> team1Emails = [];
  Stream<QuerySnapshot>? _messagesStream;

  @override
  void initState() {
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
    super.initState();
  }

  void _sendMessage(String messageText) async {
    if (messageText.isEmpty) {
      return; // Avoid sending empty messages
    }
    final messageData = {
      'time': FieldValue.serverTimestamp(), // Firestore server timestamp
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

      if (data != null && data.containsKey('participants')) {
        team1Emails = List<String>.from(data['participants']).take(4).toList();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final opponents = ref.watch(opponentsProvider);
    final challengeDetails =
        ref.watch(challengeDetailsProvider(widget.challengeId));

    return challengeDetails.when(
      data: (challenge) {
        final participantEmails = challenge.participantsEmails;
        final challengeTimestamp = challenge.timestamp;
        final challengeCategory = challenge.category;
        final challengeCategoryActivity = challenge.categoryActivity;
        final endTime = challengeTimestamp
            .toDate()
            .add(Duration(days: 30))
            .millisecondsSinceEpoch;

        return Scaffold(
          key: _chaosCircuitScaffoldKey, 
          backgroundColor: AppColors.primaryAccent,
          appBar: AppBar(
            centerTitle: true,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      'Chaos Circuit',
                      style: GoogleFonts.tektur(
                          textStyle: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1.2)),
                    ),
                    SizedBox(width: 8),
                    challengeCategory == "Specific"
                        ? Icon(
                            challengeCategoryActivity == "Running"
                                ? Icons.directions_run
                                : challengeCategoryActivity == "Cycling"
                                    ? Icons.directions_bike
                                    : challengeCategoryActivity == "Paddling"
                                        ? Icons.kayaking
                                        : Icons.directions_walk, 
                          )
                        : SizedBox.shrink(),
                  ],
                )
              ],
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
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
                  _chaosCircuitScaffoldKey.currentState?.openEndDrawer();
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                CountdownTimerWidget(endTime: endTime, onTimerEnd: () {}),
                Container(
                  color: AppColors.primaryAccent,
                  height: 300,
                  child: MatchupDisplay(challengeId: widget.challengeId),
                ),
                Container(
                  height: 100,
                  margin: const EdgeInsets.all(8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TauntDisplay(
                          participantEmails: participantEmails,
                          challengeDifficulty: challenge.difficulty),
                    ),
                  ),
                ),
                Container(
                  height: 600,
                  child: TrackComponent(
                    participantEmails: participantEmails,
                    timestamp: challengeTimestamp,
                    challengeId: widget.challengeId,
                    difficulty: challenge.difficulty,
                    category: challengeCategory,
                    categoryActivity: challengeCategoryActivity,
                  ),
                ),
              ],
            ),
          ),
          endDrawer: Drawer(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
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

                // Handle message reading logic
                List<DocumentSnapshot> messageDocs = snapshot.data?.docs ?? [];
                updateUnreadStatus(messageDocs);
                _markMessagesAsRead(messageDocs);

                final messages = snapshot.data?.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      Timestamp? timestamp = data['time'] as Timestamp?;

                      // Create a default time if 'time' is null
                      DateTime messageTime = timestamp != null
                          ? timestamp.toDate()
                          : DateTime.now();

                      return ChatMessage(
                        user: data['user'] ?? 'Anonymous',
                        message: data['message'] ?? '',
                        time: messageTime,
                        readBy: data['readBy'] as List? ?? [],
                      );
                    }).toList() ??
                    [];
                final participantColors = {
                  for (var email in team1Emails)
                    email: Colors.primaries[
                        Random(email.hashCode).nextInt(Colors.primaries.length)]
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
                  teamColor: Colors.primaries[
                      currentUser!.email.hashCode % Colors.primaries.length],
                );
              },
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Loading...'),
        ),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Error'),
        ),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TalkSmack extends StatefulWidget {
  const TalkSmack({Key? key}) : super(key: key);

  @override
  _TalkSmackState createState() => _TalkSmackState();
}

class _TalkSmackState extends State<TalkSmack> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = [];
  final currentUser = FirebaseAuth.instance.currentUser;
  final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      await FirebaseFirestore.instance.collection('SmackTalk').add({
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'user': currentUser?.email,
      });
      _messageController.clear();

      // Scroll to the bottom of the ListView
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String _formatTimestamp(Timestamp? timestamp) {
      if (timestamp == null) {
        return 'Unknown';
      }

      final now = DateTime.now();
      final difference = now.difference(timestamp.toDate());

      if (difference.inDays > 0) {
        return DateFormat.yMMMd().format(timestamp.toDate());
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inMinutes}m ago';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFDFD3C3),
      appBar: AppBar(
        title: Text(
          'Chat Room: Talk Smack',
          style: GoogleFonts.tektur(
              textStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.2)),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('SmackTalk')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                var messages = snapshot.data?.docs;

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: messages?.length,
                  itemBuilder: (context, index) {
                    var messageData = messages?[index].data();
                    var message = messageData?['message'];
                    var user = messageData?['user'].split('@')[0];
                    var timestamp = messageData?['timestamp'] as Timestamp?;
                    bool isCurrentUser = user ==
                        currentUserEmail?.split(
                            '@')[0]; // assuming you have current user's email

                    // Calculate how many minutes ago
                    var timeAgo = _formatTimestamp(timestamp);

                    return Padding(
                      padding: const EdgeInsets.only(
                        left: 12.0,
                        right: 12.0,
                        top: 4.0,
                        bottom: 4.0,
                      ),
                      child: Column(
                        crossAxisAlignment: isCurrentUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? Color.fromARGB(255, 86, 141, 135)
                                  : Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                              borderRadius: isCurrentUser
                                  ? BorderRadius.only(
                                      topLeft: Radius.circular(15),
                                      bottomLeft: Radius.circular(15),
                                      topRight: Radius.circular(15),
                                    )
                                  : BorderRadius.only(
                                      topRight: Radius.circular(15),
                                      bottomRight: Radius.circular(15),
                                      topLeft: Radius.circular(15),
                                    ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10.0,
                              horizontal: 16.0,
                            ),
                            child: Column(
                              crossAxisAlignment: isCurrentUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                isCurrentUser
                                    ? Text(user,
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold))
                                    : Text(user,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text(
                                  message ?? '',
                                  style: TextStyle(
                                    color: isCurrentUser
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 5.0),
                                Text(
                                  timeAgo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: isCurrentUser
                                        ? Colors.white.withOpacity(0.7)
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
            child: Material(
              color: Colors.white,
              elevation: 2,
              borderRadius: BorderRadius.circular(25.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Enter a message',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.teal[400],
                    onPressed: _sendMessage,
                    child: Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

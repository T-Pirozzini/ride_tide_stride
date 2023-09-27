import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_countdown_timer/index.dart';
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

  void _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      await FirebaseFirestore.instance.collection('SmackTalk').add({
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'user': currentUser?.email,
      });
      _messageController.clear();
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
        title: const Text(
          'Talk Smack Chat Room',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w300, letterSpacing: 1.2),
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
                  itemCount: messages?.length,
                  itemBuilder: (context, index) {
                    var messageData = messages?[index].data();
                    var message = messageData?['message'];
                    var user = messageData?['user'];
                    var timestamp = messageData?['timestamp'] as Timestamp?;

                    // Calculate how many minutes ago
                    var timeAgo = _formatTimestamp(timestamp);

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 5.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: ListTile(
                        title: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$user',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            SizedBox(height: 5.0),
                            Text('$message',
                                style: const TextStyle(fontSize: 18)),
                            SizedBox(height: 5.0),
                          ],
                        ),
                        subtitle: Text(timeAgo),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Enter a message',
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

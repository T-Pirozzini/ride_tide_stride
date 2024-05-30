import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ride_tide_stride/models/chat_message.dart';

import 'package:timeago/timeago.dart' as TimeAgo;

class ChatWidget extends StatefulWidget {
  final Function(String) onSend;
  // final List<String> messages;
  final List<ChatMessage> messages;
  final String? currentUserEmail;
  final Color teamColor;
  final Map<String, Color> participantColors;

  const ChatWidget(
      {Key? key,
      required this.onSend,
      required this.messages,
      required this.currentUserEmail,
      required this.teamColor,
      required this.participantColors})
      : super(key: key);

  @override
  _ChatWidgetState createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _textController = TextEditingController();

  void _sendMessage() {
    widget.onSend(_textController.text);
    _textController.clear();
  }

  Widget getUserName(String email) {
    // Proceed with fetching the username
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('Users').doc(email).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Loading...");
        }
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return Text(email);
        }
        var data = snapshot.data!.data() as Map<String, dynamic>;
        return Text(data['username'] ?? email);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: widget.messages.length,
            itemBuilder: (context, index) {
              ChatMessage message = widget.messages[index];

              final username = getUserName(message.user);

              return Column(
                children: [
                  ListTile(
                    title: Text(message.message),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        username,
                        Text(TimeAgo.format(message.time),
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          widget.participantColors[message.user] ?? Colors.grey,
                    ),
                  ),
                  Divider(),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      labelText: 'Type a message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

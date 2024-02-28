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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: widget.messages.length,
            itemBuilder: (context, index) {
              ChatMessage message = widget.messages[index];

              return ListTile(
                title: Text(message.message),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      message.user,
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(TimeAgo.format(message.time),
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
                leading: CircleAvatar(
                  backgroundColor:
                      widget.participantColors[message.user] ?? Colors.grey,
                  child: Text(
                    message.user.isNotEmpty
                        ? message.user[0].toUpperCase()
                        : '',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
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

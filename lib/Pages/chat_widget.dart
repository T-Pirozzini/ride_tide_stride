import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as TimeAgo;

class ChatWidget extends StatefulWidget {
  final Function(String) onSend;
  final List<String> messages;
  final String? currentUserEmail;
  final Color teamColor;

  const ChatWidget(
      {Key? key,
      required this.onSend,
      required this.messages,
      required this.currentUserEmail,
      required this.teamColor})
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
              String userEmail = widget.currentUserEmail!.split('@')[0];
              DateTime messageTime =
                  DateTime.now().subtract(Duration(minutes: index));

              return ListTile(
                title: Text(widget.messages[index]),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      userEmail,
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(TimeAgo.format(messageTime),
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
                leading: CircleAvatar(
                  backgroundColor: widget.teamColor,
                  child: Text(
                    widget.currentUserEmail!.isNotEmpty
                        ? widget.currentUserEmail![0].toUpperCase()
                        : '',
                    style: TextStyle(
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

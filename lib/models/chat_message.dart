class ChatMessage {
  final String message;
  final String user;
  final DateTime time;
  final List readBy;

  ChatMessage({required this.message, required this.user, required this.time, required this.readBy});
}

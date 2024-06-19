class ParticipantActivity {
  final dynamic email;
  final String date;
  final double totalDistance;
  final int activityCount;
  final bool isOpponent;
  final String? avatarUrl; 

  ParticipantActivity({
    required this.email,
    required this.date,
    required this.totalDistance,
    required this.activityCount,
    this.isOpponent = false,
    this.avatarUrl,
  });
}
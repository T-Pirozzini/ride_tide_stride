import 'package:cloud_firestore/cloud_firestore.dart';

Future<String> getUserNameString(String email) async {
  // Check if email is "Empty Slot", and avoid fetching from Firestore
  if (email == "Empty Slot") {
    return email;
  }

  // Proceed with fetching the username
  DocumentSnapshot snapshot =
      await FirebaseFirestore.instance.collection('Users').doc(email).get();
  if (!snapshot.exists || snapshot.data() == null) {
    return email;
  }
  var data = snapshot.data() as Map<String, dynamic>;
  return data['username'] ?? email;
}

// Utility method to parse "HH:MM:SS" or "MM:SS" to seconds
int parseTimeToSeconds(String timeStr) {
  List<int> parts = timeStr.split(':').map(int.parse).toList();
  if (parts.length == 3) {
    return parts[0] * 3600 + parts[1] * 60 + parts[2];
  } else if (parts.length == 2) {
    return parts[0] * 60 + parts[1];
  }
  return 0; // Return zero if the format doesn't match expected patterns
}

String calculateBestTime(double distanceInMeters, double averageSpeed) {
  if (averageSpeed == 0) return 'N/A'; // Avoid division by zero
  int totalSeconds = (distanceInMeters / averageSpeed).round();
  int hours = totalSeconds ~/ 3600;
  int minutes = (totalSeconds % 3600) ~/ 60;
  int seconds = totalSeconds % 60;

  // Format the time as HH:MM:SS
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

Future<String> getUsername(String userEmail) async {
  try {
    final DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userEmail)
        .get();

    // Cast the userDoc.data() to Map<String, dynamic> before using containsKey.
    final userData = userDoc.data() as Map<String, dynamic>?;

    if (userDoc.exists &&
        userData != null &&
        userData.containsKey('username')) {
      return userData['username'] ?? 'No participant';
    } else {
      return 'No username';
    }
  } catch (e) {
    print("Error getting username: $e");
    return 'No username';
  }
}

Duration parseBestTime(String bestTime) {
  List<String> parts = bestTime.split(':');
  return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: int.parse(parts[2]));
}

// Helper function to format time in seconds into a readable string
String formatTime(double seconds) {
  int hours = seconds ~/ 3600;
  int minutes = ((seconds % 3600) ~/ 60);
  int remainingSeconds = seconds.toInt() % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
}

String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
}

String formatDurationSeconds(int seconds) {
  final Duration duration = Duration(seconds: seconds);
  final int hours = duration.inHours;
  final int minutes = (duration.inMinutes % 60);
  final int remainingSeconds = (duration.inSeconds % 60);
  return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
}

DateTime getStartOfMonth() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
}

DateTime getEndOfMonth() {
  final now = DateTime.now();
  return DateTime(now.year, now.month + 1, 1).subtract(Duration(seconds: 1));
}

String formatDateTimeToIso8601(DateTime dateTime) {
  return dateTime.toUtc().toIso8601String();
}

String formatMovingTime(double seconds) {
  int hours = seconds ~/ 3600;
  int minutes = ((seconds % 3600) ~/ 60);
  return '${hours.toString().padLeft(2)}h ${minutes.toString().padLeft(2, '0')}m';
}

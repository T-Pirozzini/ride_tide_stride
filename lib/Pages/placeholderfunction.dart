// double totalTime = 0.0;
//   void calculateTotalTime(
//       cumulativeTimes, totalTimeInSeconds, displayName, category) {
//     print(totalTimeInSeconds);
//     // double _time = 0;
//     String bestTime = formatTime(totalTimeInSeconds);

//     totalTime += totalTimeInSeconds;

//     print(displayName +
//         category +
//         totalTime.toString() +
//         totalTimeInSeconds.toString());
//     calculateCumulativeTime(totalTime, bestTime, displayName, category);
//   }

//   Future<void> calculateCumulativeTime(
//       totalTime, bestTime, displayName, category) async {
//     String formattedTotalTime = formatTime(totalTime);

//     // Retrieve the current value from Firestore
//     DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
//         .instance
//         .collection('Competitions')
//         .doc(formattedCurrentMonth)
//         .get();

//     // Update Firestore document with new fields
//     await FirebaseFirestore.instance
//         .collection('Competitions')
//         .doc(formattedCurrentMonth)
//         .set({
//       category: {
//         'user': displayName,
//         'time': bestTime,
//         'totalTime': formattedTotalTime,
//         'date': DateTime.now(),
//       }
//     }, SetOptions(merge: true)); // Merge with existing data

//     // // Extract the current Snow2SurfTotalTime from the snapshot
//     // String? currentSnow2SurfTotalTime = snapshot.data()?['Snow2SurfTotalTime'];

//     // // Check if the times are different and update if necessary
//     // if (formattedTime != currentSnow2SurfTotalTime) {
//     //   await FirebaseFirestore.instance
//     //       .collection('Competitions')
//     //       .doc(formattedCurrentMonth)
//     //       .update({'Snow2SurfTotalTime': formattedTime});
//     // }
//   }

//   Future<String> fetchTotalTime() async {
//     try {
//       DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
//           .instance
//           .collection('Competitions')
//           .doc(formattedCurrentMonth)
//           .get();

//       String? fetchedTotalTime = snapshot.data()?['Snow2SurfTotalTime'];
//       return fetchedTotalTime ?? "0:00";
//     } catch (e) {
//       print("Error fetching total time: $e");
//       return "0:00";
//     }
//   }

//   void getTopTimes() async {
//     DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
//         .instance
//         .collection('Competitions')
//         .doc(formattedCurrentMonth)
//         .get();

//     List<dynamic> topTimes = snapshot.data()?['Snow2SurfTopTimes'];
//     print(topTimes);
//   }

//   Stream<QuerySnapshot> getCurrentMonthData() {
//     final currentMonth = DateTime.now().month;
//     final currentYear = DateTime.now().year;

//     final firstDayOfMonth = DateTime(currentYear, currentMonth, 1);
//     final lastDayOfMonth = DateTime(currentYear, currentMonth + 1, 0);

//     return FirebaseFirestore.instance
//         .collection('activities')
//         .where('start_date',
//             isGreaterThanOrEqualTo: firstDayOfMonth.toUtc().toIso8601String())
//         .where('start_date',
//             isLessThanOrEqualTo: lastDayOfMonth.toUtc().toIso8601String())
//         .snapshots();
//   }

//   void updateFirestoreWithTotalTimes() {
//     // Logic to sum up times and update Firestore
//   }

// calculateTotalTime(cumulativeTimes, totalTimeInSeconds,
                        //     displayName, categories[index]['name']);


// FutureBuilder<String>(
//                 future: fetchTotalTime(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return CircularProgressIndicator();
//                   }
//                   if (snapshot.hasError) {
//                     return Text("Error: ${snapshot.error}");
//                   }
//                   return Text("Total Time: ${snapshot.data}",
//                       style:
//                           TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
//                 },
//               ),
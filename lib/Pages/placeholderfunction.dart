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




 // Future<Set<String>> getSelectedLegs() async {
  //   String userEmail = currentUser?.email ?? '';
  //   final competitionDocId = formattedCurrentMonth;
  //   var competitionDoc = FirebaseFirestore.instance
  //       .collection('Competitions')
  //       .doc(competitionDocId);

  //   var snapshot = await competitionDoc.get();
  //   if (snapshot.exists) {
  //     var data = snapshot.data() as Map<String, dynamic>;
  //     var usersData = data['users'] ?? {};
  //     var userData = usersData[userEmail] ?? {};
  //     List<dynamic> selectedLegs = userData['selected_legs'] ?? [];
  //     return selectedLegs
  //         .map<String>((leg) => leg.toString().split(' - ')[1])
  //         .toSet();
  //   }
  //   return {};
  // }

  // Future<void> _showLegsChoiceDialog(BuildContext context) async {
  //   bool hasAlreadySelectedLegs = await checkIfUserAlreadSelectedLegs();
  //   if (hasAlreadySelectedLegs) {
  //     SnackBar snackBar = SnackBar(
  //       content: Text('You already selected legs this month!'),
  //       duration: Duration(seconds: 2),
  //     );
  //     ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //     return;
  //   }
  //   Set<String> selectedLegs = {};
  //   Set<String> selectedTypes = {};

  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //           builder: (BuildContext context, StateSetter setState) {
  //         return AlertDialog(
  //           title: Center(child: const Text('Select up to 3 legs!')),
  //           content: SingleChildScrollView(
  //             child: ListBody(
  //               children: categories.asMap().entries.map((entry) {
  //                 int index = entry.key;
  //                 Map<String, dynamic> category = entry.value;
  //                 String legTitle = 'Leg ${index + 1} - ${category['name']}';

  //                 return CheckboxListTile(
  //                   title: Text(legTitle, style: TextStyle(fontSize: 12)),
  //                   value: selectedLegs.contains(legTitle),
  //                   onChanged: (bool? value) {
  //                     setState(() {
  //                       // Add this call to setState
  //                       if (value == true) {
  //                         if (selectedLegs.length < 3) {
  //                           // Check for running or biking category conflict
  //                           if ((selectedTypes.contains('Run') &&
  //                                   category['type'].contains('Run')) ||
  //                               (selectedTypes.contains('Ride') &&
  //                                   category['type'].contains('Ride'))) {
  //                             ScaffoldMessenger.of(context).showSnackBar(
  //                               SnackBar(
  //                                 content: Text(
  //                                     'Cannot select two legs of the same type (Run or Ride).'),
  //                                 duration: Duration(seconds: 3),
  //                               ),
  //                             );
  //                             return;
  //                           }

  //                           selectedLegs.add(legTitle);
  //                           category['type']
  //                               .forEach((type) => selectedTypes.add(type));
  //                         }
  //                       } else {
  //                         selectedLegs.remove(legTitle);
  //                         category['type']
  //                             .forEach((type) => selectedTypes.remove(type));
  //                       }
  //                     });
  //                   },
  //                 );
  //               }).toList(),
  //             ),
  //           ),
  //           actions: <Widget>[
  //             ElevatedButton(
  //               child: Text('Submit'),
  //               onPressed: () {
  //                 submitUserLegs(selectedLegs);
  //                 Navigator.of(context).pop();
  //               },
  //             ),
  //           ],
  //         );
  //       });
  //     },
  //   );
  // }

  // void submitUserLegs(Set<String> selectedLegs) async {
  //   String userEmail = currentUser?.email ?? '';
  //   final competitionDocId = formattedCurrentMonth;
  //   var competitionDoc = FirebaseFirestore.instance
  //       .collection('Competitions')
  //       .doc(competitionDocId);

  //   await competitionDoc.set({
  //     'users': {
  //       userEmail: {
  //         'selected_legs': selectedLegs.toList(),
  //         'hasCompletedSelection': true,
  //       },
  //     },
  //   }, SetOptions(merge: true));
  // }

  // Future<bool> checkIfUserAlreadSelectedLegs() async {
  //   String userEmail = currentUser?.email ?? '';
  //   final competitionDocId = formattedCurrentMonth;
  //   var competitionDoc = FirebaseFirestore.instance
  //       .collection('Competitions')
  //       .doc(competitionDocId);

  //   var snapshot = await competitionDoc.get();
  //   if (!snapshot.exists) {
  //     print('Competition document does not exist for $competitionDocId');
  //     return false;
  //   }

  //   var data = snapshot.data() as Map<String, dynamic>;
  //   var usersData = data['users'] ?? {};
  //   var userData = usersData[userEmail] ?? {};

  //   return userData['hasCompletedSelection'] ?? false;
  // }

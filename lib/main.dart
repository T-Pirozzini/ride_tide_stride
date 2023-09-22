import 'dart:async';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
import 'package:ride_tide_stride/auth/auth_page.dart';
// import 'package:ride_tide_stride/Components/map.dart';
// import 'package:ride_tide_stride/pages/leaderboard_page.dart';
import 'package:ride_tide_stride/firebase_options.dart';
// import 'auth/authentication.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:intl/intl.dart';
// import 'package:strava_client/strava_client.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'secret.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // int _selectedIndex = 0;

  // void _onItemTapped(int index) {
  //   setState(() {
  //     _selectedIndex = index;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: MaterialColor(0xFF283D3B, <int, Color>{
          50: Color(0xFFA09A6A),
          100: Color(0xFFA09A6A),
          200: Color(0xFFA09A6A),
          300: Color(0xFFA09A6A),
          400: Color(0xFFA09A6A),
          500: Color(0xFFA09A6A),
          600: Color(0xFFA09A6A),
          700: Color(0xFFA09A6A),
          800: Color(0xFFA09A6A),
          900: Color(0xFFA09A6A),
        }), // Define your primary color here
        buttonTheme: ButtonThemeData(
          buttonColor: Color(0xFFD0B8A8), // Set the button color here
        ),
      ),
      title: 'Flutter Strava Plugin',
      home: const AuthPage(),
      // Scaffold(
      //   appBar: AppBar(
      //     title: Text("Hey {username}. Get after it!",
      //         style: GoogleFonts.specialElite(fontWeight: FontWeight.w300)),
      //   ),
      //   body: IndexedStack(
      //     index: _selectedIndex,
      //     children: [
      //       Builder(
      //         builder: (BuildContext context) => StravaFlutterPage(),
      //       ),
      //       Builder(
      //         builder: (BuildContext context) => Leaderboard(),
      //       ),
      //     ],
      //   ),
      //   bottomNavigationBar: BottomNavigationBar(
      //     items: const <BottomNavigationBarItem>[
      //       BottomNavigationBarItem(
      //         icon: Icon(Icons.home),
      //         label: 'Strava',
      //       ),
      //       BottomNavigationBarItem(
      //         icon: Icon(Icons.leaderboard),
      //         label: 'Leaderboard',
      //       ),
      //     ],
      //     currentIndex: _selectedIndex,
      //     onTap: _onItemTapped,
      //   ),
      // ),
    );
  }
}

// class StravaFlutterPage extends StatefulWidget {
//   @override
//   _StravaFlutterPageState createState() => _StravaFlutterPageState();
// }

// class _StravaFlutterPageState extends State<StravaFlutterPage> {
//   final TextEditingController _textEditingController = TextEditingController();
//   final DateFormat dateFormatter = DateFormat("HH:mm:ss");
//   late final StravaClient stravaClient;
//   Map<String, dynamic>? athleteData;
//   Map<String, dynamic>? athleteActivityData;
//   List<dynamic>? athleteActivities;

//   bool isLoggedIn = false;
//   TokenResponse? token;

//   @override
//   void initState() {
//     signInWithFirebase();
//     stravaClient = StravaClient(secret: secret, clientId: clientId);
//     super.initState();
//     if (token != null) {
//       _textEditingController.text = token!.accessToken;
//     }
//   }

//   Future<void> signInWithFirebase() async {
//     try {
//       final UserCredential userCredential =
//           await FirebaseAuth.instance.signInAnonymously();
//       final User? user = userCredential.user;
//       print('User signed in: ${user?.uid}');
//     } catch (e) {
//       print('Error signing in: $e');
//     }
//   }

//   FutureOr<Null> showErrorMessage(dynamic error, dynamic stackTrace) {
//     if (error is Fault) {
//       showDialog(
//           context: context,
//           builder: (context) {
//             return AlertDialog(
//               title: Text("Did Receive Fault"),
//               content: Text(
//                   "Message: ${error.message}\n-----------------\nErrors:\n${(error.errors ?? []).map((e) => "Code: ${e.code}\nResource: ${e.resource}\nField: ${e.field}\n").toList().join("\n----------\n")}"),
//             );
//           });
//     }
//   }

//   void testAuthentication() {
//     ExampleAuthentication(stravaClient).testAuthentication(
//       [
//         AuthenticationScope.profile_read_all,
//         AuthenticationScope.read_all,
//         AuthenticationScope.activity_read_all,
//       ],
//       "com.example.flutter://localhost", // Use your custom scheme here
//     ).then((token) {
//       setState(() {
//         isLoggedIn =
//             true; // Set isLoggedIn to true when authentication is successful
//         this.token = token;
//         _textEditingController.text = token.accessToken;
//       });

//       // After authentication, you can fetch athlete data or perform other actions.
//       fetchAthleteData(token.accessToken).catchError(showErrorMessage);
//     }).catchError(showErrorMessage);
//   }

//   void testDeauth() {
//     ExampleAuthentication(stravaClient).testDeauthorize().then((value) {
//       setState(() {
//         isLoggedIn = false;
//         this.token = null;
//         _textEditingController.clear();
//       });
//     }).catchError(showErrorMessage);
//   }

//   Future<void> fetchAthleteData(String accessToken) async {
//     final url = Uri.parse('https://www.strava.com/api/v3/athlete');
//     final headers = {
//       'Authorization': 'Bearer $accessToken',
//     };

//     try {
//       final response = await http.get(url, headers: headers);

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> data = json.decode(response.body);
//         setState(() {
//           athleteData = data;
//         });
//       } else {
//         // Handle the error
//         print(
//             'Failed to fetch athlete data. Status code: ${response.statusCode}');
//       }
//     } catch (error) {
//       print('Error fetching athlete data: $error');
//     }
//   }

//   Future<void> fetchAthleteActivityData(String accessToken) async {
//     final url = Uri.parse('https://www.strava.com/api/v3/athlete/activities');
//     final headers = {
//       'Authorization': 'Bearer $accessToken',
//     };

//     try {
//       final response = await http.get(url, headers: headers);

//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body);
//         setState(() {
//           athleteActivities = data;
//         });
//       } else {
//         // Handle the error
//         print(
//             'Failed to fetch athlete activities. Status code: ${response.statusCode}');
//       }
//     } catch (error) {
//       print('Error fetching athlete activities: $error');
//     }
//   }

//   String formatDuration(int seconds) {
//     final Duration duration = Duration(seconds: seconds);
//     final int hours = duration.inHours;
//     final int minutes = (duration.inMinutes % 60);
//     final int remainingSeconds = (duration.inSeconds % 60);
//     return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFFDFD3C3),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         toolbarHeight: 100,
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Image.asset("assets/RideTideStride.png", height: 150),
//           ],
//         ),
//         actions: [
//           Icon(
//             isLoggedIn
//                 ? Icons.radio_button_checked_outlined
//                 : Icons.radio_button_off,
//             color: isLoggedIn ? Color(0xFF283D3B) : Color(0xFFA09A6A),
//           ),
//           const SizedBox(
//             width: 8,
//           )
//         ],
//       ),
//       body: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _login(),
//               ElevatedButton(
//                 onPressed: () {
//                   if (token != null) {
//                     fetchAthleteData(token!.accessToken);
//                   } else {
//                     // Handle the case when token is null (e.g., show an error message).
//                     // You can display a message to the user or take appropriate action.
//                   }
//                 },
//                 child: Text("Get Logged In Athlete Data"),
//               ),
//               if (athleteData != null)
//                 Column(
//                   children: [
//                     Text('ID: ${athleteData!['id']}'),
//                     Text('Username: ${athleteData!['username']}'),
//                     Text('Firstname: ${athleteData!['firstname']}'),
//                     Text('Lastname: ${athleteData!['lastname']}'),
//                     Text('City: ${athleteData!['city']}'),
//                     Text('State: ${athleteData!['state']}'),
//                     Text('followers: ${athleteData!['follower_count']}'),
//                     Text(
//                         'mutual followers: ${athleteData!['mutual_friend_count']}'),

//                     // Add more athlete data as needed
//                   ],
//                 ),
//               ElevatedButton(
//                 onPressed: () {
//                   if (token != null) {
//                     fetchAthleteActivityData(token!.accessToken);
//                   } else {
//                     // Handle the case when token is null (e.g., show an error message).
//                   }
//                 },
//                 child: Text("Get Athlete Activity Data"),
//               ),
//               if (athleteActivities != null)
//                 Column(
//                   children: [
//                     ListView.builder(
//                       shrinkWrap: true,
//                       itemCount: athleteActivities!.length,
//                       itemBuilder: (context, index) {
//                         final activity = athleteActivities![index];
//                         final int movingTimeSeconds = activity['moving_time'];

//                         // Add a button for submission
//                         return Column(
//                           children: [
//                             ListTile(
//                               title: Text('Activity ID: ${activity['id']}'),
//                               subtitle: Text('Name: ${activity['name']}'),
//                               trailing: Text(
//                                 'Moving Time: ${formatDuration(movingTimeSeconds)}',
//                               ),
//                             ),
//                             ElevatedButton(
//                               onPressed: () {
//                                 // Call a function to submit activity data to Firestore
//                                 submitActivityToFirestore(
//                                     activity, athleteData!);
//                               },
//                               child: Text("Submit to Firestore"),
//                             ),
//                             const Divider(),
//                           ],
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _login() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             ElevatedButton(
//               child: Text("Login With Strava"),
//               onPressed: testAuthentication,
//             ),
//             ElevatedButton(
//               child: Text("De Authorize"),
//               onPressed: testDeauth,
//             )
//           ],
//         ),
//         const SizedBox(
//           height: 8,
//         ),
//         TextField(
//           minLines: 1,
//           maxLines: 3,
//           controller: _textEditingController,
//           decoration: InputDecoration(
//               border: OutlineInputBorder(),
//               label: Text("Access Token"),
//               suffixIcon: TextButton(
//                 child: Text("Copy"),
//                 onPressed: () {
//                   Clipboard.setData(
//                           ClipboardData(text: _textEditingController.text))
//                       .then((value) =>
//                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                             content: Text("Copied!"),
//                           )));
//                 },
//               )),
//         ),
//         Text('Access ID#: ${_textEditingController.text}'),
//         const Divider(),
//         // MapRouteWidget(activityData: activityData),
//       ],
//     );
//   }

//   void submitActivityToFirestore(
//       Map<String, dynamic> activity, Map<String, dynamic> athlete) {
//     final CollectionReference activitiesCollection = FirebaseFirestore.instance
//         .collection(
//             'activities'); // Replace 'activities' with your desired collection name

//     // Create a map with the activity data you want to store
//     final Map<String, dynamic> activityData = {
//       'activity_id': activity['id'],
//       'name': activity['name'],
//       'moving_time': activity['moving_time'],
//       'distance': activity['distance'],
//       'elevation_gain': activity['total_elevation_gain'],
//       'type': activity['type'],
//       'sport_type': activity['sport_type'],
//       'start_date': activity['start_date'],
//       'start_date_local': activity['start_date_local'],
//       'timezone': activity['timezone'],
//       'utc_offset': activity['utc_offset'],
//       "map": {
//         "id": activity['map']['id'],
//         "polyline": activity['map']['polyline'],
//         "resource_state": activity['map']['resource_state'],
//         "summary_polyline": activity['map']['summary_polyline'],
//       },
//       'timestamp': FieldValue.serverTimestamp(),
//       'username': athlete['username'],
//       'fullname': athlete['firstname'] + ' ' + athlete['lastname'],
//       'city': athlete['city'],
//       'state': athlete['state'], // Add a timestamp
//     };

//     // final Map<String, dynamic> athleteData = {
//     //   'username': athlete['username'],
//     //   'name': athlete['firstname'] + ' ' + athlete['lastname'],
//     //   'city': athlete['city'],
//     //   'state': athlete['state'],
//     // };

//     // Add the data to Firestore
//     activitiesCollection.add(activityData).then((value) {
//       print("Activity data submitted to Firestore successfully!");
//     }).catchError((error) {
//       print("Error submitting activity data to Firestore: $error");
//     });
//   }
// }

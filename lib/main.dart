import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ride_tide_stride/firebase_options.dart';
import 'Auth/authentication.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:strava_client/strava_client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'secret.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strava Flutter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StravaFlutterPage(),
    );
  }
}

class StravaFlutterPage extends StatefulWidget {
  @override
  _StravaFlutterPageState createState() => _StravaFlutterPageState();
}

class _StravaFlutterPageState extends State<StravaFlutterPage> {
  final TextEditingController _textEditingController = TextEditingController();
  final DateFormat dateFormatter = DateFormat("HH:mm:ss");
  late final StravaClient stravaClient;
  Map<String, dynamic>? athleteData;
  Map<String, dynamic>? athleteActivityData;
  List<dynamic>? athleteActivities;

  bool isLoggedIn = false;
  TokenResponse? token;

  @override
  void initState() {
    signInWithFirebase();
    stravaClient = StravaClient(secret: secret, clientId: clientId);
    super.initState();
    if (token != null) {
      _textEditingController.text = token!.accessToken;
    }
  }

  Future<void> signInWithFirebase() async {
    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInAnonymously();
      final User? user = userCredential.user;
      print('User signed in: ${user?.uid}');
    } catch (e) {
      print('Error signing in: $e');
    }
  }

  FutureOr<Null> showErrorMessage(dynamic error, dynamic stackTrace) {
    if (error is Fault) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Did Receive Fault"),
              content: Text(
                  "Message: ${error.message}\n-----------------\nErrors:\n${(error.errors ?? []).map((e) => "Code: ${e.code}\nResource: ${e.resource}\nField: ${e.field}\n").toList().join("\n----------\n")}"),
            );
          });
    }
  }

  void testAuthentication() {
    ExampleAuthentication(stravaClient).testAuthentication(
      [
        AuthenticationScope.profile_read_all,
        AuthenticationScope.read_all,
        AuthenticationScope.activity_read_all,
      ],
      "com.example.flutter://localhost", // Use your custom scheme here
    ).then((token) {
      setState(() {
        isLoggedIn =
            true; // Set isLoggedIn to true when authentication is successful
        this.token = token;
        _textEditingController.text = token.accessToken;
      });

      // After authentication, you can fetch athlete data or perform other actions.
      fetchAthleteData(token.accessToken).catchError(showErrorMessage);
    }).catchError(showErrorMessage);
  }

  void testDeauth() {
    ExampleAuthentication(stravaClient).testDeauthorize().then((value) {
      setState(() {
        isLoggedIn = false;
        this.token = null;
        _textEditingController.clear();
      });
    }).catchError(showErrorMessage);
  }

  Future<void> fetchAthleteData(String accessToken) async {
    final url = Uri.parse('https://www.strava.com/api/v3/athlete');
    final headers = {
      'Authorization': 'Bearer $accessToken',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          athleteData = data;
        });
      } else {
        // Handle the error
        print(
            'Failed to fetch athlete data. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching athlete data: $error');
    }
  }

  Future<void> fetchAthleteActivityData(String accessToken) async {
    final url = Uri.parse('https://www.strava.com/api/v3/athlete/activities');
    final headers = {
      'Authorization': 'Bearer $accessToken',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          athleteActivities = data;
        });
      } else {
        // Handle the error
        print(
            'Failed to fetch athlete activities. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching athlete activities: $error');
    }
  }

  String formatDuration(int seconds) {
    final Duration duration = Duration(seconds: seconds);
    final int hours = duration.inHours;
    final int minutes = (duration.inMinutes % 60);
    final int remainingSeconds = (duration.inSeconds % 60);
    return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Flutter Strava Plugin"),
        actions: [
          Icon(
            isLoggedIn
                ? Icons.radio_button_checked_outlined
                : Icons.radio_button_off,
            color: isLoggedIn ? Colors.white : Colors.red,
          ),
          const SizedBox(
            width: 8,
          )
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _login(),
              ElevatedButton(
                onPressed: () {
                  if (token != null) {
                    fetchAthleteData(token!.accessToken);
                  } else {
                    // Handle the case when token is null (e.g., show an error message).
                    // You can display a message to the user or take appropriate action.
                  }
                },
                child: Text("Get Logged In Athlete Data"),
              ),
              if (athleteData != null)
                Column(
                  children: [
                    Text('ID: ${athleteData!['id']}'),
                    Text('Username: ${athleteData!['username']}'),
                    Text('Firstname: ${athleteData!['firstname']}'),
                    Text('Lastname: ${athleteData!['lastname']}'),
                    Text('City: ${athleteData!['city']}'),
                    Text('State: ${athleteData!['state']}'),
                    Text('followers: ${athleteData!['follower_count']}'),
                    Text(
                        'mutual followers: ${athleteData!['mutual_friend_count']}'),

                    // Add more athlete data as needed
                  ],
                ),
              ElevatedButton(
                onPressed: () {
                  if (token != null) {
                    fetchAthleteActivityData(token!.accessToken);
                  } else {
                    // Handle the case when token is null (e.g., show an error message).
                  }
                },
                child: Text("Get Athlete Activity Data"),
              ),
              if (athleteActivities != null)
                Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: athleteActivities!.length,
                      itemBuilder: (context, index) {
                        final activity = athleteActivities![index];
                        final int movingTimeSeconds = activity['moving_time'];

                        // Add a button for submission
                        return Column(
                          children: [
                            ListTile(
                              title: Text('Activity ID: ${activity['id']}'),
                              subtitle: Text('Name: ${activity['name']}'),
                              trailing: Text(
                                'Moving Time: ${formatDuration(movingTimeSeconds)}',
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Call a function to submit activity data to Firestore
                                submitActivityToFirestore(activity);
                              },
                              child: Text("Submit to Firestore"),
                            ),
                            const Divider(),
                          ],
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _login() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              child: Text("Login With Strava"),
              onPressed: testAuthentication,
            ),
            ElevatedButton(
              child: Text("De Authorize"),
              onPressed: testDeauth,
            )
          ],
        ),
        const SizedBox(
          height: 8,
        ),
        TextField(
          minLines: 1,
          maxLines: 3,
          controller: _textEditingController,
          decoration: InputDecoration(
              border: OutlineInputBorder(),
              label: Text("Access Token"),
              suffixIcon: TextButton(
                child: Text("Copy"),
                onPressed: () {
                  Clipboard.setData(
                          ClipboardData(text: _textEditingController.text))
                      .then((value) =>
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("Copied!"),
                          )));
                },
              )),
        ),
        Text('Access ID#: ${_textEditingController.text}'),
        const Divider()
      ],
    );
  }

  void submitActivityToFirestore(Map<String, dynamic> activity) {
    final CollectionReference activitiesCollection = FirebaseFirestore.instance
        .collection(
            'activities'); // Replace 'activities' with your desired collection name

    // Create a map with the activity data you want to store
    final Map<String, dynamic> activityData = {
      'activity_id': activity['id'],
      'name': activity['name'],
      'moving_time': activity['moving_time'],
      'timestamp': FieldValue.serverTimestamp(), // Add a timestamp
    };

    // Add the data to Firestore
    activitiesCollection.add(activityData).then((value) {
      print("Activity data submitted to Firestore successfully!");
    }).catchError((error) {
      print("Error submitting activity data to Firestore: $error");
    });
  }
}

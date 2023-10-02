import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:ride_tide_stride/auth/auth_page.dart';
import 'package:ride_tide_stride/auth/authentication.dart';
import 'package:ride_tide_stride/secret.dart';
import 'package:strava_client/strava_client.dart';

class StravaFlutterPage extends StatefulWidget {
  const StravaFlutterPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _StravaFlutterPageState createState() => _StravaFlutterPageState();
}

class _StravaFlutterPageState extends State<StravaFlutterPage> {
  final TextEditingController _textEditingController = TextEditingController();
  final DateFormat dateFormatter = DateFormat("HH:mm:ss");
  late final StravaClient stravaClient;
  Map<String, dynamic>? athleteData;
  Map<String, dynamic>? athleteActivityData;
  List<dynamic>? athleteActivities;
  final currentUser = FirebaseAuth.instance.currentUser;

  bool isLoggedIn = false;
  TokenResponse? token;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    // signInWithFirebase();
    stravaClient = StravaClient(secret: secret, clientId: clientId);
    super.initState();
    if (token != null) {
      _textEditingController.text = token!.accessToken;
    }
    // testAuthentication();
  }

  FutureOr<Null> showErrorMessage(dynamic error, dynamic stackTrace) {
    if (error is Fault) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Sorry, we could not authenticate you"),
              content: Text(
                  "Message: User is not logged in \n-----------------\nErrors:\n${(error.errors ?? []).map((e) => "Code: ${e.code}\nResource: ${e.resource}\nField: ${e.field}\n").toList().join("\n----------\n")}"),
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
      fetchAthleteActivityData(token.accessToken).catchError(showErrorMessage);
    }).catchError(showErrorMessage);
  }

  void testDeauth() {
    ExampleAuthentication(stravaClient).testDeauthorize().then((value) {
      setState(() {
        isLoggedIn = false;
        // this.token = null;
        token = null;
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

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  Future<bool> reauthenticateUser(String email, String password) async {
    try {
      // Get reference to the user
      User? user = FirebaseAuth.instance.currentUser;

      // Re-authenticate
      AuthCredential credential =
          EmailAuthProvider.credential(email: email, password: password);
      await user?.reauthenticateWithCredential(credential);

      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> deleteUser() async {
    try {
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (e) {
      print(e);
    }
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button to close
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Account Deletion'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete your account?',
                    style: TextStyle(fontSize: 14)),
                SizedBox(
                  height: 10,
                ),
                Text('This action is permanent and cannot be undone.',
                    style:
                        TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false); // return false
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop(true); // return true
              },
            ),
          ],
        );
      },
    );
    return result ?? false; // if result is null, return false
  }

  Future<bool> _showReauthenticationDialog(BuildContext context) async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Re-authenticate'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Please enter your email and password to confirm.'),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                  ),
                ),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                  ),
                  obscureText: true, // Hide the password input
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () async {
                bool success = await reauthenticateUser(
                    emailController.text, passwordController.text);
                Navigator.of(context).pop(success);
              },
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFD3C3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        toolbarHeight: 100,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/RideTideStride.png", height: 150),
          ],
        ),
        actions: [
          Icon(
            isLoggedIn
                ? Icons.radio_button_checked_outlined
                : Icons.radio_button_off,
            color:
                isLoggedIn ? const Color(0xFF283D3B) : const Color(0xFFA09A6A),
          ),
          const SizedBox(
            width: 8,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              height: 100,
              child: DrawerHeader(
                margin: EdgeInsets.zero, // Remove default margin
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFA09A6A),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12, spreadRadius: 3, blurRadius: 5)
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Heading out?',
                      style: GoogleFonts.specialElite(
                        fontSize: 20,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              title: Text('Sign Out'),
              leading: Icon(Icons.exit_to_app),
              onTap: () async {
                await _signOut();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: Text('Delete Account'),
              leading: Icon(Icons.delete_outline),
              onTap: () async {
                bool shouldProceed =
                    await _showDeleteConfirmationDialog(context);

                if (shouldProceed) {
                  bool reauthenticated =
                      await _showReauthenticationDialog(context);
                  if (reauthenticated) {
                    await deleteUser();
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => AuthPage()));
                  } else {
                    // Handle re-authentication failure
                  }
                }
              },
            )
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                !isLoggedIn
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome to R.T.S!',
                              style: TextStyle(
                                  color: Color(0xFF283D3B),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                            Text(
                              'Click the button below to display your most recent activities.',
                              style: TextStyle(
                                  color: Color(0xFF283D3B),
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                            ElevatedButton.icon(
                              onPressed: testAuthentication,
                              icon: Icon(Icons
                                  .link), // This represents a link icon, but you can choose any other icon from the Flutter icons set.
                              label: Text(
                                "Get my Activities",
                              ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor:
                                    Color(0xFF283D3B), // Text color
                              ),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            Text(
                                'Would you like to view the leaderboards or chat with other athletes?'),
                            const SizedBox(
                              height: 15,
                            ),
                            Text(
                                'You don\'t need a Strava account to view the Leaderboards or chat with other athletes. Navigate to the other pages using the tabs at the bottom of this page')
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          const Text(
                            'Access ID: ',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _textEditingController.text,
                            style: const TextStyle(
                                fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                const SizedBox(
                  height: 15,
                ),
                if (athleteData != null)
                  Center(
                    child: Card(
                      elevation: 8,
                      child: Container(
                        width: 300,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF283D3B).withOpacity(0.8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  athleteData!['firstname'] +
                                      ' ' +
                                      athleteData!['lastname'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Text(
                                  'ID: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text('${athleteData!['id']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    )),
                              ],
                            ),
                            Row(
                              children: [
                                const Text('HQ: ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    )),
                                Text(
                                    '${athleteData!['city']}, ${athleteData!['state']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (athleteActivities != null)
                  Column(
                    children: [
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: athleteActivities!.length,
                        itemBuilder: (context, index) {
                          final activity = athleteActivities![index];
                          final int movingTimeSeconds = activity['moving_time'];

                          return GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              // Add any action you want when the card is tapped
                            },
                            child: Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 0),
                              child: Column(
                                children: [
                                  ListTile(
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('EEE, MMM d, yyyy h:mm a')
                                              .format(DateTime.parse(activity[
                                                  'start_date_local'])),
                                          style: const TextStyle(
                                            fontSize: 10,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text('${activity['name']}'),
                                        const SizedBox(height: 10),
                                      ],
                                    ),
                                    subtitle: Row(
                                      children: [
                                        if (activity['type'] == 'Run')
                                          const Icon(
                                              Icons.directions_run_outlined),
                                        if (activity['type'] == 'Ride')
                                          const Icon(
                                              Icons.directions_bike_outlined),
                                        if (activity['type'] == 'Swim')
                                          const Icon(Icons.pool_outlined),
                                        if (activity['type'] == 'Walk')
                                          const Icon(
                                              Icons.directions_walk_outlined),
                                        if (activity['type'] == 'Hike')
                                          const Icon(Icons.terrain_outlined),
                                        if (activity['type'] == 'AlpineSki')
                                          const Icon(
                                              Icons.snowboarding_outlined),
                                        if (activity['type'] ==
                                            'BackcountrySki')
                                          const Icon(
                                              Icons.snowboarding_outlined),
                                        if (activity['type'] == 'Canoeing')
                                          const Icon(Icons.kayaking_outlined),
                                        if (activity['type'] == 'Crossfit')
                                          const Icon(
                                              Icons.fitness_center_outlined),
                                        if (activity['type'] == 'EBikeRide')
                                          const Icon(
                                              Icons.electric_bike_outlined),
                                        if (activity['type'] == 'Elliptical')
                                          const Icon(
                                              Icons.fitness_center_outlined),
                                        if (activity['type'] == 'Handcycle')
                                          const Icon(
                                              Icons.directions_bike_outlined),
                                        if (activity['type'] == 'IceSkate')
                                          const Icon(
                                              Icons.ice_skating_outlined),
                                        if (activity['type'] == 'InlineSkate')
                                          const Icon(
                                              Icons.ice_skating_outlined),
                                        if (activity['type'] == 'Kayaking')
                                          const Icon(Icons.kayaking_outlined),
                                        if (activity['type'] == 'Kitesurf')
                                          const Icon(
                                              Icons.kitesurfing_outlined),
                                        if (activity['type'] == 'NordicSki')
                                          const Icon(
                                              Icons.snowboarding_outlined),
                                        if (activity['type'] == 'RockClimbing')
                                          const Icon(Icons.terrain_outlined),
                                        if (activity['type'] == 'RollerSki')
                                          const Icon(
                                              Icons.directions_bike_outlined),
                                        if (activity['type'] == 'Rowing')
                                          const Icon(Icons.kayaking_outlined),
                                        if (activity['type'] == 'Snowboard')
                                          const Icon(
                                              Icons.snowboarding_outlined),
                                        if (activity['type'] == 'Snowshoe')
                                          const Icon(
                                              Icons.snowshoeing_outlined),
                                        if (activity['type'] == 'StairStepper')
                                          const Icon(
                                              Icons.fitness_center_outlined),
                                        if (activity['type'] ==
                                            'StandUpPaddling')
                                          const Icon(Icons.kayaking_outlined),
                                        if (activity['type'] == 'Surfing')
                                          const Icon(Icons.surfing_outlined),
                                        if (activity['type'] == 'VirtualRide')
                                          const Icon(
                                              Icons.directions_bike_outlined),
                                        if (activity['type'] == 'VirtualRun')
                                          const Icon(
                                              Icons.directions_run_outlined),
                                        if (activity['type'] ==
                                            'WeightTraining')
                                          const Icon(
                                              Icons.fitness_center_outlined),
                                        if (activity['type'] == 'Windsurf')
                                          const Icon(Icons.surfing_outlined),
                                        if (activity['type'] == 'Workout')
                                          const Icon(
                                              Icons.fitness_center_outlined),
                                        if (activity['type'] == 'Yoga')
                                          const Icon(
                                              Icons.fitness_center_outlined),
                                        Text('${activity['type']}'),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Moving Time: ${formatDuration(movingTimeSeconds)}',
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Distance: ${(activity['distance'] / 1000).toStringAsFixed(2)} km',
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Elevation Gain: ${activity['total_elevation_gain']} m',
                                        ),
                                      ],
                                    ),
                                  ),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('activities')
                                        .where('activity_id',
                                            isEqualTo: activity['id'])
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return Text("Error: ${snapshot.error}");
                                      }

                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const CircularProgressIndicator();
                                      }

                                      final List<DocumentSnapshot> documents =
                                          snapshot.data!.docs;
                                      bool isSubmitted = false;

                                      if (documents.isNotEmpty) {
                                        final DocumentSnapshot document =
                                            documents.first;
                                        isSubmitted =
                                            document.get('submitted') ?? false;
                                      }

                                      return ElevatedButton(
                                        onPressed: isSubmitted
                                            ? null
                                            : () {
                                                // Call the function to submit activity data to Firestore
                                                submitActivityToFirestore(
                                                    activity, athleteData!);
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isSubmitted
                                              ? Colors.grey
                                              : const Color(
                                                  0xFF283D3B), // Change color when submitted
                                        ),
                                        child:
                                            const Text("Submit to Leaderboard"),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void submitActivityToFirestore(
      Map<String, dynamic> activity, Map<String, dynamic> athlete) {
    final CollectionReference activitiesCollection =
        FirebaseFirestore.instance.collection('activities');

    final Map<String, dynamic> activityData = {
      'activity_id': activity['id'],
      'name': activity['name'],
      'moving_time': activity['moving_time'],
      'distance': activity['distance'],
      'elevation_gain': activity['total_elevation_gain'],
      'type': activity['type'],
      'sport_type': activity['sport_type'],
      'start_date': activity['start_date'],
      'start_date_local': activity['start_date_local'],
      'timezone': activity['timezone'],
      'utc_offset': activity['utc_offset'],
      "map": {
        "id": activity['map']['id'],
        "polyline": activity['map']['polyline'],
        "resource_state": activity['map']['resource_state'],
        "summary_polyline": activity['map']['summary_polyline'],
      },
      'timestamp': FieldValue.serverTimestamp(),
      'username': athlete['username'],
      'fullname': athlete['firstname'] + ' ' + athlete['lastname'],
      'city': athlete['city'],
      'state': athlete['state'],
      'submitted': true,
      'user_email': currentUser!.email,
      'average_speed': activity['average_speed'],
      'average_watts': activity['average_watts'],
      'acheivement_count': activity['achievement_count'],
    };

    // Add the data to Firestore
    activitiesCollection.add(activityData).then((value) {
      print("Activity data submitted to Firestore successfully!");
    }).catchError((error) {
      print("Error submitting activity data to Firestore: $error");
    });
  }
}

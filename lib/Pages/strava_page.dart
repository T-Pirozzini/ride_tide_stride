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
import 'package:ride_tide_stride/components/feedback.dart';
import 'package:ride_tide_stride/secret.dart';
import 'package:strava_client/strava_client.dart';
import 'package:url_launcher/url_launcher.dart';

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

  bool autoSubmit = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String currentMonth = DateFormat('MMMM').format(DateTime.now());

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

  Future<List<String>> getSubmittedActivityIDs() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('activities')
        .where('submitted', isEqualTo: true)
        .get();

    List<String> submittedIDs =
        snapshot.docs.map((doc) => doc.get('activity_id').toString()).toList();
    return submittedIDs;
  }

  void _showStravaDialog(BuildContext context, int activityId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/strava.png',
              height: 24.0, // Adjust the size as required
              width: 24.0,
            ),
            SizedBox(width: 10),
            Text('View Activity on Strava?'),
          ],
        ),
        content: Text('Please Note: You will be leaving R.T.S'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                child: Text('Cancel', style: TextStyle(fontSize: 18)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              SizedBox(width: 10),
              TextButton(
                child: Text('Open',
                    style: TextStyle(color: Colors.deepOrange, fontSize: 18)),
                onPressed: () {
                  _openStravaActivity(activityId);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openStravaActivity(int activityId) async {
    final Uri url = Uri.https('www.strava.com', '/activities/$activityId');

    bool canOpen = await canLaunchUrl(url);
    if (canOpen) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Handle the inability to launch the URL.
      print('Could not launch $url');
    }
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

  Future<Map<String, String>> getUserInfo() async {
    final DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser!.email)
        .get();

    Map<String, dynamic>? data = docSnapshot.data() as Map<String, dynamic>?;

    String username = data?['username'] as String? ?? '';
    String email = data?['email'] as String? ?? '';

    return {'username': username, 'email': email};
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
    double screenWidth = MediaQuery.of(context).size.width;

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
              title: Text('Sign Out', style: TextStyle(fontSize: 16)),
              leading: Icon(
                Icons.exit_to_app,
                color: Color.fromARGB(255, 79, 122, 118),
                size: 32,
              ),
              subtitle: Text('See you next time!'),
              onTap: () async {
                await _signOut();
                Navigator.of(context).pop();
              },
            ),
            Divider(),
            FutureBuilder<Map<String, String>>(
              future: getUserInfo(),
              builder: (BuildContext context,
                  AsyncSnapshot<Map<String, String>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(); // Show a loader while waiting
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return UserFeedback(
                      userName: snapshot.data?['username'] ?? '',
                      userEmail: snapshot.data?['email'] ?? '');
                }
              },
            ),
            Divider(),
            ListTile(
              title: Text('My Website', style: TextStyle(fontSize: 16)),
              leading: Icon(
                Icons.code,
                color: Color.fromARGB(255, 79, 122, 118),
                size: 32,
              ),
              subtitle: Text('Check out my other apps!'),
              onTap: () =>
                  launchUrl(Uri.parse('https://portfolio-2023-1a61.fly.dev/')),
            ),
            Divider(),
            ListTile(
              title: Text('Delete Account', style: TextStyle(fontSize: 16)),
              leading: Icon(Icons.delete_outline,
                  color: Colors.red.shade300, size: 32),
              subtitle: Text('Warning: This action is permanent'),
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
                        child: Card(
                          elevation: 5.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: Color(0xFF283D3B),
                                    ),
                                    const SizedBox(width: 8.0),
                                    const Text(
                                      'Welcome to R.T.S!',
                                      style: TextStyle(
                                        color: Color(0xFF283D3B),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  'Click the button below to display your most recent activities.',
                                  style: TextStyle(
                                    color: Color(0xFF283D3B),
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 25),
                                Center(
                                  child: GestureDetector(
                                    onTap: testAuthentication,
                                    child: Image(
                                        image: AssetImage(
                                            'assets/images/btn_strava_connectwith_orange@2x.png')),
                                  ),
                                ),
                                // Center(
                                //   child: ElevatedButton.icon(
                                //     onPressed: testAuthentication,
                                //     icon: Icon(
                                //       Icons.link,
                                //       color: Colors
                                //           .white, // Adjust the color to fit your design
                                //     ),
                                //     label: Text(
                                //       "Get my Activities",
                                //       style: TextStyle(fontSize: 18),
                                //     ),
                                //     style: ElevatedButton.styleFrom(
                                //       foregroundColor: Colors.white,
                                //       backgroundColor: Color(
                                //           0xFF283D3B), // Text and Icon color
                                //       shape: RoundedRectangleBorder(
                                //         borderRadius:
                                //             BorderRadius.circular(10.0),
                                //       ),
                                //       padding: EdgeInsets.symmetric(
                                //           horizontal: 20, vertical: 12),
                                //     ),
                                //   ),
                                // ),
                                SizedBox(height: 25),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Color(0xFF283D3B),
                                    ),
                                    SizedBox(width: 8.0),
                                    Expanded(
                                      child: Text('No Strava account required!',
                                          style: TextStyle(
                                              color: Color(0xFF283D3B),
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'View the Leaderboards or Talk Smack using the tabs below.',
                                  style: TextStyle(
                                      color: Color(0xFF283D3B), fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          const Text(
                            'Strava Access ID: ',
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _textEditingController.text,
                            style: const TextStyle(
                                fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                const SizedBox(
                  height: 5,
                ),
                if (athleteData != null)
                  Center(
                    child: Card(
                      elevation: 10,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        width: screenWidth * 0.9,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF283D3B).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person,
                                    color: Colors.white, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  '${athleteData!['firstname']} ${athleteData!['lastname']}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            SwitchListTile(
                              activeColor: Colors.tealAccent,
                              title: Text(
                                'Submit $currentMonth activities',
                                style: TextStyle(color: Colors.white),
                              ),
                              value: autoSubmit,
                              onChanged: (bool value) async {
                                setState(() {
                                  autoSubmit = value;
                                });
                                // If turned ON, auto-submit all activities
                                if (autoSubmit) {
                                  getSubmittedActivityIDs()
                                      .then((submittedIDs) {
                                    for (var activity in athleteActivities!) {
                                      if (!submittedIDs.contains(
                                          activity['id'].toString())) {
                                        // Activity hasn't been submitted yet
                                        submitActivityToFirestore(
                                            activity, athleteData!);
                                        Future.delayed(
                                            Duration(milliseconds: 100));
                                      }
                                    }
                                  });
                                }
                              },
                            ),
                            Divider(color: Colors.tealAccent),
                            SizedBox(height: 10),
                            _infoRow(
                                Icons.badge, 'ID', '${athleteData!['id']}'),
                            SizedBox(height: 10),
                            _infoRow(Icons.location_city, 'HQ',
                                '${athleteData!['city']}, ${athleteData!['state']}'),
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

                          return Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal:
                                    screenWidth * 0.01), // 5% of screen width
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                _showStravaDialog(context, activity['id']);
                              },
                              child: Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${activity['name']}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20),
                                      ),
                                      // Date and activity type
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Text(
                                            DateFormat('MMM d, yyyy (EEE)')
                                                .format(DateTime.parse(activity[
                                                    'start_date_local'])),
                                            style: TextStyle(
                                              fontSize:
                                                  14, // Adjusted font size
                                              color: Colors.grey
                                                  .shade700, // Made it a bit darker
                                            ),
                                          ),
                                          // Activity type with icon
                                          _activityIcon(activity['type']),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      // Metrics with icons
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.timer_outlined,
                                                  size: 20,
                                                  color: Colors.teal.shade500),
                                              SizedBox(width: 5),
                                              Text(
                                                  '${formatDuration(movingTimeSeconds)}'),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.straighten_outlined,
                                                  size: 20,
                                                  color: Colors.teal.shade500),
                                              SizedBox(width: 5),
                                              Text(
                                                  '${(activity['distance'] / 1000).toStringAsFixed(2)} km'),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.landscape_outlined,
                                                  size: 20,
                                                  color: Colors.teal.shade500),
                                              SizedBox(width: 5),
                                              Text(
                                                  '${activity['total_elevation_gain']} m'),
                                            ],
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 10),
                                      StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('activities')
                                            .where('activity_id',
                                                isEqualTo: activity['id'])
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasError) {
                                            return Text(
                                                "Error: ${snapshot.error}");
                                          }

                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const CircularProgressIndicator();
                                          }

                                          final List<DocumentSnapshot>
                                              documents = snapshot.data!.docs;
                                          bool isSubmitted = false;

                                          if (documents.isNotEmpty) {
                                            final DocumentSnapshot document =
                                                documents.first;
                                            isSubmitted =
                                                document.get('submitted') ??
                                                    false;
                                          }

                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              ElevatedButton(
                                                onPressed:
                                                    isSubmitted || autoSubmit
                                                        ? null
                                                        : () {
                                                            // Call the function to submit activity data to Firestore
                                                            submitActivityToFirestore(
                                                                activity,
                                                                athleteData!);
                                                          },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isSubmitted
                                                      ? Colors.grey
                                                      : const Color(
                                                          0xFF283D3B), // Change color when submitted
                                                ),
                                                child: const Text(
                                                    "Submit to Leaderboard"),
                                              ),
                                              if (isSubmitted)
                                                IconButton(
                                                  icon: Icon(Icons.undo),
                                                  onPressed: () {
                                                    deleteActivityFromFirestore(
                                                        activity['id']);
                                                  },
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
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

    if (activity['sport_type'] == 'Run' || activity['sport_type'] == 'Ride') {
      showDialog(
        context: context,
        builder: (context) {
          String localSportType = activity['sport_type'] == 'Run'
              ? 'Road Run'
              : 'Road Bike'; // Default value

          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(activity['sport_type'] == "Run"
                    ? 'Road or Trail Run?'
                    : 'Road or Mtn Bike?'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      Text(activity['name']),
                      Text(
                        DateFormat('MMM d, yyyy (EEE)').format(
                            DateTime.parse(activity['start_date_local'])),
                      ),
                      Text(
                          'Please select the specific type of ${activity['sport_type'] == "Run" ? "run" : "ride"}.'),
                      SizedBox(height: 10),
                      DropdownButton<String>(
                        value: localSportType,
                        icon: const Icon(Icons.arrow_downward),
                        iconSize: 24,
                        elevation: 16,
                        style: const TextStyle(color: Colors.teal),
                        underline: Container(
                          height: 2,
                          color: Colors.tealAccent,
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            localSportType = newValue!;
                          });
                        },
                        items: (activity['sport_type'] == "Run"
                                ? <String>['Road Run', 'Trail Run']
                                : <String>['Road Bike', 'Mtn Bike'])
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value,
                                style: TextStyle(
                                    color: Colors.teal.shade700, fontSize: 16)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('Submit'),
                    onPressed: () {
                      activity['sport_type'] = localSportType;
                      Navigator.of(context).pop();
                      _submitActivity(activity, athlete, activitiesCollection);
                    },
                  ),
                ],
              );
            },
          );
        },
      );
    } else {
      _submitActivity(activity, athlete, activitiesCollection);
    }
  }

  void _submitActivity(
    Map<String, dynamic> activity,
    Map<String, dynamic> athlete,
    CollectionReference activitiesCollection,
  ) {
    double averageSpeed = activity['average_speed'];
    if (averageSpeed == 0) {
      averageSpeed = 0.0;
    }

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
      'timestamp': FieldValue.serverTimestamp(),
      'username': athlete['username'],
      'fullname': athlete['firstname'] + ' ' + athlete['lastname'],
      'city': athlete['city'],
      'state': athlete['state'],
      'submitted': true,
      'user_email': currentUser!.email,
      'average_speed': activity['average_speed'],
      'average_watts': activity['average_watts'],
    };

    // Add the data to Firestore
    activitiesCollection.add(activityData).then((value) {
      print("Activity data submitted to Firestore successfully!");
    }).catchError((error) {
      print("Error submitting activity data to Firestore: $error");
    });
  }
}

void deleteActivityFromFirestore(activityId) {
  final CollectionReference activitiesCollection =
      FirebaseFirestore.instance.collection('activities');

  activitiesCollection
      .where('activity_id', isEqualTo: activityId)
      .get()
      .then((querySnapshot) {
    for (var doc in querySnapshot.docs) {
      doc.reference.delete().then((_) {
        print("Activity deleted successfully!");
      }).catchError((error) {
        print("Error deleting activity: $error");
      });
    }
  });
}

// This function is to avoid repetition and make the code cleaner
Widget _infoRow(IconData icon, String title, String value) {
  return Row(
    children: [
      Icon(icon, color: Colors.tealAccent, size: 20),
      SizedBox(width: 8),
      Text(
        '$title: ',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    ],
  );
}

final activityIcons = {
  'Run': Icons.directions_run_outlined,
  'Ride': Icons.directions_bike_outlined,
  'Swim': Icons.pool_outlined,
  'Walk': Icons.directions_walk_outlined,
  'Hike': Icons.terrain_outlined,
  'AlpineSki': Icons.snowboarding_outlined,
  'BackcountrySki': Icons.snowboarding_outlined,
  'Canoeing': Icons.kayaking_outlined,
  'Crossfit': Icons.fitness_center_outlined,
  'EBikeRide': Icons.electric_bike_outlined,
  'Elliptical': Icons.fitness_center_outlined,
  'Handcycle': Icons.directions_bike_outlined,
  'IceSkate': Icons.ice_skating_outlined,
  'InlineSkate': Icons.ice_skating_outlined,
  'Kayaking': Icons.kayaking_outlined,
  'Kitesurf': Icons.kitesurfing_outlined,
  'NordicSki': Icons.snowboarding_outlined,
  'RockClimbing': Icons.terrain_outlined,
  'RollerSki': Icons.directions_bike_outlined,
  'Rowing': Icons.kayaking_outlined,
  'Snowboard': Icons.snowboarding_outlined,
  'Snowshoe': Icons.snowshoeing_outlined,
  'StairStepper': Icons.fitness_center_outlined,
  'StandUpPaddling': Icons.kayaking_outlined,
  'Surfing': Icons.surfing_outlined,
  'VirtualRide': Icons.directions_bike_outlined,
  'VirtualRun': Icons.directions_run_outlined,
  'WeightTraining': Icons.fitness_center_outlined,
  'Windsurf': Icons.surfing_outlined,
  'Workout': Icons.fitness_center_outlined,
  'Yoga': Icons.fitness_center_outlined,
};

Widget _activityIcon(String activityType) {
  var iconData = activityIcons[activityType] ??
      Icons.help_outline; // Default icon if not found
  return Row(
    children: [
      Icon(iconData, color: Colors.teal.shade100, size: 48),
    ],
  );
}

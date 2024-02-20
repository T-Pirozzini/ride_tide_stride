import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TeamTraversePage extends StatefulWidget {
  final String challengeId;
  final List<dynamic> participantsEmails;
  final Timestamp startDate;
  final String challengeType;
  final String challengeName;
  final String mapDistance;

  const TeamTraversePage(
      {Key? key,
      required this.challengeId,
      required this.participantsEmails,
      required this.startDate,
      required this.challengeType,
      required this.challengeName,
      required this.mapDistance})
      : super(key: key);

  @override
  State<TeamTraversePage> createState() => _TeamTraversePageState();
}

class _TeamTraversePageState extends State<TeamTraversePage> {
  Map<String, Color> participantColors = {};
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    DateTime startDate = widget.startDate.toDate();
    DateTime adjustedStartDate =
        DateTime(startDate.year, startDate.month, startDate.day);
    endDate = adjustedStartDate.add(Duration(days: 30));
  }

  Future<Map<String, double>> fetchParticipantDistances() async {
    Map<String, double> participantDistances = {};
    List<Color> colors = [
      Colors.redAccent,
      Colors.greenAccent,
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.pinkAccent,
      Colors.tealAccent,
      Colors.amberAccent,
      Colors.cyanAccent,
      Colors.limeAccent,
    ];
    int colorIndex = 0;

    // Calculate the end date as 30 days after the start date
    DateTime startDate = widget.startDate.toDate();
    DateTime adjustedStartDate =
        DateTime(startDate.year, startDate.month, startDate.day);

    DateTime endDate = adjustedStartDate.add(Duration(days: 30));

    for (String email in widget.participantsEmails) {
      double totalDistance = 0.0;
      var activitiesSnapshot = await FirebaseFirestore.instance
          .collection('activities')
          .where('user_email', isEqualTo: email)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(adjustedStartDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      for (var doc in activitiesSnapshot.docs) {
        DateTime activityDate = (doc.data()['timestamp'] as Timestamp).toDate();
        print("Activity Timestamp for $email: $activityDate");
        totalDistance += (doc.data()['distance'] as num).toDouble();
      }
      participantDistances[email] = totalDistance;

      participantColors[email] = colors[colorIndex % colors.length];
      colorIndex++;
    }
    return participantDistances;
  }

  Widget buildPieChart(Map<String, double> participantDistances) {
    double totalDistance =
        participantDistances.values.fold(0.0, (a, b) => a + b);
    List<PieChartSectionData> sections =
        participantDistances.entries.map((entry) {
      final isLarge =
          totalDistance > 0 ? (entry.value / totalDistance) > 0.1 : false;
      Color color = participantColors[entry.key] ?? Colors.grey;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${(entry.value / totalDistance * 100).toStringAsFixed(1)}%',
        radius: isLarge ? 50 : 50,
        titleStyle: TextStyle(
            fontSize: isLarge ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: Colors.white),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 20,
        sectionsSpace: 2,
      ),
    );
  }

  Future<Map<String, dynamic>> fetchChallengeMapDetails() async {
    var challengeSnapshot = await FirebaseFirestore.instance
        .collection('Challenges')
        .doc(widget.challengeId)
        .get();
    if (!challengeSnapshot.exists) {
      throw Exception("Challenge not found");
    }
    var data = challengeSnapshot.data();
    if (data == null) {
      throw Exception("Challenge data is null");
    }
    return {
      'mapDistance': data['mapDistance'],
      'mapAssetUrl': data['currentMap'],
    };
  }

  Future<Map<String, dynamic>> fetchChallengeDetailsAndTotalDistance() async {
    // Fetch participant distances first
    Map<String, double> participantDistances =
        await fetchParticipantDistances();
    double totalDistance =
        participantDistances.values.fold(0.0, (a, b) => a + b);

    // Then fetch challenge map details
    var mapDetails = await fetchChallengeMapDetails();

    // Convert 'mapDistance' to a numeric value for calculations
    String mapDistanceStr = widget
        .mapDistance; // Assuming this is your map distance string with 'kms'
    String numericPart = mapDistanceStr.replaceAll(RegExp(r'[^0-9.]'), '');
    double mapDistance = double.parse(numericPart);

    // Return a composite result containing both sets of data
    return {
      'totalDistance': totalDistance, // Total distance from participants
      'mapDistance': mapDistance, // Numeric map distance
      'mapAssetUrl': mapDetails['mapAssetUrl'], // URL or asset path for the map
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFD3C3),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.challengeType,
          style: GoogleFonts.tektur(
              textStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.2)),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Center(
                  child: Text(
                    widget.challengeName,
                    style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.2)),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      '${DateFormat('MMMM dd, yyyy').format(widget.startDate.toDate())} - ${DateFormat('MMMM dd, yyyy').format(endDate!)}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            flex:
                1, // Adjust flex to change how space is allocated between the map and participant list
            child: Stack(
              children: [
                FutureBuilder<Map<String, dynamic>>(
                  future: fetchChallengeDetailsAndTotalDistance(),
                  builder: (context, snapshot) {
                    // Handle loading and error states as before
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData) {
                      return Text("Details not available");
                    }

                    // Unchanged logic for handling fetched data
                    double totalDistanceKM =
                        snapshot.data!['totalDistance'] / 1000;
                    double mapDistance = snapshot.data!['mapDistance'];
                    String mapAssetUrl = snapshot.data!['mapAssetUrl'];
                    double progress =
                        (totalDistanceKM / mapDistance).clamp(0.0, 1.0);

                    return Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child:
                                  Image.asset(mapAssetUrl, fit: BoxFit.cover),
                            ),
                          ), // Adjusted map to be within an Expanded widget
                        ),
                        Card(
                          elevation: 2,
                          margin:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey[200],
                                  minHeight: 10,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.lightGreenAccent[200]!),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    "${totalDistanceKM.toStringAsFixed(2)} km / $mapDistance km",
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    "${(progress * 100).toStringAsFixed(2)}% Completed",
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Positioned(
                  top: 75, // Adjust as needed for padding from the top
                  right: 75, // Adjust as needed for padding from the right
                  child: Opacity(
                    opacity: 0.6,
                    child: FutureBuilder<Map<String, double>>(
                      future: fetchParticipantDistances(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Text("No data available for chart");
                        }
                        return Container(
                          width: 20, // Specify the width of the chart
                          height: 20, // Specify the height of the chart
                          child: buildPieChart(
                              snapshot.data!), // Your method to build the chart
                        );
                      },
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Card(
                      elevation: 2,
                      child: Text(
                        'Goal: ${widget.mapDistance}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 5),
          Divider(
            thickness: 2,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FutureBuilder<Map<String, double>>(
                future: fetchParticipantDistances(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData) {
                    return Text("No participant data available");
                  }

                  // Ensure we display up to 10 slots, showing "Empty Slot" as needed
                  int itemCount = max(10, widget.participantsEmails.length);
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Number of columns
                      childAspectRatio: 3 / 1, // Adjust the size ratio of items
                      crossAxisSpacing: 2, // Spacing between items horizontally
                      mainAxisSpacing: 2, // Spacing between items vertically
                    ),
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      String email = index < widget.participantsEmails.length
                          ? widget.participantsEmails[index]
                          : "Empty Position";
                      double distance = index < widget.participantsEmails.length
                          ? snapshot.data![email] ?? 0.0
                          : 0.0;

                      Color avatarColor =
                          participantColors[email] ?? Colors.grey;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              email != "Empty Position"
                                  ? CircleAvatar(
                                      backgroundColor: avatarColor,
                                      radius:
                                          10, // Adjust the size of the avatar as needed
                                    )
                                  : SizedBox.shrink(),
                              SizedBox(
                                  width:
                                      8), // Provides some spacing between the avatar and the text
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    getUserName(
                                        email), // Username or "Empty Slot"
                                    Text(
                                      index < widget.participantsEmails.length
                                          ? 'Distance: ${(distance / 1000).toStringAsFixed(2)} km'
                                          : '',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getUserName(String email) {
    // Check if email is "Empty Slot", and avoid fetching from Firestore
    if (email == "Empty Slot") {
      return Text(
          email); // Or return SizedBox.shrink() if you don't want to show anything
    }

    // Proceed with fetching the username
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('Users').doc(email).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Loading..."); // Show loading text or a spinner
        }
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return Text(email); // Fallback to email if user data is not available
        }
        var data = snapshot.data!.data()
            as Map<String, dynamic>; // Cast the data to the correct type
        return Text(
            data['username'] ?? email); // Show username or email as a fallback
      },
    );
  }
}

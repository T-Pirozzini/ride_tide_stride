import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_tide_stride/helpers/helper_functions.dart';
import 'package:ride_tide_stride/screens/challenges/competition_lobby.dart';
import 'package:ride_tide_stride/screens/leaderboard/leaderboard_page.dart';
import 'package:ride_tide_stride/screens/strava_connect/strava_page.dart';
import 'package:ride_tide_stride/screens/chat/talk_smack.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  final currentUser = FirebaseAuth.instance.currentUser;
  String username = '';

  @override
  void initState() {
    super.initState();    
    fetchUsername();
  }  

  void fetchUsername() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.email != null) {
      getUsername(currentUser.email!).then((value) {
        setState(() {
          username = value;
        });
      }).catchError((error) {
        setState(() {
          username =
              'Error fetching username'; // Set an error message or handle differently
          print("Failed to fetch username: $error");
        });
      });
    } else {
      setState(() {
        username =
            'No user logged in'; // Handle case where no user is logged in
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          child: Text("Hey $username. Get after it!",
              style: GoogleFonts.specialElite(
                  fontWeight: FontWeight.w300,
                  fontSize: 18,
                  letterSpacing: 1.2,
                  color: Colors.white)),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          Builder(
            builder: (BuildContext context) => StravaFlutterPage(),
          ),
          Builder(
            builder: (BuildContext context) => const Leaderboard(),
          ),
          Builder(
            builder: (BuildContext context) => const CompetitionLobbyPage(),
          ),
          Builder(builder: (BuildContext context) => TalkSmack()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF283D3B),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.account_box_outlined, color: Colors.white60),
            activeIcon: Icon(Icons.account_box,
                color: Colors
                    .white), // activeIcon will ensure that the icon is always white, even when selected
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard_outlined, color: Colors.white60),
            activeIcon: Icon(Icons.leaderboard, color: Colors.white),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined, color: Colors.white60),
            activeIcon: Icon(Icons.emoji_events, color: Colors.white),
            label: 'Challenge',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined, color: Colors.white60),
            activeIcon: Icon(Icons.chat, color: Colors.white),
            label: 'Talk Smack',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors
            .white, // This ensures the text for the selected item is also white
        unselectedItemColor: Colors.white.withOpacity(0.6),
      ),
    );
  }
}

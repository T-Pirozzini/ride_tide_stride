import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_tide_stride/pages/competition_lobby.dart';
import 'package:ride_tide_stride/pages/leaderboard_page.dart';
import 'package:ride_tide_stride/pages/strava_page.dart';
import 'package:ride_tide_stride/pages/talk_smack.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  final currentUser = FirebaseAuth.instance.currentUser;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    String? email =
        currentUser!.email; // Assuming currentUser is a Firebase User object
    List<String> emailParts = email!.split('@');
    String username = emailParts[0];

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

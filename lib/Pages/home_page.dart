import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_tide_stride/pages/leaderboard_page.dart';
import 'package:ride_tide_stride/pages/strava_page.dart';

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
        title: Text("Hey $username. Get after it!",
            style: GoogleFonts.specialElite(
                fontWeight: FontWeight.w300, fontSize: 18, letterSpacing: 1.2)),
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
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Strava',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

import 'package:flutter/material.dart';

class Leaderboard extends StatefulWidget {
  const Leaderboard({Key? key}) : super(key: key);

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text('Leaderboard'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Moving Time'),
              Tab(text: 'Total Distance (km)'),
              Tab(text: 'Total Elevation'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Add your leaderboard widgets for each tab here
            LeaderboardTab(title: 'Moving Time'),
            LeaderboardTab(title: 'Total Distance (km)'),
            LeaderboardTab(title: 'Total Elevation'),
          ],
        ),
      ),
    );
  }
}

class LeaderboardTab extends StatelessWidget {
  final String title;

  const LeaderboardTab({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Leaderboard for $title',
        style: TextStyle(fontSize: 20.0),
      ),
    );
  }
}
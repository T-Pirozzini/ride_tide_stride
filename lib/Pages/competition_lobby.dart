import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_tide_stride/components/competition_dialog.dart';
import 'package:ride_tide_stride/components/competition_tile.dart';

class CompetitionLobbyPage extends StatefulWidget {
  const CompetitionLobbyPage({super.key});

  @override
  State<CompetitionLobbyPage> createState() => _CompetitionLobbyPageState();
}

class _CompetitionLobbyPageState extends State<CompetitionLobbyPage> {
  // Dummy list of competitions, replace this with your actual data
  List<String> activeCompetitions = [
    'Competition 1',
    'Competition 2',
    'Competition 3',
    'Competition 1',
    'Competition 2',
    'Competition 3',
    'Competition 1',
    'Competition 2',
    'Competition 3',
    // Add more competitions as needed
  ];

  // add a new competition
  void addCompetition() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddCompetitionDialog(); // Show the custom dialog
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'The Challenge Hub',
                  style: GoogleFonts.tektur(
                      textStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.2)),
                ),
                centerTitle: true,
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child:
                    Text('Here you can join a competition or create your own.'),
              ),
            ),
            SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 columns
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  if (index < activeCompetitions.length) {
                    // You can create a custom competition tile widget here
                    return CompetitionTile(title: activeCompetitions[index]);
                  }
                  return null; // Return null for indices that exceed the available competitions
                },
                childCount: activeCompetitions.length,
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: addCompetition,
          child: Icon(Icons.add),
        ));
  }
}

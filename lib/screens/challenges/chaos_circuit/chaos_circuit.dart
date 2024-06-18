import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_tide_stride/providers/challenge_provider.dart';
import 'package:ride_tide_stride/providers/opponent_provider.dart';
import 'package:ride_tide_stride/screens/challenges/chaos_circuit/matchup_display.dart';
import 'package:ride_tide_stride/screens/challenges/chaos_circuit/taunt_display.dart';
import 'package:ride_tide_stride/screens/challenges/chaos_circuit/track_component.dart';
import 'package:ride_tide_stride/theme.dart';

class ChaosCircuit extends ConsumerStatefulWidget {
  final String challengeId;

  const ChaosCircuit({
    super.key,
    required this.challengeId,
  });

  @override
  _ChaosCircuitState createState() => _ChaosCircuitState();
}

class _ChaosCircuitState extends ConsumerState<ChaosCircuit> {
  @override
  Widget build(BuildContext context) {
    final opponents = ref.watch(opponentsProvider);
    final challengeDetails =
        ref.watch(challengeDetailsProvider(widget.challengeId));

    return Scaffold(
      backgroundColor: AppColors.primaryAccent,
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Chaos Circuit',
              style: GoogleFonts.tektur(
                  textStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2)),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: challengeDetails.when(
        data: (challenge) {
          final participantEmails = challenge.participantsEmails;
          final challengeTimestamp = challenge.timestamp;
          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  color: AppColors.primaryAccent,
                  height: 300,
                  child: MatchupDisplay(challengeId: widget.challengeId),
                ),
                Container(
                  height: 100,
                  margin: const EdgeInsets.all(8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TauntDisplay(
                          participantEmails: participantEmails,
                          challengeDifficulty: challenge.difficulty),
                    ),
                  ),
                ),
                Container(
                  height: 600,
                  child: TrackComponent(
                    participantEmails: participantEmails,
                    timestamp: challengeTimestamp,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

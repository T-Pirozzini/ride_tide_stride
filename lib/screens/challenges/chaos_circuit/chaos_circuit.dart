import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_tide_stride/providers/opponent_provider.dart';

class ChaosCircuit extends ConsumerStatefulWidget {
  final String challengeId;
  final List<dynamic> participantsEmails;
  final Timestamp startDate;
  final String challengeType;
  final String challengeName;
  final String challengeDifficulty;
  final String challengeCreator;

  const ChaosCircuit({
    super.key,
    required this.challengeId,
    required this.participantsEmails,
    required this.startDate,
    required this.challengeType,
    required this.challengeName,
    required this.challengeDifficulty,
    required this.challengeCreator,
  });

  @override
  _ChaosCircuitState createState() => _ChaosCircuitState();
}

class _ChaosCircuitState extends ConsumerState<ChaosCircuit> {
  @override
  Widget build(BuildContext context) {
    final opponents = ref.watch(opponentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFDFD3C3),
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
      body: Column(
        children: [
          Container(
            color: Colors.grey[200],
            height: 300,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text('Join Team?',
                            style: Theme.of(context).textTheme.headlineSmall),
                        subtitle: Text('Empty',
                            style: Theme.of(context).textTheme.bodySmall),
                        leading: CircleAvatar(
                          backgroundColor: Colors.tealAccent,
                        ),
                      );
                    },
                  ),
                ),
                Text(
                  'VS',
                  style: GoogleFonts.blackOpsOne(
                    textStyle: TextStyle(
                      fontSize: 32,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      final name = opponents['Advanced']!.name[index];
                      final slogan = opponents['Advanced']!.slogan[name];
                      return ListTile(
                        title: Text(opponents['Advanced']!.name[index],
                            style: Theme.of(context).textTheme.headlineSmall),
                        subtitle: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(slogan!,
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                        leading: CircleAvatar(
                          backgroundImage: AssetImage(
                              opponents[widget.challengeDifficulty]!
                                  .image[index]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

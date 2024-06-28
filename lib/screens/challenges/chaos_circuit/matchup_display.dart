import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_tide_stride/helpers/helper_functions.dart';
import 'package:ride_tide_stride/providers/challenge_provider.dart';
import 'package:ride_tide_stride/providers/opponent_provider.dart';
import 'package:ride_tide_stride/providers/users_provider.dart';
import 'package:ride_tide_stride/shared/activity_icons.dart';
import 'package:auto_size_text/auto_size_text.dart';

class MatchupDisplay extends ConsumerStatefulWidget {
  final String challengeId;
  const MatchupDisplay({super.key, required this.challengeId});

  @override
  _MatchupDisplayState createState() => _MatchupDisplayState();
}

class _MatchupDisplayState extends ConsumerState<MatchupDisplay> {
  @override
  Widget build(BuildContext context) {
    final opponents = ref.watch(opponentsProvider);
    final challengeDetails =
        ref.watch(challengeDetailsProvider(widget.challengeId));
    final usersAsyncValue = ref.watch(usersStreamProvider);

    return challengeDetails.when(
      data: (challenge) {
        return usersAsyncValue.when(
          data: (users) {
            final participants = challenge.participantsEmails;
            final teamUsers = users
                .where((user) => participants.contains(user.email))
                .toList();

            return Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (index) {
                      if (index < teamUsers.length) {
                        final user = teamUsers[index];
                        String avatarUrl = user.avatarUrl;
                        if (avatarUrl.isEmpty) {
                          avatarUrl = 'No Avatar';
                        }
                        return Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 0.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            border:
                                Border.all(color: Colors.greenAccent, width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 4.0),
                            title: Container(
                              alignment: Alignment.centerLeft,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(user.username,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.black)),
                              ),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: hexToColor(user.color),
                              radius: 25,
                              child: avatarUrl != "No Avatar"
                                  ? ClipOval(
                                      child: SvgPicture.network(
                                        user.avatarUrl,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(Icons.person, size: 40),
                            ),
                          ),
                        );
                      } else {
                        return Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 0.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.greenAccent),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 4.0),
                            title: Text('Open',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            leading: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: Text(
                                "?",
                                style: TextStyle(
                                    fontSize: 24, color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      }
                    }),
                  ),
                ),
                Text(
                  'VS',
                  style: GoogleFonts.blackOpsOne(
                    textStyle: TextStyle(
                      color: Colors.pinkAccent[200],
                      fontSize: 32,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (index) {
                      final name = opponents[challenge.difficulty]!.name[index];
                      final slogan =
                          opponents[challenge.difficulty]!.slogan[name];
                      final activity =
                          opponents[challenge.difficulty]!.activity[index];
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.redAccent, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
                          title: Row(
                            children: [
                              Text(name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                              SizedBox(width: 4),
                              Icon(activityIcons[activity]),
                            ],
                          ),
                          subtitle: AutoSizeText(
                            slogan!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            minFontSize: 4, // Set a minimum font size
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundImage: AssetImage(
                                opponents[challenge.difficulty]!.image[index]),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            );
          },
          loading: () => Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

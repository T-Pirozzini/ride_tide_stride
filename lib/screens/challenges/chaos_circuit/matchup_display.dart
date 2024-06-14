import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_tide_stride/helpers/helper_functions.dart';
import 'package:ride_tide_stride/providers/challenge_provider.dart';
import 'package:ride_tide_stride/providers/opponent_provider.dart';
import 'package:ride_tide_stride/providers/users_provider.dart';

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      if (index < teamUsers.length) {
                        final user = teamUsers[index];
                        String avatarUrl = user.avatarUrl;
                        if (avatarUrl.isEmpty) {
                          avatarUrl = 'No Avatar';
                        }
                        return Container(
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              dense: true,
                              title: Text(user.username,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                              subtitle: Text('Team Member',
                                  style: Theme.of(context).textTheme.bodySmall),
                              // leading: CircleAvatar(
                              //   backgroundColor: hexToColor(user.color),
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
                            ));
                      } else {
                        return Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            dense: true,
                            title: Text('Join Team?',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            subtitle: Text('Empty',
                                style: Theme.of(context).textTheme.bodySmall),
                            leading: CircleAvatar(
                              backgroundColor: Colors.tealAccent,
                            ),
                          ),
                        );
                      }
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
                      final name = opponents[challenge.difficulty]!.name[index];
                      final slogan =
                          opponents[challenge.difficulty]!.slogan[name];
                      return ListTile(
                        title: Text(
                            opponents[challenge.difficulty]!.name[index],
                            style: Theme.of(context).textTheme.headlineSmall),
                        subtitle: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(slogan!,
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                        leading: CircleAvatar(
                          backgroundImage: AssetImage(
                              opponents[challenge.difficulty]!.image[index]),
                        ),
                      );
                    },
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

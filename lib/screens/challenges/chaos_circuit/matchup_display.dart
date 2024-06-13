import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   // Refresh the usersProvider when this widget is inserted into the tree.
  //   ref.refresh(usersProvider);
  // }

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
                        return Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            dense: true,
                            title: Text(user.username,
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            subtitle: Text('Team Member',
                                style: Theme.of(context).textTheme.bodySmall),
                            leading: CircleAvatar(
                              backgroundColor: _hexToColor(user.color),
                            ),
                          ),
                        );
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

  Color _hexToColor(String hex) {
    hex = hex.replaceAll("#", "");
    if (hex.length == 6) {
      hex = "ff$hex";
    }
    return Color(int.parse(hex, radix: 16));
  }
}

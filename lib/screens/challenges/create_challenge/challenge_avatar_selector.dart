import 'package:flutter/material.dart';
import 'package:ride_tide_stride/models/challenge.dart';
import 'package:ride_tide_stride/theme.dart';

class ChallengeAvatarSelector extends StatelessWidget {
  final List<Challenge> challenges;
  final Function(Challenge) onChallengeSelected;
  final String selectedChallenge;

  const ChallengeAvatarSelector({
    super.key,
    required this.challenges,
    required this.onChallengeSelected,
    required this.selectedChallenge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: challenges
            .map((challenge) => GestureDetector(
                  onTap: () {
                    onChallengeSelected(challenge);
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        maxRadius:
                            selectedChallenge == challenge.name ? 30.0 : 15.0,
                        child: ClipOval(
                          child: Image.asset(challenge.assetPath),
                        ),
                      ),
                      selectedChallenge == challenge.name
                          ? Text(
                              challenge.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : SizedBox(),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

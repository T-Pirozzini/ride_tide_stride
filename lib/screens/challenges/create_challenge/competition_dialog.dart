// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ride_tide_stride/models/challenge.dart';
import 'package:ride_tide_stride/screens/challenges/create_challenge/challenge_avatar_selector.dart';
import 'package:ride_tide_stride/theme.dart';

class AddCompetitionDialog extends StatefulWidget {
  @override
  State<AddCompetitionDialog> createState() => _AddCompetitionDialogState();
}

class _AddCompetitionDialogState extends State<AddCompetitionDialog> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isPublic = true;
  bool _isVisible = true;
  String _selectedChallenge = "Mtn Scramble";
  TextEditingController _challengeNameController = TextEditingController();
  TextEditingController _challengePasswordController = TextEditingController();
  TextEditingController _challengeDescriptionController =
      TextEditingController();
  String _selectedDescription =
      "Team based challenge where the most elevation gain wins!";

  final List<Challenge> _challenges = [
    Challenge(
        name: "Mtn Scramble",
        assetPath: 'assets/images/mtn.png',
        description: "Team based challenge where the most elevation gain wins!",
        previewPaths: [
          'assets/images/Fuji.png',
          'assets/images/Kilimanjaro.png',
          'assets/images/Everest.png'
        ]),
    Challenge(
        name: "Snow2Surf",
        assetPath: 'assets/images/snow2surf.png',
        description:
            "Compete across multiple legs/activities from the mountain to the sea!",
        previewPaths: ['assets/images/snow2surf_preview.jpg']),
    Challenge(
        name: "Team Traverse",
        assetPath: 'assets/images/teamTraverse.png',
        description: "Cooperatively traverse across various landscapes!",
        previewPaths: [
          'assets/images/pei.png',
          'assets/images/van_isle.png',
          'assets/images/greenland.png'
        ]),
  ];

  final List<String> challengeNamesTeamTraverse = [
    "P.E.I",
    "Van Isle",
    "Greenland",
  ];

  final List<String> challengeDistancesTeamTraverse = [
    "280kms",
    "456kms",
    "1050kms",
  ];

  final List<String> challengeNamesMtnScramble = [
    "Mount Fuji",
    "Mount Kilimanjaro",
    "Mount Everest",
  ];

  final List<String> challengeElevationsMtnScramble = [
    "3775",
    "5895",
    "8848",
  ];

  String _selectedLevelButton = 'Cooperative';
  String _selectedDifficultyButton = 'Intro';
  String _selectedCategoryButton = 'Open';
  String _selectedActivityButton = 'Running';
  Map<String, bool> _selectedActivities = {
    'Alpine Skiing': false,
    'Nordic Skiing': false,
    'Road Running': false,
    'Trail Running': false,
    'Mountain Biking': false,
    'Kayaking': false,
    'Road Cycling': false,
    'Canoeing': false,
  };

  final PageController _pageController = PageController(viewportFraction: 1);
  int _currentPage = 0;

  void toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  void togglePrivacy() {
    setState(() {
      _isPublic = !_isPublic;
    });
  }

  void _updateDifficultyButton(String challengeName, int currentPage) {
    if (challengeName == "Team Traverse") {
      switch (challengeNamesTeamTraverse[currentPage]) {
        case "P.E.I":
          _selectedDifficultyButton = "Intro";
          break;
        case "Van Isle":
          _selectedDifficultyButton = "Advanced";
          break;
        case "Greenland":
          _selectedDifficultyButton = "Expert";
          break;
      }
    } else if (challengeName == "Mtn Scramble") {
      switch (challengeNamesMtnScramble[currentPage]) {
        case "Mount Fuji":
          _selectedDifficultyButton = "Intro";
          break;
        case "Mount Kilimanjaro":
          _selectedDifficultyButton = "Advanced";
          break;
        case "Mount Everest":
          _selectedDifficultyButton = "Expert";
          break;
      }
    }
  }

  // Method to build page indicators
  Widget _buildPageIndicators(int length, int currentPage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        length,
        (index) => Container(
          width: 8.0,
          height: 8.0,
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentPage == index
                ? AppColors.primaryColor
                : AppColors.primaryColor.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  Future<void> saveChallengeToFirestore() async {
    Challenge selectedChallenge = _challenges.firstWhere(
      (challenge) => challenge.name == _selectedChallenge,
      orElse: () => _challenges.first,
    );

    // Prepare data to be saved
    Map<String, dynamic> challengeData = {
      'type': selectedChallenge.name,
      'name': _challengeNameController.text,
      'description': selectedChallenge.description,
      'userDescription': _challengeDescriptionController.text,
      'isPublic': _isPublic,
      'password': _isPublic ? '' : _challengePasswordController.text.trim(),
      'isVisible': _isVisible,
      'previewPaths': selectedChallenge.previewPaths,
      'timestamp': FieldValue.serverTimestamp(),
      'createdBy': currentUser!.uid,
      'userEmail': currentUser!.email,
      'participants': [currentUser!.email],
      'active': true,
      'success': false,
      // Add more fields as needed
    };

    // If the selected challenge is "Team Traverse", add specific details
    if (selectedChallenge.name == "Team Traverse" &&
        _currentPage < selectedChallenge.previewPaths.length) {
      challengeData['currentMap'] =
          selectedChallenge.previewPaths[_currentPage];
      challengeData['category'] = _selectedCategoryButton;
      challengeData['categoryActivity'] = _selectedActivityButton;
      challengeData['mapName'] = challengeNamesTeamTraverse[_currentPage];
      challengeData['mapDistance'] =
          challengeDistancesTeamTraverse[_currentPage];
      _updateDifficultyButton(selectedChallenge.name, _currentPage);
      challengeData['difficulty'] = _selectedDifficultyButton;
    }

    // If the selected challenge is "Mtn Scramble", add specific details
    if (selectedChallenge.name == "Mtn Scramble" &&
        _currentPage < selectedChallenge.previewPaths.length) {
      challengeData['currentMap'] =
          selectedChallenge.previewPaths[_currentPage];
      challengeData['category'] = _selectedCategoryButton;
      challengeData['categoryActivity'] = _selectedActivityButton;
      challengeData['mapName'] = challengeNamesMtnScramble[_currentPage];
      challengeData['mapElevation'] =
          challengeElevationsMtnScramble[_currentPage];
      _updateDifficultyButton(selectedChallenge.name, _currentPage);
      challengeData['difficulty'] = _selectedDifficultyButton;
    }

    // If the selected challenge is "Snow2Surf", add specific details
    if (selectedChallenge.name == "Snow2Surf") {
      challengeData['currentMap'] =
          selectedChallenge.previewPaths[_currentPage];
      challengeData['difficulty'] = _selectedDifficultyButton;
      challengeData['legsSelected'] = _selectedActivities.entries
          .where((element) => element.value == true)
          .map((e) => e.key)
          .toList();
      challengeData['legParticipants'] = {};
    }

    // Get a reference to the Firestore service
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Add the challenge to the 'Challenges' collection
    await firestore.collection('Challenges').add(challengeData).then((docRef) {
      print("Challenge added with ID: ${docRef.id}");
    }).catchError((error) {
      print("Error adding challenge: $error");
    });
  }

  Future<void> selectActivityLegs() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Legs'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              // Add this wrapper
              builder: (BuildContext context, StateSetter setState) {
                return ListBody(
                  children: _selectedActivities.keys.map((String key) {
                    return CheckboxListTile(
                      title: Text(key),
                      value: _selectedActivities[key],
                      onChanged: (bool? value) {
                        int selectedCount =
                            _selectedActivities.values.where((v) => v).length;
                        // Check if trying to select more than 4 activities
                        if (value == true && selectedCount >= 4) {
                          // Optionally, show a dialog or toast to inform the user
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext bc) {
                              return Container(
                                child: Wrap(
                                  children: <Widget>[
                                    ListTile(
                                      leading: new Icon(Icons.warning),
                                      title: new Text(
                                          'You must select only 4 activities.'),
                                      onTap: () => {},
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        } else {
                          setState(() {
                            _selectedActivities[key] = value!;
                          });
                        }
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Done'),
              onPressed: () {
                // Process the selected activities as needed
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double contentWidth = MediaQuery.of(context).size.width * 0.7;
    // Find the currently selected challenge
    Challenge currentChallenge = _challenges.firstWhere(
      (challenge) => challenge.name == _selectedChallenge,
      orElse: () => _challenges.first,
    );

    // Determine if we should use a PageView based on the selected challenge having multiple images
    bool usePageView = currentChallenge.name == "Team Traverse" ||
        currentChallenge.name == "Mtn Scramble" &&
            currentChallenge.previewPaths.length > 1;

    // Create a method to get the name and distance for the current challenge and page
    String getNameAndDistance(int currentPage) {
      if (currentChallenge.name == "Team Traverse" &&
          currentPage < currentChallenge.previewPaths.length) {
        return "${challengeNamesTeamTraverse[currentPage]}: ${challengeDistancesTeamTraverse[currentPage]}";
      } else if (currentChallenge.name == 'Mtn Scramble' &&
          currentPage < currentChallenge.previewPaths.length) {
        return "${challengeNamesMtnScramble[currentPage]}: ${challengeElevationsMtnScramble[currentPage]}m";
      } else {
        return "";
      }
    }

    return AlertDialog(
      content: Builder(builder: (context) {
        return SingleChildScrollView(
          child: Container(
            width: contentWidth,
            // height: contentHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedLevelButton = 'Cooperative';
                        });
                      },
                      child: Text('Cooperative'),
                      style: _selectedLevelButton == 'Cooperative'
                          ? TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: AppColors.secondaryAccent,
                            )
                          : null,
                    ),
                    Icon(Icons.swap_horiz_rounded,
                        color: AppColors.secondaryColor),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedLevelButton = 'Competitive';
                        });
                      },
                      child: Text('Competitive'),
                      style: _selectedLevelButton == 'Competitive'
                          ? TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: AppColors.secondaryAccent,
                            )
                          : null,
                    ),
                  ],
                ),
                _selectedLevelButton == "Cooperative"
                    ? Text(
                        'Work together to complete a challenge!',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    : Text(
                        'Compete against others!',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategoryButton = 'Open';
                        });
                      },
                      child: Text('Open'),
                      style: _selectedCategoryButton == 'Open'
                          ? TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: AppColors.primaryColor,
                            )
                          : null,
                    ),
                    Icon(Icons.swap_horiz_rounded,
                        color: AppColors.primaryColor),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategoryButton = 'Specific';
                        });
                      },
                      child: Text('Specific'),
                      style: _selectedCategoryButton == 'Specific'
                          ? TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: AppColors.primaryColor,
                            )
                          : null,
                    ),
                  ],
                ),
                _selectedCategoryButton == "Open"
                    ? Text('All activity types are welcome!',
                        style: Theme.of(context).textTheme.bodyMedium)
                    : Text('Specify an activity type!',
                        style: Theme.of(context).textTheme.bodyMedium),
                Container(
                  height: 60,
                  child: _selectedCategoryButton == "Specific"
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedActivityButton = 'Running';
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(
                                    8), // Padding around the icon
                                decoration: BoxDecoration(
                                  color: _selectedActivityButton == 'Running'
                                      ? AppColors
                                          .secondaryColor // Selected Color
                                      : Colors.transparent, // Default Color
                                  shape: BoxShape.circle, // Circular shape
                                ),
                                child: Icon(
                                  Icons.directions_run,
                                  color: _selectedActivityButton == 'Running'
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedActivityButton = 'Cycling';
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(
                                    8), // Padding around the icon
                                decoration: BoxDecoration(
                                  color: _selectedActivityButton == 'Cycling'
                                      ? AppColors
                                          .secondaryColor // Selected Color
                                      : Colors.transparent, // Default Color
                                  shape: BoxShape.circle, // Circular shape
                                ),
                                child: Icon(
                                  Icons.directions_bike,
                                  color: _selectedActivityButton == 'Cycling'
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                            if (currentChallenge.name != "Mtn Scramble")
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedActivityButton = 'Paddling';
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(
                                      8), // Padding around the icon
                                  decoration: BoxDecoration(
                                    color: _selectedActivityButton == 'Paddling'
                                        ? AppColors
                                            .secondaryColor // Selected Color
                                        : Colors.transparent, // Default Color
                                    shape: BoxShape.circle, // Circular shape
                                  ),
                                  child: Icon(
                                    Icons.kayaking_outlined,
                                    color: _selectedActivityButton == 'Paddling'
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Container(
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                              Icon(Icons.directions_run),
                              Icon(Icons.directions_bike),
                              Icon(Icons.kayaking_outlined),
                              Icon(Icons.pool_outlined),
                              Icon(Icons.snowboarding_outlined),
                              Icon(Icons.ice_skating_outlined),
                              Icon(Icons.snowshoeing_outlined),
                            ])),
                ),
                ChallengeAvatarSelector(
                    challenges: _challenges,
                    selectedChallenge: _selectedChallenge,
                    onChallengeSelected: (challenge) {
                      setState(() {
                        _selectedChallenge = challenge.name;
                        _selectedDescription = challenge.description;
                      });
                    }),
                SizedBox(height: 5),
                Container(
                  height: 40,
                  child: Text(_selectedDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                ),
                Container(
                  height: 200,
                  child: Expanded(
                    child: usePageView
                        ? Column(
                            children: [
                              Container(
                                height: 150,
                                child: PageView(
                                  controller: _pageController,
                                  onPageChanged: (int page) {
                                    setState(() {
                                      _currentPage = page;
                                      _updateDifficultyButton(
                                          _selectedChallenge, page);
                                    });
                                  },
                                  children:
                                      currentChallenge.previewPaths.map((path) {
                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          getNameAndDistance(_currentPage),
                                          style: TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Icon(
                                                Icons
                                                    .keyboard_double_arrow_left,
                                                size: 30,
                                                color: AppColors.primaryColor),
                                            Container(
                                              height: 100,
                                              child: Image.asset(
                                                path,
                                                fit: BoxFit.fitHeight,
                                                height: 150,
                                              ),
                                            ),
                                            Icon(
                                                Icons
                                                    .keyboard_double_arrow_right,
                                                size: 30,
                                                color: AppColors.primaryColor),
                                          ],
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                              _buildPageIndicators(
                                currentChallenge.previewPaths.length,
                                _currentPage,
                              ),
                              Text(_selectedDifficultyButton,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                            ],
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: Image.asset(
                                  currentChallenge.previewPaths.first,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedDifficultyButton = 'Intro';
                                      });
                                    },
                                    child: Text('Intro'),
                                    style: _selectedDifficultyButton == 'Intro'
                                        ? TextButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor:
                                                AppColors.primaryColor,
                                          )
                                        : null,
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedDifficultyButton = 'Advanced';
                                      });
                                    },
                                    child: Text('Advanced'),
                                    style:
                                        _selectedDifficultyButton == 'Advanced'
                                            ? TextButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                backgroundColor:
                                                    AppColors.primaryColor,
                                              )
                                            : null,
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedDifficultyButton = 'Expert';
                                      });
                                    },
                                    child: Text('Expert'),
                                    style: _selectedDifficultyButton == 'Expert'
                                        ? TextButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor:
                                                AppColors.primaryColor,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () async {
                                  await selectActivityLegs();
                                  setState(() {});
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: AppColors.secondaryAccent,
                                ),
                                child: Text(
                                    'Select Activity Legs (${_selectedActivities.values.where((v) => v).length} of 4)'),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 250,
                      height: 30,
                      child: TextFormField(
                        controller: _challengeNameController,
                        decoration: InputDecoration(
                          labelText: 'Name Your Team...',
                          labelStyle: Theme.of(context).textTheme.bodyMedium,
                          hintStyle: Theme.of(context).textTheme.bodyMedium,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    Container(
                      width: 300,
                      height: 30,
                      child: TextFormField(
                        controller: _challengeDescriptionController,
                        decoration: InputDecoration(
                            labelText: 'Add a description (optional)',
                            labelStyle: Theme.of(context).textTheme.bodyMedium,
                            hintStyle: Theme.of(context).textTheme.bodyMedium,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            )),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Container(
                  width: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Column(
                            children: [
                              ButtonTheme(
                                minWidth:
                                    32.0, // Ensure the buttons have a consistent width
                                height: 32.0,
                                child: OutlinedButton(
                                  onPressed: togglePrivacy,
                                  style: OutlinedButton.styleFrom(
                                    shape: CircleBorder(),
                                    padding: EdgeInsets.all(5),
                                  ),
                                  child: Icon(
                                      _isPublic ? Icons.lock_open : Icons.lock),
                                ),
                              ),
                              Text(_isPublic ? 'Public' : 'Private',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                          Flexible(
                            child: _isPublic
                                ? Text('Anyone can join your challenge',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium)
                                : TextFormField(
                                    controller: _challengePasswordController,
                                    decoration: InputDecoration(
                                        labelText: 'Enter a password...',
                                        isDense: true,
                                        labelStyle: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                        )),
                                  ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Column(
                            children: [
                              ButtonTheme(
                                minWidth:
                                    32.0, // Ensure the buttons have a consistent width
                                height: 32.0,
                                child: OutlinedButton(
                                  onPressed: toggleVisibility,
                                  style: OutlinedButton.styleFrom(
                                    shape: CircleBorder(),
                                    padding: EdgeInsets.all(5),
                                  ),
                                  child: Icon(_isVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                ),
                              ),
                              Text(_isVisible ? 'Visible' : 'Hidden',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                          Flexible(
                            child: Text(
                                _isVisible
                                    ? 'Everyone can view your challenge'
                                    : 'Your challenge is private',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () {
                if (_challengeNameController.text.trim().isEmpty) {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext bc) {
                      return Container(
                        child: Wrap(
                          children: <Widget>[
                            ListTile(
                              leading: new Icon(Icons.warning),
                              title: new Text('Please create a team name.'),
                              onTap: () => {},
                            ),
                          ],
                        ),
                      );
                    },
                  );
                } else if (!_isPublic &&
                    _challengePasswordController.text.trim().isEmpty) {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext bc) {
                      return Container(
                        child: Wrap(
                          children: <Widget>[
                            ListTile(
                              leading: new Icon(Icons.warning),
                              title: new Text('Please enter a password.'),
                              onTap: () => {},
                            ),
                          ],
                        ),
                      );
                    },
                  );
                } else {
                  // Call the method to save the challenge
                  saveChallengeToFirestore().then((_) {
                    // Close the dialog or show a confirmation message
                    Navigator.of(context).pop();
                    // Show a Snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Challenge created successfully'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }).catchError(
                    (error) {
                      // Optionally handle errors, e.g., show an error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to create challenge'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                  );
                }
                ;
              },
              child: Text('Create Challenge'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.primaryColor,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }
}

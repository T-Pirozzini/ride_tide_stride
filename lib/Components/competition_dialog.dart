import 'package:flutter/material.dart';
import 'package:ride_tide_stride/models/challenge.dart';

class AddCompetitionDialog extends StatefulWidget {
  @override
  State<AddCompetitionDialog> createState() => _AddCompetitionDialogState();
}

class _AddCompetitionDialogState extends State<AddCompetitionDialog> {
  bool _isPublic = true;
  bool _isVisible = true;
  String _selectedChallenge = "Mtn Scramble";
  String _selectedDescription =
      "Team based challenge where the most elevation gain wins!";

  final List<Challenge> _challenges = [
    Challenge(
        name: "Mtn Scramble",
        assetPath: 'assets/images/mtn.png',
        description: "Team based challenge where the most elevation gain wins!",
        previewPaths: ['assets/images/mtn.png']),
    Challenge(
        name: "Snow2Surf",
        assetPath: 'assets/images/snow2surf.png',
        description:
            "Compete across multiple legs/activities from the mountain to the sea!",
        previewPaths: ['assets/images/snow2surf.png']),
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

  final List<String> challengeNames = [
    "P.E.I",
    "Van Isle",
    "Iceland",
  ];

  final List<String> challengeDistances = [
    "280kms",
    "456kms",
    "1050kms",
  ];

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
                ? Theme.of(context).primaryColor
                : Theme.of(context).primaryColor.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double contentWidth = MediaQuery.of(context).size.width * 0.7;
    double contentHeight = MediaQuery.of(context).size.height * 0.7;
    // Find the currently selected challenge
    Challenge currentChallenge = _challenges.firstWhere(
      (challenge) => challenge.name == _selectedChallenge,
      orElse: () => _challenges.first,
    );

    // Determine if we should use a PageView based on the selected challenge having multiple images
    bool usePageView = currentChallenge.name == "Team Traverse" &&
        currentChallenge.previewPaths.length > 1;

    // Create a method to get the name and distance for the current challenge and page
    String getNameAndDistance(int currentPage) {
      if (currentChallenge.name == "Team Traverse" &&
          currentPage < currentChallenge.previewPaths.length) {
        return "${challengeNames[currentPage]}: ${challengeDistances[currentPage]}";
      } else {
        return "";
      }
    }

    return AlertDialog(
      title: Center(child: Text('Create a Challenge')),
      content: Container(
        width: contentWidth,
        height: contentHeight,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _challenges
                      .map((challenge) => GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedChallenge = challenge.name;
                                _selectedDescription = challenge.description;
                              });
                            },
                            child: CircleAvatar(
                              maxRadius: _selectedChallenge == challenge.name
                                  ? 30.0
                                  : 20.0,
                              child: ClipOval(
                                child: Image.asset(challenge.assetPath),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              Container(
                height: 150,
                child: usePageView
                    ? Column(
                        children: [
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              onPageChanged: (int page) {
                                setState(() {
                                  _currentPage = page;
                                });
                              },
                              children:
                                  currentChallenge.previewPaths.map((path) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      getNameAndDistance(_currentPage),
                                      style: TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(
                                        height:
                                            10), // Adjust the spacing between Text and Image
                                    Image.asset(
                                      path,
                                      fit: BoxFit.fitHeight,
                                      height:
                                          80, // Adjust the image height as needed
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
                        ],
                      )
                    : Image.asset(
                        currentChallenge.previewPaths.first,
                        fit: BoxFit.cover,
                      ),
              ),
              Container(
                height: 50,
                child: Column(
                  children: [
                    Text(_selectedChallenge,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(_selectedDescription,
                        style: TextStyle(
                            fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              SizedBox(height: 5),
              TextFormField(
                decoration: InputDecoration(
                    labelText: 'Name your challenge...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    )),
              ),
              SizedBox(height: 15),
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
                                onPressed: toggleVisibility,
                                style: OutlinedButton.styleFrom(
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(15),
                                ),
                                child: Icon(_isVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                              ),
                            ),
                            Text(_isVisible ? 'Visible' : 'Hidden'),
                          ],
                        ),
                        Flexible(
                          child: Text(
                              _isVisible
                                  ? 'Allow others to view your challenge'
                                  : 'Keep your challenge private',
                              style: TextStyle(fontSize: 12)),
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
                                  64.0, // Ensure the buttons have a consistent width
                              height: 64.0,
                              child: OutlinedButton(
                                onPressed: togglePrivacy,
                                style: OutlinedButton.styleFrom(
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(15),
                                ),
                                child: Icon(
                                    _isPublic ? Icons.lock_open : Icons.lock),
                              ),
                            ),
                            Text(_isPublic ? 'Public' : 'Private'),
                          ],
                        ),
                        Flexible(
                          child: Text(
                              _isPublic
                                  ? 'Allow anyone to join your challenge'
                                  : 'Only allow participants with a passcode',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              !_isPublic
                  ? TextFormField(
                      decoration: InputDecoration(
                          labelText: 'Enter a password...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          )),
                    )
                  : SizedBox(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Add'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }
}

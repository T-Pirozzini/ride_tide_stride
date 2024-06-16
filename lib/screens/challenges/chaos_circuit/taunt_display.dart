import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_tide_stride/helpers/helper_data_sets.dart';
import 'package:ride_tide_stride/helpers/helper_functions.dart';

class TauntDisplay extends ConsumerStatefulWidget {
  final participantEmails;
  final challengeDifficulty;

  const TauntDisplay(
      {Key? key,
      required this.participantEmails,
      required this.challengeDifficulty})
      : super(key: key);

  @override
  _TauntDisplayState createState() => _TauntDisplayState();
}

class _TauntDisplayState extends ConsumerState<TauntDisplay> {
  String taunt = "Loading...";
  List opponentNames = [];

  @override
  void initState() {
    super.initState();
    fetchTaunt();
    setupOpponents();
  }

  void setupOpponents() {
    // Ensure that opponents map contains the difficulty level
    if (opponents.containsKey(widget.challengeDifficulty)) {
      opponentNames =
          List<String>.from(opponents[widget.challengeDifficulty]['name']);
      opponentNames.shuffle();
    }
  }

  Future<void> fetchTaunt() async {
    try {
      // Convert each email into a getUsername future and create a list of those futures
      List<Future<String>> usernameFutures = widget.participantEmails
          .map<Future<String>>((email) => getUsername(
                  email.toString()) // Make sure to call toString() if necessary
              )
          .toList(); // Make sure to convert it to a List

      // Now you can use Future.wait on a List<Future<String>>
      List<String> usernames = await Future.wait(usernameFutures);
      String opponent =
          opponentNames.isNotEmpty ? opponentNames.first : "Opponent";
      String opponentTeamName = opponents[widget.challengeDifficulty]
          ['teamName']; // Get the team name from the opponents map
      final response = await OpenAI.instance.chat.create(
        model: "gpt-3.5-turbo-0125", // Using the correct GPT-4o model
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
              role: OpenAIChatMessageRole
                  .system, // Use the enum value for system role
              content: [
                OpenAIChatCompletionChoiceMessageContentItemModel.text(
                    "You are an AI named $opponent designed to generate creative and sometimes rude or arrogant taunts for a competitive exercise challenge.")
              ]),
          OpenAIChatCompletionChoiceMessageModel(
              role: OpenAIChatMessageRole
                  .user, // Use the enum value for user role
              content: [
                OpenAIChatCompletionChoiceMessageContentItemModel.text(
                    "Generate a creative taunt for an exercise challenge. You and your 3 teammates are against these humans: ${usernames.join(", ")}. Call out only one of the specific users by name in your taunt. List your name followed by a colon before your taunt. Taunt in the style of your team name: $opponentTeamName and true to the character of: $opponent.")
              ]),
        ],
      );

      // Extract text properties, filter nulls, and convert to List<String>
      List<String> contents = response.choices.first.message.content!
          .map((item) => item.text)
          .where((text) => text != null)
          .map((text) => text!)
          .toList();

      // Join all strings and trim the final result
      String newTaunt = contents.join(" ").trim();

      setState(() {
        taunt = newTaunt;
      });
    } catch (e) {
      setState(() {
        taunt = "Failed to fetch taunt. Please try again later.";
      });
      print("Error fetching taunt: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TypewriterText(
            taunt,
            style: GoogleFonts.electrolize(
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;

  const TypewriterText(this.text,
      {Key? key, this.style, this.duration = const Duration(milliseconds: 50)})
      : super(key: key);

  @override
  _TypewriterTextState createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = "";
  Timer? _timer;
  int _charPosition = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _resetAndStartTyping();
    }
  }

  void _resetAndStartTyping() {
    _timer?.cancel();
    _displayedText = "";
    _charPosition = 0;
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.duration, (timer) {
      if (_charPosition < widget.text.length) {
        setState(() {
          _displayedText += widget.text[_charPosition];
          _charPosition++;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style,
    );
  }
}

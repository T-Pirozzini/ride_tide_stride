import 'package:flutter/material.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TauntDisplay extends StatefulWidget {
  @override
  _TauntDisplayState createState() => _TauntDisplayState();
}

class _TauntDisplayState extends State<TauntDisplay> {
  String taunt = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchTaunt();
  }

  Future<void> fetchTaunt() async {
    try {
      final response = await OpenAI.instance.chat.create(
        model: "gpt-3.5-turbo-0125", // Using the correct GPT-4o model
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
              role: OpenAIChatMessageRole
                  .system, // Use the enum value for system role
              content: [
                OpenAIChatCompletionChoiceMessageContentItemModel.text(
                    "You are an AI designed to generate creative taunts for games.")
              ]),
          OpenAIChatCompletionChoiceMessageModel(
              role: OpenAIChatMessageRole
                  .user, // Use the enum value for user role
              content: [
                OpenAIChatCompletionChoiceMessageContentItemModel.text(
                    "Generate a creative taunt for a game challenge.")
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
      appBar: AppBar(
        title: Text("Daily Taunt"),
      ),
      body: Center(
        child: Text(
          taunt,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AddCompetitionDialog extends StatefulWidget {
  @override
  State<AddCompetitionDialog> createState() => _AddCompetitionDialogState();
}

class _AddCompetitionDialogState extends State<AddCompetitionDialog> {
  void onPressed() {
    // Add your logic to handle the button press here
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(child: Text('Create A Competition')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CircleAvatar(
                maxRadius: 40,
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/mtn.png',
                  ),
                ),
              ),
              CircleAvatar(
                maxRadius: 40,
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/snow2surf.png',
                  ),
                ),
              ),
              CircleAvatar(
                maxRadius: 40,
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/teamTraverse.png',
                  ),
                ),
              ),
            ],
          ),
          // Add your form fields for competition details here
          // You can use TextFormField, DropdownButton, etc. as needed
          TextFormField(
            decoration: InputDecoration(labelText: 'Competition Name'),
          ),
          SizedBox(height: 20),
          // Add other fields and widgets for different competition types
          // Customize this part based on your competition types
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Add your logic to handle the form submission here
            // Create a new competition based on the entered details
            // Close the dialog if the submission is successful
            Navigator.of(context).pop();
          },
          child: Text('Add'),
        ),
        TextButton(
          onPressed: () {
            // Close the dialog if the user cancels
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }
}

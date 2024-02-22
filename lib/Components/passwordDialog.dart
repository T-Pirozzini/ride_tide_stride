import 'package:flutter/material.dart';

class PasswordDialog extends StatefulWidget {
  final String challengePassword;

  const PasswordDialog({Key? key, required this.challengePassword}) : super(key: key);

  @override
  _PasswordDialogState createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter Challenge Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: _errorMessage,
            ),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_passwordController.text == widget.challengePassword) {
              Navigator.of(context).pop(true); // Password is correct
            } else {
              setState(() => _errorMessage = 'Incorrect password');
            }
          },
          child: Text('Submit'),
        ),
      ],
    );
  }
}

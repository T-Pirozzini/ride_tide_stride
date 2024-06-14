import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:dice_bear/dice_bear.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ride_tide_stride/helpers/helper_functions.dart'; // Import the flutter_svg package

Future<Map<String, String>> getUserInfo() async {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
      .collection('Users')
      .doc(currentUser!.email)
      .get();

  print("CurrentUser: $currentUser");

  Map<String, dynamic>? data = docSnapshot.data() as Map<String, dynamic>?;

  String username = data?['username'] as String? ?? '';
  String email = data?['email'] as String? ?? '';
  String color = data?['color'] as String? ?? '#FFD700';
  String avatarUrl = data?['avatarUrl'] as String? ?? 'No Avatar';

  return {
    'username': username,
    'email': email,
    'color': color,
    'avatarUrl': avatarUrl,
  };
}

void updateProfile(BuildContext context, VoidCallback onProfileUpdated) async {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  Map<String, String> userInfo = await getUserInfo();
  Color pickedColor = hexToColor(userInfo["color"]!);
  String _avatarUrl = userInfo['avatarUrl']!;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      TextEditingController usernameController =
          TextEditingController(text: userInfo['username']);
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit Profile'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      hintText: "Enter new username",
                      labelText: "New Username",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[200],
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: pickedColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: _avatarUrl != 'No Avatar'
                              ? SvgPicture.network(
                                  _avatarUrl,
                                  height: 80,
                                )
                              : Icon(Icons.person, size: 80),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Avatar avatar = DiceBearBuilder(
                              seed: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                              sprite: DiceBearSprite.bottts,
                            ).build();
                            setState(() {
                              _avatarUrl = avatar.svgUri.toString();
                            });
                          },
                          child: Text('Generate New Avatar'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SlidePicker(
                    colorModel: ColorModel.rgb,
                    enableAlpha: false,
                    pickerColor: pickedColor,
                    onColorChanged: (Color color) {
                      setState(() {
                        pickedColor = color;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
              TextButton(
                child: Text('Save'),
                onPressed: () async {
                  String colorString =
                      '#${pickedColor.value.toRadixString(16).padLeft(8, '0')}';
                  await FirebaseFirestore.instance
                      .collection('Users')
                      .doc(currentUser!.email)
                      .update({
                    'color': colorString,
                    'username': usernameController.text,
                    'avatarUrl': _avatarUrl,
                  });
                  onProfileUpdated();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    },
  );
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ride_tide_stride/main.dart';

class FirebaseApi {
  // create an instance of FirebaseMessaging
  final _firebaseMessaging = FirebaseMessaging.instance;

  //function to initialize notifications
  Future<void> initNotifications() async {
    // request permission from user (will prompt user)
    await _firebaseMessaging.requestPermission();

    // fetch the FCM token for this device
    final fcmToken = await _firebaseMessaging.getToken();

    // print the token
    print('Token: ' + fcmToken.toString());

    // initialize further settings for push notifications
    initPushNotifications();
  }

  // function to handle received messages
  void handleMessage(RemoteMessage? message) {
    // if the message is null, do nothing
    if (message == null) return;

    // navigate to new screen when message is received and user taps notification
    navigatorKey.currentState!.pushNamed('/usersPage', arguments: message);
  }

  // function to initialize foreground and background settings
  Future initPushNotifications() async {
    // handle notifications if the app was terminated and now opened
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

    // attach event listeners for when a notificiation opent the app
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  } 
}

// void _setupFCM() async {
//     FirebaseMessaging messaging = FirebaseMessaging.instance;
//     String? token = await messaging.getToken();
//     print("FCM Token: $token");
//     if (token != null) {
//       // Save the token to Firestore (example)
//       _saveTokenToFirestore(token);
//     }

//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       print('Got a message whilst in the foreground!');
//       print('Message data: ${message.data}');

//       if (message.notification != null) {
//         print('Message also contained a notification: ${message.notification}');
//       }
//     });
//   }

//   void _saveTokenToFirestore(String token) async {
//     // Get the current user's email or ID (example)
//     String userEmail =
//         currentUser!.email.toString(); // Replace with actual user email or ID

//     await FirebaseFirestore.instance.collection('Users').doc(userEmail).update({
//       'fcmToken': token,
//     });
//   }

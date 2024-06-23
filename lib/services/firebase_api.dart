import 'dart:convert';

// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:ride_tide_stride/main.dart';

// class FirebaseApi {
  // create an instance of FirebaseMessaging
//   final _firebaseMessaging = FirebaseMessaging.instance;

//   final _androidChannel = const AndroidNotificationChannel(
//     'high_importance_channel', // id
//     'High Importance Notifications', // title
//     description:
//         'This channel is used for important notifications.', // description
//     importance: Importance.defaultImportance,
//   );

//   final _localNotifications = FlutterLocalNotificationsPlugin();

//   Future<void> handleBackgroundMessage(RemoteMessage message) async {
//     if (message.notification != null) {
//       print('Title: ${message.notification!.title}');
//       print('Body: ${message.notification!.body}');
//       print('Payload: ${message.data}');
//     }
//   }

//   // function to handle received messages
//   void handleMessage(RemoteMessage? message) {
//     // if the message is null, do nothing
//     if (message == null) return;

//     // navigate to new screen when message is received and user taps notification
//     navigatorKey.currentState!.pushNamed('/usersPage', arguments: message);
//   }

//   Future initLocalNotifications() async {
//     final android = AndroidInitializationSettings('@drawable/ic_launcher');
//     final iOS = DarwinInitializationSettings();
//     final settings = InitializationSettings(android: android, iOS: iOS);
//     await _localNotifications.initialize(settings,
//         onDidReceiveNotificationResponse: (NotificationResponse response) {
//       final payload = response.payload;
//       if (payload != null) {
//         final message = RemoteMessage.fromMap(jsonDecode(payload));
//         handleMessage(message);
//       }
//     });
//     final platform = _localNotifications.resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin>()!;
//     await platform?.createNotificationChannel(_androidChannel);
//   }

//   // function to initialize foreground and background settings
//   Future initPushNotifications() async {
//     await FirebaseMessaging.instance
//         .setForegroundNotificationPresentationOptions(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//     // handle notifications if the app was terminated and now opened
//     FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

//     // attach event listeners for when a notificiation opens the app
//     FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

//     // FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

//     FirebaseMessaging.onMessage.listen((message) {
//       final notification = message.notification;
//       if (notification == null) return;

//       _localNotifications.show(
//         notification.hashCode,
//         notification.title,
//         notification.body,
//         NotificationDetails(
//           android: AndroidNotificationDetails(
//             _androidChannel.id,
//             _androidChannel.name,
//             channelDescription: _androidChannel.description,
//             icon: '@drawable/ic launcher',
//             importance: _androidChannel.importance,
//           ),
//         ),
//         payload: jsonEncode(message.toMap()),
//       );
//     });
//   }

//   //function to initialize notifications
//   Future<void> initNotifications() async {
//     // request permission from user (will prompt user)
//     await _firebaseMessaging.requestPermission();

//     // fetch the FCM token for this device
//     final fcmToken = await _firebaseMessaging.getToken();

//     // print the token
//     print('Token: ' + fcmToken.toString());

//     // initialize further settings for push notifications
//     initPushNotifications();
//     initLocalNotifications();
//   }
// }

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

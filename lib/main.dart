import 'dart:async';
import 'dart:io';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_tide_stride/auth/auth_page.dart';
import 'package:ride_tide_stride/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ride_tide_stride/screens/activities/activities_page.dart';
import 'package:ride_tide_stride/screens/leaderboard/users_page.dart';
import 'package:ride_tide_stride/screens/awards/awards_page.dart';
import 'package:ride_tide_stride/screens/challenges/challenge_results_page.dart';
import 'package:ride_tide_stride/services/firebase_api.dart';
import 'package:ride_tide_stride/theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // await FirebaseApi().initNotifications();
  await dotenv.load(fileName: ".env");
  OpenAI.apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside of a text field
        // This is the current best practice for dismissing the keyboard since flutter version 2+
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: primaryTheme,
        title: 'Ride.Tide.Stride',
        home: const AuthPage(),
        navigatorKey: navigatorKey,
        routes: {
          '/awardsPage': (context) => AwardsPage(),
          '/challengeResultsPage': (context) => ChallengeResultsPage(),
          '/usersPage': (context) => UsersListPage(),
          '/activitiesPage': (context) => ActivitiesListPage(
              userEmail:
                  ModalRoute.of(context)?.settings.arguments as String? ?? ''),
        },
      ),
    );
  }
}

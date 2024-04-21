import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_tide_stride/auth/auth_page.dart';
import 'package:ride_tide_stride/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ride_tide_stride/pages/awards_page.dart';
import 'package:ride_tide_stride/pages/challenge_results_page.dart';
import 'package:ride_tide_stride/pages/results_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
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
        theme: ThemeData(
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF283D3B),
          ),
          useMaterial3: false,
          primarySwatch: const MaterialColor(
            0xFF283D3B,
            <int, Color>{
              50: Color(0xFFA09A6A),
              100: Color(0xFFA09A6A),
              200: Color(0xFFA09A6A),
              300: Color(0xFFA09A6A),
              400: Color(0xFFA09A6A),
              500: Color(0xFFA09A6A),
              600: Color(0xFFA09A6A),
              700: Color(0xFFA09A6A),
              800: Color(0xFFA09A6A),
              900: Color(0xFFA09A6A),
            },
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF283D3B),
          ),
          dialogTheme: const DialogTheme(
            backgroundColor: Colors.white,
          ),
          fontFamily: GoogleFonts.openSans().fontFamily,
          buttonTheme: const ButtonThemeData(
            buttonColor: Color(0xFFD0B8A8),
          ),
        ),
        title: 'Ride.Tide.Stride',
        home: const AuthPage(),
        routes: {
          '/resultsPage': (context) => ResultsPage(),
          '/awardsPage': (context) => AwardsPage(),
          '/challengeResultsPage': (context) => ChallengeResultsPage(),
        },
      ),
    );
  }
}

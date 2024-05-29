import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static Color primaryColor = Color(0xFF283D3B);
  static Color primaryAccent = Color(0xFF56CCF2);
  static Color secondaryColor = const Color(0xFFD0B8A8);
  static Color secondaryAccent = Color.fromARGB(255, 10, 10, 10);
  static Color backgroundColor = const Color(0xFFDFD3C3);
  static Color titleColor = Colors.black;
  static Color textColor = Colors.black;
  static Color subTextColor = Colors.grey;
  static Color successColor = const Color.fromRGBO(9, 149, 110, 1);
  static Color highlightColor = Colors.tealAccent;
}

ThemeData primaryTheme = ThemeData(
  useMaterial3: false,
  // seed color
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primaryColor,
  ),
  // scaffold color
  scaffoldBackgroundColor: AppColors.secondaryAccent,

  // app bar theme colors
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF283D3B),
    // foregroundColor: AppColors.textColor,
    surfaceTintColor: Colors.transparent,
    centerTitle: true,
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

  textTheme: const TextTheme().copyWith(
    bodySmall: TextStyle(
      color: AppColors.textColor,
      fontSize: 10,
      letterSpacing: 1,
    ),
    bodyMedium: TextStyle(
      color: AppColors.textColor,
      fontSize: 12,
      letterSpacing: 1,
    ),
    bodyLarge: TextStyle(
      color: AppColors.textColor,
      fontSize: 14,
      letterSpacing: 1,
    ),
    headlineSmall: TextStyle(
      color: AppColors.titleColor,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      letterSpacing: 1,
    ),
    headlineMedium: TextStyle(
      color: AppColors.titleColor,
      fontSize: 16,
      fontWeight: FontWeight.bold,
      letterSpacing: 1,
    ),
    headlineLarge: TextStyle(
      color: AppColors.titleColor,
      fontSize: 18,
      fontWeight: FontWeight.bold,
      letterSpacing: 1,
    ),
    titleMedium: TextStyle(
      color: AppColors.titleColor,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
    ),
  ),
);

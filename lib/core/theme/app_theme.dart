import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Neon Green Color
  static const Color neonGreen = Color(0xFF39FF14);
  // Space Black Color
  static const Color spaceBlack = Color(0xFF0B0E11);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: neonGreen,
          brightness: Brightness.dark,
          surface: spaceBlack,
          onSurface: Colors.white,
        ).copyWith(
          primary: neonGreen,
        ),
        scaffoldBackgroundColor: spaceBlack,
        textTheme: GoogleFonts.rajdhaniTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ).apply(
          bodyColor: Colors.white,
          displayColor: neonGreen,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: neonGreen,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  static List<BoxShadow> get neonGlow => [
        BoxShadow(
          color: neonGreen.withOpacity(0.5),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ];
}

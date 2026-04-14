import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color spaceBlack = Color(0xFF0B0E11);
  static const Color panelBlack = Color(0xFF1A1F24);
  static const Color errorRed = Color(0xFFFF3131);

  // Spacing (8-point scale)
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

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
          secondary: panelBlack,
          error: errorRed,
        ),
        scaffoldBackgroundColor: spaceBlack,
        textTheme: GoogleFonts.rajdhaniTextTheme(
          const TextTheme(
            headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700), // Heading 1
            titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),   // Heading 2
            bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),    // Body Large
            bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),   // Body Small
            labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),   // Caption
          ),
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
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'Rajdhani',
          ),
        ),
      );

  static List<BoxShadow> get neonGlow => [
        BoxShadow(
          color: neonGreen.withOpacity(0.5),
          blurRadius: 10,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: neonGreen.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 4,
        ),
      ];
}

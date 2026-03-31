import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyWalkColor {
  static const charcoal = Color(0xFF1E1E2E);
  static const warmWhite = Color(0xFFFAF7F2);
  static const golden = Color(0xFFD4A843);
  static const sage = Color(0xFF7A9E7E);
  static const warmCoral = Color(0xFFD4836B);
  static const softGold = Color(0xFFE8D5A3);
  static const mutedSage = Color(0xFFC5D8C7);

  static const cardBackground = Color(0xFF262638);
  static const cardBorder = Color(0x0FFFFFFF); // white 6% opacity

  static const surfaceOverlay = Color(0x0AFFFFFF); // white 4%
  static const inputBackground = Color(0x1AFFFFFF); // white 10%

  static const LinearGradient goldenGradient = LinearGradient(
    colors: [Color(0xFFD4A843), Color(0xFFE8D5A3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient warmGlow = RadialGradient(
    colors: [Color(0x1FD4A843), Color(0x0AD4A843), Colors.transparent],
    center: Alignment.topCenter,
    radius: 1.0,
  );
}

class AppTheme {
  static TextTheme _buildTextTheme(Color baseColor) {
    final inter = GoogleFonts.interTextTheme().apply(bodyColor: baseColor, displayColor: baseColor);
    return inter.copyWith(
      displayLarge: GoogleFonts.dmSerifDisplay(color: baseColor),
      displayMedium: GoogleFonts.dmSerifDisplay(color: baseColor),
      headlineLarge: GoogleFonts.dmSerifDisplay(color: baseColor, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.dmSerifDisplay(color: baseColor, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.dmSerifDisplay(color: baseColor, fontWeight: FontWeight.w600),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: MyWalkColor.charcoal,
      colorScheme: const ColorScheme.dark(
        primary: MyWalkColor.golden,
        secondary: MyWalkColor.sage,
        surface: MyWalkColor.cardBackground,
        onPrimary: MyWalkColor.charcoal,
        onSurface: MyWalkColor.warmWhite,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: MyWalkColor.charcoal,
        selectedItemColor: MyWalkColor.golden,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
        elevation: 0,
      ),
      textTheme: _buildTextTheme(MyWalkColor.warmWhite),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: MyWalkColor.warmWhite,
      colorScheme: ColorScheme.light(
        primary: MyWalkColor.golden,
        secondary: MyWalkColor.sage,
        surface: const Color(0xFFF0EDE8),
        onPrimary: MyWalkColor.charcoal,
        onSurface: MyWalkColor.charcoal,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: MyWalkColor.warmWhite,
        selectedItemColor: MyWalkColor.golden,
        unselectedItemColor: MyWalkColor.charcoal.withValues(alpha: 0.4),
        type: BottomNavigationBarType.fixed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: MyWalkColor.warmWhite,
        foregroundColor: MyWalkColor.charcoal,
        elevation: 0,
      ),
      textTheme: _buildTextTheme(MyWalkColor.charcoal),
    );
  }
}

// Reusable decoration helpers
class MyWalkDecorations {
  static BoxDecoration get card => BoxDecoration(
    color: MyWalkColor.cardBackground,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
  );

  static BoxDecoration get inputField => BoxDecoration(
    color: MyWalkColor.inputBackground,
    borderRadius: BorderRadius.circular(12),
  );
}

// Reusable button style
class MyWalkButtonStyle {
  static ButtonStyle primary({Color color = MyWalkColor.golden}) =>
      ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: MyWalkColor.charcoal,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      );
}

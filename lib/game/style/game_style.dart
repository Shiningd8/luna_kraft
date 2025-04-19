import 'package:flutter/material.dart';

/// Game style constants to maintain consistency
class GameStyle {
  // Color palette
  static const Color primaryBlue = Color(0xFF3498db);
  static const Color skyBlue = Color(0xFF87CEEB);
  static const Color grassGreen = Color(0xFF7ED957);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color brownEarth = Color(0xFFA0522D);
  static const Color sheepWhite = Color(0xFFF5F5F5);
  static const Color cloudWhite = Color(0xFFFFFFFF);
  static const Color scoreYellow = Color(0xFFFFD700);

  // Text styles
  static const TextStyle scoreStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: cloudWhite,
    shadows: [
      Shadow(
        blurRadius: 4,
        color: Colors.black45,
        offset: Offset(2, 2),
      ),
    ],
  );

  static const TextStyle gameOverStyle = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: cloudWhite,
    shadows: [
      Shadow(
        blurRadius: 6,
        color: Colors.black45,
        offset: Offset(3, 3),
      ),
    ],
  );

  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: cloudWhite,
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    elevation: 5,
    textStyle: const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.red[700],
    foregroundColor: cloudWhite,
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    elevation: 5,
    textStyle: const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
  );

  // Animation durations
  static const Duration fastAnimation = Duration(milliseconds: 250);
  static const Duration normalAnimation = Duration(milliseconds: 500);
  static const Duration slowAnimation = Duration(seconds: 1);
}

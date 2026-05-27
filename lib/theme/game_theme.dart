import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GameTheme {
  // Brand colors
  static const Color background = Color(0xFF10171E);
  static const Color cardBg = Color(0xFF1B2631);
  static const Color border = Color(0xFF2D3C4D);
  static const Color accentGold = Color(0xFFFFD700);

  // Resource colors
  static const Color healthRed = Color(0xFFEF5350);
  static const Color energyYellow = Color(0xFFFFB300);
  static const Color energyBlue = Color(0xFF1E88E5);
  static const Color textLight = Color(0xFFECEFF1);
  static const Color textMuted = Color(0xFF90A4AE);

  // Skill colors
  static const Color woodcuttingGreen = Color(0xFF66BB6A);
  static const Color miningGrey = Color(0xFF78909C);
  static const Color herbalismLightGreen = Color(0xFF9CCC65);
  static const Color wayfindingBlue = Color(0xFF29B6F6);
  static const Color lorePurple = Color(0xFFAB47BC);
  static const Color cookingOrange = Color(0xFFFFA726);
  static const Color craftingCyan = Color(0xFF26C6DA);
  static const Color combatRed = Color(0xFFEF5350);

  static Color getSkillColor(dynamic skillType) {
    // Using string matching to avoid tight coupling if skillType is passed as enum
    final String name = skillType.toString().toLowerCase();
    if (name.contains('woodcutting')) return woodcuttingGreen;
    if (name.contains('mining')) return miningGrey;
    if (name.contains('herbalism')) return herbalismLightGreen;
    if (name.contains('wayfinding')) return wayfindingBlue;
    if (name.contains('lore')) return lorePurple;
    if (name.contains('cooking')) return cookingOrange;
    if (name.contains('crafting')) return craftingCyan;
    if (name.contains('combat')) return combatRed;
    return textMuted;
  }

  static Color getQualityColor(dynamic quality) {
    if (quality == null) return border;
    final name = quality.toString().toLowerCase();
    if (name.contains('crude')) return const Color(0xFF90A4AE); // Grey
    if (name.contains('standard')) return Colors.white70;       // White
    if (name.contains('fine')) return const Color(0xFF29B6F6);   // Blue
    if (name.contains('masterwork')) return accentGold;          // Gold
    return border;
  }

  // Theme definition
  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accentGold,
      cardColor: cardBg,
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: textLight, fontSize: 32, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: textLight, fontSize: 20, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: textLight, fontSize: 16),
          bodyMedium: TextStyle(color: textMuted, fontSize: 14),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: accentGold,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // Card Decoration with Glassmorphic border
  static BoxDecoration glassCardDecoration({Color? customBg}) {
    return BoxDecoration(
      color: customBg ?? cardBg.withOpacity(0.9),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: border.withOpacity(0.8),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static Color? getBeastIconColor(String beastId) {
    if (beastId == 'echo_of_wilds') return const Color(0xFF66BB6A); // Green
    if (beastId == 'echo_of_stone') return const Color(0xFF90A4AE); // Grey
    if (beastId == 'echo_of_tide') return const Color(0xFF29B6F6);  // Blue
    return null;
  }
}

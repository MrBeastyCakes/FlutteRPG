import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/skill.dart';
import '../models/codex.dart';
import '../models/item.dart';
import '../models/crafted_item.dart';

class DSColors {
  DSColors._();

  // Surface elevation
  static const Color surface0 = Color(0xFF0A0F14);
  static const Color surface1 = Color(0xFF10171E);
  static const Color surface2 = Color(0xFF161E27);
  static const Color surface3 = Color(0xFF1B2631);
  static const Color surface4 = Color(0xFF222E3A);
  static const Color surface5 = Color(0xFF2A3645);

  // Borders
  static const Color borderSubtle = Color(0xFF1F2A36);
  static const Color borderDefault = Color(0xFF2D3C4D);
  static const Color borderEmphasis = Color(0xFF3E5063);
  static const Color borderAccent = Color(0xFF5B7186);

  // Accent
  static const Color accent = Color(0xFFFFD700);
  static const Color accentMuted = Color(0xFFCFA600);
  static const Color accentSoft = Color(0x33FFD700);
  static const Color accentEmphasis = Color(0xFFFFE45C);

  // Text
  static const Color textPrimary = Color(0xFFECEFF1);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textMuted = Color(0xFF90A4AE);
  static const Color textDisabled = Color(0xFF5A6B7A);
  static const Color textOnAccent = Color(0xFF0A0F14);

  // Skill colors — Woodcutting
  static const Color woodcuttingBase = Color(0xFF66BB6A);
  static const Color woodcuttingLight = Color(0xFF98EE99);
  static const Color woodcuttingDark = Color(0xFF4A8C4E);
  static const Color woodcuttingSoft = Color(0x3366BB6A);

  // Skill colors — Mining
  static const Color miningBase = Color(0xFF78909C);
  static const Color miningLight = Color(0xFFA7C0CD);
  static const Color miningDark = Color(0xFF546E7A);
  static const Color miningSoft = Color(0x3378909C);

  // Skill colors — Herbalism
  static const Color herbalismBase = Color(0xFF9CCC65);
  static const Color herbalismLight = Color(0xFFCFFF95);
  static const Color herbalismDark = Color(0xFF6B9B37);
  static const Color herbalismSoft = Color(0x339CCC65);

  // Skill colors — Wayfinding
  static const Color wayfindingBase = Color(0xFF29B6F6);
  static const Color wayfindingLight = Color(0xFF73E8FF);
  static const Color wayfindingDark = Color(0xFF0086C3);
  static const Color wayfindingSoft = Color(0x3329B6F6);

  // Skill colors — Lore
  static const Color loreBase = Color(0xFFAB47BC);
  static const Color loreLight = Color(0xFFDF78EF);
  static const Color loreDark = Color(0xFF790E8B);
  static const Color loreSoft = Color(0x33AB47BC);

  // Skill colors — Cooking
  static const Color cookingBase = Color(0xFFFFA726);
  static const Color cookingLight = Color(0xFFFFD95B);
  static const Color cookingDark = Color(0xFFC77800);
  static const Color cookingSoft = Color(0x33FFA726);

  // Skill colors — Crafting
  static const Color craftingBase = Color(0xFF26C6DA);
  static const Color craftingLight = Color(0xFF6FF9FF);
  static const Color craftingDark = Color(0xFF0095A8);
  static const Color craftingSoft = Color(0x3326C6DA);

  // Skill colors — Combat
  static const Color combatBase = Color(0xFFEF5350);
  static const Color combatLight = Color(0xFFFF867C);
  static const Color combatDark = Color(0xFFB61827);
  static const Color combatSoft = Color(0x33EF5350);

  // Quality
  static const Color qualityCrudeBase = Color(0xFF90A4AE);
  static const Color qualityCrudeShimmer = Color(0xFFB0BEC5);
  static const Color qualityCrudeGlow = Color(0x4D90A4AE);

  static const Color qualityStandardBase = Colors.white70;
  static const Color qualityStandardShimmer = Colors.white;
  static const Color qualityStandardGlow = Color(0x4DFFFFFF);

  static const Color qualityFineBase = Color(0xFF29B6F6);
  static const Color qualityFineShimmer = Color(0xFF81D4FA);
  static const Color qualityFineGlow = Color(0x4D29B6F6);

  static const Color qualityMasterworkBase = Color(0xFFFFD700);
  static const Color qualityMasterworkShimmer = Color(0xFFFFEC8B);
  static const Color qualityMasterworkGlow = Color(0x66FFD700);

  // Semantic
  static const Color success = Color(0xFF4CAF50);
  static const Color successSoft = Color(0x334CAF50);
  static const Color warning = Color(0xFFFFB300);
  static const Color warningSoft = Color(0x33FFB300);
  static const Color error = Color(0xFFEF5350);
  static const Color errorSoft = Color(0x33EF5350);
  static const Color info = Color(0xFF1E88E5);
  static const Color infoSoft = Color(0x331E88E5);
  static const Color goldAccent = Color(0xFFFFD700);

  // Tag (Codex)
  static const Color tagWilds = Color(0xFF5BAA6F);
  static const Color tagStone = Color(0xFFAAAAAA);
  static const Color tagTide = Color(0xFF5B8FAA);
  static const Color tagSource = Color(0xFF7B5BAA);
  static const Color tagOldEmpire = Color(0xFFFFD700);

  // Resource bars
  static const Color healthBar = Color(0xFFEF5350);
  static const Color energyBar = Color(0xFFFFB300);
  static const Color xpBar = Color(0xFFFFD700);

  // Helper resolvers
  static Color skill(SkillType s, [String shade = 'base']) {
    switch (s) {
      case SkillType.woodcutting:
        return shade == 'light' ? woodcuttingLight : shade == 'dark' ? woodcuttingDark : shade == 'soft' ? woodcuttingSoft : woodcuttingBase;
      case SkillType.mining:
        return shade == 'light' ? miningLight : shade == 'dark' ? miningDark : shade == 'soft' ? miningSoft : miningBase;
      case SkillType.herbalism:
        return shade == 'light' ? herbalismLight : shade == 'dark' ? herbalismDark : shade == 'soft' ? herbalismSoft : herbalismBase;
      case SkillType.wayfinding:
        return shade == 'light' ? wayfindingLight : shade == 'dark' ? wayfindingDark : shade == 'soft' ? wayfindingSoft : wayfindingBase;
      case SkillType.lore:
        return shade == 'light' ? loreLight : shade == 'dark' ? loreDark : shade == 'soft' ? loreSoft : loreBase;
      case SkillType.cooking:
        return shade == 'light' ? cookingLight : shade == 'dark' ? cookingDark : shade == 'soft' ? cookingSoft : cookingBase;
      case SkillType.crafting:
        return shade == 'light' ? craftingLight : shade == 'dark' ? craftingDark : shade == 'soft' ? craftingSoft : craftingBase;
      case SkillType.combat:
        return shade == 'light' ? combatLight : shade == 'dark' ? combatDark : shade == 'soft' ? combatSoft : combatBase;
    }
  }

  static Color quality(QualityTier q, [String shade = 'base']) {
    switch (q) {
      case QualityTier.crude:
        return shade == 'shimmer' ? qualityCrudeShimmer : shade == 'glow' ? qualityCrudeGlow : qualityCrudeBase;
      case QualityTier.standard:
        return shade == 'shimmer' ? qualityStandardShimmer : shade == 'glow' ? qualityStandardGlow : qualityStandardBase;
      case QualityTier.fine:
        return shade == 'shimmer' ? qualityFineShimmer : shade == 'glow' ? qualityFineGlow : qualityFineBase;
      case QualityTier.masterwork:
        return shade == 'shimmer' ? qualityMasterworkShimmer : shade == 'glow' ? qualityMasterworkGlow : qualityMasterworkBase;
    }
  }

  static Color tag(CodexTag t) {
    switch (t) {
      case CodexTag.wilds: return tagWilds;
      case CodexTag.stone: return tagStone;
      case CodexTag.tide: return tagTide;
      case CodexTag.source: return tagSource;
      case CodexTag.oldEmpire: return tagOldEmpire;
      case CodexTag.misc: return Colors.blueGrey;
    }
  }
}

class DSText {
  DSText._();

  // Display (splash pages, You-Win screens)
  static TextStyle display(BuildContext context) => GoogleFonts.cinzel(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.5,
        color: DSColors.textPrimary,
      );

  // Titles & Headings
  static TextStyle headingLarge(BuildContext context) => GoogleFonts.cinzel(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: DSColors.textPrimary,
      );

  static TextStyle headingMedium(BuildContext context) => GoogleFonts.cinzel(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: DSColors.textPrimary,
      );

  static TextStyle headingSmall(BuildContext context) => GoogleFonts.cinzel(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: DSColors.textPrimary,
      );

  // Body Texts
  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.eczar(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: DSColors.textPrimary,
      );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.eczar(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: DSColors.textPrimary,
      );

  static TextStyle bodySmall(BuildContext context) => GoogleFonts.eczar(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: DSColors.textMuted,
      );

  // Labels & CTAs
  static TextStyle label(BuildContext context) => GoogleFonts.cinzel(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.0,
        letterSpacing: 1.2,
        color: DSColors.textMuted,
      );

  static TextStyle button(BuildContext context) => GoogleFonts.cinzel(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.0,
        letterSpacing: 0.5,
      );

  // Numeric stats (HP/XP/gold counts)
  static TextStyle numeric(BuildContext context) => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: DSColors.textPrimary,
      );

  // Narrative segments
  static TextStyle narrativeBody(BuildContext context) => GoogleFonts.eczar(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.7,
        color: DSColors.textPrimary,
        fontStyle: FontStyle.italic,
      );

  static TextStyle narrativeTitle(BuildContext context) => GoogleFonts.cinzel(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: DSColors.textPrimary,
      );

  static TextStyle narrativeQuote(BuildContext context) => GoogleFonts.eczar(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.6,
        fontStyle: FontStyle.italic,
        color: DSColors.textSecondary,
      );
}

class DSSpace {
  DSSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double huge = 64;

  static const EdgeInsets card = EdgeInsets.all(md);
  static const EdgeInsets section = EdgeInsets.symmetric(horizontal: md, vertical: sm);
  static const EdgeInsets dense = EdgeInsets.all(sm);
}

class DSRadius {
  DSRadius._();
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
  static const double pill = 999;
}

class DSShadow {
  DSShadow._();
  static List<BoxShadow> get sm => [
        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 1)),
      ];
  static List<BoxShadow> get md => [
        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
      ];
  static List<BoxShadow> get lg => [
        BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
      ];
  static List<BoxShadow> get glow => [
        BoxShadow(color: DSColors.accent.withOpacity(0.3), blurRadius: 20, spreadRadius: 2),
      ];
}

class DSMotion {
  DSMotion._();
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration deliberate = Duration(milliseconds: 500);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve linear = Curves.linear;

  // Standard combinations
  static const Duration buttonPress = fast;
  static const Duration counterTween = standard;
  static const Duration modalEntry = slow;
  static const Duration celebration = deliberate;
}

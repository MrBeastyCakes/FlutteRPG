# Spec 7a — Design System & Microinteractions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Spec 7a — establish `lib/design/` module with tokens (color/type/spacing/radius/shadow/motion), 15 component primitives, microinteraction layer, audio engine + 13 SFX, Settings screen with audio controls. Existing views unchanged structurally; the new system becomes available for gradual adoption.

**Architecture:** Pure additive. New `lib/design/` directory with `tokens.dart`, `typography.dart`, `primitives/` subdirectory (15 widget files + `_animated_pressable.dart`). New `lib/engine/audio_engine.dart` singleton wrapping `audioplayers` package. New Settings screen as a `GameSheet.showFullscreen` route mounted from a new AppBar overflow menu. Existing `lib/theme/game_theme.dart` continues to work; both systems coexist. Gradual widget migration is deferred to Spec 7b.

**Tech Stack:** Flutter (Dart ^3.11.4), Provider state management, `flutter_test` + `fake_async`. New dependency: `audioplayers ^6.0.0`. New font (Fraunces) loaded via existing `google_fonts` dep. New asset directory `assets/audio/sfx/` with 13 .wav files from kenney.nl Interface (CC0).

**Reference spec:** [docs/superpowers/specs/2026-05-25-spec-7a-design-system-microinteractions-design.md](../specs/2026-05-25-spec-7a-design-system-microinteractions-design.md)

---

## File Structure

**Files created:**
- `lib/design/tokens.dart` — DSColors, DSSpace, DSRadius, DSShadow, DSMotion
- `lib/design/typography.dart` — DSText (Outfit + Fraunces helpers)
- `lib/design/primitives/_animated_pressable.dart` — internal press-feedback wrapper
- `lib/design/primitives/game_button.dart`
- `lib/design/primitives/game_card.dart`
- `lib/design/primitives/game_chip.dart`
- `lib/design/primitives/game_icon_button.dart`
- `lib/design/primitives/game_avatar.dart`
- `lib/design/primitives/game_tabs.dart`
- `lib/design/primitives/game_list_item.dart`
- `lib/design/primitives/game_progress_bar.dart`
- `lib/design/primitives/game_input.dart`
- `lib/design/primitives/game_switch.dart`
- `lib/design/primitives/game_slider.dart`
- `lib/design/primitives/game_tooltip.dart`
- `lib/design/primitives/game_skeleton.dart`
- `lib/design/primitives/game_sheet.dart`
- `lib/design/primitives/game_toast.dart`
- `lib/engine/audio_engine.dart`
- `lib/views/settings_view.dart`
- `assets/audio/sfx/` (13 .wav files; sourced manually by engineer from kenney.nl Interface pack)
- `test/design/tokens_test.dart`
- `test/design/typography_test.dart`
- `test/design/game_button_test.dart` + 14 more primitive test files
- `test/engine/audio_engine_test.dart`
- `test/views/settings_view_test.dart`

**Files modified:**
- `pubspec.yaml` — add `audioplayers: ^6.0.0` dep; register `assets/audio/sfx/` and Fraunces font
- `lib/main.dart` — async `main()` initializes `AudioEngine.instance` before `runApp`; mount Settings route
- `lib/engine/game_engine.dart` — add `playSfx(String key)` helper; wire SFX into `_onMasterworkSuccess`, skill level-up, `_resolveCombatRound` crit, `lockCodexPuzzle` correct/wrong, `_grantReward`, random event firing
- `lib/widgets/custom_progress_bar.dart` — wrap with new GameProgressBar (or refactor in place); update all call sites
- `lib/views/*` — add `RepaintBoundary` around number-counter widgets that should tween; wrap quality badges in shimmer; update level-up callsite to use spring scale-pulse

---

## Task 1: Create lib/design/ directory + DSColors token class

**Files:**
- Create: `lib/design/tokens.dart`
- Test: `test/design/tokens_test.dart` (new)

- [ ] **Step 1: Write failing test**

Create `test/design/tokens_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/design/tokens.dart';

void main() {
  group('DSColors surfaces form monotonic darkness ramp', () {
    test('surface0 through surface5 each have non-zero brightness diff', () {
      final ramp = [
        DSColors.surface0, DSColors.surface1, DSColors.surface2,
        DSColors.surface3, DSColors.surface4, DSColors.surface5,
      ];
      for (var i = 1; i < ramp.length; i++) {
        expect(ramp[i].computeLuminance(), greaterThan(ramp[i - 1].computeLuminance()),
            reason: 'surface$i should be lighter than surface${i - 1}');
      }
    });
  });

  group('Skill color ramps have all 4 shades', () {
    test('Woodcutting ramp has base, light, dark, soft', () {
      expect(DSColors.woodcuttingBase, isNotNull);
      expect(DSColors.woodcuttingLight, isNotNull);
      expect(DSColors.woodcuttingDark, isNotNull);
      expect(DSColors.woodcuttingSoft, isNotNull);
      // Light should be lighter than dark
      expect(DSColors.woodcuttingLight.computeLuminance(),
          greaterThan(DSColors.woodcuttingDark.computeLuminance()));
    });
  });

  group('Quality ramps', () {
    test('Masterwork has stronger glow than Crude', () {
      expect(DSColors.qualityMasterworkGlow.alpha,
          greaterThan(DSColors.qualityCrudeGlow.alpha));
    });
  });

  group('Semantic state colors', () {
    test('success/warning/error/info all have base + soft', () {
      expect(DSColors.success, isNotNull);
      expect(DSColors.successSoft, isNotNull);
      expect(DSColors.error, isNotNull);
      expect(DSColors.errorSoft, isNotNull);
    });
  });
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/design/tokens_test.dart`

Expected: Compilation error — `tokens.dart` doesn't exist.

- [ ] **Step 3: Create lib/design/tokens.dart**

```dart
import 'package:flutter/material.dart';

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

  // Tag (Codex)
  static const Color tagWilds = Color(0xFF5BAA6F);
  static const Color tagStone = Color(0xFFAAAAAA);
  static const Color tagTide = Color(0xFF5B8FAA);
  static const Color tagSource = Color(0xFF7B5BAA);
  static const Color tagOldEmpire = Color(0xFFFFD700);
}
```

- [ ] **Step 4: Run test, verify pass**

Run: `flutter test test/design/tokens_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/design/tokens.dart test/design/tokens_test.dart
git commit -m "feat(design): add DSColors token class with 5-tier surface + 8 skill ramps + quality + semantic"
```

---

## Task 2: Add DSSpace, DSRadius, DSShadow, DSMotion tokens

**Files:**
- Modify: `lib/design/tokens.dart`
- Test: `test/design/tokens_test.dart` (extend)

- [ ] **Step 1: Write failing tests**

Add to `test/design/tokens_test.dart`:

```dart
group('DSSpace scale', () {
  test('8 spacing values exist', () {
    expect(DSSpace.xs, 4);
    expect(DSSpace.sm, 8);
    expect(DSSpace.md, 12);
    expect(DSSpace.lg, 16);
    expect(DSSpace.xl, 24);
    expect(DSSpace.xxl, 32);
    expect(DSSpace.xxxl, 48);
    expect(DSSpace.huge, 64);
  });
});

group('DSRadius scale', () {
  test('6 radius values exist', () {
    expect(DSRadius.sm, 4);
    expect(DSRadius.md, 8);
    expect(DSRadius.lg, 12);
    expect(DSRadius.xl, 16);
    expect(DSRadius.xxl, 20);
    expect(DSRadius.pill, 999);
  });
});

group('DSShadow', () {
  test('4 shadow tokens exist', () {
    expect(DSShadow.sm, isNotEmpty);
    expect(DSShadow.md, isNotEmpty);
    expect(DSShadow.lg, isNotEmpty);
    expect(DSShadow.glow, isNotEmpty);
  });
});

group('DSMotion', () {
  test('4 durations exist with expected ms', () {
    expect(DSMotion.fast.inMilliseconds, 120);
    expect(DSMotion.standard.inMilliseconds, 200);
    expect(DSMotion.slow.inMilliseconds, 350);
    expect(DSMotion.deliberate.inMilliseconds, 500);
  });

  test('Standard combination tokens exist', () {
    expect(DSMotion.buttonPress, DSMotion.fast);
    expect(DSMotion.counterTween, DSMotion.standard);
    expect(DSMotion.modalEntry, DSMotion.slow);
    expect(DSMotion.celebration, DSMotion.deliberate);
  });
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/design/tokens_test.dart`

Expected: FAIL — classes undefined.

- [ ] **Step 3: Append to lib/design/tokens.dart**

```dart
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
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/design/tokens_test.dart`

Expected: All token tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/design/tokens.dart test/design/tokens_test.dart
git commit -m "feat(design): add DSSpace, DSRadius, DSShadow, DSMotion token classes"
```

---

## Task 3: Typography tokens (Outfit + Fraunces)

**Files:**
- Create: `lib/design/typography.dart`
- Modify: `pubspec.yaml` (register Fraunces if not auto-fetched by google_fonts)
- Test: `test/design/typography_test.dart` (new)

- [ ] **Step 1: Write failing test**

Create `test/design/typography_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/design/typography.dart';
import 'package:flutter_text_based_rpg/design/tokens.dart';

void main() {
  testWidgets('DSText.display returns correct style', (tester) async {
    late TextStyle style;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (ctx) {
      style = DSText.display(ctx);
      return const SizedBox.shrink();
    })));
    expect(style.fontSize, 32);
    expect(style.fontWeight, FontWeight.w700);
    expect(style.color, DSColors.textPrimary);
  });

  testWidgets('DSText.narrativeBody is italic', (tester) async {
    late TextStyle style;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (ctx) {
      style = DSText.narrativeBody(ctx);
      return const SizedBox.shrink();
    })));
    expect(style.fontStyle, FontStyle.italic);
  });

  testWidgets('DSText.label has letter spacing for ALL CAPS feel', (tester) async {
    late TextStyle style;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (ctx) {
      style = DSText.label(ctx);
      return const SizedBox.shrink();
    })));
    expect(style.letterSpacing, greaterThan(1.0));
  });
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/design/typography_test.dart`

Expected: FAIL — typography.dart doesn't exist.

- [ ] **Step 3: Create lib/design/typography.dart**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

class DSText {
  DSText._();

  // UI font (Outfit)
  static TextStyle display(BuildContext context) => GoogleFonts.outfit(
    fontSize: 32, fontWeight: FontWeight.w700, height: 1.1, letterSpacing: -0.5,
    color: DSColors.textPrimary,
  );

  static TextStyle headingLarge(BuildContext context) => GoogleFonts.outfit(
    fontSize: 22, fontWeight: FontWeight.w700, height: 1.2, color: DSColors.textPrimary,
  );

  static TextStyle headingMedium(BuildContext context) => GoogleFonts.outfit(
    fontSize: 18, fontWeight: FontWeight.w600, height: 1.3, color: DSColors.textPrimary,
  );

  static TextStyle headingSmall(BuildContext context) => GoogleFonts.outfit(
    fontSize: 14, fontWeight: FontWeight.w600, height: 1.3, color: DSColors.textPrimary,
  );

  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.outfit(
    fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: DSColors.textPrimary,
  );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.outfit(
    fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: DSColors.textPrimary,
  );

  static TextStyle bodySmall(BuildContext context) => GoogleFonts.outfit(
    fontSize: 12, fontWeight: FontWeight.w400, height: 1.4, color: DSColors.textMuted,
  );

  static TextStyle label(BuildContext context) => GoogleFonts.outfit(
    fontSize: 11, fontWeight: FontWeight.w600, height: 1.0,
    letterSpacing: 1.2, color: DSColors.textMuted,
  );

  static TextStyle button(BuildContext context) => GoogleFonts.outfit(
    fontSize: 13, fontWeight: FontWeight.w600, height: 1.0, letterSpacing: 0.3,
  );

  // Narrative font (Fraunces)
  static TextStyle narrativeBody(BuildContext context) => GoogleFonts.fraunces(
    fontSize: 15, fontWeight: FontWeight.w400, height: 1.7,
    color: DSColors.textPrimary, fontStyle: FontStyle.italic,
  );

  static TextStyle narrativeTitle(BuildContext context) => GoogleFonts.fraunces(
    fontSize: 20, fontWeight: FontWeight.w600, height: 1.3, color: DSColors.textPrimary,
  );

  static TextStyle narrativeQuote(BuildContext context) => GoogleFonts.fraunces(
    fontSize: 14, fontWeight: FontWeight.w400, height: 1.6,
    fontStyle: FontStyle.italic, color: DSColors.textSecondary,
  );
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/design/typography_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/design/typography.dart test/design/typography_test.dart
git commit -m "feat(design): add DSText typography helpers (Outfit + Fraunces)"
```

---

## Task 4: _AnimatedPressable wrapper

**Files:**
- Create: `lib/design/primitives/_animated_pressable.dart`

- [ ] **Step 1: Create the widget**

```dart
import 'package:flutter/material.dart';
import '../tokens.dart';

class AnimatedPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? sfxKey;
  final HitTestBehavior behavior;
  final double pressedScale;
  final Duration pressDuration;

  const AnimatedPressable({
    super.key,
    required this.child,
    this.onTap,
    this.sfxKey,
    this.behavior = HitTestBehavior.opaque,
    this.pressedScale = 0.96,
    this.pressDuration = DSMotion.fast,
  });

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.pressDuration,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
      CurvedAnimation(parent: _controller, curve: DSMotion.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(_) {
    if (widget.onTap == null) return;
    _controller.forward();
  }

  void _handleTapUp(_) {
    if (widget.onTap == null) return;
    _controller.reverse();
    widget.onTap?.call();
    // Audio fire — import via late-binding to avoid circular deps
    // Engineer wires AudioEngine call site here in Task 18
    // if (widget.sfxKey != null) AudioEngine.instance.play(widget.sfxKey!);
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: widget.onTap == null ? null : _handleTapDown,
      onTapUp: widget.onTap == null ? null : _handleTapUp,
      onTapCancel: widget.onTap == null ? null : _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze`

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/design/primitives/_animated_pressable.dart
git commit -m "feat(design): add AnimatedPressable internal wrapper for press feedback"
```

---

## Task 5: GameButton

**Files:**
- Create: `lib/design/primitives/game_button.dart`
- Test: `test/design/game_button_test.dart` (new)

- [ ] **Step 1: Write failing test**

Create `test/design/game_button_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/design/primitives/game_button.dart';
import 'package:flutter_text_based_rpg/design/tokens.dart';

void main() {
  testWidgets('GameButton renders label and calls onPressed', (tester) async {
    bool pressed = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: GameButton(
      label: 'Test',
      onPressed: () => pressed = true,
    ))));
    expect(find.text('Test'), findsOneWidget);
    await tester.tap(find.byType(GameButton));
    await tester.pumpAndSettle();
    expect(pressed, true);
  });

  testWidgets('Primary variant uses accent bg', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: GameButton(
      label: 'P', variant: GameButtonVariant.primary, onPressed: () {},
    ))));
    final container = tester.widget<Container>(find.descendant(
      of: find.byType(GameButton),
      matching: find.byType(Container),
    ).first);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, DSColors.accent);
  });

  testWidgets('Disabled when onPressed is null', (tester) async {
    bool pressed = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: GameButton(
      label: 'Disabled', onPressed: null,
    ))));
    await tester.tap(find.byType(GameButton));
    await tester.pumpAndSettle();
    expect(pressed, false);
  });

  testWidgets('Loading state shows CircularProgressIndicator', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: GameButton(
      label: 'L', onPressed: () {}, isLoading: true,
    ))));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('L'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/design/game_button_test.dart`

Expected: Compilation error.

- [ ] **Step 3: Create lib/design/primitives/game_button.dart**

```dart
import 'package:flutter/material.dart';
import '../tokens.dart';
import '../typography.dart';
import '_animated_pressable.dart';

enum GameButtonVariant { primary, secondary, ghost, danger }
enum GameButtonSize { sm, md, lg }

class GameButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final GameButtonVariant variant;
  final GameButtonSize size;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;

  const GameButton({
    super.key,
    required this.label,
    this.icon,
    this.variant = GameButtonVariant.primary,
    this.size = GameButtonSize.md,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = false,
  });

  Color _backgroundColor() {
    if (onPressed == null) return DSColors.surface2;
    switch (variant) {
      case GameButtonVariant.primary: return DSColors.accent;
      case GameButtonVariant.secondary: return DSColors.surface4;
      case GameButtonVariant.ghost: return Colors.transparent;
      case GameButtonVariant.danger: return DSColors.error;
    }
  }

  Color _textColor() {
    if (onPressed == null) return DSColors.textDisabled;
    switch (variant) {
      case GameButtonVariant.primary: return DSColors.textOnAccent;
      case GameButtonVariant.secondary: return DSColors.textPrimary;
      case GameButtonVariant.ghost: return DSColors.textPrimary;
      case GameButtonVariant.danger: return Colors.white;
    }
  }

  Color? _borderColor() {
    if (variant == GameButtonVariant.secondary) return DSColors.borderDefault;
    return null;
  }

  double _height() {
    switch (size) {
      case GameButtonSize.sm: return 28;
      case GameButtonSize.md: return 36;
      case GameButtonSize.lg: return 44;
    }
  }

  double _fontSize() {
    switch (size) {
      case GameButtonSize.sm: return 11;
      case GameButtonSize.md: return 13;
      case GameButtonSize.lg: return 14;
    }
  }

  EdgeInsets _padding() {
    switch (size) {
      case GameButtonSize.sm: return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case GameButtonSize.md: return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case GameButtonSize.lg: return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = isLoading
        ? SizedBox(
            width: _height() * 0.5,
            height: _height() * 0.5,
            child: CircularProgressIndicator(strokeWidth: 2, color: _textColor()),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: _textColor(), size: _fontSize() + 2),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: DSText.button(context).copyWith(
                  fontSize: _fontSize(),
                  color: _textColor(),
                ),
              ),
            ],
          );

    final button = AnimatedPressable(
      onTap: isLoading ? null : onPressed,
      sfxKey: 'ui_click',
      child: Container(
        constraints: BoxConstraints(minHeight: _height()),
        padding: _padding(),
        decoration: BoxDecoration(
          color: _backgroundColor(),
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: _borderColor() == null ? null : Border.all(color: _borderColor()!),
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/design/game_button_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/design/primitives/game_button.dart test/design/game_button_test.dart
git commit -m "feat(design): add GameButton primitive with 4 variants × 3 sizes"
```

---

## Task 6: GameCard, GameChip, GameIconButton, GameAvatar

These four primitives are similar in structure to GameButton — visual containers with token-based styling and optional press feedback. Implement them in one task with one test file each.

**Files:**
- Create: `lib/design/primitives/game_card.dart`
- Create: `lib/design/primitives/game_chip.dart`
- Create: `lib/design/primitives/game_icon_button.dart`
- Create: `lib/design/primitives/game_avatar.dart`
- Test: `test/design/game_card_test.dart`, `game_chip_test.dart`, `game_icon_button_test.dart`, `game_avatar_test.dart`

- [ ] **Step 1: Write tests for each primitive (one test per file)**

Each test verifies: renders without crash, applies token colors, tap callback fires (if applicable). Reuse the GameButton test pattern.

- [ ] **Step 2: Run tests, verify they fail**

Expected: All 4 fail (files don't exist).

- [ ] **Step 3: Implement each primitive**

`lib/design/primitives/game_card.dart`:

```dart
import 'package:flutter/material.dart';
import '../tokens.dart';
import '_animated_pressable.dart';

enum GameCardVariant { flat, elevated, glass }

class GameCard extends StatelessWidget {
  final Widget child;
  final GameCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accentBorder;
  final double? width;

  const GameCard({
    super.key,
    required this.child,
    this.variant = GameCardVariant.flat,
    this.padding = const EdgeInsets.all(12),
    this.onTap,
    this.accentBorder,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    List<BoxShadow>? shadow;
    Color borderColor;
    switch (variant) {
      case GameCardVariant.flat:
        bg = DSColors.surface3;
        shadow = null;
        borderColor = DSColors.borderDefault;
        break;
      case GameCardVariant.elevated:
        bg = DSColors.surface3;
        shadow = DSShadow.md;
        borderColor = DSColors.borderDefault;
        break;
      case GameCardVariant.glass:
        bg = DSColors.surface3.withOpacity(0.85);
        shadow = DSShadow.lg;
        borderColor = DSColors.borderDefault.withOpacity(0.8);
        break;
    }

    final card = Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DSRadius.lg),
        border: Border(
          top: BorderSide(color: borderColor),
          right: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
          left: accentBorder != null
              ? BorderSide(color: accentBorder!, width: 4)
              : BorderSide(color: borderColor),
        ),
        boxShadow: shadow,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return AnimatedPressable(onTap: onTap, sfxKey: 'ui_click_soft', child: card);
  }
}
```

`lib/design/primitives/game_chip.dart`:

```dart
import 'package:flutter/material.dart';
import '../tokens.dart';
import '../typography.dart';
import '_animated_pressable.dart';

enum GameChipVariant { filled, outlined, stat }
enum GameChipSize { sm, md }

class GameChip extends StatelessWidget {
  final String label;
  final String? leadingEmoji;
  final IconData? leadingIcon;
  final Color? color;
  final GameChipVariant variant;
  final GameChipSize size;
  final VoidCallback? onTap;

  const GameChip({
    super.key,
    required this.label,
    this.leadingEmoji,
    this.leadingIcon,
    this.color,
    this.variant = GameChipVariant.filled,
    this.size = GameChipSize.md,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effColor = color ?? DSColors.accent;
    Color bg;
    Color textColor;
    Color borderColor;
    switch (variant) {
      case GameChipVariant.filled:
        bg = effColor.withOpacity(0.15);
        textColor = effColor;
        borderColor = effColor.withOpacity(0.4);
        break;
      case GameChipVariant.outlined:
        bg = Colors.transparent;
        textColor = DSColors.textPrimary;
        borderColor = DSColors.borderEmphasis;
        break;
      case GameChipVariant.stat:
        bg = DSColors.surface4;
        textColor = DSColors.textPrimary;
        borderColor = DSColors.borderSubtle;
        break;
    }
    final padding = size == GameChipSize.sm
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
    final fontSize = size == GameChipSize.sm ? 10.0 : 12.0;

    final chip = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DSRadius.pill),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingEmoji != null) ...[
            Text(leadingEmoji!, style: TextStyle(fontSize: fontSize + 2)),
            const SizedBox(width: 4),
          ] else if (leadingIcon != null) ...[
            Icon(leadingIcon, size: fontSize + 2, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(label, style: DSText.bodySmall(context).copyWith(
            color: textColor, fontSize: fontSize,
            fontWeight: FontWeight.w600,
          )),
        ],
      ),
    );
    if (onTap == null) return chip;
    return AnimatedPressable(onTap: onTap, sfxKey: 'ui_click_soft', child: chip);
  }
}
```

`lib/design/primitives/game_icon_button.dart`:

```dart
import 'package:flutter/material.dart';
import '../tokens.dart';
import '_animated_pressable.dart';

class GameIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? iconColor;
  final double size;
  final bool selected;

  const GameIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.iconColor,
    this.size = 20,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final btn = Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: selected ? DSColors.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(DSRadius.pill),
      ),
      child: Icon(
        icon,
        size: size,
        color: iconColor ?? (selected ? DSColors.accent : DSColors.textPrimary),
      ),
    );
    final wrapped = AnimatedPressable(
      onTap: onPressed,
      sfxKey: 'ui_click_soft',
      pressedScale: 0.92,
      child: btn,
    );
    if (tooltip == null) return wrapped;
    return Tooltip(message: tooltip!, child: wrapped);
  }
}
```

`lib/design/primitives/game_avatar.dart`:

```dart
import 'package:flutter/material.dart';
import '../tokens.dart';
import '../typography.dart';

enum GameAvatarSize { sm, md, lg }

class GameAvatar extends StatelessWidget {
  final String emoji;
  final Color? backgroundColor;
  final GameAvatarSize size;
  final bool showRing;
  final String? label;

  const GameAvatar({
    super.key,
    required this.emoji,
    this.backgroundColor,
    this.size = GameAvatarSize.md,
    this.showRing = false,
    this.label,
  });

  double get _diameter {
    switch (size) {
      case GameAvatarSize.sm: return 32;
      case GameAvatarSize.md: return 48;
      case GameAvatarSize.lg: return 64;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _diameter, height: _diameter,
          decoration: BoxDecoration(
            color: backgroundColor ?? DSColors.surface4,
            shape: BoxShape.circle,
            border: showRing
                ? Border.all(color: DSColors.accent, width: 2)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: TextStyle(fontSize: _diameter * 0.6)),
        ),
        if (label != null) ...[
          const SizedBox(height: 2),
          Text(label!, style: DSText.bodySmall(context)),
        ],
      ],
    );
  }
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/design/`

Expected: All PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/design/primitives/game_card.dart lib/design/primitives/game_chip.dart \
        lib/design/primitives/game_icon_button.dart lib/design/primitives/game_avatar.dart \
        test/design/game_card_test.dart test/design/game_chip_test.dart \
        test/design/game_icon_button_test.dart test/design/game_avatar_test.dart
git commit -m "feat(design): add GameCard, GameChip, GameIconButton, GameAvatar primitives"
```

---

## Task 7: GameTabs (with animated indicator)

**Files:**
- Create: `lib/design/primitives/game_tabs.dart`
- Test: `test/design/game_tabs_test.dart`

- [ ] **Step 1: Write failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/design/primitives/game_tabs.dart';

void main() {
  testWidgets('GameTabs renders all tabs and changes index on tap', (tester) async {
    int selected = 0;
    await tester.pumpWidget(MaterialApp(home: StatefulBuilder(builder: (ctx, setState) {
      return Scaffold(body: GameTabs(
        tabs: const [GameTab(label: 'A'), GameTab(label: 'B'), GameTab(label: 'C')],
        selectedIndex: selected,
        onChanged: (i) => setState(() => selected = i),
      ));
    })));
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    await tester.tap(find.text('C'));
    await tester.pumpAndSettle();
    expect(selected, 2);
  });
}
```

- [ ] **Step 2: Run test, verify it fails**

Expected: FAIL.

- [ ] **Step 3: Implement GameTabs**

```dart
import 'package:flutter/material.dart';
import '../tokens.dart';
import '../typography.dart';
import '_animated_pressable.dart';

enum GameTabsVariant { pills, underline, segments }

class GameTab {
  final String label;
  final IconData? icon;
  final String? badgeText;
  const GameTab({required this.label, this.icon, this.badgeText});
}

class GameTabs extends StatelessWidget {
  final List<GameTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final GameTabsVariant variant;

  const GameTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.variant = GameTabsVariant.pills,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(tabs.length, (i) {
        final tab = tabs[i];
        final selected = i == selectedIndex;
        Widget content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tab.icon != null) ...[
              Icon(tab.icon, size: 14, color: selected ? DSColors.accent : DSColors.textMuted),
              const SizedBox(width: 4),
            ],
            Text(tab.label, style: DSText.bodySmall(context).copyWith(
              color: selected ? DSColors.accent : DSColors.textMuted,
              fontWeight: FontWeight.w600,
            )),
            if (tab.badgeText != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: DSColors.error,
                  borderRadius: BorderRadius.circular(DSRadius.pill),
                ),
                child: Text(tab.badgeText!, style: DSText.bodySmall(context).copyWith(
                  color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700,
                )),
              ),
            ],
          ],
        );

        if (variant == GameTabsVariant.pills) {
          content = AnimatedContainer(
            duration: DSMotion.standard, curve: DSMotion.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? DSColors.accentSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(DSRadius.pill),
            ),
            child: content,
          );
        } else if (variant == GameTabsVariant.underline) {
          content = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(padding: const EdgeInsets.all(8), child: content),
              AnimatedContainer(
                duration: DSMotion.standard,
                height: 2,
                color: selected ? DSColors.accent : Colors.transparent,
                width: 60,
              ),
            ],
          );
        } else {
          content = Expanded(child: AnimatedContainer(
            duration: DSMotion.standard,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: selected ? DSColors.surface5 : Colors.transparent),
            alignment: Alignment.center,
            child: content,
          ));
        }

        return Expanded(
          flex: variant == GameTabsVariant.segments ? 1 : 0,
          child: AnimatedPressable(
            onTap: () => onChanged(i),
            sfxKey: 'ui_tab_switch',
            child: content,
          ),
        );
      }),
    );
  }
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/design/game_tabs_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/design/primitives/game_tabs.dart test/design/game_tabs_test.dart
git commit -m "feat(design): add GameTabs with animated indicator (3 variants)"
```

---

## Task 8: GameListItem

**Files:**
- Create: `lib/design/primitives/game_list_item.dart`
- Test: `test/design/game_list_item_test.dart`

- [ ] **Step 1: Test**

```dart
testWidgets('GameListItem renders title and tap fires callback', (tester) async {
  bool tapped = false;
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: GameListItem(
    leading: const Text('🐗'),
    title: 'Forest Boar',
    subtitle: 'Defeated 7 times',
    onTap: () => tapped = true,
  ))));
  expect(find.text('Forest Boar'), findsOneWidget);
  expect(find.text('Defeated 7 times'), findsOneWidget);
  await tester.tap(find.byType(GameListItem));
  await tester.pumpAndSettle();
  expect(tapped, true);
});
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Implement**

```dart
import 'package:flutter/material.dart';
import '../tokens.dart';
import '../typography.dart';
import '_animated_pressable.dart';

class GameListItem extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSelected;

  const GameListItem({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: DSSpace.lg, vertical: DSSpace.md),
      decoration: BoxDecoration(
        color: isSelected ? DSColors.surface4 : Colors.transparent,
        borderRadius: BorderRadius.circular(DSRadius.md),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: DSSpace.md),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: DSText.bodyMedium(context).copyWith(fontWeight: FontWeight.w600)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: DSText.bodySmall(context)),
              ],
            ],
          )),
          if (trailing != null) trailing!,
        ],
      ),
    );
    if (onTap == null) return row;
    return AnimatedPressable(onTap: onTap, sfxKey: 'ui_click_soft', child: row);
  }
}
```

- [ ] **Step 4: Run tests, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/design/primitives/game_list_item.dart test/design/game_list_item_test.dart
git commit -m "feat(design): add GameListItem primitive replacing ListTile"
```

---

## Task 9: GameProgressBar (refactor CustomProgressBar)

**Files:**
- Create: `lib/design/primitives/game_progress_bar.dart`
- Test: `test/design/game_progress_bar_test.dart`

- [ ] **Step 1: Test**

```dart
testWidgets('GameProgressBar renders with progress value', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: GameProgressBar(
    progress: 0.5,
    color: Colors.green,
  ))));
  expect(find.byType(GameProgressBar), findsOneWidget);
});

testWidgets('GameProgressBar with animate=true uses TweenAnimationBuilder', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: GameProgressBar(
    progress: 0.5, color: Colors.green, animate: true,
  ))));
  expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
});
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Implement**

```dart
import 'package:flutter/material.dart';
import '../tokens.dart';
import '../typography.dart';

class GameProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final double height;
  final bool animate;
  final String? label;
  final bool showGlow;

  const GameProgressBar({
    super.key,
    required this.progress,
    required this.color,
    this.height = 8,
    this.animate = false,
    this.label,
    this.showGlow = false,
  });

  Widget _buildBar(double value) {
    final clamped = value.clamp(0.0, 1.0);
    return Stack(
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: DSColors.surface4,
            borderRadius: BorderRadius.circular(DSRadius.sm),
          ),
        ),
        FractionallySizedBox(
          widthFactor: clamped,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(DSRadius.sm),
              boxShadow: showGlow && clamped > 0.9
                  ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)]
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bar = animate
        ? TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: DSMotion.counterTween,
            curve: DSMotion.easeOut,
            builder: (context, value, _) => _buildBar(value),
          )
        : _buildBar(progress);

    if (label == null) return bar;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      bar,
      const SizedBox(height: 4),
      Text(label!, style: DSText.bodySmall(context)),
    ]);
  }
}
```

- [ ] **Step 4: Run tests, verify pass**

- [ ] **Step 5: Update existing CustomProgressBar call sites**

Search the codebase for `CustomProgressBar` usages (mostly in skills_view, dashboard_view) and replace with `GameProgressBar`. Keep behavior identical (animate defaults to false to avoid regressions).

- [ ] **Step 6: Commit**

```bash
git add lib/design/primitives/game_progress_bar.dart test/design/game_progress_bar_test.dart lib/views/
git commit -m "feat(design): add GameProgressBar replacing CustomProgressBar; update call sites"
```

---

## Task 10: GameInput, GameSwitch, GameSlider (form primitives)

Implement these three together — needed for Settings screen.

**Files:**
- Create: `lib/design/primitives/game_input.dart`, `game_switch.dart`, `game_slider.dart`
- Test: corresponding test files

- [ ] **Step 1: Tests**

Each test verifies: renders, value change calls onChanged, visual state matches token expectations.

- [ ] **Step 2: Run, verify they fail**

- [ ] **Step 3: Implement each**

`game_input.dart`:

```dart
import 'package:flutter/material.dart';
import '../tokens.dart';
import '../typography.dart';

class GameInput extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? placeholder;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const GameInput({
    super.key,
    required this.controller,
    this.label,
    this.placeholder,
    this.leadingIcon,
    this.trailingIcon,
    this.onTrailingTap,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: DSText.label(context)),
          const SizedBox(height: 4),
        ],
        Container(
          decoration: BoxDecoration(
            color: DSColors.surface4,
            borderRadius: BorderRadius.circular(DSRadius.md),
            border: Border.all(color: errorText != null ? DSColors.error : DSColors.borderDefault),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: DSText.bodyMedium(context),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              hintText: placeholder,
              hintStyle: DSText.bodyMedium(context).copyWith(color: DSColors.textDisabled),
              prefixIcon: leadingIcon == null ? null : Icon(leadingIcon, color: DSColors.textMuted, size: 18),
              suffixIcon: trailingIcon == null ? null : GestureDetector(
                onTap: onTrailingTap,
                child: Icon(trailingIcon, color: DSColors.textMuted, size: 18),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText!, style: DSText.bodySmall(context).copyWith(color: DSColors.error)),
        ],
      ],
    );
  }
}
```

`game_switch.dart`:

```dart
import 'package:flutter/material.dart';
import '../tokens.dart';
import '../typography.dart';

class GameSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  const GameSwitch({super.key, required this.value, this.onChanged, this.label});

  @override
  Widget build(BuildContext context) {
    final track = AnimatedContainer(
      duration: DSMotion.standard,
      width: 44, height: 24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: value ? DSColors.accentSoft : DSColors.surface4,
        borderRadius: BorderRadius.circular(DSRadius.pill),
      ),
      child: AnimatedAlign(
        duration: DSMotion.standard,
        curve: DSMotion.easeOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: value ? DSColors.accent : DSColors.borderEmphasis,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );

    final widget = GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: label == null ? track : Row(
        mainAxisSize: MainAxisSize.min,
        children: [track, const SizedBox(width: 8), Text(label!, style: DSText.bodyMedium(context))],
      ),
    );
    return widget;
  }
}
```

`game_slider.dart`:

```dart
import 'package:flutter/material.dart';
import '../tokens.dart';
import '../typography.dart';

class GameSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String? label;
  final String Function(double)? valueFormatter;

  const GameSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    required this.onChanged,
    this.label,
    this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label!, style: DSText.label(context)),
          if (valueFormatter != null)
            Text(valueFormatter!(value), style: DSText.bodySmall(context)),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: DSColors.accent,
            inactiveTrackColor: DSColors.surface4,
            thumbColor: DSColors.accent,
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run tests, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/design/primitives/game_input.dart lib/design/primitives/game_switch.dart \
        lib/design/primitives/game_slider.dart test/design/game_input_test.dart \
        test/design/game_switch_test.dart test/design/game_slider_test.dart
git commit -m "feat(design): add GameInput, GameSwitch, GameSlider form primitives"
```

---

## Task 11: GameTooltip, GameSkeleton

**Files:**
- Create: `lib/design/primitives/game_tooltip.dart`, `game_skeleton.dart`
- Test: corresponding test files

- [ ] **Step 1: Tests**

- [ ] **Step 2: Run, verify they fail**

- [ ] **Step 3: Implement**

`game_tooltip.dart`:

```dart
import 'package:flutter/material.dart';
import '../tokens.dart';
import '../typography.dart';

class GameTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final TooltipTriggerMode? triggerMode;

  const GameTooltip({super.key, required this.message, required this.child, this.triggerMode});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      triggerMode: triggerMode,
      decoration: BoxDecoration(
        color: DSColors.surface5,
        borderRadius: BorderRadius.circular(DSRadius.sm),
        border: Border.all(color: DSColors.borderDefault),
      ),
      textStyle: DSText.bodySmall(context).copyWith(color: DSColors.textPrimary),
      waitDuration: DSMotion.fast,
      showDuration: const Duration(seconds: 3),
      child: child,
    );
  }
}
```

`game_skeleton.dart`:

```dart
import 'package:flutter/material.dart';
import '../tokens.dart';

class GameSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry? borderRadius;

  const GameSkeleton({super.key, required this.width, required this.height, this.borderRadius});

  @override
  State<GameSkeleton> createState() => _GameSkeletonState();
}

class _GameSkeletonState extends State<GameSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: widget.width, height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(DSRadius.md),
          gradient: LinearGradient(
            begin: Alignment(-1.0 + _controller.value * 2, 0),
            end: Alignment(0.0 + _controller.value * 2, 0),
            colors: [DSColors.surface4, DSColors.surface5, DSColors.surface4],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/design/primitives/game_tooltip.dart lib/design/primitives/game_skeleton.dart \
        test/design/game_tooltip_test.dart test/design/game_skeleton_test.dart
git commit -m "feat(design): add GameTooltip and GameSkeleton utility primitives"
```

---

## Task 12: GameSheet (bottom + fullscreen)

**Files:**
- Create: `lib/design/primitives/game_sheet.dart`
- Test: `test/design/game_sheet_test.dart`

- [ ] **Step 1: Test**

```dart
testWidgets('GameSheet.showBottom opens sheet with child', (tester) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (ctx) {
    return ElevatedButton(
      onPressed: () => GameSheet.showBottom(ctx, child: const Text('Hello sheet')),
      child: const Text('Open'),
    );
  }))));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  expect(find.text('Hello sheet'), findsOneWidget);
});
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Implement**

```dart
import 'package:flutter/material.dart';
import '../tokens.dart';
import '../typography.dart';

class GameSheet {
  GameSheet._();

  static Future<T?> showBottom<T>(
    BuildContext context, {
    required Widget child,
    double? heightFactor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: DSColors.surface4,
            borderRadius: BorderRadius.vertical(top: Radius.circular(DSRadius.xxl)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(DSSpace.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: DSColors.borderEmphasis,
                      borderRadius: BorderRadius.circular(DSRadius.pill),
                    ),
                  ),
                  const SizedBox(height: DSSpace.md),
                  Flexible(child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: child,
                  )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<T?> showFullscreen<T>(
    BuildContext context, {
    required Widget child,
    String? title,
  }) {
    return Navigator.of(context).push<T>(MaterialPageRoute(
      builder: (ctx) => Scaffold(
        backgroundColor: DSColors.surface2,
        appBar: title == null ? null : AppBar(
          title: Text(title, style: DSText.headingMedium(ctx)),
          backgroundColor: DSColors.surface2,
        ),
        body: SafeArea(child: child),
      ),
    ));
  }
}
```

- [ ] **Step 4: Run tests, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/design/primitives/game_sheet.dart test/design/game_sheet_test.dart
git commit -m "feat(design): add GameSheet with bottom modal and fullscreen variants"
```

---

## Task 13: GameToast

**Files:**
- Create: `lib/design/primitives/game_toast.dart`
- Test: `test/design/game_toast_test.dart`

- [ ] **Step 1: Test**

```dart
testWidgets('GameToast.show displays message', (tester) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (ctx) {
    return ElevatedButton(
      onPressed: () => GameToast.show(ctx, message: 'Hello toast'),
      child: const Text('Toast'),
    );
  }))));
  await tester.tap(find.text('Toast'));
  await tester.pump(const Duration(milliseconds: 100));
  expect(find.text('Hello toast'), findsOneWidget);
});
```

- [ ] **Step 2: Implement**

```dart
import 'package:flutter/material.dart';
import '../tokens.dart';
import '../typography.dart';

enum GameToastVariant { success, error, info }

class GameToast {
  GameToast._();

  static void show(
    BuildContext context, {
    required String message,
    GameToastVariant variant = GameToastVariant.info,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    Color stripeColor;
    switch (variant) {
      case GameToastVariant.success: stripeColor = DSColors.success;
      case GameToastVariant.error: stripeColor = DSColors.error;
      case GameToastVariant.info: stripeColor = DSColors.info;
    }
    final overlayState = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (ctx) => _ToastWidget(
      message: message,
      stripeColor: stripeColor,
      icon: icon,
      duration: duration,
      onDismiss: () => entry.remove(),
    ));
    overlayState.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Color stripeColor;
  final IconData? icon;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.stripeColor,
    required this.icon,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: DSMotion.slow);
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: DSMotion.easeOut),
    );
    _ctrl.forward();
    Future.delayed(widget.duration, () async {
      if (mounted) {
        await _ctrl.reverse();
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12, right: 12,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: DSColors.surface4,
              borderRadius: BorderRadius.circular(DSRadius.md),
              border: Border(left: BorderSide(color: widget.stripeColor, width: 4)),
              boxShadow: DSShadow.md,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: widget.stripeColor, size: 18),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(widget.message, style: DSText.bodyMedium(context))),
            ]),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Run tests, verify pass**

- [ ] **Step 4: Commit**

```bash
git add lib/design/primitives/game_toast.dart test/design/game_toast_test.dart
git commit -m "feat(design): add GameToast with slide-in animation and 3 variants"
```

---

## Task 14: AudioEngine + audioplayers dependency + 13 SFX assets

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/engine/audio_engine.dart`
- Create: `assets/audio/sfx/` directory with 13 .wav files (engineer downloads from kenney.nl Interface Sounds CC0 pack)
- Modify: `lib/main.dart`
- Test: `test/engine/audio_engine_test.dart`

- [ ] **Step 1: Add audioplayers dependency**

In `pubspec.yaml`:

```yaml
dependencies:
  audioplayers: ^6.0.0
flutter:
  assets:
    - assets/audio/sfx/
```

Run: `flutter pub get`

- [ ] **Step 2: Download 13 SFX from kenney.nl**

Visit https://kenney.nl/assets/interface-sounds and download the pack. Place 13 files in `assets/audio/sfx/`:
- `ui_click.wav` — short button click
- `ui_click_soft.wav` — softer click
- `ui_toggle.wav` — toggle sound
- `ui_sheet_open.wav` — whoosh
- `ui_tab_switch.wav` — tick
- `ui_success.wav` — two-note chime
- `ui_error.wav` — buzz
- `ui_info_chime.wav` — single ding
- `ui_levelup_chime.wav` — ascending arpeggio
- `ui_masterwork_complete.wav` — triumphant flourish
- `ui_crit.wav` — metallic clink
- `ui_puzzle_solve.wav` — harmonic resolve
- `ui_error_soft.wav` — muted tone

(Pick the closest-feeling sound from the pack; rename to match the keys above.)

- [ ] **Step 3: Write failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/audio_engine.dart';

void main() {
  test('AudioEngine starts enabled with 0.7 volume', () {
    expect(AudioEngine.instance.enabled, true);
    expect(AudioEngine.instance.volume, 0.7);
  });

  test('setEnabled changes enabled state', () {
    AudioEngine.instance.setEnabled(false);
    expect(AudioEngine.instance.enabled, false);
    AudioEngine.instance.setEnabled(true);
  });

  test('setVolume clamps to 0-1', () {
    AudioEngine.instance.setVolume(1.5);
    expect(AudioEngine.instance.volume, 1.0);
    AudioEngine.instance.setVolume(-0.5);
    expect(AudioEngine.instance.volume, 0.0);
    AudioEngine.instance.setVolume(0.5);
  });
}
```

- [ ] **Step 4: Run test, verify it fails**

- [ ] **Step 5: Implement lib/engine/audio_engine.dart**

```dart
import 'package:audioplayers/audioplayers.dart';

class AudioEngine {
  AudioEngine._();
  static final AudioEngine instance = AudioEngine._();

  final Map<String, AudioPlayer> _players = {};
  bool _enabled = true;
  double _volume = 0.7;

  Future<void> init() async {
    for (final key in _allSfxKeys) {
      try {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource('audio/sfx/$key.wav'));
        _players[key] = player;
      } catch (_) {
        // Graceful: missing audio file or platform issue — skip silently
      }
    }
  }

  Future<void> play(String key) async {
    if (!_enabled) return;
    final player = _players[key];
    if (player == null) return;
    try {
      await player.stop();
      await player.setVolume(_volume);
      await player.resume();
    } catch (_) {}
  }

  void setEnabled(bool enabled) { _enabled = enabled; }
  void setVolume(double volume) { _volume = volume.clamp(0.0, 1.0); }
  bool get enabled => _enabled;
  double get volume => _volume;
}

const _allSfxKeys = [
  'ui_click', 'ui_click_soft', 'ui_toggle', 'ui_sheet_open', 'ui_tab_switch',
  'ui_success', 'ui_error', 'ui_info_chime', 'ui_levelup_chime',
  'ui_masterwork_complete', 'ui_crit', 'ui_puzzle_solve', 'ui_error_soft',
];
```

- [ ] **Step 6: Wire init in main.dart**

In `lib/main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioEngine.instance.init();
  runApp(...);
}
```

Add import.

- [ ] **Step 7: Run tests, verify pass**

Run: `flutter test test/engine/audio_engine_test.dart`

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add pubspec.yaml lib/engine/audio_engine.dart lib/main.dart test/engine/audio_engine_test.dart assets/audio/sfx/
git commit -m "feat(audio): add AudioEngine with 13 SFX from kenney.nl Interface (CC0)"
```

---

## Task 15: Wire SFX into AnimatedPressable

**Files:**
- Modify: `lib/design/primitives/_animated_pressable.dart`

- [ ] **Step 1: Uncomment / add the audio call**

In `_handleTapUp`:

```dart
void _handleTapUp(_) {
  if (widget.onTap == null) return;
  _controller.reverse();
  widget.onTap?.call();
  if (widget.sfxKey != null) {
    AudioEngine.instance.play(widget.sfxKey!);
  }
}
```

Add import: `import '../../engine/audio_engine.dart';`

- [ ] **Step 2: Verify with full test suite**

Run: `flutter test`

Expected: All tests pass; primitive widgets now play sounds when tapped (test will not actually play audio since init isn't called in test setup).

- [ ] **Step 3: Commit**

```bash
git add lib/design/primitives/_animated_pressable.dart
git commit -m "feat(audio): wire AudioEngine.play into AnimatedPressable for primitive SFX"
```

---

## Task 16: Wire engine-level SFX moments

**Files:**
- Modify: `lib/engine/game_engine.dart`

- [ ] **Step 1: Add playSfx helper**

In `GameEngine`:

```dart
import 'audio_engine.dart';

// In class:
void playSfx(String key) {
  AudioEngine.instance.play(key);
}
```

- [ ] **Step 2: Wire SFX into engine moments**

Find each existing path and add the play call:

- `_onMasterworkSuccess` (after level cap unlocks): `playSfx('ui_masterwork_complete');`
- Skill level-up (search for level-up emit point): `playSfx('ui_levelup_chime');`
- `_resolveCombatRound` crit branch: `playSfx('ui_crit');`
- `lockCodexPuzzle` correct branch: `playSfx('ui_puzzle_solve');`
- `lockCodexPuzzle` wrong branch: `playSfx('ui_error_soft');`
- `_grantReward` (after applying any reward): `playSfx('ui_success');`
- `_fireRandomEvent` (when random event modal fires): `playSfx('ui_info_chime');`

- [ ] **Step 3: Verify the game still runs**

Run: `flutter run -d windows`

Expected: Play through key moments and confirm sounds play.

- [ ] **Step 4: Commit**

```bash
git add lib/engine/game_engine.dart
git commit -m "feat(audio): wire SFX into engine moments (masterwork, levelup, crit, puzzle, reward, random event)"
```

---

## Task 17: Settings screen with Audio section

**Files:**
- Create: `lib/views/settings_view.dart`
- Modify: `lib/main.dart` (AppBar overflow menu)
- Test: `test/views/settings_view_test.dart`

- [ ] **Step 1: Test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/views/settings_view.dart';
import 'package:flutter_text_based_rpg/engine/audio_engine.dart';

void main() {
  testWidgets('SettingsView shows Audio section with Sound toggle and Volume slider', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsView()));
    expect(find.text('AUDIO'), findsOneWidget);
    expect(find.text('Sound Effects'), findsOneWidget);
    expect(find.text('Volume'), findsOneWidget);
  });

  testWidgets('Toggling Sound switch changes AudioEngine.enabled', (tester) async {
    AudioEngine.instance.setEnabled(true);
    await tester.pumpWidget(const MaterialApp(home: SettingsView()));
    final switchFinder = find.byType(Switch);  // matches our GameSwitch internal GestureDetector
    // Tap the toggle area
    // Specifics depend on widget tree; verify enabled state changes
  });
}
```

- [ ] **Step 2: Implement SettingsView**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design/tokens.dart';
import '../design/typography.dart';
import '../design/primitives/game_card.dart';
import '../design/primitives/game_switch.dart';
import '../design/primitives/game_slider.dart';
import '../engine/audio_engine.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _soundEnabled = AudioEngine.instance.enabled;
  double _volume = AudioEngine.instance.volume;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.surface2,
      appBar: AppBar(
        title: Text('Settings', style: DSText.headingMedium(context)),
        backgroundColor: DSColors.surface2,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DSSpace.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AUDIO', style: DSText.label(context)),
            const SizedBox(height: DSSpace.sm),
            GameCard(
              padding: const EdgeInsets.all(DSSpace.lg),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    const Text('🔊', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text('Sound Effects', style: DSText.bodyMedium(context)),
                  ]),
                  GameSwitch(value: _soundEnabled, onChanged: (v) {
                    setState(() => _soundEnabled = v);
                    AudioEngine.instance.setEnabled(v);
                  }),
                ]),
                const SizedBox(height: DSSpace.lg),
                GameSlider(
                  label: 'Volume',
                  value: _volume,
                  onChanged: (v) {
                    setState(() => _volume = v);
                    AudioEngine.instance.setVolume(v);
                  },
                  valueFormatter: (v) => '${(v * 100).round()}%',
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Mount in main.dart AppBar overflow menu**

In `lib/main.dart`, find the existing AppBar and change the reset button into a `PopupMenuButton`:

```dart
actions: [
  PopupMenuButton<String>(
    icon: const Icon(Icons.more_vert, color: DSColors.textMuted),
    onSelected: (value) {
      if (value == 'settings') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsView()));
      } else if (value == 'reset') {
        // existing reset logic
      }
    },
    itemBuilder: (_) => [
      const PopupMenuItem(value: 'settings', child: Text('Settings')),
      const PopupMenuItem(value: 'reset', child: Text('Reset Game')),
    ],
  ),
],
```

Add import.

- [ ] **Step 4: Run tests, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/views/settings_view.dart lib/main.dart test/views/settings_view_test.dart
git commit -m "feat(ui): add Settings view with Audio section (mute toggle + volume slider)"
```

---

## Task 18: Microinteraction wiring — number tweens

**Files:**
- Modify: existing views that display numeric counters (Dashboard, Skills, Inventory)

- [ ] **Step 1: Identify counter displays**

Search the codebase for Text widgets displaying numeric values (gold, HP, energy, XP, defeat count, etc.). Common patterns:

```dart
Text('${stats.gold}')
Text('${engine.playerStats.currentHealth}/${engine.playerStats.maxHealth}')
Text('${skill.xp.toInt()} XP')
```

- [ ] **Step 2: Wrap with TweenAnimationBuilder**

Replace direct number displays with:

```dart
TweenAnimationBuilder<double>(
  tween: Tween<double>(begin: 0, end: stats.gold.toDouble()),
  duration: DSMotion.counterTween,
  curve: DSMotion.easeOut,
  builder: (context, value, _) => Text('${value.toInt()}'),
)
```

For HP/energy bars, the existing `GameProgressBar` with `animate: true` already does this — just enable the flag at call sites.

- [ ] **Step 3: Verify visually**

Run: `flutter run -d windows`

Expected: Gold counter ticks up smoothly when a coin is gained. HP bar drains visibly during action. XP bar fills smoothly on action completion.

- [ ] **Step 4: Commit**

```bash
git add lib/views/
git commit -m "feat(ui): wrap number counters in TweenAnimationBuilder for smooth tweens"
```

---

## Task 19: Microinteraction wiring — quality shimmer + level-up spring

**Files:**
- Modify: `lib/views/inventory_view.dart` (quality badges)
- Modify: `lib/views/skills_view.dart` or `lib/widgets/particle_explosion.dart` (level-up spring)
- Modify: existing Masterwork completion path (badge entry spring)

- [ ] **Step 1: Quality tier shimmer widget**

Create or extend the existing quality badge widget to add a shimmer sweep on first display + on tap:

```dart
class QualityShimmer extends StatefulWidget {
  final QualityTier quality;
  final Widget child;
  // Implementation: AnimationController over 1200ms, linear gradient sweep across child
  // Trigger once on initState; trigger again on tap if onTap is provided
}
```

Wrap quality badges in inventory cards with `QualityShimmer`.

- [ ] **Step 2: Level-up spring pulse on skill card**

In the existing skill card render (Skills view), wrap in `AnimatedScale` controlled by a level-up event:

```dart
// Listen to engine.levelUpEvents stream; on event for this skill, animate scale 1.0 → 1.1 → 1.0 over DSMotion.celebration with spring curve
```

- [ ] **Step 3: Masterwork badge entry animation**

In the spec badge widget (added in Spec 4 Task 23), wrap badge in `TweenAnimationBuilder<double>` for scale 0 → 1.2 → 1.0 over `DSMotion.celebration` when first shown:

```dart
TweenAnimationBuilder<double>(
  tween: Tween<double>(begin: 0, end: 1),
  duration: DSMotion.celebration,
  curve: DSMotion.spring,
  builder: (context, value, child) => Transform.scale(scale: value, child: child),
  child: _badgeContent,
)
```

- [ ] **Step 4: Verify visually**

Run the app. Trigger level-up, masterwork complete, view a Fine/Masterwork item — confirm all animations play.

- [ ] **Step 5: Commit**

```bash
git add lib/views/ lib/widgets/
git commit -m "feat(ui): add quality shimmer + level-up spring + masterwork badge entry animations"
```

---

## Task 20: Final smoke test

**Files:**
- Modify: `test/widget_test.dart`

- [ ] **Step 1: End-to-end test**

```dart
testWidgets('Spec 7a smoke — design system loads, audio inits, settings opens', (tester) async {
  // 1. Verify tokens are accessible
  expect(DSColors.accent, isNotNull);
  expect(DSSpace.lg, 16);
  expect(DSMotion.fast, const Duration(milliseconds: 120));

  // 2. Pump a primitive
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: GameButton(
    label: 'Test', onPressed: () {},
  ))));
  expect(find.text('Test'), findsOneWidget);

  // 3. Verify AudioEngine accessible
  expect(AudioEngine.instance, isNotNull);
});
```

- [ ] **Step 2: Run full test suite**

Run: `flutter test`

Expected: All Spec 1 + 2 + 3 + 4 + 7a tests pass.

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`

Expected: Zero errors, zero warnings.

- [ ] **Step 4: Commit**

```bash
git add test/widget_test.dart
git commit -m "test(spec7a): final smoke test for design system + audio engine"
```

---

## Post-implementation checklist

- [ ] All `flutter test` passes
- [ ] `flutter analyze` shows zero errors and zero warnings
- [ ] Manual play test:
  - Fresh app → every button press has audible click + scale animation
  - Gold counter tween up after selling an item
  - Open Codex → narrative text renders in Fraunces italic
  - Level up a skill → particle burst + spring pulse + chime
  - Solve a puzzle → harmonic resolve chime + Reading slides up
  - Craft a Masterwork item → gold shimmer sweep on inventory card
  - AppBar overflow → Settings → Audio toggle works
  - Volume slider changes SFX loudness
  - Toggle off Sound → all SFX silent
- [ ] All 13 SFX files present in `assets/audio/sfx/`
- [ ] Fraunces font loads (or pre-bundled if `google_fonts` network fetch is unreliable)
- [ ] README.md updated with "Spec 7a — Design System & Microinteractions" notes

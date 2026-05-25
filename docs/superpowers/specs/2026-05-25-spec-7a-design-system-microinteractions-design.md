# Spec 7a — Design System & Microinteractions

**Date:** 2026-05-25
**Status:** Approved (pending spec review)
**Parent:** [Echoes from the Deep umbrella vision](2026-05-24-echoes-from-the-deep-vision.md) (Spec 7 added post-umbrella as UI overhaul)
**Sibling:** Spec 7b — Per-View Redesigns (separate brainstorm; depends on this spec)
**Scope:** Foundational design system + microinteraction layer + sound. Ships color/type/spacing/radius/shadow/motion tokens, 15 component primitives, 15 microinteraction moments, 13 SFX, audio engine, Settings screen with audio controls. Existing views inherit a more premium feel without structural changes. Per-view layout redesigns are deferred to Spec 7b.

---

## 1. Goals & Acceptance Criteria

### 1.1 What Spec 7a ships

- **Evolved color palette** — keep gold accent + per-skill / per-quality colors; add 5-tier surface elevation scale; broaden each skill color into 4-shade ramp (base/light/dark/soft); 3-shade quality ramps
- **Two-typeface system** — Outfit for UI; Fraunces (italic) for Codex fragments / Readings / milestone events / Masterwork trial narrative
- **Type scale + spacing tokens** — explicit display/heading/body/caption sizes; 4dp spacing scale (4/8/12/16/24/32/48/64)
- **Motion vocabulary** — 4 timing curves (linear, ease-out, ease-in-out, spring), 4 standard durations (120/200/350/500ms)
- **15 component primitives** — GameButton, GameCard, GameChip, GameSheet, GameTabs, GameIconButton, GameToast, GameTooltip, GameInput, GameSwitch, GameSlider, GameAvatar, GameListItem, GameProgressBar, GameSkeleton
- **Microinteraction catalog** — 15 defined animation patterns covering button press, number tweens, tab switch, modal entry, level-up celebration, quality shimmer, puzzle correct/wrong, combat hits, etc.
- **Sound layer** — 13 short SFX from a free pack (kenney.nl Interface), `audioplayers` package, Settings → Audio with mute toggle + volume slider
- **`lib/design/` module** — new directory housing tokens.dart, typography.dart, primitives/ subdirectory
- **Settings screen** — new full-screen route mounted from AppBar overflow menu; for v1 it contains only the Audio section

### 1.2 What Spec 7a does NOT do

- No layout redesigns for any view (Spec 7b)
- No information-architecture changes (Spec 7b)
- No new game systems or content
- No formal accessibility audit (visual contrast respected at AA level as practice but not certified)
- No removal of existing widgets (they coexist with new primitives; gradual migration)
- No theme switching (light mode, etc.) — single dark theme only
- No internationalization
- No music / ambient audio (SFX only)
- No haptic feedback

### 1.3 Acceptance criteria

A player after Spec 7a ships:

1. Opens the app. Every button press feels weighty: brief scale-down on tap with a click sound, smooth release.
2. Number changes (gold counter, HP bar, XP gain) tween smoothly instead of snapping.
3. Reads a Codex Fragment — narrative text renders in elegant Fraunces italic serif; UI chrome around it stays in clean Outfit sans.
4. Solves a Codex puzzle — green-border animation on correct positions plays a satisfying spring + harmonic resolve chime; Reading overlay slides in with weight.
5. Levels up a skill — particle burst (existing) is joined by a subtle audio chime + XP-counter tween + skill-card spring pulse.
6. Crafts a Masterwork item — quality badge has a dramatic gold shimmer sweep.
7. Opens a modal — slides up from bottom with spring + soft whoosh; outside-tap dismisses with reverse fade.
8. Opens AppBar overflow → Settings → toggles Sound off → all SFX silent immediately. Adjusts Volume slider.
9. Existing widgets (Workshop, Codex, Skills view) look identical in layout but read with refined typography + spacing + motion. Zero visible regressions.

### 1.4 Design principles inherited

- **No art** — pure tokens + emoji + Material Icons + motion. Free CC0 SFX pack only (kenney.nl Interface).
- **Progressive discovery** — Settings UI only exposes sections relevant to current game state (Audio always; future categories appear as earned).
- **Systems converse** — the design system is what every other system speaks through; tokens are referenced from every existing file in incremental migration.

---

## 2. Design Tokens

New file `lib/design/tokens.dart` is the single source of truth for color, type, spacing, radius, shadow. Every primitive component references these. The existing `lib/theme/game_theme.dart` continues to work; tokens.dart is a layer above with richer structure.

### 2.1 Color tokens — `DSColors`

#### Surface (5-tier elevation scale)

```dart
class DSColors {
  static const Color surface0 = Color(0xFF0A0F14);  // app background
  static const Color surface1 = Color(0xFF10171E);  // sticky chrome (current 'background')
  static const Color surface2 = Color(0xFF161E27);  // page-level cards
  static const Color surface3 = Color(0xFF1B2631);  // nested cards (current 'cardBg')
  static const Color surface4 = Color(0xFF222E3A);  // modal sheets, popovers
  static const Color surface5 = Color(0xFF2A3645);  // hovered/pressed states

  // Borders & dividers
  static const Color borderSubtle = Color(0xFF1F2A36);
  static const Color borderDefault = Color(0xFF2D3C4D);
  static const Color borderEmphasis = Color(0xFF3E5063);
  static const Color borderAccent = Color(0xFF5B7186);

  // Accent (gold)
  static const Color accent = Color(0xFFFFD700);
  static const Color accentMuted = Color(0xFFCFA600);
  static const Color accentSoft = Color(0x33FFD700);
  static const Color accentEmphasis = Color(0xFFFFE45C);
}
```

#### Text

```dart
static const Color textPrimary = Color(0xFFECEFF1);
static const Color textSecondary = Color(0xFFB0BEC5);
static const Color textMuted = Color(0xFF90A4AE);
static const Color textDisabled = Color(0xFF5A6B7A);
static const Color textOnAccent = Color(0xFF0A0F14);
```

#### Skill colors — 4-shade ramps (8 skills × 4 shades)

Each skill: {base, light, dark, soft}. Light for highlights/hover, dark for borders/pressed, soft is 20% opacity for backgrounds/glows.

```dart
// Woodcutting (green)
static const Color woodcuttingBase = Color(0xFF66BB6A);
static const Color woodcuttingLight = Color(0xFF98EE99);
static const Color woodcuttingDark = Color(0xFF4A8C4E);
static const Color woodcuttingSoft = Color(0x3366BB6A);

// Mining (grey)
static const Color miningBase = Color(0xFF78909C);
static const Color miningLight = Color(0xFFA7C0CD);
static const Color miningDark = Color(0xFF546E7A);
static const Color miningSoft = Color(0x3378909C);

// Herbalism (light green)
static const Color herbalismBase = Color(0xFF9CCC65);
static const Color herbalismLight = Color(0xFFCFFF95);
static const Color herbalismDark = Color(0xFF6B9B37);
static const Color herbalismSoft = Color(0x339CCC65);

// Wayfinding (blue)
static const Color wayfindingBase = Color(0xFF29B6F6);
static const Color wayfindingLight = Color(0xFF73E8FF);
static const Color wayfindingDark = Color(0xFF0086C3);
static const Color wayfindingSoft = Color(0x3329B6F6);

// Lore (purple)
static const Color loreBase = Color(0xFFAB47BC);
static const Color loreLight = Color(0xFFDF78EF);
static const Color loreDark = Color(0xFF790E8B);
static const Color loreSoft = Color(0x33AB47BC);

// Cooking (orange)
static const Color cookingBase = Color(0xFFFFA726);
static const Color cookingLight = Color(0xFFFFD95B);
static const Color cookingDark = Color(0xFFC77800);
static const Color cookingSoft = Color(0x33FFA726);

// Crafting (cyan)
static const Color craftingBase = Color(0xFF26C6DA);
static const Color craftingLight = Color(0xFF6FF9FF);
static const Color craftingDark = Color(0xFF0095A8);
static const Color craftingSoft = Color(0x3326C6DA);

// Combat (red)
static const Color combatBase = Color(0xFFEF5350);
static const Color combatLight = Color(0xFFFF867C);
static const Color combatDark = Color(0xFFB61827);
static const Color combatSoft = Color(0x33EF5350);

static Map<String, Color> skillColorRamp(SkillType s) {
  switch (s) {
    case SkillType.woodcutting: return {
      'base': woodcuttingBase, 'light': woodcuttingLight,
      'dark': woodcuttingDark, 'soft': woodcuttingSoft,
    };
    // ... 7 more cases ...
  }
}
```

#### Quality colors — 3-shade ramps (4 tiers × 3 shades)

```dart
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
```

#### Semantic state colors

```dart
static const Color success = Color(0xFF4CAF50);
static const Color successSoft = Color(0x334CAF50);
static const Color warning = Color(0xFFFFB300);
static const Color warningSoft = Color(0x33FFB300);
static const Color error = Color(0xFFEF5350);
static const Color errorSoft = Color(0x33EF5350);
static const Color info = Color(0xFF1E88E5);
static const Color infoSoft = Color(0x331E88E5);
```

#### Tag colors (Codex)

```dart
static const Color tagWilds = Color(0xFF5BAA6F);
static const Color tagStone = Color(0xFFAAAAAA);
static const Color tagTide = Color(0xFF5B8FAA);
static const Color tagSource = Color(0xFF7B5BAA);
static const Color tagOldEmpire = Color(0xFFFFD700);
```

### 2.2 Typography tokens — `DSText`

`lib/design/typography.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

class DSText {
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

### 2.3 Spacing tokens — `DSSpace`

```dart
class DSSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double huge = 64;
}
```

All padding/margin/gap values across the app come from `DSSpace.*` post-migration.

### 2.4 Radius tokens — `DSRadius`

```dart
class DSRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
  static const double pill = 999;
}
```

### 2.5 Shadow tokens — `DSShadow`

```dart
class DSShadow {
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
```

### 2.6 Motion tokens — `DSMotion`

```dart
class DSMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration deliberate = Duration(milliseconds: 500);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve linear = Curves.linear;

  static const Duration buttonPress = fast;
  static const Duration counterTween = standard;
  static const Duration modalEntry = slow;
  static const Duration celebration = deliberate;
}
```

### 2.7 Migration example

Before:
```dart
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: const Color(0xFF1B2631),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFF2D3C4D)),
  ),
  child: Text('Hello', style: TextStyle(color: Colors.white, fontSize: 14)),
)
```

After:
```dart
Container(
  padding: const EdgeInsets.all(DSSpace.md),
  decoration: BoxDecoration(
    color: DSColors.surface3,
    borderRadius: BorderRadius.circular(DSRadius.md),
    border: Border.all(color: DSColors.borderDefault),
  ),
  child: Text('Hello', style: DSText.bodyMedium(context)),
)
```

---

## 3. Component Primitives

All 15 primitives live in `lib/design/primitives/` (one file each). Each component references tokens — never raw values.

### 3.1 GameButton

```dart
enum GameButtonVariant { primary, secondary, ghost, danger }
enum GameButtonSize { sm, md, lg }

class GameButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final GameButtonVariant variant;
  final GameButtonSize size;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;
}
```

| Variant | Background | Text | Border |
|---|---|---|---|
| primary | `accent` | `textOnAccent` | none |
| secondary | `surface4` | `textPrimary` | `borderDefault` |
| ghost | transparent | `textPrimary` | none |
| danger | `error` | white | none |

**Sizes:** sm (h=28, text=11, padding=12/6), md (h=36, text=13, padding=16/8), lg (h=44, text=14, padding=20/12).

**Microinteraction:** press scale 1.0 → 0.96 over `fast`. Loading state replaces label with `CircularProgressIndicator` and disables tap. Disabled = `borderSubtle` + `textDisabled`. SFX `ui_click`.

### 3.2 GameCard

```dart
enum GameCardVariant { flat, elevated, glass }

class GameCard extends StatelessWidget {
  final Widget child;
  final GameCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accentBorder;
  final double? width;
}
```

| Variant | Background | Border | Shadow |
|---|---|---|---|
| flat | `surface3` | `borderDefault` | none |
| elevated | `surface3` | `borderDefault` | `DSShadow.md` |
| glass | `surface3.withOpacity(0.85)` | `borderDefault.withOpacity(0.8)` | `DSShadow.lg` + backdrop blur |

If `onTap != null`, hover/press = `surface5` tint. Optional `accentBorder` paints a 4dp colored stripe on the left edge.

### 3.3 GameChip

```dart
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
}
```

| Variant | Background | Text | Border |
|---|---|---|---|
| filled | `color.withOpacity(0.15)` | `color` | `color.withOpacity(0.4)` |
| outlined | transparent | `textPrimary` | `borderEmphasis` |
| stat | `surface4` | label muted + value primary | `borderSubtle` |

Tappable variants get press scale + SFX.

### 3.4 GameSheet

```dart
class GameSheet {
  static Future<T?> showBottom<T>(BuildContext context, {required Widget child, double? heightFactor});
  static Future<T?> showFullscreen<T>(BuildContext context, {required Widget child, String? title});
}
```

- **Bottom:** `surface4` bg, `DSRadius.xxl` top corners, drag handle (4×40 pill), padding `DSSpace.lg`. Slides up over `modalEntry` (350ms) with `easeOut`.
- **Fullscreen:** `surface2` bg, optional title bar with close icon. Fade + scale (0.96 → 1.0).

SFX `ui_sheet_open` on entry.

### 3.5 GameTabs

```dart
enum GameTabsVariant { pills, underline, segments }

class GameTabs extends StatelessWidget {
  final List<GameTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final GameTabsVariant variant;
}

class GameTab {
  final String label;
  final IconData? icon;
  final String? badgeText;
}
```

| Variant | Look |
|---|---|
| pills | rounded pill per tab; selected = `accentSoft` + `accent` text |
| underline | flat row; selected gets 2dp underline in `accent` |
| segments | full-width row of equal buttons; selected = `surface5` |

Tab change crossfades the indicator over `standard` with `easeInOut`. Badge bumps with spring when count increases. SFX `ui_tab_switch`.

### 3.6 GameIconButton

```dart
class GameIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? iconColor;
  final double size;
  final bool selected;
}
```

Circular 32×32 hit area, icon centered. Selected = `accentSoft` bg. Press = scale 0.92. SFX `ui_click_soft`.

### 3.7 GameToast

```dart
enum GameToastVariant { success, error, info }

class GameToast {
  static void show(BuildContext context, {
    required String message,
    GameToastVariant variant = GameToastVariant.info,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  });
}
```

Slides in from top, stays for `duration`, slides out. Stacked if multiple. Rounded `surface4` card with colored left stripe matching variant. SFX `ui_success`/`ui_error`/`ui_info_chime`.

### 3.8 GameTooltip

```dart
class GameTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final TooltipTriggerMode triggerMode;
}
```

Wraps Flutter's `Tooltip` with token styling: `surface5` bg, `textPrimary` text, `DSRadius.sm`, fade in/out over `fast`. No SFX.

### 3.9 GameInput

```dart
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
}
```

`surface4` bg, `borderDefault` border, focused = `borderAccent`, error = `error` border + `error` text below. Label above field in `DSText.label`. Focus ring fade in/out over `fast`.

### 3.10 GameSwitch

```dart
class GameSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
}
```

Custom-drawn 44×24 switch. Track `surface4` (off) / `accentSoft` (on). Thumb 20×20, `borderEmphasis` (off) / `accent` (on). Slide over `standard` with `easeOut`; track crossfades. SFX `ui_toggle`.

### 3.11 GameSlider

```dart
class GameSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String? label;
  final String Function(double)? valueFormatter;
}
```

Track 4dp height, thumb 16dp. Active portion `accent`, inactive `surface4`. Floating value label above thumb during drag — fades in on drag, out on release over `fast`.

### 3.12 GameAvatar

```dart
enum GameAvatarSize { sm, md, lg }

class GameAvatar extends StatelessWidget {
  final String emoji;
  final Color? backgroundColor;
  final GameAvatarSize size;
  final bool showRing;
  final String? label;
}
```

Sizes: sm (32), md (48), lg (64). Circular bg with centered emoji at 60% size. Optional ring = 2dp `accent` border.

### 3.13 GameListItem

```dart
class GameListItem extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSelected;
}
```

Replaces `ListTile`. Padding `DSSpace.md` vertical / `DSSpace.lg` horizontal. Selected = `surface4` bg. Tappable items get press scale + SFX `ui_click_soft`.

### 3.14 GameProgressBar

```dart
class GameProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final double height;
  final bool animate;
  final String? label;
  final bool showGlow;
}
```

Refactors existing `CustomProgressBar`. Animate tweens fill over `counterTween` (200ms). Glow pulses subtly at >90% fill.

### 3.15 GameSkeleton

```dart
class GameSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry? borderRadius;
}
```

Shimmering placeholder. Left-to-right gradient sweep over 1.2s on `surface4` bg. Used sparingly.

### 3.16 Cross-component patterns

- **`_AnimatedPressable`** internal wrapper handles scale 1.0 → 0.96 over 120ms — used by every tappable primitive
- **SFX hook:** every primitive that fires sound calls `AudioEngine.instance.play(key)` — no-op if Sound disabled
- **Disabled state:** `onPressed: null` → bg `surface2`, text `textDisabled`, no SFX
- **Semantic labels:** every icon-only primitive accepts optional `semanticLabel` for screen readers

---

## 4. Motion Vocabulary & Microinteractions

### 4.1 The motion language

Every animation uses `DSMotion` tokens:

| Token | Duration | Curve | When |
|---|---|---|---|
| `fast` | 120ms | `easeOut` | Button press, focus ring |
| `standard` | 200ms | `easeOut` | Counter tweens, tab switch |
| `slow` | 350ms | `easeOut` | Modal entry/exit, page transition |
| `deliberate` | 500ms | `spring` | Celebrations |

Spring is reserved for celebration moments only.

### 4.2 `_AnimatedPressable` wrapper

```dart
class _AnimatedPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? sfxKey;
  final HitTestBehavior behavior;
  final double pressedScale;       // default 0.96
  final Duration pressDuration;    // default DSMotion.fast
}
```

`AnimationController` scaling between 1.0 and `pressedScale`. On tap-down: forward. On tap-up / cancel: reverse. Fires `onTap` + plays `sfxKey` on tap-up.

### 4.3 Microinteraction catalog (15 moments)

#### Tier 1 — Always-on feedback

1. **Button press** — scale 1.0 → 0.96 → 1.0 over `fast`. SFX `ui_click`.
2. **Number tween** — any displayed number (gold, HP, XP, quality count) changes via `TweenAnimationBuilder<double>` over `standard` with `easeOut`.
3. **Progress bar fill** — `GameProgressBar` with `animate: true` tweens fill width over `standard`.
4. **Focus ring** — form inputs fade in 2dp `accent` border over `fast`. Fade out on blur.
5. **Tab switch** — selected indicator slides + colors crossfade over `standard` with `easeInOut`. Content crossfades.

#### Tier 2 — Modal & navigation

6. **Modal sheet entry** — slides up over `slow`, content fades in at 70% mark.
7. **Page transition** — bottom-nav switch uses `AnimatedSwitcher` + small `SlideTransition` (8dp up) over `standard`.
8. **Toast appearance** — slides down from top + fades over `slow`, dwells, slides up + fades on dismiss.
9. **Tooltip fade** — long-press fade in + slide up 4dp over `fast`.

#### Tier 3 — Game-moment celebrations

10. **Level up** — existing particle burst + spring scale-pulse on skill card (1.0 → 1.1 → 1.0) + SFX `ui_levelup_chime`. ~500ms total.
11. **Masterwork complete** — skill card flashes with full color glow; spec badge appears with spring entry (scale 0 → 1.2 → 1.0); bg flashes skill's `light` shade for 200ms. SFX `ui_masterwork_complete`.
12. **Quality tier shimmer** — Fine/Masterwork items get a gradient sweep over the card. Linear gradient left → right over 1200ms, ease-in-out. Triggered on first display + on tap. Masterwork uses `qualityMasterworkGlow`.
13. **Puzzle correct lock** — all-green state triggers cards pulsing spring scale (1.0 → 1.05 → 1.0) in top-to-bottom stagger (50ms apart), then Reading overlay slides up. SFX `ui_puzzle_solve`.
14. **Puzzle wrong lock** — cards briefly shake (3 oscillations of 4dp over 200ms). Red borders fade in over `fast`. SFX `ui_error_soft`.
15. **Combat hit** — beast HP bar tweens down (existing) + beast icon flash scale 1.0 → 1.06 → 1.0 over `fast`. Player damage = own HP bar tween + 50% opacity flash on screen border in `error`. Crits = extra `accent` pulse on damage number + SFX `ui_crit`.

### 4.4 Implementation patterns

- `TweenAnimationBuilder<double>` — one-shot value tweens
- `AnimatedScale`, `AnimatedOpacity`, `AnimatedSlide` — property animations
- `AnimatedSwitcher` — crossfades
- `Hero` — shared-element (rarely; only on item-detail navigation)
- `AnimationController` + `AnimatedBuilder` — custom multi-property (shimmer sweep, puzzle stagger)

No third-party animation library required.

### 4.5 Performance

- `RepaintBoundary` around frequently-animated widgets to isolate paint
- `AnimatedBuilder` not `AnimatedWidget` when only subtree animates
- Stop controllers on widget dispose
- Skeleton shimmer (only continuous animation) caps at 1.2s loop

---

## 5. Sound Layer

### 5.1 Audio package

```yaml
dependencies:
  audioplayers: ^6.0.0
```

### 5.2 Sound catalog (13 SFX)

| Key | Where | Style |
|---|---|---|
| `ui_click` | GameButton press, GameChip tap, GameIconButton tap | Short crisp click, ~60ms |
| `ui_click_soft` | GameListItem tap, secondary | Softer click, ~80ms |
| `ui_toggle` | GameSwitch | Two-tone toggle, ~100ms |
| `ui_sheet_open` | GameSheet open | Whoosh, ~200ms |
| `ui_tab_switch` | GameTabs change | Soft tick, ~80ms |
| `ui_success` | Craft complete, item used, quest complete | Bright two-note chime, ~300ms |
| `ui_error` | Energy too low, action blocked | Low buzz, ~250ms |
| `ui_info_chime` | Notification, World Event modal | Single ding, ~200ms |
| `ui_levelup_chime` | Level up | Ascending arpeggio, ~600ms |
| `ui_masterwork_complete` | Masterwork trial success | Triumphant flourish, ~1200ms |
| `ui_crit` | Critical Strike in combat | Sharp metallic clink |
| `ui_puzzle_solve` | Codex puzzle correct | Gentle harmonic resolve |
| `ui_error_soft` | Wrong puzzle Lock | Single muted tone |

All files placed under `assets/audio/sfx/` and registered in `pubspec.yaml`. Total bundle addition ~1MB.

### 5.3 Asset sourcing

Free **kenney.nl Interface Sounds** pack (CC0 license) covers ~90% of the catalog. All files must be CC0 or compatible permissive license.

### 5.4 Audio engine

New `lib/engine/audio_engine.dart`:

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
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(AssetSource('audio/sfx/$key.wav'));
      _players[key] = player;
    }
  }

  Future<void> play(String key) async {
    if (!_enabled) return;
    final player = _players[key];
    if (player == null) return;
    await player.stop();
    await player.setVolume(_volume);
    await player.resume();
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
  }

  bool get enabled => _enabled;
  double get volume => _volume;
}

const _allSfxKeys = [
  'ui_click', 'ui_click_soft', 'ui_toggle', 'ui_sheet_open', 'ui_tab_switch',
  'ui_success', 'ui_error', 'ui_info_chime', 'ui_levelup_chime',
  'ui_masterwork_complete', 'ui_crit', 'ui_puzzle_solve', 'ui_error_soft',
];
```

Initialized in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioEngine.instance.init();
  runApp(...);
}
```

### 5.5 Engine-side SFX firing

```dart
// In GameEngine:
void playSfx(String key) {
  AudioEngine.instance.play(key);
}
```

Wired moments:
- `_onMasterworkSuccess` → `playSfx('ui_masterwork_complete')`
- Skill level-up → `playSfx('ui_levelup_chime')`
- Critical strike in `_resolveCombatRound` → `playSfx('ui_crit')`
- `lockCodexPuzzle` correct → `playSfx('ui_puzzle_solve')`
- `lockCodexPuzzle` wrong → `playSfx('ui_error_soft')`
- `_grantReward` for any reward → `playSfx('ui_success')`
- Random event modal appears → `playSfx('ui_info_chime')`

### 5.6 Settings screen

A new top-level Settings route, mounted via a gear icon on the AppBar (existing reset button moves into an overflow menu alongside Settings).

```
┌─ Settings ──────────────────────────────┐
│                                          │
│  AUDIO                                   │
│  ┌────────────────────────────────────┐ │
│  │  🔊 Sound Effects        [ON ⬤  ] │ │
│  │  Volume                              │ │
│  │  ●━━━━━━━━━━━━━━━━━━━━━━━━━ 70%      │ │
│  └────────────────────────────────────┘ │
│                                          │
└──────────────────────────────────────────┘
```

Built with new primitives: GameSwitch for enable, GameSlider for volume, GameCard wrapping the section. Settings opens via `GameSheet.showFullscreen`.

Settings state lives in `AudioEngine.instance` for now (no persistence — resets on app restart). When persistence lands, AudioEngine writes to SharedPreferences.

### 5.7 Graceful degradation

If audio fails to load: `AudioEngine.init()` catches errors silently. `play()` becomes no-op. Settings still shows controls. Game continues with zero audio.

---

## 6. Implementation Order, Testing, Migration

### 6.1 Test strategy

**Widget tests for each primitive** — one test file per primitive in `test/design/`:
- Renders with correct token-based styling
- Variants render appropriately
- Tap callbacks fire
- Disabled state blocks interaction + SFX
- Animations trigger (where applicable)

**Token tests** — `test/design/tokens_test.dart`:
- Surface elevations form monotonic darkness ramp
- Skill color ramps have all 4 shades (base/light/dark/soft)
- Quality color ramps have all 3 shades (base/shimmer/glow)
- Semantic colors exist for all 4 states (success/warning/error/info)

**Typography tests** — `test/design/typography_test.dart`:
- DSText methods return TextStyles with expected font families
- Sizes match scale spec

**Audio tests** — `test/engine/audio_engine_test.dart`:
- `init()` loads all 13 SFX keys
- `play(key)` is no-op when disabled
- Volume clamps to 0–1
- Unknown key is no-op

**Motion tests** (lightweight):
- `_AnimatedPressable` forwards on tap-down, reverses on tap-up
- `GameProgressBar.animate: true` triggers `TweenAnimationBuilder`
- `GameToast.show` returns a Future completing after `duration`

**Integration test:**
- Render existing Dashboard with new tokens imported — verify zero visible regressions and no compilation errors

### 6.2 Implementation order

Single PR, internally staged:

1. **Create `lib/design/` directory** — empty module structure.
2. **Tokens + Typography** — `tokens.dart` + `typography.dart`. Token tests pass.
3. **`_AnimatedPressable`** — `lib/design/primitives/_animated_pressable.dart`.
4. **GameButton** — smallest primitive with all the patterns; test thoroughly.
5. **GameCard, GameChip, GameIconButton, GameAvatar** — visual primitives.
6. **GameTabs** — indicator animation.
7. **GameListItem** — built atop GameCard.
8. **GameProgressBar** — refactor existing CustomProgressBar; update all call sites.
9. **GameInput, GameSwitch, GameSlider** — form primitives for Settings.
10. **GameTooltip, GameSkeleton** — utility primitives.
11. **GameSheet, GameToast** — modal patterns; wire into existing `showModalBottomSheet` / `ScaffoldMessenger.showSnackBar` call sites.
12. **AudioEngine + assets** — add `audioplayers` dep, create engine, add `assets/audio/sfx/` directory, place 13 sound files, register in pubspec. Wire `init()` in `main.dart`.
13. **Wire SFX into primitives** — GameButton → `ui_click`, GameSwitch → `ui_toggle`, etc.
14. **Wire engine-level SFX** — level-up, masterwork complete, crit, puzzle solve. Modify existing engine paths.
15. **Settings screen** — new full-screen route from AppBar gear/overflow. Audio section with GameSwitch + GameSlider.
16. **Microinteraction wiring for existing widgets** — number counters, quality badges, level-up celebration, masterwork completion. No layout changes; just add animations / SFX to existing widget trees.
17. **Tests** — written alongside each step.

Each numbered step compiles and the game runs.

### 6.3 Migration plan

Gradual adoption per `lib/views/`:

- After Spec 7a ships, existing views still use `GameTheme.*`, raw `Container`, raw `ListTile`, etc.
- Migration is opportunistic during Spec 7b (per-view redesigns) and any feature work.
- Two systems coexist; `GameTheme.*` remains backwards-compatible.
- No big-bang migration commit.

**Migration recipe per view:**
1. Replace raw color literals → `DSColors.*`
2. Replace raw spacing → `DSSpace.*`
3. Replace `Container` with header/border → `GameCard`
4. Replace `ListTile` → `GameListItem`
5. Replace `ElevatedButton`/`TextButton` → `GameButton`
6. Replace text styles → `DSText.*`
7. Replace `Chip`/status pills → `GameChip`
8. Replace `showModalBottomSheet` → `GameSheet.showBottom`
9. Replace `Tooltip` → `GameTooltip`
10. Replace `ScaffoldMessenger.showSnackBar` → `GameToast.show`

### 6.4 Risks & deferrals

- **`google_fonts` may need network fetch for Fraunces on first load** — pre-load via pubspec font asset config so the font ships bundled.
- **`audioplayers` package size & platform compat** — ~1MB bundle add; works iOS/Android/Windows/macOS/Web (Web has slight latency).
- **Web audio latency** — browsers gate audio until first user interaction; SFX activate after first tap.
- **Tweens during combat may stutter** — `RepaintBoundary` around animated counters; profile and tune.
- **Gradual migration creates dual-system period** — accepted trade-off for incremental shipping.
- **Settings persistence not yet implemented** — audio toggle resets on app restart (matches current no-persistence model).
- **Deferred to Spec 7b:** per-view layout redesigns; information-architecture refinements; structural changes to existing screens.
- **Deferred to future spec(s):** music/ambient loops; haptic feedback; full WCAG-AAA accessibility audit; light theme; internationalization.

### 6.5 Player walkthrough

A player after Spec 7a ships:

1. Opens app. Visual feel similar but more polished — borders crisper, type hierarchy clearer.
2. Taps a button. Satisfying click + brief scale + audible click.
3. Travels to a zone. Tab transition feels smoother.
4. Hunts a Forest Boar. HP bars tween smoothly instead of snapping. Crit lights up with a metallic clink.
5. Levels up Crafting. Ascending arpeggio + skill card spring pulse + XP tween.
6. Reads a Codex Fragment. Renders in elegant Fraunces italic — first time it's distinguished from UI chrome.
7. Solves a puzzle. Harmonic resolve chime + staggered card pulse + Reading slides up.
8. Crafts a Fine-quality item. Inventory card shimmers blue when first shown.
9. Crafts a Masterwork item. Bigger gold shimmer, longer dwell.
10. Opens AppBar overflow → Settings → Audio. Toggles off Sound. All future SFX silent.
11. Re-toggles on, adjusts Volume slider to 30%. SFX softer.
12. Number-tweens are the most pervasive change: gold counter ticks up, XP bar fills smoothly, energy bar drains visibly during action.

The game feels deliberate now. Nothing snaps. Everything has weight.

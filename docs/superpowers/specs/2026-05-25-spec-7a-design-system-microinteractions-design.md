# Spec 7a — Design System & Microinteractions

**Date:** 2026-05-25 (revised 2026-05-26)
**Status:** Revised in place (pending spec review)
**Parent:** [Echoes from the Deep umbrella vision](2026-05-24-echoes-from-the-deep-vision.md)
**Companion specs:** Spec 7b (per-screen redesigns) — separate brainstorm; Spec 7c (sound layer) — separate brainstorm
**Depends on:** Specs 1–5 implemented. Specs 6a (in-progress), 6b, 6c designed (downstream callers of the primitives this spec ships).
**Scope:** Foundation refresh. Ships design tokens, the 15 `Game*` component primitives, the motion vocabulary (6 existing microinteractions + 3 new + 2 dropped), and migration of the three highest-traffic surfaces (Dashboard, Inventory, Codex tabs). Sound layer is **removed** from this spec and deferred to Spec 7c. Per-screen redesigns are **removed** and deferred to Spec 7b.

---

## 1. Goals, Scope, What's Changed

### 1.1 Why this revision exists

Original 7a (committed `0d2b732` on 2026-05-25 — see git history for the pre-revision contents) was written before Specs 4, 5, 6a, 6b, 6c shipped or existed in design. In the months since:

- Spec 4 added combat stances, telegraphed beast specials, random events, Masterwork specializations
- Spec 5 added 3-phase Echo bosses + breach cleansing rituals
- Spec 6a (in implementation) adds repair UI, reagent notice cards, Tavern view, merchant rep chips
- Spec 6b adds player XP bar, achievements tab, derived titles
- Spec 6c adds Nexus zone + You-Win modal + Source Cleanser title
- Several primitives the downstream specs reference (`GameCard`, `GameChip`, `GameProgressBar`, `GameTabs`, `GameButton`) are documented but **none exist in code**

This revision (a) refreshes the token catalog against the current game, (b) confirms the full 15-primitive plan and updates it for what downstream specs assume, (c) updates the motion catalog to reflect what already shipped + what's still needed, (d) **drops the sound layer entirely** (moved to Spec 7c), (e) scopes migration to three high-traffic surfaces (rest moves to Spec 7b).

### 1.2 What revised 7a ships

1. **Design tokens** (`DSColors`, `DSText`, `DSSpace`, `DSRadius`, `DSShadow`, `DSMotion`) — token-only API replacing direct `GameTheme.*` access. Adds **Combat skill color** (missing from current `getSkillColor`), Codex tag color ramp (Wilds/Stone/Tide/Source/OldEmpire/Misc), a 5-tier surface elevation scale, and a 5-tier merchant rep color ramp (didn't exist in original 7a).
2. **All 15 component primitives** as originally planned — `GameButton`, `GameCard`, `GameChip`, `GameSheet`, `GameTabs`, `GameIconButton`, `GameToast`, `GameTooltip`, `GameInput`, `GameSwitch`, `GameSlider`, `GameAvatar`, `GameListItem`, `GameProgressBar`, `GameSkeleton`. Built on top of the new tokens. Each gets a focused test and a golden snapshot.
3. **Motion vocabulary refresh** — confirms the 6 existing microinteraction widgets, formalizes the missing `_AnimatedPressable` wrapper, adds 3 new microinteractions for game moments that didn't exist when original 7a was written (phase-banner-flash, repair-shimmer, reputation-tier-up), drops 2 that didn't survive contact with the game.
4. **Migration of high-traffic surfaces** — Dashboard, Inventory, Codex tabs are refactored to use new tokens + primitives. Build, Skills, Tavern, and most modals stay on raw widgets until Spec 7b screen redesigns hit them.

### 1.3 What revised 7a does NOT do

- **Sound layer** (original 7a §5) — deferred to Spec 7c; `playSfx` stays a stub.
- **Per-screen redesigns** — moved to Spec 7b. This spec ships tokens + primitives + minimal migration, not new layouts.
- Settings screen (was scoped under Sound originally; deferred with sound).
- Performance profiling work beyond a "no jank in 60fps debug mode" smoke check.
- Save persistence (still not in scope anywhere).
- Build / Skills / Tavern view migrations.
- Combat HUD / narrative event modal / you-win modal layout redesign.

### 1.4 Acceptance criteria

After revised 7a ships:

1. `lib/theme/design_tokens.dart` exists with `DSColors`, `DSText`, `DSSpace`, `DSRadius`, `DSShadow`, `DSMotion` modules.
2. `GameTheme.getSkillColor(SkillType.combat)` returns a defined color (not the muted fallback).
3. All 15 `Game*` primitives exist as files in `lib/widgets/game/` with focused tests + golden snapshots.
4. The 3 high-traffic surfaces (Dashboard, Inventory, Codex Beasts/Quests/Fragments tabs) render exclusively from tokens + primitives.
5. The motion catalog file documents all 9 microinteractions (6 shipped + 3 new) with intended trigger sites.
6. `playSfx` remains a stub (sound deferred); all current call sites continue to no-op silently.
7. `flutter test` is green; no widget tests fail due to token/primitive migration.
8. Visual smoke check: dashboard, inventory, codex tabs render identically or visibly cleaner — not regressed.
9. Source-grep guard (`test/widgets/tokens_only_test.dart`) fails the build if any of the 3 migrated files re-introduces raw color literals or legacy `GameTheme.cardBg` / `GameTheme.background` / `GameTheme.border` references.

### 1.5 What's changed vs original 7a (delta summary)

| Original 7a | Revised 7a |
|---|---|
| §2 — token catalog defined 8 skill colors (mentioned Combat) | Same, but Combat color now confirmed and added to `getSkillColor` (was missing); merchant tier color ramp added |
| §3 — 15 primitives, all marked "ship" | Same 15; ship order re-prioritized by downstream spec usage |
| §4 — 15 microinteractions cataloged | Confirmed 6 shipped + adds 3 new game-moment microinteractions (phase-banner-flash, repair-shimmer, reputation-tier-up); drops 2 vague entries (`ambient_zone_parallax`, `skill_xp_glow`) that didn't survive contact with the game |
| §5 — sound layer (13 SFX + AudioEngine + settings) | **Removed.** Deferred to Spec 7c. |
| §6 — migration plan touched every screen | Migration scoped to 3 high-traffic surfaces (Dashboard, Inventory, Codex); rest moves to Spec 7b screen redesigns |

### 1.6 Design principles inherited

- **No art** — single-emoji icons + Material Icons for UI chrome.
- **No dual-emoji icons** — single glyph per entity (per [feedback_no_dual_emoji](../../C--Users-t8rto-Desktop-flutter-text-based-rpg/memory/feedback_no_dual_emoji.md)).
- **Progressive discovery** — primitives must support hiding rather than greying. `GameCard` with `visible: false` collapses; locked entries should never use a token to render `???` shapes.
- **Systems converse** — tokens are the source of truth for every color/space/font decision; primitives are the source of truth for every shape that recurs.

---

## 2. Design Token Catalog

### 2.1 File structure

```
lib/theme/
├── game_theme.dart          (existing — becomes a thin re-export + legacy bridge during migration)
└── design_tokens.dart       (NEW — the canonical token module)
```

`design_tokens.dart` exposes 6 token modules:

```dart
class DSColors { /* … */ }
class DSText   { /* … */ }
class DSSpace  { /* … */ }
class DSRadius { /* … */ }
class DSShadow { /* … */ }
class DSMotion { /* … */ }
```

All token access is via static const where possible. Color ramps that need runtime selection (skill / quality / tag / merchant tier) expose helper methods that return the appropriate shade.

### 2.2 `DSColors` — color tokens

#### Surface (5-tier elevation scale)

Promotes the current 2-color (`background` / `cardBg`) approach into a layered system:

| Token | Value | Use |
|---|---|---|
| `surface0` | `#0B1117` | Root background (darker than current `background`) |
| `surface1` | `#10171E` | Default canvas (= current `background`) |
| `surface2` | `#1B2631` | Cards (= current `cardBg`) |
| `surface3` | `#243240` | Elevated cards (modals on top of cards) |
| `surface4` | `#2D3C4D` | Highest elevation (active selection, focused control) = current `border` |

The current `border` color promotes to `surface4`; new border tokens:

| Token | Value | Use |
|---|---|---|
| `borderSubtle` | `#2D3C4D` | Default 1px stroke on cards/inputs |
| `borderStrong` | `#3C5066` | Active/focused stroke |

#### Text

| Token | Value | Use |
|---|---|---|
| `textPrimary` | `#ECEFF1` | Body, headings |
| `textSecondary` | `#B0BEC5` | Labels |
| `textMuted` | `#90A4AE` | Captions, disabled |
| `textInverse` | `#10171E` | Dark text on gold/highlight buttons |

#### Skill colors — 8 skills × 4 shades

**Combat color is new** (currently missing — `getSkillColor(SkillType.combat)` returns muted fallback in [game_theme.dart:35](../../lib/theme/game_theme.dart#L35)).

| Skill | Light | Base | Deep | Tint (bg wash) |
|---|---|---|---|---|
| Woodcutting | `#A5D6A7` | `#66BB6A` | `#388E3C` | `#1B2E1F` |
| Mining | `#B0BEC5` | `#78909C` | `#455A64` | `#1F262B` |
| Herbalism | `#C5E1A5` | `#9CCC65` | `#558B2F` | `#1F2D17` |
| Wayfinding | `#81D4FA` | `#29B6F6` | `#0277BD` | `#11242F` |
| Lore | `#CE93D8` | `#AB47BC` | `#6A1B9A` | `#241524` |
| Cooking | `#FFCC80` | `#FFA726` | `#E65100` | `#2E1F11` |
| Crafting | `#80DEEA` | `#26C6DA` | `#00838F` | `#11272A` |
| **Combat** (new) | `#FF8A80` | `#E53935` | `#B71C1C` | `#2E1414` |

Helper: `DSColors.skill(SkillType s, [SkillShade shade = SkillShade.base])`.

#### Quality colors — 4 tiers × 3 shades

| Quality | Light | Base | Deep |
|---|---|---|---|
| Crude | `#B0BEC5` | `#90A4AE` | `#546E7A` |
| Standard | `#FFFFFF` | `#ECEFF1` | `#B0BEC5` |
| Fine | `#81D4FA` | `#29B6F6` | `#0277BD` |
| Masterwork | `#FFE082` | `#FFD700` | `#F57C00` |

Helper: `DSColors.quality(QualityTier q, [QualityShade shade = QualityShade.base])`.

#### Codex tag colors — 6 tags × 2 shades

Used for fragment tag chips, region status, region cleanse banners.

| Tag | Base | Tint |
|---|---|---|
| Wilds | `#66BB6A` | `#1B2E1F` |
| Stone | `#78909C` | `#1F262B` |
| Tide | `#29B6F6` | `#11242F` |
| Source | `#FFD700` | `#2E2615` |
| OldEmpire | `#AB47BC` | `#241524` |
| Misc | `#90A4AE` | `#1F262B` |

Helper: `DSColors.tag(CodexTag t, [TagShade shade = TagShade.base])`.

#### Quest status

`questActive: #29B6F6`, `questComplete: #66BB6A`, `questFailed: #E53935`.

#### Merchant rep tier colors (NEW)

For 6a reputation chips; didn't exist in original 7a.

| Tier | Color |
|---|---|
| Stranger | `#90A4AE` (muted) |
| Familiar | `#81D4FA` (light blue) |
| TrustedPatron | `#9CCC65` (light green) |
| HonoredFriend | `#FFB300` (amber) |
| SwornCompanion | `#FFD700` (gold) |

Helper: `DSColors.merchantTier(MerchantTier t)` (depends on 6a's `MerchantTier` enum).

#### Semantic state colors

| Token | Value | Use |
|---|---|---|
| `success` | `#66BB6A` | Quest complete, achievement unlock |
| `warning` | `#FFA726` | Low energy, telegraph, low durability |
| `danger` | `#E53935` | Damage taken, fail state |
| `info` | `#29B6F6` | Neutral status, milestone fired |
| `goldAccent` | `#FFD700` | Title, masterwork, currency |

#### Resource bar colors

Carried from current theme; add `xpBar` for 6b's player XP.

| Token | Value | Use |
|---|---|---|
| `healthBar` | `#EF5350` | HP |
| `energyBar` | `#FFB300` | Energy |
| `xpBar` | `#FFD700` (muted gold) | Player XP per 6b §4.5 |

### 2.3 `DSText` — typography tokens

```dart
class DSText {
  // Display (rare — splash, You-Win screen)
  static TextStyle get displayLarge => _gothic(48, FontWeight.w700, DSColors.textPrimary);
  static TextStyle get displayMedium => _gothic(36, FontWeight.w700, DSColors.textPrimary);

  // Title (section headers, dashboard name line)
  static TextStyle get titleLarge => _gothic(24, FontWeight.w600, DSColors.textPrimary);
  static TextStyle get titleMedium => _gothic(20, FontWeight.w600, DSColors.textPrimary);
  static TextStyle get titleSmall  => _gothic(16, FontWeight.w600, DSColors.textPrimary);

  // Body (default copy, descriptions)
  static TextStyle get bodyLarge   => _serif(16, FontWeight.w400, DSColors.textPrimary);
  static TextStyle get bodyMedium  => _serif(14, FontWeight.w400, DSColors.textPrimary);
  static TextStyle get bodySmall   => _serif(12, FontWeight.w400, DSColors.textSecondary);

  // Label (button text, chips)
  static TextStyle get labelLarge  => _gothic(14, FontWeight.w600, DSColors.textPrimary);
  static TextStyle get labelMedium => _gothic(12, FontWeight.w600, DSColors.textPrimary);
  static TextStyle get labelSmall  => _gothic(10, FontWeight.w600, DSColors.textMuted);

  // Numeric (XP/HP/gold display — tabular figures)
  static TextStyle get numeric     => _mono(14, FontWeight.w600, DSColors.textPrimary);

  // Helpers using google_fonts (already in pubspec)
  static TextStyle _gothic(double size, FontWeight w, Color c) =>
      GoogleFonts.cinzel(fontSize: size, fontWeight: w, color: c);
  static TextStyle _serif(double size, FontWeight w, Color c) =>
      GoogleFonts.eczar(fontSize: size, fontWeight: w, color: c, height: 1.4);
  static TextStyle _mono(double size, FontWeight w, Color c) =>
      GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: w, color: c,
          fontFeatures: const [FontFeature.tabularFigures()]);
}
```

Three font families:
- **Cinzel** — display + UI labels (fantasy serif)
- **Eczar** — body (readable book serif)
- **JetBrains Mono** — numeric (tabular figures keep HP/XP/gold from jumping as digits change)

### 2.4 `DSSpace` — spacing scale

8pt grid:

```dart
class DSSpace {
  static const double xxs = 2;
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;   // most common card padding
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;

  // Padding helpers
  static const EdgeInsets card    = EdgeInsets.all(md);
  static const EdgeInsets section = EdgeInsets.symmetric(horizontal: md, vertical: sm);
  static const EdgeInsets dense   = EdgeInsets.all(sm);
}
```

Use `DSSpace.md` (not `16.0`) everywhere.

### 2.5 `DSRadius` — border radius

```dart
class DSRadius {
  static const double xs  = 4;    // chips
  static const double sm  = 8;    // buttons, inputs
  static const double md  = 12;   // cards
  static const double lg  = 16;   // modals
  static const double xl  = 24;   // hero containers
  static const double full = 999; // pills

  static BorderRadius all(double r) => BorderRadius.circular(r);
}
```

### 2.6 `DSShadow` — elevation

Five elevation levels matching the surface scale:

```dart
class DSShadow {
  static const List<BoxShadow> e0 = [];
  static const List<BoxShadow> e1 = [BoxShadow(color: Color(0x40000000), blurRadius: 2,  offset: Offset(0, 1))];
  static const List<BoxShadow> e2 = [BoxShadow(color: Color(0x50000000), blurRadius: 4,  offset: Offset(0, 2))];
  static const List<BoxShadow> e3 = [BoxShadow(color: Color(0x60000000), blurRadius: 8,  offset: Offset(0, 4))];
  static const List<BoxShadow> e4 = [BoxShadow(color: Color(0x70000000), blurRadius: 16, offset: Offset(0, 8))];
}
```

`GameCard.elevation: 0..4` selects.

### 2.7 `DSMotion` — durations & curves

```dart
class DSMotion {
  // Durations
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration quick   = Duration(milliseconds: 150);
  static const Duration medium  = Duration(milliseconds: 250);
  static const Duration slow    = Duration(milliseconds: 450);
  static const Duration epic    = Duration(milliseconds: 800);

  // Curves
  static const Curve standard   = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutQuint;
  static const Curve bounce     = Curves.elasticOut;
  static const Curve linear     = Curves.linear;
}
```

| Duration | Use |
|---|---|
| `instant` | Ripple, tap-state, button press scale |
| `quick` | Bounce, hover-like microinteractions |
| `medium` | Page slide, modal enter, tab indicator slide |
| `slow` | Chip morph, accent transitions, repair shimmer |
| `epic` | Phase banner, achievement modal entry, skeleton pulse loop |

### 2.8 Migration bridge (`game_theme.dart`)

[game_theme.dart](../../lib/theme/game_theme.dart) keeps its current exports (`GameTheme.background`, `getSkillColor`, etc.) but the bodies redirect to `DSColors`:

```dart
class GameTheme {
  static Color get background => DSColors.surface1;
  static Color get cardBg => DSColors.surface2;
  static Color get border => DSColors.borderSubtle;
  static Color get accentGold => DSColors.goldAccent;

  static Color getSkillColor(dynamic skillType) {
    // String-match wrapper around DSColors.skill() for legacy callers
  }
}
```

Existing screens keep working unmodified. New code uses `DSColors.*` directly. Spec 7b screen redesigns progressively drop the `GameTheme.*` calls.

### 2.9 Touch summary for §2

| File | Change |
|---|---|
| `lib/theme/design_tokens.dart` (new) | All 6 token modules: DSColors, DSText, DSSpace, DSRadius, DSShadow, DSMotion |
| [lib/theme/game_theme.dart](../../lib/theme/game_theme.dart) | Rewrite bodies as thin re-exports of `DSColors.*`; add Combat skill color path |
| `test/design_tokens_test.dart` (new) | Verify every helper returns non-null; skill enum coverage (all 8); tag enum coverage (all 6); merchant tier coverage (all 5) |

---

## 3. Component Primitives (15)

### 3.1 File structure

```
lib/widgets/game/
├── _animated_pressable.dart     (private — wrapper used by every interactive primitive; see §4.2)
├── game_button.dart
├── game_card.dart
├── game_chip.dart
├── game_sheet.dart
├── game_tabs.dart
├── game_icon_button.dart
├── game_toast.dart
├── game_tooltip.dart
├── game_input.dart
├── game_switch.dart
├── game_slider.dart
├── game_avatar.dart
├── game_list_item.dart
├── game_progress_bar.dart
└── game_skeleton.dart
```

Each file: one public widget class, focused tests in `test/widgets/game/<name>_test.dart`, golden snapshot in `test/widgets/game/golden/<name>.png`. Every primitive consumes ONLY from `DSColors` / `DSText` / `DSSpace` / `DSRadius` / `DSShadow` / `DSMotion` — never raw values, never `GameTheme.*`.

### 3.2 `GameButton`

**Use:** primary CTA, secondary action, destructive action. Wraps `_AnimatedPressable` (§4) for bounce-on-press.

```dart
enum GameButtonVariant { primary, secondary, destructive, ghost }
enum GameButtonSize { small, medium, large }

class GameButton extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  final VoidCallback? onPressed;
  final GameButtonVariant variant;
  final GameButtonSize size;
  final bool busy;        // shows GameSkeleton in label slot
  final bool fullWidth;
}
```

Variant → tokens:
- `primary` → `goldAccent` bg + `textInverse` label
- `secondary` → `surface3` bg + `textPrimary` label + `borderSubtle` stroke
- `destructive` → `danger` bg + `textPrimary`
- `ghost` → transparent + `textPrimary`

Disabled state: 40% opacity, no press animation.

### 3.3 `GameCard`

**Use:** content container. Replaces ad-hoc `Container(decoration: BoxDecoration(color: GameTheme.cardBg, …))` across current views.

```dart
class GameCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;       // default DSSpace.card
  final int elevation;            // 0..4 → DSShadow.e0..e4 + DSColors.surface1..surface4
  final Color? accentColor;       // optional left border accent (skill / tag tinting)
  final VoidCallback? onTap;      // makes the card pressable (wraps in _AnimatedPressable)
  final bool visible;             // false → SizedBox.shrink (per progressive discovery)
}
```

### 3.4 `GameChip`

**Use:** status pill, tag label, count indicator. Heavy use across Codex tabs, merchant rep, achievement category headers.

```dart
class GameChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;             // base; tint derived from color.withOpacity(0.15)
  final GameChipSize size;        // small (height 20) / medium (24) / large (28)
  final bool outlined;            // outline-only vs filled
  final VoidCallback? onTap;
}
```

Helper constructors:
- `GameChip.skill(SkillType s, {String? label})`
- `GameChip.tag(CodexTag t)`
- `GameChip.merchantTier(MerchantTier t)`
- `GameChip.quality(QualityTier q)`
- `GameChip.questStatus(QuestStatus s)`

Each pulls the appropriate color from `DSColors`.

### 3.5 `GameSheet`

**Use:** bottom-sheet modal. Replaces ad-hoc `showModalBottomSheet`. Standard chrome (drag handle, title row, close button), `surface3` background, `DSRadius.lg` top corners.

```dart
class GameSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? leadingIcon;
  final List<GameButton> actions;
  final bool showDragHandle;

  static Future<T?> show<T>(BuildContext c, {required GameSheet sheet});
}
```

### 3.6 `GameTabs`

**Use:** Codex tab bar, Tavern tab bar (Notice Board / Bram's Wares).

```dart
class GameTabs extends StatelessWidget {
  final List<GameTab> tabs;
  final int activeIndex;
  final ValueChanged<int> onTabChanged;
  final bool scrollable;
}

class GameTab {
  final String label;
  final IconData? icon;
  final int? badgeCount;          // shown as GameChip.small to the right of label
}
```

Active tab: `goldAccent` underline + `textPrimary` label. Inactive: `borderSubtle` underline + `textMuted` label. Tab change uses `DSMotion.medium` for the indicator slide.

### 3.7 `GameIconButton`

**Use:** standalone icon control — nav, dismiss, expand, settings.

```dart
class GameIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;              // 16 / 24 / 32 / 48
  final Color? color;
  final String? semanticLabel;    // accessibility
  final bool busy;
}
```

Wraps `_AnimatedPressable`.

### 3.8 `GameToast`

**Use:** transient log surface for non-celebration messages (subtler than `FloatingNotification`). Used by `log()` calls when severity is `info` or `warning` and the player isn't viewing the Activity Log.

```dart
class GameToast extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Duration duration;        // default DSMotion.epic
  final ToastSeverity severity;   // info / warning / success / danger
}
```

Auto-stacks if multiple fire in quick succession (max 3 visible; FIFO drop).

### 3.9 `GameTooltip`

**Use:** longpress-revealed info on inventory items, equipped slots, achievement badges. Mobile: longpress; future-proofs for hover when desktop comes.

```dart
class GameTooltip extends StatelessWidget {
  final Widget child;
  final String content;
  final Widget? richContent;      // optional rich content overrides plain text
}
```

### 3.10 `GameInput`

**Use:** text entry. Currently anticipated: search-filter on Codex/Inventory (probable in 7b screen redesigns), rename character (defer-until-needed). Built now so 7b doesn't block.

```dart
class GameInput extends StatefulWidget {
  final String label;
  final String? hint;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final IconData? leadingIcon;
  final String? errorText;
  final int? maxLength;
}
```

### 3.11 `GameSwitch`

**Use:** boolean settings (defer-until-Settings-screen ships). Built now to match the full primitive plan.

```dart
class GameSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;
}
```

### 3.12 `GameSlider`

**Use:** numeric slider (sound volume when 7c ships; quality preferences). Built now.

```dart
class GameSlider extends StatelessWidget {
  final double value;             // 0..1
  final ValueChanged<double> onChanged;
  final int? divisions;
  final String? label;
  final String Function(double)? labelBuilder;
}
```

### 3.13 `GameAvatar`

**Use:** player portrait circle on dashboard, NPC portrait in narrative event modals, merchant portrait on shop sheet.

```dart
class GameAvatar extends StatelessWidget {
  final String emoji;             // single glyph (per no-dual-emoji memory)
  final Color? ringColor;         // optional accent ring (skill color, tier color)
  final double size;              // 32 / 48 / 64 / 96
}
```

### 3.14 `GameListItem`

**Use:** standardized row in inventory lists, quest lists, fragment lists, merchant stock lists. Replaces variant `Row(children: [Icon, Text, …])` patterns.

```dart
class GameListItem extends StatelessWidget {
  final Widget leading;           // typically GameAvatar or Icon
  final String title;
  final String? subtitle;
  final Widget? trailing;         // typically GameChip or count text
  final VoidCallback? onTap;
  final bool selected;
  final bool dimmed;              // for "locked" but visible items
}
```

### 3.15 `GameProgressBar`

**Use:** HP, energy, player XP, durability, masterwork task progress, daily task progress.

```dart
class GameProgressBar extends StatelessWidget {
  final double value;             // 0..1
  final Color color;
  final Color? backgroundColor;   // defaults to color.withOpacity(0.15)
  final double height;            // 4 / 6 / 10
  final bool animated;            // animate value changes via DSMotion.medium
  final String? leadingLabel;     // optional text inside the bar
  final String? trailingLabel;    // e.g. "240/250"
}
```

### 3.16 `GameSkeleton`

**Use:** loading placeholder. Game is offline-only but useful for the brief frame between zone-travel commit and zone-content render, and for the busy-state of `GameButton`.

```dart
class GameSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double radius;            // defaults to DSRadius.xs
}
```

Pulses opacity 0.4 → 0.7 → 0.4 on `DSMotion.epic` loop.

### 3.17 Cross-component patterns

- **Every interactive primitive** wraps the press surface in `_AnimatedPressable` (§4) for the bounce feedback. Consistency = predictability.
- **Disabled state** is uniform: 40% opacity, no animation, no press handler. Implemented via a single `Opacity` wrapper at the primitive root.
- **No primitive owns its own color directly** — every color routes through `DSColors`. Lint rule (analysis_options.yaml) blocks `Color(0x…)` literals in `lib/widgets/game/`.

### 3.18 Test strategy

- One focused widget test per primitive (8–15 tests each): renders, respects disabled, fires `onPressed`/`onChanged`, applies token defaults, applies overrides.
- One golden snapshot per primitive at default state (locked PNG in repo).
- One golden snapshot per variant (e.g., `GameButton.primary`, `.secondary`, `.destructive`, `.ghost`).

### 3.19 Ship priority order

Downstream specs reference these heavily — ship in this order:

1. `GameCard`, `GameChip`, `GameProgressBar` — used everywhere
2. `GameButton`, `GameIconButton`, `GameTabs` — heavy use across views
3. `GameListItem`, `GameAvatar` — used in inventory, codex, merchant lists
4. `GameSheet`, `GameToast` — used by 6a repair modal, achievement notifications
5. `GameTooltip`, `GameInput` — used in 7b screen redesigns
6. `GameSwitch`, `GameSlider`, `GameSkeleton` — deferred-but-built (low current demand)

### 3.20 Touch summary for §3

| File | Change |
|---|---|
| `lib/widgets/game/*.dart` (15 new) | All 15 primitives + `_animated_pressable.dart` |
| `test/widgets/game/*_test.dart` (15 new) | Focused widget tests |
| `test/widgets/game/golden/*.png` (multiple) | Golden snapshots per variant |
| `analysis_options.yaml` | Lint rule banning raw `Color(0x…)` literals in `lib/widgets/game/` |

---

## 4. Motion Vocabulary & Microinteraction Refresh

### 4.1 The motion language

Every motion in the game belongs to one of three tiers:

| Tier | Purpose | Duration range | Examples |
|---|---|---|---|
| **T1 — Feedback** | "Your tap registered." | `instant`–`quick` (80–150ms) | Bounce on press, ripple, focus ring |
| **T2 — Continuity** | "You moved from A to B." | `medium` (250ms) | Page slide, tab indicator, modal enter |
| **T3 — Celebration** | "Something important happened." | `slow`–`epic` (450–800ms) | Coin spawn, particle burst, phase banner |

Rule: never use a T3 motion for a T1 moment. Tap → bounce, not particle burst. Celebrations are rare and earned.

### 4.2 `_AnimatedPressable` — the foundational wrapper

Named in original 7a but never extracted. Formalize now — every interactive primitive in §3 wraps its press surface in it.

```dart
// lib/widgets/game/_animated_pressable.dart
class _AnimatedPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  State<_AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<_AnimatedPressable> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: DSMotion.instant,
    lowerBound: 0.94,
    upperBound: 1.00,
    value: 1.00,
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { if (widget.enabled) _ctrl.reverse(); },
      onTapUp: (_)   { if (widget.enabled) _ctrl.forward(); },
      onTapCancel: () { if (widget.enabled) _ctrl.forward(); },
      onTap: widget.enabled ? widget.onPressed : null,
      child: ScaleTransition(scale: _ctrl, child: widget.child),
    );
  }
}
```

Existing [bounce_tap.dart](../../lib/widgets/bounce_tap.dart) is **superseded** — the wrapper above takes its job and ships inside every primitive. Mark `bounce_tap.dart` deprecated; remove after migration.

### 4.3 Microinteraction catalog (9 total)

Down from original 7a's 15. Two vague entries dropped; three new ones added for game moments that didn't exist when original 7a was written.

#### Already shipped (6)

| ID | Widget | Trigger sites | Tier |
|---|---|---|---|
| `tap_bounce` | `_AnimatedPressable` (§4.2) | Every interactive primitive | T1 |
| `coin_spawn` | [coin_animation.dart](../../lib/widgets/coin_animation.dart) | Sell completion, gold reward, quest gold reward | T3 |
| `floating_notification` | [floating_notification.dart](../../lib/widgets/floating_notification.dart) | Achievement unlock, milestone fire, item received | T3 |
| `particle_explosion` | [particle_explosion.dart](../../lib/widgets/particle_explosion.dart) | Combat critical hit, masterwork completion, fragment puzzle solve | T3 |
| `pulsing_dot` | [pulsing_dot.dart](../../lib/widgets/pulsing_dot.dart) | New-content indicator on tab, unread quest, available masterwork | T1 |
| `flying_item_overlay` | [flying_item_overlay.dart](../../lib/widgets/flying_item_overlay.dart) | Item gathered → inventory icon arc | T2 |

#### New (3)

| ID | Trigger | Motion |
|---|---|---|
| `phase_banner_flash` | Echo / Source combat phase transition (Spec 5 + 6c) | Full-width banner slides down from top (`DSMotion.medium`), shows phase narration line in `DSText.titleMedium` with the phase theme color (Wilds green / Stone grey / Tide blue), auto-dismisses after 1.8s |
| `repair_shimmer` | Repair completion at Bench or merchant (Spec 6a) | Animated gradient sweep (left → right) across the repaired item card in `DSColors.goldAccent` with 30% opacity, `DSMotion.slow`, once |
| `reputation_tier_up` | Merchant rep tier-up (Spec 6a) | Rep chip on shop scales 1.0 → 1.4 → 1.0 with `DSMotion.bounce` curve, color shifts to next tier's color over `DSMotion.slow`, fires a `floating_notification` saying "Hilda now trusts you" (or whichever merchant name) |

#### Dropped from original 7a (2)

| ID | Reason for drop |
|---|---|
| `ambient_zone_parallax` | Pure decoration; no game moment requires it; would be performance-fragile on lower-end devices |
| `skill_xp_glow` | XP ticks too frequent — a glow on each would be visual noise. `pulsing_dot` covers the rare "new content" cases instead |

### 4.4 New widgets to build

```
lib/widgets/microinteractions/
├── phase_banner_overlay.dart      (new)
├── repair_shimmer.dart            (new)
├── reputation_tier_up_effect.dart (new)
└── microinteraction_dispatcher.dart (new — concurrency cap; §4.5)
```

Trigger sites for the 3 new microinteractions:

| Widget | Engine signal | Subscribe site |
|---|---|---|
| `PhaseBannerOverlay` | `CombatState.activePhaseIndex` changes mid-combat | Watched by the combat view (extended `combat_action_bar.dart` or wrapped in a Stack at dashboard level) |
| `RepairShimmer` | `engine.lastRepairedSlotId` (new field, set by `repairWithMaterials` / `repairWithGold` for one frame) | Watched by [inventory_view.dart](../../lib/views/inventory_view.dart) item rows |
| `ReputationTierUpEffect` | `engine.lastRepTierUp` (new field, set by merchant tier-up handler for one frame) | Watched by the shop sheet |

Each effect widget reads the engine signal via `Consumer<GameEngine>`, plays once on change, then dismisses.

### 4.5 Implementation patterns

- **All animations use `DSMotion` tokens** — no raw `Duration(milliseconds: ...)` in animation code.
- **All animation curves use `DSMotion.standard / .emphasized / .bounce / .linear`** — no raw `Curves.*` in animation code (lint rule).
- **Celebrations are RAII-safe** — each T3 microinteraction registers itself with a session-wide `MicrointeractionDispatcher` that limits concurrent T3 effects to 3 (oldest fades early if a 4th fires). Prevents particle storms during multi-event ticks.

```dart
// lib/widgets/microinteractions/microinteraction_dispatcher.dart
class MicrointeractionDispatcher extends ChangeNotifier {
  final List<_ActiveEffect> _active = [];
  static const int _maxConcurrent = 3;

  void play(_EffectType type, OverlayEntry entry) {
    _active.add(_ActiveEffect(type, entry));
    if (_active.length > _maxConcurrent) {
      final oldest = _active.removeAt(0);
      oldest.entry.remove();
    }
    notifyListeners();
  }
}
```

### 4.6 Performance

- 60fps target on mid-tier hardware (Android 9+ / iPhone X+).
- T3 effects use `AnimatedBuilder` + `Transform` (compositor-level, no rebuild).
- Particle counts capped: `particle_explosion` ≤ 20 particles, `coin_animation` ≤ 8 coins.
- `MicrointeractionDispatcher` cap of 3 concurrent T3 effects keeps peak compositor load bounded.

### 4.7 Touch summary for §4

| File | Change |
|---|---|
| `lib/widgets/game/_animated_pressable.dart` (new) | The wrapper; consumed by every interactive primitive |
| [lib/widgets/bounce_tap.dart](../../lib/widgets/bounce_tap.dart) | Mark `@Deprecated('Use _AnimatedPressable inside Game* primitives')`; delete after migration |
| `lib/widgets/microinteractions/phase_banner_overlay.dart` (new) | Phase transition banner |
| `lib/widgets/microinteractions/repair_shimmer.dart` (new) | Repair completion shimmer |
| `lib/widgets/microinteractions/reputation_tier_up_effect.dart` (new) | Rep tier-up effect |
| `lib/widgets/microinteractions/microinteraction_dispatcher.dart` (new) | Concurrency cap for T3 effects |
| [lib/engine/game_engine.dart](../../lib/engine/game_engine.dart) | Add `lastRepairedSlotId`, `lastRepTierUp` one-frame signal fields + clear on next frame |

---

## 5. High-Traffic Surface Migration

This section ships **token + primitive adoption** in the three highest-touch player surfaces. No layout redesign (lives in Spec 7b); visual hierarchy stays where it is — only the building blocks change.

### 5.1 Dashboard ([dashboard_view.dart](../../lib/views/dashboard_view.dart))

**Current state:** header row (avatar emoji + name + level + title), HP bar, energy bar, log console, active action card, station chip, weather chip. ~340 lines mixing raw `Container`/`BoxDecoration`/`Text` with `GameTheme.*`.

**Migration touch list:**

| Section | Before | After |
|---|---|---|
| Header row | Raw `Row` + `CircleAvatar` + `Text(stats.name, style: GameTheme.…)` | `GameCard` (elevation: 1) + `GameAvatar(emoji: '🧙', ringColor: DSColors.skill(highestSkill))` + `Text(stats.name, style: DSText.titleMedium)` |
| Title line | `Text(stats.title, …)` raw | `Text(stats.title, style: DSText.labelMedium.copyWith(color: DSColors.goldAccent))` |
| Player level line (added per 6b §4.5) | (new — was always intended for 6b) | `Row([Text("Lvl ${playerLevel}", style: DSText.numeric), SizedBox(width: DSSpace.xs), GameProgressBar(value: xpProgress, color: DSColors.xpBar, height: 4, trailingLabel: "$playerXp/$xpToNext")])` |
| HP bar | `CustomProgressBar` | `GameProgressBar(value: hpRatio, color: DSColors.healthBar, leadingLabel: "❤", trailingLabel: "$current/$max", animated: true)` |
| Energy bar | `CustomProgressBar` | `GameProgressBar(value: energyRatio, color: DSColors.energyBar, leadingLabel: "⚡", trailingLabel: "$current/$max", animated: true)` |
| Active action card | Raw `Container` with `BoxDecoration(color: GameTheme.cardBg, …)` | `GameCard(elevation: 2, accentColor: DSColors.skill(action.skill), child: …)` |
| Station chip | Raw `Container` pill | `GameChip(label: stationName, icon: stationIcon, color: DSColors.skill(stationSkill), size: small)` |
| Weather chip | [pulsing_weather_chip.dart](../../lib/widgets/pulsing_weather_chip.dart) | Internals wrap `GameChip` |
| Travel CTA | Raw `ElevatedButton` | `GameButton(label: 'Travel', leadingIcon: Icons.directions_walk, variant: primary, size: medium)` |
| Reset CTA | Raw `TextButton` | `GameButton(label: 'Reset', variant: ghost, size: small)` |
| Log console | [activity_log_console.dart](../../lib/widgets/activity_log_console.dart) | Internals → `DSText.bodySmall` + `GameCard(elevation: 0)` background |

**Deletions:** [custom_progress_bar.dart](../../lib/widgets/custom_progress_bar.dart) gets `@Deprecated('Use GameProgressBar')`; deletes when zero references remain.

### 5.2 Inventory ([inventory_view.dart](../../lib/views/inventory_view.dart))

**Current state:** grid of item slots with quantity badges + tap-to-modal for details + equipment slots row. ~580 lines.

**Migration touch list:**

| Section | Before | After |
|---|---|---|
| Equipment slots row | Raw `Row` of `Container` cells | `Row` of `GameCard(elevation: 2, padding: dense, accentColor: DSColors.skill(slot.skill), onTap: …, child: GameAvatar(emoji: item.icon, size: 48))` |
| Inventory grid cells | Raw `GridView` cell with `Container` + nested `Text`/badges | `GameCard(elevation: 1, padding: dense, accentColor: item != null ? DSColors.quality(item.quality) : null, onTap: () => _showItemModal(item), child: …)` |
| Item count badge | Raw `Container` pill | `GameChip(label: '$count', size: small, color: DSColors.textMuted)` |
| Quality border | Raw `Border.all(color: GameTheme.getQualityColor(quality))` | Routed via `GameCard.accentColor` |
| Item detail modal ([item_dashboard_modal.dart](../../lib/widgets/item_dashboard_modal.dart)) | Existing widget | Internals → `GameSheet` chrome + `DSText.*` body + `GameButton.primary` for "Equip"/"Consume" |
| Sell button (when 6a ships) | (planned) | `GameButton(label: 'Sell for $price', variant: secondary, leadingIcon: Icons.attach_money)` |
| Durability bar (6a) | (planned) | `GameProgressBar(value: durRatio, color: durRatio < 0.25 ? DSColors.warning : DSColors.success, height: 4, animated: true)` |
| "Worn" badge (6a) | (planned) | `GameChip(label: 'Worn', size: small, color: DSColors.warning, outlined: true)` |
| Reagent notice card | [reagent_notice_card.dart](../../lib/widgets/reagent_notice_card.dart) | Pulsing wrapper unchanged; internals → `GameCard(elevation: 3, accentColor: DSColors.warning)` + `DSText.titleSmall` + `GameButton.primary` |

### 5.3 Codex tabs ([codex_view.dart](../../lib/views/codex_view.dart))

**Current state:** `DefaultTabController` with 4–6 tabs (Quests, Beasts, Regions, Fragments, Achievements when earned). Each tab is a `ListView` of raw `Card`-flavored containers. ~700 lines.

**Migration touch list:**

| Section | Before | After |
|---|---|---|
| Tab bar | Raw `TabBar` | `GameTabs(tabs: …, activeIndex: _selectedTab, onTabChanged: …, scrollable: tabs.length > 3)` |
| Quest list cell | Raw `Container` | `GameListItem(leading: GameAvatar(emoji: quest.icon, ringColor: DSColors.questActive), title: quest.title, subtitle: quest.descriptionShort, trailing: GameChip.questStatus(quest.status), onTap: …)` |
| Quest objectives sub-list | Raw `Column` of `Text` | `Column` of `GameListItem(leading: Icon(obj.completed ? Icons.check_circle : Icons.radio_button_unchecked, color: …), title: obj.descriptionPublic, dimmed: obj.comingSoon)` |
| Beast list cell | Raw `Card` + `Row` | `GameListItem(leading: GameAvatar(emoji: beast.icon), title: beast.name, subtitle: beast.subtitlePublic, trailing: GameChip(label: 'Defeated: $count', size: small), onTap: …)` |
| Beast detail page | Raw `Column` | `GameCard(elevation: 2, child: …)` with `DSText.titleLarge` name, `DSText.bodyMedium` description, weakness-hint line (Spec 6b §5.4) using `GameChip(label: 'Weak to: $hint', color: DSColors.warning, outlined: true)` |
| Fragment list cell | Raw `Container` | `GameListItem(leading: GameAvatar(emoji: '📜', ringColor: DSColors.tag(fragment.tag)), title: fragment.title, trailing: GameChip.tag(fragment.tag), onTap: …)` |
| Fragment reading overlay ([reading_overlay.dart](../../lib/widgets/reading_overlay.dart)) | Existing widget | Internals → `GameSheet` chrome + `DSText.bodyLarge` for fragment text + `GameButton.ghost('Close')` |
| Codex puzzle view ([codex_puzzle_view.dart](../../lib/views/codex_puzzle_view.dart)) | Raw layout | `GameCard` wrappers + `GameButton.primary` for answer-commit CTA. Puzzle option chips → `GameChip(onTap: …)` |

### 5.4 What stays unchanged in this spec

- [build_view.dart](../../lib/views/build_view.dart) — Build screen. Touched by 6a's repair UI in-progress; deferred to 7b.
- [skills_view.dart](../../lib/views/skills_view.dart) — Skills screen. Deferred to 7b.
- [tavern_view.dart](../../lib/views/tavern_view.dart) — Tavern screen (6a). Deferred to 7b.
- All `narrative_event_modal`, `you_win_modal`, `world_event_widgets`, `combat_action_bar`, `quick_slot_bar` — internals migrate only if they live inside the 3 high-traffic surfaces.

### 5.5 Migration validation

A "tokens-only" guard test catches future regressions:

```dart
// test/widgets/tokens_only_test.dart
test('migrated views import no raw color literals or GameTheme.* getters', () {
  for (final path in [
    'lib/views/dashboard_view.dart',
    'lib/views/inventory_view.dart',
    'lib/views/codex_view.dart',
  ]) {
    final src = File(path).readAsStringSync();
    expect(src, isNot(contains(RegExp(r'Color\(0x[0-9a-fA-F]{8}\)'))),
        reason: '$path uses a raw color literal');
    expect(src, isNot(contains('GameTheme.cardBg')),
        reason: '$path uses GameTheme.cardBg instead of DSColors.surface2');
    // ... etc for the 4-5 GameTheme.* keys most likely to leak
  }
});
```

### 5.6 Touch summary for §5

| File | Change |
|---|---|
| [lib/views/dashboard_view.dart](../../lib/views/dashboard_view.dart) | Migrate all UI surface to tokens + primitives; add player XP bar; remove `CustomProgressBar` usage |
| [lib/views/inventory_view.dart](../../lib/views/inventory_view.dart) | Migrate grid + slots + modal trigger to tokens + primitives |
| [lib/views/codex_view.dart](../../lib/views/codex_view.dart) | Migrate all tabs + reading overlay launch + puzzle view launch to tokens + primitives |
| [lib/widgets/item_dashboard_modal.dart](../../lib/widgets/item_dashboard_modal.dart) | Internals → `GameSheet` |
| [lib/widgets/reading_overlay.dart](../../lib/widgets/reading_overlay.dart) | Internals → `GameSheet` |
| [lib/widgets/activity_log_console.dart](../../lib/widgets/activity_log_console.dart) | Internals → tokens |
| [lib/widgets/custom_progress_bar.dart](../../lib/widgets/custom_progress_bar.dart) | `@Deprecated`; delete when refcount = 0 |
| `test/widgets/dashboard_tokens_test.dart` (new) | Token-only render guard |
| `test/widgets/inventory_tokens_test.dart` (new) | Same |
| `test/widgets/codex_tokens_test.dart` (new) | Same |
| `test/widgets/tokens_only_test.dart` (new) | Source-grep guard |

---

## 6. Testing, Implementation Order, Migration & Rollout

### 6.1 Test strategy

**`test/design_tokens_test.dart` (new)**
- Every `DSColors` ramp helper returns non-null for every input
- `DSColors.skill(SkillType.combat)` returns the new red base (not muted fallback)
- `DSColors.tag(CodexTag t)` covers all 6 enum values
- `DSColors.merchantTier(MerchantTier t)` covers all 5 enum values (depends on 6a's `MerchantTier` enum)
- `DSText.numeric` has `FontFeature.tabularFigures()` set
- `DSSpace`, `DSRadius`, `DSShadow`, `DSMotion` constants are non-negative / non-empty

**`test/widgets/game/<primitive>_test.dart` (15 new files)**
- One focused widget test file per primitive
- Standard assertions: renders, respects `enabled: false`, fires `onPressed`/`onChanged`, applies token defaults, applies overrides
- Golden snapshot per primitive at default state — locked PNG in `test/widgets/game/golden/`
- Golden snapshot per variant

**`test/widgets/microinteractions/*.dart` (new)**
- `_animated_pressable_test.dart` — scale animates on press, no animation when `enabled: false`, fires `onPressed` only on press-up
- `phase_banner_overlay_test.dart` — renders narration on phase change, auto-dismisses after 1.8s, uses phase color
- `repair_shimmer_test.dart` — triggers on `lastRepairedSlotId` change, plays once, completes after `DSMotion.slow`
- `reputation_tier_up_effect_test.dart` — triggers on `lastRepTierUp` change, chip scales 1.0→1.4→1.0, color shifts to next tier
- `microinteraction_dispatcher_test.dart` — caps concurrent T3 effects at 3, oldest evicted on overflow

**`test/widgets/dashboard_tokens_test.dart` / `inventory_tokens_test.dart` / `codex_tokens_test.dart` (3 new)**
- Walk widget tree of each migrated view
- Assert specific primitives present
- Assert no raw `Container(decoration: BoxDecoration(color: …))` survivors

**`test/widgets/tokens_only_test.dart` (new — source-grep guard)**
- Read source of each migrated file as string
- Fail if `Color(0x…)` regex matches anywhere in the file
- Fail if `GameTheme.cardBg` / `GameTheme.background` / `GameTheme.border` literal references appear

**Existing test suite** — all current widget tests stay green; failures indicate a regression in migration, not a token-spec issue.

### 6.2 Implementation order

Two PRs are reasonable here given the size — Part A is foundation, Part B is migration. Each part compiles + tests green at the end.

**PR 1 — Foundation (tokens + primitives + motion):**

1. **`design_tokens.dart`** — All 6 modules with full catalogs. `test/design_tokens_test.dart` validates.
2. **`game_theme.dart` bridge** — Rewrite bodies as thin re-exports of `DSColors.*`. Existing callers stay green.
3. **`_animated_pressable.dart`** — The wrapper. Mark [bounce_tap.dart](../../lib/widgets/bounce_tap.dart) as `@Deprecated`.
4. **Primitives in ship-priority order:**
   - 4a. `GameCard`, `GameChip`, `GameProgressBar` + tests + goldens
   - 4b. `GameButton`, `GameIconButton`, `GameTabs` + tests + goldens
   - 4c. `GameListItem`, `GameAvatar` + tests + goldens
   - 4d. `GameSheet`, `GameToast` + tests + goldens
   - 4e. `GameTooltip`, `GameInput` + tests + goldens
   - 4f. `GameSwitch`, `GameSlider`, `GameSkeleton` + tests + goldens
5. **Lint rule** — add `analysis_options.yaml` entry banning `Color(0x…)` literals in `lib/widgets/game/`.
6. **3 new microinteractions** — `phase_banner_overlay.dart`, `repair_shimmer.dart`, `reputation_tier_up_effect.dart` + tests.
7. **`MicrointeractionDispatcher`** + concurrency-cap test.
8. **Engine signal fields** — add `lastRepairedSlotId`, `lastRepTierUp` to [game_engine.dart](../../lib/engine/game_engine.dart); wire to repair handlers (6a sites) and merchant tier-up handler (6a). `_clearTransientSignals()` call at end-of-frame resets them.

After PR 1: foundation exists; nothing using it yet; all existing tests green.

**PR 2 — Migration (3 high-traffic surfaces):**

9. **Dashboard migration** — header → `GameCard` + `GameAvatar`; HP/energy/XP bars → `GameProgressBar`; active action → `GameCard`; chips → `GameChip`; CTAs → `GameButton`. `dashboard_tokens_test.dart` enforces.
10. **Inventory migration** — grid + equipment slots → `GameCard`; modal → `GameSheet`; durability bar → `GameProgressBar`; chips → `GameChip`. `inventory_tokens_test.dart` enforces.
11. **Codex migration** — tab bar → `GameTabs`; list cells → `GameListItem`; reading overlay → `GameSheet`. `codex_tokens_test.dart` enforces.
12. **Bridge widget cleanup** — internals of `item_dashboard_modal`, `reading_overlay`, `activity_log_console` migrate to tokens + primitives.
13. **CustomProgressBar deprecation** — `@Deprecated` annotation; delete when last reference falls.
14. **Source-grep guard** — `tokens_only_test.dart` runs against the 3 migrated files.

After PR 2: dashboard, inventory, codex render exclusively from tokens + primitives.

### 6.3 Migration risk control

- **PR 1 ships in isolation** — adds new files + a bridge in `game_theme.dart`. No existing screen changes. Lowest-risk merge.
- **PR 2 ships per-screen sequentially** — Dashboard first, then Inventory, then Codex. Each is its own commit. If any screen breaks visually in playtest, revert one commit, not the whole PR.
- **Goldens lock the visual contract** — golden snapshots for each primitive guard against accidental token tweaks bleeding into UI regressions.
- **Token bridge stays for downstream specs** — Spec 7b (screen redesigns) will progressively eliminate `GameTheme.*` calls in remaining views. Bridge file becomes thinner over time; deletes when refcount = 0.

### 6.4 Documentation updates

- README.md — append "Spec 7a (revised) — Design System" notes; link to token files; brief usage example for adding a new screen
- Inline `///` doc comments on every public primitive with a 1-line usage example
- `lib/widgets/game/README.md` (new) — primitive index with a screenshot of each (from goldens) and the "use when…" line per primitive

### 6.5 Risks & deferrals

- **Three-font addition (Cinzel + Eczar + JetBrains Mono).** Adds ~600KB to app size. `google_fonts` lazy-loads but first-launch will fetch. Acceptable for offline-first because the package caches after first fetch.
- **Tab indicator slide motion change** — current `TabBar` may visually differ from `GameTabs` on the indicator transition. Golden snapshots will catch the diff; playtest the codex to confirm the new motion feels right.
- **`_AnimatedPressable` scale-down is subtle** — 0.94 lower bound may not be perceptible. Tunable single constant.
- **3-effect concurrency cap may evict celebrations a player wanted to see.** Mitigated by the fact that real game moments don't fire 4+ T3 effects per second; this is a defense-in-depth cap.
- **Source-grep test is brittle to source formatting.** A multi-line `Color(...)` literal would slip through. Acceptable trade — the bigger threat is open-coded color strings, which the regex catches.
- **Deferred to Spec 7b:** Build / Skills / Tavern view migrations, all modal/overlay redesigns, narrative event modal redesign, combat HUD redesign.
- **Deferred to Spec 7c (sound):** AudioEngine, 13 SFX catalog, audioplayers package, settings screen with volume slider.
- **Deferred indefinitely (not 7b/7c):** Per-platform haptic feedback (`Haptics.lightImpact()` on `_AnimatedPressable` press) — defer until iOS playtest signals a need.

### 6.6 Player walkthrough after both PRs ship

A returning player launches the app:

1. Splash dismisses to dashboard. Dashboard looks **cleaner** — better text hierarchy, more breathing room (8pt grid), tabular numeric figures don't jump as HP/XP changes.
2. Header now shows the player XP bar under the name line (6b acceptance — wired here for the first time as part of dashboard migration).
3. Combat skill chip on the dashboard (when in combat zone) now has a defined red color (was muted grey).
4. Tap the inventory tab. Items render in `GameCard` cells with their quality color as the left-accent border. Tapping an item opens a `GameSheet` modal instead of the old custom modal — same content, standardized chrome.
5. Tap the codex. Tab bar slides with the new `DSMotion.medium` indicator transition. Quest list rows are `GameListItem` with consistent leading-icon + title + status-chip layout.
6. Tap a fragment to read. `GameSheet` opens with the fragment text in `DSText.bodyLarge` (Eczar serif) — more comfortable to read than current.
7. Win a combat → `floating_notification` for the kill, `particle_explosion` for a crit, `coin_animation` if gold drops. Capped at 3 concurrent so multi-event ticks never become particle storms.
8. Trigger an Echo phase transition → new `phase_banner_overlay` slides down from top with the phase narration in the phase's theme color.

Nothing about the player's flow changes. Everything looks like the same game, but built right.

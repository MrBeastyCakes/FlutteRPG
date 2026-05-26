# Spec 6b — Achievements, Titles & Player XP Rebalance

**Date:** 2026-05-26
**Status:** Approved (pending spec review)
**Parent:** [Echoes from the Deep umbrella vision](2026-05-24-echoes-from-the-deep-vision.md)
**Companion specs:** [6a Living Economy](2026-05-25-spec-6a-living-economy-design.md) (parallel implementation), 6c Nexus Finale (separate brainstorm)
**Depends on:** Specs 1–5 (all assumed implemented). Spec 7a primitives (`FloatingNotification`, `GameCard`, `GameChip`, `GameProgressBar`) used throughout.
**Scope:** Second of three mini-specs decomposed from the umbrella's Spec 6. Ships three coupled systems: Achievements registry (40 entries), auto-derived Title system (24 titles), and a real Player XP track (replaces the dashboard's sum-of-skills calc, drips at 1/5 rate). Achievements include the Bestiary "weak to" knowledge-propagation surface.

---

## 1. Goals & Acceptance Criteria

### 1.1 What 6b ships

1. **Achievements (40 total)** — central observer-style engine that subscribes to existing event hooks (combat-win, craft-complete, fragment-collected, quest-complete, merchant-tier-up, etc.) and grants matching achievements. Six visible categories of 6 each (First Steps, Mastery, Combat, Crafting, Lore, Economy) plus Hidden category of 4. A subset (5 Combat entries) are wired to **Bestiary "weak to" hint reveals** — when the achievement unlocks, the matching beast's weakness line appears on its Bestiary card.

2. **Titles (24 total, 8 skills × 3 tiers)** — `PlayerStats.title` becomes a derived value, recomputed whenever a skill levels up or the player levels up. Title = the title for the player's currently-highest-level skill at the appropriate tier (1–9 / 10–19 / 20+). No picker UI — the title shifts on the dashboard when ranks shift. Ties broken by `SkillType` enum order.

3. **Player XP system (real track)** — new fields `playerLevel`, `playerXp` on `PlayerStats`. Player XP = 20% of any skill XP requested (5× slower than the implicit current sum-of-skills rate). Curve: linear, `xpToNext = 100 × playerLevel`. Player level-up fires an event the achievement observer + title recompute listen to. No level cap.

### 1.2 What 6b does NOT do

- Title picker UI (auto-derived only — 6c or later may add manual pinning)
- Achievement progress bars for incomplete achievements (binary unlock state only)
- Nexus zone / The Source final boss (Spec 6c)
- Credits / Free Mode / NG+ (Spec 6c)
- Music / ambient audio
- Save persistence

### 1.3 Acceptance criteria

A player after 6b ships:

1. Earned achievements appear in Codex → Achievements tab, grouped by category. Visible-category locked entries show as `❔ ???` with a vague criteria hint (no precise counts). Hidden category never shows locked entries.
2. First time a Bestiary-tied achievement unlocks, the matching beast's "Weak to X" line appears on its Bestiary card (was hidden before).
3. Dashboard title shifts from "Wayfarer" to the appropriate skill+tier title once the player's highest skill changes (e.g., "Apprentice" if Crafting overtakes Wayfinding).
4. Player XP bar visible on dashboard under the name line with `current / next-level` numbers; advances at 1/5 the rate of skill XP.
5. Floating notification on achievement unlock (reuses 7a `FloatingNotification`); same notification fires for Hidden achievements.
6. Reset clears all earned achievements, player XP, counters, and re-derives title to "Wayfarer".

### 1.4 Design principles inherited

- **No art** — single-emoji icons; UI built from Spec 7a primitives.
- **No dual-emoji icons** — every achievement and title use single glyphs only; distinguished by category color tint and name.
- **Progressive discovery** — Hidden category never lists locked entries; visible-category locked entries show `❔ ???` + vague hint (no precise "X of Y" counters). Codex Achievements tab itself stays hidden until first unlock fires.
- **Systems converse** — achievement engine consumes existing engine event sites; title resolver reads existing skill map; player XP drips from existing `_grantSkillXp` call sites.

---

## 2. Achievement Model & Registry

### 2.1 Data model

`Achievement` already exists as a stub in [codex.dart:473](../../lib/models/codex.dart#L473). Extend:

```dart
enum AchievementCategory { firstSteps, mastery, combat, crafting, lore, economy, hidden }

enum AchievementTrigger {
  questComplete,        // criteria: questId
  beastDefeated,        // criteria: beastId, count
  fragmentCollected,    // criteria: tag (CodexTag), count
  craftComplete,        // criteria: quality / itemType / count
  recipeUnlocked,       // criteria: count
  zoneEntered,          // criteria: zoneId
  zoneCleansed,         // criteria: tag (wilds/stone/tide/all)
  merchantTier,         // criteria: merchantId / tier
  playerLevel,          // criteria: level
  skillLevel,           // criteria: skill / level (any-skill if skill omitted)
  goldEarned,           // criteria: cumulative
  totalLevel,           // criteria: sum-of-skill-levels threshold
  custom,               // criteria: opaque 'key' — for special-case grants
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;                       // single emoji
  final AchievementCategory category;
  final bool hidden;
  final AchievementTrigger trigger;
  final Map<String, dynamic> criteria;
  final String? bestiaryHintBeastId;       // if set, unlock fires Bestiary 'weak to' reveal

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.trigger,
    required this.criteria,
    this.hidden = false,
    this.bestiaryHintBeastId,
  });
}
```

The existing `titleUnlock` field on `Achievement` is **removed** in 6b — titles are decoupled from achievements (auto-derived from highest skill, see Section 3).

### 2.2 The 40 achievements

#### First Steps (6) — early-game one-shots, visible

| id | name | icon | trigger | criteria |
|---|---|---|---|---|
| `first_gather` | First Harvest | 🌱 | custom | key: `first_gather` |
| `first_kill` | Drew First Blood | 🗡️ | beastDefeated | any, count: 1 |
| `first_craft` | Forged in Earnest | 🔨 | craftComplete | count: 1 |
| `first_fragment` | Loose Page | 📜 | fragmentCollected | tag: any, count: 1 |
| `first_quest_done` | A Task Completed | ✅ | questComplete | any, count: 1 |
| `reach_town_square` | Found Home | 🏘️ | zoneEntered | zoneId: `town_square` |

#### Mastery (6) — skill milestones, visible

| id | name | icon | trigger | criteria |
|---|---|---|---|---|
| `skill_first_10` | First Cap | 🎯 | skillLevel | any, level: 10 |
| `skill_first_20` | Cap Broken | 🔓 | skillLevel | any, level: 20 |
| `skill_first_masterwork` | Masterpiece | 🏅 | custom | key: `first_masterwork` |
| `all_skills_5` | Well-Rounded | ⚖️ | custom | key: `all_skills_5` |
| `all_skills_10` | Polymath | 🧠 | custom | key: `all_skills_10` |
| `total_skill_50` | Half-Centurion | 💯 | totalLevel | sum: 50 |

#### Combat (6) — five Bestiary-hint triggers + one capstone, visible

| id | name | icon | trigger | criteria | bestiaryHintBeastId |
|---|---|---|---|---|---|
| `boar_hunter` | Tusker | 🐗 | beastDefeated | `forest_boar`, count: 5 | `forest_boar` |
| `spider_lore` | Web-Walker | 🕷️ | beastDefeated | `cave_spider`, count: 5 | `cave_spider` |
| `wolf_pack` | Lone Hunter | 🐺 | beastDefeated | `shadow_wolf`, count: 5 | `shadow_wolf` |
| `troll_breaker` | Stone-Cracker | 👹 | beastDefeated | `cavern_troll`, count: 3 | `cavern_troll` |
| `tide_culler` | Tide-Culler | 🦀 | beastDefeated | `shore_crab`, count: 8 | `shore_crab` |
| `echo_slayer` | Echoeshaper | 👁️ | custom | key: `defeat_all_echoes` | — |

#### Crafting (6), visible

| id | name | icon | trigger | criteria |
|---|---|---|---|---|
| `crafter_10` | Bench Veteran | 🛠️ | craftComplete | count: 10 |
| `crafter_50` | Bench Master | ⚙️ | craftComplete | count: 50 |
| `masterwork_3` | Hands of the Source | ✨ | craftComplete | quality: masterwork, count: 3 |
| `recipe_10` | Recipe Hoarder | 📘 | recipeUnlocked | count: 10 |
| `brewer_first` | Brewer | 🍷 | craftComplete | itemType: brew, count: 1 |
| `repair_first` | Mender | 🪛 | custom | key: `first_repair` |

#### Lore (6), visible

| id | name | icon | trigger | criteria |
|---|---|---|---|---|
| `fragments_wilds` | Wilds-Bound | 🌳 | fragmentCollected | tag: `wilds`, count: 5 |
| `fragments_stone` | Stone-Bound | ⛰️ | fragmentCollected | tag: `stone`, count: 5 |
| `fragments_tide` | Tide-Bound | 🌊 | fragmentCollected | tag: `tide`, count: 5 |
| `fragments_source` | Source-Bound | 🔱 | fragmentCollected | tag: `source`, count: 3 |
| `cleanse_first` | First Breach Sealed | 🕯️ | zoneCleansed | tag: any |
| `cleanse_all` | Three Wounds Closed | 🪬 | zoneCleansed | tag: `all` |

#### Economy (6), visible — depends on Spec 6a

| id | name | icon | trigger | criteria |
|---|---|---|---|---|
| `first_trade` | A Fair Bargain | 🪙 | custom | key: `first_trade` |
| `gold_500` | Coinwise | 💰 | goldEarned | cumulative: 500 |
| `gold_5000` | Coffer-Heavy | 💎 | goldEarned | cumulative: 5000 |
| `trusted_first` | A Familiar Face | 🤝 | merchantTier | any, tier: `trustedPatron` |
| `sworn_first` | Sworn Companion | 💞 | merchantTier | any, tier: `swornCompanion` |
| `sworn_all` | Six True Friends | 🫂 | custom | key: `sworn_all_six` |

#### Hidden (4) — never appear locked

| id | name | icon | trigger | criteria |
|---|---|---|---|---|
| `barehanded_kill` | Bare-Knuckle | ✊ | custom | key: `barehanded_kill` |
| `no_repair_run` | Tireless | ♾️ | custom | key: `no_repair_total_30` |
| `feast_brewer` | Twilight Drinker | 🥂 | custom | key: `consume_elixir_of_twilight` |
| `obelisk_secrets` | Stone-Listener | 🗿 | custom | key: `obelisk_double_drop` |

**Total: 6+6+6+6+6+6+4 = 40.**

### 2.3 Bestiary hint mechanic

Five Combat achievements have `bestiaryHintBeastId`. When the achievement unlocks, the achievement engine adds the beastId to `_revealedBeastHints`. The Bestiary card on the Codex Beasts tab reads that set and conditionally renders the "Weak to: …" line.

If `Beast` doesn't currently expose a weakness label, 6b adds an optional `String? weaknessHint` field, populated for exactly the 5 hinted beasts:

| beastId | weaknessHint |
|---|---|
| `forest_boar` | Heavy Strike during charge windows |
| `cave_spider` | Strike between web-bursts |
| `shadow_wolf` | Defend on howl, then Strike |
| `cavern_troll` | Heavy Strike — armor breaks under force |
| `shore_crab` | Strike sides — armored front |

Other beasts (Greater Goblin, Tide Lobster, Drowned, Echoes) stay weakness-less in 6b.

---

## 3. Title Derivation System

### 3.1 Title table (24 titles)

| Skill | Tier 1 (1–9) | Tier 2 (10–19) | Tier 3 (20+) |
|---|---|---|---|
| Woodcutting | Sapling | Woodcutter | Heartwood-Reaver |
| Mining | Prospector | Pickbearer | Vein-Master |
| Herbalism | Sprig | Herbalist | Greenwarden |
| Wayfinding | Wayfarer | Pathfinder | Cartographer |
| Lore | Reader | Scholar | Lorekeeper |
| Cooking | Hearth-Hand | Cook | Brewmaster |
| Crafting | Apprentice | Crafter | Artisan |
| Combat | Brawler | Warrior | Blademaster |

"Wayfarer" matches the existing default — a fresh-start player whose only nonzero progress is Wayfinding 1 lands on it naturally.

### 3.2 Resolver

```dart
// lib/models/title.dart (new)
class TitleResolver {
  static const Map<SkillType, List<String>> _titles = {
    SkillType.woodcutting: ['Sapling',     'Woodcutter',  'Heartwood-Reaver'],
    SkillType.mining:      ['Prospector',  'Pickbearer',  'Vein-Master'],
    SkillType.herbalism:   ['Sprig',       'Herbalist',   'Greenwarden'],
    SkillType.wayfinding:  ['Wayfarer',    'Pathfinder',  'Cartographer'],
    SkillType.lore:        ['Reader',      'Scholar',     'Lorekeeper'],
    SkillType.cooking:     ['Hearth-Hand', 'Cook',        'Brewmaster'],
    SkillType.crafting:    ['Apprentice',  'Crafter',     'Artisan'],
    SkillType.combat:      ['Brawler',     'Warrior',     'Blademaster'],
  };

  /// Returns the active title for the given skill map.
  /// Ties broken by SkillType enum order (deterministic).
  static String resolve(Map<SkillType, SkillState> skills) {
    SkillType bestSkill = SkillType.wayfinding;  // fallback for all-zero state
    int bestLevel = 0;
    for (final type in SkillType.values) {        // iteration = enum order
      final lvl = skills[type]?.level ?? 0;
      if (lvl > bestLevel) {
        bestLevel = lvl;
        bestSkill = type;
      }
    }
    final tierIndex = bestLevel >= 20 ? 2 : (bestLevel >= 10 ? 1 : 0);
    return _titles[bestSkill]![tierIndex];
  }
}
```

### 3.3 Engine integration

`PlayerStats.title` stays a stored field (mutable via `copyWith`); the engine recomputes and writes it on every event that could change the highest-skill / tier:

```dart
void _recomputeTitle() {
  final newTitle = TitleResolver.resolve(_skills);
  if (_playerStats.title != newTitle) {
    _playerStats = _playerStats.copyWith(title: newTitle);
    notifyListeners();
  }
}
```

Called from:
- End of `_grantSkillXp` (covers all skill-XP-bearing events)
- End of `_onPlayerLevelUp` (explicit "refreshes on player level up" requirement)
- `resetGame` (re-derive to "Wayfarer")

### 3.4 UI

Dashboard already reads `stats.title` ([dashboard_view.dart:149](../../lib/views/dashboard_view.dart#L149)) — no view change needed. The title string updates reactively when `notifyListeners()` fires.

---

## 4. Player XP System

### 4.1 Data model

```dart
// lib/models/player_stats.dart — add 2 fields
final int playerLevel;
final int playerXp;          // XP within current level (0 .. xpToNext)

// initial():
playerLevel: 1,
playerXp: 0,

// copyWith() extended for both
```

### 4.2 XP curve

```dart
// lib/models/player_progression.dart (new)
class PlayerProgression {
  static int xpToNextLevel(int currentLevel) => 100 * currentLevel;

  /// Apply XP gain; returns (newLevel, newXp, didLevelUp).
  static ({int level, int xp, bool didLevelUp}) applyXp(int level, int xp, int xpGain) {
    int newLevel = level;
    int newXp = xp + xpGain;
    bool leveledUp = false;
    while (newXp >= xpToNextLevel(newLevel)) {
      newXp -= xpToNextLevel(newLevel);
      newLevel += 1;
      leveledUp = true;
    }
    return (level: newLevel, xp: newXp, didLevelUp: leveledUp);
  }
}
```

No level cap. Costs grow linearly; the curve self-paces.

### 4.3 XP source: 20% of every skill XP request

In `GameEngine._grantSkillXp`:

```dart
void _grantSkillXp(SkillType skill, int amount) {
  // Existing skill XP application
  _skills[skill] = _skills[skill]!.applyXp(amount);

  // NEW: 20% feeds player XP (rounded down; 0-gain calls grant 0)
  final playerGain = amount ~/ 5;
  if (playerGain > 0) {
    final result = PlayerProgression.applyXp(
      _playerStats.playerLevel,
      _playerStats.playerXp,
      playerGain,
    );
    _playerStats = _playerStats.copyWith(
      playerLevel: result.level,
      playerXp: result.xp,
    );
    if (result.didLevelUp) {
      _onPlayerLevelUp();
    }
  }

  _recomputeTitle();
  notifyListeners();
}
```

**Pre-cap, not post-cap:** the 20% is computed from the *requested* skill XP, not from what actually applied after cap clamping. A capped skill still feeds player XP — players who've hit a cap can keep accumulating player XP while they wait to unlock the next Masterwork tier. This avoids a soft trap.

### 4.4 Level-up handler

```dart
void _onPlayerLevelUp() {
  log("You've grown — Player Level ${_playerStats.playerLevel}!", LogType.success);
  playSfx('ui_level_up');
  _achievementEngine.onEvent(
    AchievementEvent.playerLevel(_playerStats.playerLevel),
  );
}
```

### 4.5 Dashboard change

[dashboard_view.dart:79](../../lib/views/dashboard_view.dart#L79) currently computes:

```dart
int totalLevel = engine.skills.values.fold(0, (sum, skill) => sum + skill.level);
```

Replace with:

```dart
final playerLevel = engine.playerStats.playerLevel;
final playerXp = engine.playerStats.playerXp;
final xpToNext = PlayerProgression.xpToNextLevel(playerLevel);
```

The "Lvl X Title" line becomes `Lvl $playerLevel ${stats.title}`. A small XP bar (`GameProgressBar` from 7a) shows `$playerXp / $xpToNext` directly under the name line. Muted-gold accent; 4px height; non-interactive.

### 4.6 Reset behavior

`resetGame` re-initializes `playerLevel: 1, playerXp: 0` via `PlayerStats.initial()`. Title resolver recomputes to "Wayfarer".

---

## 5. Achievement Engine & Wiring

### 5.1 AchievementEngine

```dart
// lib/engine/achievement_engine.dart (new)
class AchievementEvent {
  final AchievementTrigger trigger;
  final Map<String, dynamic> data;
  const AchievementEvent(this.trigger, this.data);

  factory AchievementEvent.beastDefeated(String beastId) =>
      AchievementEvent(AchievementTrigger.beastDefeated, {'beastId': beastId});
  factory AchievementEvent.craftComplete(Item item, QualityTier q) =>
      AchievementEvent(AchievementTrigger.craftComplete, {'itemId': item.id, 'itemType': item.type, 'quality': q});
  factory AchievementEvent.fragmentCollected(CodexTag tag) =>
      AchievementEvent(AchievementTrigger.fragmentCollected, {'tag': tag});
  factory AchievementEvent.questComplete(String questId) =>
      AchievementEvent(AchievementTrigger.questComplete, {'questId': questId});
  factory AchievementEvent.zoneEntered(String zoneId) =>
      AchievementEvent(AchievementTrigger.zoneEntered, {'zoneId': zoneId});
  factory AchievementEvent.zoneCleansed(String tag) =>
      AchievementEvent(AchievementTrigger.zoneCleansed, {'tag': tag});
  factory AchievementEvent.merchantTier(String merchantId, MerchantTier tier) =>
      AchievementEvent(AchievementTrigger.merchantTier, {'merchantId': merchantId, 'tier': tier});
  factory AchievementEvent.skillLevel(SkillType s, int level) =>
      AchievementEvent(AchievementTrigger.skillLevel, {'skill': s, 'level': level});
  factory AchievementEvent.playerLevel(int level) =>
      AchievementEvent(AchievementTrigger.playerLevel, {'level': level});
  factory AchievementEvent.goldEarned(int cumulative) =>
      AchievementEvent(AchievementTrigger.goldEarned, {'cumulative': cumulative});
  factory AchievementEvent.recipeUnlocked(int totalUnlocked) =>
      AchievementEvent(AchievementTrigger.recipeUnlocked, {'count': totalUnlocked});
  factory AchievementEvent.totalLevel(int sum) =>
      AchievementEvent(AchievementTrigger.totalLevel, {'sum': sum});
  factory AchievementEvent.custom(String key, [Map<String, dynamic>? extra]) =>
      AchievementEvent(AchievementTrigger.custom, {'key': key, ...?extra});
}

class AchievementEngine {
  final Set<String> _earned = {};
  final Map<String, int> _counters = {};
  final Set<String> _revealedBeastHints = {};
  final void Function(Achievement) _onUnlock;

  AchievementEngine({required void Function(Achievement) onUnlock}) : _onUnlock = onUnlock;

  Set<String> get earned => Set.unmodifiable(_earned);
  Set<String> get revealedBeastHints => Set.unmodifiable(_revealedBeastHints);

  void onEvent(AchievementEvent e) {
    final counterKey = _counterKeyFor(e);
    if (counterKey != null) {
      _counters[counterKey] = (_counters[counterKey] ?? 0) + 1;
    }

    for (final ach in Achievements.all) {
      if (_earned.contains(ach.id)) continue;
      if (ach.trigger != e.trigger) continue;
      if (_matches(ach, e)) _grant(ach);
    }
  }

  void _grant(Achievement ach) {
    _earned.add(ach.id);
    if (ach.bestiaryHintBeastId != null) {
      _revealedBeastHints.add(ach.bestiaryHintBeastId!);
    }
    _onUnlock(ach);
  }

  String? _counterKeyFor(AchievementEvent e) {
    switch (e.trigger) {
      case AchievementTrigger.beastDefeated:     return 'beast:${e.data['beastId']}';
      case AchievementTrigger.craftComplete:
        final q = e.data['quality'];
        // Maintain two counters: per-quality + any
        return 'craft:any';   // quality counter incremented in matcher when applicable
      case AchievementTrigger.fragmentCollected: return 'frag:${(e.data['tag'] as CodexTag).name}';
      case AchievementTrigger.questComplete:     return 'quest:any';
      default: return null;
    }
  }

  bool _matches(Achievement ach, AchievementEvent e) {
    final c = ach.criteria;
    switch (ach.trigger) {
      case AchievementTrigger.beastDefeated:
        final beastId = c['beastId'];
        final count = c['count'] ?? 1;
        if (beastId == 'any') return (_counters['beast:${e.data['beastId']}'] ?? 0) >= 1 && count == 1;
        if (e.data['beastId'] != beastId) return false;
        return (_counters['beast:$beastId'] ?? 0) >= count;
      case AchievementTrigger.craftComplete:
        final wantedQuality = c['quality'];
        final wantedType = c['itemType'];
        final count = c['count'] ?? 1;
        if (wantedQuality != null && e.data['quality'] != wantedQuality) return false;
        if (wantedType != null && e.data['itemType'] != wantedType) return false;
        if (wantedQuality != null) {
          final key = 'craft:q:${(wantedQuality as QualityTier).name}';
          _counters[key] = (_counters[key] ?? 0) + 1;
          return (_counters[key] ?? 0) >= count;
        }
        if (wantedType != null) {
          final key = 'craft:t:${(wantedType as ItemType).name}';
          _counters[key] = (_counters[key] ?? 0) + 1;
          return (_counters[key] ?? 0) >= count;
        }
        return (_counters['craft:any'] ?? 0) >= count;
      case AchievementTrigger.fragmentCollected:
        final wantedTag = c['tag'];
        final count = c['count'] ?? 1;
        if (wantedTag == 'any') {
          final total = _counters.entries
              .where((e) => e.key.startsWith('frag:'))
              .fold<int>(0, (s, e) => s + e.value);
          return total >= count;
        }
        if ((e.data['tag'] as CodexTag).name != wantedTag) return false;
        return (_counters['frag:$wantedTag'] ?? 0) >= count;
      case AchievementTrigger.questComplete:
        final qid = c['questId'];
        if (qid == null) return (_counters['quest:any'] ?? 0) >= (c['count'] ?? 1);
        return e.data['questId'] == qid;
      case AchievementTrigger.zoneEntered:
        return e.data['zoneId'] == c['zoneId'];
      case AchievementTrigger.zoneCleansed:
        final t = c['tag'];
        if (t == 'all') return e.data['tag'] == 'all';
        return t == 'any' || e.data['tag'] == t;
      case AchievementTrigger.merchantTier:
        final tier = c['tier'] as MerchantTier;
        return (e.data['tier'] as MerchantTier).index >= tier.index;
      case AchievementTrigger.skillLevel:
        return e.data['level'] >= c['level'];
      case AchievementTrigger.playerLevel:
        return e.data['level'] >= c['level'];
      case AchievementTrigger.goldEarned:
        return e.data['cumulative'] >= c['cumulative'];
      case AchievementTrigger.totalLevel:
        return e.data['sum'] >= c['sum'];
      case AchievementTrigger.recipeUnlocked:
        return e.data['count'] >= c['count'];
      case AchievementTrigger.custom:
        return c['key'] == e.data['key'];
    }
  }

  void reset() {
    _earned.clear();
    _counters.clear();
    _revealedBeastHints.clear();
  }
}
```

### 5.2 Engine event emission sites

| Engine site | Event emitted |
|---|---|
| `_resolveCombat` victory branch | `beastDefeated(beast.id)` |
| `_resolveCraftCompletion` (Spec 4) | `craftComplete(item, quality)` |
| Fragment-add site (`_grantFragment`) | `fragmentCollected(tag)` |
| `_maybeCompleteQuest` on completion | `questComplete(quest.id)` |
| `travelTo(zone)` first-entry dedup | `zoneEntered(zone.id)` (dedup via `_firstEnteredZones` set in engine) |
| `_onCleansingComplete` (Spec 5) | `zoneCleansed(tag)`; also `zoneCleansed('all')` when all 3 set |
| Merchant rep tier-up handler (Spec 6a) | `merchantTier(merchantId, tier)` |
| `SkillState.applyXp` post-level-up | Two emissions: `skillLevel(skill, newLevel)` then `totalLevel(sumOfSkills)` |
| `_onPlayerLevelUp` (Section 4) | `playerLevel(newLevel)` |
| `buyItem` / `sellItem` (lifetime gold tracker) | `goldEarned(_lifetimeGold)` |
| `_recipesUnlocked.add(...)` | `recipeUnlocked(_recipesUnlocked.length)` |

### 5.3 Custom-trigger sites

| Achievement | Site & condition |
|---|---|
| `first_gather` | First non-combat `_completeAction` per session — engine emits `custom('first_gather')` once |
| `skill_first_masterwork` | `_onMasterworkSuccess` after the first non-cleansing masterwork |
| `all_skills_5` | End of `_grantSkillXp` — if `_skills.values.every((s) => s.level >= 5)` emit `custom('all_skills_5')` |
| `all_skills_10` | Same site — threshold 10 |
| `repair_first` | First call to `repairWithMaterials` or `repairWithGold` (Spec 6a) |
| `brewer_first` | `_resolveCraftCompletion` when `item.type == ItemType.brew` — also matches `craftComplete` matcher, but redundancy is fine (earned set dedups) |
| `sworn_all_six` | Merchant tier-up handler when all 6 merchants are at Sworn Companion |
| `barehanded_kill` | `_resolveCombat` victory when `_equippedWeaponSlot == null` |
| `no_repair_total_30` | End of `_grantSkillXp` — `totalSkillLevels() >= 30 && !_anyRepairThisRun` (engine tracks `_anyRepairThisRun` bool) |
| `consume_elixir_of_twilight` | Food-consumption handler when item.id == `elixir_of_twilight` (6a item) |
| `obelisk_double_drop` | `inspect_obelisk` completion when both wilds AND old_empire fragment drops occurred in same resolution |
| `defeat_all_echoes` | `_resolveCombat` victory when defeated beast is an Echo AND all 3 Echo `beastDefeated` counters in `_achievementEngine` are ≥ 1 (`beast:echo_of_wilds`, `beast:echo_of_stone`, `beast:echo_of_tide`) — no new engine flags needed |

### 5.4 Bestiary hint UI wiring

[codex_view.dart](../../lib/views/codex_view.dart) `_buildBeastDetail` conditionally renders:

```dart
if (engine.achievementEngine.revealedBeastHints.contains(beast.id)
    && beast.weaknessHint != null) {
  Text('Weak to: ${beast.weaknessHint}', style: weaknessLineStyle)
}
```

Until the matching achievement unlocks, the weakness line is absent (not "?" — fully hidden, matching progressive-discovery principles).

### 5.5 Notification flow on unlock

`onUnlock(ach)` callback (passed at construction by `GameEngine`):

1. Push a `FloatingNotification` (7a widget): icon = `ach.icon`, title = "Achievement Unlocked", body = `ach.name`, accent = gold. 2.5s auto-dismiss.
2. `log("Achievement: ${ach.name}", LogType.success)`.
3. `playSfx('ui_achievement_unlock')` (placeholder; silent if sfx absent).

Hidden achievements show the same notification — they only stay invisible in *list* views prior to unlock, not in the unlock moment.

### 5.6 Codex Achievements tab rules

The tab visibility scaffold already exists ([codex_view.dart:44–46](../../lib/views/codex_view.dart#L44)) and reads `engine.earnedAchievementIds.isNotEmpty`. 6b extends `_buildAchievementsTab` to:

- 7 section headers (one per category), each a `GameCard` with header chip `Earned: N` (no denominator — per [feedback_progressive_discovery](../../C--Users-t8rto-Desktop-flutter-text-based-rpg/memory/feedback_progressive_discovery.md)).
- **Visible categories** (First Steps, Mastery, Combat, Crafting, Lore, Economy): all 6 entries listed. Earned entries show full icon + name + description. Unearned entries show `❔ ???` + greyed criteria hint (vague: e.g., "Defeat several Forest Boars" — not "Defeat 5 Forest Boars").
- **Hidden category**: only earned entries appear. The category card itself doesn't render until ≥1 Hidden earned.

---

## 6. Testing Strategy, Implementation Order & Rollout

### 6.1 Test strategy

**`test/title_resolver_test.dart` (new)**
- Empty skill state → "Wayfarer" fallback
- Single skill at level 5 → Tier 1 title for that skill
- Single skill at level 10 → Tier 2; at 20 → Tier 3
- Two skills tied → tie-break by enum order
- Highest-skill change → resolver picks the new highest

**`test/player_progression_test.dart` (new)**
- `xpToNextLevel(1) == 100`, `xpToNextLevel(10) == 1000`
- `applyXp` rolls level over at exact boundary
- `applyXp` handles multi-level XP gains (e.g., 1000 from level 1 → carries through 5 levels)
- `applyXp` returns `didLevelUp: false` for in-level gains

**`test/player_xp_integration_test.dart` (new)**
- `_grantSkillXp(skill, 100)` grants 20 player XP
- `_grantSkillXp(skill, 4)` grants 0 player XP (integer division)
- Skill at cap: `_grantSkillXp` still grants 20% to player XP (pre-clamp)
- Player level-up fires `_onPlayerLevelUp` and emits `AchievementEvent.playerLevel(N)`
- Title recomputes when skill levels up and the highest-skill changes
- Dashboard `playerLevel` reads from `playerStats.playerLevel`, not `sum(skills)`
- Reset resets player XP to 0 and title to "Wayfarer"

**`test/achievement_engine_test.dart` (new)**
- Engine starts with 0 earned, 0 counters, empty bestiary hints
- `beastDefeated('forest_boar')` × 5 → `boar_hunter` unlocks
- `boar_hunter` unlock adds `forest_boar` to `revealedBeastHints`
- Same-beast counter doesn't double-count after already-earned achievement re-checks (unearned guard)
- `fragmentCollected(CodexTag.wilds)` × 5 → `fragments_wilds` unlocks; tide collections don't increment wilds counter
- `merchantTier(merchantId, swornCompanion)` triggers `sworn_first` once; second merchant doesn't re-trigger
- Custom trigger `'first_gather'` fires only once per session
- Hidden achievement `barehanded_kill` unlocks via custom trigger; doesn't appear in unearned-visible list
- `reset()` clears all three state sets

**`test/achievement_registry_test.dart` (new)**
- `Achievements.all.length == 40`
- Exactly 6 per visible category, 4 in Hidden
- All achievement IDs unique
- All icons are single-emoji (rune count check, per [feedback_no_dual_emoji](../../C--Users-t8rto-Desktop-flutter-text-based-rpg/memory/feedback_no_dual_emoji.md))
- Exactly 5 achievements have non-null `bestiaryHintBeastId`; the 5 beastIds match `[forest_boar, cave_spider, shadow_wolf, cavern_troll, shore_crab]`

**`test/bestiary_hint_test.dart` (new)**
- Beast detail view hides weakness line when beast not in `revealedBeastHints`
- After `boar_hunter` earns, beast detail for `forest_boar` renders weakness line
- Other beasts' weakness lines remain hidden

**Extend `test/widget_test.dart`**
- Dashboard renders new player-XP bar under name
- Codex Achievements tab visibility flips from absent → present after first unlock
- Hidden category section invisible until ≥1 Hidden earned

**Integration smoke (extend `test/quest_engine_test.dart`)**

```dart
test('Spec 6b acceptance — title shifts, achievement unlocks bestiary hint', () {
  final engine = GameEngine();
  engine.grantSkillXpForTest(SkillType.herbalism, 50000);
  expect(engine.playerStats.title, 'Herbalist');           // Tier 2
  expect(engine.playerStats.playerLevel, greaterThan(1));  // 50000/5 = 10000 player XP
  for (var i = 0; i < 5; i++) engine.runCombatToVictoryForTest('cave_spider');
  expect(engine.achievementEngine.earned, contains('spider_lore'));
  expect(engine.achievementEngine.revealedBeastHints, contains('cave_spider'));
});
```

### 6.2 Implementation order

Single PR, internally staged. Each step compiles.

1. **`PlayerProgression`** — new file `lib/models/player_progression.dart` + `test/player_progression_test.dart`. Pure functions.
2. **`PlayerStats` extension** — add `playerLevel`, `playerXp` fields + `copyWith` + `initial`.
3. **`TitleResolver`** — new file `lib/models/title.dart` + `test/title_resolver_test.dart`. Pure resolver.
4. **Engine XP/Title wiring** — modify `_grantSkillXp` to drip player XP + recompute title. Add `_onPlayerLevelUp`. Add `_lifetimeGold` counter for `goldEarned` event.
5. **Dashboard update** — replace `totalLevel = sum(skills)` with `playerStats.playerLevel`; add small XP bar under name.
6. **`Achievement` model extension** — add category, trigger, criteria, bestiaryHintBeastId, hidden fields. Remove unused `titleUnlock` field.
7. **`Achievements.all` registry** — populate 40 entries per Section 2 tables. Validate via `test/achievement_registry_test.dart`.
8. **`AchievementEngine`** — new file `lib/engine/achievement_engine.dart`. Wire `_achievementEngine` into `GameEngine` with `onUnlock` callback that pushes a `FloatingNotification`.
9. **Event emission sites** — wire `_achievementEngine.onEvent(...)` at the 11 engine sites in §5.2.
10. **Custom-trigger handlers** — inline `_achievementEngine.onEvent(AchievementEvent.custom(...))` at the 12 sites in §5.3.
11. **Bestiary hint UI** — extend `_buildBeastDetail` in [codex_view.dart](../../lib/views/codex_view.dart) to conditionally render weakness line. Add `Beast.weaknessHint` field if not present; populate for the 5 hinted beasts.
12. **Codex Achievements tab rewrite** — replace placeholder `_buildAchievementsTab` with grouped-category layout per §5.6.
13. **Reset wiring** — `GameEngine.resetGame` resets `_achievementEngine`, player XP track, `_lifetimeGold`, `_anyRepairThisRun`, `_firstEnteredZones`, re-derives title.
14. **Integration smoke test** in `test/quest_engine_test.dart` per §6.1.

After step 14, 6b ships end-to-end.

### 6.3 Migration & compatibility

No save persistence. First launch after 6b:
- Players start over (no migration needed).
- Dashboard "Lvl N" will be visibly smaller than the old sum-of-skills total — expected.
- The Codex Achievements tab stays hidden on fresh runs until the first unlock fires (likely `first_gather` or `first_kill` within minutes of play).
- Spec 6a achievements (`first_trade`, `gold_500`, `trusted_first`, `sworn_first`, `sworn_all`, `feast_brewer`) only unlock if 6a is shipped. If 6b ships before 6a: those entries appear as `❔ ???` hints in their categories until 6a lands.

### 6.4 Documentation updates

- README.md — extend with "Spec 6b — Achievements, Titles & Player XP" notes
- Inline `///` doc comments on `AchievementEngine`, `TitleResolver`, `PlayerProgression`

### 6.5 Risks & deferrals

- **5× XP nerf may feel punishing.** Global rebalance touching every progression moment. Worth playtesting at the point where the player would have hit "Lvl 10" under the old sum-of-skills. The 20% drip is a single-constant knob to retune.
- **Hidden achievement triggers are sparse.** Only 4 entries, all custom-keyed. Discoverability depends on players doing unusual things (bare-knuckle kill, no-repair sprint). Expected and intentional.
- **Bestiary weakness label.** Only 5 beasts get `weaknessHint` text in 6b. Other beasts stay weakness-less — adding more is a content task for a later spec.
- **Custom triggers' inline grant sites are coupling points.** Step 10 touches 12 engine sites. Acceptable trade for the hybrid model — pure data-driven matchers for derived conditions would require a stateful polling loop, more complex.
- **Deferred to 6c:** title picker (the 24-title set is auto-derived only; if 6c wants manual pinning, the title field stays mutable and recompute logic can be gated on a `manualTitle == null` check).

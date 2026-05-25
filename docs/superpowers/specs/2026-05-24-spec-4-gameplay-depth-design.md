# Spec 4 — Gameplay Depth

**Date:** 2026-05-24
**Status:** Approved (pending spec review)
**Parent:** [Echoes from the Deep umbrella vision](2026-05-24-echoes-from-the-deep-vision.md)
**Depends on:** [Spec 1](2026-05-24-spec-1-quest-codex-foundation-design.md), [Spec 2](2026-05-24-spec-2-codex-content-story-design.md), [Spec 3](2026-05-24-spec-3-sundered-coast-biome-design.md) (all assumed implemented)
**Scope:** Fourth of six sub-specs. Bundles four cohesive subsystems: Combat Stance system with telegraphed beast specials and Quick-Slot bar; Random Event engine with 20 templates; Masterwork-as-Specialization rework with 16 level-20 trials; Spec 3 spillover (Salt Press recipes, Driftwood substitution, Sea Fog crit activation). Adds a unified `NarrativeEventModal` widget shared by Masterwork trials and Random Events.

---

## 1. Goals & Acceptance Criteria

### 1.1 What Spec 4 ships

- **Combat Stance system:** every combat round, player picks one of 5 actions (Strike / Heavy Strike / Defend / Read Tells / Item). Round timer ~2s; default Strike if no input.
- **Telegraphed beast specials:** all 7 beasts (4 existing + 3 from Spec 3) gain abilities firing every 3 rounds with one-round telegraph.
- **Quick-Slot Bar:** always-visible 3-slot consumable strip above Dashboard inventory; tap to use; long-press to configure.
- **Sea Fog crit activation:** Coast + Sea Fog grants +20% crit chance, +50% crit damage (deferred from Spec 3).
- **Random Event engine:** non-combat actions roll for events at ~5% total rate; 20 templates across 4 categories (Interruption / Discovery / Traveler / Omen).
- **Two new items:** Honeycomb (food modifier) + Traveler's Feather (Spec 6 placeholder).
- **Masterwork-as-Specialization rework:** existing level-10 trials' choices set permanent spec paths via new `specPath` field on terminal `MasterworkOption`. 16 new level-20 trials add sub-spec choices.
- **8 level-10 specs + 16 level-20 sub-specs** with full mechanical effects.
- **`_skillSpecs` / `_skillSubSpecs` engine state** + Skills view spec badges + Bestiary spec hints after 3+ defeats of a beast.
- **5 Salt Press recipes** (Salt-Cured Trout, Brined Boar, Kelp Wrap, Pearl Tonic, Brine Stabilizer) + 5 new food/modifier items.
- **Driftwood substitution** for oak_log in tool recipes with +0.03 quality bias.
- **Unified `NarrativeEventModal`** widget replacing the old Masterwork modal; used by both Masterwork trials and Random Events with category-themed border/header.

### 1.2 What Spec 4 does NOT do

- No Echoes / cleansing rituals (Spec 5)
- No new zones / beasts beyond Spec 3
- No third-tier (level 30) specializations
- No companion / taming
- No Achievement entries (spec hint mechanism stubs; Spec 6 fills the Achievement registry)
- No save persistence

### 1.3 Acceptance criteria

A player after Spec 4 ships:

1. Combat with a Forest Boar shows a 5-button action bar; tapping Defend during the round-3 telegraph halves Charge damage
2. Mid-fight, taps Quick-Slot 1 (preset Loaded Potato) → heals 45 HP, slot empties
3. Forages Wildflowers — 4% per non-combat action (5% overall across 4 categories) chance fires a Random Event modal; choices resolve with costs/rewards
4. Hits Crafting 10 → existing Masterwork trial fires → picks iron-reinforced terminal option → spec recorded as `crafting_smith` → Skills view shows blue **Smith** badge
5. Crafts a sword next session → +20% quality bias from Smith spec applied to roll
6. Hits Crafting 20 → new Greater Ironbark trial offered → picks Weaponsmith → gold **Weaponsmith** sub-spec badge
7. Coast in Sea Fog → combat shows ⚡ Critical Strike! on roughly 20% of attacks (+50% damage on crit)
8. Builds Salt Press → opens Workshop Craft tab → 5 starter recipes visible
9. Crafts Stone Axe — uses Driftwood automatically when no Oak Log → +0.03 quality bias
10. Defeats Forest Boar 3+ times → Bestiary entry shows "Tracker spec: +1 yield from this beast type"

### 1.4 Design principles inherited

- **No art** — Material Icons for stance buttons, emoji for telegraph banners, emoji for Quick-Slot icons, emoji for spec badges
- **Progressive discovery** — Random Events are surprises (no event list UI); level-20 trials only offered when level-10 spec is set; Bestiary spec hints unlock at 3+ defeats; Quick-Slot defaults empty (player configures)
- **Thin story spine** — level-20 trials are short narrative beats (4 steps each); no NPC dialogue trees
- **Systems converse** — Sea Fog crit ties Coast weather (Spec 3) into combat (Spec 4); Omen events feed Codex Fragments (Spec 2 + Spec 5 Source pool); Specs affect crafting quality (Spec 2 system) and combat damage (Spec 4 system)

---

## 2. Combat Depth

### 2.1 Round model

```dart
// New: lib/models/combat.dart

enum PlayerStance { strike, heavyStrike, defend, readTells, item }

class CombatRound {
  final int roundNumber;
  final PlayerStance chosenStance;
  final int playerDamageDealt;
  final int playerDamageTaken;
  final bool wasCrit;
}

class BeastTelegraph {
  final String abilityId;
  final String text;       // shown 1 round before
  final bool reveal;       // true when player used Read Tells
}

// Extend CombatState in game_engine.dart
class CombatState {
  // existing fields...
  final List<CombatRound> roundHistory;
  final int roundsSinceLastTelegraph;
  final BeastTelegraph? activeTelegraph;
  final PlayerStance? pendingStance;
  final DateTime? roundDeadline;
  final int? pendingQuickslotIndex;
}
```

### 2.2 Round resolution rules

| Stance | Energy | Effect |
|---|---|---|
| Strike | 0 | Normal damage = `playerAttack - beastDefense` (min 1). Beast acts normally. |
| Heavy Strike | 5 | Damage × 1.5. Beast acts FIRST (player takes incoming first, then deals damage). |
| Defend | 2 | Beast damage halved (min 1); +0 to +5 counter (5 if Guardian spec, 0 otherwise). Player Strike doesn't fire. |
| Read Tells | 3 | No damage either side. Next round: if a telegraph fires, ability name + numeric prediction revealed. |
| Item | 0 | Consume Quick-Slot item; apply healAmount/energyAmount. Slot empties. Beast acts normally. |

Round resolution order:
1. Player chooses stance (or timer expires → default `strike`)
2. If Heavy Strike: beast acts first
3. Otherwise: player acts first
4. Apply effects to HP / energy / quickslot
5. Check defeat / victory
6. If continuing: increment round, check telegraph cooldown, set up next round

### 2.3 Engine API

```dart
// In GameEngine:

void setCombatStance(PlayerStance stance, {int? quickslotIndex}) {
  if (_activeCombat == null || _activeCombat!.pendingStance != null) return;
  final cost = _stanceCost(stance);
  if (_playerStats.currentEnergy < cost) {
    log("Not enough energy.", LogType.warning);
    return;
  }
  _activeCombat = _activeCombat!.copyWith(
    pendingStance: stance,
    pendingQuickslotIndex: quickslotIndex,
  );
  _resolveCombatRound();
}

int _stanceCost(PlayerStance s) {
  switch (s) {
    case PlayerStance.strike: return 0;
    case PlayerStance.heavyStrike:
      return (_skillSpecs[SkillType.combat] == 'combat_berserker') ? 4 : 5;
    case PlayerStance.defend: return 2;
    case PlayerStance.readTells: return 3;
    case PlayerStance.item: return 0;
  }
}

void _onRoundTimerExpired() {
  if (_activeCombat == null || _activeCombat!.pendingStance != null) return;
  setCombatStance(PlayerStance.strike);  // default
}
```

The existing global tick fires `_onRoundTimerExpired` when `DateTime.now() >= roundDeadline`.

### 2.4 Beast abilities

```dart
// lib/models/beast.dart additions:

enum BeastSpecialEffect {
  bigHit,            // double damage
  stun,              // skip player's next action
  bigHitStun,        // double damage + stun (Troll, Salt-Touched)
  summonAlly,        // spawn an additional beast
  drainOverTime,     // -5 HP per round for 3 rounds
  accuracyDebuff,    // player misses 50% next 2 rounds
}

class BeastAbility {
  final String id;
  final String name;
  final int cooldownRounds;          // typically 3
  final String telegraphText;
  final BeastSpecialEffect effect;

  const BeastAbility({
    required this.id,
    required this.name,
    required this.cooldownRounds,
    required this.telegraphText,
    required this.effect,
  });
}

class Beast {
  // existing fields...
  final BeastAbility? ability;        // NEW (optional, null = no special)
}
```

Ability assignments (added to each existing Beast constant):

| Beast | Ability | Telegraph | Effect |
|---|---|---|---|
| Forest Boar 🐗 | Charge | "The boar paws the dirt, lowering its tusks." | bigHit (×2) |
| Cave Spider 🕷️ | Web | "Web-glands glisten." | stun |
| Shadow Wolf 🐺 | Howl | "The wolf's eyes flash silver." | summonAlly (Shadow Wolf) |
| Cavern Troll 👹 | Smash | "The troll hefts a boulder." | bigHitStun |
| Tide Hound 🐕 | Salt Splash | "The hound shakes seawater from its coat." | accuracyDebuff |
| Brine Crawler 🦞 | Pincer Lock | "The crawler's claws lock open." | drainOverTime |
| Salt-Touched Drowned 🧟 | Death Wail | "The drowned thing opens its mouth without sound." | bigHitStun |

All `cooldownRounds: 3`. First ability fires on round 3 if fight lasts that long.

### 2.5 Quick-Slot Bar

```dart
// In GameEngine:

final List<String?> _quickslots = [null, null, null];

List<String?> get quickslots => List.unmodifiable(_quickslots);

void setQuickslot(int index, String? itemId) {
  if (index < 0 || index >= 3) return;
  if (itemId != null) {
    final item = Items.findById(itemId);
    if (item == null || item.type != ItemType.food) return;
  }
  _quickslots[index] = itemId;
  notifyListeners();
}

void useQuickslot(int index) {
  if (index < 0 || index >= 3) return;
  final itemId = _quickslots[index];
  if (itemId == null) return;

  if (_activeCombat != null) {
    setCombatStance(PlayerStance.item, quickslotIndex: index);
  } else {
    // Out-of-combat use
    final item = Items.findById(itemId)!;
    _playerStats = _playerStats.copyWith(
      currentHealth: (_playerStats.currentHealth + item.healAmount).clamp(0, _playerStats.maxHealth),
      currentEnergy: (_playerStats.currentEnergy + item.energyAmount).clamp(0, _playerStats.maxEnergy),
    );
    log("Used ${item.icon} ${item.name}: +${item.healAmount} HP, +${item.energyAmount} energy.", LogType.success);
    _quickslots[index] = null;
    notifyListeners();
  }
}
```

UI: strip widget above Dashboard inventory panel. 3 round buttons showing item emoji + name (or "+" if empty). Tap occupied → use. Long-press → opens inventory picker filtered to `ItemType.food`. First-use shows a one-time confirmation dialog: *"Quick-Slot items are consumed on use. Continue?"*

### 2.6 Sea Fog crit

In `_resolveCombatRound` when computing player damage:

```dart
double critChance = 0.0;
if (_currentZone.id.startsWith('sundered_coast_') &&
    _coastWeather.current == CoastWeather.seaFog) {
  critChance += 0.20;
}
// Combat spec sub-spec additions:
if (_skillSubSpecs[SkillType.combat] == 'combat_reaper') critChance += 0.15;
// ... future spec modifiers ...

final isCrit = _random.nextDouble() < critChance;
final dmgMultiplier = isCrit ? 1.5 : 1.0;
final finalDmg = (baseDmg * dmgMultiplier).round();

if (isCrit) {
  log("⚡ Critical Strike! ${finalDmg} damage", LogType.success);
}
```

### 2.7 Combat UI

New widget `CombatActionBar` mounted inside the existing combat dashboard card. Shows:

- Round counter + countdown progress bar (visual shrinking bar matching `roundDeadline`)
- Telegraph banner (red box with telegraph text) when `activeTelegraph != null`
- 5 stance buttons in a row; grey when energy insufficient
- Item button opens an inline 3-button popover (Quick-Slot picker)

Combat log section below the panel shows last 3 rounds' results.

---

## 3. Random Events

### 3.1 Event engine

New file `lib/models/random_event.dart`:

```dart
enum EventCategory { interruption, discovery, traveler, omen }

class RandomEvent {
  final String id;
  final EventCategory category;
  final String title;
  final String prompt;
  final List<RandomEventOption> options;
  final List<SkillType>? triggerSkills;    // restrict event by required skill
  final List<int>? triggerZoneTiers;       // restrict by zone tier

  const RandomEvent({
    required this.id,
    required this.category,
    required this.title,
    required this.prompt,
    required this.options,
    this.triggerSkills,
    this.triggerZoneTiers,
  });
}

class RandomEventOption {
  final String text;
  final String feedback;
  final int energyCost;
  final int healthCost;
  final int goldCost;
  final SkillType? requiredSkill;
  final int requiredLevel;
  final String? requiredItemId;
  final int requiredItemCount;
  final List<EventReward> rewards;

  const RandomEventOption({
    required this.text,
    required this.feedback,
    this.energyCost = 0,
    this.healthCost = 0,
    this.goldCost = 0,
    this.requiredSkill,
    this.requiredLevel = 1,
    this.requiredItemId,
    this.requiredItemCount = 0,
    required this.rewards,
  });
}

class EventReward {
  final EventRewardKind kind;
  final String? targetId;
  final int amount;
  const EventReward({required this.kind, this.targetId, required this.amount});
}

enum EventRewardKind { item, gold, skillXp, fragment }
```

### 3.2 Trigger logic in `_completeAction`

After existing fragment-drop block, append:

```dart
if (!action.isCombat) {
  _maybeFireRandomEvent(action);
}

void _maybeFireRandomEvent(ZoneAction action) {
  if (_activeRandomEvent != null) return;
  final roll = _random.nextDouble();

  EventCategory? category;
  if (roll < 0.02) category = EventCategory.interruption;
  else if (roll < 0.035) category = EventCategory.discovery;
  else if (roll < 0.045) category = EventCategory.traveler;
  else if (roll < 0.045 + _omenChance()) category = EventCategory.omen;
  else return;

  final eligible = RandomEvents.all.where((e) {
    if (e.category != category) return false;
    if (e.triggerSkills != null && action.requiredSkill != null && !e.triggerSkills!.contains(action.requiredSkill)) return false;
    if (e.triggerZoneTiers != null && !e.triggerZoneTiers!.contains(_currentZone.tier)) return false;
    return true;
  }).toList();

  if (eligible.isEmpty) return;
  final event = eligible[_random.nextInt(eligible.length)];
  _fireRandomEvent(event);
}

double _omenChance() {
  final uncleansed = _calculateBreachTagsWithFragments().length;
  return (0.0025 + uncleansed * 0.004).clamp(0.0025, 0.015);
}
```

Total roll rate ≈ 5% per non-combat action completion.

### 3.3 Engine state

```dart
ActiveRandomEventState? _activeRandomEvent;
final StreamController<RandomEvent> _randomEventStream = StreamController.broadcast();

ActiveRandomEventState? get activeRandomEvent => _activeRandomEvent;
Stream<RandomEvent> get randomEvents => _randomEventStream.stream;

void _fireRandomEvent(RandomEvent event) {
  _activeRandomEvent = ActiveRandomEventState(event: event, startedAt: DateTime.now());
  _randomEventStream.add(event);
  notifyListeners();
}

void resolveRandomEvent(int optionIndex) {
  if (_activeRandomEvent == null) return;
  final event = _activeRandomEvent!.event;
  if (optionIndex < 0 || optionIndex >= event.options.length) return;
  final option = event.options[optionIndex];

  // Validate prerequisites
  if (option.requiredSkill != null) {
    final skill = _skills[option.requiredSkill!];
    if (skill == null || skill.level < option.requiredLevel) return;
  }
  if (option.requiredItemId != null && !_inventory.hasItem(option.requiredItemId!, option.requiredItemCount)) return;

  // Apply costs
  _playerStats = _playerStats.copyWith(
    currentEnergy: (_playerStats.currentEnergy - option.energyCost).clamp(0, _playerStats.maxEnergy),
    currentHealth: (_playerStats.currentHealth - option.healthCost).clamp(0, _playerStats.maxHealth),
    gold: (_playerStats.gold - option.goldCost).clamp(0, 999999),
  );
  if (option.requiredItemId != null) {
    _inventory = _inventory.removeItem(option.requiredItemId!, option.requiredItemCount);
  }

  // Apply rewards
  for (final r in option.rewards) {
    _grantEventReward(r);
  }

  log(option.feedback, LogType.info);
  _activeRandomEvent = null;
  notifyListeners();
}

void _grantEventReward(EventReward r) {
  switch (r.kind) {
    case EventRewardKind.item:
      final item = Items.findById(r.targetId!);
      if (item != null) _inventory = _inventory.addItem(item, r.amount);
      break;
    case EventRewardKind.gold:
      _playerStats = _playerStats.copyWith(gold: _playerStats.gold + r.amount);
      break;
    case EventRewardKind.skillXp:
      final skill = SkillType.values.firstWhere((s) => s.name == r.targetId);
      _skills[skill] = _skills[skill]!.addXp(r.amount.toDouble());
      break;
    case EventRewardKind.fragment:
      // Roll a fragment of the specified tag (r.targetId names the tag)
      final tag = CodexTag.values.firstWhere((t) => t.name == r.targetId);
      tryDropFragment(tag, 1.0);
      break;
  }
}
```

### 3.4 The 20 event templates

#### Interruption (5)

| id | Trigger | Title | Prompt + Options |
|---|---|---|---|
| `bee_swarm` | Herbalism | Bee Swarm | "A wild bee swarm bursts from the bush!" — [Endure: −8 HP, +2 wildflower] [Smoke (1 oak_log): +1 wildflower +1 honeycomb] [Retreat] |
| `rockslide` | Mining | Rockslide | "Pebbles patter down, then a low rumble." — [Brace (Combat 5+): −5 HP] [Dive: lose action loot] [Take cover (Wayfinding 3+): no loss] |
| `sudden_storm` | Wayfinding | Sudden Storm | "Black clouds boil up from nowhere." — [Push: −10 energy] [Shelter: wait 5s] [Turn back: cancel] |
| `axe_slip` | Woodcutting | Axe Slip | "Your grip slipped." — [Bandage (1 wild_berries): −0 HP] [Tough it out: −12 HP, +1 log] [Pause: cancel] |
| `cooking_flare` | Cooking | Pot Flare-up | "The pot leaps in a sudden flare." — [Quick-stir (Cooking 5+): no loss] [Use water (1 hot_water): salvage] [Discard: lose the food] |

#### Discovery (5)

| id | Trigger | Title | Prompt + Options |
|---|---|---|---|
| `hidden_cache` | Any non-combat | Hidden Cache | "A loose stone reveals a cloth-wrapped bundle." — [Open: +1 random resource, +5 gold] [Leave it: nothing] |
| `rare_bloom` | Herbalism | Rare Bloom | "A dark violet bloom catches your eye." — [Pluck (Herbalism 3+): +2 nightshade] [Sketch (Lore 3+): +25 Lore XP] [Leave: nothing] |
| `surveyors_marker` | Wayfinding | Old Surveyor's Marker | "A stone carved with First Age script." — [Read (Lore 1+): +1 Codex Fragment (Old Empire / any)] [Ignore: nothing] |
| `glinting_pebble` | Mining | Glinting Pebble | "A pebble in the shaft glints unnaturally." — [Pocket: +1 salt_crystal or +1 copper_ore (random)] [Inspect (Lore 3+): +20 Lore XP +1 salt_crystal] |
| `feather_in_path` | Woodcutting / scout | Feather in the Path | "A long slate-gray feather rests on the trail." — [Follow (Wayfinding 5+): +1 travelers_feather] [Pocket: +5 gold] [Ignore: nothing] |

#### Traveler (5)

| id | Trigger | Title | Prompt + Options |
|---|---|---|---|
| `wandering_refugee` | T1-2 any | Wandering Refugee | "A thin man with hollow eyes asks for food." — [Offer (1 baked_potato): +30 gold] [Listen: +1 Codex Fragment (Source if open, else Wilds)] [Walk past: nothing] |
| `injured_trapper` | T1-2 wilderness | Injured Trapper | "A trapper limps from the trees, cradling his arm." — [Help (1 wild_berries): +1 wolf_pelt] [Heal (Herbalism 3+): +1 wolf_pelt +1 boar_meat] [Walk past: nothing] |
| `traveling_merchant` | Town Square only | Traveling Merchant | "A merchant with a strange cart greets you." — [Buy (50 gold): +1 philter_of_clarity] [Trade (1 wolf_pelt): +40 gold] [Decline] |
| `mute_pilgrim` | T2-3 any | Mute Pilgrim | "A robed pilgrim gestures to your pack." — [Share rations (1 cooked_fish): +1 Codex Fragment (any open pool)] [Offer water (1 hot_water): +1 wild_berries] [Walk past] |
| `sea_messenger` | Coast zones only | Sea Messenger | "A gull-borne message tube falls at your feet." — [Receive (Wayfinding 5+): +1 Codex Fragment (Tide)] [Refuse: +20 gold] [Ignore] |

#### Omen (5)

| id | Trigger | Title | Prompt + Options |
|---|---|---|---|
| `black_sap_oak` | Woodcutting, T2-3 | Black Sap on the Oak | "Your blade comes back wet with something darker than sap." — [Cut anyway: −5 HP, +1 Codex Fragment (Source / Wilds)] [Mark and leave: +5 Lore XP] [Flee] |
| `whispering_stone` | Mining, T2-3 | Whispering Stone | "The vein hums in a rhythm you almost recognize." — [Listen (Lore 5+): +1 Codex Fragment (Source / Stone)] [Strike it silent: −3 HP] [Walk away] |
| `fog_voice` | Coast, Sea Fog active | Voice in the Fog | "A voice from the fog calls your name." — [Answer: −10 energy, +1 Codex Fragment (Source / Tide)] [Cover ears: nothing] [Sing back (Lore 8+): +30 Lore XP, +1 Codex Fragment] |
| `withered_grove` | Herbalism, T2-3 | Withered Grove | "The grove's heart-tree is rotted black." — [Document (Lore 3+): +25 Lore XP] [Take cuttings: +2 nightshade, +1 Codex Fragment (Wilds)] [Leave] |
| `tapping_in_walls` | Mining, T3 | Tapping in the Walls | "Three taps, a pause, three taps." — [Press your ear: +1 Codex Fragment (Source / Stone)] [Strike back: −5 HP, +1 Stone fragment] [Withdraw: +5 Lore XP] |

### 3.5 Two new items

```dart
// In lib/models/item.dart:

static const Item honeycomb = Item(
  id: 'honeycomb',
  name: 'Honeycomb',
  description: 'A sticky, golden comb. Sweetens any dish with a slight energy bonus.',
  icon: '🍯',
  type: ItemType.food,
  value: 15,
  healAmount: 8,
  energyAmount: 12,
);

static const Item travelersFeather = Item(
  id: 'travelers_feather',
  name: "Traveler's Feather",
  description: 'A long, slate-gray feather. They say it points toward hidden paths.',
  icon: '🪶',
  type: ItemType.resource,
  value: 25,
);
```

Appended to `Items.all`.

---

## 4. Masterwork-as-Specialization Rework

### 4.1 Mechanic

Existing level-10 Masterwork trials' terminal options gain a `specPath` field. On trial success, engine records the player's chosen path in `_skillSpecs[skillType]`. Permanent for the playthrough.

### 4.2 Data model changes

```dart
// In lib/models/masterwork.dart:

class MasterworkOption {
  // existing fields...
  final String? specPath;       // NEW — e.g., 'crafting_smith'
  final String? subSpecPath;    // NEW — e.g., 'crafting_weaponsmith'

  const MasterworkOption({
    // existing required + optional...
    this.specPath,
    this.subSpecPath,
  });
}

// In GameEngine:

final Map<SkillType, String> _skillSpecs = {};
final Map<SkillType, String> _skillSubSpecs = {};

Map<SkillType, String> get skillSpecs => Map.unmodifiable(_skillSpecs);
Map<SkillType, String> get skillSubSpecs => Map.unmodifiable(_skillSubSpecs);

String? specForSkill(SkillType s) => _skillSpecs[s];
String? subSpecForSkill(SkillType s) => _skillSubSpecs[s];
```

### 4.3 Wiring existing level-10 trials

Each of the 8 existing trials' terminal options gets `specPath` set. Example for Crafting:

```dart
// Iron-reinforced terminal:
MasterworkOption(
  text: 'Complete the felling.',
  isSuccess: true,
  energyCost: 20,
  feedback: 'The reinforced blade bites deep into the metallic trunk. The Ironbark tree groans and falls. Woodcutting cap unlocked!',
  specPath: 'crafting_smith',  // NEW
),

// Berry-healed terminal:
MasterworkOption(
  text: 'Complete the felling.',
  isSuccess: true,
  energyCost: 10,
  feedback: 'You chop the remaining connection. The tree falls smoothly. Woodcutting cap unlocked!',
  specPath: 'crafting_tinker',  // NEW
),
```

Path mapping for all 8 existing trials:

| Skill | Iron-/Iron-equivalent option → | Creative/non-iron option → |
|---|---|---|
| Combat | `combat_berserker` (aggressive option) | `combat_guardian` (defensive option) |
| Crafting | `crafting_smith` (iron-reinforced) | `crafting_tinker` (berry-healed creativity) |
| Cooking | `cooking_innkeeper` (precise/structured cook) | `cooking_field_chef` (improvised/field cook) |
| Herbalism | `herbalism_garden_keeper` (patient cultivation) | `herbalism_wild_walker` (risky pluck) |
| Woodcutting | `woodcutting_logger` (volume / brute force) | `woodcutting_arborist` (patience / rare-wood ID) |
| Mining | `mining_prospector` (seeking / exploration) | `mining_refiner` (processing / quality focus) |
| Wayfinding | `wayfinding_cartographer` (mapping / observation) | `wayfinding_tracker` (pursuit / beast-following) |
| Lore | `lore_loremaster` (broad knowledge) | `lore_glyph_carver` (focused glyph mastery) |

The existing trial narratives already imply these paths — Spec 4 just wires the encoding.

### 4.4 Engine completion logic

In the existing Masterwork completion handler:

```dart
void _onMasterworkSuccess(MasterworkRunState run, MasterworkOption terminalOption) {
  final task = run.task;
  // Existing: unlock cap, fire event
  _skills[task.skillType] = _skills[task.skillType]!.unlockCap();

  if (terminalOption.specPath != null) {
    _skillSpecs[task.skillType] = terminalOption.specPath!;
    log("You have walked the ${_specName(terminalOption.specPath!)} path. Forevermore, your craft knows your name.",
        LogType.success);
  }
  if (terminalOption.subSpecPath != null) {
    _skillSubSpecs[task.skillType] = terminalOption.subSpecPath!;
    log("You have refined further into ${_subSpecName(terminalOption.subSpecPath!)}.",
        LogType.success);
  }

  _notifyQuestObservers(MasterworkCompletedEvent(task.skillType));
  notifyListeners();
}
```

### 4.5 Specialization effects table (16 level-10 specs)

| Spec id | Skill | Effect |
|---|---|---|
| `combat_berserker` | Combat | Heavy Strike damage × 1.8 (vs 1.5); Heavy Strike energy cost 4 (vs 5); Defend counter-damage = 0 |
| `combat_guardian` | Combat | Defend reflects flat 5 damage; +1 flat Defense always; Heavy Strike energy cost 8 |
| `crafting_smith` | Crafting | +20% quality bias on weapons + armor; Smith-only blueprints (Spec 6 pool) |
| `crafting_tinker` | Crafting | +20% quality bias on tools + accessories (backpack/gloves/glyphs); Tinker-only blueprints |
| `cooking_innkeeper` | Cooking | Cooking at Field Kitchen +30% speed; foods crafted at Town Square stations permanent |
| `cooking_field_chef` | Cooking | Cooking without Field Kitchen costs no energy; field-crafted foods +1 yield |
| `herbalism_garden_keeper` | Herbalism | Unlocks Wildflower Garden Town Square action (passive 1–2 wildflower per session, 10min cooldown); +20% Herbalism XP from passive sources |
| `herbalism_wild_walker` | Herbalism | +50% rare herb chance (Nightshade etc.) in wild zones; immune to herb hazards (no health-cost on Herbalism actions) |
| `woodcutting_logger` | Woodcutting | +30% wood yield; 20% chance to fell 2 trees in one action |
| `woodcutting_arborist` | Woodcutting | Unlocks Examine Grove Town Square action (passive +1 oak/willow every 10min real-time); +30% quality bias when wood is substituted (driftwood etc.) |
| `mining_prospector` | Mining | +30% ore yield; 20% double-vein chance; +50% rare ore drop |
| `mining_refiner` | Mining | Smelter consumption yields +1 ingot (activates when Smelter ships in a future spec); +30% quality bias on metal-based crafts |
| `wayfinding_cartographer` | Wayfinding | Beast spawn locations shown on Region Status Board; +20% Lore XP from any source |
| `wayfinding_tracker` | Wayfinding | Hunting actions +1 yield; Echo presence indicators on Region Status (activates when Echoes ship in Spec 5) |
| `lore_loremaster` | Lore | Read fragments grant +5 XP to every skill; Old Empire fragments drop 2× more often |
| `lore_glyph_carver` | Lore | Glyph items (glyph_swiftness, glyph_fortitude) +50% effect; +1 use per glyph; unlocks Glyph-Carver-only recipes (Glyph of Sundering, Glyph of Calm) |

### 4.6 Level-20 sub-spec effects (16 sub-specs)

| Sub-spec id | Parent | Effect |
|---|---|---|
| `combat_skirmisher` | Berserker | Round timer −0.5s; Heavy Strike disabled, Strike damage × 1.2 |
| `combat_reaper` | Berserker | +15% crit chance always; crit damage × 2.0 (vs 1.5) |
| `combat_bastion` | Guardian | +3 flat Defense; HP regen +5 per round when Defending |
| `combat_sentinel` | Guardian | Defend counter-damage doubled (10 flat); 25% chance to counter even on Strike round |
| `crafting_weaponsmith` | Smith | +15% additional quality bias on weapons |
| `crafting_armorsmith` | Smith | +15% additional quality bias on armor |
| `crafting_toolmaker` | Tinker | +15% additional quality bias on tools |
| `crafting_backpacker` | Tinker | +1 inventory slot (permanent) |
| `cooking_brewmaster` | Innkeeper | Foods crafted at Inn-only stations also restore +30% energy |
| `cooking_pastrycook` | Innkeeper | Cooked foods grant +1 random stat buff (small) for 3 actions |
| `cooking_trailcook` | Field-Chef | Can cook from raw with no station, no energy cost |
| `cooking_stewmaster` | Field-Chef | Multi-ingredient combos: combine 2 foods into a stew (max-heal max-energy of either input) |
| `herbalism_botanist` | Garden-Keeper | Wildflower Garden also produces 1 wild_berries per cycle |
| `herbalism_hedge_witch` | Garden-Keeper | Wildflower Garden has 10% chance per cycle to produce 1 nightshade |
| `herbalism_poison_picker` | Wild-Walker | Nightshade gathers always yield +1; nightshade weapons gain DoT effect (Spec 5+) |
| `herbalism_bloomseer` | Wild-Walker | All herb gathers 25% faster |
| `woodcutting_clearcutter` | Logger | Wood yield × 1.5; duration × 1.4 (slower but max yield) |
| `woodcutting_speedchopper` | Logger | Wood yield normal; duration × 0.6 (fast) |
| `woodcutting_sapling_mender` | Arborist | Examine Grove cooldown reduced to 5min real-time |
| `woodcutting_heartwood_reader` | Arborist | Ironbark guaranteed when available (Spec 5+ T3 zone); 10% chance for Heartwood (rare crafting modifier) |
| `mining_vein_hunter` | Prospector | +20% chance for a hidden ore (random ore type) per mining action |
| `mining_tunnel_caller` | Prospector | T3 mining hazard chance reduced by 50% |
| `mining_smelt_master` | Refiner | Smelter output doubled (activates when Smelter ships) |
| `mining_slag_cutter` | Refiner | Smelter outputs get +0.10 quality bias |
| `wayfinding_sea_reader` | Cartographer | Coast weather shown 10 minutes in advance |
| `wayfinding_path_mapper` | Cartographer | Scout actions instant in already-scouted zones |
| `wayfinding_beast_lurer` | Tracker | Hunt actions guarantee a beast encounter (no failed hunts) |
| `wayfinding_spoor_reader` | Tracker | Echo telegraphs shown 2 rounds in advance (Spec 5+) |
| `lore_polymath` | Loremaster | Read fragments grant +10 XP to every skill (vs +5) |
| `lore_translator` | Loremaster | Puzzle wrong-Lock penalty reduced to −1 Lore XP (vs −3); auto-reveals 1 correct position after 5 wrong locks |
| `lore_rune_weaver` | Glyph-Carver | Glyphs gain +1 additional use (stacks with Glyph-Carver's +1) |
| `lore_engraver` | Glyph-Carver | Unlocks T3 glyph recipes (Glyph of Convergence, Glyph of Echo) |

### 4.7 Level-20 trials — 16 trial definitions

Each follows a 4-step pattern: `start` (framing referencing player's level-10 spec) → branch A choice → branch A terminal (encodes subSpecA) → branch B terminal (encodes subSpecB).

**Trial offering logic** in `_maybeOfferMasterworkQuest`:

```dart
final spec = _skillSpecs[skill];
if (spec == null) return;  // level-10 spec required first
final taskId = 'task_lvl20_${spec}';
final task = MasterworkTasks.findById(taskId);
if (task == null) return;
// Offer the quest...
```

#### 1. Berserker Lvl 20 — *Blood and Fury*

```dart
static final MasterworkTask combatLvl20Berserker = MasterworkTask(
  id: 'task_lvl20_combat_berserker',
  skillType: SkillType.combat,
  levelGate: 20,
  title: 'Blood and Fury',
  description: 'You have followed the Berserker path. Now choose the shape of your fury.',
  startStepId: 'start',
  steps: {
    'start': MasterworkStep(
      id: 'start',
      prompt: 'A pack of cave spiders moves toward you in the dark. Your blood already sings.',
      options: [
        MasterworkOption(
          text: 'Strike fast and many — outpace their numbers.',
          nextStepId: 'skirmisher_end',
          feedback: 'You cut through them in a blur of motion, never standing still.',
        ),
        MasterworkOption(
          text: 'Strike rare and devastating — wait for the perfect opening.',
          nextStepId: 'reaper_end',
          feedback: 'You wait, breath slow, then strike once. Once is enough.',
        ),
      ],
    ),
    'skirmisher_end': MasterworkStep(
      id: 'skirmisher_end',
      prompt: 'Your speed has become your weapon. The pack lies still in a wide circle.',
      options: [
        MasterworkOption(
          text: 'Stand fast in the silence.',
          isSuccess: true,
          energyCost: 25,
          feedback: 'You are Skirmisher. The fast strike is yours.',
          subSpecPath: 'combat_skirmisher',
        ),
      ],
    ),
    'reaper_end': MasterworkStep(
      id: 'reaper_end',
      prompt: 'The last spider falls. The cave is utterly still.',
      options: [
        MasterworkOption(
          text: 'Wipe the blade clean.',
          isSuccess: true,
          energyCost: 20,
          feedback: 'You are Reaper. The killing blow is yours.',
          subSpecPath: 'combat_reaper',
        ),
      ],
    ),
  },
);
```

#### 2. Guardian Lvl 20 — *Walls and Mirrors*

```dart
static final MasterworkTask combatLvl20Guardian = MasterworkTask(
  id: 'task_lvl20_combat_guardian',
  skillType: SkillType.combat,
  levelGate: 20,
  title: 'Walls and Mirrors',
  description: 'You have followed the Guardian path. A cavern troll bears down on you; you have not lifted your sword.',
  startStepId: 'start',
  steps: {
    'start': MasterworkStep(
      id: 'start',
      prompt: 'The troll roars and charges. Your shield is ready. The question is not whether you survive — you have made that question small. The question is what you teach the troll.',
      options: [
        MasterworkOption(
          text: 'Plant your feet. Become the wall that does not move.',
          nextStepId: 'bastion_end',
          feedback: 'You set your stance wide and low. The troll\'s charge slams into nothing it can move.',
        ),
        MasterworkOption(
          text: 'Angle your shield. Let every strike rebound back into the striker.',
          nextStepId: 'sentinel_end',
          feedback: 'You turn the shield-face. The troll\'s first blow lands and returns, rocking the troll on its heels.',
        ),
      ],
    ),
    'bastion_end': MasterworkStep(
      id: 'bastion_end',
      prompt: 'The troll batters you for what feels like an hour. You do not move. It tires before you do.',
      options: [
        MasterworkOption(
          text: 'Step forward and end it.',
          isSuccess: true,
          energyCost: 25,
          feedback: 'The troll falls. You are Bastion. Nothing will move you that does not move the world first.',
          subSpecPath: 'combat_bastion',
        ),
      ],
    ),
    'sentinel_end': MasterworkStep(
      id: 'sentinel_end',
      prompt: 'The troll bleeds from its own blows. You have not landed one. It still falls.',
      options: [
        MasterworkOption(
          text: 'Let it collapse into its own weight.',
          isSuccess: true,
          energyCost: 20,
          feedback: 'You are Sentinel. Your enemies break themselves on you.',
          subSpecPath: 'combat_sentinel',
        ),
      ],
    ),
  },
);
```

#### 3. Smith Lvl 20 — *The Greater Ironbark*

```dart
static final MasterworkTask craftingLvl20Smith = MasterworkTask(
  id: 'task_lvl20_crafting_smith',
  skillType: SkillType.crafting,
  levelGate: 20,
  title: 'The Greater Ironbark',
  description: 'A second Ironbark stands in the deeper grove, taller and harder than the first. Your Smith path has shaped you; the path you cut next will refine it further.',
  startStepId: 'start',
  steps: {
    'start': MasterworkStep(
      id: 'start',
      prompt: 'The Greater Ironbark towers above you. Your hammer-arm twitches; you have grown strong on the forge path. But today the choice is what kind of strong you will be.',
      options: [
        MasterworkOption(
          text: 'Reshape your axe-head before approaching — a longer, finer edge.',
          nextStepId: 'weaponsmith_end',
          requiredItemId: 'iron_ore',
          requiredItemCount: 8,
          feedback: 'You temper the iron with practiced strokes. The axe rings like a bell.',
        ),
        MasterworkOption(
          text: 'Reshape your armor instead — let the tree fall and the impact test the gear.',
          nextStepId: 'armorsmith_end',
          requiredItemId: 'iron_ore',
          requiredItemCount: 6,
          feedback: 'You re-rivet your chest plate and brace your stance. The armor sits true.',
        ),
      ],
    ),
    'weaponsmith_end': MasterworkStep(
      id: 'weaponsmith_end',
      prompt: 'With the sharper axe, the cut comes precise and deep. You fell the Greater Ironbark with one stroke.',
      options: [
        MasterworkOption(
          text: 'Take the heartwood and forge a new blade pattern.',
          isSuccess: true,
          energyCost: 25,
          feedback: 'You bear the heartwood home and forge a new pattern from it. Your weaponcraft has reached a master\'s hand. Weaponsmith unlocked.',
          subSpecPath: 'crafting_weaponsmith',
        ),
      ],
    ),
    'armorsmith_end': MasterworkStep(
      id: 'armorsmith_end',
      prompt: 'The tree falls; the impact rings through your braced armor. You feel no harm. You read the weak points the impact revealed in the metal.',
      options: [
        MasterworkOption(
          text: 'Take the heartwood and lay out a new armor pattern.',
          isSuccess: true,
          energyCost: 20,
          feedback: 'You bear the heartwood home and lay out a new armor pattern from it. Your armorcraft has reached a master\'s hand. Armorsmith unlocked.',
          subSpecPath: 'crafting_armorsmith',
        ),
      ],
    ),
  },
);
```

#### 4. Tinker Lvl 20 — *The Salt-Eaten Loom*

```dart
static final MasterworkTask craftingLvl20Tinker = MasterworkTask(
  id: 'task_lvl20_crafting_tinker',
  skillType: SkillType.crafting,
  levelGate: 20,
  title: 'The Salt-Eaten Loom',
  description: 'A loom in the Drowned Lighthouse, eaten through by salt. Broken in interesting ways. Your Tinker eye reads it like a book.',
  startStepId: 'start',
  steps: {
    'start': MasterworkStep(
      id: 'start',
      prompt: 'The loom is a wreck, but the wreck shows you something. Two halves of it are still useful. You cannot save both.',
      options: [
        MasterworkOption(
          text: 'Repair the loom\'s tool-bench — the small precise vises and rasps.',
          nextStepId: 'toolmaker_end',
          requiredItemId: 'driftwood',
          requiredItemCount: 6,
          feedback: 'You salvage the brass fittings and re-rig the bench with driftwood. Every tool you make there sits a little finer.',
        ),
        MasterworkOption(
          text: 'Salvage the loom\'s straps and webbing for backpack work.',
          nextStepId: 'backpacker_end',
          requiredItemId: 'spider_silk',
          requiredItemCount: 4,
          feedback: 'You unwind the salt-stiff straps and reweave them with fresh spider silk. The new harness holds more than the old.',
        ),
      ],
    ),
    'toolmaker_end': MasterworkStep(
      id: 'toolmaker_end',
      prompt: 'Your new bench sits true. The first tool you craft on it sings under the rasp.',
      options: [
        MasterworkOption(
          text: 'Pack the bench home.',
          isSuccess: true,
          energyCost: 20,
          feedback: 'You are Toolmaker. Every tool from your hands carries the salt-loom\'s memory.',
          subSpecPath: 'crafting_toolmaker',
        ),
      ],
    ),
    'backpacker_end': MasterworkStep(
      id: 'backpacker_end',
      prompt: 'The new harness fits you. It feels lighter, somehow, than the old one — though it carries more.',
      options: [
        MasterworkOption(
          text: 'Settle the straps and walk home.',
          isSuccess: true,
          energyCost: 18,
          feedback: 'You are Backpacker. The loom\'s last work is what you wear.',
          subSpecPath: 'crafting_backpacker',
        ),
      ],
    ),
  },
);
```

#### 5. Innkeeper Lvl 20 — *The Long Feast*

```dart
static final MasterworkTask cookingLvl20Innkeeper = MasterworkTask(
  id: 'task_lvl20_cooking_innkeeper',
  skillType: SkillType.cooking,
  levelGate: 20,
  title: 'The Long Feast',
  description: 'The Cartographer\'s Tent is throwing a feast for the Wharfmaster\'s arrival. You are running the kitchen.',
  startStepId: 'start',
  steps: {
    'start': MasterworkStep(
      id: 'start',
      prompt: 'Two stations need a master\'s hand. You can only stand at one. The other will be lesser.',
      options: [
        MasterworkOption(
          text: 'Take the brewing station — the drinks are the spine of the feast.',
          nextStepId: 'brewmaster_end',
          requiredItemId: 'wildflower',
          requiredItemCount: 6,
          feedback: 'You set wildflower mead, bittered tea, and hot rye to brewing in turn.',
        ),
        MasterworkOption(
          text: 'Take the oven — the pastries set the mood.',
          nextStepId: 'pastrycook_end',
          requiredItemId: 'baked_potato',
          requiredItemCount: 3,
          feedback: 'You bind potato dough into delicate parcels and slip them into the oven.',
        ),
      ],
    ),
    'brewmaster_end': MasterworkStep(
      id: 'brewmaster_end',
      prompt: 'Every guest drinks. Every guest leaves stronger than they came.',
      options: [
        MasterworkOption(
          text: 'Hand the last cup to the Wharfmaster.',
          isSuccess: true,
          energyCost: 18,
          feedback: 'You are Brewmaster. Your drinks restore what food cannot reach.',
          subSpecPath: 'cooking_brewmaster',
        ),
      ],
    ),
    'pastrycook_end': MasterworkStep(
      id: 'pastrycook_end',
      prompt: 'The pastries leave the oven golden. Every bite carries a small fortune of luck.',
      options: [
        MasterworkOption(
          text: 'Plate the last tray.',
          isSuccess: true,
          energyCost: 16,
          feedback: 'You are Pastrycook. Your food gifts more than nourishment.',
          subSpecPath: 'cooking_pastrycook',
        ),
      ],
    ),
  },
);
```

#### 6. Field-Chef Lvl 20 — *Fire on the Wayside*

```dart
static final MasterworkTask cookingLvl20FieldChef = MasterworkTask(
  id: 'task_lvl20_cooking_field_chef',
  skillType: SkillType.cooking,
  levelGate: 20,
  title: 'Fire on the Wayside',
  description: 'A wayside fire, no station, no walls. A hungry party is coming home with the dusk.',
  startStepId: 'start',
  steps: {
    'start': MasterworkStep(
      id: 'start',
      prompt: 'You have a fire and what you can carry. The party will be here in an hour. You cannot do everything.',
      options: [
        MasterworkOption(
          text: 'Spit-roast each catch whole — speed is the priority.',
          nextStepId: 'trailcook_end',
          requiredItemId: 'raw_trout',
          requiredItemCount: 2,
          feedback: 'You spit each trout, salt it heavy, and turn them in rotation. The smell brings the party home faster than their feet.',
        ),
        MasterworkOption(
          text: 'Combine everything into one great stew — the whole is more than parts.',
          nextStepId: 'stewmaster_end',
          requiredItemId: 'boar_meat',
          requiredItemCount: 2,
          feedback: 'You build a stew from boar, kelp, salt, and whatever herb you find at hand. The pot rumbles low and rich.',
        ),
      ],
    ),
    'trailcook_end': MasterworkStep(
      id: 'trailcook_end',
      prompt: 'Each fish is served whole and quick. The party eats standing, smiling, ready to walk again.',
      options: [
        MasterworkOption(
          text: 'Bank the fire.',
          isSuccess: true,
          energyCost: 12,
          feedback: 'You are Trailcook. No station, no station needed.',
          subSpecPath: 'cooking_trailcook',
        ),
      ],
    ),
    'stewmaster_end': MasterworkStep(
      id: 'stewmaster_end',
      prompt: 'The stew is ladled into every bowl. Each bowl tastes of every ingredient at once.',
      options: [
        MasterworkOption(
          text: 'Drain the pot.',
          isSuccess: true,
          energyCost: 14,
          feedback: 'You are Stewmaster. Two foods become one greater food in your hands.',
          subSpecPath: 'cooking_stewmaster',
        ),
      ],
    ),
  },
);
```

#### 7. Garden-Keeper Lvl 20 — *The Second Garden*

```dart
static final MasterworkTask herbalismLvl20GardenKeeper = MasterworkTask(
  id: 'task_lvl20_herbalism_garden_keeper',
  skillType: SkillType.herbalism,
  levelGate: 20,
  title: 'The Second Garden',
  description: 'Your wildflower garden has thrived. You have room for a second bed. The question is what to plant in it.',
  startStepId: 'start',
  steps: {
    'start': MasterworkStep(
      id: 'start',
      prompt: 'You have turned the earth and prepared the bed. The soil is good. What you plant here will shape what comes from your garden for years.',
      options: [
        MasterworkOption(
          text: 'Plant wild berries alongside — they pair with the bluebells.',
          nextStepId: 'botanist_end',
          requiredItemId: 'wild_berries',
          requiredItemCount: 5,
          feedback: 'You press berry-seeds into the soil. The garden will bear two harvests now.',
        ),
        MasterworkOption(
          text: 'Plant nightshade — risky, but the rewards are uncommon.',
          nextStepId: 'hedge_witch_end',
          requiredItemId: 'nightshade',
          requiredItemCount: 3,
          feedback: 'You bed the nightshade carefully, ringed in stones. It needs space and patience.',
        ),
      ],
    ),
    'botanist_end': MasterworkStep(
      id: 'botanist_end',
      prompt: 'The berry shoots come up two weeks later, healthy and bright.',
      options: [
        MasterworkOption(
          text: 'Tend the garden.',
          isSuccess: true,
          energyCost: 15,
          feedback: 'You are Botanist. Your garden gives more than one harvest.',
          subSpecPath: 'herbalism_botanist',
        ),
      ],
    ),
    'hedge_witch_end': MasterworkStep(
      id: 'hedge_witch_end',
      prompt: 'The nightshade is slow. But when it blooms, it blooms purple and rare.',
      options: [
        MasterworkOption(
          text: 'Crouch beside the bed and breathe in.',
          isSuccess: true,
          energyCost: 18,
          feedback: 'You are Hedge-Witch. Your garden grows what others fear to touch.',
          subSpecPath: 'herbalism_hedge_witch',
        ),
      ],
    ),
  },
);
```

#### 8. Wild-Walker Lvl 20 — *The Deep Grove*

```dart
static final MasterworkTask herbalismLvl20WildWalker = MasterworkTask(
  id: 'task_lvl20_herbalism_wild_walker',
  skillType: SkillType.herbalism,
  levelGate: 20,
  title: 'The Deep Grove',
  description: 'You stand in the heart of a grove that no warden has named. Both poison and bloom grow thick here.',
  startStepId: 'start',
  steps: {
    'start': MasterworkStep(
      id: 'start',
      prompt: 'Two harvests are possible. Either is worth a season\'s walking. You cannot take both.',
      options: [
        MasterworkOption(
          text: 'Harvest the nightshade — careful, deliberate, stacked into the pack.',
          nextStepId: 'poison_picker_end',
          feedback: 'You bind each cluster of nightshade in turn. The pack grows heavy with violet weight.',
        ),
        MasterworkOption(
          text: 'Take only what is in first bloom — fastest, lightest, most varied.',
          nextStepId: 'bloomseer_end',
          feedback: 'You move through the grove in long strides, taking only the brightest blossoms. The walk itself is the gathering.',
        ),
      ],
    ),
    'poison_picker_end': MasterworkStep(
      id: 'poison_picker_end',
      prompt: 'You leave the grove with a pack heavier than you came in with. Every cluster is whole.',
      options: [
        MasterworkOption(
          text: 'Walk home slow under the weight.',
          isSuccess: true,
          energyCost: 18,
          feedback: 'You are Poison-Picker. Where nightshade grows, you carry it home.',
          subSpecPath: 'herbalism_poison_picker',
        ),
      ],
    ),
    'bloomseer_end': MasterworkStep(
      id: 'bloomseer_end',
      prompt: 'You leave the grove almost as light as you came in. Every bloom in your pack is at perfect freshness.',
      options: [
        MasterworkOption(
          text: 'Step quick down the trail.',
          isSuccess: true,
          energyCost: 12,
          feedback: 'You are Bloomseer. The first bloom is the only bloom worth taking, and you find it before others see it.',
          subSpecPath: 'herbalism_bloomseer',
        ),
      ],
    ),
  },
);
```

#### 9. Logger Lvl 20 — *The Old Stand*

```dart
static final MasterworkTask woodcuttingLvl20Logger = MasterworkTask(
  id: 'task_lvl20_woodcutting_logger',
  skillType: SkillType.woodcutting,
  levelGate: 20,
  title: 'The Old Stand',
  description: 'An old stand of oaks — enough wood for a winter. You have to choose how you harvest it.',
  startStepId: 'start',
  steps: {
    'start': MasterworkStep(
      id: 'start',
      prompt: 'The stand is yours for one day. You can take every tree, slow, and waste nothing. Or you can move fast and take the easy ones. The cold is coming either way.',
      options: [
        MasterworkOption(
          text: 'Fell every tree. Slow, methodical, no waste.',
          nextStepId: 'clearcutter_end',
          feedback: 'You work from dawn, dropping one tree, then the next, in a steady cadence. You finish at dusk with everything.',
        ),
        MasterworkOption(
          text: 'Take what falls easiest. Speed over volume.',
          nextStepId: 'speedchopper_end',
          feedback: 'You range the stand, picking out the easy fells, the half-leaning ones, the ones whose roots are already loose.',
        ),
      ],
    ),
    'clearcutter_end': MasterworkStep(
      id: 'clearcutter_end',
      prompt: 'The stand is gone. The pile beside you is enormous.',
      options: [
        MasterworkOption(
          text: 'Begin hauling.',
          isSuccess: true,
          energyCost: 30,
          feedback: 'You are Clearcutter. Where you cut, you cut everything.',
          subSpecPath: 'woodcutting_clearcutter',
        ),
      ],
    ),
    'speedchopper_end': MasterworkStep(
      id: 'speedchopper_end',
      prompt: 'You took a third of the stand in a morning and left the rest to live.',
      options: [
        MasterworkOption(
          text: 'Walk home with the load.',
          isSuccess: true,
          energyCost: 15,
          feedback: 'You are Speedchopper. Your axe goes where the work goes easiest.',
          subSpecPath: 'woodcutting_speedchopper',
        ),
      ],
    ),
  },
);
```

#### 10. Arborist Lvl 20 — *The Sapling Path*

```dart
static final MasterworkTask woodcuttingLvl20Arborist = MasterworkTask(
  id: 'task_lvl20_woodcutting_arborist',
  skillType: SkillType.woodcutting,
  levelGate: 20,
  title: 'The Sapling Path',
  description: 'A storm has torn through a sapling grove. Some young trees are saved; others are bent past mending. You see what could be done.',
  startStepId: 'start',
  steps: {
    'start': MasterworkStep(
      id: 'start',
      prompt: 'You stand among the wreckage of the storm. The young trees can be tended. The dying older ones can be read — their heartwood often holds rarer stock than their living relatives. Both take a season.',
      options: [
        MasterworkOption(
          text: 'Tend the surviving saplings. They will return value for years.',
          nextStepId: 'sapling_mender_end',
          feedback: 'You stake each leaning sapling, ring each root in stones, and begin a season\'s patient work.',
        ),
        MasterworkOption(
          text: 'Read the heartwood of the dying trees. The rare stock is here, if anywhere.',
          nextStepId: 'heartwood_reader_end',
          feedback: 'You bring out the small chisel and the listening-glass. The heartwood speaks of three trees with Ironbark grain.',
        ),
      ],
    ),
    'sapling_mender_end': MasterworkStep(
      id: 'sapling_mender_end',
      prompt: 'The saplings take. Six months later the grove is bright again.',
      options: [
        MasterworkOption(
          text: 'Walk the new grove.',
          isSuccess: true,
          energyCost: 18,
          feedback: 'You are Sapling-Mender. Your grove gives back to you forever.',
          subSpecPath: 'woodcutting_sapling_mender',
        ),
      ],
    ),
    'heartwood_reader_end': MasterworkStep(
      id: 'heartwood_reader_end',
      prompt: 'You take three logs of true Ironbark from the dying trees. They are worth a small fortune.',
      options: [
        MasterworkOption(
          text: 'Bear the logs home.',
          isSuccess: true,
          energyCost: 22,
          feedback: 'You are Heartwood-Reader. Where rare wood grows, you find it.',
          subSpecPath: 'woodcutting_heartwood_reader',
        ),
      ],
    ),
  },
);
```

#### 11. Prospector Lvl 20 — *The Cavern's Promise*

```dart
static final MasterworkTask miningLvl20Prospector = MasterworkTask(
  id: 'task_lvl20_mining_prospector',
  skillType: SkillType.mining,
  levelGate: 20,
  title: 'The Cavern\'s Promise',
  description: 'A cavern your foreman would not enter. The veins are deep and the roof is uncertain.',
  startStepId: 'start',
  steps: {
    'start': MasterworkStep(
      id: 'start',
      prompt: 'You stand at the cavern mouth. The veins glint deep within. The roof is bowed. You can search every shadow for the hidden ones, or you can work the safer cuts and call out for the tunnel to hold.',
      options: [
        MasterworkOption(
          text: 'Hunt every vein. Where there is one, there are three more hidden.',
          nextStepId: 'vein_hunter_end',
          feedback: 'You crouch low and read the cavern walls. Hidden veins reveal themselves to the patient eye.',
        ),
        MasterworkOption(
          text: 'Work the obvious veins. Speak to the roof. Make it hold.',
          nextStepId: 'tunnel_caller_end',
          requiredItemId: 'river_clay',
          requiredItemCount: 4,
          feedback: 'You pack clay into the worst stress points and work the open faces. The roof groans but holds.',
        ),
      ],
    ),
    'vein_hunter_end': MasterworkStep(
      id: 'vein_hunter_end',
      prompt: 'You find veins others have walked past for years.',
      options: [
        MasterworkOption(
          text: 'Mark them in your journal.',
          isSuccess: true,
          energyCost: 22,
          feedback: 'You are Vein-Hunter. Where ore hides, you read its hiding place.',
          subSpecPath: 'mining_vein_hunter',
        ),
      ],
    ),
    'tunnel_caller_end': MasterworkStep(
      id: 'tunnel_caller_end',
      prompt: 'The roof holds for the whole shift. You take what you came for and leave the cavern safer than you found it.',
      options: [
        MasterworkOption(
          text: 'Walk out into the day.',
          isSuccess: true,
          energyCost: 18,
          feedback: 'You are Tunnel-Caller. Where you work, the tunnels stay open.',
          subSpecPath: 'mining_tunnel_caller',
        ),
      ],
    ),
  },
);
```

#### 12. Refiner Lvl 20 — *The Smelter's Heart*

```dart
static final MasterworkTask miningLvl20Refiner = MasterworkTask(
  id: 'task_lvl20_mining_refiner',
  skillType: SkillType.mining,
  levelGate: 20,
  title: 'The Smelter\'s Heart',
  description: 'An old smelter stands cold in the deeper shafts. You can rebuild it your way.',
  startStepId: 'start',
  steps: {
    'start': MasterworkStep(
      id: 'start',
      prompt: 'The smelter\'s heart is broken. You have the parts to rebuild it, but the rebuild itself is a choice. You can build for output — double the throughput — or for purity.',
      options: [
        MasterworkOption(
          text: 'Build for output. Twin furnaces, parallel feeds, max throughput.',
          nextStepId: 'smelt_master_end',
          requiredItemId: 'iron_ore',
          requiredItemCount: 10,
          feedback: 'You forge the twin firepots and link them with a wide flue. The smelter\'s mouth grows wider than the old design ever was.',
        ),
        MasterworkOption(
          text: 'Build for purity. A single deeper crucible, finer drafts, slower work, better ingots.',
          nextStepId: 'slag_cutter_end',
          requiredItemId: 'river_clay',
          requiredItemCount: 8,
          feedback: 'You line the crucible with seven layers of clay and reset the drafts to a finer flow. The smelter will work slow but speak true.',
        ),
      ],
    ),
    'smelt_master_end': MasterworkStep(
      id: 'smelt_master_end',
      prompt: 'The new smelter eats ore at twice the pace. The yield is what you wanted.',
      options: [
        MasterworkOption(
          text: 'Tap the first run.',
          isSuccess: true,
          energyCost: 25,
          feedback: 'You are Smelt-Master. Every load that enters comes out doubled.',
          subSpecPath: 'mining_smelt_master',
        ),
      ],
    ),
    'slag_cutter_end': MasterworkStep(
      id: 'slag_cutter_end',
      prompt: 'The first ingot rings like a small bell. There is no slag.',
      options: [
        MasterworkOption(
          text: 'Pour the next run.',
          isSuccess: true,
          energyCost: 22,
          feedback: 'You are Slag-Cutter. Your ingots carry no impurity.',
          subSpecPath: 'mining_slag_cutter',
        ),
      ],
    ),
  },
);
```

#### 13. Cartographer Lvl 20 — *Charts of the Sea*

```dart
static final MasterworkTask wayfindingLvl20Cartographer = MasterworkTask(
  id: 'task_lvl20_wayfinding_cartographer',
  skillType: SkillType.wayfinding,
  levelGate: 20,
  title: 'Charts of the Sea',
  description: 'The Wharfmaster spreads old sea-charts before you. Two studies are possible. You can master one.',
  startStepId: 'start',
  steps: {
    'start': MasterworkStep(
      id: 'start',
      prompt: 'The charts are layered: weather patterns marked in faded red ink, trade paths in faded blue. To master one is to read it as the keepers once did. To master both is beyond a single season.',
      options: [
        MasterworkOption(
          text: 'Study the red ink — weather patterns and tide turns.',
          nextStepId: 'sea_reader_end',
          feedback: 'You spend the season reading red ink. The Wharfmaster nods more often than he speaks.',
        ),
        MasterworkOption(
          text: 'Study the blue ink — trade paths and stopping points.',
          nextStepId: 'path_mapper_end',
          feedback: 'You spend the season memorizing every blue line. The paths begin to overlay on the land in your mind.',
        ),
      ],
    ),
    'sea_reader_end': MasterworkStep(
      id: 'sea_reader_end',
      prompt: 'You can read the Coast weather ten minutes before it changes. The Wharfmaster stops checking the sky himself.',
      options: [
        MasterworkOption(
          text: 'Take the charts with you.',
          isSuccess: true,
          energyCost: 18,
          feedback: 'You are Sea-Reader. The weather speaks to you before it speaks to others.',
          subSpecPath: 'wayfinding_sea_reader',
        ),
      ],
    ),
    'path_mapper_end': MasterworkStep(
      id: 'path_mapper_end',
      prompt: 'You walk the scouted paths in your sleep. There are no surprises left in the lines you have studied.',
      options: [
        MasterworkOption(
          text: 'Roll up the charts.',
          isSuccess: true,
          energyCost: 16,
          feedback: 'You are Path-Mapper. Where you have been, you go instantly.',
          subSpecPath: 'wayfinding_path_mapper',
        ),
      ],
    ),
  },
);
```

#### 14. Tracker Lvl 20 — *The Last Spoor*

```dart
static final MasterworkTask wayfindingLvl20Tracker = MasterworkTask(
  id: 'task_lvl20_wayfinding_tracker',
  skillType: SkillType.wayfinding,
  levelGate: 20,
  title: 'The Last Spoor',
  description: 'A rare beast\'s trail, fresh in mud. The choice now is how you meet it.',
  startStepId: 'start',
  steps: {
    'start': MasterworkStep(
      id: 'start',
      prompt: 'The trail is fresh. You can move ahead of it and lure the beast to ground of your choosing. Or you can stay behind it, reading the spoor, and know everything before you meet it.',
      options: [
        MasterworkOption(
          text: 'Lure it out. Pick the ground. Control the encounter.',
          nextStepId: 'beast_lurer_end',
          feedback: 'You circle ahead and lay scent. The beast comes to you, on terrain you have chosen.',
        ),
        MasterworkOption(
          text: 'Read the spoor. Know everything before you meet it.',
          nextStepId: 'spoor_reader_end',
          feedback: 'You crouch over each track and broken twig. The beast\'s habits unfold across the mud like writing.',
        ),
      ],
    ),
    'beast_lurer_end': MasterworkStep(
      id: 'beast_lurer_end',
      prompt: 'The beast arrives where you chose. The fight is brief and yours.',
      options: [
        MasterworkOption(
          text: 'Clean the blade.',
          isSuccess: true,
          energyCost: 20,
          feedback: 'You are Beast-Lurer. Beasts come to you, never the other way.',
          subSpecPath: 'wayfinding_beast_lurer',
        ),
      ],
    ),
    'spoor_reader_end': MasterworkStep(
      id: 'spoor_reader_end',
      prompt: 'You meet the beast knowing its every habit. It dies surprised.',
      options: [
        MasterworkOption(
          text: 'Pack the spoils.',
          isSuccess: true,
          energyCost: 16,
          feedback: 'You are Spoor-Reader. You know your enemy before it knows you.',
          subSpecPath: 'wayfinding_spoor_reader',
        ),
      ],
    ),
  },
);
```

#### 15. Loremaster Lvl 20 — *The Polyphonic Reading*

```dart
static final MasterworkTask loreLvl20Loremaster = MasterworkTask(
  id: 'task_lvl20_lore_loremaster',
  skillType: SkillType.lore,
  levelGate: 20,
  title: 'The Polyphonic Reading',
  description: 'The Codex lies open. Two roads to deeper reading present themselves.',
  startStepId: 'start',
  steps: {
    'start': MasterworkStep(
      id: 'start',
      prompt: 'You can read across all the subjects at once, sharpening every skill the Codex touches. Or you can read the languages between the subjects, finding the meanings the puzzles only hint at.',
      options: [
        MasterworkOption(
          text: 'Read across — every fragment teaches every skill.',
          nextStepId: 'polymath_end',
          feedback: 'You let the readings inform every craft. The cartographer watches you with new interest.',
        ),
        MasterworkOption(
          text: 'Read between — every fragment teaches you how to read the next.',
          nextStepId: 'translator_end',
          feedback: 'You begin to see the metalanguage. Puzzles unfold faster under your hand.',
        ),
      ],
    ),
    'polymath_end': MasterworkStep(
      id: 'polymath_end',
      prompt: 'Every page now feeds every skill. Your hands learn from your reading.',
      options: [
        MasterworkOption(
          text: 'Set the book down.',
          isSuccess: true,
          energyCost: 14,
          feedback: 'You are Polymath. Every fragment makes you better at everything.',
          subSpecPath: 'lore_polymath',
        ),
      ],
    ),
    'translator_end': MasterworkStep(
      id: 'translator_end',
      prompt: 'The puzzles open easier under your eye now. The patterns are visible where before they were guesses.',
      options: [
        MasterworkOption(
          text: 'Close the Codex.',
          isSuccess: true,
          energyCost: 12,
          feedback: 'You are Translator. The languages between the words now belong to you.',
          subSpecPath: 'lore_translator',
        ),
      ],
    ),
  },
);
```

#### 16. Glyph-Carver Lvl 20 — *The Twin Glyphs*

```dart
static final MasterworkTask loreLvl20GlyphCarver = MasterworkTask(
  id: 'task_lvl20_lore_glyph_carver',
  skillType: SkillType.lore,
  levelGate: 20,
  title: 'The Twin Glyphs',
  description: 'Two clay tablets. Two glyphs. One method per side.',
  startStepId: 'start',
  steps: {
    'start': MasterworkStep(
      id: 'start',
      prompt: 'You can weave the runes carefully, layered fine, so each glyph holds more than one casting. Or you can engrave them deep, with a new method that opens up glyph patterns never before written.',
      options: [
        MasterworkOption(
          text: 'Weave the runes carefully. Each glyph carries more.',
          nextStepId: 'rune_weaver_end',
          requiredItemId: 'river_clay',
          requiredItemCount: 4,
          feedback: 'You layer the runes in concentric coils. Each tablet, when finished, hums with reserve.',
        ),
        MasterworkOption(
          text: 'Engrave them deep, in a new method. New glyphs become possible.',
          nextStepId: 'engraver_end',
          requiredItemId: 'nightshade',
          requiredItemCount: 2,
          feedback: 'You ink the nightshade into the engraver\'s well and cut deeper than tradition allows. The new shapes resolve into a pattern that\'s never been written.',
        ),
      ],
    ),
    'rune_weaver_end': MasterworkStep(
      id: 'rune_weaver_end',
      prompt: 'Each glyph rings with more castings than tradition allows.',
      options: [
        MasterworkOption(
          text: 'Wrap the tablets.',
          isSuccess: true,
          energyCost: 18,
          feedback: 'You are Rune-Weaver. Every glyph from your hand carries more than it should.',
          subSpecPath: 'lore_rune_weaver',
        ),
      ],
    ),
    'engraver_end': MasterworkStep(
      id: 'engraver_end',
      prompt: 'The deep-cut glyphs open into shapes no Lore Keeper has recorded. New blueprints unfold in your mind.',
      options: [
        MasterworkOption(
          text: 'Press the new patterns into your journal.',
          isSuccess: true,
          energyCost: 22,
          feedback: 'You are Engraver. New glyphs are now possible because of you.',
          subSpecPath: 'lore_engraver',
        ),
      ],
    ),
  },
);
```

**Registry:** All 16 trials added to `MasterworkTasks.all` and `MasterworkTasks.findById`. Total writing: ~3500 words across 16 trials. Each trial follows the same 4-step pattern (start with two branch options, plus one terminal step per branch). Implementation is a straight copy from the spec into `lib/models/masterwork.dart`.

### 4.8 Skills view spec badges

In Skills view, on each skill card, append:

```dart
if (_skillSpecs.containsKey(skill.type)) {
  final spec = _skillSpecs[skill.type]!;
  // Render blue chip with _specName(spec)
}
if (_skillSubSpecs.containsKey(skill.type)) {
  final subSpec = _skillSubSpecs[skill.type]!;
  // Render gold chip with _subSpecName(subSpec)
}
```

Tap a badge → modal showing the full spec effect description.

### 4.9 Bestiary spec hints

In Codex Beasts tab, on each beast card:

```dart
Widget? buildSpecHint(GameEngine engine, String beastId) {
  final defeats = engine.bestiary[beastId]?.defeatCount ?? 0;
  if (defeats < 3) return null;

  final hints = engine.bestiarySpecHints(beastId);
  if (hints.isEmpty) return null;
  return ChipBar(hints: hints);
}
```

Engine helper:

```dart
List<String> bestiarySpecHints(String beastId) {
  final hints = <String>[];
  switch (beastId) {
    case 'forest_boar':
      hints.add('Tracker spec: +1 yield from this beast type.');
      hints.add('Wild-Walker spec: hazard resistance increases boar drop chance.');
      break;
    case 'cave_spider':
      hints.add('Berserker spec: Heavy Strike one-shot at level 20+.');
      hints.add('Refiner spec: Spider Silk drops crafted with +0.10 quality.');
      break;
    case 'shadow_wolf':
      hints.add('Guardian spec: Defend prevents summon-ally on Howl.');
      hints.add('Tracker spec: +1 Wolf Pelt yield.');
      break;
    case 'cavern_troll':
      hints.add('Bastion sub-spec: Smash damage halved further.');
      hints.add('Sea-Reader sub-spec: Echo presence indicators reveal troll spawns.');
      break;
    case 'tide_hound':
      hints.add('Sentinel sub-spec: counter-damage on Defend kills hounds outright.');
      hints.add('Beast-Lurer sub-spec: hound encounters guaranteed.');
      break;
    case 'brine_crawler':
      hints.add('Guardian spec: Defend halves Pincer Lock drain.');
      hints.add('Smelt-Master sub-spec: Crawler Carapace + ore yields steel-tier ingots.');
      break;
    case 'salt_touched_drowned':
      hints.add('Bastion sub-spec: survive Death Wail without stun.');
      hints.add('Reaper sub-spec: crit guaranteed on first hit.');
      break;
  }
  return hints;
}
```

---

## 5. Salt Press Recipes & Driftwood Substitution

### 5.1 Salt Press recipes (5)

```dart
// Recipes appended to Recipes.all:

static const Recipe saltCuredTrout = Recipe(
  id: 'salt_cured_trout',
  name: 'Salt-Cured Trout',
  icon: '🐟',
  description: 'Preserve a fresh trout with sea-salt.',
  resultItemId: 'salt_cured_trout',
  resultQuantity: 1,
  requiredSkill: SkillType.cooking,
  requiredLevel: 3,
  xpReward: 25,
  inputs: {'raw_trout': 1, 'salt_crystal': 1},
  energyCost: 3,
  durationSeconds: 4,
);

static const Recipe brinedBoar = Recipe(
  id: 'brined_boar',
  name: 'Brined Boar',
  icon: '🍖',
  description: 'Brine boar meat in salt-water.',
  resultItemId: 'brined_boar',
  resultQuantity: 1,
  requiredSkill: SkillType.cooking,
  requiredLevel: 5,
  xpReward: 30,
  inputs: {'boar_meat': 2, 'salt_crystal': 1},
  energyCost: 3,
  durationSeconds: 5,
);

static const Recipe kelpWrap = Recipe(
  id: 'kelp_wrap',
  name: 'Kelp Wrap',
  icon: '🥬',
  description: 'Wrap a baked potato in salted kelp.',
  resultItemId: 'kelp_wrap',
  resultQuantity: 1,
  requiredSkill: SkillType.cooking,
  requiredLevel: 4,
  xpReward: 28,
  inputs: {'kelp': 2, 'baked_potato': 1},
  energyCost: 3,
  durationSeconds: 4,
);

static const Recipe pearlTonic = Recipe(
  id: 'pearl_tonic',
  name: 'Pearl Tonic',
  icon: '🧪',
  description: 'Distill a pearlescent draught.',
  resultItemId: 'pearl_tonic',
  resultQuantity: 1,
  requiredSkill: SkillType.herbalism,
  requiredLevel: 6,
  xpReward: 40,
  inputs: {'pearl_shell': 1, 'kelp': 3, 'hot_water': 1},
  energyCost: 5,
  durationSeconds: 6,
);

static const Recipe brineStabilizer = Recipe(
  id: 'brine_stabilizer',
  name: 'Brine Stabilizer',
  icon: '🫙',
  description: 'A briny gel that stabilizes finicky recipes.',
  resultItemId: 'brine_stabilizer',
  resultQuantity: 1,
  requiredSkill: SkillType.cooking,
  requiredLevel: 5,
  xpReward: 35,
  inputs: {'salt_crystal': 2, 'river_clay': 1},
  energyCost: 4,
  durationSeconds: 5,
);
```

All 5 recipes have `station: 'salt_press'` (added field to Recipe model if not already present; matches Spec 1's `stationId` field if that exists).

### 5.2 Five new items

```dart
// In lib/models/item.dart:

static const Item saltCuredTrout = Item(
  id: 'salt_cured_trout', name: 'Salt-Cured Trout',
  description: 'Fresh trout preserved in salt. Lasts longer than fresh fish and keeps your energy steady.',
  icon: '🐟', type: ItemType.food, value: 30, healAmount: 35, energyAmount: 20,
);

static const Item brinedBoar = Item(
  id: 'brined_boar', name: 'Brined Boar',
  description: 'Boar meat brined in salt-water. Heavy on the stomach, light on the wallet.',
  icon: '🍖', type: ItemType.food, value: 40, healAmount: 45, energyAmount: 10,
);

static const Item kelpWrap = Item(
  id: 'kelp_wrap', name: 'Kelp Wrap',
  description: 'A potato wrapped in sea kelp. Tastes of brine and earth.',
  icon: '🥬', type: ItemType.food, value: 35, healAmount: 30, energyAmount: 25,
);

static const Item pearlTonic = Item(
  id: 'pearl_tonic', name: 'Pearl Tonic',
  description: 'A pearlescent draught that sharpens the hands and clears the head.',
  icon: '🧪', type: ItemType.food, value: 80, healAmount: 0, energyAmount: 60,
);

static const Item brineStabilizer = Item(
  id: 'brine_stabilizer', name: 'Brine Stabilizer',
  description: 'A clear, briny gel. Crafters use it as a stabilizing modifier when working on tricky recipes.',
  icon: '🫙', type: ItemType.resource, value: 50,
);
```

All 5 appended to `Items.all`.

### 5.3 Driftwood substitution

```dart
// In GameEngine:

static const Map<String, List<String>> _substitutions = {
  'oak_log': ['driftwood'],
  // Future expansion: 'willow_log': ['driftwood', 'ironbark_log'], etc.
};

bool _hasInputsForRecipe(Recipe recipe) {
  for (final entry in recipe.inputs.entries) {
    final required = entry.key;
    final qty = entry.value;
    final substitutes = [required, ...?_substitutions[required]];
    final available = substitutes.fold<int>(
      0,
      (sum, id) => sum + _inventory.getItemCount(id),
    );
    if (available < qty) return false;
  }
  return true;
}

Map<String, int> _consumeInputsForRecipe(Recipe recipe) {
  final actuallyConsumed = <String, int>{};
  for (final entry in recipe.inputs.entries) {
    int remaining = entry.value;
    final substitutes = [entry.key, ...?_substitutions[entry.key]];
    // Prefer substitutes (Driftwood first when available — auto-substitute)
    for (final id in substitutes.reversed) {
      if (remaining <= 0) break;
      final has = _inventory.getItemCount(id);
      final use = remaining < has ? remaining : has;
      if (use > 0) {
        _inventory = _inventory.removeItem(id, use);
        actuallyConsumed[id] = (actuallyConsumed[id] ?? 0) + use;
        remaining -= use;
      }
    }
  }
  return actuallyConsumed;
}

double _calculateRecipeQualityBias(Recipe recipe, Map<String, int> actualConsumed) {
  double bias = 0.0;
  if (actualConsumed.containsKey('driftwood') && recipe.inputs.containsKey('oak_log')) {
    bias += 0.03;
  }
  return bias;
}
```

Quality bias is added to the existing craft-quality calculation when the craft completes.

---

## 6. Testing, Rollout, & Risks

### 6.1 Test strategy

**New test files:**
- `test/combat_stance_test.dart` — Stance selection, default-Strike, energy gating, telegraph counters, Sea Fog crit
- `test/beast_ability_test.dart` — Each ability fires every 3 rounds with telegraph; Defend halves; Read Tells reveals
- `test/random_event_test.dart` — Trigger rate distribution, category filtering, Omen scaling, resolve costs/rewards
- `test/masterwork_spec_test.dart` — Level-10 trials set specPath; level-20 trials offered only after spec set; subSpecPath records
- `test/spec_effects_test.dart` — All 16 + 16 spec effects verified via mock cases
- `test/salt_press_test.dart` — All 5 recipes exist with correct inputs; new items in Items.all
- `test/driftwood_substitution_test.dart` — `_hasInputsForRecipe` accepts substitutes; consumption prefers substitutes; quality bias correctly applied

**Extend existing:**
- `test/quest_engine_test.dart` — End-to-end smoke test of combat + event + spec + Salt Press
- `test/codex_drops_test.dart` — Omen events fire Source-tag fragments when pool open

### 6.2 Implementation order

Single PR, internally staged:

1. **Combat round model** — `CombatRound`, `PlayerStance`, extend `CombatState`. No behavior change.
2. **Stance setting + resolution** — `setCombatStance`, `_resolveCombatRound`, default-Strike timer.
3. **Beast abilities** — `BeastAbility`, extend `Beast`. Define abilities for all 7 beasts.
4. **Telegraph system** — Pending/active telegraph state, fire every 3 rounds.
5. **Combat UI** — `CombatActionBar` widget, telegraph banner, round-timer progress bar.
6. **Quick-Slot Bar engine state** — `_quickslots` array + `setQuickslot` + `useQuickslot`.
7. **Quick-Slot UI** — Dashboard strip widget, picker, one-time confirmation dialog.
8. **Sea Fog crit** — Engine reads weather + zone, applies crit chance.
9. **Random event model** — `RandomEvent`, `RandomEventOption`, `EventCategory`, `EventReward`, `_maybeFireRandomEvent`, `resolveRandomEvent`, stream.
10. **20 event templates** — Add to `RandomEvents.all`. Add Honeycomb + Traveler's Feather to `Items.all`.
11. **NarrativeEventModal redesign** — Unified widget with category-themed border/header; replace existing Masterwork modal; use for Random Events too.
12. **Salt Press recipes** — Add 5 new items + 5 new recipes; wire into Recipes.all with `station: 'salt_press'`.
13. **Driftwood substitution** — `_substitutions` map; rewire `_hasInputsForRecipe`, `_consumeInputsForRecipe`, `_calculateRecipeQualityBias`.
14. **Masterwork-as-spec mechanic** — `specPath`/`subSpecPath` on MasterworkOption; `_skillSpecs`/`_skillSubSpecs` state; `_onMasterworkSuccess` records.
15. **Wire existing trials** — Update all 8 existing level-10 trials' terminal options.
16. **8 + 8 level-20 trials** — Add 16 new MasterworkTask entries (Blood and Fury, Walls and Mirrors, etc.) with full narrative.
17. **Level-20 offering logic** — Extend `_maybeOfferMasterworkQuest`.
18. **Specialization effects wiring** — Engine reads spec/sub-spec in combat damage, craft quality, gather yield, etc.
19. **Skills view spec badges** — Render badges + tap-to-modal.
20. **Bestiary spec hints** — `bestiarySpecHints` helper + render hint text after 3+ defeats.
21. **Tests** — written alongside each step.

### 6.3 Migration & compatibility

No save persistence. Players who already completed level-10 Masterwork trials in pre-Spec-4 sessions: no spec recorded (`_skillSpecs` defaults empty); their existing perks (cap +10) still apply. To get a spec, must complete trials in a fresh session.

Combat: existing fights use the new round model. Default-Strike preserves hands-off play.

### 6.4 Risks & deferrals

- **Round-based combat refactor is the highest-risk change.** Test rigorously at each round; verify hands-off auto-Strike preserves prior playability.
- **Quick-Slot consumption is permanent.** One-time confirmation dialog mitigates.
- **16 trials × ~250 words = ~4000 words of narrative writing.** Each trial expanded during implementation following the trial 1 (Blood and Fury) and trial 3 (Greater Ironbark) reference patterns.
- **Some spec effects reference future systems** (Smelter, Echo telegraphs, T3 zones). Engine code handles gracefully — those modifiers no-op when the system doesn't yet exist.
- **NarrativeEventModal redesign affects existing Masterwork UX.** Test that existing trials still play correctly through the new modal.
- **Deferred to Spec 5:** Echo combat (Tracker / Spoor-Reader / Beast-Lurer specs partially activate); first_breach_cleansed flag (Omen-driven Source drops stay no-op until cleansing exists); breach cleansing rituals.
- **Deferred to Spec 6:** Achievement entries; NG+ logic for resetting specs; Smelter / Tannery / Apothecary stations referenced by Refiner sub-specs.

### 6.5 Player walkthrough

A player after Spec 4 ships:

1. Logs in. Quick-Slot strip appears above inventory (3 empty slots).
2. Travels to Whispering Woods, fights a Forest Boar. Action bar appears with 5 stances. Ignores it; default Strike fires per round.
3. Round 3: boar telegraphs *"The boar paws the dirt, lowering its tusks."* Player doesn't react. Round 4: takes 12 damage Charge instead of 6 normal.
4. Next boar: player taps Defend on telegraph round. Takes 3 damage instead of 12.
5. Forages Wildflowers — eventually rolls a Random Event: *"A wild bee swarm bursts from the bush!"* Picks Smoke them out (1 Oak Log), gains Wildflower + Honeycomb.
6. Hits Crafting 10. Existing Ironbark Trial fires through new NarrativeEventModal (gold-bordered). Picks iron-reinforced path. *"You have walked the Smith path."* Blue Smith badge on Crafting card.
7. Crafts a sword. Quality roll +0.20 from Smith spec. Rolls Fine instead of Standard.
8. Travels to Coast in Sea Fog. Fights Tide Hound. First crit lights up ⚡ Critical Strike! 13 damage.
9. Builds Salt Press. Opens Workshop Craft tab. 5 Coast recipes available. Crafts Salt-Cured Trout, slots it in Quick-Slot 1.
10. Hits Crafting 20. Greater Ironbark trial fires. Picks Weaponsmith. Gold Weaponsmith sub-spec badge.
11. Next sword craft. Quality bias +0.35 (Smith +0.20 + Weaponsmith +0.15). Masterwork-quality roll likely.
12. Defeats Forest Boar 3 times. Bestiary entry shows: *"Tracker spec: +1 yield from this beast type."* Player considers Wayfinding next.

The game now has tactical combat, surprise lore moments, and meaningful build identity.

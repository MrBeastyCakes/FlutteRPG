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
// 4-step trial. start → bastion_end / sentinel_end
// Framing: "A great cavern troll bears down. Your shield is ready."
// Branch A: "Plant your feet, weather every blow" → Bastion (subSpec)
// Branch B: "Let each strike rebound from your shield" → Sentinel (subSpec)
```

#### 3. Smith Lvl 20 — *The Greater Ironbark* (sample reference)

(Full text shown earlier in design Section 4 — wiring crafting_weaponsmith vs crafting_armorsmith.)

#### 4. Tinker Lvl 20 — *The Salt-Eaten Loom*

```dart
// 4-step trial. start → toolmaker_end / backpacker_end
// Framing: "A salt-eaten loom in the Drowned Lighthouse — broken in interesting ways."
// Branch A: "Repair the loom's tool-bench" → Toolmaker
// Branch B: "Salvage the loom's straps as backpack thread" → Backpacker
```

#### 5. Innkeeper Lvl 20 — *The Long Feast*

```dart
// Framing: "The Cartographer's Tent throws a feast for the Wharfmaster's arrival."
// Branch A: "Brew the drinks" → Brewmaster
// Branch B: "Bake the pastries" → Pastrycook
```

#### 6. Field-Chef Lvl 20 — *Fire on the Wayside*

```dart
// Framing: "A wayside fire, no station, no time. You need to feed a hungry party."
// Branch A: "Cook each animal whole and quick" → Trailcook
// Branch B: "Make a stew from everything at once" → Stewmaster
```

#### 7. Garden-Keeper Lvl 20 — *The Second Garden*

```dart
// Framing: "Your garden has thrived. You have room for a second bed."
// Branch A: "Plant berries alongside" → Botanist
// Branch B: "Plant nightshade with caution" → Hedge-Witch
```

#### 8. Wild-Walker Lvl 20 — *The Deep Grove*

```dart
// Framing: "You stand in the heart of a grove that no warden has named."
// Branch A: "Harvest the nightshade carefully" → Poison-Picker
// Branch B: "Take only what blooms first" → Bloomseer
```

#### 9. Logger Lvl 20 — *The Old Stand*

```dart
// Framing: "An old stand of trees — enough wood for a winter."
// Branch A: "Fell every tree, no waste" → Clearcutter
// Branch B: "Move fast, take what's easy" → Speedchopper
```

#### 10. Arborist Lvl 20 — *The Sapling Path*

```dart
// Framing: "A sapling grove damaged by storm. You see what could be saved."
// Branch A: "Tend the saplings — they will return value" → Sapling-Mender
// Branch B: "Read the heartwood of the dying trees — there's rarer stock here" → Heartwood-Reader
```

#### 11. Prospector Lvl 20 — *The Cavern's Promise*

```dart
// Framing: "A cavern your foreman wouldn't enter."
// Branch A: "Seek every hidden vein" → Vein-Hunter
// Branch B: "Call out for the tunnel to hold — work safer here" → Tunnel-Caller
```

#### 12. Refiner Lvl 20 — *The Smelter's Heart*

```dart
// Framing: "An old smelter stands cold. You can rebuild it your way."
// Branch A: "Build for output — double the throughput" → Smelt-Master
// Branch B: "Build for purity — better ingots" → Slag-Cutter
```

#### 13. Cartographer Lvl 20 — *Charts of the Sea*

```dart
// Framing: "The Wharfmaster shows you old sea-charts."
// Branch A: "Study the weather patterns" → Sea-Reader
// Branch B: "Study the trade paths" → Path-Mapper
```

#### 14. Tracker Lvl 20 — *The Last Spoor*

```dart
// Framing: "A rare beast's trail, fresh in mud."
// Branch A: "Lure it out — control the encounter" → Beast-Lurer
// Branch B: "Read the spoor — know what comes" → Spoor-Reader
```

#### 15. Loremaster Lvl 20 — *The Polyphonic Reading*

```dart
// Framing: "The Codex offers two roads to deeper reading."
// Branch A: "Read across all subjects" → Polymath
// Branch B: "Read the languages between" → Translator
```

#### 16. Glyph-Carver Lvl 20 — *The Twin Glyphs*

```dart
// Framing: "Two clay tablets, two glyphs."
// Branch A: "Weave the runes carefully" → Rune-Weaver
// Branch B: "Engrave them deep, with a new method" → Engraver
```

For trials 2 + 4–16, the structure is identical to trial 1 (Berserker). Each has `start` step + two branch terminal steps. Full text expanded during implementation (sample shown in trial 1 + reference to Greater Ironbark in §4 of brainstorm). **Engineers writing these follow the trial 1 / trial 3 pattern with the framing and branch hints listed above.** Estimated 200–300 words per trial; ~3500 words total for all 16.

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

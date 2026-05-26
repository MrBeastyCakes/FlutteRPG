# Spec 6a — Living Economy

**Date:** 2026-05-25
**Status:** Approved (pending spec review)
**Parent:** [Echoes from the Deep umbrella vision](2026-05-24-echoes-from-the-deep-vision.md)
**Depends on:** Specs 1–5 (all assumed implemented). Spec 7a primitives (GameCard, GameChip, GameProgressBar, GameButton, GameTabs) used throughout.
**Companion specs:** 6b (Achievements + Titles) and 6c (Nexus Finale) — separate brainstorms.
**Scope:** First of three mini-specs decomposed from the umbrella's Spec 6. Ships four "living world" subsystems: Tool Durability (all equipment), Scarce Reagents (6 items + Notice spawn mechanic), Merchant Reputation (5-tier ladder + 6th merchant Bram the Tavern-Keeper), Daily Tasks (Tavern fixture + 30 task templates).

---

## 1. Goals & Acceptance Criteria

### 1.1 What 6a ships

1. **Tool Durability** — all equipment (tools, weapons, armor) gains `currentDurability` / `maxDurability` on `InventorySlot`. Decrements per use (tools per gather; weapons per Strike/Heavy Strike; armor per damage taken). At 0, equipment becomes Worn (stat bonuses ignored, still equipped). Two repair paths: materials at Crafting Bench (25% of recipe inputs) OR gold at relevant merchant (Maeve for tools, Hilda for weapons/armor). Quality affects max durability (75/100/150/250 for Crude/Standard/Fine/Masterwork); Sturdy affix +50%.

2. **Scarce Reagents** — 6 new reagent items integrated as crafting modifier-slot ingredients (extending Spec 4's modifier system). Notice spawn mechanic: 2–4 spawns per session (scaling with total skill level) appearing as pulsing cards at top of zone-action lists. Per-biome thematic pools + universal Wisp-Light at 10% override chance. Collection requires skill level 5 + 5 energy.

3. **Merchant Reputation** — 5-tier ladder (Stranger / Familiar / Trusted Patron / Honored Friend / Sworn Companion). Reputation gained per transaction (+2 per gold spent, +1 per gold gained, cap 200/session/merchant). Each tier unlocks: stock bonuses, discounts (10/20/30%), unique items at Trusted Patron, one-time gifts at Honored Friend, personal Codex fragments at Sworn Companion. Adds **6th merchant Bram the Tavern-Keeper** (always accessible via Tavern, plus joins rotation). Visible via per-shop chip + new Codex Reputation tab.

4. **Daily Tasks (Tavern fixture)** — Town Square gains a **Tavern** fixture (conditional render after first Town Square restoration). Full sub-view with 2 tabs: Notice Board (3 daily tasks) + Bram's Wares (his merchant inventory). 30 task templates across 6 categories (Gather / Hunt / Visit / Craft / Codex / Cleanse). Procedural generation scales with player total skill level + respects engine flags. Tasks auto-progress via existing Quest engine observers. Daily Bonus on all 3 claimed: 120 gold + 5% blueprint scroll chance. Tasks reset on app restart.

### 1.2 What 6a does NOT do

- No Achievements / Titles (Spec 6b)
- No Nexus zone / The Source final boss (Spec 6c)
- No credits sequence / Free Mode / NG+ (Spec 6c)
- No music / ambient audio
- No save persistence

### 1.3 Acceptance criteria

A player after 6a ships:

1. Sees durability bars on equipped tools / weapons / armor; bars drain during use; low-durability warning fires once per session per equipped item
2. Worn equipment still equipped but no stat bonus; "Worn" badge on item card
3. Repairs tools at Maeve / weapons + armor at Hilda for gold (~25% sell value); OR repairs anything at a Crafting Bench for materials (25% of recipe inputs)
4. Pulsing Notice card appears at top of zone-action lists for uncollected reagent spawns; tap collects (requires skill 5+ + 5 energy)
5. Crafts with a Wisp-Light reagent in the modifier slot → guaranteed Masterwork quality
6. Visits Hilda → rep chip shows tier + progress; reaches Trusted Patron → her shop stocks a Weaponsmith's Pattern blueprint scroll
7. Visits Town Square → new "Visit the Tavern" action; tap opens Tavern view with Notice Board (3 daily tasks) + Bram's Wares (merchant inventory)
8. Completes all 3 daily tasks → Daily Bonus modal: +120 gold + 5% blueprint scroll
9. Opens Codex → new Reputation tab listing 6 merchants with tier + progress
10. After ~60 sessions of capped trade with a merchant → Sworn Companion unlocks their personal Codex fragment (Misc-tag)

### 1.4 Design principles inherited

- **No art** — single-emoji icons everywhere; UI built from Spec 7a primitives (GameCard, GameChip, GameProgressBar, GameTabs, GameButton)
- **No dual-emoji icons** — Bram = 🍺, each reagent has a distinct single emoji
- **Progressive discovery** — Tavern fixture only after first Town Square restoration; Reputation chip per merchant only after first trade; Codex Reputation tab only when at least one trade has occurred; Notice cards only when spawn exists in current zone
- **Systems converse** — durability ticks via existing combat + gathering events; reagents plug into Spec 4 modifier slot; reputation hooks into existing shop transactions; daily tasks auto-progress via Spec 1 Quest observer pipeline

---

## 2. Tool Durability

### 2.1 Data model

```dart
// Extend lib/models/inventory.dart InventorySlot:

class InventorySlot {
  // existing: item, quantity, quality, affixIds
  final int currentDurability;   // 0..maxDurability
  final int maxDurability;       // 0 = unset (quest items / pre-migration)
  // copyWith / equality updated to include both
}
```

### 2.2 Max durability calculation

```dart
int calculateMaxDurability(Item item, QualityTier quality, List<String> affixIds) {
  int base;
  switch (quality) {
    case QualityTier.crude: base = 75;
    case QualityTier.standard: base = 100;
    case QualityTier.fine: base = 150;
    case QualityTier.masterwork: base = 250;
  }
  if (affixIds.contains('sturdy')) base = (base * 1.5).round();
  return base;
}
```

Items with `value: 0` (Cleansing Tokens, Echo Essences, etc.) are durability-immune — skip the stamp.

### 2.3 Decrement rules

| Equipment | Decrements when |
|---|---|
| Tool (axe / pickaxe / gloves) | Gathering action completes that uses the tool's `toolSkill` |
| Weapon | Combat round uses Strike or Heavy Strike stance |
| Armor | Combat round inflicts non-zero damage on player |

### 2.4 Engine wiring

In `_completeAction` (gathering completion):

```dart
if (!action.isCombat && action.requiredSkill != null) {
  final tool = _equippedToolSlots[action.requiredSkill!];
  if (tool != null) {
    _decrementDurability(tool, slot: 'tool', skill: action.requiredSkill);
  }
}
```

In `_resolveCombatRound`:

```dart
if (stance == PlayerStance.strike || stance == PlayerStance.heavyStrike) {
  if (_equippedWeaponSlot != null) {
    _decrementDurability(_equippedWeaponSlot!, slot: 'weapon');
  }
}
if (playerDmgTaken > 0 && _equippedArmorSlot != null) {
  _decrementDurability(_equippedArmorSlot!, slot: 'armor');
}
```

Helper:

```dart
final Set<String> _lowDurabilityWarned = {};

void _decrementDurability(InventorySlot equipped, {required String slot, SkillType? skill}) {
  if (equipped.maxDurability == 0) return;
  final newDur = (equipped.currentDurability - 1).clamp(0, equipped.maxDurability);
  final updated = equipped.copyWith(currentDurability: newDur);

  switch (slot) {
    case 'tool':   _equippedToolSlots[skill!] = updated;
    case 'weapon': _equippedWeaponSlot = updated;
    case 'armor':  _equippedArmorSlot = updated;
  }

  final pct = newDur / equipped.maxDurability;
  if (pct <= 0.25 && !_lowDurabilityWarned.contains(equipped.item.id)) {
    _lowDurabilityWarned.add(equipped.item.id);
    log("⚠️ ${equipped.item.icon} ${equipped.item.name} is wearing thin (${newDur}/${equipped.maxDurability}).", LogType.warning);
    AudioEngine.instance.play('ui_error_soft');
  }
  notifyListeners();
}
```

### 2.5 Worn equipment behavior

When `currentDurability == 0`: equipped but stat-stripped. UI shows "Worn" badge.

```dart
bool isSlotWorn(InventorySlot? slot) {
  if (slot == null || slot.maxDurability == 0) return false;
  return slot.currentDurability <= 0;
}

int getPlayerAttack() {
  int base = 5;
  if (_equippedWeaponSlot != null && !isSlotWorn(_equippedWeaponSlot)) {
    base += getItemAttackPower(...);
  }
  // ... combat spec bonus stays the same ...
  return base;
}
```

Same pattern applied to `getPlayerDefense`, tool speed/success bonus lookups.

### 2.6 Repair Path A — materials at Crafting Bench

```dart
Map<String, int> calculateRepairCost(InventorySlot slot) {
  final recipe = Recipes.findByResultItemId(slot.item.id);
  if (recipe == null) return {};  // non-craftable → gold only
  return recipe.inputs.map((id, qty) => MapEntry(id, max(1, (qty * 0.25).ceil())));
}

bool canRepairWithMaterials(InventorySlot slot) {
  final cost = calculateRepairCost(slot);
  if (cost.isEmpty) return false;
  for (final entry in cost.entries) {
    if (!_inventory.hasItem(entry.key, entry.value)) return false;
  }
  return true;
}

void repairWithMaterials(InventorySlot equipped, {required String slot, SkillType? skill}) {
  final cost = calculateRepairCost(equipped);
  if (!canRepairWithMaterials(equipped)) return;
  for (final entry in cost.entries) {
    _inventory = _inventory.removeItem(entry.key, entry.value);
  }
  final updated = equipped.copyWith(currentDurability: equipped.maxDurability);
  _setEquippedSlot(slot, updated, skill: skill);
  log("Repaired ${equipped.item.icon} ${equipped.item.name} at the Crafting Bench.", LogType.success);
  AudioEngine.instance.play('ui_success');
  _lowDurabilityWarned.remove(equipped.item.id);
  notifyListeners();
}
```

Bench repair queued as a ~3s action (sequenced behind any active craft).

### 2.7 Repair Path B — gold at relevant merchant

| Merchant | Repairs |
|---|---|
| Maeve (Outfitter) | Tools (axe, pickaxe, gloves) |
| Hilda (Blacksmith) | Weapons + Armor |
| Cedric, Pippin, Silas, Bram | No repairs |

```dart
int calculateRepairGoldCost(InventorySlot slot) {
  if (slot.maxDurability == 0) return 0;
  final damagePct = (slot.maxDurability - slot.currentDurability) / slot.maxDurability;
  return max(1, (slot.item.value * 0.25 * damagePct).ceil());
}

void repairWithGold(InventorySlot equipped, {required String slot, SkillType? skill}) {
  final cost = calculateRepairGoldCost(equipped);
  if (_playerStats.gold < cost) return;
  _playerStats = _playerStats.copyWith(gold: _playerStats.gold - cost);
  final updated = equipped.copyWith(currentDurability: equipped.maxDurability);
  _setEquippedSlot(slot, updated, skill: skill);
  log("Repaired ${equipped.item.icon} ${equipped.item.name} (-$cost gold).", LogType.success);
  AudioEngine.instance.play('ui_success');
  _lowDurabilityWarned.remove(equipped.item.id);
  notifyListeners();
}
```

Gold repair is instant.

### 2.8 UI surfaces

- **Equipment slot durability bars** — `GameProgressBar` (Spec 7a) on Dashboard equipment quick-view + Inventory view's Equipment section. Color: skill color >50%; warning yellow 25–50%; error red <25%; "Worn" badge replaces bar at 0
- **Workshop Build sub-tab: Repairs panel** — appears above build options when a Crafting Bench is selected in the current zone; lists each repairable equipped item with cost + Repair button
- **Maeve / Hilda shop view: Repairs section** — appears above Buy/Sell when relevant equipment is damaged; shows gold cost + Repair button

### 2.9 Touch summary for §2

| File | Change |
|---|---|
| `lib/models/inventory.dart` | Extend `InventorySlot` with `currentDurability`, `maxDurability`; update `copyWith` + equality |
| `lib/engine/game_engine.dart` | Add `_decrementDurability`, `isSlotWorn`, `_lowDurabilityWarned`; tick durability in `_completeAction` (tools) + `_resolveCombatRound` (weapons + armor); add repair API; modify stat helpers to respect Worn |
| `lib/views/inventory_view.dart` | Render durability bar + "Worn" badge |
| `lib/views/dashboard_view.dart` | Render durability bar on equipment quick-view |
| `lib/views/build_view.dart` | Add Repairs panel to Crafting Bench |
| `lib/views/shop_view.dart` (or merchant equivalent) | Add Repairs section to Maeve + Hilda |
| `lib/models/recipe.dart` | Add `findByResultItemId(itemId)` helper if not present |

---

## 3. Scarce Reagents

### 3.1 The 6 reagent items

```dart
// In lib/models/item.dart:

static const Item moonpetal = Item(
  id: 'moonpetal', name: 'Moonpetal',
  description: 'A bone-white blossom that glows faintly in moonlight. Forces an affix roll on a craft.',
  icon: '🌸', type: ItemType.resource, value: 60,
);

static const Item spiritSap = Item(
  id: 'spirit_sap', name: 'Spirit Sap',
  description: 'Translucent sap that doubles back on itself. Doubles the output of a craft.',
  icon: '💧', type: ItemType.resource, value: 70,
);

static const Item hollowBone = Item(
  id: 'hollow_bone', name: 'Hollow Bone',
  description: 'A weightless bone from a creature no one remembers. Grants Brutal affix to a weapon.',
  icon: '🦴', type: ItemType.resource, value: 80,
);

static const Item seaTear = Item(
  id: 'sea_tear', name: 'Sea-Tear',
  description: 'A crystallized drop of cold sea-water. Grants Tempered affix to armor.',
  icon: '💎', type: ItemType.resource, value: 80,
);

static const Item coalblood = Item(
  id: 'coalblood', name: 'Coalblood',
  description: 'A viscous black liquid that smells of forge-smoke. Grants Frugal affix to any craft.',
  icon: '🌑', type: ItemType.resource, value: 90,
);

static const Item wispLight = Item(
  id: 'wisp_light', name: 'Wisp-Light',
  description: 'A flickering mote captured at twilight. Guarantees Masterwork quality on a craft.',
  icon: '✨', type: ItemType.resource, value: 200,
);
```

Note on Sea-Tear / Glinting Ore icon clash: both use 💎. Different contexts (Sea-Tear in modifier picker, Glinting Ore in raw resource inventory) — flagged for visual review during implementation; swap Sea-Tear to 🌀 if confusion arises.

### 3.2 Modifier effects

Extending Spec 4's modifier slot handling in `_resolveCraftCompletion`:

```dart
switch (modifierId) {
  // ... existing Spec 4 cases ...
  case 'moonpetal':
    if (resultIsAffixable(resultItem)) affixIds.add(_rollRandomAffix(resultItem.type));
    break;
  case 'spirit_sap':
    finalQty = finalQty * 2;
    break;
  case 'hollow_bone':
    if (resultItem.type == ItemType.weapon) affixIds.add('brutal');
    break;
  case 'sea_tear':
    if (resultItem.type == ItemType.armor) affixIds.add('tempered');
    break;
  case 'coalblood':
    affixIds.add('frugal');
    break;
  case 'wisp_light':
    quality = QualityTier.masterwork;
    affixIds = [_rollRandomAffix(resultItem.type), _rollRandomAffix(resultItem.type)];
    break;
}
_inventory = _inventory.removeItem(modifierId, 1);
```

Type-mismatched modifiers (e.g., Hollow Bone in a tool craft) are still consumed but apply no effect. UI warns at queue time with Confirm / Cancel.

### 3.3 Notice spawn engine

```dart
// New file: lib/models/reagent_spawn.dart

class ReagentSpawn {
  final String reagentItemId;
  final String zoneId;
  final String noticeText;
  final SkillType collectionSkill;
  bool collected;
  ReagentSpawn({required this.reagentItemId, required this.zoneId,
    required this.noticeText, required this.collectionSkill, this.collected = false});
}
```

Engine state:

```dart
List<ReagentSpawn> _activeSessionSpawns = [];
```

Spawn generation (called on first `travelTo` per session):

```dart
void _generateSessionSpawns() {
  if (_activeSessionSpawns.isNotEmpty) return;

  final totalLevel = _skills.values.fold<int>(0, (sum, s) => sum + s.level);
  final spawnCount = totalLevel < 30 ? 2 : (totalLevel < 80 ? 3 : 4);

  final eligibleZones = _unlockedZoneIds.where((id) => id != 'town_square').toList();
  if (eligibleZones.isEmpty) return;

  for (int i = 0; i < spawnCount; i++) {
    final zoneId = eligibleZones[_random.nextInt(eligibleZones.length)];
    final spawn = _rollReagentForZone(zoneId);
    if (spawn != null) _activeSessionSpawns.add(spawn);
  }
  log("The world feels alive. ${spawnCount} unusual sightings rumored.", LogType.info);
}

ReagentSpawn? _rollReagentForZone(String zoneId) {
  List<String> pool;
  if (zoneId.startsWith('whispering_woods')) {
    pool = ['moonpetal', 'spirit_sap', 'coalblood'];
  } else if (zoneId.startsWith('darkstone_mine')) {
    pool = ['hollow_bone', 'sea_tear', 'coalblood'];
  } else if (zoneId.startsWith('sundered_coast')) {
    pool = ['sea_tear', 'spirit_sap', 'moonpetal'];
  } else {
    return null;
  }

  String reagentId = _random.nextDouble() < 0.10
    ? 'wisp_light'
    : pool[_random.nextInt(pool.length)];

  return ReagentSpawn(
    reagentItemId: reagentId,
    zoneId: zoneId,
    noticeText: _noticeTextFor(reagentId),
    collectionSkill: _collectionSkillFor(reagentId),
  );
}
```

Notice texts + collection skill mapping per reagent (see spec body for full table).

### 3.4 Collection action

```dart
void collectReagentSpawn(int spawnIndex) {
  if (spawnIndex < 0 || spawnIndex >= _activeSessionSpawns.length) return;
  final spawn = _activeSessionSpawns[spawnIndex];
  if (spawn.collected) return;
  if (_currentZone.id != spawn.zoneId) return;

  final skill = _skills[spawn.collectionSkill];
  if (skill == null || skill.level < 5) {
    log("You don't have the skill to retrieve this. (Requires ${spawn.collectionSkill.name} Lvl 5)", LogType.warning);
    return;
  }
  if (_playerStats.currentEnergy < 5) {
    log("You're too tired. Rest first.", LogType.warning);
    return;
  }
  _playerStats = _playerStats.copyWith(currentEnergy: _playerStats.currentEnergy - 5);

  final reagent = Items.findById(spawn.reagentItemId)!;
  _inventory = _inventory.addItem(reagent, 1);
  spawn.collected = true;

  log("Collected ${reagent.icon} ${reagent.name}!", LogType.success);
  AudioEngine.instance.play('ui_success');
  notifyListeners();
}
```

### 3.5 Notice card UI

Renders at top of zone-action list when current zone has an uncollected spawn. Uses `GameCard` with `accentBorder: DSColors.accent` + subtle pulse animation. Disappears the moment the spawn is collected. Multiple spawns in same zone stack vertically.

### 3.6 Touch summary for §3

| File | Change |
|---|---|
| `lib/models/item.dart` | Add 6 reagents to `Items.all` |
| `lib/models/reagent_spawn.dart` (new) | `ReagentSpawn` class |
| `lib/engine/game_engine.dart` | Add `_activeSessionSpawns`, `_generateSessionSpawns`, `_rollReagentForZone`, `_noticeTextFor`, `_collectionSkillFor`, `collectReagentSpawn`; extend modifier-effect resolution with 6 new cases; call `_generateSessionSpawns` on first `travelTo` per session |
| `lib/views/dashboard_view.dart` | Render Notice card at top of zone actions when current zone has uncollected spawn |
| `lib/views/workshop_view.dart` (or modifier picker location) | Show reagents in modifier slot picker; type-mismatch warning dialog |

---

## 4. Merchant Reputation

### 4.1 Data model

```dart
// In lib/models/shop.dart:

enum ReputationTier { stranger, familiar, trustedPatron, honoredFriend, swornCompanion }

class MerchantReputation {
  final String merchantId;
  int totalRep;
  int sessionRepGained;

  MerchantReputation({required this.merchantId, this.totalRep = 0, this.sessionRepGained = 0});

  ReputationTier get tier {
    if (totalRep >= 12000) return ReputationTier.swornCompanion;
    if (totalRep >= 5000) return ReputationTier.honoredFriend;
    if (totalRep >= 2000) return ReputationTier.trustedPatron;
    if (totalRep >= 500) return ReputationTier.familiar;
    return ReputationTier.stranger;
  }

  int get repForNextTier {
    switch (tier) {
      case ReputationTier.stranger: return 500;
      case ReputationTier.familiar: return 2000;
      case ReputationTier.trustedPatron: return 5000;
      case ReputationTier.honoredFriend: return 12000;
      case ReputationTier.swornCompanion: return 12000;
    }
  }
}
```

### 4.2 Rep gain wiring

```dart
final Map<String, MerchantReputation> _merchantRep = {};
final Set<String> _claimedGifts = {};

MerchantReputation _ensureRep(String merchantId) {
  return _merchantRep.putIfAbsent(merchantId, () => MerchantReputation(merchantId: merchantId));
}

// In existing buyItem (after the buy succeeds):
final rep = _ensureRep(merchant.id);
final repGain = (goldSpent * 2).clamp(0, 200 - rep.sessionRepGained);
if (repGain > 0) {
  rep.totalRep += repGain;
  rep.sessionRepGained += repGain;
  _checkRepTierUp(merchant.id);
}

// In existing sellItem (after the sell succeeds):
final rep = _ensureRep(merchant.id);
final repGain = (goldGained * 1).clamp(0, 200 - rep.sessionRepGained);
if (repGain > 0) {
  rep.totalRep += repGain;
  rep.sessionRepGained += repGain;
  _checkRepTierUp(merchant.id);
}
```

Session cap resets on engine init.

### 4.3 Tier-up handling

```dart
void _checkRepTierUp(String merchantId) {
  final rep = _merchantRep[merchantId]!;
  final newTier = rep.tier;
  final flagId = 'rep_${merchantId}_tier_${newTier.name}';
  if (_engineFlags.contains(flagId)) return;
  _engineFlags.add(flagId);

  switch (newTier) {
    case ReputationTier.familiar:
      log("${_merchantName(merchantId)} now greets you as a Familiar face.", LogType.success);
    case ReputationTier.trustedPatron:
      log("${_merchantName(merchantId)} considers you a Trusted Patron. New stock available.", LogType.success);
      _onTrustedPatronUnlocked(merchantId);
    case ReputationTier.honoredFriend:
      log("${_merchantName(merchantId)} now calls you an Honored Friend. A gift awaits.", LogType.success);
    case ReputationTier.swornCompanion:
      log("${_merchantName(merchantId)} names you Sworn Companion.", LogType.success);
      _onSwornCompanionUnlocked(merchantId);
    case ReputationTier.stranger:
      break;
  }
  AudioEngine.instance.play('ui_success');
  notifyListeners();
}
```

### 4.4 Tier reward table

| Tier | Cedric | Hilda | Pippin | Silas | Maeve | Bram |
|---|---|---|---|---|---|---|
| Stranger | Default | Default | Default | Default | Default | Default |
| Familiar (500) | +1 stock on rotating items | Same | Same | Same | Same | Same |
| Trusted Patron (2000) | 10% disc + **Tinker's Bauble** | 10% + **Weaponsmith's Pattern** | 10% + **Elixir of Twilight** | 10% + **Old Empire Fragment** | 10% + **Quality Affix Unlock** | 10% + **Tavern's Best** |
| Honored Friend (5000) | 20% + random blueprint gift | 20% + rare blueprint gift | 20% + 1 Wisp-Light | 20% + 1 Old Empire fragment | 20% + Fine random tool | 20% + 5 quick-slot foods |
| Sworn Companion (12000) | 30% + "Cedric's Story" fragment | 30% + "Hilda's Story" | 30% + "Pippin's Story" | 30% + "Silas's Story" | 30% + "Maeve's Story" | 30% + "Bram's Story" |

### 4.5 New items for Trusted Patron tier (3 net-new + 3 hook-into-existing)

```dart
// In lib/models/item.dart:

static const Item tinkersBauble = Item(
  id: 'tinkers_bauble', name: "Tinker's Bauble",
  description: "A small clockwork trinket from Cedric's private stock. Used as a crafting modifier — adds +1 to result quantity.",
  icon: '⚙️', type: ItemType.resource, value: 100,
);

static const Item elixirOfTwilight = Item(
  id: 'elixir_of_twilight', name: 'Elixir of Twilight',
  description: "Pippin's signature concoction. Restores 30 HP and 50 energy.",
  icon: '🧪', type: ItemType.food, value: 120, healAmount: 30, energyAmount: 50,
);

static const Item tavernsBest = Item(
  id: 'taverns_best', name: "Tavern's Best",
  description: "Bram's reserve drink. Doesn't restore much, but lifts the spirits. Grants +10% craft speed for 5 actions.",
  icon: '🍺', type: ItemType.food, value: 60, healAmount: 10, energyAmount: 30,
);
```

The other three (Weaponsmith's Pattern, Old Empire Fragment, Quality Affix Unlock) hook into existing concepts: Weaponsmith's Pattern is a blueprint scroll for a Spec 4 spec recipe; Old Empire Fragment grants an Old Empire-tag Codex fragment immediately; Quality Affix Unlock is a one-time consumable that adds a chosen affix to next craft (rolls during implementation if not yet wired).

Tinker's Bauble extends Spec 4's modifier slot: new switch arm `case 'tinkers_bauble': finalQty += 1; break;`.

### 4.6 Honored Friend one-time gifts

```dart
void _claimHonoredFriendGift(String merchantId) {
  if (_claimedGifts.contains(merchantId)) return;
  _claimedGifts.add(merchantId);

  switch (merchantId) {
    case 'cedric': _grantRandomBlueprint();
    case 'hilda': _grantBlueprintByTag('smith');
    case 'pippin': _inventory = _inventory.addItem(Items.wispLight, 1);
    case 'silas': _tryGrantOldEmpireFragment();
    case 'maeve': _grantRandomFineTool();
    case 'bram': _inventory = _inventory.addItem(Items.bakedPotato, 5);
  }
  log("${_merchantName(merchantId)} hands you a parting gift.", LogType.success);
}
```

Triggered via popover on first merchant visit after reaching Honored Friend tier.

### 4.7 Six Sworn Companion fragments

```dart
// In lib/models/codex.dart, add to CodexFragments.all:

CodexFragment(id: 'merchant_cedric', tag: CodexTag.misc, title: "Cedric's Story",
  text: "Cedric's mother ran the cart before he did. She walked all the way from the Old Empire's last city before it fell. He has never told anyone this.",
  sourceHint: "Sworn Companion of Cedric", orderInTag: 1),

CodexFragment(id: 'merchant_hilda', tag: CodexTag.misc, title: "Hilda's Story",
  text: "Hilda forged her first true blade at twelve. Her teacher was burned in the second-to-last forge-fire of the Old Age. She still keeps his hammer.",
  sourceHint: "Sworn Companion of Hilda", orderInTag: 2),

CodexFragment(id: 'merchant_pippin', tag: CodexTag.misc, title: "Pippin's Story",
  text: "Pippin once mixed a draught that brought a dead bird back to life for forty seconds. He has never tried it on anything larger. He never will.",
  sourceHint: "Sworn Companion of Pippin", orderInTag: 3),

CodexFragment(id: 'merchant_silas', tag: CodexTag.misc, title: "Silas's Story",
  text: "Silas can read three dead languages. He learned the first as a child. He learned the second under threat. He learned the third because he wanted to.",
  sourceHint: "Sworn Companion of Silas", orderInTag: 4),

CodexFragment(id: 'merchant_maeve', tag: CodexTag.misc, title: "Maeve's Story",
  text: "Maeve walked the deep woods alone for a year between her sixteenth and seventeenth winters. She has never said what she found there. She came back changed.",
  sourceHint: "Sworn Companion of Maeve", orderInTag: 5),

CodexFragment(id: 'merchant_bram', tag: CodexTag.misc, title: "Bram's Story",
  text: "Bram took over the tavern from his father, who took it from his father. The tavern is older than the town. Bram does not know what is buried beneath the cellar floor. He hopes it stays there.",
  sourceHint: "Sworn Companion of Bram", orderInTag: 6),
```

### 4.8 Discount application

```dart
int displayBuyPrice(ShopListing listing, GameEngine engine, String merchantId) {
  final rep = engine.merchantReputation(merchantId);
  double discount = 0.0;
  switch (rep.tier) {
    case ReputationTier.trustedPatron: discount = 0.10;
    case ReputationTier.honoredFriend: discount = 0.20;
    case ReputationTier.swornCompanion: discount = 0.30;
    default: discount = 0.0;
  }
  final discounted = (listing.effectiveBuyPrice * (1 - discount)).ceil();
  return max(1, discounted);
}
```

Stacks multiplicatively with existing `discountPercent` (daily deals).

### 4.9 Bram — 6th merchant

```dart
static final Merchant bram = Merchant(
  id: 'bram',
  name: 'Bram',
  title: 'The Tavern-Keeper',
  icon: '🍺',
  greetings: [
    "First round's on the house if you've news worth telling.",
    "The fire's hot and the kettle's full. What'll it be?",
    "There's a corner table free. Sit a while.",
    "We hear most things first, here. We just don't always say.",
  ],
  baseListings: [
    ShopListing(item: Items.herbalTea, buyPrice: 14, sellPrice: 5, stock: 8, maxStock: 8, category: ShopCategory.provisions),
    ShopListing(item: Items.spicedTea, buyPrice: 32, sellPrice: 11, stock: 5, maxStock: 5, category: ShopCategory.provisions),
    ShopListing(item: Items.bakedPotato, buyPrice: 10, sellPrice: 3, stock: 12, maxStock: 12, category: ShopCategory.provisions),
    ShopListing(item: Items.smokedTrout, buyPrice: 27, sellPrice: 9, stock: 4, maxStock: 4, category: ShopCategory.provisions),
    ShopListing(item: Items.hotWater, buyPrice: 3, sellPrice: 1, category: ShopCategory.supplies),
  ],
);
```

Bram joins `Merchant.all` (now 6). Bram is permanently accessible via Tavern fixture; also joins existing 2-active-rotation without disrupting it.

### 4.10 UI surfaces

- **Shop rep chip**: `GameChip` + `GameProgressBar` above each merchant's listings, showing tier + progress. Conditional render after first transaction with that merchant.
- **Codex Reputation tab**: new tab between Beasts and Regions. Lists all 6 merchants with tier badges + progress. Tap a card → reward ladder modal. Tab itself only renders when at least one merchant transaction exists.

### 4.11 Touch summary for §4

| File | Change |
|---|---|
| `lib/models/shop.dart` | Add `ReputationTier` + `MerchantReputation`; add Bram merchant; extend `Merchant.all` |
| `lib/models/item.dart` | Add Tinker's Bauble, Elixir of Twilight, Tavern's Best |
| `lib/models/codex.dart` | Add 6 Sworn Companion Misc-tag fragments |
| `lib/engine/game_engine.dart` | Add `_merchantRep` state + helpers (`_ensureRep`, `_checkRepTierUp`, `_onTrustedPatronUnlocked`, `_claimHonoredFriendGift`, `_onSwornCompanionUnlocked`); modify `buyItem`/`sellItem` to grant rep; extend modifier resolution for Tinker's Bauble |
| `lib/views/shop_view.dart` | Render rep chip; apply discount to displayed prices; Trusted Patron unique-item display; Honored Friend gift popover |
| `lib/views/codex_view.dart` | Add Reputation tab (conditional render); reward-ladder modal |

---

## 5. Tavern & Daily Tasks

### 5.1 Tavern fixture

```dart
// Append to townSquare.actions:

ZoneAction(
  id: 'visit_tavern',
  name: 'Visit the Tavern',
  description: 'Bram keeps the kettle hot and the notice board fresh.',
  durationSeconds: 1,
  energyCost: 0,
  requiredSkill: SkillType.wayfinding, requiredLevel: 1,
  xpReward: 0, lootTable: [],
),
```

Visibility (extending `isActionVisible`): `if (actionId == 'visit_tavern') return _engineFlags.contains('town_square_restored');`

Completion handler in `_completeAction` flags `_tavernRequested = true` and notifies; Dashboard listens and pushes `TavernView` route.

### 5.2 TavernView

`lib/views/tavern_view.dart` — full sub-view with 2 tabs (`GameTabs`):

- **Notice Board** — 3 daily task cards + Daily Bonus tracker
- **Bram's Wares** — rep chip + Bram's listings (Buy/Sell)

### 5.3 Daily Task data model

```dart
// New file: lib/models/daily_task.dart

enum DailyTaskCategory { gather, hunt, visit, craft, codex, cleanse }

class DailyTaskTemplate {
  final String id;
  final DailyTaskCategory category;
  final String titleTemplate;
  final String iconHint;
  final ObjectiveKind objectiveKind;
  final List<String> possibleTargetIds;
  final int minQty;
  final int maxQty;
  final int baseGoldReward;
  final int baseSkillXpReward;
  final SkillType? rewardSkill;
  final int minPlayerLevel;
  final bool requiresEngineFlag;
  final String? engineFlagRequired;
  const DailyTaskTemplate({ /* all required + defaults */ });
}

class DailyTask {
  final String templateId;
  final String resolvedTitle;
  final String iconHint;
  final ObjectiveKind objectiveKind;
  final String? targetId;
  final int targetCount;
  int currentCount;
  final int goldReward;
  final int skillXpReward;
  final SkillType? rewardSkill;
  bool claimed;
  bool get isComplete => currentCount >= targetCount;
}
```

### 5.4 30 task templates (5 per category × 6 categories)

Full set defined in spec body. Categories and example templates:

| Category | Examples |
|---|---|
| Gather | gather_oak (5–15 Oak Logs), gather_wildflower (5–12), gather_copper (5–12), gather_willow (5–12 @ lvl 10), gather_iron (3–8 @ lvl 15) |
| Hunt | hunt_boar (2–5), hunt_spider (2–4), hunt_wolf (1–3 @ lvl 10), hunt_troll (1–2 @ lvl 15), hunt_coast (1–3 @ lvl 12, coast_unlocked) |
| Visit | visit_scout, visit_woods_2 (lvl 5), visit_darkstone_2 (lvl 8), visit_coast (lvl 10), visit_t3 (lvl 15) |
| Craft | craft_basic, craft_potion (lvl 5), craft_fine (lvl 8), craft_weapon (lvl 5), craft_salt_cured (lvl 10, coast_unlocked) |
| Codex | codex_read_any, codex_read_three (lvl 5), codex_wilds (lvl 3), codex_stone (lvl 5, first_stone_drop), codex_puzzle_solve (lvl 8) |
| Cleanse | cleanse_any (lvl 15, first_breach_cleansed), cleanse_reagent (lvl 10), cleanse_t3_gather (lvl 15), cleanse_ironbark (lvl 15), cleanse_glinting (lvl 15) |

Each template defines its title template, reward scaling, and engine-flag prerequisites.

### 5.5 Task generation per session

```dart
List<DailyTask> _todaysTasks = [];
bool _dailyBonusClaimed = false;

void _generateTodaysTasks() {
  if (_todaysTasks.isNotEmpty) return;

  final totalLevel = _skills.values.fold<int>(0, (sum, s) => sum + s.level);
  final eligible = DailyTasks.all.where((t) {
    if (t.minPlayerLevel > totalLevel) return false;
    if (t.requiresEngineFlag && !_engineFlags.contains(t.engineFlagRequired!)) return false;
    return true;
  }).toList();

  final picks = <DailyTaskTemplate>[];
  final usedCategories = <DailyTaskCategory>{};

  final first = eligible[_random.nextInt(eligible.length)];
  picks.add(first);
  usedCategories.add(first.category);

  while (picks.length < 3) {
    final candidates = eligible.where((t) => !picks.contains(t) &&
        (usedCategories.length >= 2 || !usedCategories.contains(t.category))).toList();
    if (candidates.isEmpty) break;
    final next = candidates[_random.nextInt(candidates.length)];
    picks.add(next);
    usedCategories.add(next.category);
  }

  for (final template in picks) {
    final qty = template.minQty + _random.nextInt(template.maxQty - template.minQty + 1);
    final targetId = template.possibleTargetIds[_random.nextInt(template.possibleTargetIds.length)];
    final title = template.titleTemplate
      .replaceAll('{qty}', qty.toString())
      .replaceAll('{item}', _itemDisplayName(targetId))
      .replaceAll('{beast}', _beastDisplayName(targetId));
    _todaysTasks.add(DailyTask(
      templateId: template.id,
      resolvedTitle: title,
      iconHint: template.iconHint,
      objectiveKind: template.objectiveKind,
      targetId: targetId == 'any' ? null : targetId,
      targetCount: qty,
      goldReward: template.baseGoldReward,
      skillXpReward: template.baseSkillXpReward,
      rewardSkill: template.rewardSkill,
      claimed: false,
    ));
  }
  _dailyBonusClaimed = false;
}
```

### 5.6 Auto-progression

Daily tasks ride Spec 1's Quest observer pipeline. Extend `_notifyQuestObservers`:

```dart
void _notifyQuestObservers(QuestEvent event) {
  // ... existing quest observer logic ...
  _notifyDailyTaskObservers(event);
}

void _notifyDailyTaskObservers(QuestEvent event) {
  for (final task in _todaysTasks) {
    if (task.isComplete || task.claimed) continue;
    if (_matchesTaskTarget(task, event)) {
      task.currentCount = (task.currentCount + event.count).clamp(0, task.targetCount);
    }
  }
  notifyListeners();
}
```

`_matchesTaskTarget` handles `tag:wilds` syntax for codex tag filter and `any` wildcard.

### 5.7 Claim flow

```dart
void claimDailyTask(String templateId) {
  final task = _todaysTasks.firstWhere((t) => t.templateId == templateId);
  if (!task.isComplete || task.claimed) return;
  task.claimed = true;

  _playerStats = _playerStats.copyWith(gold: _playerStats.gold + task.goldReward);
  if (task.rewardSkill != null) {
    _skills[task.rewardSkill!] = _skills[task.rewardSkill!]!.addXp(task.skillXpReward.toDouble());
  }
  AudioEngine.instance.play('ui_success');
  log("Daily Task complete: ${task.resolvedTitle} (+${task.goldReward} gold)", LogType.success);

  _maybeClaimDailyBonus();
  notifyListeners();
}

void _maybeClaimDailyBonus() {
  if (_dailyBonusClaimed) return;
  if (!_todaysTasks.every((t) => t.claimed)) return;
  _dailyBonusClaimed = true;

  const bonusGold = 120;
  _playerStats = _playerStats.copyWith(gold: _playerStats.gold + bonusGold);
  log("Daily Bonus: all tasks complete! (+$bonusGold gold)", LogType.success);

  if (_random.nextDouble() < 0.05) {
    _grantRandomBlueprint();
    log("A blueprint scroll falls from the rolled notice.", LogType.success);
  }
  AudioEngine.instance.play('ui_levelup_chime');
  notifyListeners();
}
```

### 5.8 Touch summary for §5

| File | Change |
|---|---|
| `lib/models/zone.dart` | Append `visit_tavern` ZoneAction to `townSquare.actions` |
| `lib/models/daily_task.dart` (new) | Enum, template/task classes, 30 templates in `DailyTasks.all` |
| `lib/engine/game_engine.dart` | Add `_todaysTasks`, `_dailyBonusClaimed`, generation/observer/claim/bonus methods; extend `_notifyQuestObservers`; handle `visit_tavern` in `_completeAction`; visibility logic |
| `lib/views/tavern_view.dart` (new) | Full sub-view with 2 tabs (Notice Board + Bram's Wares) |
| `lib/views/dashboard_view.dart` | Listen for tavern open signal; push TavernView route |

---

## 6. Testing, Rollout, & Risks

### 6.1 Test strategy

**`test/durability_test.dart` (new):** InventorySlot durability fields + copyWith; `calculateMaxDurability` per quality + Sturdy affix; decrement per gather (tool only) / per Strike-or-Heavy-Strike (weapon) / per damage-taken (armor); Worn state stat-stripping; low-durability warning fires once per session; both repair paths consume correct cost + restore full durability; repair-with-materials disabled for non-craftable items.

**`test/reagent_test.dart` (new):** 6 reagent items exist; `_generateSessionSpawns` produces correct count per level; per-biome pool respected; Wisp-Light 10% override; collection requires Wayfinding/Herbalism/Mining lvl 5 + 5 energy; spawn cannot be collected twice; modifier-slot effects fire per reagent; type-mismatch consumes modifier but applies no effect.

**`test/reputation_test.dart` (new):** `MerchantReputation.tier` thresholds (0/500/2000/5000/12000); buy +2 / sell +1 rep per gold; session cap 200; tier-up logs message + fires unlock; Honored Friend gift one-time; Sworn Companion grants correct Codex fragment; discount applied at correct percentages; Bram in `Merchant.all`.

**`test/daily_task_test.dart` (new):** 30 templates with unique ids; `_generateTodaysTasks` produces 3 distinct spanning ≥ 2 categories; `minPlayerLevel` and `engineFlagRequired` filters respected; `_notifyDailyTaskObservers` advances on matching events; tag-filtered codex tasks (`tag:wilds`) only advance on Wilds reads; claim grants gold + XP; Daily Bonus fires only when all 3 claimed; `visit_tavern` visibility gated by `town_square_restored`.

**Smoke test (extend `test/quest_engine_test.dart`):** end-to-end Tavern → daily task progress → claim → reputation gain on shop trade → reagent spawn collection → durability decrement on equipped tool gathering action.

### 6.2 Implementation order

Single PR, internally staged. 19 tasks (see spec body for full list). High-level sequence:

1. Items (6 reagents + 3 unique merchant items)
2. Inventory durability extension
3. Durability calculation + craft/purchase stamping
4. Durability decrement wiring (gather, combat)
5. Worn equipment stat-stripping
6. Repair API (materials + gold)
7. Repair UI (Bench + merchant)
8. Reagent spawn engine
9. Notice card UI
10. Reagent modifier effects
11. Reputation engine
12. Bram merchant
13. 6 Sworn Companion Codex fragments
14. Reputation UI (chip + discount + gift modal)
15. Codex Reputation tab
16. Daily task model + 30 templates
17. Daily task engine + observer hook
18. Tavern view
19. Tests interleaved

### 6.3 Migration & compatibility

No save persistence. Existing equipped items get durability lazy-stamped via `calculateMaxDurability` on first slot read. Reagent spawns roll on first travel. Daily tasks generate on first Tavern visit. Reputation starts at 0 for all merchants.

### 6.4 Documentation updates

- `README.md` — extend with "Spec 6a — Living Economy" notes
- Inline `///` doc comments on `_decrementDurability`, `_generateSessionSpawns`, `_checkRepTierUp`, `_generateTodaysTasks`

### 6.5 Risks & deferrals

- **Durability friction across all equipment** — combat AND gathering both tick. Dual-path repair (gold OR materials) hedges. Tune `maxDurability` literals if too punishing.
- **Reagent discoverability** — players who don't browse zones miss spawns. Mitigation: "world feels alive" log at session start; Notice card visually prominent.
- **Reputation 60-session grind to Sworn Companion** — long-term goal by design. May feel inaccessible to short-session players.
- **Bram in 2-active rotation + Tavern fixture** — Bram appears in standard rotation alongside other merchants AND is always-accessible via Tavern. Players see his stock more often than other merchants. Acceptable for the "Tavern is central" feel; tune rotation weighting if balance issue emerges.
- **Daily Bonus blueprint at 5%** — ~1 scroll per 20 full-completion sessions. Keep precious.
- **No persistence reset of session caps** — every app launch resets rep cap, daily tasks, reagent spawns, low-durability warnings. Acceptable; will become a persistence concern in any future save-game spec.
- **Some Trusted Patron items hook into future systems** — Weaponsmith's Pattern + Quality Affix Unlock graceful-degrade if Spec 4 specs not fully wired; Old Empire Fragment works immediately.
- **Deferred to 6b:** Achievements + Titles (Honored Friend / Sworn Companion can hook into future achievement unlocks).
- **Deferred to 6c:** Nexus zone, The Source, credits, NG+ — no entanglement with 6a.

### 6.6 Player walkthrough

A player after 6a ships:

1. Logs in. Existing equipment shows durability bars.
2. Chops oak ~75 times — axe pulses red, warning log fires.
3. Maeve's shop → Repairs section → 8 gold repair. OR Crafting Bench → 1 oak_log + 1 river_clay.
4. Travels to Whispering Woods → pulsing Notice card at top of zone actions: "A faint pale glow among the underbrush. (Wayfinding Lvl 5 · ⚡ 5) [Investigate]"
5. Taps Investigate → Moonpetal added to inventory.
6. Returns to Town Square → "Visit the Tavern" card now visible. Taps it.
7. Tavern opens: Notice Board (3 tasks) + Bram's Wares.
8. Plays day, reads a fragment, completes codex task → claims it.
9. Trades with Hilda — sees rep chip: "Stranger — 47/500 to Familiar". After many sessions, reaches Trusted Patron → her shop stocks a Weaponsmith's Pattern.
10. After ~60 sessions of trade with Bram, reaches Sworn Companion → Bram's Story fragment unlocks in Codex Misc.
11. Crafts a Bronze Sword with a Wisp-Light reagent → guaranteed Masterwork with 2 affixes.

The world feels lived-in: maintenance, rhythm, social investment, surprise rare loot.

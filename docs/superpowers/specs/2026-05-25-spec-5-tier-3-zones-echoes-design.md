# Spec 5 — Tier-3 Zones & Echoes

**Date:** 2026-05-25
**Status:** Approved (pending spec review)
**Parent:** [Echoes from the Deep umbrella vision](2026-05-24-echoes-from-the-deep-vision.md)
**Depends on:** [Spec 1](2026-05-24-spec-1-quest-codex-foundation-design.md), [Spec 2](2026-05-24-spec-2-codex-content-story-design.md), [Spec 3](2026-05-24-spec-3-sundered-coast-biome-design.md), [Spec 4](2026-05-24-spec-4-gameplay-depth-design.md) (all assumed implemented)
**Scope:** Fifth of six sub-specs from the umbrella. Ships the climax content: 2 new Tier-3 zones (Bloomwither Hollow + The Glowing Vein), 3 Echo bosses with 3-phase HP-gated combat using Spec 4's Stance system, 3 Breach Introduction milestone events, 3 Echo Essence items, 3 cleansing actions in Town Square, 3 cleansing ritual narrative trials, 3 Cleansing Token items, 4 new T3 resources (Ironbark Log, Glinting Ore, Corrupted Wildflower, Corrupted Iron Dust). Wires `breach_<tag>_cleansed` + `first_breach_cleansed` flags that gate Source pool, alternate Coast unlock, and Nexus (Spec 6).

---

## 1. Goals & Acceptance Criteria

### 1.1 What Spec 5 ships

- **2 new Tier-3 zones** with full action sets: Bloomwither Hollow (Whispering Woods III) and The Glowing Vein (Darkstone Mine III). Sundered Coast III (Drowned Lighthouse) already exists from Spec 3; Spec 5 wires its Echo + cleansing.
- **3 Echo bosses** — Echo of the Wilds, Echo of the Stone, Echo of the Tide. Each is a 3-phase HP-gated boss fight using Spec 4's Stance combat system with unique phase mechanics (heal-on-hit / damage reduction / accuracy debuff at P2; enrage at P3). All three use the single 👁️ emoji distinguished by color tint.
- **3 Breach Introduction events** — one-time `MilestoneEvent` modals that fire on first T3 zone entry (Bloomwither, Glowing Vein) or on `approach_lamp_room` action (Tide).
- **3 Echo Essence items** — `wilds_echo_essence` 🌿, `stone_echo_essence` 💎, `tide_echo_essence` 🌊. Drop guaranteed on Echo defeat. Used as cleansing gate.
- **3 Town Square cleansing actions** — `burn_wilds_echo_essence`, `burn_stone_echo_essence`, `burn_tide_echo_essence`. Conditional render based on Essence in inventory. Tap consumes Essence + launches ritual.
- **3 Cleansing Ritual trials** — 4-step Masterwork-pattern narrative trials (Burning the Hollow, Quieting the Wound, Lighting the Forgotten Lamp). Two terminal success paths per ritual.
- **3 Cleansing Token items** — `wilds_cleansing_token` 🟢, `stone_cleansing_token` ⚪, `tide_cleansing_token` 🔵. Granted on ritual success. Used as Nexus precondition (Spec 6).
- **`first_breach_cleansed` flag** wired — opens Source-tag pool (Spec 2) + alternate Coast unlock route (Spec 3) + fires `source_pool_opens` milestone.
- **`breach_<tag>_cleansed` flags** wired — reduces Storm chance (Spec 3) + drives `_calculateStormChance`.
- **`nexus_unlockable` flag** wired — set when all 3 breaches cleansed. Spec 6 reads this to gate Nexus zone visibility.
- **2 new beasts beyond Echoes** — none. Corrupted guard beasts are narrative reskins of existing Shadow Wolf (Bloomwither) and Cavern Troll (Glowing Vein) — `beastId` references existing IDs.
- **4 new T3 resources** — Ironbark Log, Glinting Ore, Corrupted Wildflower, Corrupted Iron Dust. Activates Spec 4 sub-specs that reference rare T3 wood/ore.
- **Main quest progression** — Cleanse the Hollow / Vein / Tide quests (offered in Spec 2 with `comingSoon` objectives) become completable. All-three-cleansed offers Main 8 Source Convergence (Spec 6 finishes).
- **4 new MilestoneEvents** — 3 per-breach cleansed celebrations + 1 capstone "all three sealed" event.

### 1.2 What Spec 5 does NOT do

- No Nexus zone (Spec 6)
- No final boss / The Source (Spec 6)
- No credits sequence / Free Mode / NG+ (Spec 6)
- No new Codex fragments — all 50 already exist in Spec 2; Source pool just opens
- No Achievement entries — Spec 6 fills the registry
- No new merchant items, daily tasks, durability, scarce reagents (Spec 6)
- No new beast types beyond the 3 Echoes (reuse Shadow Wolf and Cavern Troll for guard beasts)

### 1.3 Acceptance criteria

A player after Spec 5 ships:

1. Travels to Whispering Woods III for first time → modal Breach Introduction event fires
2. Sees Bloomwither Hollow has 5 actions including new gathering (Fell Ironbark, Pluck Corrupted Wildflower, Read Hollow Plaque, Hunt Corrupted Wolf) + 1 Echo action
3. Engages Echo of the Wilds → 3-phase fight; phase 2 adds heal-on-hit passive; phase 3 enrages
4. Defeats Echo → guaranteed Wilds Echo Essence drop + post-fight narrative directing to Town Square
5. Returns to Town Square → new conditional action visible: **"🔥 Burn the Wilds Echo Essence"**
6. Taps action → 4-step cleansing ritual → completes → Essence consumed → Wilds Cleansing Token added + `breach_wilds_cleansed` flag set + (if first) `first_breach_cleansed` flag set
7. After first cleansing → Source-tag fragments start dropping from T3 zones / Echoes / Omen events; Storm Swell chance reduced on Coast
8. Cleanse the Hollow main quest objectives complete; Cleanse the Vein quest offered next
9. Repeat for Stone (Glowing Vein) and Tide (Drowned Lighthouse — Echo + cleansing newly enabled)
10. After all 3 cleansings → capstone milestone fires; `nexus_unlockable` flag set; Main 8 Source Convergence quest offered with `comingSoon` objectives (awaits Spec 6)

### 1.4 Design principles inherited

- **No art** — single emoji per icon (no dual-emoji); Echoes share 👁️ distinguished by color tint
- **No dual-emoji icons** — all Echo entities use single 👁️ glyph with color-ramp tinting via Spec 7a `DSColors.skillColorRamp(...)`
- **Progressive discovery** — Cleansing actions only visible when Essence in inventory; Echo phase mechanics revealed via combat play not preview UI
- **Thin story spine** — Breach Introduction events are short paragraphs; cleansing rituals are 4-step trials; no quest-giver dialogue trees
- **Systems converse** — Echo combat exercises Spec 4 Stance system; ritual completion sets flags that unlock Spec 2 Source pool, reduce Spec 3 Storm chance, and gate Spec 6 Nexus

---

## 2. Tier-3 Zones & New Resources

### 2.1 Bloomwither Hollow (Whispering Woods III)

**Tier 3.** A twilight grove where corruption manifests visibly — black sap weeps from Ironbarks, soil is threaded with dark roots, the rotted shrine at the center pulses faintly.

| ZoneAction id | Name | Skill | Lvl | Energy | Dur | XP | Loot |
|---|---|---|---|---|---|---|---|
| `fell_ironbark` | Fell Ironbark | Woodcutting | 15 | 12 | 9s | 75 | Ironbark Log (0.65, 1), Oak Log (0.30, 1–2); hazard 0.20 / 12 dmg |
| `pluck_corrupted_bloom` | Pluck Corrupted Wildflower | Herbalism | 15 | 10 | 7s | 65 | Corrupted Wildflower (0.70, 1), Nightshade (0.20, 1); hazard 0.15 / 8 dmg |
| `read_hollow_plaque` | Read the Hollow Plaque | Lore | 12 | 8 | 8s | 70 | Fragment drops (Wilds + Source + Old Empire) — see §4 |
| `hunt_corrupted_wolf` | Hunt the Corrupted Wolf | Combat | 12 | 10 | 7s | 75 | Wolf Pelt (0.70, 1), Corrupted Wildflower (0.30, 1); `isCombat: true`, `beastId: 'shadow_wolf'` (existing, narratively reskinned) |
| `hunt_echo_of_wilds` | Hunt the Echo of the Wilds | Combat | 15 | 18 | 12s | 200 | Wilds Echo Essence (1.0, 1), Ironbark Log (0.50, 1–2), Wolf Pelt (0.40, 1); `isCombat: true`, `beastId: 'echo_of_wilds'` |

### 2.2 The Glowing Vein (Darkstone Mine III)

**Tier 3.** A deep cavern where corruption has crystallized into a pulsing lens of stone. The foreman's lantern still hangs unlit at the entrance.

| ZoneAction id | Name | Skill | Lvl | Energy | Dur | XP | Loot |
|---|---|---|---|---|---|---|---|
| `mine_glinting_ore` | Mine the Glinting Ore | Mining | 15 | 12 | 9s | 75 | Glinting Ore (0.65, 1), Iron Ore (0.40, 1–2); hazard 0.20 / 12 dmg |
| `sift_iron_dust` | Sift Corrupted Iron Dust | Mining | 15 | 10 | 7s | 65 | Corrupted Iron Dust (0.70, 1), Iron Ore (0.30, 1); hazard 0.15 / 8 dmg |
| `read_vein_glyph` | Read the Vein Glyph | Lore | 12 | 8 | 8s | 70 | Fragment drops (Stone + Source + Old Empire) |
| `slay_corrupted_troll` | Slay the Corrupted Troll | Combat | 12 | 12 | 8s | 100 | Troll Claw (0.70, 1), Corrupted Iron Dust (0.30, 1); `isCombat: true`, `beastId: 'cavern_troll'` |
| `hunt_echo_of_stone` | Hunt the Echo of the Stone | Combat | 15 | 20 | 14s | 220 | Stone Echo Essence (1.0, 1), Glinting Ore (0.50, 1–2), Troll Claw (0.40, 1); `isCombat: true`, `beastId: 'echo_of_stone'` |

### 2.3 Sundered Coast III (Drowned Lighthouse) — Spec 5 additions

Coast III already exists from Spec 3 with `scavenge_lamp_room`, `brave_drowned_cellar`, `read_lighthouse_plaque`, `approach_lamp_room`. Spec 5 adds:

| ZoneAction id | Name | Skill | Lvl | Energy | Dur | XP | Loot |
|---|---|---|---|---|---|---|---|
| `hunt_echo_of_tide` | Hunt the Echo of the Tide | Combat | 15 | 20 | 14s | 220 | Tide Echo Essence (1.0, 1), Pearl Shell (0.50, 1–2), Salt-Touched Skin (0.40, 1); `isCombat: true`, `beastId: 'echo_of_tide'` |

The Spec 3 placeholder `approach_lamp_room` action becomes wired in Spec 5: tapping it sets `drowned_lighthouse_spoken` flag, which fires the Tide Breach Introduction milestone. From then on, `hunt_echo_of_tide` appears in the Coast III action list.

### 2.4 New beasts (just the 3 Echoes)

All Echoes use single `👁️` icon distinguished by color tint at render time using `DSColors.skillColorRamp` per parent biome (Wilds = woodcuttingBase, Stone = miningBase, Tide = wayfindingBase).

```dart
// In lib/models/beast.dart:

// Define the shared ability constant first so it can be referenced by all phases:
static const BeastAbility _strangleVines = BeastAbility(
  id: 'strangle_vines',
  name: 'Strangle Vines',
  cooldownRounds: 3,
  telegraphText: 'Roots burst around your feet.',
  effect: BeastSpecialEffect.drainOverTime,
);

static const Beast echoOfWilds = Beast(
  id: 'echo_of_wilds',
  name: 'Echo of the Wilds',
  icon: '👁️',
  maxHealth: 240,
  attackPower: 18,
  defense: 4,
  xpReward: 280,
  lootTable: [
    LootDrop(item: Items.wildsEchoEssence, chance: 1.0, minQuantity: 1, maxQuantity: 1),
    LootDrop(item: Items.ironbarkLog, chance: 0.50, minQuantity: 1, maxQuantity: 2),
    LootDrop(item: Items.wolfPelt, chance: 0.40, minQuantity: 1, maxQuantity: 1),
  ],
  ability: _strangleVines,
  phases: [
    EchoPhase(hpThreshold: 1.0, ability: _strangleVines, entryNarration: 'You face the Echo of the Wilds.', passive: BeastPassive.none),
    EchoPhase(hpThreshold: 0.66, ability: _strangleVines, entryNarration: 'The Echo trembles — vines knit closed its wounds. It heals as it fights.', passive: BeastPassive.healOnHit),
    EchoPhase(hpThreshold: 0.33, ability: _strangleVines, entryNarration: 'The Hollow itself rises against you. The Echo will not slow.', passive: BeastPassive.enrage),
  ],
);

static const BeastAbility _quake = BeastAbility(
  id: 'quake',
  name: 'Quake',
  cooldownRounds: 3,
  telegraphText: 'The cavern wall groans.',
  effect: BeastSpecialEffect.bigHitStun,
);

static const Beast echoOfStone = Beast(
  id: 'echo_of_stone',
  name: 'Echo of the Stone',
  icon: '👁️',
  maxHealth: 280,
  attackPower: 16,
  defense: 8,
  xpReward: 320,
  lootTable: [
    LootDrop(item: Items.stoneEchoEssence, chance: 1.0, minQuantity: 1, maxQuantity: 1),
    LootDrop(item: Items.glintingOre, chance: 0.50, minQuantity: 1, maxQuantity: 2),
    LootDrop(item: Items.trollClaw, chance: 0.40, minQuantity: 1, maxQuantity: 1),
  ],
  ability: _quake,
  phases: [
    EchoPhase(hpThreshold: 1.0, ability: _quake, entryNarration: 'You face the Echo of the Stone.', passive: BeastPassive.none),
    EchoPhase(hpThreshold: 0.66, ability: _quake, entryNarration: "The Echo's surface hardens to crystal. Your blade rings dull.", passive: BeastPassive.damageReduction),
    EchoPhase(hpThreshold: 0.33, ability: _quake, entryNarration: "The cavern wall pulses with the Echo's heartbeat. It will not be slowed.", passive: BeastPassive.enrage),
  ],
);

static const BeastAbility _stormShroud = BeastAbility(
  id: 'storm_shroud',
  name: 'Storm Shroud',
  cooldownRounds: 3,
  telegraphText: 'The fog thickens. You lose the lamp.',
  effect: BeastSpecialEffect.accuracyDebuff,
);

static const Beast echoOfTide = Beast(
  id: 'echo_of_tide',
  name: 'Echo of the Tide',
  icon: '👁️',
  maxHealth: 260,
  attackPower: 17,
  defense: 5,
  xpReward: 300,
  lootTable: [
    LootDrop(item: Items.tideEchoEssence, chance: 1.0, minQuantity: 1, maxQuantity: 1),
    LootDrop(item: Items.pearlShell, chance: 0.50, minQuantity: 1, maxQuantity: 2),
    LootDrop(item: Items.saltTouchedPelt, chance: 0.40, minQuantity: 1, maxQuantity: 1),
  ],
  ability: _stormShroud,
  phases: [
    EchoPhase(hpThreshold: 1.0, ability: _stormShroud, entryNarration: 'You face the Echo of the Tide.', passive: BeastPassive.none),
    EchoPhase(hpThreshold: 0.66, ability: _stormShroud, entryNarration: 'The fog thickens around the Echo. You can barely see your own hands.', passive: BeastPassive.reducedAccuracy),
    EchoPhase(hpThreshold: 0.33, ability: _stormShroud, entryNarration: 'The Drowned rise from the surf. The Echo summons its kin.', passive: BeastPassive.enrage),
  ],
);
```

`Beasts.all` extends with `echoOfWilds, echoOfStone, echoOfTide`.

### 2.5 New resources (4 items)

```dart
// In lib/models/item.dart:

static const Item ironbarkLog = Item(
  id: 'ironbark_log',
  name: 'Ironbark Log',
  description: 'A log of true Ironbark, rare and impossibly hard. Sought by master weaponsmiths.',
  icon: '🪵',
  type: ItemType.resource,
  value: 50,
);

static const Item glintingOre = Item(
  id: 'glinting_ore',
  name: 'Glinting Ore',
  description: 'A pulsing chunk of stone that glows faintly without flame. Heavier than it should be.',
  icon: '💎',
  type: ItemType.resource,
  value: 55,
);

static const Item corruptedWildflower = Item(
  id: 'corrupted_wildflower',
  name: 'Corrupted Wildflower',
  description: 'A bluebell veined with black sap. Smells of old iron. Useful as a crafting modifier.',
  icon: '🪻',
  type: ItemType.resource,
  value: 30,
);

static const Item corruptedIronDust = Item(
  id: 'corrupted_iron_dust',
  name: 'Corrupted Iron Dust',
  description: 'A fine glittering dust skimmed from the Glinting wall. Pungent. Used as a crafting modifier.',
  icon: '🧂',
  type: ItemType.resource,
  value: 35,
);
```

All 4 appended to `Items.all`. Activates Spec 4 sub-specs (Heartwood-Reader, Vein-Hunter) that reference rare T3 wood/ore.

### 2.6 Echo Essence items (3 items)

Each uses a distinct biome-themed single emoji (not the eye — the eye is reserved for the Echo entity itself).

```dart
static const Item wildsEchoEssence = Item(
  id: 'wilds_echo_essence',
  name: 'Wilds Echo Essence',
  description: 'A pulsing green mote you tore from the Echo of the Wilds. Carry it to the Town Center and burn it.',
  icon: '🌿',
  type: ItemType.resource,
  value: 0,
);

static const Item stoneEchoEssence = Item(
  id: 'stone_echo_essence',
  name: 'Stone Echo Essence',
  description: 'A cold crystalline mote you wrested from the Echo of the Stone. Carry it to the Town Center and burn it.',
  icon: '💎',
  type: ItemType.resource,
  value: 0,
);

static const Item tideEchoEssence = Item(
  id: 'tide_echo_essence',
  name: 'Tide Echo Essence',
  description: 'A briny pulsing mote you pulled from the Echo of the Tide. Carry it to the Town Center and burn it.',
  icon: '🌊',
  type: ItemType.resource,
  value: 0,
);
```

### 2.7 Cleansing Token items (3 items)

```dart
static const Item wildsCleansingToken = Item(
  id: 'wilds_cleansing_token',
  name: 'Wilds Cleansing Token',
  description: 'A small carved seed-shape, warm to the touch. Proof that the Wilds breach is sealed.',
  icon: '🟢',
  type: ItemType.resource,
  value: 0,
);

static const Item stoneCleansingToken = Item(
  id: 'stone_cleansing_token',
  name: 'Stone Cleansing Token',
  description: 'A smooth stone disc, cold and silent. Proof that the Stone breach is sealed.',
  icon: '⚪',
  type: ItemType.resource,
  value: 0,
);

static const Item tideCleansingToken = Item(
  id: 'tide_cleansing_token',
  name: 'Tide Cleansing Token',
  description: 'A salt-crusted shell-fragment that hums quietly. Proof that the Tide breach is sealed.',
  icon: '🔵',
  type: ItemType.resource,
  value: 0,
);
```

### 2.8 Touch summary for §2

| File | Change |
|---|---|
| `lib/models/zone.dart` | Add `whisperingWoodsTier3` (Bloomwither Hollow) + `darkstoneMineTier3` (Glowing Vein) zone constants with full action lists; wire `approach_lamp_room` in Coast III to set `drowned_lighthouse_spoken` flag; add `hunt_echo_of_tide` to Coast III |
| `lib/models/beast.dart` | Extend `Beast` with `phases` field; add `EchoPhase` class + `BeastPassive` enum; add 3 Echo beasts to `Beasts.all` |
| `lib/models/item.dart` | Add 4 T3 resources + 3 Echo Essences + 3 Cleansing Tokens (10 new items); extend `Items.all` |

---

## 3. Echo Phase Mechanics & Breach Introductions

### 3.1 Phase-gated boss combat

```dart
// In lib/models/beast.dart:

enum BeastPassive {
  none,
  healOnHit,
  damageReduction,
  reducedAccuracy,
  enrage,
}

class EchoPhase {
  final double hpThreshold;
  final BeastAbility ability;
  final String entryNarration;
  final BeastPassive? passive;

  const EchoPhase({
    required this.hpThreshold,
    required this.ability,
    required this.entryNarration,
    this.passive,
  });
}

class Beast {
  // existing fields...
  final List<EchoPhase>? phases;        // NEW — null for regular beasts; populated for Echoes
}
```

### 3.2 Phase definitions per Echo

| Echo | P1 (100% → 66%) | P2 (66% → 33%) | P3 (33% → 0%) |
|---|---|---|---|
| Wilds | Strangle Vines (drainOverTime) | + `healOnHit`: regen 3 HP/round | + `enrage`: cooldown 3 → 2 |
| Stone | Quake (bigHitStun) | + `damageReduction`: incoming −25% | + `enrage` |
| Tide | Storm Shroud (accuracyDebuff) | + `reducedAccuracy`: crit halved | + `enrage` |

### 3.3 Engine resolution

New `CombatState` fields:
```dart
int activePhaseIndex;             // -1 = no phases yet entered
BeastAbility? activePhaseAbility;
BeastPassive? activePhasePassive;
```

New helper in `GameEngine`:
```dart
void _checkEchoPhaseTransition() {
  if (_activeCombat == null) return;
  final beast = _activeCombat!.beast;
  if (beast.phases == null) return;

  final hpPct = _activeCombat!.beastCurrentHealth / beast.maxHealth;
  EchoPhase? currentPhase;
  for (final phase in beast.phases!) {
    if (hpPct <= phase.hpThreshold) {
      currentPhase = phase;
    }
  }
  if (currentPhase == null) return;

  if (_activeCombat!.activePhaseIndex != beast.phases!.indexOf(currentPhase)) {
    final newIndex = beast.phases!.indexOf(currentPhase);
    _activeCombat = _activeCombat!.copyWith(
      activePhaseIndex: newIndex,
      activePhaseAbility: currentPhase.ability,
      activePhasePassive: currentPhase.passive,
    );
    log(currentPhase.entryNarration, LogType.warning);
    playSfx('ui_info_chime');
  }
}
```

Called from `_resolveCombatRound` after damage is applied to beast.

### 3.4 Passive effect resolution

In `_resolveCombatRound`:

```dart
// healOnHit (Wilds P2)
if (_activeCombat!.activePhasePassive == BeastPassive.healOnHit) {
  final healed = (_activeCombat!.beastCurrentHealth + 3).clamp(0, beast.maxHealth);
  _activeCombat = _activeCombat!.copyWith(beastCurrentHealth: healed);
  log("The Echo healed 3 HP.", LogType.info);
}

// damageReduction (Stone P2) — applied in damage calc:
if (_activeCombat!.activePhasePassive == BeastPassive.damageReduction) {
  playerDmgDealt = (playerDmgDealt * 0.75).round();
}

// reducedAccuracy (Tide P2) — applied in crit chance:
if (_activeCombat!.activePhasePassive == BeastPassive.reducedAccuracy) {
  critChance *= 0.5;
}

// enrage (P3) — reduce cooldownRounds:
final effectiveCooldown = (_activeCombat!.activePhasePassive == BeastPassive.enrage)
    ? max(1, ability.cooldownRounds - 1)
    : ability.cooldownRounds;
```

The combat-log entry `"The Echo healed 3 HP."` is explicit so players notice the passive even if HP bar tweens smoothly via Spec 7a.

### 3.5 Breach Introduction events

3 new `MilestoneEvent` entries.

```dart
static final MilestoneEvent bloomwitherEntered = MilestoneEvent(
  id: 'bloomwither_entered',
  severity: MilestoneSeverity.major,
  title: 'The Hollow Speaks',
  body: 'The trees here stand wrong, and a deeper wrong watches from the heart of the hollow. The Warden\'s old advice runs through your mind — an Ironbark log, well-seasoned, and three Wildflowers cut at first light, burned at the rotted shrine within. But first: what waits in the Hollow will not let you near without a fight. Defeat it. Wrest its essence. Return to Town Square and burn the essence at the town center. That is how a Breach is sealed.',
  icon: '🌿',
  trigger: (engine) => engine.regionStatus.containsKey('whispering_woods_3'),
  onFire: null,
);

static final MilestoneEvent glowingVeinEntered = MilestoneEvent(
  id: 'glowing_vein_entered',
  severity: MilestoneSeverity.major,
  title: 'The Vein Pulses',
  body: 'The Glinting Vein is no vein — it is a wound. The foreman\'s last writing speaks of an alchemist\'s draught — wildflower tinctured with river clay, twice-distilled — that calms the pulse. The thing inside the wound will rise to defend it. Endure the rising. Then carry the wound\'s essence home, and burn it at the town center.',
  icon: '💎',
  trigger: (engine) => engine.regionStatus.containsKey('darkstone_mine_3'),
  onFire: null,
);

static final MilestoneEvent drownedLighthouseSpoken = MilestoneEvent(
  id: 'drowned_lighthouse_spoken',
  severity: MilestoneSeverity.major,
  title: 'The Lamp Speaks',
  body: 'You climb the lighthouse stairs. The lamp room is silent — but not empty. The keeper\'s last page warned you: do not relight the lamp with oil; carry a Salt Crystal — the pure kind from the deep tide pools — and set it within the lamp\'s heart. Something old in the sea will rise to silence the song. Do not let it. When you have its essence, carry it home and burn it at the town center.',
  icon: '🌊',
  trigger: (engine) => engine.engineFlags.contains('drowned_lighthouse_spoken'),
  onFire: null,
);
```

Coast III's `approach_lamp_room` action `_completeAction` handler sets `engineFlags.add('drowned_lighthouse_spoken')` (replacing the Spec 3 placeholder behavior).

### 3.6 Post-Echo-defeat narrative

```dart
// In _onBeastDefeated or _resolveCombat end-of-fight branch:
if (beast.id == 'echo_of_wilds') {
  log("The Echo collapses into a brittle husk. A green mote pulses where its heart was — you pluck it free. Carry it home. Burn it where the cartographer keeps his fire.", LogType.worldEvent);
  playSfx('ui_masterwork_complete');
}
if (beast.id == 'echo_of_stone') {
  log("The Echo cracks open like a geode. A cold crystalline mote slides into your palm. Carry it home. Burn it at the town center.", LogType.worldEvent);
  playSfx('ui_masterwork_complete');
}
if (beast.id == 'echo_of_tide') {
  log("The Echo recedes into the surf, leaving a briny mote behind that pulses faintly in your hand. Carry it home. Burn it at the town center.", LogType.worldEvent);
  playSfx('ui_masterwork_complete');
}
```

The Essence drop happens via the normal loot table (guaranteed 1.0 chance).

---

## 4. Cleansing Actions, Ritual Trials & Flag Wiring

### 4.1 Town Center burn actions

3 conditional ZoneActions appended to `townSquare.actions`:

```dart
ZoneAction(
  id: 'burn_wilds_echo_essence',
  name: 'Burn the Wilds Echo Essence',
  description: 'Take the Essence to the Town Center fire and let it consume itself.',
  durationSeconds: 6,
  energyCost: 8,
  requiredSkill: SkillType.lore,
  requiredLevel: 1,
  xpReward: 100,
  lootTable: [],
),
ZoneAction(
  id: 'burn_stone_echo_essence',
  name: 'Burn the Stone Echo Essence',
  description: 'Take the Essence to the Town Center fire and let it consume itself.',
  durationSeconds: 6,
  energyCost: 8,
  requiredSkill: SkillType.lore,
  requiredLevel: 1,
  xpReward: 100,
  lootTable: [],
),
ZoneAction(
  id: 'burn_tide_echo_essence',
  name: 'Burn the Tide Echo Essence',
  description: 'Take the Essence to the Town Center fire and let it consume itself.',
  durationSeconds: 6,
  energyCost: 8,
  requiredSkill: SkillType.lore,
  requiredLevel: 1,
  xpReward: 100,
  lootTable: [],
),
```

Visibility logic (extending `isActionVisible`):

```dart
if (actionId == 'burn_wilds_echo_essence') return _inventory.hasItem('wilds_echo_essence', 1);
if (actionId == 'burn_stone_echo_essence') return _inventory.hasItem('stone_echo_essence', 1);
if (actionId == 'burn_tide_echo_essence') return _inventory.hasItem('tide_echo_essence', 1);
```

`_completeAction` for burn actions consumes the Essence and launches the ritual:

```dart
if (action.id == 'burn_wilds_echo_essence') {
  _inventory = _inventory.removeItem('wilds_echo_essence', 1);
  _startCleansingRitual('wilds');
  return;
}
if (action.id == 'burn_stone_echo_essence') {
  _inventory = _inventory.removeItem('stone_echo_essence', 1);
  _startCleansingRitual('stone');
  return;
}
if (action.id == 'burn_tide_echo_essence') {
  _inventory = _inventory.removeItem('tide_echo_essence', 1);
  _startCleansingRitual('tide');
  return;
}
```

### 4.2 The 3 Cleansing Ritual trials

#### 4.2.1 Wilds Cleansing — *Burning the Hollow*

```dart
static final MasterworkTask cleansingWilds = MasterworkTask(
  id: 'cleansing_wilds',
  skillType: SkillType.lore,
  levelGate: 1,
  title: 'Burning the Hollow',
  description: 'The Wilds Echo Essence sits in the Town Center fire. The flame won\'t take. The cartographer watches.',
  startStepId: 'start',
  steps: {
    'start': MasterworkStep(
      id: 'start',
      prompt: 'The Essence won\'t catch. The cartographer hands you a thin bundle of dry kindling. "You\'ll need to speak to it. The Wilds want a word, not an offering. Make a name for the place."',
      options: [
        MasterworkOption(
          text: 'Name the Hollow as the Warden named it in her last journal.',
          nextStepId: 'wardens_name',
          requiredSkill: SkillType.lore,
          requiredLevel: 5,
          feedback: 'You speak the name the Warden wrote in her last entry. The Essence flares green.',
        ),
        MasterworkOption(
          text: 'Name the Hollow yourself, in your own tongue.',
          nextStepId: 'own_name',
          feedback: 'You speak a name of your own choosing. The Essence smolders, uncertain.',
        ),
      ],
    ),
    'wardens_name': MasterworkStep(
      id: 'wardens_name',
      prompt: 'The Essence burns clean, green-gold. The Hollow speaks once, softly, in a voice you almost recognize. Then silence.',
      options: [
        MasterworkOption(
          text: 'Take what remains from the ashes.',
          isSuccess: true,
          energyCost: 8,
          feedback: 'A small carved seed-shape sits in the ash, warm to the touch. The Wilds Breach is sealed.',
        ),
      ],
    ),
    'own_name': MasterworkStep(
      id: 'own_name',
      prompt: 'The Essence burns dim. Your name does not catch. The cartographer murmurs the Warden\'s name; the flame catches at last.',
      options: [
        MasterworkOption(
          text: 'Take what remains from the ashes.',
          isSuccess: true,
          energyCost: 10,
          feedback: 'A small carved seed-shape sits in the ash, warm to the touch. The Wilds Breach is sealed — though the cartographer notes the name to remember next time.',
        ),
      ],
    ),
  },
);
```

#### 4.2.2 Stone Cleansing — *Quieting the Wound*

```dart
static final MasterworkTask cleansingStone = MasterworkTask(
  id: 'cleansing_stone',
  skillType: SkillType.lore,
  levelGate: 1,
  title: 'Quieting the Wound',
  description: 'The Stone Echo Essence sits in the Town Center fire. It hums in your hand, three slow taps, three slow taps. The cartographer covers his ears.',
  startStepId: 'start',
  steps: {
    'start': MasterworkStep(
      id: 'start',
      prompt: 'The Essence won\'t burn. It taps against the iron bowl, three then three. The cartographer hands you a small lead bell. "Strike the bell on the off-beats. Drown out the rhythm. Then it will burn."',
      options: [
        MasterworkOption(
          text: 'Strike the bell on the silences between the taps.',
          nextStepId: 'silence_match',
          feedback: 'You ring on the half-beats. The Essence\'s rhythm falters, then breaks. The flame takes.',
        ),
        MasterworkOption(
          text: 'Ring the bell continuously to drown the taps entirely.',
          nextStepId: 'continuous_ring',
          energyCost: 12,
          feedback: 'You ring without pause. The cavern in your mind goes dark. The flame catches; you ring until your arms ache.',
        ),
      ],
    ),
    'silence_match': MasterworkStep(
      id: 'silence_match',
      prompt: 'The Essence burns cool blue, then grey. The taps stop. You hear, for the first time in weeks, the sound of your own pulse.',
      options: [
        MasterworkOption(
          text: 'Take what remains from the ashes.',
          isSuccess: true,
          energyCost: 6,
          feedback: 'A smooth stone disc sits in the cooling ash, cold and silent. The Stone Breach is sealed.',
        ),
      ],
    ),
    'continuous_ring': MasterworkStep(
      id: 'continuous_ring',
      prompt: 'The Essence burns through. The taps stop, finally. You realize you are still ringing the bell. You set it down.',
      options: [
        MasterworkOption(
          text: 'Take what remains from the ashes.',
          isSuccess: true,
          energyCost: 8,
          feedback: 'A smooth stone disc sits in the ash. You\'re exhausted but the Stone Breach is sealed.',
        ),
      ],
    ),
  },
);
```

#### 4.2.3 Tide Cleansing — *Lighting the Forgotten Lamp*

```dart
static final MasterworkTask cleansingTide = MasterworkTask(
  id: 'cleansing_tide',
  skillType: SkillType.lore,
  levelGate: 1,
  title: 'Lighting the Forgotten Lamp',
  description: 'The Tide Echo Essence sits in the Town Center fire. It will not burn; it weeps brine. The cartographer brings out an old keeper\'s lamp.',
  startStepId: 'start',
  steps: {
    'start': MasterworkStep(
      id: 'start',
      prompt: 'The cartographer sets the lamp beside the Essence. "The Keeper\'s notes said the lamp sang a note that kept the wrong things at bay. The Essence will burn only if you can light the lamp and sing that note. But the note has been forgotten."',
      options: [
        MasterworkOption(
          text: 'Recall the Keeper\'s description and hum the note from memory.',
          nextStepId: 'memory_note',
          requiredSkill: SkillType.lore,
          requiredLevel: 5,
          feedback: 'You hum a long low note. The lamp catches; the Essence catches with it.',
        ),
        MasterworkOption(
          text: 'Let the Essence guide your voice — sing what it wants you to sing.',
          nextStepId: 'guided_note',
          energyCost: 10,
          feedback: 'You open your throat and let the Essence pull the note out of you. It is not your voice; you are not entirely sure it stops being your voice afterward.',
        ),
      ],
    ),
    'memory_note': MasterworkStep(
      id: 'memory_note',
      prompt: 'The lamp burns steady. The Essence burns with it, brine-blue. The note holds. The cartographer dabs his eyes.',
      options: [
        MasterworkOption(
          text: 'Take what remains from the ashes.',
          isSuccess: true,
          energyCost: 6,
          feedback: 'A salt-crusted shell-fragment sits in the ash, humming quietly. The Tide Breach is sealed.',
        ),
      ],
    ),
    'guided_note': MasterworkStep(
      id: 'guided_note',
      prompt: 'The lamp burns. The Essence burns. The note holds. You stop singing eventually. The cartographer hands you a cup of water.',
      options: [
        MasterworkOption(
          text: 'Take what remains from the ashes.',
          isSuccess: true,
          energyCost: 12,
          feedback: 'A salt-crusted shell-fragment sits in the ash, humming quietly. The Tide Breach is sealed.',
        ),
      ],
    ),
  },
);
```

All 3 added to `MasterworkTasks.all` and `MasterworkTasks.findById`.

### 4.3 Ritual success handler

```dart
void _onCleansingComplete(String breachTag) {
  // 1. Set breach flag
  setEngineFlag('breach_${breachTag}_cleansed');

  // 2. First-breach side effect
  if (!_engineFlags.contains('first_breach_cleansed')) {
    setEngineFlag('first_breach_cleansed');
  }

  // 3. Grant Cleansing Token
  final tokenId = '${breachTag}_cleansing_token';
  final token = Items.findById(tokenId);
  if (token != null) {
    _inventory = _inventory.addItem(token, 1);
  }

  // 4. Advance Cleanse main quest objective
  for (final quest in _activeQuests) {
    for (final obj in quest.objectives) {
      if (obj.kind == ObjectiveKind.cleanse && obj.targetId == 'breach_$breachTag') {
        obj.currentCount = obj.targetCount;
        obj.comingSoon = false;
      }
    }
    _maybeCompleteQuest(quest);
  }

  // 5. All-three-cleansed offers Main 8
  if (_engineFlags.contains('breach_wilds_cleansed') &&
      _engineFlags.contains('breach_stone_cleansed') &&
      _engineFlags.contains('breach_tide_cleansed')) {
    if (!_activeQuests.any((q) => q.id == 'main_source_convergence') &&
        !_completedQuests.any((q) => q.id == 'main_source_convergence')) {
      offerQuest(MainQuests.sourceConvergence());
    }
  }

  playSfx('ui_masterwork_complete');
  notifyListeners();
}
```

Modify `_onMasterworkSuccess` to dispatch cleansings:

```dart
void _onMasterworkSuccess(MasterworkRunState run, MasterworkOption terminalOption) {
  final task = run.task;

  // Detect cleansing ritual — bypass cap-unlock logic
  if (task.id.startsWith('cleansing_')) {
    _onCleansingComplete(task.id.substring('cleansing_'.length));
    return;
  }

  // Existing: unlock cap, record spec, etc.
  // ... existing logic from Spec 4 ...
}
```

### 4.4 Cleansing milestone events

4 new MilestoneEvents added to `Milestones.all`:

| id | Trigger | Severity | Body |
|---|---|---|---|
| `breach_wilds_cleansed_milestone` | `breach_wilds_cleansed` flag | major | "The forest hush returns. Birds are singing in the eastern groves for the first time in months. The Warden's gate has opened on its own." |
| `breach_stone_cleansed_milestone` | `breach_stone_cleansed` flag | major | "The tapping stops in your dreams. The foreman is found, alive, sitting at the lip of the deepest shaft. He does not remember the year. He cries when he sees the sun." |
| `breach_tide_cleansed_milestone` | `breach_tide_cleansed` flag | major | "The Lighthouse lamp lights itself at dusk. The Drowned are gone from the pier. The salt smells like salt again." |
| `all_breaches_cleansed_milestone` | All 3 breach flags set | major | "Town Square's bells ring without being struck. Somewhere, a stone door opens beneath the world. The cartographer hands you a key you have never seen before." (onFire: sets `nexus_unlockable` flag) |

The existing Spec 2 `source_pool_opens` milestone is already wired to `first_breach_cleansed`. Spec 5 just ensures the flag gets set; the milestone fires automatically.

### 4.5 Flag cascade summary

When the first breach is cleansed:
- `breach_<tag>_cleansed` flag → biome-specific milestone fires
- `first_breach_cleansed` flag →
  - Spec 2's `source_pool_opens` milestone fires
  - Spec 2's `_isFragmentPoolOpen(CodexTag.source)` returns true → Source fragments drop
  - Spec 3's alternate Coast unlock path activates (if not yet unlocked)
  - Spec 3's `_calculateStormChance` removes that tag from breach-count, reducing Storm chance

When all three breaches are cleansed:
- `all_breaches_cleansed_milestone` fires
- `nexus_unlockable` flag set → Spec 6 gates Nexus visibility on this + presence of all 3 Cleansing Tokens

### 4.6 Touch summary for §4

| File | Change |
|---|---|
| `lib/models/zone.dart` | Append 3 conditional burn actions to `townSquare.actions` |
| `lib/models/masterwork.dart` | Add 3 cleansing ritual `MasterworkTask` constants; extend `MasterworkTasks.all` / `findById` |
| `lib/models/milestone.dart` | Add 4 new milestone events (3 per-breach + 1 capstone) + 3 Breach Introduction milestones (Bloomwither, Glowing Vein, Drowned Lighthouse) |
| `lib/engine/game_engine.dart` | Extend `isActionVisible` for 3 burn actions; extend `_completeAction` to consume Essence + launch ritual on burn actions; add `_startCleansingRitual` + `_onCleansingComplete`; modify `_onMasterworkSuccess` to detect cleansings and bypass cap-unlock logic |

---

## 5. Testing, Rollout, & Risks

### 5.1 Test strategy

#### Echo combat tests (`test/echo_combat_test.dart` — new)

- Each Echo has `phases` populated (3 entries) with distinct entry narrations
- Phase transition fires when beast HP drops below threshold:
  - At `hpPct == 0.66` → phase 2 activates → log shows P2 narration
  - At `hpPct == 0.33` → phase 3 activates → log shows P3 narration
- Wilds Echo P2 `healOnHit`: beast HP regenerates 3 per round during P2 only
- Stone Echo P2 `damageReduction`: player damage 75% of normal during P2
- Tide Echo P2 `reducedAccuracy`: crit chance halved during P2
- P3 `enrage`: telegraph cooldown drops 3 → 2
- Echo defeat fires Essence drop (guaranteed) + post-fight log entry

#### Cleansing flow tests (`test/cleansing_test.dart` — new)

- `isActionVisible(townSquare, 'burn_wilds_echo_essence')` false without Essence; true with
- Tapping burn action consumes 1 Essence + launches corresponding ritual
- Successful ritual:
  - Sets `breach_<tag>_cleansed` flag
  - Grants 1 Cleansing Token
  - Advances `cleanse` quest objectives with matching `targetId`, resets `comingSoon`
  - Fires per-breach milestone
- First cleansing also sets `first_breach_cleansed`; Spec 2's source pool opens
- All three cleansed sets `nexus_unlockable` + fires capstone + offers Main 8 Source Convergence
- Re-tapping burn action after cleansing is no-op (action no longer visible)

#### Zone & item tests

- Bloomwither / Glowing Vein zones exist with 5 actions matching spec
- Sundered Coast III gains `hunt_echo_of_tide`; `approach_lamp_room` sets flag
- Reused beast IDs work in T3 zones for "corrupted" guard fights
- Hazard chances 0.15–0.20 on T3 gathering
- 10 new items exist with correct types and values; Essence/Token items have `value: 0`
- Each item icon is a single emoji (length ≤ 4 codepoints per the no-dual-emoji rule)

#### Breach Introduction milestone tests (extend `test/quest_engine_test.dart`)

- `bloomwither_entered` fires on first travel to `whispering_woods_3`
- `glowing_vein_entered` fires on first travel to `darkstone_mine_3`
- `drowned_lighthouse_spoken` fires on `approach_lamp_room` action completion
- Each fires once (dedup via existing `_firedMilestoneIds`)

#### Integration smoke test (extend `test/quest_engine_test.dart`)

```dart
test('Spec 5 acceptance — full Wilds Breach arc', () {
  final engine = GameEngine();
  engine.unlockZoneForTest('whispering_woods_3');
  engine.travelTo(Zones.whisperingWoodsTier3);
  expect(engine.firedMilestoneIdsForTest, contains('bloomwither_entered'));

  engine.runCombatToVictoryForTest('echo_of_wilds');
  expect(engine.inventory.hasItem('wilds_echo_essence', 1), true);

  engine.travelTo(Zones.townSquare);
  expect(engine.isActionVisible(Zones.townSquare, 'burn_wilds_echo_essence'), true);

  engine.completeActionForTest('burn_wilds_echo_essence');
  engine.completeMasterworkForTest('cleansing_wilds', useFirstSuccessOption: true);

  expect(engine.engineFlags.contains('breach_wilds_cleansed'), true);
  expect(engine.engineFlags.contains('first_breach_cleansed'), true);
  expect(engine.inventory.hasItem('wilds_cleansing_token', 1), true);
  expect(engine.inventory.hasItem('wilds_echo_essence', 1), false);
  expect(engine.isActionVisible(Zones.townSquare, 'burn_wilds_echo_essence'), false);
  expect(engine.completedQuests.any((q) => q.id == 'main_cleanse_hollow'), true);
  expect(engine.isFragmentPoolOpenForTest(CodexTag.source), true);
});
```

### 5.2 Implementation order

Single PR, internally staged:

1. **Items** — add 10 new items (4 resources + 3 Essences + 3 Tokens) to `Items.all`.
2. **Echo beasts + phase model** — extend `Beast` with `phases` field, add `EchoPhase` + `BeastPassive`. Add 3 Echo beasts to `Beasts.all`.
3. **T3 zones** — add `whisperingWoodsTier3` and `darkstoneMineTier3` to `Zones.all`. Append `hunt_echo_of_tide` to `sunderedCoastTier3`. Wire `approach_lamp_room` to set `drowned_lighthouse_spoken` flag.
4. **Town Square burn actions** — append 3 conditional ZoneActions to `townSquare.actions`.
5. **Engine — phase mechanics** — extend `CombatState` with `activePhaseIndex`, `activePhaseAbility`, `activePhasePassive`. Add `_checkEchoPhaseTransition`. Wire passives into `_resolveCombatRound` (heal, damage reduction, accuracy debuff, enrage).
6. **Engine — visibility logic** — extend `isActionVisible` for 3 burn actions.
7. **Cleansing ritual tasks** — add 3 `MasterworkTask` constants to `MasterworkTasks.all` / `findById`.
8. **Engine — cleansing dispatch** — extend `_completeAction` for burn actions; modify `_onMasterworkSuccess` to detect and dispatch cleansings; implement `_onCleansingComplete` (flag, token, objective advance, milestone, Source Convergence offer).
9. **Milestones** — add 4 cleansing milestones + 3 Breach Introduction milestones to `Milestones.all`.
10. **Post-Echo narrative** — in `_resolveCombat` end-of-fight branch, detect Echo defeat and log directive.
11. **Tests** — written alongside each step.

Each numbered step compiles. After step 10, the game can be played end-to-end through a Breach cleansing.

### 5.3 Migration & compatibility

No save persistence; no save migration. Player first-launch change after Spec 5 ships:
- T3 zone exploration becomes meaningful (was stub content)
- Cleanse main quests (offered by Spec 2 with `comingSoon`) become completable
- Source pool becomes reachable

For players who reached T3 zones pre-Spec-5 (e.g., Coast III from Spec 3 with `approach_lamp_room` placeholder), the action now fires the Tide Breach Introduction on next tap.

### 5.4 Documentation updates

- `README.md` — extend with "Spec 5 — Tier-3 Zones & Echoes" notes
- Inline `///` doc comments on `EchoPhase`, `_checkEchoPhaseTransition`, `_onCleansingComplete`

### 5.5 Risks & deferrals

- **Echo balance is a guess.** 240/280/260 HP × 3 phases × ~12–15 rounds is the design target. Easy to tune via HP literals.
- **Phase 2 passives may be hard to communicate.** Spec 7a's tween animations could obscure healing. Mitigation: combat log explicitly notes "Echo healed 3 HP" per tick.
- **Cleansing rituals are short by design** (4 steps). Could feel anticlimactic after the Echo fight. Mitigation: post-fight narrative + milestone payoff carry the weight.
- **`_onCleansingComplete` directly mutates quest objectives** — bypasses normal `_matches` because Cleanse objectives have `comingSoon: true`. Deliberate exception; documented inline so future engineers don't generalize it via observers.
- **No persistence of `firedMilestoneIds`** — milestones can re-fire across sessions. Existing behavior since Spec 1; not addressed here.
- **Deferred to Spec 6:** Nexus zone; The Source final boss; Cleansing Token consumption at Nexus; credits sequence; Free Mode / NG+; Achievements for cleansings; Lore-completionist True Ending integration.

### 5.6 Player walkthrough

A player after Spec 5 ships:

1. Travels to Whispering Woods → completes T2 → scouts Bloomwither Hollow → first entry fires **Breach Introduction modal**: *"The trees here stand wrong..."*
2. Sees 5 actions in Bloomwither Hollow.
3. Engages Echo of the Wilds. Phase 1: Strangle Vines telegraphed every 3 rounds. At ~66% HP: *"The Echo trembles — vines knit closed its wounds. It heals as it fights."* Phase 2 begins.
4. Player must outpace the healing. At ~33%: *"The Hollow itself rises against you. The Echo will not slow."* Phase 3 enrage.
5. Echo defeated. Loot drops + activity log: *"The Echo collapses into a brittle husk..."*. Triumphant SFX.
6. Travels to Town Square. Sees **"🔥 Burn the Wilds Echo Essence"** action card.
7. Taps it. Ritual modal: *"The Essence won't catch..."*. Chooses to name the Hollow as the Warden did.
8. Ritual completes. *"A small carved seed-shape sits in the ash."* Token in inventory. Per-breach milestone + first-breach milestone fire. Source pool opens. Cleanse the Hollow quest completes → Cleanse the Vein quest offered.
9. Source-tag fragments begin dropping from Omen events and T3 zones.
10. Repeats for Stone (Glowing Vein) and Tide (Drowned Lighthouse).
11. After third cleansing: capstone milestone fires: *"Town Square's bells ring without being struck..."*. Three Cleansing Tokens sit in inventory. Main 8 Source Convergence quest offered with `comingSoon` objectives awaiting Spec 6's Nexus.

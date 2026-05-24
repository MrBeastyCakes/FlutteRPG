# Echoes from the Deep — Umbrella Vision

**Date:** 2026-05-24
**Status:** Approved (pending spec review)
**Scope:** Umbrella vision document for the full game overhaul. Defines theme, structure, design principles, and decomposes the work into 6 sub-spec topics. Each sub-spec gets its own brainstorm → design → plan → implementation cycle.

---

## 0. Design Principles

These principles bind every sub-spec and every implementation decision.

### 0.1 No art assets — emoji + text + Material Icons only

The game is text-based and uses Unicode emoji as icons across every existing system (beasts, items, stations, NPCs). All new content respects this. No painted maps, no portraits, no sprites, no custom illustrations. UI is built from Flutter Material Icons, GameTheme colored containers, and emoji.

Multi-emoji combinations (e.g., Echo of the Wilds `🌿👁️`) are how unique entities get visual identity. The design constraint pushes quality into writing and clever emoji use — text-based games punch above their weight when the writing is sharp.

### 0.2 Progressive discovery — never spoil scope

The player never sees content they have not earned visibility into.

- No "X of Y" counters anywhere. Show "12 Fragments collected", never "12 / 50".
- No greyed-out future tiles, no `???` placeholders for known-but-locked things.
- Codex sections appear only after the player has at least one entry in them.
- Locked zones, achievements, and recipes are hidden, not greyed.
- Even abstract concepts (e.g., "there are three Breaches") stay hidden until the player encounters their second Breach.

The game is small. The illusion of vastness depends on never letting the player count what's left.

### 0.3 Thin story spine — world tells the story

No NPC dialogue trees, no quest-giver monologues. Story is delivered through:
- Codex Fragments (1–3 sentence vignettes the player collects via play)
- Activity-log World Events that fire on milestones
- Subtle shifts in zone descriptions and weather as corruption rises

Total writing budget for v1: ~50 Codex Fragments + ~12 milestone events + ~10 ritual/Breach narratives + ~8 new Masterwork trials. Focused weeks of writing, not a novel.

### 0.4 Make systems converse

The biggest design wins come from systems pointing at each other:
- Lore drops feed Codex puzzles which gate True Ending which influences NG+
- Combat depth makes Echoes memorable which delivers Source fragments which complete the lore arc
- Crafting quality + specializations feed combat which feeds zone gating which feeds exploration which feeds lore
- Merchant reputation unlocks rare blueprints which feed specialization choices

Every sub-spec must explicitly call out which other systems it touches.

---

## 1. Theme & Arc

### 1.1 The Theme: *Echoes from the Deep*

Something old and wrong is waking up in the world's hidden places. The player learns this through what they observe: corrupted beasts in the deepest layers, glyphs on Obelisks that hint at sealed things, weather patterns shifting, refugees passing through Town Square. The whole world tells a single story through how it changes.

### 1.2 The Arc: *Three Breaches, One Convergence*

The world has been pierced in three places. Each region (Forest, Caves, the new Coast biome) hides one **Breach** — a localized eruption of corruption. The player's arc:

1. **Discover** — anomalies appear in Tier 1 zones; the Codex starts filling with fragments
2. **Investigate** — Tier 2 zones show corruption spreading; mini-bosses tied to the Breach appear in Tier 3
3. **Cleanse** — defeat the Breach's Echo, perform a cleansing ritual, seal the Breach
4. **Converge** — once all 3 Breaches are cleansed, a new Nexus zone opens where the Source itself can be confronted
5. **Defeat** — Final boss at the Nexus → credits → free mode + NG+ unlock

### 1.3 Endgame shape

Definitive ending with credits → Free / NG+ mode → future expansions add new threats. The architecture is expansion-ready — Frozen Peaks biome, taming skill, deeper Masterworks, and more are explicitly reserved for future content.

---

## 2. World Structure

### 2.1 Biomes & Zones (v1 scope)

Three biomes, each with three tiers, each anchored by a Breach in its Tier 3 zone. Plus Town Square (hub) and Nexus of Echoes (finale).

| Biome | T1 | T2 | T3 (Breach) |
|---|---|---|---|
| **Whispering Woods** *(existing)* | Sunny, oak, berries, boars | Foggy, willow, nightshade, wolves | **Bloomwither Hollow** — twilight, corrupted blooms, Echo of the Wilds |
| **Darkstone** *(existing)* | Copper, tin, spiders | Iron, trolls, hazardous | **The Glowing Vein** — luminous corruption, deep mites, Echo of the Stone |
| **Sundered Coast** *(NEW)* | Tide pools, kelp, crabs | Cliffs, salt-flats, gulls | **Drowned Lighthouse** — storm-lashed, brackish corruption, Echo of the Tide |
| — | — | — | **Nexus of Echoes** — endgame zone, unlocks after all 3 Breaches cleansed |

Each Tier-3 zone is gated by a cleansing event from the previous tier, not just a number check — progression carries a story beat.

### 2.2 New biome — Sundered Coast (mechanical identity)

- **New resources:** Driftwood (substitutes Oak/Willow with quality bias), Salt Crystal (Caustic-affix modifier), Pearl Shell (late-game armor input), Kelp (cooking ingredient)
- **New beasts:** Tide Hound 🐕 (T1), Brine Crawler 🦀 (T2), Salt-Touched Drowned 🧟 (T3), Echo of the Tide 🌊👁️ (Echo)
- **New station — Salt Press 🧂** — unlocked in T2 Coast; preserves provisions into longer-buffed variants
- **Weather identity:** Sea Fog (+Combat crit), Storm Swell (Coast actions disabled — wait or move on)
- Wayfinding gates tide-pool actions that only succeed during certain weather (ties to weather subsystem)

### 2.3 Mini-bosses — The Three Echoes + The Source

| Echo | Region | Theme |
|---|---|---|
| **Echo of the Wilds** 🌿👁️ | Bloomwither Hollow | Corrupted Ironbark; vine attacks; regenerates from foliage; weak to fire (cooking-themed) |
| **Echo of the Stone** 💎👁️ | Glowing Vein | Crystallized troll-thing; high defense; telegraphed quake; weak to precision (mining-themed) |
| **Echo of the Tide** 🌊👁️ | Drowned Lighthouse | Risen drowned; summons brine minions; storm-shroud accuracy debuff; weak to pure water (herbalism-themed) |
| **The Source** 👁️ | Nexus of Echoes | Three-phase final fight mirroring the three Echoes; requires Cleansed Tokens from each Breach to initiate |

Echoes are designed as showcase fights for the new combat-depth system (section 4) — multi-phase, telegraphed specials, unique mechanics. They feel different from grinding boars.

### 2.4 Town Square evolution

Town Square stays the hub but grows along with player progress. New structural additions appear progressively:

- **Tavern Notice Board** — daily tasks (Living Economy cluster). Appears after restoring the first Town Square station.
- **Cartographer's Tent** — Codex view UI. Appears after first Codex fragment collected.
- **Wharfmaster's Pier** — gates travel to Sundered Coast. Appears after first Breach cleansed + refugee event.
- **Reputation chips** — appear on each merchant after first interaction with them.

### 2.5 Discovery flow (progressive discovery applied)

- Game starts with only Town Square visible. Whispering Woods and Darkstone Mine appear in the Region Status Board only after the player triggers their discovery via existing scouting actions in Town Square.
- Tier-2 and Tier-3 zones appear after the previous tier's exploration action surfaces them.
- The Nexus does not exist in the UI until the third Breach is cleansed.
- The concept of "three Breaches" stays hidden until the player encounters their second one.

---

## 3. Story Spine & Codex

### 3.1 Main quest progression

```
Explore zone → discover T3 zone → first entry to T3 triggers Breach Introduction event
(one-time text overlay revealing the Echo and the cleansing offering required) →
Gather offerings + defeat Echo → perform Cleansing ritual →
Breach sealed → next biome opens via natural exploration / refugee event
```

The cleansing approach is revealed in the Breach Introduction event — a short text overlay when first entering each Tier-3 zone. No NPC dialog tree, no quest giver. The narrative scene IS the quest hand-off:

> *"The trees here stand wrong, and a deeper wrong watches from the heart of the hollow. Old tales say only an Ironbark log seasoned with three Wildflowers, burned at the rotted shrine, can quiet the breach. The thing that guards it will not let you near without a fight."*

### 3.2 Cleansing ritual

After defeating an Echo, the Breach must be **Cleansed** — a small interactive narrative beat using the existing Masterwork trial pattern. 3–4 choice steps, requires specific items revealed by the Breach Introduction, ends with a "Breach Sealed" Codex entry and a unique **Cleansing Token** item. The final boss fight at the Nexus requires all three Cleansing Tokens to initiate.

### 3.3 The Codex

A new top-level view, opened from the Cartographer's Tent in Town Square. Three sections (each appears only after the player has at least one entry in it):

#### 3.3.1 Fragments

Short vignettes — 1–3 sentences each — collected from Obelisks, beast loot, exploration, blueprint scrolls, random events, and Echo defeats. Each fragment carries a tag (Wilds / Stone / Tide / Source / Old Empire).

States: **Discovered** (icon + tag visible) → **Read** (full text + small Lore XP on first read). No "Unknown" placeholder for unfound fragments — they don't appear at all.

Writing budget: ~50 fragments. Composed with intent — each fragment must read well alone AND fit a hidden chronological order within its tag (see Codex puzzles below).

#### 3.3.2 Bestiary

Every beast the player has fought gains an entry on first defeat: 1-sentence flavor, observed stats, drop history, and — for Echoes — a defeat date. Bestiary entries also surface specialization-effectiveness hints over time as the player encounters and re-encounters each beast.

#### 3.3.3 Region Status Board

A vertical list grouped by biome. Each zone is a card showing emoji + name + status badge (Anomalous 🟡 / Spreading 🟠 / Cleansed 🟢 / Locked 🔒). Hidden zones simply don't appear. Zone-to-zone unlock paths are shown as text ("Unlocked by: Scout Forest Paths in Town Square"), not drawn arrows.

### 3.4 Codex puzzles — optional backstory

Per-tag ordering puzzles. Each tag's puzzle UI unlocks once the player has at least **3 fragments** in that tag.

UI: draggable fragment cards in a vertical list (Flutter `ReorderableListView`). Tap **Lock Sequence** to commit.

- **Correct:** A synthesized **Reading** appears — 2–4 paragraph in-fiction passage. One-time reward (varies by tag, see table below).
- **Incorrect:** Partial-feedback hint — *"6 of 10 adjacent pairs feel right"*. No punishment, unlimited re-tries.

Ordering clues live in the fragment text itself (seasons, named places, before/after temporal language) and in discovery context (zone, beast, Obelisk source shown alongside each fragment).

#### Puzzle rewards

| Tag | Solving reward |
|---|---|
| Wilds / Stone / Tide | Lore XP + Achievement + 1 random blueprint scroll + a Source-tag fragment unlocks somewhere |
| Source | Lore XP + Achievement + unique cosmetic title |
| Old Empire | **True Ending** epilogue narrative + unique NG+ starting bonus |
| All 5 sequences solved | **Synthesis** Codex entry appears — 4-paragraph capstone narrative + completionist Achievement |

#### Puzzles are optional, not gating

A player who never solves a puzzle can still complete the game. The puzzles deepen the lore experience but do not block main-quest progression. The True Ending is the carrot.

### 3.5 Milestone Events

Triggered automatically when the player crosses a story threshold. Each fires a special activity-log entry + an unmissable one-time overlay (single-tap dismiss). No interactive choices.

| Trigger | Event |
|---|---|
| Reach character level 5 | "A traveler limps into Town Square, muttering of black sap dripping from oaks." |
| First Codex fragment with `Source` tag read | "The Codex grows heavy. A new section has opened." |
| All 3 Breaches cleansed | "Town Square's bells ring without being struck. The Nexus is open." |
| Source defeated | Credits sequence + Free Mode unlock notification |

Writing budget: ~12 milestones.

### 3.6 Quest engine (minimal)

To support story milestones, cleansing rituals, daily tasks, and future expansions, the engine adds a thin Quest system:

```dart
class Quest {
  final String id;
  final QuestType type;     // main | side | daily
  final String title, description;
  final List<QuestObjective> objectives;
  final List<QuestReward> rewards;
}

class QuestObjective {
  enum Kind { gather, kill, craft, visit, cleanse, codexRead }
  final Kind kind;
  final String targetId;
  final int targetCount;
  int currentCount;
}
```

UI: Quest Log chip on Dashboard + a full Quest tab inside the Codex view. Main quests advance automatically (gated by milestone triggers); side/daily quests are explicit accept/turn-in.

v1 main quest count: ~8 main quests forming the spine (Discover → Investigate × 3 → Cleanse × 3 → Source).

### 3.7 Where fragments come from

Fragments are seeded across many systems so any play style finds some:

| Source | Frequency | Notes |
|---|---|---|
| Obelisk inspections | High | Each visit has a chance; obelisks gain tag affinities by zone |
| Beast drops | Low | Each beast has a small thematic-tag drop chance |
| Random events (Omen category) | Medium | Omen events have a high chance of dropping a fragment |
| Exploration / scouting actions | Medium | Tier-2/Tier-3 exploration unlocks zone-tied fragments |
| Tier-3 zone gathering | Low | Even routine gathering in T3 has rare fragment drops |
| Echo defeat | Guaranteed | Each Echo drops 2 Source-tag + 1 region-tag fragments |
| Silas's rare merchant unlock (rep) | One-time | The rare way to find Old Empire fragments outside Obelisks |

---

## 4. Gameplay Depth

### 4.1 Random Events

Non-combat zone actions roll a small chance to fire a Random Event instead of the normal loot result. Events use the existing Masterwork narrative pattern (text + 2–3 choice buttons). No new UI surface.

| Category | Examples | Trigger |
|---|---|---|
| **Interruption** | Bee swarm during foraging; rockslide while mining; sudden fog | ~4% per gathering action |
| **Discovery** | Hidden cache; rare flower; old surveyor's marker | ~3% |
| **Traveler** | Wandering refugee offers info for food; trapper trades a pelt | ~2% (T1–T2 only) |
| **Omen** *(themed)* | Black sap on a tree; corrupted whisper from stone; fog whispers a name | 0.5% → 3% (rises as Breaches spread) |

~20 event templates in v1, ~5 per category. Choices have skill-check variants (Lore, Combat, etc.) that surface when the player has the prerequisite. Omen events have a high chance to drop a Source-tag Codex fragment — they're the primary lore-discovery path for the Source tag.

### 4.2 Combat Depth

#### Stance-based action choices

Each combat round, the player picks one action from a horizontal action bar:

| Action | Cost | Effect |
|---|---|---|
| **Strike** | — | Standard attack (current behavior) |
| **Heavy Strike** | 5 energy | +50% damage, beast acts first this round |
| **Defend** | 2 energy | Halve incoming damage; small counter-damage |
| **Read Tells** | 3 energy | Reveal beast's intended action next round (Lore/Wayfinding check) |
| **Item** | varies | Use a consumable from Quick-Slot Bar |

If no choice is made before the round timer (~2s, faster with Combat perk), the default is Strike — preserves auto-combat for hands-off players.

#### Telegraphed beast specials

Each beast gains a `BeastAbility` that fires every N rounds with a one-round telegraph.

| Beast | Telegraph | Effect if not countered |
|---|---|---|
| Forest Boar 🐗 | "The boar paws the dirt, lowering its tusks." | Charge — +100% damage next round |
| Cave Spider 🕷️ | "Web-glands glisten." | Web — skip your next action |
| Shadow Wolf 🐺 | "The wolf's eyes flash silver." | Howl — summons a second wolf |
| Cavern Troll 👹 | "The troll hefts a boulder." | Smash — +60% damage + stun |
| Echo of the Wilds 🌿👁️ | "Roots burst around your feet." | Strangle — drain over 3 turns |
| (plus new Coast + Echo abilities — defined in their sub-specs) | | |

Defend or Read Tells counters them. Adds tactile reactive combat without a full ability system.

#### Quick-Slot Bar

Player configures 3 quick-slots from inventory (food / potions / glyphs). Eating a Loaded Potato mid-fight is now a real combat option.

### 4.3 Masterworks as Specialization Path Choices

The existing Masterwork trial system is reworked so its branching narrative choices **permanently shape a specialization path**, not just unlock the level cap.

#### Current → New

- **Today:** Masterwork trial → cap +10. Branching choices are flavor.
- **New:** Masterwork trial → cap +10 AND the path through the trial determines a specialization that changes the skill's passive perks and unlocks specialized recipes/abilities.

#### Two paths per skill at level 10, two more at level 20

Each skill's level-10 Masterwork forks into 2 paths based on the player's first major choice. The level-20 Masterwork further refines into 2 sub-paths within the chosen path.

Example — Crafting:

| Level | Path Choice | Effect |
|---|---|---|
| 10 (existing trial) | **Smith path** — reinforced the axe with iron | +20% quality bias on weapons & armor; unlocks Smith blueprints |
| 10 (existing trial) | **Tinker path** — chose a creative non-iron solution | +20% quality bias on tools & accessories; unlocks Tinker blueprints |
| 20 (new trial, Smith) | Weaponsmith *or* Armorsmith | +15% to chosen subtype |
| 20 (new trial, Tinker) | Toolmaker *or* Backpacker | +15% to chosen subtype |

Same pattern for the other 7 skills. Level 30 trials reserved for future expansion.

Engine adds `Map<SkillType, List<String>> _skillSpecs` — each skill carries 0–2 chosen specs (level-10 choice + level-20 choice). Skills view shows current specs as small badges after the choice is made. Bestiary "weak to spec X" hints surface as the player encounters and re-encounters each beast.

Writing burden: existing 8 level-10 trials need path-consequence wiring (no new text). 8 new level-20 trials needed (~10 hours of writing).

---

## 5. Living Economy

### 5.1 Merchant Reputation

Each of the 5 merchants gains a hidden reputation score. Selling adds +1 per gold of value (with a session cap to prevent farming); buying adds +2 per gold (paying customers are loved).

| Tier | Rep | Unlocks |
|---|---|---|
| Stranger | 0 | Default stock |
| Familiar | 500 | Unique greetings; +1 stock on rotating items |
| Trusted Patron | 2,000 | 10% discount; **unique rare item** in stock |
| Honored Friend | 5,000 | 20% discount; one-time gift (blueprint or quality item) |
| Sworn Companion | 12,000 | 30% discount; personal-flavor Codex fragment + Achievement |

Per-merchant reputation displayed only after first interaction. Trusted-Patron unique items wire merchants into other systems:

| Merchant | Trusted Patron item |
|---|---|
| Cedric (Trader) | Unique modifier item |
| Hilda (Blacksmith) | Rare Smith-path blueprint scroll |
| Pippin (Alchemist) | Exotic potion recipe |
| Silas (Lore Keeper) | An Old Empire Codex fragment (rare path) |
| Maeve (Outfitter) | Rare quality affix unlock |

### 5.2 Daily Tasks (Tavern Notice Board)

Town Square gains a new view: 3 procedurally-rolled tasks per session from template categories, scaled to player level. Tasks reset on app restart (matches the no-persistence reality).

| Category | Example | Reveal condition |
|---|---|---|
| Gather | "Bring 10 Oak Logs" | Always |
| Hunt | "Defeat 2 Cave Spiders" | Always |
| Visit | "Scout 1 new exploration path" | Always |
| Craft | "Craft 1 Fine-quality weapon" | After first craft |
| Codex | "Read 1 new Codex Fragment" | After first fragment read |
| Cleanse | "Defeat any Echo this session" | After first Breach cleansed |

Tasks self-track via the Quest engine. Completing all 3 in a session grants a **Daily Bonus** — a small gold purse + 5% chance of a blueprint scroll.

### 5.3 Achievements & Titles

A new Achievements view in the Codex. ~40 achievements in v1 across categories: First Steps, Mastery, Combat, Crafting, Lore, Economy, Hidden.

Locked achievements are hidden — no greyed list. Hidden category achievements never appear until earned (surprise drops). A discreet "Achievements: N" counter is OK; never "N / 40".

A subset of achievements grant **Titles** (already in schema as `PlayerStats.title`). Examples: *Apprentice Smith*, *Wilds Cleanser*, *Sworn Companion of Hilda*, *Echoeshaper*, *Lore-Bound*. Player selects which title to display.

Achievements drive the Bestiary "weak to spec X" knowledge surface — having "Defeat 3 Cave Spiders" is the trigger for the weakness hint to appear. Achievements become the in-game mechanism for knowledge propagation.

### 5.4 Resource Pressure

Two scarcity systems running side by side.

#### Tool durability

Each equipped tool gains `currentDurability` / `maxDurability`. Each gathering action with that tool decrements by 1. At 0, the tool becomes **Worn** — still works but loses its speed/success bonuses. Repair at any Crafting Bench: ~3 second action, 25% of original material cost. Cannot repair in the field — must travel.

| Quality | Max Durability |
|---|---|
| Crude | 75 |
| Standard | 100 |
| Fine | 150 |
| Masterwork | 250 |

Affixes apply: Sturdy → +50% durability; Ergonomic → unchanged. UI: small durability bar on tool slots. One floating notification per session when any equipped tool drops below 25%.

#### Scarce per-session reagents

2–3 rare reagent spawns appear in random zones each session as a special **Notice** sub-row on the zone view: *"You notice an unusual gleam near the riverbed. (Wayfinding action available)"*. Performing the action collects it (one-shot).

Reagents are modifier-tier ingredients with strong effects:

| Reagent | Effect |
|---|---|
| Moonpetal 🌸 | Forces affix roll on next craft |
| Spirit Sap 💧 | Doubles output of next craft |
| Hollow Bone 🦴 | Adds Brutal affix to weapon craft |
| Sea-Tear 💎 | Adds Tempered affix to armor craft |
| Coalblood 🌑 | Adds Frugal affix to any craft |
| Wisp-Light ✨ | Guaranteed Masterwork roll (extremely rare spawn) |

Spawn rate scales with player progression. Notice mechanic is hidden until first spawn encountered (becomes a tutorial moment). Reagents earn Codex entries when first collected — never appear in any list before that.

---

## 6. Sub-Spec Decomposition & Sequencing

This umbrella vision does not get implemented directly. It is broken into 6 sub-specs, each a separate brainstorm → spec → plan → implementation cycle (~2–3 weeks each).

### 6.1 The 6 Sub-Specs

#### Spec 1 — Quest Engine & Codex Foundation *(~2.5 wk)*

The plumbing under everything story-related.

- `Quest` / `QuestObjective` / `QuestReward` data model
- Engine fields: `_activeQuests`, `_completedQuests`, `_codexFragments`, `_lockedCodexSequences`
- Codex view (Fragments / Bestiary / Region Status / Achievements sections, progressive discovery applied)
- Bestiary auto-populates on beast defeat
- Region Status Board (emoji + status badge cards)
- World Event overlay widget for milestones
- Quest Log chip on Dashboard + Quest tab in Codex view

Does NOT include actual quests, fragments, or achievements — those land later. Pure foundation.

#### Spec 2 — Codex Content & Story Milestones *(~2.5 wk, writing-heavy)*

- ~50 Codex Fragments across 5 tags
- Per-tag puzzle ordering data + verification logic + ReorderableListView puzzle UI
- ~12 Milestone Events
- Tag puzzle Reading texts (one per tag) + Synthesis Reading
- Wiring fragment drops into existing systems (Obelisks, beast loot)
- True Ending epilogue text
- 8 main quest stubs (Discover → Investigate × 3 → Cleanse × 3 → Source)

#### Spec 3 — Sundered Coast Biome *(~3 wk)*

- 3 new zones (Coast T1, T2, T3 — Drowned Lighthouse)
- 4 new beasts (Tide Hound, Brine Crawler, Salt-Touched Drowned, Echo of the Tide)
- 5+ new resources (Driftwood, Salt Crystal, Pearl Shell, Kelp, variants)
- Salt Press station (specialist + tier ladder + recipes)
- Coast-themed weather (Sea Fog, Storm Swell)
- Wharfmaster's Pier in Town Square — triggered by first Breach cleansing
- Refugee event introducing the Coast
- Breach Introduction event for Drowned Lighthouse
- Tide-tagged Codex fragments + Tide tag puzzle data

#### Spec 4 — Gameplay Depth *(~3 wk)*

- Combat Stance system (5 actions, action bar)
- Telegraphed beast specials for all existing + new beasts (~8 abilities)
- Quick-Slot Bar (3 consumable slots in combat)
- Random Event engine + ~20 event templates across 4 categories
- Existing Masterwork rework: branching choices set specialization paths
- 8 new level-20 Masterwork trials (writing-heavy)
- `_skillSpecs` engine state + Skills view spec badges
- Bestiary "weak to spec X" hints surface via Achievement triggers

#### Spec 5 — Tier-3 Zones & Echoes *(~2.5 wk)*

- Whispering Woods III (Bloomwither Hollow) + Echo of the Wilds + cleansing ritual
- Darkstone Mine III (The Glowing Vein) + Echo of the Stone + cleansing ritual
- Sundered Coast III already covered in Spec 3
- Multi-phase Echo combats using Spec 4's depth system
- Cleansing ritual narrative trials (Masterwork pattern, offerings from Spec 2 Readings)
- Cleansing Token items + their use as Nexus gate
- Wilds + Stone tagged Codex fragments

#### Spec 6 — Living Economy + Nexus Finale *(~3.5 wk)*

- Tool Durability system (per-item state + Repair action)
- Scarce Reagent spawn system (per-session, Notice mechanic on zone view)
- 6 reagent items + their modifier effects
- Merchant Reputation (5-tier ladder + per-merchant rare items)
- Daily Tasks Notice Board (Tavern UI + procedural task generation)
- ~40 Achievements + Title system
- Nexus of Echoes zone
- The Source: 3-phase final boss
- Credits sequence
- Free Mode / NG+ unlock flag + NG+ starting bonus logic
- Final cleansing + Synthesis-as-true-ending tie-in

### 6.2 Recommended sequencing

```
Spec 1 (Foundation)
   ↓
Spec 2 (Story content, depends on foundation)
   ↓
Spec 3 (New biome — can start in parallel with Spec 2 if helpful)
   ↓
Spec 4 (Gameplay depth — uses existing + new content)
   ↓
Spec 5 (T3 zones + Echoes — needs Spec 4's combat depth to feel right)
   ↓
Spec 6 (Economy + Finale — capstone)
```

Each spec ends with a playable game strictly better than before:

- **After Spec 1:** Codex foundation exists. Bestiary auto-fills. Region Status shows discovered zones.
- **After Spec 2:** Story is alive. Fragments dropping, puzzles solvable, milestones firing.
- **After Spec 3:** A whole new biome to explore.
- **After Spec 4:** Combat is engaging. Random events break monotony. Masterwork choices feel weighty.
- **After Spec 5:** Endgame exists. Three Breaches to cleanse. Echoes memorable.
- **After Spec 6:** Ship — economy texture, daily engagement, finale, credits, NG+.

### 6.3 Total scope estimate

| Spec | Design | Implementation | Total |
|---|---|---|---|
| 1 — Quest & Codex Foundation | 1 wk | 1.5 wk | 2.5 wk |
| 2 — Codex Content & Story | 1.5 wk | 1 wk | 2.5 wk |
| 3 — Sundered Coast | 1 wk | 2 wk | 3 wk |
| 4 — Gameplay Depth | 1 wk | 2 wk | 3 wk |
| 5 — T3 Zones & Echoes | 1 wk | 1.5 wk | 2.5 wk |
| 6 — Living Economy + Finale | 1.5 wk | 2 wk | 3.5 wk |
| **Total** | **7 wk** | **10 wk** | **~17 wk** |

Roughly 4 months solo-dev time at full pace, ~6 months calendar at part-time pace.

### 6.4 What this vision does NOT do

- Does NOT contain full data definitions for each spec's content (sub-specs do)
- Does NOT specify exact balance numbers, RNG distributions, or formulas (sub-specs do)
- Does NOT commit to specific UI implementations for new views (sub-specs do)
- Does NOT cover content reserved for future expansions (see §6.6)

### 6.5 What this vision DOES do

- Establishes the unified theme that flavors every system
- Names every subsystem and how it converses with the others
- Defines world structure, story arc, endgame shape
- Locks the design principles (no art, progressive discovery, thin story spine)
- Carves the work into 6 sub-specs with sequencing rationale
- Provides a credible scope estimate

### 6.6 Reserved for future expansions

Explicitly out of scope for v1, intended for post-launch expansions:

- **Frozen Peaks biome** — a 4th biome with its own Breach (the architecture supports adding biomes)
- **Taming skill** — a 9th skill replacing the v1 "no companion" decision; lets the player tame and bond with creatures
- **NPC companions / mercenaries** — hired adventurers who perform passive tasks
- **Level 30 Masterworks** — a third tier of specialization choice
- **Day/night cycle** — beyond the existing weather system
- **Multiplayer / PvP** — not in vision; reserved indefinitely

### 6.7 Next steps after this vision is approved

1. This document is the umbrella; it does not get implemented directly.
2. Start by brainstorming **Spec 1 — Quest Engine & Codex Foundation** in a separate session (produces its own spec + implementation plan).
3. After Spec 1 ships, brainstorm Spec 2. Etc.
4. Each sub-spec gets its own `docs/superpowers/specs/YYYY-MM-DD-<spec-name>-design.md` referenced from this umbrella.
5. The umbrella may need light revisions if a sub-spec discovers something that changes the vision — that is expected, not failure.

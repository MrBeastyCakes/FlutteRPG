# Spec 2 — Codex Content & Story

**Date:** 2026-05-24
**Status:** Approved (pending spec review)
**Parent:** [Echoes from the Deep umbrella vision](2026-05-24-echoes-from-the-deep-vision.md)
**Depends on:** [Spec 1 — Quest Engine & Codex Foundation](2026-05-24-spec-1-quest-codex-foundation-design.md) (already implemented)
**Scope:** Second of six sub-specs from the umbrella. Content + content-driven systems on top of Spec 1's foundation: 50 Codex fragments across 5 tags with full text, drag-to-reorder per-tag puzzles with per-card feedback, 5 fully-written Readings, 11 milestone events, 8 main quest stubs with "Coming Soon" objectives for later-spec content, and drop wiring into existing Obelisks/beasts/scout-actions.

---

## 1. Goals & Acceptance Criteria

### 1.1 What Spec 2 ships

- The Codex's **Fragments** tab appears once the player reads their first fragment (was hidden in Spec 1)
- 50 fragments exist in `CodexFragments.all` (10 per tag × 5 tags) with full text and `orderInTag` set
- Per-tag puzzle UI: drag-to-reorder + Lock + per-card green/red position feedback
- 5 fully-written Readings (Wilds, Stone, Tide, Source, Old Empire) shown on tag-puzzle solve
- 11 milestone events firing at story beats throughout play (10 new + the existing `town_square_restored` from Spec 1)
- 8 main quest stubs with full descriptions; later-spec objectives marked "Coming Soon"
- Synthesis placeholder section appears once 4-of-5 tag puzzles solved (Spec 6 fills the body)
- True Ending epilogue placeholder triggers when Old Empire puzzle solved (Spec 6 fills the body)
- Fragment drops wired into Obelisks (Wilds + Old Empire), Darkstone Mine I/II via new `inspect_glyph` actions (Stone + Old Empire), beast defeats (region-tagged), scout actions, and T3 gathering (Source-tag, gate-blocked in v1)

### 1.2 What Spec 2 does NOT do

- No Sundered Coast content (Spec 3) — Tide-tag fragments are authored and present in `CodexFragments.all`, but their pool stays gated until the Coast unlocks
- No Combat depth / random events / specializations (Spec 4)
- No Tier-3 zones / Echoes / cleansing rituals (Spec 5) — Source pool stays gated; Cleanse main-quest objectives are uncompletable
- No final boss / Nexus / credits / Synthesis-and-True-Ending body content (Spec 6)
- No new beasts, items, recipes, or stations beyond the `inspect_glyph` ZoneAction in Darkstone

### 1.3 Acceptance criteria

A player after Spec 2 ships:

1. Inspects an Obelisk in Town Square or Whispering Woods → ~10% chance of a Wilds-pool fragment (1% chance of Old Empire too)
2. Defeats a beast → ~8% chance of a fragment matching the beast's region tag (Forest Boar / Wolf → Wilds; Spider / Troll → Stone)
3. Reads a fragment → it appears in the Codex Fragments tab, sorted by tag; the Fragments tab itself appears for the first time
4. Once 3+ fragments collected in any tag → a "Solve Puzzle" button appears on that tag's section
5. Drags-and-reorders → taps Lock → cards highlight green/red per position; correct lock plays a burst and shows the Reading
6. Wrong Lock costs −3 Lore XP (floor 0) and shows the per-card highlights
7. Discovering 2 different breach-tag fragments (Wilds+Stone, Wilds+Tide, or Stone+Tide) → a major milestone modal fires: the concept "three Breaches" appears for the first time
8. Quest log shows 8 main quests as the player progresses; later-spec quests show "Coming Soon" badges on Cleanse/Source objectives
9. Solving Old Empire puzzle → sets `true_ending_unlocked` flag (Spec 6 reads this to gate the True Ending epilogue)

### 1.4 Design principles inherited from umbrella + Spec 1

- **No art** — emoji + text + Material Icons only (ReorderableListView's built-in drag handles)
- **Progressive discovery** — Fragments tab hidden until first fragment read; per-tag puzzle UI hidden until 3+ fragments in that tag; Synthesis section hidden until 4-of-5 puzzles solved; no "N / 10" counters
- **Thin story spine** — Codex fragments + milestone overlays carry all narrative; no NPC dialog trees
- **Systems converse** — Fragment drops feed puzzles which gate Readings which deepen the story which references creatures players have fought and places they've been

---

## 2. Fragment Content & Tag Pools

### 2.1 Fragment count per tag

10 fragments per tag × 5 tags = **50 fragments total**. Each fragment has `orderInTag` set to its correct puzzle position (1–10). A tag's puzzle becomes solvable when all 10 are collected.

| Tag | Count | Pool gate | Drop sources |
|---|---|---|---|
| **Wilds** | 10 | Always open | Whispering Woods Obelisks, forest beasts (Boar, Wolf), forest scout actions |
| **Stone** | 10 | Opens on first visit to Darkstone Mine I | Darkstone Obelisks (new `inspect_glyph` action), cave beasts (Spider, Troll), mine scout actions |
| **Tide** | 10 | Opens once Sundered Coast is unlocked (Spec 3) | Coast Obelisks, Coast beasts, Coast scout actions — pool stays empty in v1 ship |
| **Source** | 10 | Opens after `first_breach_cleansed` flag set (Spec 5) | T3 gathering rare drops + guaranteed Echo defeats — pool empty in v1 ship |
| **Old Empire** | 10 | Always open | All Obelisks across all zones, very rare (~1% per Obelisk visit) |

Pool gates checked at drop time via `engine.engineFlags` and `_regionStatus`. Spec 2 ships Wilds + Stone + Old Empire fully wired. Tide + Source wait for later specs to flip their gates.

### 2.2 Fragment voice & writing style

All 50 fragments share a consistent voice:

- **First-or-third-person observation**, never explanatory exposition
- **Concrete sensory detail** (smell of black sap, weight of an iron pickaxe, taste of brine)
- **Implication over statement** — show, don't tell
- **1–3 sentences each**, ~25–60 words
- **No proper names of NPCs** (matches the no-quest-giver design)
- **References across fragments** — characters and places recur, creating ordering clues

Each fragment carries a `sourceHint` shown in the Codex UI: e.g., "Found at: Crumbling Obelisk in Whispering Woods I".

### 2.3 The 50 fragments

#### Wilds (10) — The Warden's Account

| # | id | Title | Text |
|---|---|---|---|
| 1 | `wilds_01` | First Spring | *Last spring the bluebells came up early, faces bright. I marked the date in my journal: a good year coming. I was wrong about the year.* |
| 2 | `wilds_02` | Black Sap | *I cut a young oak for firewood today and the sap ran black. I left the axe in the wood and walked away.* |
| 3 | `wilds_03` | The Quiet | *The birds stopped singing in the eastern groves. Not gone — I can see them. They just stopped.* |
| 4 | `wilds_04` | The First Sick Boar | *A boar charged me at dusk. Its eyes were the wrong color. I killed it; it tasted of iron and something older.* |
| 5 | `wilds_05` | Ironbark Forgets | *The old folk used to call certain oaks Ironbark for the strength of their wood. The Ironbarks have begun to soften from the inside, weeping that same black sap.* |
| 6 | `wilds_06` | Roots in the Deep | *I tracked a sick wolf to a clearing and found roots running upward from the soil. Roots, growing the wrong way. I did not stay to see what they reached for.* |
| 7 | `wilds_07` | The Warden's Walk | *I have walked these woods forty years. I no longer know them. The trails move when I am not looking.* |
| 8 | `wilds_08` | The Hollow Calls | *There is a hollow in the deepest grove where no warden goes. I dreamed of it last night. I dreamed it called my name.* |
| 9 | `wilds_09` | The Last Bluebell | *I picked a bluebell today. It came up with thread, not roots — a long dark thread that ran deep into the soil. I did not pull further.* |
| 10 | `wilds_10` | A Door I Do Not Open | *I have stopped going to the Hollow. I lock the warden's gate at night now. Something is on the other side. It knows my name.* |

#### Stone (10) — The Foreman's Confession

| # | id | Title | Text |
|---|---|---|---|
| 1 | `stone_01` | The Vein | *We struck a copper vein last week thick as my arm. The lads cheered. I should have asked why no one had cut it before us.* |
| 2 | `stone_02` | The Tap | *There is a sound in the deep shafts at night. A slow tapping. Three taps, a pause, three taps. We tell the new boys it is settling rock.* |
| 3 | `stone_03` | The Light That Should Not Glow | *Found a chunk of ore today that glowed in my palm without sun or flame. I pocketed it. I think that was wrong.* |
| 4 | `stone_04` | The Glinting Vein | *The deep wall opened on a vein that pulsed like a slow heart. The foreman called it the Glinting. He looked at it too long.* |
| 5 | `stone_05` | Stone Remembers | *I drove my pick into a fresh seam and the rock — I swear it — flinched. The strike rang back wrong, like striking a bell that does not want to be rung.* |
| 6 | `stone_06` | The Foreman's Walk | *The foreman has stopped sleeping. He walks the lower shafts at night now, his lamp out, his eyes lit. He does not see us anymore.* |
| 7 | `stone_07` | What Lives in the Tap | *I counted the tapping last night. Three taps, a pause, three taps — but the pauses are getting shorter. It is learning to speak.* |
| 8 | `stone_08` | Trolls Are Listening | *The cavern trolls do not attack the foreman. They watch him pass. The trolls know something the foreman has forgotten.* |
| 9 | `stone_09` | The Vein Is a Wound | *I understand now: the Glinting is not a vein. It is a wound in the world. We have been picking at a wound.* |
| 10 | `stone_10` | The Tapping Knows My Name | *The tapping has my rhythm now. When I hammer, it answers. When I stop, it waits. I will not go down again.* |

#### Tide (10) — The Keeper's Log

Pool stays empty in v1 ship; written for Spec 3 readiness.

| # | id | Title | Text |
|---|---|---|---|
| 1 | `tide_01` | The Lighthouse Keeper's Log | *Day one of the keeper's new rotation. Tide normal. Lamp lit. Gulls overhead. A quiet station, this Drowned Lighthouse.* |
| 2 | `tide_02` | Brine in the Cisterns | *The freshwater cistern tastes of salt this morning. I checked the seals: intact. The salt is coming from below.* |
| 3 | `tide_03` | The Hound at the Door | *A wet hound came to the keeper's door last night and would not leave. Its eyes shone like fish scales. I closed the door.* |
| 4 | `tide_04` | The Pier Sang | *Walking the pier at moonrise, I heard it sing — a long low note from beneath the planks. I have not walked the pier since.* |
| 5 | `tide_05` | The Salt That Bites | *I tried to make a salt-cure of fresh fish. The salt smoked in the bowl, hissed when it touched the meat. This is not the salt of my grandmother.* |
| 6 | `tide_06` | Drowned Things Watching | *I see them at low tide now — shapes in the shallows that do not move when the water moves. They wait.* |
| 7 | `tide_07` | The Lamp Will Not Stay Lit | *I lit the great lamp at dusk. By midwatch it had gone out, though I had filled the reservoir myself. I lit it again. It guttered as if breathed on.* |
| 8 | `tide_08` | The Crawler in the Cellar | *A brine crawler in the cellar this morning, big as a hound. I drove it off. There are more, I am sure, in the dark.* |
| 9 | `tide_09` | The Sea Speaks the Foreman's Name | *I dreamed last night of a man with a lamp out, walking deep mine shafts. The sea told me his name. I have never been to the mines.* |
| 10 | `tide_10` | The Light Has Gone Out | *The great lamp is out and will not relight. The drowned have come ashore. I write this from the keeper's loft, while I still can.* |

#### Source (10) — The Convergence

Pool stays empty in v1 until first Breach cleansed (Spec 5).

| # | id | Title | Text |
|---|---|---|---|
| 1 | `source_01` | A Common Thread | *Three sicknesses, three regions. Three voices speaking through different mouths. The thread runs deeper than any one of them.* |
| 2 | `source_02` | The First Word | *Before the woods spoke wrongly, before the stones rang false, before the sea took the lamp — something said its first word. The world has been answering ever since.* |
| 3 | `source_03` | Beneath Every Depth | *The miners thought the Glinting was the bottom. It was not. Beneath every stone is another stone. Beneath every depth, another depth.* |
| 4 | `source_04` | The Old Word for It | *The old tongue had a word for what is happening. It meant 'echo' — but the kind of echo a struck wound makes, not the kind a struck bell makes.* |
| 5 | `source_05` | It Wears Their Faces | *The Echo of the Wilds is not the Wilds. The Echo of the Stone is not the Stone. The Echo of the Tide is not the Tide. They are all the same Echo, wearing the faces it has learned.* |
| 6 | `source_06` | The Old Empire Knew | *The First Age built Beacons at the breach-sites and called them by their right names. The names are forgotten. The Beacons are toppled. The breaches are open.* |
| 7 | `source_07` | The Source Speaks Through Three Mouths | *Three mouths to speak with. Three throats to silence. To unmake the speaker, you must unmake the speech.* |
| 8 | `source_08` | A Convergence | *When the three are silenced — and only then — the speaker will come out from beneath the world to find what silenced them. It will not be pleased.* |
| 9 | `source_09` | The Place It Will Come | *Where the three roads meet beneath the world: that is where it will come. The First Age had a name for the place. We will have to remember.* |
| 10 | `source_10` | What Remains | *If you stand at the convergence and unmake the speaker, the world will be quieter. Not silent. Quieter. That is the most you can hope for. Hope for it.* |

#### Old Empire (10) — The Cartographer's Wager

Always-open pool; ~1% per Obelisk visit. Optional True Ending track.

| # | id | Title | Text |
|---|---|---|---|
| 1 | `empire_01` | The First Age Spoke | *Before our age there was an older one. They left their script carved on stones we still cannot read. They wrote, mostly, about silence.* |
| 2 | `empire_02` | The Beacons of Asar | *The First Age built Five Beacons to mark where the world is thin. The Beacons fell long ago. The places remained thin.* |
| 3 | `empire_03` | The Cartographer's Last Map | *The last cartographer of the First Age died with one map unfinished. It marked the breach-sites. It marked the convergence. It did not mark a way home.* |
| 4 | `empire_04` | The Tongue of Asar | *Their tongue had thirty-two words for "silence" and one for "war." We have the inverse problem.* |
| 5 | `empire_05` | The Long Watch | *The First Age built a watch that would last a thousand years. The watch lasted nine hundred. We are the watch now, and we did not know.* |
| 6 | `empire_06` | The Old Empire Fell To Hope | *The records say the First Age fell not to war or famine but to hope. They believed the breaches could be closed forever. They were wrong; the breaches reopened, and they had unmade their watch.* |
| 7 | `empire_07` | What the Beacons Were | *The Beacons were not lights. They were instruments. They sang a single low note at the breach-sites. The note kept the speaker quiet.* |
| 8 | `empire_08` | The Old Empire's Wager | *Knowing the breaches would reopen, the First Age left us a wager: build the instruments anew, or accept the diminished world. The instruments are hard to build.* |
| 9 | `empire_09` | The Inheritor | *Their last writing, in their tongue: "to whoever follows: the wager is yours. We are sorry. We hoped." Their script for "hoped" is the same as their script for "failed."* |
| 10 | `empire_10` | The Quiet Inheritance | *To inherit the watch is to choose what to do with it. The First Age chose hope. You may choose otherwise. The world will know which you chose.* |

---

## 3. Puzzle UI & Readings

### 3.1 Fragments tab visibility

When the player reads their first fragment, the **Fragments tab appears** in the Codex view. Before that read, the tab is hidden (progressive discovery).

Layout:

```
┌─ Codex ▸ Fragments ──────────────────────┐
│                                          │
│  WILDS                          7 found   │
│  ┌────────────────────────────────────┐  │
│  │ 📜 First Spring                    │  │
│  │ 📜 Black Sap                       │  │
│  │ 📜 ???  (unread)                   │  │
│  │ ...                                 │  │
│  │           [SOLVE PUZZLE] (7+)      │  │
│  └────────────────────────────────────┘  │
│                                          │
│  STONE                          3 found   │
│  ┌────────────────────────────────────┐  │
│  │ 📜 The Vein                        │  │
│  │ 📜 The Tap                         │  │
│  │ 📜 ???  (unread)                   │  │
│  │           [PUZZLE LOCKED] (3/10)   │  │
│  └────────────────────────────────────┘  │
│                                          │
└──────────────────────────────────────────┘
```

Each tag is a collapsible section. Sections only appear for tags with at least 1 fragment. Header shows tag name and discreet "N found" count — never "N / 10".

**Unread vs read:** Just-dropped fragments appear as "📜 ???" with a pulse animation. Tapping reveals title + text + sourceHint. Reading grants 15 Lore XP and fires `CodexFragmentReadEvent`.

**[SOLVE PUZZLE]** button appears once a tag has 3+ fragments. Disabled with "(N/10)" label until all 10 are collected.

### 3.2 Puzzle view — `lib/views/codex_puzzle_view.dart`

Full-screen route opened from the Solve Puzzle button:

```
┌─ Wilds — Order the Fragments ────────────┐
│  Drag to reorder. Lock when ready.      │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ 1.  📜 The Hollow Calls       ☰    │ │
│  │ 2.  📜 First Spring           ☰    │ │
│  │ 3.  📜 The Warden's Walk      ☰    │ │
│  │ ... (current order)                 │ │
│  │ 10. 📜 Black Sap              ☰    │ │
│  └────────────────────────────────────┘ │
│                                          │
│         [ LOCK SEQUENCE ]                │
└──────────────────────────────────────────┘
```

- Flutter `ReorderableListView` (built-in drag handles)
- Tap a row → quick peek modal with full text
- **Lock Sequence** full-width button

### 3.3 After Lock — per-card feedback

Per user override of the umbrella's "N pairs feel right" → **highlight specific wrong-position cards**:

- Each card border turns **green** (correct position) or **red** (wrong)
- Summary line: *"7 of 10 in correct place. (Wrong-Lock cost: −3 Lore XP)"*
- Player can drag red cards and Lock again — no cooldown
- Wrong Lock costs **−3 Lore XP** (very slight; floor 0 — clamps, no negative XP, no level loss)
- First wrong Lock in a session shows a tiny onboarding dialog: *"Hint: re-reading fragments before locking saves you XP"*
- Correct Lock plays existing particle-burst widget and shows the **Reading overlay**

**Note:** Per-card feedback is intentionally easier than the umbrella's "N pairs feel right" model. The user explicitly chose this for accessibility. If playtesting shows puzzles trivial, revisit in a balance pass.

### 3.4 Readings — `lib/models/codex_reading.dart` (added to `lib/models/codex.dart`)

```dart
class CodexReading {
  final CodexTag tag;
  final String title;          // e.g., "The Warden's Account"
  final String body;           // 2-4 paragraphs
  final List<QuestReward> rewards;

  const CodexReading({
    required this.tag,
    required this.title,
    required this.body,
    required this.rewards,
  });
}

class CodexReadings {
  static const CodexReading wildsReading = CodexReading(...);
  static const CodexReading stoneReading = CodexReading(...);
  static const CodexReading tideReading = CodexReading(...);
  static const CodexReading sourceReading = CodexReading(...);
  static const CodexReading oldEmpireReading = CodexReading(...);
  static CodexReading? forTag(CodexTag tag);
}
```

#### 3.4.1 Wilds Reading — *The Warden's Account*

> Forty years I have walked the Whispering Woods. I know its trails the way a blacksmith knows his anvil — by the small marks each leaves on me. So when the bluebells came up early last spring, I noticed. When the sap ran black, I noticed. When the birds stopped singing in the eastern groves, I noticed.
>
> Something has come into the wood that does not belong. I have followed its trail to a hollow I will not name. It dreams. It calls. It learns the names of those who walk near it. It learned mine, and I have stopped walking near it.
>
> If you read this, you have done what I could not. Find the Hollow. Take with you an Ironbark log, well-seasoned, and three Wildflowers cut at first light. Burn the offering at the rotted shrine within. What rises will fight you. It must fight you. There is no other way to close what has opened here.
>
> *— The Warden*

**Rewards:** 60 Lore XP; Achievement stub "Wilds Witness" (Spec 6); 25 gold (Spec 4 will replace with random Wilds-tagged blueprint scroll); `tryDropFragment(CodexTag.source, 1.0)` (no-op until Source pool opens in Spec 5).

#### 3.4.2 Stone Reading — *The Foreman's Confession*

> They will tell you the foreman went mad. He did not. He went silent first, and silence is not madness — it is the absence of the noise we use to drown out the truth.
>
> The Glinting Vein is not a vein. It is a wound. Beneath the lowest shaft of Darkstone Mine there is a pulsing, glowing lens of stone that should not be, and the foreman walked into the shaft one night and put his ear to it. The lens spoke to him. It is still speaking. He answers it now in his sleep, and the deep tappings in the mine answer him back, and so the conversation goes, growing.
>
> If you would silence the wound, bring an alchemist's draught — wildflower tinctured with river clay, twice-distilled — and pour it into the Glinting at the moment its pulse lengthens. What dwells in the wound will rise to defend it. You must endure the rising. Then pour. The lens will close.
>
> *— What the foreman wrote on the wall the morning he stopped speaking*

**Rewards:** 60 Lore XP; Achievement stub "Stone Witness"; 25 gold (Spec 4 → Stone blueprint scroll); Source-tag fragment unlock attempt.

#### 3.4.3 Tide Reading — *The Keeper's Last Page*

> I am the keeper of the Drowned Lighthouse. I write this from the loft above the lamp room. The lamp will not stay lit. The drowned have come ashore. I do not have much time.
>
> The lamp is not just a lamp. The old keepers told me, and I did not listen, because old keepers tell many things. They told me the lamp is a Beacon — that it sings, when properly lit, a low note that keeps the wrong things in the sea where they belong. The lamp has stopped singing. The note has gone out of the world. The wrong things are walking up the pier.
>
> If you find this, do not relight the lamp with oil. Lamp oil will not hold. Carry a Salt Crystal — the pure kind from the deep tide pools, not the brine-stained kind from the cliffs — and set it within the lamp's heart. The Crystal will sing the note the lamp has forgotten. Something old in the sea will rise to silence the song. Do not let it.
>
> *— The Keeper, from the loft, by lamplight*

**Rewards:** 60 Lore XP; Achievement stub "Tide Witness"; 25 gold (Spec 4 → Tide blueprint scroll); Source-tag fragment unlock attempt.

#### 3.4.4 Source Reading — *The Convergence*

> Three breaches. Three Echoes wearing three faces. One Source beneath them all, and beneath the Source — beneath every depth, you have read this before — another depth.
>
> The Echoes are not the Source. The Echoes are the Source's voice in three different mouths: a wood-mouth, a stone-mouth, a sea-mouth. Silence the three mouths and the Source will come out from beneath the world to see what has silenced them. It will come to the convergence — the place where the three breach-roads meet beneath the surface, which the First Age called by a name we do not remember.
>
> You will need a token from each cleansed breach. You will need the Beacons remembered. You will need to stand at the convergence and unmake the speaker. What waits there cannot be reasoned with. It can only be unmade.
>
> If you go: do not bring hope. Hope was the First Age's mistake. Bring the instruments. Bring the silence.

**Rewards:** 100 Lore XP; Achievement stub "Source Witness"; unique title *"Inheritor"*; sets `engineFlag: nexus_understood` (Spec 6 reads this as Nexus precondition).

#### 3.4.5 Old Empire Reading — *The Cartographer's Wager*

> The First Age fell because they hoped. They built the Beacons, they sang the silence into the world, and they believed they had closed the wound forever. They had not. The wound reopened in their grandchildren's time, and the grandchildren did not know the song, because the First Age had unmade the watch when they thought the song was no longer needed.
>
> They left us a map and a wager. The map is a stone, in a place I will not name in this writing, that shows the breach-sites and the convergence. The wager is this: build the instruments anew, or accept the diminished world. The instruments are hard to build. The diminished world is easy to live in. They left us free to choose.
>
> If you have read this, you have chosen. The choice is silent and personal and has no audience. The world will know which you chose only by what the world becomes.
>
> *— from the unfinished map of the last cartographer of the First Age*

**Rewards:** 120 Lore XP; Achievement stub "Empire Witness"; unique title *"Cartographer's Heir"*; sets `engineFlag: true_ending_unlocked` (Spec 6 reads this to gate the True Ending epilogue).

### 3.5 Reading display UI

When a puzzle is solved, the Reading appears as a **full-screen overlay**:

- Dim background
- Centered card: small tag header, title, full body in italic narrative styling, rewards summary, "Continue" button
- Background tinted by tag color (Wilds = green, Stone = gray, Tide = blue, Source = purple, Old Empire = gold)
- Tap-outside or Continue dismisses; rewards granted; activity log entry added

Re-reads accessible from the Codex Fragments tab — that tag's section now shows "📖 Read the *<title>*" alongside the fragment list. Re-reading shows the Reading again (no rewards).

### 3.6 Synthesis placeholder

When 4 of 5 tag puzzles are solved (Wilds + Stone + Tide + Source counted; Old Empire optional), a **Synthesis section** appears in the Codex Fragments tab below the tag sections:

```
┌────────────────────────────────────┐
│  ✨ SYNTHESIS                       │
│  One more reading awaits...        │
│                                    │
│  Solve the last tag's puzzle to    │
│  unlock the Synthesis.             │
└────────────────────────────────────┘
```

When all 5 solved, the section becomes a tap-to-read card. Body in Spec 2:

> *[Synthesis content authored in Spec 6 — final integration with Nexus unlock and ending sequence.]*

Mechanism, trigger, and reward hooks are in place — Spec 6 just swaps the body string.

---

## 4. Milestones & Main Quest Stubs

### 4.1 The 11 milestone events

| # | id | Severity | Trigger | Body |
|---|---|---|---|---|
| 1 | `town_square_restored` | major | engineFlag set (Spec 1) | *"As you hammer the last beam into place, the town stirs..."* |
| 2 | `first_codex_fragment` | minor | First fragment added to `_knownCodexFragmentIds` | *"The cartographer presses something into your palm: a torn page, its ink still damp. 'These have begun to surface. Bring me more.'"* |
| 3 | `first_codex_read` | minor | First fragment read | *"A line you read lodges itself in your mind. You feel the Codex grow heavier in the tent."* |
| 4 | `first_wilds_drop` | minor | First Wilds-tag fragment collected | *"A faint scent of bluebells follows you back to town. The cartographer recognizes the tag and pulls down the Wilds atlas."* |
| 5 | `first_stone_drop` | minor | First Stone-tag fragment collected | *"The cartographer turns the page slowly. 'Stone speaks last,' he says. 'When stone speaks, it's almost too late.'"* |
| 6 | `second_breach_concept` | **major** | ≥1 fragment from TWO different breach tags (Wilds/Stone/Tide combinations) | *"The cartographer's eyes go very still. 'You've brought me a second voice. There are three. There have always been three. The Old Empire knew them as Breaches. You should know them too.'"* — sets `engineFlag: breaches_concept_known` |
| 7 | `first_puzzle_solved` | minor | First time any tag's puzzle is locked correctly (covers the "Reading unlocked" beat too) | *"Pieces snap into place. The cartographer reads it through, sets it down, and looks at you differently."* |
| 8 | `lore_completionist_path` | minor | First Old Empire fragment collected | *"This one is older than the others. The script is not a tongue we speak. The cartographer treats it like a relic."* |
| 9 | `source_pool_opens` | minor | `engineFlag: first_breach_cleansed` set (Spec 5) | *"The world has gone briefly quiet — not silent, quieter — and in that quiet you find a page you had not noticed before."* |
| 10 | `synthesis_approaching` | minor | 4 of 5 tag puzzles solved | *"The cartographer lays out the readings side by side. A pattern is forming. One more should complete it."* |
| 11 | `synthesis_unlocked` | **major** | All 5 tag puzzles solved | Placeholder body (Spec 6 writes): *"The Synthesis lies open. [Synthesis content authored in Spec 6.]"* — sets `engineFlag: synthesis_complete` |

Trigger functions are cheap (flag or set-membership checks). Dedup set short-circuits already-fired entries.

### 4.2 The 8 main quests

All 8 authored in Spec 2. Objectives that depend on Spec 5/6 content use `comingSoon: true` flag.

#### Main 1 — Discover the Sickness *(offered at engine init, alongside `main_restore_town_square`)*

- **Title:** Discover the Sickness
- **Description:** "The forest, the mine, the coast — something is changing in places long thought safe. Begin to gather the cartographer's torn pages. They say more than they seem."
- **Objectives:**
  - Read 3 Codex Fragments — `codexRead × 3` (no targetTag — any tag counts)
- **Rewards:** 50 gold, 50 Lore XP, `offerQuest: main_investigate_wilds`, `offerQuest: main_investigate_stones`

#### Main 2 — Investigate the Wilds *(offered on Main 1 completion)*

- **Description:** "The Whispering Woods are speaking, and not in a tongue you know. Solve their Reading to understand what stirs in the Hollow."
- **Objectives:**
  - Collect & read 10 Wilds-tag fragments — `codexRead × 10` with `targetTag: CodexTag.wilds`
  - Lock the Wilds puzzle correctly — `custom` with `targetId: 'puzzle_wilds_solved'` (set by `lockCodexPuzzle` on success)
- **Rewards:** 100 gold, 75 Wayfinding XP, 25 gold (Spec 4 → blueprint), `offerQuest: main_cleanse_hollow`

#### Main 3 — Investigate the Stones *(offered alongside Main 2 on Main 1 completion)*

- Same shape as Main 2, for Stone tag
- **Description:** "The deep tappings in Darkstone speak a rhythm. The Glinting Vein is not a vein — read what the foreman saw."
- **Objectives:**
  - Collect & read 10 Stone-tag fragments — `codexRead × 10` with `targetTag: CodexTag.stone`
  - Lock the Stone puzzle correctly — `custom` with `targetId: 'puzzle_stone_solved'`
- **Rewards:** 100 gold, 75 Mining XP, 25 gold (Spec 4 → blueprint), `offerQuest: main_cleanse_vein`

#### Main 4 — Investigate the Tide *(offered after Coast unlocked — Spec 3 wires this)*

- Same shape, for Tide tag
- **Description:** "The Drowned Lighthouse has gone dark. Find what the keeper left in the loft."
- **Objectives:**
  - Collect & read 10 Tide-tag fragments — `codexRead × 10` with `targetTag: CodexTag.tide`
  - Lock the Tide puzzle correctly — `custom` with `targetId: 'puzzle_tide_solved'`
- **Rewards:** 100 gold, 75 Herbalism XP, 25 gold (Spec 4 → blueprint), `offerQuest: main_cleanse_tide`
- Note: in v1 ship, Main 4 is **not yet offered** — Spec 3 will add the Coast-unlock trigger that fires `offerQuest(MainQuests.investigateTide())`. The factory exists in Spec 2 so Spec 3 can call it cleanly.

#### Main 5 — Cleanse the Hollow *(offered on Main 2 completion)*

- **Description:** "The Reading told you what the Wilds need. Travel to Bloomwither Hollow with an Ironbark log and three Wildflowers. Defeat what guards the Hollow. Burn the offering at the rotted shrine."
- **Objectives:** (BOTH `comingSoon: true` in Spec 2)
  - Defeat the Echo of the Wilds — `custom` with `targetId: 'echo_wilds_defeated'`
  - Perform the Cleansing — `cleanse` with `targetId: 'breach_wilds'`
- Uncompletable until Spec 5 wires Echoes + cleansing

#### Main 6 — Cleanse the Vein *(offered on Main 3 completion)*

- Same shape, Stone-tag variant, both objectives `comingSoon`

#### Main 7 — Cleanse the Tide *(offered on Main 4 completion)*

- Same shape, Tide-tag variant, both objectives `comingSoon`

#### Main 8 — The Source Convergence *(offered when all three Cleanse quests complete — Spec 5)*

- **Description:** "Three breaches sealed. The Source itself is rising from beneath the world. Bring your three Cleansing Tokens to the Nexus of Echoes."
- **Objectives:** (BOTH `comingSoon: true`)
  - Travel to the Nexus of Echoes — `visit` with `targetId: 'nexus_of_echoes'`
  - Defeat The Source — `custom` with `targetId: 'source_defeated'`
- Uncompletable until Spec 6

### 4.3 QuestObjective extensions

```dart
class QuestObjective {
  final ObjectiveKind kind;
  final String? targetId;
  final String? targetTag;       // NEW — tag-filter for codexRead
  final int targetCount;
  int currentCount;
  bool comingSoon;               // NEW — defaults false; true marks Spec 5/6-dependent objectives
}
```

`_matches(objective, event)` extension: if `event` is `CodexFragmentReadEvent`, additionally check `objective.targetTag == null || fragment.tag == objective.targetTag`. Backward compatible: null `targetTag` matches any.

`comingSoon: true` objectives are never matched by `_matches` — they wait for explicit `engine.advanceQuestObjective(questId, objectiveIndex)` calls from Spec 5/6 implementations.

### 4.4 Coming Soon objective UI

In the Quest Log popover and Codex Quests tab, objectives with `comingSoon: true` render:

- Greyed-out checkbox (`Icons.lock_clock`)
- Label suffix: " *(Coming Soon)*"
- Tappable info-bubble: *"This objective requires content from a future update."*

### 4.5 RewardKind extension

```dart
enum RewardKind {
  gold, skillXp, item, blueprint, worldEvent, unlock,
  offerQuest,   // NEW — automatically offers a next quest by id
}
```

`_grantReward` switch arm:

```dart
case RewardKind.offerQuest:
  final next = MainQuests.findById(reward.targetId!);
  if (next != null) offerQuest(next);
  break;
```

`lib/models/main_quests.dart` (new file) holds factory functions for all 8 quests, since `Quest` is mutable (mutable `currentCount` per objective) and we need fresh instances on each offer.

---

## 5. Wiring & Integration

### 5.1 Fragment drop sources

#### 5.1.1 Obelisk inspections

Existing `inspect_obelisk` action in Whispering Woods I. Append to `_completeAction`:

```dart
if (action.id == 'inspect_obelisk') {
  tryDropFragment(CodexTag.wilds, 0.10);
  tryDropFragment(CodexTag.oldEmpire, 0.01);
}
```

#### 5.1.2 New `inspect_glyph` action in Darkstone Mine I and II

```dart
ZoneAction(
  id: 'inspect_glyph',
  name: 'Read Mine-Glyph',
  description: 'A chiseled glyph on the cavern wall, half-forgotten.',
  durationSeconds: 5,
  energyCost: 4,
  requiredSkill: SkillType.lore,
  requiredLevel: 1,
  xpReward: 30,
  lootTable: [],
),
```

Added to both Darkstone Mine I and II zone definitions in `lib/models/zone.dart`.

Wired drop in `_completeAction`:

```dart
if (action.id == 'inspect_glyph') {
  tryDropFragment(CodexTag.stone, 0.10);
  tryDropFragment(CodexTag.oldEmpire, 0.01);
}
```

#### 5.1.3 Beast defeats

In `_resolveCombat`, after existing `_notifyQuestObservers(BeastDefeatedEvent(beast.id))`:

```dart
final regionTag = _regionTagForBeast(beast.id);
if (regionTag != null) {
  tryDropFragment(regionTag, 0.08);
}

// Helper:
CodexTag? _regionTagForBeast(String beastId) {
  switch (beastId) {
    case 'forest_boar':
    case 'shadow_wolf':
      return CodexTag.wilds;
    case 'cave_spider':
    case 'cavern_troll':
      return CodexTag.stone;
    // Coast beasts (Spec 3) added later
    default:
      return null;
  }
}
```

#### 5.1.4 Scout-action completions

In `_completeAction`:

```dart
if (action.id == 'explore_forest_paths' || action.id == 'explore_deep_woods') {
  tryDropFragment(CodexTag.wilds, 0.05);
}
if (action.id == 'explore_rocky_trails' || action.id == 'explore_lower_shafts') {
  tryDropFragment(CodexTag.stone, 0.05);
}
```

#### 5.1.5 Tier-3 zone gathering (placeholder)

```dart
// In _completeAction for any non-combat, non-scout gather action:
if (engine.currentZone.tier >= 3) {
  tryDropFragment(CodexTag.source, 0.03);
}
```

Source pool gated by `first_breach_cleansed` flag — no-op until Spec 5.

#### 5.1.6 Echo defeat (placeholder contract)

Spec 2 documents the contract; Spec 5 implements:

```dart
// In future _onEchoDefeated(echoId, regionTag):
// - 2 guaranteed Source-tag fragments
// - 1 guaranteed region-tag fragment (Wilds/Stone/Tide based on Echo)
```

### 5.2 Drop machinery

```dart
void tryDropFragment(CodexTag tag, double chance) {
  if (!_isFragmentPoolOpen(tag)) return;
  if (_random.nextDouble() > chance) return;
  final eligible = CodexFragments.all
      .where((f) => f.tag == tag && !_knownCodexFragmentIds.contains(f.id))
      .toList();
  if (eligible.isEmpty) return;
  final fragment = eligible[_random.nextInt(eligible.length)];
  _grantFragment(fragment);
}

bool _isFragmentPoolOpen(CodexTag tag) {
  switch (tag) {
    case CodexTag.wilds: return true;
    case CodexTag.stone: return _regionStatus.containsKey('darkstone_mine_1');
    case CodexTag.tide: return _engineFlags.contains('coast_unlocked');
    case CodexTag.source: return _engineFlags.contains('first_breach_cleansed');
    case CodexTag.oldEmpire: return true;
    case CodexTag.misc: return true;
  }
}

void _grantFragment(CodexFragment fragment) {
  _knownCodexFragmentIds.add(fragment.id);
  log("📜 Codex Fragment found: ${fragment.title}", LogType.success);
  // Existing FloatingNotification widget hook
  notifyListeners();
}
```

### 5.3 Reading & puzzle Lock

```dart
void readCodexFragment(String fragmentId) {
  if (!_knownCodexFragmentIds.contains(fragmentId)) return;
  final alreadyRead = _readCodexFragmentIds.contains(fragmentId);
  _readCodexFragmentIds.add(fragmentId);

  if (!alreadyRead) {
    final fragment = CodexFragments.findById(fragmentId)!;
    final loreSkill = _skills[SkillType.lore]!;
    _skills[SkillType.lore] = loreSkill.addXp(15);
    log("Read Codex Fragment: ${fragment.title} (+15 Lore XP)", LogType.success);
    _notifyQuestObservers(CodexFragmentReadEvent(fragmentId));
  }
  notifyListeners();
}

void lockCodexPuzzle(CodexTag tag, List<String> orderedFragmentIds) {
  final expected = CodexFragments.all
      .where((f) => f.tag == tag)
      .toList()
    ..sort((a, b) => a.orderInTag.compareTo(b.orderInTag));

  if (orderedFragmentIds.length != expected.length) return;

  final correctness = <bool>[];
  for (var i = 0; i < orderedFragmentIds.length; i++) {
    correctness.add(orderedFragmentIds[i] == expected[i].id);
  }
  final allCorrect = correctness.every((c) => c);

  if (allCorrect) {
    if (_solvedTagPuzzles.contains(tag)) return; // No double rewards
    _solvedTagPuzzles.add(tag);
    _engineFlags.add('puzzle_${tag.name}_solved');
    final reading = CodexReadings.forTag(tag)!;
    for (var r in reading.rewards) _grantReward(r);
    _puzzleResultController.add(PuzzleResult(tag: tag, correctness: correctness, reading: reading));
    _checkMilestones();
  } else {
    _puzzleAttempts[tag] = (_puzzleAttempts[tag] ?? 0) + 1;
    final loreSkill = _skills[SkillType.lore]!;
    final newXp = max(0.0, loreSkill.xp - 3);
    _skills[SkillType.lore] = loreSkill.copyWith(xp: newXp);
    log("Puzzle attempt failed (−3 Lore XP). ${correctness.where((c) => c).length} of ${correctness.length} in place.", LogType.info);
    _puzzleResultController.add(PuzzleResult(tag: tag, correctness: correctness, reading: null));
  }
  notifyListeners();
}
```

### 5.4 New engine state additions (beyond Spec 1)

```dart
final Set<String> _readCodexFragmentIds = {};
final Set<CodexTag> _solvedTagPuzzles = {};
final Map<CodexTag, int> _puzzleAttempts = {};

final StreamController<PuzzleResult> _puzzleResultController = StreamController.broadcast();

Set<String> get readCodexFragmentIds => Set.unmodifiable(_readCodexFragmentIds);
Set<CodexTag> get solvedTagPuzzles => Set.unmodifiable(_solvedTagPuzzles);
Stream<PuzzleResult> get puzzleResults => _puzzleResultController.stream;
```

`PuzzleResult` class:

```dart
class PuzzleResult {
  final CodexTag tag;
  final List<bool> correctness;
  final CodexReading? reading;
  const PuzzleResult({required this.tag, required this.correctness, this.reading});
}
```

### 5.5 Main quest registration

`lib/models/main_quests.dart` (new):

```dart
class MainQuests {
  static Quest discoverSickness() => Quest(id: 'main_discover_sickness', ...);
  static Quest investigateWilds() => Quest(id: 'main_investigate_wilds', ...);
  // ... 6 more factories ...

  static Quest? findById(String id) {
    switch (id) {
      case 'main_discover_sickness': return discoverSickness();
      case 'main_investigate_wilds': return investigateWilds();
      // ... etc
      default: return null;
    }
  }
}
```

`_bootstrapStarterQuests` extension:

```dart
void _bootstrapStarterQuests() {
  // Existing Spec 1 restoration quest
  offerQuest(/* main_restore_town_square */);
  // NEW: Spec 2 first main quest
  offerQuest(MainQuests.discoverSickness());
}
```

### 5.6 Touch-list summary

| File | Change |
|---|---|
| `lib/models/codex.dart` | Add 50 `CodexFragment` const entries to `CodexFragments.all`; add `CodexReading` class + 5 Reading constants + `CodexReadings.forTag` helper + Synthesis placeholder body |
| `lib/models/quest.dart` | Add `targetTag` and `comingSoon` fields to `QuestObjective`; add `RewardKind.offerQuest`; add `PuzzleResult` class |
| `lib/models/main_quests.dart` *(new)* | 8 quest factory functions + `findById` lookup |
| `lib/models/milestone.dart` | Add 10 new `MilestoneEvent` entries to `Milestones.all` (11 total including Spec 1's) |
| `lib/models/zone.dart` | Add `inspect_glyph` ZoneAction to Darkstone Mine I and II |
| `lib/engine/game_engine.dart` | Add `_readCodexFragmentIds`, `_solvedTagPuzzles`, `_puzzleAttempts`, `_puzzleResultController` state + getters; add `tryDropFragment`, `_grantFragment`, `_isFragmentPoolOpen`, `_regionTagForBeast`, `lockCodexPuzzle`; extend `readCodexFragment`; extend `_grantReward` for `RewardKind.offerQuest`; extend `_matches` for `targetTag` filter; append `tryDropFragment` calls in `_completeAction` (Obelisk, glyph, scout, T3 gather) and `_resolveCombat`; offer Discover Sickness in `_bootstrapStarterQuests` |
| `lib/views/codex_view.dart` | Add Fragments tab (hidden until first read); per-tag collapsible sections; unread/read distinction; Solve Puzzle button; Synthesis section appearance logic |
| `lib/views/codex_puzzle_view.dart` *(new)* | Drag-to-reorder puzzle UI; Lock button; per-card green/red feedback after Lock; Reading overlay trigger on solve |
| `lib/widgets/reading_overlay.dart` *(new)* | Full-screen Reading display with tag-tinted background, body, rewards summary, Continue button |

---

## 6. Testing & Rollout

### 6.1 Test strategy

#### Content & model tests

**New `test/codex_fragments_test.dart`:**
- `CodexFragments.all.length == 50`
- 10 fragments per tag
- Every fragment has a unique `id`
- Every fragment has a unique `(tag, orderInTag)` pair
- `orderInTag` values 1–10 are all present per tag (no gaps)
- `CodexFragments.findById` round-trip
- `CodexReadings.forTag` returns non-null for each of the 5 tags

**Add to `test/quest_test.dart`:**
- `targetTag` filter: a `codexRead` objective with `targetTag: CodexTag.wilds` only advances on Wilds-tag fragment reads
- `comingSoon: true` objectives never advance via `_matches`
- `RewardKind.offerQuest` chains the next quest into `_activeQuests`

#### Drop & puzzle tests

**New `test/codex_drops_test.dart`:**
- `tryDropFragment(CodexTag.wilds, 1.0)` always succeeds when pool open and unread fragments exist
- `tryDropFragment(CodexTag.stone, 1.0)` no-ops when `darkstone_mine_1` not in `_regionStatus`
- After visiting Darkstone Mine I, Stone pool opens
- `tryDropFragment(CodexTag.source, 1.0)` no-ops without `first_breach_cleansed`
- Once all 10 Wilds collected, additional `tryDropFragment(CodexTag.wilds, 1.0)` calls no-op
- `readCodexFragment` is idempotent: only first call grants XP

**New `test/codex_puzzle_test.dart`:**
- `lockCodexPuzzle(CodexTag.wilds, [correct])` adds tag to `_solvedTagPuzzles`, grants rewards, sets `puzzle_wilds_solved` flag, emits `PuzzleResult` with all-true correctness
- `lockCodexPuzzle(CodexTag.wilds, [wrong])` does NOT add to `_solvedTagPuzzles`, deducts 3 Lore XP (floor 0), emits `PuzzleResult` with partial correctness
- Re-locking after fix grants full reward — no penalty stacking on success
- Already-solved puzzle: re-locking is no-op (no double rewards)
- Lore XP clamps to 0 (no negative)

#### Engine integration tests

**Add to `test/game_engine_test.dart`:**
- Beast defeat in Whispering Woods I rolls Wilds-tag drop (mocked RNG forces success)
- Beast defeat in Darkstone Mine I rolls Stone-tag drop
- `inspect_obelisk` completion rolls both Wilds AND Old Empire drop attempts
- `inspect_glyph` exists on Darkstone Mine I and II and rolls Stone + Old Empire on completion

#### Milestone tests

**Add to `test/quest_engine_test.dart`:**
- `first_codex_fragment` fires on first fragment collected; idempotent
- `first_codex_read` fires on first read
- `first_wilds_drop` / `first_stone_drop` fire only on their respective tags
- `second_breach_concept` fires only when ≥1 fragment from TWO different breach tags — verify with each pair combination
- `synthesis_approaching` fires on 4-of-5; `synthesis_unlocked` on 5-of-5

#### Main quest chain tests

**Add to `test/quest_test.dart`:**
- `_bootstrapStarterQuests` offers both `main_restore_town_square` AND `main_discover_sickness`
- Completing Discover auto-offers Investigate Wilds
- `main_investigate_wilds` blocked until 10 Wilds read AND `puzzle_wilds_solved` flag set
- Solving Wilds puzzle sets the flag and completes the custom objective
- Cleanse quests' `comingSoon` objectives never increment regardless of events

#### Widget tests

**Add to `test/widget_test.dart`:**
- Fragments tab hidden when `_knownCodexFragmentIds.isEmpty`
- Fragments tab appears after first fragment collected
- Tag section renders only if that tag has ≥1 fragment
- Solve Puzzle button only appears for tags with 3+ fragments
- Solving a puzzle in the Puzzle view shows the Reading overlay
- Locking wrong puzzle highlights cards with green/red per correctness
- Synthesis section appears only after 4-of-5 puzzles solved

#### Integration smoke test

1. Fresh engine → Discover Sickness quest active
2. Force-drop 3 Wilds fragments → read all 3 → Discover completes → Investigate Wilds offered
3. Force-drop remaining 7 Wilds → collection full
4. Read all 10 → Investigate Wilds objective 1 of 2 done
5. Lock puzzle correct order → Reading overlay → Cleanse the Hollow offered with `comingSoon` objectives
6. Simulate events targeting Cleanse objectives → confirm they don't advance

### 6.2 Implementation order

Single PR, internally staged:

1. **Data layer — fragments** — Fill `CodexFragments.all` with all 50 entries. Verify count + uniqueness tests.
2. **Data layer — readings** — Add `CodexReading` class + 5 Reading constants + Synthesis placeholder.
3. **Data layer — milestones** — Extend `Milestones.all` with 10 new entries.
4. **Data layer — main quests** — Create `lib/models/main_quests.dart` with 8 factories. Add `targetTag`, `comingSoon` to `QuestObjective`. Add `RewardKind.offerQuest`.
5. **Engine — drop machinery** — Add `tryDropFragment`, `_grantFragment`, `_isFragmentPoolOpen`, `_regionTagForBeast`. Extend `readCodexFragment`. Add `_readCodexFragmentIds`.
6. **Engine — puzzle Lock** — Add `lockCodexPuzzle`, `_solvedTagPuzzles`, `_puzzleAttempts`, `_puzzleResultController`, `PuzzleResult`.
7. **Engine — wire drops into existing methods** — Append `tryDropFragment` calls. Wire 4 existing beasts in `_regionTagForBeast`.
8. **Zone content — `inspect_glyph`** — Add the new ZoneAction to Darkstone Mine I and II.
9. **Engine — bootstrap Discover quest** — Add to `_bootstrapStarterQuests`.
10. **Engine — `_grantReward` for `offerQuest`** — Extend the switch arm. Quest chaining tests pass.
11. **UI — Fragments tab in Codex view** — Tag sections, unread/read, Solve Puzzle button.
12. **UI — Codex Puzzle view** — `ReorderableListView` + Lock + per-card feedback.
13. **UI — Reading overlay** — New widget, full-screen modal.
14. **UI — Coming Soon objective rendering** — Quest Log popover + Codex Quests tab.
15. **UI — Synthesis section** — In Fragments tab, conditional on 4+ tags solved.
16. **Tests** — written alongside each step.

### 6.3 Migration & backward compatibility

No persistence; no save migration. Player first-launch change:
- Sees existing Restore Town Square quest + new Discover Sickness quest
- Obelisk visits may drop fragments — Codex's Fragments tab appears after first read
- Early game becomes lore-rich without changing existing systems

### 6.4 Documentation updates

- `README.md` — extend "Codex & Quests" section with puzzle + Reading info
- Inline `///` doc comments on `tryDropFragment`, `lockCodexPuzzle`, puzzle UI reorder semantics

### 6.5 Risks & deferrals

- **50 fragments is a lot to balance.** Drop rates assumed; first playtest may show too sparse/dense. Mitigation: rates live as numeric literals in `tryDropFragment` callsites — single-PR balance pass post-Spec-2.
- **Per-card green/red feedback is generous.** Puzzles likely solve in 2–4 attempts. User explicitly chose this. The −3 Lore XP per wrong-Lock keeps brute-force from being free. If playtest shows trivial, revisit.
- **Source / Tide pools stay empty until later specs.** Quest log shows main quests for Tide/Cleanse/Source as "Coming Soon" — risks player confusion. Mitigation: Coming Soon affordance + info-bubble explains "future update".
- **Stone-tag requires new `inspect_glyph` actions.** Small content addition flagged. Alternative: defer and let Stone fragments only drop from beasts + scouts (slower fill).
- **Deferred to Spec 3:** Tide-tag drop sources wiring (Coast beasts/obelisks); add Coast beasts to `_regionTagForBeast`
- **Deferred to Spec 5:** `first_breach_cleansed` flag setting; Echo defeat guaranteed drops; Cleansing ritual quest completion
- **Deferred to Spec 6:** Synthesis Reading body; True Ending epilogue body; Achievement entries for Witness titles; NG+ starting-bonus logic from `true_ending_unlocked`

### 6.6 Player walkthrough — what shipping looks like

A player after Spec 2:

1. Fresh app → sees Restore Town Square (Spec 1) + Discover Sickness (new) in Quest Log
2. Restores stations → Cartographer's Tent appears → opens Codex → Quests/Beasts/Regions tabs visible (Fragments still hidden)
3. Inspects an Obelisk → 10% chance → "📜 Codex Fragment: *Black Sap*" floating notification fires
4. Opens Codex → Fragments tab appears for the first time → sees one Wilds fragment, unread
5. Taps the fragment → text appears → +15 Lore XP → Discover Sickness objective: 1 of 3
6. After 3 reads → Discover completes → milestone modal → Investigate Wilds offered
7. Grinds Whispering Woods → fragments fill over a few hours → puzzle button at 3 → ignored until 10 collected
8. Drags fragments into chronological order, Locks → 7 of 10 correct → green/red highlights → −3 Lore XP → log notes wrong-Lock
9. Adjusts 3 cards, Locks again → all 10 correct → particle burst → **Reading overlay**: *The Warden's Account* → +60 Lore XP + 25 gold + Witness Achievement stub
10. Cleanse the Hollow quest offered with "Coming Soon" objectives → player sees arc shape ahead
11. Investigates Stones similarly. Hits 2-tag threshold → **major modal milestone**: *"The cartographer's eyes go very still..."* — concept "three Breaches" enters the player's world
12. Old Empire fragment from a rare Obelisk drop → quietly fills the lore-completionist track

The game now has a story.

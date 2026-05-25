import 'quest.dart';

enum CodexTag { wilds, stone, tide, source, oldEmpire, misc }

class CodexFragment {
  final String id;
  final CodexTag tag;
  final String title;            // short title (e.g., "On Black Sap")
  final String text;             // 1–3 sentences
  final String? sourceHint;      // "Found at: Crumbling Obelisk in Whispering Woods I"
  final int orderInTag;          // puzzle ordering; Spec 2 uses, Spec 1 stores inertly

  const CodexFragment({
    required this.id,
    required this.tag,
    required this.title,
    required this.text,
    this.sourceHint,
    required this.orderInTag,
  });
}

class CodexFragments {
  static const List<CodexFragment> all = [
    // ─── WILDS ────────────────────────────────────────
    CodexFragment(
      id: 'wilds_01',
      tag: CodexTag.wilds,
      title: 'First Spring',
      text: "Last spring the bluebells came up early, faces bright. I marked the date in my journal: a good year coming. I was wrong about the year.",
      sourceHint: "Found at: Crumbling Obelisk, Whispering Woods I",
      orderInTag: 1,
    ),
    CodexFragment(
      id: 'wilds_02',
      tag: CodexTag.wilds,
      title: 'Black Sap',
      text: "I cut a young oak for firewood today and the sap ran black. I left the axe in the wood and walked away.",
      sourceHint: "Found at: Forest beast drop, Whispering Woods",
      orderInTag: 2,
    ),
    CodexFragment(
      id: 'wilds_03',
      tag: CodexTag.wilds,
      title: 'The Quiet',
      text: "The birds stopped singing in the eastern groves. Not gone — I can see them. They just stopped.",
      sourceHint: "Found at: Whispering Woods scout action",
      orderInTag: 3,
    ),
    CodexFragment(
      id: 'wilds_04',
      tag: CodexTag.wilds,
      title: 'The First Sick Boar',
      text: "A boar charged me at dusk. Its eyes were the wrong color. I killed it; it tasted of iron and something older.",
      sourceHint: "Found at: Forest beast drop, Whispering Woods",
      orderInTag: 4,
    ),
    CodexFragment(
      id: 'wilds_05',
      tag: CodexTag.wilds,
      title: 'Ironbark Forgets',
      text: "The old folk used to call certain oaks Ironbark for the strength of their wood. The Ironbarks have begun to soften from the inside, weeping that same black sap.",
      sourceHint: "Found at: Crumbling Obelisk, Whispering Woods I",
      orderInTag: 5,
    ),
    CodexFragment(
      id: 'wilds_06',
      tag: CodexTag.wilds,
      title: 'Roots in the Deep',
      text: "I tracked a sick wolf to a clearing and found roots running upward from the soil. Roots, growing the wrong way. I did not stay to see what they reached for.",
      sourceHint: "Found at: Whispering Woods II beast drop",
      orderInTag: 6,
    ),
    CodexFragment(
      id: 'wilds_07',
      tag: CodexTag.wilds,
      title: "The Warden's Walk",
      text: "I have walked these woods forty years. I no longer know them. The trails move when I am not looking.",
      sourceHint: "Found at: Whispering Woods scout action",
      orderInTag: 7,
    ),
    CodexFragment(
      id: 'wilds_08',
      tag: CodexTag.wilds,
      title: 'The Hollow Calls',
      text: "There is a hollow in the deepest grove where no warden goes. I dreamed of it last night. I dreamed it called my name.",
      sourceHint: "Found at: Crumbling Obelisk, Whispering Woods II",
      orderInTag: 8,
    ),
    CodexFragment(
      id: 'wilds_09',
      tag: CodexTag.wilds,
      title: 'The Last Bluebell',
      text: "I picked a bluebell today. It came up with thread, not roots — a long dark thread that ran deep into the soil. I did not pull further.",
      sourceHint: "Found at: Whispering Woods foraging",
      orderInTag: 9,
    ),
    CodexFragment(
      id: 'wilds_10',
      tag: CodexTag.wilds,
      title: 'A Door I Do Not Open',
      text: "I have stopped going to the Hollow. I lock the warden's gate at night now. Something is on the other side. It knows my name.",
      sourceHint: "Found at: Whispering Woods II Obelisk (rare)",
      orderInTag: 10,
    ),

    // ─── STONE ────────────────────────────────────────
    CodexFragment(
      id: 'stone_01',
      tag: CodexTag.stone,
      title: 'The Vein',
      text: "We struck a copper vein last week thick as my arm. The lads cheered. I should have asked why no one had cut it before us.",
      sourceHint: "Found at: Mine-Glyph, Darkstone Mine I",
      orderInTag: 1,
    ),
    CodexFragment(
      id: 'stone_02',
      tag: CodexTag.stone,
      title: 'The Tap',
      text: "There is a sound in the deep shafts at night. A slow tapping. Three taps, a pause, three taps. We tell the new boys it is settling rock.",
      sourceHint: "Found at: Darkstone scout action",
      orderInTag: 2,
    ),
    CodexFragment(
      id: 'stone_03',
      tag: CodexTag.stone,
      title: 'The Light That Should Not Glow',
      text: "Found a chunk of ore today that glowed in my palm without sun or flame. I pocketed it. I think that was wrong.",
      sourceHint: "Found at: Cave beast drop, Darkstone",
      orderInTag: 3,
    ),
    CodexFragment(
      id: 'stone_04',
      tag: CodexTag.stone,
      title: 'The Glinting Vein',
      text: "The deep wall opened on a vein that pulsed like a slow heart. The foreman called it the Glinting. He looked at it too long.",
      sourceHint: "Found at: Mine-Glyph, Darkstone Mine II",
      orderInTag: 4,
    ),
    CodexFragment(
      id: 'stone_05',
      tag: CodexTag.stone,
      title: 'Stone Remembers',
      text: "I drove my pick into a fresh seam and the rock — I swear it — flinched. The strike rang back wrong, like striking a bell that does not want to be rung.",
      sourceHint: "Found at: Darkstone Mine II gathering",
      orderInTag: 5,
    ),
    CodexFragment(
      id: 'stone_06',
      tag: CodexTag.stone,
      title: "The Foreman's Walk",
      text: "The foreman has stopped sleeping. He walks the lower shafts at night now, his lamp out, his eyes lit. He does not see us anymore.",
      sourceHint: "Found at: Cave beast drop, Darkstone",
      orderInTag: 6,
    ),
    CodexFragment(
      id: 'stone_07',
      tag: CodexTag.stone,
      title: 'What Lives in the Tap',
      text: "I counted the tapping last night. Three taps, a pause, three taps — but the pauses are getting shorter. It is learning to speak.",
      sourceHint: "Found at: Darkstone scout action",
      orderInTag: 7,
    ),
    CodexFragment(
      id: 'stone_08',
      tag: CodexTag.stone,
      title: 'Trolls Are Listening',
      text: "The cavern trolls do not attack the foreman. They watch him pass. The trolls know something the foreman has forgotten.",
      sourceHint: "Found at: Cavern Troll defeat, Darkstone Mine II",
      orderInTag: 8,
    ),
    CodexFragment(
      id: 'stone_09',
      tag: CodexTag.stone,
      title: 'The Vein Is a Wound',
      text: "I understand now: the Glinting is not a vein. It is a wound in the world. We have been picking at a wound.",
      sourceHint: "Found at: Mine-Glyph, Darkstone Mine II",
      orderInTag: 9,
    ),
    CodexFragment(
      id: 'stone_10',
      tag: CodexTag.stone,
      title: 'The Tapping Knows My Name',
      text: "The tapping has my rhythm now. When I hammer, it answers. When I stop, it waits. I will not go down again.",
      sourceHint: "Found at: Darkstone Mine II rare drop",
      orderInTag: 10,
    ),

    // ─── TIDE ─────────────────────────────────────────
    CodexFragment(
      id: 'tide_01',
      tag: CodexTag.tide,
      title: "The Lighthouse Keeper's Log",
      text: "Day one of the keeper's new rotation. Tide normal. Lamp lit. Gulls overhead. A quiet station, this Drowned Lighthouse.",
      sourceHint: "Found at: Sundered Coast I (Spec 3)",
      orderInTag: 1,
    ),
    CodexFragment(
      id: 'tide_02',
      tag: CodexTag.tide,
      title: 'Brine in the Cisterns',
      text: "The freshwater cistern tastes of salt this morning. I checked the seals: intact. The salt is coming from below.",
      sourceHint: "Found at: Sundered Coast (Spec 3)",
      orderInTag: 2,
    ),
    CodexFragment(
      id: 'tide_03',
      tag: CodexTag.tide,
      title: 'The Hound at the Door',
      text: "A wet hound came to the keeper's door last night and would not leave. Its eyes shone like fish scales. I closed the door.",
      sourceHint: "Found at: Tide Hound defeat (Spec 3)",
      orderInTag: 3,
    ),
    CodexFragment(
      id: 'tide_04',
      tag: CodexTag.tide,
      title: 'The Pier Sang',
      text: "Walking the pier at moonrise, I heard it sing — a long low note from beneath the planks. I have not walked the pier since.",
      sourceHint: "Found at: Coast scout action (Spec 3)",
      orderInTag: 4,
    ),
    CodexFragment(
      id: 'tide_05',
      tag: CodexTag.tide,
      title: 'The Salt That Bites',
      text: "I tried to make a salt-cure of fresh fish. The salt smoked in the bowl, hissed when it touched the meat. This is not the salt of my grandmother.",
      sourceHint: "Found at: Sundered Coast II (Spec 3)",
      orderInTag: 5,
    ),
    CodexFragment(
      id: 'tide_06',
      tag: CodexTag.tide,
      title: 'Drowned Things Watching',
      text: "I see them at low tide now — shapes in the shallows that do not move when the water moves. They wait.",
      sourceHint: "Found at: Brine Crawler defeat (Spec 3)",
      orderInTag: 6,
    ),
    CodexFragment(
      id: 'tide_07',
      tag: CodexTag.tide,
      title: 'The Lamp Will Not Stay Lit',
      text: "I lit the great lamp at dusk. By midwatch it had gone out, though I had filled the reservoir myself. I lit it again. It guttered as if breathed on.",
      sourceHint: "Found at: Coast Obelisk (Spec 3)",
      orderInTag: 7,
    ),
    CodexFragment(
      id: 'tide_08',
      tag: CodexTag.tide,
      title: 'The Crawler in the Cellar',
      text: "A brine crawler in the cellar this morning, big as a hound. I drove it off. There are more, I am sure, in the dark.",
      sourceHint: "Found at: Brine Crawler defeat (Spec 3)",
      orderInTag: 8,
    ),
    CodexFragment(
      id: 'tide_09',
      tag: CodexTag.tide,
      title: "The Sea Speaks the Foreman's Name",
      text: "I dreamed last night of a man with a lamp out, walking deep mine shafts. The sea told me his name. I have never been to the mines.",
      sourceHint: "Found at: Coast Obelisk (Spec 3)",
      orderInTag: 9,
    ),
    CodexFragment(
      id: 'tide_10',
      tag: CodexTag.tide,
      title: 'The Light Has Gone Out',
      text: "The great lamp is out and will not relight. The drowned have come ashore. I write this from the keeper's loft, while I still can.",
      sourceHint: "Found at: Drowned Lighthouse rare drop (Spec 3)",
      orderInTag: 10,
    ),

    // ─── SOURCE ───────────────────────────────────────
    CodexFragment(
      id: 'source_01',
      tag: CodexTag.source,
      title: 'A Common Thread',
      text: "Three sicknesses, three regions. Three voices speaking through different mouths. The thread runs deeper than any one of them.",
      sourceHint: "Found at: cross-biome rare drop (Spec 5)",
      orderInTag: 1,
    ),
    CodexFragment(
      id: 'source_02',
      tag: CodexTag.source,
      title: 'The First Word',
      text: "Before the woods spoke wrongly, before the stones rang false, before the sea took the lamp — something said its first word. The world has been answering ever since.",
      sourceHint: "Found at: T3 zone gathering (Spec 5)",
      orderInTag: 2,
    ),
    CodexFragment(
      id: 'source_03',
      tag: CodexTag.source,
      title: 'Beneath Every Depth',
      text: "The miners thought the Glinting was the bottom. It was not. Beneath every stone is another stone. Beneath every depth, another depth.",
      sourceHint: "Found at: Echo of the Stone defeat (Spec 5)",
      orderInTag: 3,
    ),
    CodexFragment(
      id: 'source_04',
      tag: CodexTag.source,
      title: 'The Old Word for It',
      text: "The old tongue had a word for what is happening. It meant 'echo' — but the kind of echo a struck wound makes, not the kind a struck bell makes.",
      sourceHint: "Found at: T3 zone gathering (Spec 5)",
      orderInTag: 4,
    ),
    CodexFragment(
      id: 'source_05',
      tag: CodexTag.source,
      title: 'It Wears Their Faces',
      text: "The Echo of the Wilds is not the Wilds. The Echo of the Stone is not the Stone. The Echo of the Tide is not the Tide. They are all the same Echo, wearing the faces it has learned.",
      sourceHint: "Found at: Echo defeat (Spec 5)",
      orderInTag: 5,
    ),
    CodexFragment(
      id: 'source_06',
      tag: CodexTag.source,
      title: 'The Old Empire Knew',
      text: "The First Age built Beacons at the breach-sites and called them by their right names. The names are forgotten. The Beacons are toppled. The breaches are open.",
      sourceHint: "Found at: Echo defeat (Spec 5)",
      orderInTag: 6,
    ),
    CodexFragment(
      id: 'source_07',
      tag: CodexTag.source,
      title: 'The Source Speaks Through Three Mouths',
      text: "Three mouths to speak with. Three throats to silence. To unmake the speaker, you must unmake the speech.",
      sourceHint: "Found at: Echo defeat (Spec 5)",
      orderInTag: 7,
    ),
    CodexFragment(
      id: 'source_08',
      tag: CodexTag.source,
      title: 'A Convergence',
      text: "When the three are silenced — and only then — the speaker will come out from beneath the world to find what silenced them. It will not be pleased.",
      sourceHint: "Found at: Echo defeat (Spec 5)",
      orderInTag: 8,
    ),
    CodexFragment(
      id: 'source_09',
      tag: CodexTag.source,
      title: 'The Place It Will Come',
      text: "Where the three roads meet beneath the world: that is where it will come. The First Age had a name for the place. We will have to remember.",
      sourceHint: "Found at: cross-biome rare drop (Spec 5)",
      orderInTag: 9,
    ),
    CodexFragment(
      id: 'source_10',
      tag: CodexTag.source,
      title: 'What Remains',
      text: "If you stand at the convergence and unmake the speaker, the world will be quieter. Not silent. Quieter. That is the most you can hope for. Hope for it.",
      orderInTag: 10,
    ),

    // ─── OLD EMPIRE ───────────────────────────────────
    CodexFragment(
      id: 'empire_01',
      tag: CodexTag.oldEmpire,
      title: 'The First Age Spoke',
      text: "Before our age there was an older one. They left their script carved on stones we still cannot read. They wrote, mostly, about silence.",
      sourceHint: "Found at: any Obelisk (rare)",
      orderInTag: 1,
    ),
    CodexFragment(
      id: 'empire_02',
      tag: CodexTag.oldEmpire,
      title: 'The Beacons of Asar',
      text: "The First Age built Five Beacons to mark where the world is thin. The Beacons fell long ago. The places remained thin.",
      sourceHint: "Found at: any Obelisk (rare)",
      orderInTag: 2,
    ),
    CodexFragment(
      id: 'empire_03',
      tag: CodexTag.oldEmpire,
      title: "The Cartographer's Last Map",
      text: "The last cartographer of the First Age died with one map unfinished. It marked the breach-sites. It marked the convergence. It did not mark a way home.",
      sourceHint: "Found at: any Obelisk (rare)",
      orderInTag: 3,
    ),
    CodexFragment(
      id: 'empire_04',
      tag: CodexTag.oldEmpire,
      title: 'The Tongue of Asar',
      text: "Their tongue had thirty-two words for \"silence\" and one for \"war.\" We have the inverse problem.",
      sourceHint: "Found at: any Obelisk (rare)",
      orderInTag: 4,
    ),
    CodexFragment(
      id: 'empire_05',
      tag: CodexTag.oldEmpire,
      title: 'The Long Watch',
      text: "The First Age built a watch that would last a thousand years. The watch lasted nine hundred. We are the watch now, and we did not know.",
      sourceHint: "Found at: any Obelisk (rare)",
      orderInTag: 5,
    ),
    CodexFragment(
      id: 'empire_06',
      tag: CodexTag.oldEmpire,
      title: 'The Old Empire Fell To Hope',
      text: "The records say the First Age fell not to war or famine but to hope. They believed the breaches could be closed forever. They were wrong; the breaches reopened, and they had unmade their watch.",
      sourceHint: "Found at: any Obelisk (rare)",
      orderInTag: 6,
    ),
    CodexFragment(
      id: 'empire_07',
      tag: CodexTag.oldEmpire,
      title: 'What the Beacons Were',
      text: "The Beacons were not lights. They were instruments. They sang a single low note at the breach-sites. The note kept the speaker quiet.",
      sourceHint: "Found at: any Obelisk (rare)",
      orderInTag: 7,
    ),
    CodexFragment(
      id: 'empire_08',
      tag: CodexTag.oldEmpire,
      title: "The Old Empire's Wager",
      text: "Knowing the breaches would reopen, the First Age left us a wager: build the instruments anew, or accept the diminished world. The instruments are hard to build.",
      sourceHint: "Found at: any Obelisk (rare)",
      orderInTag: 8,
    ),
    CodexFragment(
      id: 'empire_09',
      tag: CodexTag.oldEmpire,
      title: 'The Inheritor',
      text: "Their last writing, in their tongue: \"to whoever follows: the wager is yours. We are sorry. We hoped.\" Their script for \"hoped\" is the same as their script for \"failed.\"",
      sourceHint: "Found at: Silas (Lore Keeper) at Trusted Patron rep (Spec 6)",
      orderInTag: 9,
    ),
    CodexFragment(
      id: 'empire_10',
      tag: CodexTag.oldEmpire,
      title: 'The Quiet Inheritance',
      text: "To inherit the watch is to choose what to do with it. The First Age chose hope. You may choose otherwise. The world will know which you chose.",
      sourceHint: "Found at: any Obelisk (very rare)",
      orderInTag: 10,
    ),
  ];

  static CodexFragment? findById(String id) {
    for (var f in all) {
      if (f.id == id) return f;
    }
    return null;
  }
}

class BestiaryEntry {
  final String beastId;
  final DateTime firstDefeated;
  int defeatCount;
  Set<String> droppedItemIds;

  BestiaryEntry({
    required this.beastId,
    required this.firstDefeated,
    required this.defeatCount,
    required this.droppedItemIds,
  });
}

enum RegionStatus { locked, anomalous, spreading, cleansed }

class RegionStatusInfo {
  final String zoneId;
  RegionStatus status;
  DateTime? discoveredAt;
  DateTime? cleansedAt;

  RegionStatusInfo({
    required this.zoneId,
    required this.status,
    this.discoveredAt,
    this.cleansedAt,
  });
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;             // emoji
  final bool hidden;             // hidden achievements don't appear until earned
  final String? titleUnlock;     // optional Title text granted on unlock

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.hidden = false,
    this.titleUnlock,
  });
}

class Achievements {
  static const List<Achievement> all = [];  // empty in Spec 1; Spec 6 fills
}

class CodexReading {
  final CodexTag tag;
  final String title;
  final String body;
  final List<QuestReward> rewards;

  const CodexReading({
    required this.tag,
    required this.title,
    required this.body,
    required this.rewards,
  });
}

class CodexReadings {
  static const CodexReading wildsReading = CodexReading(
    tag: CodexTag.wilds,
    title: "The Warden's Account",
    body: '''Forty years I have walked the Whispering Woods. I know its trails the way a blacksmith knows his anvil — by the small marks each leaves on me. So when the bluebells came up early last spring, I noticed. When the sap ran black, I noticed. When the birds stopped singing in the eastern groves, I noticed.

Something has come into the wood that does not belong. I have followed its trail to a hollow I will not name. It dreams. It calls. It learns the names of those who walk near it. It learned mine, and I have stopped walking near it.

If you read this, you have done what I could not. Find the Hollow. Take with you an Ironbark log, well-seasoned, and three Wildflowers cut at first light. Burn the offering at the rotted shrine within. What rises will fight you. It must fight you. There is no other way to close what has opened here.

— The Warden''',
    rewards: [
      QuestReward(kind: RewardKind.skillXp, targetId: 'lore', amount: 60),
      QuestReward(kind: RewardKind.gold, amount: 25),
    ],
  );

  static const CodexReading stoneReading = CodexReading(
    tag: CodexTag.stone,
    title: "The Foreman's Confession",
    body: '''They will tell you the foreman went mad. He did not. He went silent first, and silence is not madness — it is the absence of the noise we use to drown out the truth.

The Glinting Vein is not a vein. It is a wound. Beneath the lowest shaft of Darkstone Mine there is a pulsing, glowing lens of stone that should not be, and the foreman walked into the shaft one night and put his ear to it. The lens spoke to him. It is still speaking. He answers it now in his sleep, and the deep tappings in the mine answer him back, and so the conversation goes, growing.

If you would silence the wound, bring an alchemist's draught — wildflower tinctured with river clay, twice-distilled — and pour it into the Glinting at the moment its pulse lengthens. What dwells in the wound will rise to defend it. You must endure the rising. Then pour. The lens will close.

— What the foreman wrote on the wall the morning he stopped speaking''',
    rewards: [
      QuestReward(kind: RewardKind.skillXp, targetId: 'lore', amount: 60),
      QuestReward(kind: RewardKind.gold, amount: 25),
    ],
  );

  static const CodexReading tideReading = CodexReading(
    tag: CodexTag.tide,
    title: "The Keeper's Last Page",
    body: '''I am the keeper of the Drowned Lighthouse. I write this from the loft above the lamp room. The lamp will not stay lit. The drowned have come ashore. I do not have much time.

The lamp is not just a lamp. The old keepers told me, and I did not listen, because old keepers tell many things. They told me the lamp is a Beacon — that it sings, when properly lit, a low note that keeps the wrong things in the sea where they belong. The lamp has stopped singing. The note has gone out of the world. The wrong things are walking up the pier.

If you find this, do not relight the lamp with oil. Lamp oil will not hold. Carry a Salt Crystal — the pure kind from the deep tide pools, not the brine-stained kind from the cliffs — and set it within the lamp's heart. The Crystal will sing the note the lamp has forgotten. Something old in the sea will rise to silence the song. Do not let it.

— The Keeper, from the loft, by lamplight''',
    rewards: [
      QuestReward(kind: RewardKind.skillXp, targetId: 'lore', amount: 60),
      QuestReward(kind: RewardKind.gold, amount: 25),
    ],
  );

  static const CodexReading sourceReading = CodexReading(
    tag: CodexTag.source,
    title: 'The Convergence',
    body: '''Three breaches. Three Echoes wearing three faces. One Source beneath them all, and beneath the Source — beneath every depth, you have read this before — another depth.

The Echoes are not the Source. The Echoes are the Source's voice in three different mouths: a wood-mouth, a stone-mouth, a sea-mouth. Silence the three mouths and the Source will come out from beneath the world to see what has silenced them. It will come to the convergence — the place where the three breach-roads meet beneath the surface, which the First Age called by a name we do not remember.

You will need a token from each cleansed breach. You will need the Beacons remembered. You will need to stand at the convergence and unmake the speaker. What waits there cannot be reasoned with. It can only be unmade.

If you go: do not bring hope. Hope was the First Age's mistake. Bring the instruments. Bring the silence.''',
    rewards: [
      QuestReward(kind: RewardKind.skillXp, targetId: 'lore', amount: 100),
      QuestReward(kind: RewardKind.unlock, targetId: 'nexus_understood', amount: 1),
    ],
  );

  static const CodexReading oldEmpireReading = CodexReading(
    tag: CodexTag.oldEmpire,
    title: "The Cartographer's Wager",
    body: '''The First Age fell because they hoped. They built the Beacons, they sang the silence into the world, and they believed they had closed the wound forever. They had not. The wound reopened in their grandchildren's time, and the grandchildren did not know the song, because the First Age had unmade the watch when they thought the song was no longer needed.

They left us a map and a wager. The map is a stone, in a place I will not name in this writing, that shows the breach-sites and the convergence. The wager is this: build the instruments anew, or accept the diminished world. The instruments are hard to build. The diminished world is easy to live in. They left us free to choose.

If you have read this, you have chosen. The choice is silent and personal and has no audience. The world will know which you chose only by what the world becomes.

— from the unfinished map of the last cartographer of the First Age''',
    rewards: [
      QuestReward(kind: RewardKind.skillXp, targetId: 'lore', amount: 120),
      QuestReward(kind: RewardKind.unlock, targetId: 'true_ending_unlocked', amount: 1),
    ],
  );

  static const CodexReading synthesisReading = CodexReading(
    tag: CodexTag.misc,
    title: 'The Synthesis',
    body: '''[Synthesis content authored in Spec 6 — final integration with Nexus unlock and ending sequence.]''',
    rewards: [],
  );

  static CodexReading? forTag(CodexTag tag) {
    switch (tag) {
      case CodexTag.wilds: return wildsReading;
      case CodexTag.stone: return stoneReading;
      case CodexTag.tide: return tideReading;
      case CodexTag.source: return sourceReading;
      case CodexTag.oldEmpire: return oldEmpireReading;
      case CodexTag.misc: return null;
    }
  }
}

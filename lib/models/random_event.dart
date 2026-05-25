import 'skill.dart';

enum EventCategory { interruption, discovery, traveler, omen }

enum EventRewardKind { item, gold, skillXp, fragment }

class EventReward {
  final EventRewardKind kind;
  final String? targetId;
  final int amount;
  const EventReward({required this.kind, this.targetId, required this.amount});
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

class RandomEvent {
  final String id;
  final EventCategory category;
  final String title;
  final String prompt;
  final List<RandomEventOption> options;
  final List<SkillType>? triggerSkills;
  final List<int>? triggerZoneTiers;

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

class ActiveRandomEventState {
  final RandomEvent event;
  final DateTime startedAt;
  const ActiveRandomEventState({required this.event, required this.startedAt});
}

class RandomEvents {
  // ─── Interruption (5) ───
  static const RandomEvent beeSwarm = RandomEvent(
    id: 'bee_swarm',
    category: EventCategory.interruption,
    title: 'Bee Swarm',
    prompt: 'A wild bee swarm bursts from the bush you were searching!',
    triggerSkills: [SkillType.herbalism],
    options: [
      RandomEventOption(
        text: 'Endure the stings',
        feedback: 'You take the stings and pluck the bloom anyway.',
        healthCost: 8,
        rewards: [EventReward(kind: EventRewardKind.item, targetId: 'wildflower', amount: 2)],
      ),
      RandomEventOption(
        text: 'Smoke them out',
        feedback: 'A small fire drives the bees off. You gather extra honey.',
        requiredItemId: 'oak_log',
        requiredItemCount: 1,
        rewards: [
          EventReward(kind: EventRewardKind.item, targetId: 'wildflower', amount: 1),
          EventReward(kind: EventRewardKind.item, targetId: 'honeycomb', amount: 1),
        ],
      ),
      RandomEventOption(
        text: 'Retreat',
        feedback: 'You back away slowly and try again later.',
        rewards: [],
      ),
    ],
  );

  static const RandomEvent rockslide = RandomEvent(
    id: 'rockslide',
    category: EventCategory.interruption,
    title: 'Rockslide',
    prompt: 'Pebbles patter down, then a low rumble of falling stone.',
    triggerSkills: [SkillType.mining],
    options: [
      RandomEventOption(
        text: 'Brace yourself',
        feedback: 'You shield your head and take the brunt of the falling shale.',
        healthCost: 5,
        requiredSkill: SkillType.combat,
        requiredLevel: 5,
        rewards: [],
      ),
      RandomEventOption(
        text: 'Dive out of the way',
        feedback: 'You tumble aside. You are safe, but your tools are buried.',
        rewards: [],
      ),
      RandomEventOption(
        text: 'Take cover',
        feedback: 'You quickly identify a stable overhang and step under it.',
        requiredSkill: SkillType.wayfinding,
        requiredLevel: 3,
        rewards: [],
      ),
    ],
  );

  static const RandomEvent suddenStorm = RandomEvent(
    id: 'sudden_storm',
    category: EventCategory.interruption,
    title: 'Sudden Storm',
    prompt: 'Black clouds boil up from nowhere, washing out the path.',
    triggerSkills: [SkillType.wayfinding],
    options: [
      RandomEventOption(
        text: 'Push through',
        feedback: 'You battle the heavy winds and rain.',
        energyCost: 10,
        rewards: [],
      ),
      RandomEventOption(
        text: 'Shelter under trees',
        feedback: 'You shelter under a tree until the storm passes.',
        rewards: [],
      ),
      RandomEventOption(
        text: 'Turn back',
        feedback: 'You cancel your travel plans.',
        rewards: [],
      ),
    ],
  );

  static const RandomEvent axeSlip = RandomEvent(
    id: 'axe_slip',
    category: EventCategory.interruption,
    title: 'Axe Slip',
    prompt: 'Your grip slipped on the sweat-slicked haft.',
    triggerSkills: [SkillType.woodcutting],
    options: [
      RandomEventOption(
        text: 'Bandage the wound',
        feedback: 'You press wild berries to the cut to soothe the pain.',
        requiredItemId: 'wild_berries',
        requiredItemCount: 1,
        rewards: [],
      ),
      RandomEventOption(
        text: 'Tough it out',
        feedback: 'You bind the hand with rag and keep swinging.',
        healthCost: 12,
        rewards: [EventReward(kind: EventRewardKind.item, targetId: 'oak_log', amount: 1)],
      ),
      RandomEventOption(
        text: 'Pause work',
        feedback: 'You take a break to recover.',
        rewards: [],
      ),
    ],
  );

  static const RandomEvent cookingFlare = RandomEvent(
    id: 'cooking_flare',
    category: EventCategory.interruption,
    title: 'Pot Flare-up',
    prompt: 'The pot leaps in a sudden flare, threatening to burn the food.',
    triggerSkills: [SkillType.cooking],
    options: [
      RandomEventOption(
        text: 'Quick-stir',
        feedback: 'You stir rapidly to disperse the heat.',
        requiredSkill: SkillType.cooking,
        requiredLevel: 5,
        rewards: [],
      ),
      RandomEventOption(
        text: 'Use water',
        feedback: 'You splash hot water in. The flare subsides, salvaging the dish.',
        requiredItemId: 'hot_water',
        requiredItemCount: 1,
        rewards: [],
      ),
      RandomEventOption(
        text: 'Discard it',
        feedback: 'You dump the contents before the pot is ruined.',
        rewards: [],
      ),
    ],
  );

  // ─── Discovery (5) ───
  static const RandomEvent hiddenCache = RandomEvent(
    id: 'hidden_cache',
    category: EventCategory.discovery,
    title: 'Hidden Cache',
    prompt: 'A loose stone reveals a cloth-wrapped bundle hidden in the roots.',
    options: [
      RandomEventOption(
        text: 'Open it',
        feedback: 'You open the bundle and find coins and copper ore.',
        rewards: [
          EventReward(kind: EventRewardKind.gold, amount: 5),
          EventReward(kind: EventRewardKind.item, targetId: 'copper_ore', amount: 1),
        ],
      ),
      RandomEventOption(
        text: 'Leave it',
        feedback: 'You leave it undisturbed.',
        rewards: [],
      ),
    ],
  );

  static const RandomEvent rareBloom = RandomEvent(
    id: 'rare_bloom',
    category: EventCategory.discovery,
    title: 'Rare Bloom',
    prompt: 'A dark violet bloom catches your eye in the undergrowth.',
    triggerSkills: [SkillType.herbalism],
    options: [
      RandomEventOption(
        text: 'Pluck it carefully',
        feedback: 'You harvest the bloom intact.',
        requiredSkill: SkillType.herbalism,
        requiredLevel: 3,
        rewards: [EventReward(kind: EventRewardKind.item, targetId: 'nightshade', amount: 2)],
      ),
      RandomEventOption(
        text: 'Sketch it',
        feedback: 'You document its leaf patterns.',
        requiredSkill: SkillType.lore,
        requiredLevel: 3,
        rewards: [EventReward(kind: EventRewardKind.skillXp, targetId: 'lore', amount: 25)],
      ),
      RandomEventOption(
        text: 'Leave it',
        feedback: 'You walk past it.',
        rewards: [],
      ),
    ],
  );

  static const RandomEvent surveyorsMarker = RandomEvent(
    id: 'surveyors_marker',
    category: EventCategory.discovery,
    title: "Old Surveyor's Marker",
    prompt: 'A stone carved with First Age script.',
    triggerSkills: [SkillType.wayfinding],
    options: [
      RandomEventOption(
        text: 'Read the markings',
        feedback: 'You translate the markings.',
        requiredSkill: SkillType.lore,
        requiredLevel: 1,
        rewards: [EventReward(kind: EventRewardKind.fragment, targetId: 'stone', amount: 1)],
      ),
      RandomEventOption(
        text: 'Ignore it',
        feedback: 'You walk past it.',
        rewards: [],
      ),
    ],
  );

  static const RandomEvent glintingPebble = RandomEvent(
    id: 'glinting_pebble',
    category: EventCategory.discovery,
    title: 'Glinting Pebble',
    prompt: 'A pebble in the shaft glints unnaturally.',
    triggerSkills: [SkillType.mining],
    options: [
      RandomEventOption(
        text: 'Pocket it',
        feedback: 'You slide the stone into your pouch.',
        rewards: [EventReward(kind: EventRewardKind.item, targetId: 'salt_crystal', amount: 1)],
      ),
      RandomEventOption(
        text: 'Inspect closely',
        feedback: 'You analyze its crystalline growth.',
        requiredSkill: SkillType.lore,
        requiredLevel: 3,
        rewards: [
          EventReward(kind: EventRewardKind.skillXp, targetId: 'lore', amount: 20),
          EventReward(kind: EventRewardKind.item, targetId: 'salt_crystal', amount: 1),
        ],
      ),
    ],
  );

  static const RandomEvent featherInPath = RandomEvent(
    id: 'feather_in_path',
    category: EventCategory.discovery,
    title: 'Feather in the Path',
    prompt: 'A long slate-gray feather rests on the trail.',
    options: [
      RandomEventOption(
        text: 'Follow the trail',
        feedback: 'You follow where the feather points.',
        requiredSkill: SkillType.wayfinding,
        requiredLevel: 5,
        rewards: [EventReward(kind: EventRewardKind.item, targetId: 'travelers_feather', amount: 1)],
      ),
      RandomEventOption(
        text: 'Pocket it',
        feedback: 'A merchant might like this.',
        rewards: [EventReward(kind: EventRewardKind.gold, amount: 5)],
      ),
      RandomEventOption(
        text: 'Ignore',
        feedback: 'You walk past it.',
        rewards: [],
      ),
    ],
  );

  // ─── Traveler (5) ───
  static const RandomEvent wanderingRefugee = RandomEvent(
    id: 'wandering_refugee',
    category: EventCategory.traveler,
    title: 'Wandering Refugee',
    prompt: 'A thin man with hollow eyes asks for food.',
    triggerZoneTiers: [1, 2],
    options: [
      RandomEventOption(
        text: 'Offer baked potato',
        feedback: 'He eats hungrily and hands you a few coins.',
        requiredItemId: 'baked_potato',
        requiredItemCount: 1,
        rewards: [EventReward(kind: EventRewardKind.gold, amount: 30)],
      ),
      RandomEventOption(
        text: 'Listen to his story',
        feedback: 'He speaks of the wild beasts in the woods.',
        rewards: [EventReward(kind: EventRewardKind.fragment, targetId: 'wilds', amount: 1)],
      ),
      RandomEventOption(
        text: 'Walk past',
        feedback: 'You walk past.',
        rewards: [],
      ),
    ],
  );

  static const RandomEvent injuredTrapper = RandomEvent(
    id: 'injured_trapper',
    category: EventCategory.traveler,
    title: 'Injured Trapper',
    prompt: 'A trapper limps from the trees, cradling his arm.',
    triggerZoneTiers: [1, 2],
    options: [
      RandomEventOption(
        text: 'Help him bandage',
        feedback: 'You press berries to soothe the pain.',
        requiredItemId: 'wild_berries',
        requiredItemCount: 1,
        rewards: [EventReward(kind: EventRewardKind.item, targetId: 'wolf_pelt', amount: 1)],
      ),
      RandomEventOption(
        text: 'Heal the arm',
        feedback: 'You set the bone and apply herbs.',
        requiredSkill: SkillType.herbalism,
        requiredLevel: 3,
        rewards: [
          EventReward(kind: EventRewardKind.item, targetId: 'wolf_pelt', amount: 1),
          EventReward(kind: EventRewardKind.item, targetId: 'boar_meat', amount: 1),
        ],
      ),
      RandomEventOption(
        text: 'Walk past',
        feedback: 'You leave him.',
        rewards: [],
      ),
    ],
  );

  static const RandomEvent travelingMerchant = RandomEvent(
    id: 'traveling_merchant',
    category: EventCategory.traveler,
    title: 'Traveling Merchant',
    prompt: 'A merchant with a strange cart greets you.',
    triggerZoneTiers: [1],
    options: [
      RandomEventOption(
        text: 'Buy clarity elixir',
        feedback: 'You buy the blue draught.',
        goldCost: 50,
        rewards: [EventReward(kind: EventRewardKind.item, targetId: 'philter_of_clarity', amount: 1)],
      ),
      RandomEventOption(
        text: 'Trade pelt',
        feedback: 'He buys your wolf pelt.',
        requiredItemId: 'wolf_pelt',
        requiredItemCount: 1,
        rewards: [EventReward(kind: EventRewardKind.gold, amount: 40)],
      ),
      RandomEventOption(
        text: 'Decline',
        feedback: 'You decline.',
        rewards: [],
      ),
    ],
  );

  static const RandomEvent mutePilgrim = RandomEvent(
    id: 'mute_pilgrim',
    category: EventCategory.traveler,
    title: 'Mute Pilgrim',
    prompt: 'A robed pilgrim gestures to your pack.',
    triggerZoneTiers: [2, 3],
    options: [
      RandomEventOption(
        text: 'Share cooked fish',
        feedback: 'He bows and hands you an ancient clay token.',
        requiredItemId: 'cooked_fish',
        requiredItemCount: 1,
        rewards: [EventReward(kind: EventRewardKind.fragment, targetId: 'stone', amount: 1)],
      ),
      RandomEventOption(
        text: 'Offer hot water',
        feedback: 'He drinks and smiles, leaving some wild berries.',
        requiredItemId: 'hot_water',
        requiredItemCount: 1,
        rewards: [EventReward(kind: EventRewardKind.item, targetId: 'wild_berries', amount: 1)],
      ),
      RandomEventOption(
        text: 'Walk past',
        feedback: 'You walk past.',
        rewards: [],
      ),
    ],
  );

  static const RandomEvent seaMessenger = RandomEvent(
    id: 'sea_messenger',
    category: EventCategory.traveler,
    title: 'Sea Messenger',
    prompt: 'A gull-borne message tube falls at your feet.',
    triggerZoneTiers: [1, 2],
    options: [
      RandomEventOption(
        text: 'Receive message',
        feedback: 'You decode the coastal markers.',
        requiredSkill: SkillType.wayfinding,
        requiredLevel: 5,
        rewards: [EventReward(kind: EventRewardKind.fragment, targetId: 'tide', amount: 1)],
      ),
      RandomEventOption(
        text: 'Refuse and salvage tube',
        feedback: 'You discard the scroll and sell the brass tube.',
        rewards: [EventReward(kind: EventRewardKind.gold, amount: 20)],
      ),
      RandomEventOption(
        text: 'Ignore',
        feedback: 'You walk past it.',
        rewards: [],
      ),
    ],
  );

  // ─── Omen (5) ───
  static const RandomEvent blackSapOak = RandomEvent(
    id: 'black_sap_oak',
    category: EventCategory.omen,
    title: 'Black Sap on the Oak',
    prompt: 'Your blade comes back wet with something darker than sap.',
    triggerSkills: [SkillType.woodcutting],
    triggerZoneTiers: [2, 3],
    options: [
      RandomEventOption(
        text: 'Cut anyway',
        feedback: 'You strike the dark wood, feeling a cold chill.',
        healthCost: 5,
        rewards: [EventReward(kind: EventRewardKind.fragment, targetId: 'wilds', amount: 1)],
      ),
      RandomEventOption(
        text: 'Mark and leave',
        feedback: 'You carve a warding mark and walk away.',
        rewards: [EventReward(kind: EventRewardKind.skillXp, targetId: 'lore', amount: 5)],
      ),
      RandomEventOption(
        text: 'Flee',
        feedback: 'You flee the grove.',
        rewards: [],
      ),
    ],
  );

  static const RandomEvent whisperingStone = RandomEvent(
    id: 'whispering_stone',
    category: EventCategory.omen,
    title: 'Whispering Stone',
    prompt: 'The vein hums in a rhythm you almost recognize.',
    triggerSkills: [SkillType.mining],
    triggerZoneTiers: [2, 3],
    options: [
      RandomEventOption(
        text: 'Listen closely',
        feedback: 'You focus on the hum.',
        requiredSkill: SkillType.lore,
        requiredLevel: 5,
        rewards: [EventReward(kind: EventRewardKind.fragment, targetId: 'stone', amount: 1)],
      ),
      RandomEventOption(
        text: 'Strike it silent',
        feedback: 'You shatter the hum, taking feedback shock.',
        healthCost: 3,
        rewards: [],
      ),
      RandomEventOption(
        text: 'Walk away',
        feedback: 'You step away.',
        rewards: [],
      ),
    ],
  );

  static const RandomEvent fogVoice = RandomEvent(
    id: 'fog_voice',
    category: EventCategory.omen,
    title: 'Voice in the Fog',
    prompt: 'A voice from the fog calls your name.',
    triggerZoneTiers: [1, 2],
    options: [
      RandomEventOption(
        text: 'Answer',
        feedback: 'You answer, feeling a drain on your mind.',
        energyCost: 10,
        rewards: [EventReward(kind: EventRewardKind.fragment, targetId: 'tide', amount: 1)],
      ),
      RandomEventOption(
        text: 'Cover ears',
        feedback: 'You walk in silence.',
        rewards: [],
      ),
      RandomEventOption(
        text: 'Sing back',
        feedback: 'Your counter-melody rings clear.',
        requiredSkill: SkillType.lore,
        requiredLevel: 8,
        rewards: [
          EventReward(kind: EventRewardKind.skillXp, targetId: 'lore', amount: 30),
          EventReward(kind: EventRewardKind.fragment, targetId: 'tide', amount: 1),
        ],
      ),
    ],
  );

  static const RandomEvent witheredGrove = RandomEvent(
    id: 'withered_grove',
    category: EventCategory.omen,
    title: 'Withered Grove',
    prompt: "The grove's heart-tree is rotted black.",
    triggerSkills: [SkillType.herbalism],
    triggerZoneTiers: [2, 3],
    options: [
      RandomEventOption(
        text: 'Document blight',
        feedback: 'You sketch the decay.',
        requiredSkill: SkillType.lore,
        requiredLevel: 3,
        rewards: [EventReward(kind: EventRewardKind.skillXp, targetId: 'lore', amount: 25)],
      ),
      RandomEventOption(
        text: 'Take cuttings',
        feedback: 'You prune the viable shoots.',
        rewards: [
          EventReward(kind: EventRewardKind.item, targetId: 'nightshade', amount: 2),
          EventReward(kind: EventRewardKind.fragment, targetId: 'wilds', amount: 1),
        ],
      ),
      RandomEventOption(
        text: 'Leave',
        feedback: 'You leave it.',
        rewards: [],
      ),
    ],
  );

  static const RandomEvent tappingInWalls = RandomEvent(
    id: 'tapping_in_walls',
    category: EventCategory.omen,
    title: 'Tapping in the Walls',
    prompt: 'Three taps, a pause, three taps.',
    triggerSkills: [SkillType.mining],
    triggerZoneTiers: [3],
    options: [
      RandomEventOption(
        text: 'Press your ear',
        feedback: 'You hear the ancient hum of the deep stone.',
        rewards: [EventReward(kind: EventRewardKind.fragment, targetId: 'stone', amount: 1)],
      ),
      RandomEventOption(
        text: 'Strike back',
        feedback: 'The wall crumbles, hitting your arm.',
        healthCost: 5,
        rewards: [EventReward(kind: EventRewardKind.fragment, targetId: 'stone', amount: 1)],
      ),
      RandomEventOption(
        text: 'Withdraw',
        feedback: 'You leave the shaft.',
        rewards: [EventReward(kind: EventRewardKind.skillXp, targetId: 'lore', amount: 5)],
      ),
    ],
  );

  static const List<RandomEvent> all = [
    // Interruption
    beeSwarm, rockslide, suddenStorm, axeSlip, cookingFlare,
    // Discovery
    hiddenCache, rareBloom, surveyorsMarker, glintingPebble, featherInPath,
    // Traveler
    wanderingRefugee, injuredTrapper, travelingMerchant, mutePilgrim, seaMessenger,
    // Omen
    blackSapOak, whisperingStone, fogVoice, witheredGrove, tappingInWalls,
  ];
}

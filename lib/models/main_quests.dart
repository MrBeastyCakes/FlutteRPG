import 'quest.dart';
import 'codex.dart';

class MainQuests {
  static Quest discoverSickness() => Quest(
        id: 'main_discover_sickness',
        type: QuestType.main,
        title: 'Discover the Sickness',
        description: 'The forest, the mine, the coast — something is changing in places long thought safe. Begin to gather the cartographer\'s torn pages. They say more than they seem.',
        objectives: [
          QuestObjective(
            kind: ObjectiveKind.codexRead,
            targetCount: 3,
          ),
        ],
        rewards: const [
          QuestReward(kind: RewardKind.gold, amount: 50),
          QuestReward(kind: RewardKind.skillXp, targetId: 'lore', amount: 50),
          QuestReward(kind: RewardKind.offerQuest, targetId: 'main_investigate_wilds', amount: 1),
          QuestReward(kind: RewardKind.offerQuest, targetId: 'main_investigate_stones', amount: 1),
        ],
        status: QuestStatus.active,
      );

  static Quest investigateWilds() => Quest(
        id: 'main_investigate_wilds',
        type: QuestType.main,
        title: 'Investigate the Wilds',
        description: 'The Whispering Woods are speaking, and not in a tongue you know. Solve their Reading to understand what stirs in the Hollow.',
        objectives: [
          QuestObjective(
            kind: ObjectiveKind.codexRead,
            targetTag: 'wilds', // matches tag name string
            targetCount: 10,
          ),
          QuestObjective(
            kind: ObjectiveKind.custom,
            targetId: 'puzzle_wilds_solved',
            targetCount: 1,
          ),
        ],
        rewards: const [
          QuestReward(kind: RewardKind.gold, amount: 100),
          QuestReward(kind: RewardKind.skillXp, targetId: 'wayfinding', amount: 75),
          QuestReward(kind: RewardKind.gold, amount: 25),
          QuestReward(kind: RewardKind.offerQuest, targetId: 'main_cleanse_hollow', amount: 1),
        ],
        status: QuestStatus.active,
      );

  static Quest investigateStones() => Quest(
        id: 'main_investigate_stones',
        type: QuestType.main,
        title: 'Investigate the Stones',
        description: 'The deep tappings in Darkstone speak a rhythm. The Glinting Vein is not a vein — read what the foreman saw.',
        objectives: [
          QuestObjective(
            kind: ObjectiveKind.codexRead,
            targetTag: 'stone',
            targetCount: 10,
          ),
          QuestObjective(
            kind: ObjectiveKind.custom,
            targetId: 'puzzle_stone_solved',
            targetCount: 1,
          ),
        ],
        rewards: const [
          QuestReward(kind: RewardKind.gold, amount: 100),
          QuestReward(kind: RewardKind.skillXp, targetId: 'mining', amount: 75),
          QuestReward(kind: RewardKind.gold, amount: 25),
          QuestReward(kind: RewardKind.offerQuest, targetId: 'main_cleanse_vein', amount: 1),
        ],
        status: QuestStatus.active,
      );

  static Quest investigateTide() => Quest(
        id: 'main_investigate_tide',
        type: QuestType.main,
        title: 'Investigate the Tide',
        description: 'The Drowned Lighthouse has gone dark. Find what the keeper left in the loft.',
        objectives: [
          QuestObjective(
            kind: ObjectiveKind.codexRead,
            targetTag: 'tide',
            targetCount: 10,
          ),
          QuestObjective(
            kind: ObjectiveKind.custom,
            targetId: 'puzzle_tide_solved',
            targetCount: 1,
          ),
        ],
        rewards: const [
          QuestReward(kind: RewardKind.gold, amount: 100),
          QuestReward(kind: RewardKind.skillXp, targetId: 'herbalism', amount: 75),
          QuestReward(kind: RewardKind.gold, amount: 25),
          QuestReward(kind: RewardKind.offerQuest, targetId: 'main_cleanse_tide', amount: 1),
        ],
        status: QuestStatus.active,
      );

  static Quest cleanseHollow() => Quest(
        id: 'main_cleanse_hollow',
        type: QuestType.main,
        title: 'Cleanse the Hollow',
        description: 'The Reading told you what the Wilds need. Travel to Bloomwither Hollow with an Ironbark log and three Wildflowers. Defeat what guards the Hollow. Burn the offering at the rotted shrine.',
        objectives: [
          QuestObjective(
            kind: ObjectiveKind.custom,
            targetId: 'echo_wilds_defeated',
            targetCount: 1,
            comingSoon: true,
          ),
          QuestObjective(
            kind: ObjectiveKind.cleanse,
            targetId: 'breach_wilds',
            targetCount: 1,
            comingSoon: true,
          ),
        ],
        rewards: const [],
        status: QuestStatus.active,
      );

  static Quest cleanseVein() => Quest(
        id: 'main_cleanse_vein',
        type: QuestType.main,
        title: 'Cleanse the Vein',
        description: 'The Reading told you what the Stones need. Travel to the Glowing Vein with twice-distilled wildflower-and-river-clay draught. Defeat what defends the wound. Pour the draught at the right moment.',
        objectives: [
          QuestObjective(
            kind: ObjectiveKind.custom,
            targetId: 'echo_stone_defeated',
            targetCount: 1,
            comingSoon: true,
          ),
          QuestObjective(
            kind: ObjectiveKind.cleanse,
            targetId: 'breach_stone',
            targetCount: 1,
            comingSoon: true,
          ),
        ],
        rewards: const [],
        status: QuestStatus.active,
      );

  static Quest cleanseTide() => Quest(
        id: 'main_cleanse_tide',
        type: QuestType.main,
        title: 'Cleanse the Tide',
        description: 'The Reading told you what the Tide needs. Travel to the Drowned Lighthouse with a pure Salt Crystal. Set it within the lamp\'s heart. What rises from the sea must be unmade.',
        objectives: [
          QuestObjective(
            kind: ObjectiveKind.custom,
            targetId: 'echo_tide_defeated',
            targetCount: 1,
            comingSoon: true,
          ),
          QuestObjective(
            kind: ObjectiveKind.cleanse,
            targetId: 'breach_tide',
            targetCount: 1,
            comingSoon: true,
          ),
        ],
        rewards: const [],
        status: QuestStatus.active,
      );

  static Quest sourceConvergence() => Quest(
        id: 'main_source_convergence',
        type: QuestType.main,
        title: 'The Source Convergence',
        description: 'Three breaches sealed. The Source itself is rising from beneath the world. Bring your three Cleansing Tokens to the Nexus of Echoes.',
        objectives: [
          QuestObjective(
            kind: ObjectiveKind.visit,
            targetId: 'nexus_of_echoes',
            targetCount: 1,
            comingSoon: true,
          ),
          QuestObjective(
            kind: ObjectiveKind.custom,
            targetId: 'source_defeated',
            targetCount: 1,
            comingSoon: true,
          ),
        ],
        rewards: const [],
        status: QuestStatus.active,
      );

  static Quest? findById(String id) {
    switch (id) {
      case 'main_discover_sickness': return discoverSickness();
      case 'main_investigate_wilds': return investigateWilds();
      case 'main_investigate_stones': return investigateStones();
      case 'main_investigate_tide': return investigateTide();
      case 'main_cleanse_hollow': return cleanseHollow();
      case 'main_cleanse_vein': return cleanseVein();
      case 'main_cleanse_tide': return cleanseTide();
      case 'main_source_convergence': return sourceConvergence();
      default: return null;
    }
  }
}

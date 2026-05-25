import 'skill.dart';

class MasterworkOption {
  final String text;
  final String? nextStepId; // If null, this is an ending option
  final bool isSuccess; // If it's a completing/ending option, is it successful?
  final String feedback; // Narrative text shown after clicking
  final int energyCost;
  final int healthCost; // Damage taken (positive) or recovered (negative)
  final int goldCost;
  final SkillType? requiredSkill;
  final int requiredLevel;
  final String? requiredItemId;
  final int requiredItemCount;
  final String? specPath;
  final String? subSpecPath;

  const MasterworkOption({
    required this.text,
    this.nextStepId,
    this.isSuccess = false,
    required this.feedback,
    this.energyCost = 0,
    this.healthCost = 0,
    this.goldCost = 0,
    this.requiredSkill,
    this.requiredLevel = 1,
    this.requiredItemId,
    this.requiredItemCount = 1,
    this.specPath,
    this.subSpecPath,
  });
}

class MasterworkStep {
  final String id;
  final String prompt;
  final List<MasterworkOption> options;

  const MasterworkStep({
    required this.id,
    required this.prompt,
    required this.options,
  });
}

class MasterworkTask {
  final String id;
  final SkillType skillType;
  final int levelGate;
  final String title;
  final String description;
  final Map<String, MasterworkStep> steps; // Maps stepId -> Step
  final String startStepId;

  const MasterworkTask({
    required this.id,
    required this.skillType,
    required this.levelGate,
    required this.title,
    required this.description,
    required this.steps,
    required this.startStepId,
  });

  MasterworkStep get startStep => steps[startStepId]!;
}

/// A registry of all Masterwork Tasks
class MasterworkTasks {
  static final MasterworkTask woodcuttingLvl10 = MasterworkTask(
    id: 'wc_lvl_10',
    skillType: SkillType.woodcutting,
    levelGate: 10,
    title: 'The Ironbark Trial',
    description: 'Fell the ancient Ironbark Tree in the deep forest. Its bark is hard as iron, and a normal axe will break against it.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
        id: 'start',
        prompt: 'You enter a hidden glade and stand before the giant Ironbark Tree. Its wood has a metallic sheen. How do you approach the felling?',
        options: [
          MasterworkOption(
            text: 'Examine the trunk to find a grain weakness.',
            nextStepId: 'weakness_found',
            requiredSkill: SkillType.lore,
            requiredLevel: 3,
            feedback: 'Your understanding of ancient woods reveals a spiral stress line near the base.',
          ),
          MasterworkOption(
            text: 'Deliver a massive, heavy chop to the center.',
            nextStepId: 'force_strike',
            energyCost: 20,
            feedback: 'You swing with all your power. The impact vibrates through your bones!',
          ),
          MasterworkOption(
            text: 'Retreat and prepare further.',
            nextStepId: null,
            isSuccess: false,
            feedback: 'You decide you are not ready and step away.',
          ),
        ],
      ),
      'weakness_found': const MasterworkStep(
        id: 'weakness_found',
        prompt: 'You spotted the weak stress line. Aligning your blade carefully is key.',
        options: [
          MasterworkOption(
            text: 'Chop precisely along the spiral line.',
            nextStepId: null,
            isSuccess: true,
            energyCost: 15,
            feedback: 'With a clean strike, the wood splits with a sharp ring. The Ironbark tree falls! You have completed the Woodcutting Trial!',
            specPath: 'woodcutting_arborist',
          ),
          MasterworkOption(
            text: 'Smash the weakness with brute force.',
            nextStepId: 'injury_scenario',
            energyCost: 25,
            feedback: 'You hit the correct spot, but swung too wildly. The ironwood splinters and explodes!',
          ),
        ],
      ),
      'force_strike': const MasterworkStep(
        id: 'force_strike',
        prompt: 'Your axe bounces off the trunk with a shower of sparks. The tree is barely scratched, and your hands are throbbing with pain.',
        options: [
          MasterworkOption(
            text: 'Submit 5 Iron Ores to reinforce your axe head.',
            nextStepId: 'reinforced_axe',
            requiredItemId: 'iron_ore',
            requiredItemCount: 5,
            feedback: 'You use the iron ores to fortify your tool. It now rings with heavy metal.',
          ),
          MasterworkOption(
            text: 'Force another heavy swing regardless.',
            nextStepId: null,
            isSuccess: false,
            energyCost: 30,
            healthCost: 25,
            feedback: 'You swing again. The axe handle snaps, flying back and hitting your shoulder. You collapse in exhaustion and pain, failing the trial.',
          ),
        ],
      ),
      'reinforced_axe': const MasterworkStep(
        id: 'reinforced_axe',
        prompt: 'With your reinforced axe head, the tree stands no chance against your hard strikes.',
        options: [
          MasterworkOption(
            text: 'Strike the tree with the reinforced axe.',
            nextStepId: null,
            isSuccess: true,
            energyCost: 20,
            feedback: 'The reinforced blade bites deep into the metallic trunk. The Ironbark tree groans and falls. Woodcutting cap unlocked!',
            specPath: 'woodcutting_logger',
          ),
        ],
      ),
      'injury_scenario': const MasterworkStep(
        id: 'injury_scenario',
        prompt: 'Shrapnel from the wood grazes your chest, and you are bleeding. You must steady yourself.',
        options: [
          MasterworkOption(
            text: 'Use Wild Bluebells to patch your wound.',
            nextStepId: 'healed_strike',
            requiredItemId: 'wild_berries', // Berry juice/berries
            requiredItemCount: 3,
            feedback: 'You rub the soothing berry juices on the scratch. The pain subsides.',
          ),
          MasterworkOption(
            text: 'Power through the bleeding and deliver a final blow.',
            nextStepId: null,
            isSuccess: true,
            energyCost: 35,
            healthCost: 30,
            feedback: 'Gritting your teeth, you deliver one final massive swing. The tree splits and falls, but you are severely wounded. You unlocked Woodcutting!',
            specPath: 'woodcutting_logger',
          ),
        ],
      ),
      'healed_strike': const MasterworkStep(
        id: 'healed_strike',
        prompt: 'Now stabilized, you can finish the job.',
        options: [
          MasterworkOption(
            text: 'Complete the felling.',
            nextStepId: null,
            isSuccess: true,
            energyCost: 10,
            feedback: 'You chop the remaining connection. The tree falls smoothly. Woodcutting cap unlocked!',
            specPath: 'woodcutting_arborist',
          ),
        ],
      ),
    },
  );

  static final MasterworkTask miningLvl10 = MasterworkTask(
    id: 'min_lvl_10',
    skillType: SkillType.mining,
    levelGate: 10,
    title: 'The Glinting Core',
    description: 'Mine the highly volatile Glinting Core deep within the Darkstone cavern. It requires structural knowledge to avoid triggering a collapse.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
        id: 'start',
        prompt: 'You stand before a glowing crystal core embedded in a crumbly rock ceiling. Tapping it recklessly could bury you.',
        options: [
          MasterworkOption(
            text: 'Examine the vault structure.',
            nextStepId: 'vault_structure',
            requiredSkill: SkillType.lore,
            requiredLevel: 4,
            feedback: 'You analyze the arch. The stress is concentrated on a single dark granite pillar.',
          ),
          MasterworkOption(
            text: 'Start chipping away at the outer shell.',
            nextStepId: 'collapse_imminent',
            energyCost: 20,
            feedback: 'You swing your pick. Tiny cracks immediately spread across the cavern roof!',
          ),
        ],
      ),
      'vault_structure': const MasterworkStep(
        id: 'vault_structure',
        prompt: 'You know exactly which granite pillar is holding up the cavern roof. If you avoid hitting it, you will be safe.',
        options: [
          MasterworkOption(
            text: 'Mine the core carefully, avoiding the support.',
            nextStepId: null,
            isSuccess: true,
            energyCost: 15,
            feedback: 'You delicately slide your pickaxe behind the crystal core, popping it free. The roof holds. Mining cap unlocked!',
            specPath: 'mining_refiner',
          ),
        ],
      ),
      'collapse_imminent': const MasterworkStep(
        id: 'collapse_imminent',
        prompt: 'Rocks begin to crumble around you. A collapse is imminent! You must act fast.',
        options: [
          MasterworkOption(
            text: 'Dive out of the cave.',
            nextStepId: null,
            isSuccess: false,
            energyCost: 10,
            healthCost: 20,
            feedback: 'You dive out. A rock strikes your back, and you escape empty-handed.',
          ),
          MasterworkOption(
            text: 'Dodge falling rubble while grabbing the core.',
            nextStepId: null,
            isSuccess: true,
            energyCost: 30,
            healthCost: 40,
            feedback: 'You grab the core just as the ceiling caves in. Rubble bruises you severely, but you pull the Glinting Core out of the rubble! Mining unlocked!',
            specPath: 'mining_prospector',
          ),
        ],
      ),
    },
  );

  static final MasterworkTask herbalismLvl10 = MasterworkTask(
    id: 'herb_lvl_10',
    skillType: SkillType.herbalism,
    levelGate: 10,
    title: 'The Philter of Clarity',
    description: 'Brew a volatile herbal potion. One wrong temperature or ingredient order will ruin the concoction.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
        id: 'start',
        prompt: 'Your mortar and pestle are ready. You have the fire lit. The recipe calls for Nightshade and Wild Bluebells.',
        options: [
          MasterworkOption(
            text: 'Mash 2 Nightshade Berries first to create a base.',
            nextStepId: 'mash_nightshade',
            requiredItemId: 'nightshade',
            requiredItemCount: 2,
            feedback: 'You grind the berries into a dark purple paste. Fumes rise from the bowl.',
          ),
          MasterworkOption(
            text: 'Boil Bluebells in river water first.',
            nextStepId: 'boil_bluebells',
            requiredItemId: 'wild_berries', // using wildberries as standard placeholder
            requiredItemCount: 2,
            feedback: 'You boil the bluebell petals. The water turns a clear blue, but it smells slightly acidic.',
          ),
        ],
      ),
      'mash_nightshade': const MasterworkStep(
        id: 'mash_nightshade',
        prompt: 'The nightshade paste is reacting with the air. How do you stabilize the heat?',
        options: [
          MasterworkOption(
            text: 'Slowly stir in Wild Blueberries.',
            nextStepId: 'stable_potion',
            requiredItemId: 'wild_berries',
            requiredItemCount: 3,
            feedback: 'The blue juice from the berries neutralizes the toxic vapors, stabilizing the mixture.',
          ),
          MasterworkOption(
            text: 'Apply maximum heat immediately.',
            nextStepId: null,
            isSuccess: false,
            energyCost: 15,
            healthCost: 30,
            feedback: 'The paste ignites! Toxic gas floods the room, searing your lungs. You ruin the potion.',
          ),
        ],
      ),
      'stable_potion': const MasterworkStep(
        id: 'stable_potion',
        prompt: 'The potion is bubbling a warm lavender color. It is ready for the final brewing step.',
        options: [
          MasterworkOption(
            text: 'Distill the mixture slowly and preserve the garden seeds.',
            nextStepId: null,
            isSuccess: true,
            energyCost: 15,
            feedback: 'You filter the liquid into a vial. It glows with pure clarity. You drink it and feel your mind expand. Herbalism cap unlocked!',
            specPath: 'herbalism_garden_keeper',
          ),
          MasterworkOption(
            text: 'Rapidly condense the extract for wild potency.',
            nextStepId: null,
            isSuccess: true,
            energyCost: 15,
            feedback: 'You flash-boil the extract, locking in volatile wild elements. You drink it and feel your senses sharpen. Herbalism cap unlocked!',
            specPath: 'herbalism_wild_walker',
          ),
        ],
      ),
      'boil_bluebells': const MasterworkStep(
        id: 'boil_bluebells',
        prompt: 'The acidic blue water is boiling rapidly. If you add nightshade now, it might explode.',
        options: [
          MasterworkOption(
            text: 'Add Nightshade anyway.',
            nextStepId: null,
            isSuccess: false,
            energyCost: 20,
            healthCost: 20,
            feedback: 'The potion explodes, spraying acid on your face. You fail the trial.',
          ),
          MasterworkOption(
            text: 'Let it cool down first.',
            nextStepId: 'mash_nightshade',
            feedback: 'You remove it from the fire. The acid levels settle down, and you can now proceed with mashing the berries.',
          ),
        ],
      ),
    },
  );

  static final MasterworkTask wayfindingLvl10 = MasterworkTask(
    id: 'wf_lvl_10',
    skillType: SkillType.wayfinding,
    levelGate: 10,
    title: 'The Lost Outpost',
    description: 'Find the lost surveyor\'s outpost in the deep Whispering Woods. Thick fog conceals the trails, and the wind threatens to sweep you off course.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
        id: 'start',
        prompt: 'You enter a dense, foggy section of the Whispering Woods. The path splits into three. How do you find your way?',
        options: [
          MasterworkOption(
            text: 'Read the moss on the trees to verify direction.',
            nextStepId: null,
            isSuccess: true,
            requiredSkill: SkillType.wayfinding,
            requiredLevel: 5,
            feedback: 'Your wayfinding experience reveals that moss grows thicker on the damp north-facing bark. You navigate successfully to the Outpost! Wayfinding cap unlocked!',
            specPath: 'wayfinding_tracker',
          ),
          MasterworkOption(
            text: 'Decipher old explorer carvings on a stone marker.',
            nextStepId: null,
            isSuccess: true,
            requiredSkill: SkillType.lore,
            requiredLevel: 3,
            feedback: 'You translate the faded glyphs. They point straight through a hidden thicket to the Outpost! Wayfinding cap unlocked!',
            specPath: 'wayfinding_cartographer',
          ),
          MasterworkOption(
            text: 'Push forward through the thick fog blindly.',
            nextStepId: null,
            isSuccess: false,
            energyCost: 20,
            healthCost: 15,
            feedback: 'You trip over hidden roots and get completely lost, eventually stumbling back to the entrance in exhaustion.',
          ),
        ],
      ),
    },
  );

  static final MasterworkTask loreLvl10 = MasterworkTask(
    id: 'lore_lvl_10',
    skillType: SkillType.lore,
    levelGate: 10,
    title: 'The Runed Obelisk',
    description: 'Translate the ancient runic carvings of the Obelisk in the deep forest. The inscriptions are highly complex and magical.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
        id: 'start',
        prompt: 'You stand before a glowing obsidian obelisk. The runes pulse with arcane energy. How do you approach the deciphering?',
        options: [
          MasterworkOption(
            text: 'Translate the grammar structure directly.',
            nextStepId: null,
            isSuccess: true,
            requiredSkill: SkillType.lore,
            requiredLevel: 5,
            feedback: 'You identify the dialect as First Age script and parse the runes safely. You feel ancient knowledge flood your mind! Lore cap unlocked!',
            specPath: 'lore_loremaster',
          ),
          MasterworkOption(
            text: 'Make a clay rubbing of the runes to analyze.',
            nextStepId: null,
            isSuccess: true,
            requiredItemId: 'river_clay',
            requiredItemCount: 3,
            feedback: 'You press the clay against the pulsing runes, safely preserving the symbols for study. You decipher the secrets! Lore cap unlocked!',
            specPath: 'lore_glyph_carver',
          ),
          MasterworkOption(
            text: 'Touch the obelisk to sense the runes.',
            nextStepId: null,
            isSuccess: false,
            energyCost: 15,
            healthCost: 20,
            feedback: 'An electric discharge repels you! The magical feedback sears your hands, forcing you to retreat.',
          ),
        ],
      ),
    },
  );

  static final MasterworkTask cookingLvl10 = MasterworkTask(
    id: 'cook_lvl_10',
    skillType: SkillType.cooking,
    levelGate: 10,
    title: 'The Feast of the Elder',
    description: 'Prepare a legendary trout platter for the Village Elder. The fish must be smoked perfectly without burning.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
        id: 'start',
        prompt: 'You have your ingredients and campfire ready. The Elder prefers delicate, herb-infused smoking. How do you start?',
        options: [
          MasterworkOption(
            text: 'Smoke the fish using aromatic willow logs.',
            nextStepId: null,
            isSuccess: true,
            requiredItemId: 'willow_log',
            requiredItemCount: 2,
            feedback: 'The sweet willow smoke flavors the trout perfectly. The Elder proclaims it the best dish in decades! Cooking cap unlocked!',
            specPath: 'cooking_innkeeper',
          ),
          MasterworkOption(
            text: 'Season the trout with forest wildflowers.',
            nextStepId: null,
            isSuccess: true,
            requiredItemId: 'wildflower',
            requiredItemCount: 4,
            feedback: 'The crushed petals create a subtle, floral glaze that preserves the fish perfectly. The Elder is delighted! Cooking cap unlocked!',
            specPath: 'cooking_field_chef',
          ),
          MasterworkOption(
            text: 'Cook on maximum heat to sear the skin.',
            nextStepId: null,
            isSuccess: false,
            energyCost: 15,
            healthCost: 10,
            feedback: 'The fat flares up! The fish burns to a crisp and grease splatters on your hands. You fail the preparation.',
          ),
        ],
      ),
    },
  );

  static final MasterworkTask craftingLvl10 = MasterworkTask(
    id: 'craft_lvl_10',
    skillType: SkillType.crafting,
    levelGate: 10,
    title: 'The Masterpiece Anvil',
    description: 'Forge a heavy, flawless steel anvil. It requires precise temperature control and powerful hammer strikes.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
        id: 'start',
        prompt: 'Your bellows are pumping, and the iron ore is melting in the crucible. How do you shape the anvil block?',
        options: [
          MasterworkOption(
            text: 'Deliver rhythmic, heavy hammer strikes.',
            nextStepId: null,
            isSuccess: true,
            requiredSkill: SkillType.crafting,
            requiredLevel: 5,
            feedback: 'Your rhythmic blows draw out air bubbles, creating a dense, flawless anvil head. It rings with quality! Crafting cap unlocked!',
            specPath: 'crafting_smith',
          ),
          MasterworkOption(
            text: 'Temper the cooling iron with river clay.',
            nextStepId: null,
            isSuccess: true,
            requiredItemId: 'river_clay',
            requiredItemCount: 5,
            feedback: 'The clay coating slows the cooling rate, preventing brittle fractures in the steel anvil. An exceptional piece! Crafting cap unlocked!',
            specPath: 'crafting_tinker',
          ),
          MasterworkOption(
            text: 'Quench the hot metal in cold river water immediately.',
            nextStepId: null,
            isSuccess: false,
            energyCost: 20,
            healthCost: 10,
            feedback: 'The rapid cooling fractures the iron! Steam sears your face, and the anvil splits in two. You fail the forge.',
          ),
        ],
      ),
    },
  );

  static final MasterworkTask woodcuttingLvl20Logger = MasterworkTask(
    id: 'task_lvl20_woodcutting_logger',
    skillType: SkillType.woodcutting,
    levelGate: 20,
    title: 'The Old Stand',
    description: 'An old stand of oaks — enough wood for a winter. You have to choose how you harvest it.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
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
      'clearcutter_end': const MasterworkStep(
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
      'speedchopper_end': const MasterworkStep(
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

  static final MasterworkTask woodcuttingLvl20Arborist = MasterworkTask(
    id: 'task_lvl20_woodcutting_arborist',
    skillType: SkillType.woodcutting,
    levelGate: 20,
    title: 'The Sapling Path',
    description: 'A storm has torn through a sapling grove. Some young trees are saved; others are bent past mending. You see what could be done.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
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
      'sapling_mender_end': const MasterworkStep(
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
      'heartwood_reader_end': const MasterworkStep(
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

  static final MasterworkTask miningLvl20Prospector = MasterworkTask(
    id: 'task_lvl20_mining_prospector',
    skillType: SkillType.mining,
    levelGate: 20,
    title: 'The Cavern\'s Promise',
    description: 'A cavern your foreman would not enter. The veins are deep and the roof is uncertain.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
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
      'vein_hunter_end': const MasterworkStep(
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
      'tunnel_caller_end': const MasterworkStep(
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

  static final MasterworkTask miningLvl20Refiner = MasterworkTask(
    id: 'task_lvl20_mining_refiner',
    skillType: SkillType.mining,
    levelGate: 20,
    title: 'The Smelter\'s Heart',
    description: 'An old smelter stands cold in the deeper shafts. You can rebuild it your way.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
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
      'smelt_master_end': const MasterworkStep(
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
      'slag_cutter_end': const MasterworkStep(
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

  static final MasterworkTask herbalismLvl20GardenKeeper = MasterworkTask(
    id: 'task_lvl20_herbalism_garden_keeper',
    skillType: SkillType.herbalism,
    levelGate: 20,
    title: 'The Second Garden',
    description: 'Your wildflower garden has thrived. You have room for a second bed. The question is what to plant in it.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
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
      'botanist_end': const MasterworkStep(
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
      'hedge_witch_end': const MasterworkStep(
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

  static final MasterworkTask herbalismLvl20WildWalker = MasterworkTask(
    id: 'task_lvl20_herbalism_wild_walker',
    skillType: SkillType.herbalism,
    levelGate: 20,
    title: 'The Deep Grove',
    description: 'You stand in the heart of a grove that no warden has named. Both poison and bloom grow thick here.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
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
      'poison_picker_end': const MasterworkStep(
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
      'bloomseer_end': const MasterworkStep(
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

  static final MasterworkTask wayfindingLvl20Cartographer = MasterworkTask(
    id: 'task_lvl20_wayfinding_cartographer',
    skillType: SkillType.wayfinding,
    levelGate: 20,
    title: 'Charts of the Sea',
    description: 'The Wharfmaster spreads old sea-charts before you. Two studies are possible. You can master one.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
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
      'sea_reader_end': const MasterworkStep(
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
      'path_mapper_end': const MasterworkStep(
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

  static final MasterworkTask wayfindingLvl20Tracker = MasterworkTask(
    id: 'task_lvl20_wayfinding_tracker',
    skillType: SkillType.wayfinding,
    levelGate: 20,
    title: 'The Last Spoor',
    description: 'A rare beast\'s trail, fresh in mud. The choice now is how you meet it.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
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
      'beast_lurer_end': const MasterworkStep(
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
      'spoor_reader_end': const MasterworkStep(
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

  static final MasterworkTask loreLvl20Loremaster = MasterworkTask(
    id: 'task_lvl20_lore_loremaster',
    skillType: SkillType.lore,
    levelGate: 20,
    title: 'The Polyphonic Reading',
    description: 'The Codex lies open. Two roads to deeper reading present themselves.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
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
      'polymath_end': const MasterworkStep(
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
      'translator_end': const MasterworkStep(
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

  static final MasterworkTask loreLvl20GlyphCarver = MasterworkTask(
    id: 'task_lvl20_lore_glyph_carver',
    skillType: SkillType.lore,
    levelGate: 20,
    title: 'The Twin Glyphs',
    description: 'Two clay tablets. Two glyphs. One method per side.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
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
      'rune_weaver_end': const MasterworkStep(
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
      'engraver_end': const MasterworkStep(
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

  static final MasterworkTask cookingLvl20Innkeeper = MasterworkTask(
    id: 'task_lvl20_cooking_innkeeper',
    skillType: SkillType.cooking,
    levelGate: 20,
    title: 'The Long Feast',
    description: 'The Cartographer\'s Tent is throwing a feast for the Wharfmaster\'s arrival. You are running the kitchen.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
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
      'brewmaster_end': const MasterworkStep(
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
      'pastrycook_end': const MasterworkStep(
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

  static final MasterworkTask cookingLvl20FieldChef = MasterworkTask(
    id: 'task_lvl20_cooking_field_chef',
    skillType: SkillType.cooking,
    levelGate: 20,
    title: 'Fire on the Wayside',
    description: 'A wayside fire, no station, no walls. A hungry party is coming home with the dusk.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
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
      'trailcook_end': const MasterworkStep(
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
      'stewmaster_end': const MasterworkStep(
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

  static final MasterworkTask craftingLvl20Smith = MasterworkTask(
    id: 'task_lvl20_crafting_smith',
    skillType: SkillType.crafting,
    levelGate: 20,
    title: 'The Greater Ironbark',
    description: 'A second Ironbark stands in the deeper grove, taller and harder than the first. Your Smith path has shaped you; the path you cut next will refine it further.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
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
      'weaponsmith_end': const MasterworkStep(
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
      'armorsmith_end': const MasterworkStep(
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

  static final MasterworkTask craftingLvl20Tinker = MasterworkTask(
    id: 'task_lvl20_crafting_tinker',
    skillType: SkillType.crafting,
    levelGate: 20,
    title: 'The Salt-Eaten Loom',
    description: 'A loom in the Drowned Lighthouse, eaten through by salt. Broken in interesting ways. Your Tinker eye reads it like a book.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
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
      'toolmaker_end': const MasterworkStep(
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
      'backpacker_end': const MasterworkStep(
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

  static final MasterworkTask combatLvl10 = MasterworkTask(
    id: 'combat_lvl_10',
    skillType: SkillType.combat,
    levelGate: 10,
    title: "The Gladiator's Arena",
    description: 'Enter the Town Arena to face the champion Gladiator in a test of pure combat skill and endurance.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
        id: 'start',
        prompt: 'You enter the sandy arena ring. The Gladiator champion draws his wooden training sword. How do you open the duel?',
        options: [
          MasterworkOption(
            text: 'Analyze his stance for an opening.',
            nextStepId: 'stance_analysed',
            requiredSkill: SkillType.lore,
            requiredLevel: 3,
            feedback: 'Your understanding of ancient dueling stances reveals a spiral stress line in his footing.',
          ),
          MasterworkOption(
            text: 'Charge in with a heavy offensive strike.',
            nextStepId: 'charge_strike',
            energyCost: 20,
            feedback: 'You swing with all your power. The impact vibrates through your bones!',
          ),
          MasterworkOption(
            text: 'Yield and retreat.',
            nextStepId: null,
            isSuccess: false,
            feedback: 'You decide you are not ready and step away.',
          ),
        ],
      ),
      'stance_analysed': const MasterworkStep(
        id: 'stance_analysed',
        prompt: 'You spotted the weakness in his stance. Aligning your blow is key.',
        options: [
          MasterworkOption(
            text: 'Deliver a swift feint and strike his leg.',
            nextStepId: null,
            isSuccess: true,
            energyCost: 15,
            feedback: 'You feint right and strike his left ankle! The Gladiator nods in respect and yields. Combat Lvl 10 cap unlocked!',
            specPath: 'combat_guardian',
          ),
          MasterworkOption(
            text: 'Try to disarm him with brute force.',
            nextStepId: null,
            isSuccess: false,
            energyCost: 25,
            feedback: 'You try to grab his sword, but he counters and sweeps your legs, forcing you to yield.',
          ),
        ],
      ),
      'charge_strike': const MasterworkStep(
        id: 'charge_strike',
        prompt: 'Your aggressive charge catches him off guard, but he blocks with his shield and prepares a heavy counter.',
        options: [
          MasterworkOption(
            text: 'Roll under his shield and strike from behind.',
            nextStepId: null,
            isSuccess: true,
            energyCost: 15,
            feedback: 'You roll under the shield and hit his back. He laughs and concedes the duel! Combat Lvl 10 cap unlocked!',
            specPath: 'combat_berserker',
          ),
          MasterworkOption(
            text: 'Brace for impact and block his swing.',
            nextStepId: null,
            isSuccess: false,
            energyCost: 15,
            healthCost: 15,
            feedback: 'You brace yourself, but the blow is too heavy. You are knocked down and yield.',
          ),
        ],
      ),
    },
  );

  static final MasterworkTask combatLvl20Berserker = MasterworkTask(
    id: 'task_lvl20_combat_berserker',
    skillType: SkillType.combat,
    levelGate: 20,
    title: 'Blood and Fury',
    description: 'You have followed the Berserker path. Now choose the shape of your fury.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
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
      'skirmisher_end': const MasterworkStep(
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
      'reaper_end': const MasterworkStep(
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

  static final MasterworkTask combatLvl20Guardian = MasterworkTask(
    id: 'task_lvl20_combat_guardian',
    skillType: SkillType.combat,
    levelGate: 20,
    title: 'Walls and Mirrors',
    description: 'You have followed the Guardian path. A cavern troll bears down on you; you have not lifted your sword.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
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
      'bastion_end': const MasterworkStep(
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
      'sentinel_end': const MasterworkStep(
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

  static final List<MasterworkTask> all = [
    woodcuttingLvl10,
    miningLvl10,
    herbalismLvl10,
    wayfindingLvl10,
    loreLvl10,
    cookingLvl10,
    craftingLvl10,
    combatLvl10,
    woodcuttingLvl20Logger,
    woodcuttingLvl20Arborist,
    miningLvl20Prospector,
    miningLvl20Refiner,
    herbalismLvl20GardenKeeper,
    herbalismLvl20WildWalker,
    wayfindingLvl20Cartographer,
    wayfindingLvl20Tracker,
    loreLvl20Loremaster,
    loreLvl20GlyphCarver,
    cookingLvl20Innkeeper,
    cookingLvl20FieldChef,
    craftingLvl20Smith,
    craftingLvl20Tinker,
    combatLvl20Berserker,
    combatLvl20Guardian,
  ];

  static MasterworkTask? findForSkill(SkillType skill, int level, [String? spec]) {
    try {
      if (level == 20 && spec != null) {
        return all.firstWhere((task) => task.id == 'task_lvl20_$spec');
      }
      return all.firstWhere((task) => task.skillType == skill && task.levelGate == level);
    } catch (_) {
      return null;
    }
  }

  static MasterworkTask? findById(String id) {
    try {
      return all.firstWhere((task) => task.id == id);
    } catch (_) {
      return null;
    }
  }
}

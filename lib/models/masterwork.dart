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
            text: 'Distill the mixture.',
            nextStepId: null,
            isSuccess: true,
            energyCost: 15,
            feedback: 'You filter the liquid into a vial. It glows with pure clarity. You drink it and feel your mind expand. Herbalism cap unlocked!',
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
          ),
          MasterworkOption(
            text: 'Decipher old explorer carvings on a stone marker.',
            nextStepId: null,
            isSuccess: true,
            requiredSkill: SkillType.lore,
            requiredLevel: 3,
            feedback: 'You translate the faded glyphs. They point straight through a hidden thicket to the Outpost! Wayfinding cap unlocked!',
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
          ),
          MasterworkOption(
            text: 'Make a clay rubbing of the runes to analyze.',
            nextStepId: null,
            isSuccess: true,
            requiredItemId: 'river_clay',
            requiredItemCount: 3,
            feedback: 'You press the clay against the pulsing runes, safely preserving the symbols for study. You decipher the secrets! Lore cap unlocked!',
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
          ),
          MasterworkOption(
            text: 'Season the trout with forest wildflowers.',
            nextStepId: null,
            isSuccess: true,
            requiredItemId: 'wildflower',
            requiredItemCount: 4,
            feedback: 'The crushed petals create a subtle, floral glaze that preserves the fish perfectly. The Elder is delighted! Cooking cap unlocked!',
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
          ),
          MasterworkOption(
            text: 'Temper the cooling iron with river clay.',
            nextStepId: null,
            isSuccess: true,
            requiredItemId: 'river_clay',
            requiredItemCount: 5,
            feedback: 'The clay coating slows the cooling rate, preventing brittle fractures in the steel anvil. An exceptional piece! Crafting cap unlocked!',
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

  static final MasterworkTask woodcuttingLvl20 = MasterworkTask(
    id: 'wc_lvl_20',
    skillType: SkillType.woodcutting,
    levelGate: 20,
    title: 'The Whisperer\'s Heart',
    description: 'Fell the magical Sentinel Oak in the Whispering Woods. It is shielded by deep briars and responds to iron axes.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
        id: 'start',
        prompt: 'You stand before the towering Sentinel Oak. Magical briars shield the base of the trunk. How do you proceed?',
        options: [
          MasterworkOption(
            text: 'Submit an Iron Axe from inventory to cut the magical shield.',
            nextStepId: null,
            isSuccess: true,
            requiredItemId: 'iron_axe',
            requiredItemCount: 1,
            feedback: 'You strike the briars with the heavy iron axe. It shears the magical vines instantly, letting you fell the Sentinel Oak! Woodcutting Lvl 20 cap unlocked!',
          ),
          MasterworkOption(
            text: 'Locate a structural gap in the briar vines.',
            nextStepId: null,
            isSuccess: true,
            requiredSkill: SkillType.lore,
            requiredLevel: 8,
            feedback: 'Your lore studies reveal the briars follow a hexagram pattern. You step through a gap and clean-cut the trunk! Woodcutting Lvl 20 cap unlocked!',
          ),
          MasterworkOption(
            text: 'Chop directly through the thorn shield.',
            nextStepId: null,
            isSuccess: false,
            energyCost: 30,
            healthCost: 25,
            feedback: 'The magical thorns slice your arms, injecting a sleep toxin. You collapse in pain and fail the trial.',
          ),
        ],
      ),
    },
  );

  static final MasterworkTask miningLvl20 = MasterworkTask(
    id: 'min_lvl_20',
    skillType: SkillType.mining,
    levelGate: 20,
    title: 'The Deep Core Vault',
    description: 'Mine the sealed gate of the Deep Caverns\' treasury. The locking plates are composed of solid obsidian.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
        id: 'start',
        prompt: 'You find the treasury vault door. The lock plates are solid obsidian. A weak tool will shatter. How do you proceed?',
        options: [
          MasterworkOption(
            text: 'Submit an Iron Pickaxe to shatter the lock plate.',
            nextStepId: null,
            isSuccess: true,
            requiredItemId: 'iron_pickaxe',
            requiredItemCount: 1,
            feedback: 'With a mighty swing, the iron pickaxe shatters the obsidian lock plate. The door swings open! Mining Lvl 20 cap unlocked!',
          ),
          MasterworkOption(
            text: 'Chisel precise stress fractures using Mining expertise.',
            nextStepId: null,
            isSuccess: true,
            requiredSkill: SkillType.mining,
            requiredLevel: 15,
            feedback: 'You tap along the crystalline boundaries of the obsidian. With one gentle tap, the plate splits cleanly! Mining Lvl 20 cap unlocked!',
          ),
          MasterworkOption(
            text: 'Smash the vault gate with bare fists.',
            nextStepId: null,
            isSuccess: false,
            energyCost: 30,
            healthCost: 30,
            feedback: 'You break your hands against the solid obsidian. The door remains completely unharmed, and you are bleeding.',
          ),
        ],
      ),
    },
  );

  static final MasterworkTask herbalismLvl20 = MasterworkTask(
    id: 'herb_lvl_20',
    skillType: SkillType.herbalism,
    levelGate: 20,
    title: 'The Bloom of Midnight',
    description: 'Harvest the highly caustic Midnight Bloom under the full moon. It requires skin protection to gather safely.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
        id: 'start',
        prompt: 'You locate the Midnight Bloom glowing in the dark. Caustic nectar drips from its leaves. How do you harvest it?',
        options: [
          MasterworkOption(
            text: 'Submit Foraging Gloves to shield your hands.',
            nextStepId: null,
            isSuccess: true,
            requiredItemId: 'foraging_gloves',
            requiredItemCount: 1,
            feedback: 'The leather gloves absorb the caustic nectar, letting you pluck the bloom safely. Herbalism Lvl 20 cap unlocked!',
          ),
          MasterworkOption(
            text: 'Neutralize the acid using fine River Clay coating.',
            nextStepId: null,
            isSuccess: true,
            requiredItemId: 'river_clay',
            requiredItemCount: 3,
            feedback: 'You coat the bloom in river clay paste, neutralizing the caustic properties before plucking. Herbalism Lvl 20 cap unlocked!',
          ),
          MasterworkOption(
            text: 'Pluck the flower with bare hands.',
            nextStepId: null,
            isSuccess: false,
            energyCost: 20,
            healthCost: 25,
            feedback: 'The caustic sap burns your skin severely! You drop the flower, ruin the petals, and retreat in pain.',
          ),
        ],
      ),
    },
  );

  static final MasterworkTask wayfindingLvl20 = MasterworkTask(
    id: 'wf_lvl_20',
    skillType: SkillType.wayfinding,
    levelGate: 20,
    title: 'The Abyssal Rift',
    description: 'Cross the broken stone bridge at the Abyssal Rift. The wind is fierce, and the drop is bottomless.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
        id: 'start',
        prompt: 'You stand before the bottomless Abyssal Rift. The stone bridge is collapsed, leaving only a narrow ledge. How do you cross?',
        options: [
          MasterworkOption(
            text: 'Carefully anchor yourself and trace the ledge.',
            nextStepId: null,
            isSuccess: true,
            requiredSkill: SkillType.wayfinding,
            requiredLevel: 15,
            feedback: 'Your excellent balance and step placement allow you to creep across the windy ledge safely! Wayfinding Lvl 20 cap unlocked!',
          ),
          MasterworkOption(
            text: 'Submit a Willow Log to construct a temporary brace.',
            nextStepId: null,
            isSuccess: true,
            requiredItemId: 'willow_log',
            requiredItemCount: 1,
            feedback: 'You lay the sturdy willow log across the gap, forming a stable footbridge. You walk across safely! Wayfinding Lvl 20 cap unlocked!',
          ),
          MasterworkOption(
            text: 'Jump the gap with a running start.',
            nextStepId: null,
            isSuccess: false,
            energyCost: 25,
            healthCost: 35,
            feedback: 'The strong winds blow you off course! You fall, barely catching the far edge, bruising your ribs and struggling to climb up.',
          ),
        ],
      ),
    },
  );

  static final MasterworkTask loreLvl20 = MasterworkTask(
    id: 'lore_lvl_20',
    skillType: SkillType.lore,
    levelGate: 20,
    title: 'The Codex of Ages',
    description: 'Unlock the Codex of Ages, a heavy tome sealed with a complex multi-stage runic puzzle.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
        id: 'start',
        prompt: 'You place the Codex of Ages on your desk. Its metallic cover is locked by glowing dials. How do you attempt to break the seal?',
        options: [
          MasterworkOption(
            text: 'Decipher the astronomical sequence using Lore.',
            nextStepId: null,
            isSuccess: true,
            requiredSkill: SkillType.lore,
            requiredLevel: 15,
            feedback: 'You align the stars on the lock dials according to ancient constellations, releasing the latch. The Codex opens! Lore Lvl 20 cap unlocked!',
          ),
          MasterworkOption(
            text: 'Submit a Glyph of Swiftness to trigger dial rotations.',
            nextStepId: null,
            isSuccess: true,
            requiredItemId: 'glyph_swiftness',
            requiredItemCount: 1,
            feedback: 'You touch the Glyph of Swiftness to the lock. The dials spin at extreme speed and snap into the correct alignment! Lore Lvl 20 cap unlocked!',
          ),
          MasterworkOption(
            text: 'Attempt to pry the lock open with a tool.',
            nextStepId: null,
            isSuccess: false,
            energyCost: 20,
            healthCost: 15,
            feedback: 'The security runes detonate! A blast of kinetic energy hurls you across the room, leaving the book locked.',
          ),
        ],
      ),
    },
  );

  static final MasterworkTask cookingLvl20 = MasterworkTask(
    id: 'cook_lvl_20',
    skillType: SkillType.cooking,
    levelGate: 20,
    title: 'The Ambrosia Elixir',
    description: 'Brew the legendary Ambrosia Elixir. It requires balancing volatile energy tea and clarity potions.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
        id: 'start',
        prompt: 'Your cauldron is bubbling. You must blend highly refined ingredients at an exact boiling point. How do you stabilize the brew?',
        options: [
          MasterworkOption(
            text: 'Use culinary instincts to regulate heat and timing.',
            nextStepId: null,
            isSuccess: true,
            requiredSkill: SkillType.cooking,
            requiredLevel: 15,
            feedback: 'You skim the top at the exact millisecond the color shifts to golden. The elixir is pristine! Cooking Lvl 20 cap unlocked!',
          ),
          MasterworkOption(
            text: 'Submit a Philter of Clarity to refine the mixture.',
            nextStepId: null,
            isSuccess: true,
            requiredItemId: 'philter_of_clarity',
            requiredItemCount: 1,
            feedback: 'Adding the Philter immediately clarifies the solution, binding the active components perfectly. You succeed! Cooking Lvl 20 cap unlocked!',
          ),
          MasterworkOption(
            text: 'Boil it at maximum temperature to distill faster.',
            nextStepId: null,
            isSuccess: false,
            energyCost: 25,
            healthCost: 20,
            feedback: 'The mixture turns to black sludge, releasing noxious vapors that choke you. The brew is ruined.',
          ),
        ],
      ),
    },
  );

  static final MasterworkTask craftingLvl20 = MasterworkTask(
    id: 'craft_lvl_20',
    skillType: SkillType.crafting,
    levelGate: 20,
    title: 'The Forge of Stars',
    description: 'Weave bronze and iron components into the flawless Star Forge Bracers.',
    startStepId: 'start',
    steps: {
      'start': const MasterworkStep(
        id: 'start',
        prompt: 'You stand before the hot forge with molten bronze and iron. The metal must be woven seamlessly. How do you shape the bracers?',
        options: [
          MasterworkOption(
            text: 'Weave the metallic layers using Crafting expertise.',
            nextStepId: null,
            isSuccess: true,
            requiredSkill: SkillType.crafting,
            requiredLevel: 15,
            feedback: 'Your hammer merges the metals, forming a beautiful interlaced pattern of incredible strength. A masterpiece! Crafting Lvl 20 cap unlocked!',
          ),
          MasterworkOption(
            text: 'Submit a Glyph of Fortitude to fuse the plates.',
            nextStepId: null,
            isSuccess: true,
            requiredItemId: 'glyph_fortitude',
            requiredItemCount: 1,
            feedback: 'You place the glyph on the mold. The runic energy fuses the metals seamlessly, creating glowing star-engraved bracers! Crafting Lvl 20 cap unlocked!',
          ),
          MasterworkOption(
            text: 'Hammer the metals together aggressively.',
            nextStepId: null,
            isSuccess: false,
            energyCost: 25,
            healthCost: 15,
            feedback: 'The metals reject each other, spraying sparks and molten drops on your chest. The materials are ruined.',
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
    woodcuttingLvl20,
    miningLvl20,
    herbalismLvl20,
    wayfindingLvl20,
    loreLvl20,
    cookingLvl20,
    craftingLvl20,
  ];

  static MasterworkTask? findForSkill(SkillType skill, int level) {
    try {
      return all.firstWhere((task) => task.skillType == skill && task.levelGate == level);
    } catch (_) {
      return null;
    }
  }
}

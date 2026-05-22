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

  static final List<MasterworkTask> all = [
    woodcuttingLvl10,
    miningLvl10,
    herbalismLvl10,
  ];

  static MasterworkTask? findForSkill(SkillType skill, int level) {
    try {
      return all.firstWhere((task) => task.skillType == skill && task.levelGate == level);
    } catch (_) {
      return null;
    }
  }
}

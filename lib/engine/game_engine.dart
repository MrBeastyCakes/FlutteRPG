import 'dart:async';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

import '../models/player_stats.dart';
import '../models/skill.dart';
import '../models/item.dart';
import '../models/inventory.dart';
import '../models/crafted_item.dart';
import '../models/zone.dart';
import '../models/masterwork.dart';
import '../models/recipe.dart';
import '../models/structure.dart';
import '../models/beast.dart';
import '../models/shop.dart';
import '../models/quest.dart';
import '../models/codex.dart';
import '../models/milestone.dart';
import 'activity_log.dart';

class ActiveActionState {
  final ZoneAction? action;
  final Recipe? recipe;
  final Structure? structure;
  final Station? station;
  final bool isUpgrade;
  final bool isRestoration;
  final String? targetZoneId;
  final double progress; // 0.0 to 1.0
  final double durationSeconds;

  const ActiveActionState({
    this.action,
    this.recipe,
    this.structure,
    this.station,
    this.isUpgrade = false,
    this.isRestoration = false,
    this.targetZoneId,
    required this.progress,
    required this.durationSeconds,
  });

  ActiveActionState copyWith({
    ZoneAction? action,
    Recipe? recipe,
    Structure? structure,
    Station? station,
    bool? isUpgrade,
    bool? isRestoration,
    String? targetZoneId,
    double? progress,
    double? durationSeconds,
  }) {
    return ActiveActionState(
      action: action ?? this.action,
      recipe: recipe ?? this.recipe,
      structure: structure ?? this.structure,
      station: station ?? this.station,
      isUpgrade: isUpgrade ?? this.isUpgrade,
      isRestoration: isRestoration ?? this.isRestoration,
      targetZoneId: targetZoneId ?? this.targetZoneId,
      progress: progress ?? this.progress,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }
}

class CombatState {
  final Beast beast;
  final int beastCurrentHealth;
  final int playerStartHealth;
  final List<String> combatLog;

  const CombatState({
    required this.beast,
    required this.beastCurrentHealth,
    required this.playerStartHealth,
    required this.combatLog,
  });

  CombatState copyWith({
    Beast? beast,
    int? beastCurrentHealth,
    int? playerStartHealth,
    List<String>? combatLog,
  }) {
    return CombatState(
      beast: beast ?? this.beast,
      beastCurrentHealth: beastCurrentHealth ?? this.beastCurrentHealth,
      playerStartHealth: playerStartHealth ?? this.playerStartHealth,
      combatLog: combatLog ?? this.combatLog,
    );
  }
}

class QueuedCraft {
  final String recipeId;
  int count; // remaining iterations
  final Map<int, String> slotChoices; // slotIndex -> chosen item id
  final String? modifierItemId;

  QueuedCraft({
    required this.recipeId,
    required this.count,
    required this.slotChoices,
    this.modifierItemId,
  });
}

class StationInstance {
  final String zoneId;
  final String stationId;
  int tier; // 1..maxTier
  bool isRuined; // Town Square stations start true
  ActiveActionState? currentCraft; // head of queue, in progress
  List<QueuedCraft> queue; // pending entries behind head
  ActiveActionState? tierUpgrade; // if upgrading right now
  ActiveActionState? restoration; // if being restored right now

  StationInstance({
    required this.zoneId,
    required this.stationId,
    required this.tier,
    required this.isRuined,
    this.currentCraft,
    required this.queue,
    this.tierUpgrade,
    this.restoration,
  });
}

class MasterworkRunState {
  final MasterworkTask task;
  final String currentStepId;

  const MasterworkRunState({
    required this.task,
    required this.currentStepId,
  });

  MasterworkStep get currentStep => task.steps[currentStepId]!;

  MasterworkRunState copyWith({
    MasterworkTask? task,
    String? currentStepId,
  }) {
    return MasterworkRunState(
      task: task ?? this.task,
      currentStepId: currentStepId ?? this.currentStepId,
    );
  }
}

class LootEvent {
  final String icon;
  final String name;
  final QualityTier? quality;
  final List<String> affixIds;
  LootEvent(this.icon, this.name, [this.quality, this.affixIds = const []]);
}

class LevelUpEvent {
  final SkillType skillType;
  final int level;
  LevelUpEvent(this.skillType, this.level);
}

class ShopEvent {
  final String type; // 'purchase', 'sale', 'error'
  final Item item;
  final int quantity;
  final int goldAmount;

  ShopEvent({
    required this.type,
    required this.item,
    required this.quantity,
    required this.goldAmount,
  });
}

class GameEngine extends ChangeNotifier {
  // Broadcast streams for micro-interactions
  final StreamController<LootEvent> _lootController = StreamController<LootEvent>.broadcast();
  Stream<LootEvent> get lootEvents => _lootController.stream;

  final StreamController<LevelUpEvent> _levelUpController = StreamController<LevelUpEvent>.broadcast();
  Stream<LevelUpEvent> get levelUpEvents => _levelUpController.stream;

  final StreamController<ShopEvent> _shopController = StreamController<ShopEvent>.broadcast();
  Stream<ShopEvent> get shopEvents => _shopController.stream;

  final StreamController<QuestEvent> _questController = StreamController<QuestEvent>.broadcast();
  Stream<QuestEvent> get questEvents => _questController.stream;

  final StreamController<MilestoneEvent> _milestoneController = StreamController<MilestoneEvent>.broadcast();
  Stream<MilestoneEvent> get milestoneEvents => _milestoneController.stream;

  final List<Quest> _activeQuests = [];
  final List<Quest> _completedQuests = [];
  final Set<String> _knownCodexFragmentIds = {};
  final Map<String, BestiaryEntry> _bestiary = {};
  final Map<String, RegionStatusInfo> _regionStatus = {};
  final Set<String> _earnedAchievementIds = {};
  final Set<String> _firedMilestoneIds = {};
  final Set<String> _engineFlags = {};
  String? _activeTitleId;
  bool _isPaused = false;

  PlayerStats _playerStats = PlayerStats.initial();
  Map<SkillType, SkillState> _skills = {};
  Inventory _inventory = Inventory.initial();
  Zone _currentZone = Zones.townSquare;
  final List<LogEntry> _logs = [];
  final Set<String> _unlockedZoneIds = {'town_square'};
  final Map<String, double> _explorationProgress = {
    'explore_forest_paths': 0.0,
    'explore_rocky_trails': 0.0,
    'explore_deep_woods': 0.0,
    'explore_lower_shafts': 0.0,
  };

  ShopState _shopState = ShopState.initial();
  ShopState get shopState => _shopState;

  int _maxEquipmentSlots = 1;
  final Map<SkillType, InventorySlot> _equippedToolSlots = {};
  InventorySlot? _equippedWeaponSlot;
  InventorySlot? _equippedArmorSlot;
  CombatState? _activeCombat;

  ActiveActionState? _playerAction;
  Timer? _globalTimer;
  final Map<String, StationInstance> _stationInstances = {};
  final Set<String> _knownRecipeIds = {};
  final Set<String> _idleWarnedStations = {};
  int _activeTabIndex = 0;
  String? _focusedStationId;

  int get activeTabIndex => _activeTabIndex;
  String? get focusedStationId => _focusedStationId;

  void setActiveTabIndex(int index) {
    _activeTabIndex = index;
    notifyListeners();
  }

  void focusStation(String stationId) {
    _focusedStationId = stationId;
    _activeTabIndex = 3; // Workshop tab
    notifyListeners();
  }

  void clearFocusedStation() {
    _focusedStationId = null;
    notifyListeners();
  }

  MasterworkRunState? _activeMasterwork;

  final Random _random = Random();

  GameEngine() {
    // Initialize skills
    for (var type in SkillType.values) {
      _skills[type] = SkillState.initial(type);
    }
    // Initialize ruined stations in Town Square
    _initializeRuinedStations();

    // Add initial logs
    log("Welcome to Elaria RPG! Set off, gather resources, and level up.", LogType.info);
    log("Tavern rumor: Complete a Masterwork Trial every 10 levels to break your limits.", LogType.info);

    recordRegionDiscovered('town_square');
    _bootstrapStarterQuests();
  }

  void _startTimerIfNeeded() {
    if (_globalTimer != null) return;
    _globalTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _tick();
    });
  }

  void _stopTimerIfIdle() {
    if (_globalTimer == null) return;

    // Check player
    if (_playerAction != null) return;

    // Check stations
    for (var instance in _stationInstances.values) {
      if (instance.currentCraft != null || instance.restoration != null || instance.tierUpgrade != null) {
        return;
      }
    }

    _globalTimer!.cancel();
    _globalTimer = null;
  }

  void _initializeRuinedStations() {
    _stationInstances.clear();
    _stationInstances['town_square::crafting_bench'] = StationInstance(
      zoneId: 'town_square',
      stationId: 'crafting_bench',
      tier: 1,
      isRuined: true,
      queue: [],
    );
    _stationInstances['town_square::field_kitchen'] = StationInstance(
      zoneId: 'town_square',
      stationId: 'field_kitchen',
      tier: 1,
      isRuined: true,
      queue: [],
    );
  }



  // Getters
  PlayerStats get playerStats => _playerStats;
  set playerStats(PlayerStats val) {
    _playerStats = val;
    notifyListeners();
  }

  Item? get equippedWeapon => _equippedWeaponSlot?.item;
  Item? get equippedArmor => _equippedArmorSlot?.item;
  InventorySlot? get equippedWeaponSlot => _equippedWeaponSlot;
  InventorySlot? get equippedArmorSlot => _equippedArmorSlot;
  CombatState? get activeCombat => _activeCombat;

  int getPlayerAttack() {
    int base = 5;
    if (_equippedWeaponSlot != null) {
      base += getItemAttackPower(_equippedWeaponSlot!.item, _equippedWeaponSlot!.quality, _equippedWeaponSlot!.affixIds).round();
    }
    // Combat Perk 10 (Slayer's Might): +3 Attack power
    final combatSkill = _skills[SkillType.combat];
    if (combatSkill != null && combatSkill.levelCap > 10) {
      base += 3;
    }
    return base;
  }

  int getPlayerDefense() {
    int base = 0;
    if (_equippedArmorSlot != null) {
      base += getItemDefense(_equippedArmorSlot!.item, _equippedArmorSlot!.quality, _equippedArmorSlot!.affixIds).round();
    }
    // Combat Perk 10 (Slayer's Might): +1 Defense
    final combatSkill = _skills[SkillType.combat];
    if (combatSkill != null && combatSkill.levelCap > 10) {
      base += 1;
    }
    return base;
  }

  void equipWeapon(Item item, [QualityTier? quality, List<String>? affixIds]) {
    if (item.type != ItemType.weapon) return;
    final affs = affixIds ?? const [];
    if (!_inventory.hasItem(item.id, 1)) return;

    // Remove from inventory
    _inventory = _inventory.removeItem(item.id, 1, quality, affs);

    // Unequip current weapon if any
    if (_equippedWeaponSlot != null) {
      if (_inventory.isFull) {
        log("Inventory is full! Cannot unequip current weapon.", LogType.error);
        _inventory = _inventory.addItem(item, 1, quality, affs);
        return;
      }
      _inventory = _inventory.addItem(_equippedWeaponSlot!.item, 1, _equippedWeaponSlot!.quality, _equippedWeaponSlot!.affixIds);
    }

    _equippedWeaponSlot = InventorySlot(item: item, quantity: 1, quality: quality, affixIds: affs);
    log("Equipped ⚔️ ${item.name} (Attack +${getItemAttackPower(item, quality, affs).toInt()}).", LogType.success);
    notifyListeners();
  }

  void unequipWeapon() {
    if (_equippedWeaponSlot == null) return;
    if (_inventory.isFull) {
      log("Inventory is full! Cannot unequip current weapon.", LogType.error);
      return;
    }

    final slot = _equippedWeaponSlot!;
    _equippedWeaponSlot = null;
    _inventory = _inventory.addItem(slot.item, 1, slot.quality, slot.affixIds);
    log("Unequipped ⚔️ ${slot.item.name}.", LogType.info);
    notifyListeners();
  }

  void equipArmor(Item item, [QualityTier? quality, List<String>? affixIds]) {
    if (item.type != ItemType.armor) return;
    final affs = affixIds ?? const [];
    if (!_inventory.hasItem(item.id, 1)) return;

    // Remove from inventory
    _inventory = _inventory.removeItem(item.id, 1, quality, affs);

    // Unequip current armor if any
    if (_equippedArmorSlot != null) {
      if (_inventory.isFull) {
        log("Inventory is full! Cannot unequip current armor.", LogType.error);
        _inventory = _inventory.addItem(item, 1, quality, affs);
        return;
      }
      _inventory = _inventory.addItem(_equippedArmorSlot!.item, 1, _equippedArmorSlot!.quality, _equippedArmorSlot!.affixIds);
    }

    _equippedArmorSlot = InventorySlot(item: item, quantity: 1, quality: quality, affixIds: affs);
    log("Equipped 🛡️ ${item.name} (Defense +${getItemDefense(item, quality, affs).toInt()}).", LogType.success);
    notifyListeners();
  }

  void unequipArmor() {
    if (_equippedArmorSlot == null) return;
    if (_inventory.isFull) {
      log("Inventory is full! Cannot unequip current armor.", LogType.error);
      return;
    }

    final slot = _equippedArmorSlot!;
    _equippedArmorSlot = null;
    _inventory = _inventory.addItem(slot.item, 1, slot.quality, slot.affixIds);
    log("Unequipped 🛡️ ${slot.item.name}.", LogType.info);
    notifyListeners();
  }

  Map<SkillType, SkillState> get skills => _skills;
  
  Inventory get inventory => _inventory;
  set inventory(Inventory val) {
    _inventory = val;
    notifyListeners();
  }

  Map<String, StationInstance> get stationInstances => _stationInstances;

  Map<String, List<String>> get zoneStructures {
    final Map<String, List<String>> res = {};
    for (var instance in _stationInstances.values) {
      if (!instance.isRuined) {
        if (!res.containsKey(instance.zoneId)) {
          res[instance.zoneId] = [];
        }
        res[instance.zoneId]!.add(instance.stationId);
      }
    }
    return res;
  }

  List<String> getBuiltStructuresForZone(String zoneId) {
    return _stationInstances.values
        .where((s) => s.zoneId == zoneId && !s.isRuined)
        .map((s) => s.stationId)
        .toList();
  }

  bool hasStructureInZone(String zoneId, String structureId) {
    final instance = _stationInstances["${zoneId}::${structureId}"];
    return instance != null && !instance.isRuined;
  }


  int get maxEquipmentSlots => _maxEquipmentSlots;
  Map<SkillType, Item> get equippedTools => _equippedToolSlots.map((k, v) => MapEntry(k, v.item));
  Map<SkillType, InventorySlot> get equippedToolSlots => _equippedToolSlots;

  void equipTool(Item item, [QualityTier? quality, List<String>? affixIds]) {
    if (!item.isTool || item.toolSkill == null) {
      log("This item cannot be equipped as a tool!", LogType.error);
      return;
    }

    final skill = item.toolSkill!;
    final affs = affixIds ?? const [];

    // Verify if we have the item in inventory
    if (!_inventory.hasItem(item.id, 1)) {
      log("You don't have this tool in your inventory!", LogType.error);
      return;
    }

    // Check slots restriction if it's a new skill slot
    if (!_equippedToolSlots.containsKey(skill) && _equippedToolSlots.length >= _maxEquipmentSlots) {
      log("All equipment slots full ($_maxEquipmentSlots/$_maxEquipmentSlots)! Unequip a tool first or upgrade your backpack.", LogType.error);
      return;
    }

    cancelAction();

    // Remove tool from inventory
    _inventory = _inventory.removeItem(item.id, 1, quality, affs);

    // Save previous tool if any
    final oldToolSlot = _equippedToolSlots[skill];

    // Equip new tool
    _equippedToolSlots[skill] = InventorySlot(item: item, quantity: 1, quality: quality, affixIds: affs);
    log("Equipped ${item.icon} ${item.name} for ${skill.name}.", LogType.success);

    // Return previous tool to inventory
    if (oldToolSlot != null) {
      _inventory = _inventory.addItem(oldToolSlot.item, 1, oldToolSlot.quality, oldToolSlot.affixIds);
      log("Returned ${oldToolSlot.item.icon} ${oldToolSlot.item.name} to inventory.", LogType.info);
    }

    notifyListeners();
  }

  void unequipTool(SkillType skill) {
    final toolSlot = _equippedToolSlots[skill];
    if (toolSlot == null) {
      log("No tool equipped for ${skill.name}.", LogType.error);
      return;
    }

    if (_inventory.isFull) {
      log("Inventory full! Free some slots first to unequip ${toolSlot.item.name}.", LogType.error);
      return;
    }

    cancelAction();

    _equippedToolSlots.remove(skill);
    _inventory = _inventory.addItem(toolSlot.item, 1, toolSlot.quality, toolSlot.affixIds);
    log("Unequipped ${toolSlot.item.icon} ${toolSlot.item.name} for ${skill.name}.", LogType.success);

    notifyListeners();
  }

  Zone get currentZone => _currentZone;
  Set<String> get unlockedZoneIds => _unlockedZoneIds;
  Map<String, double> get explorationProgress => _explorationProgress;
  List<LogEntry> get logs => List.unmodifiable(_logs);
  ActiveActionState? get activeAction => _playerAction;
  MasterworkRunState? get activeMasterwork => _activeMasterwork;

  List<Quest> get activeQuests => List.unmodifiable(_activeQuests);
  List<Quest> get completedQuests => List.unmodifiable(_completedQuests);
  Set<String> get knownCodexFragmentIds => Set.unmodifiable(_knownCodexFragmentIds);
  Map<String, BestiaryEntry> get bestiary => Map.unmodifiable(_bestiary);
  Map<String, RegionStatusInfo> get regionStatus => Map.unmodifiable(_regionStatus);
  Set<String> get earnedAchievementIds => Set.unmodifiable(_earnedAchievementIds);
  Set<String> get firedMilestoneIds => Set.unmodifiable(_firedMilestoneIds);
  Set<String> get engineFlags => Set.unmodifiable(_engineFlags);
  String? get activeTitleId => _activeTitleId;
  bool get isPaused => _isPaused;


  List<Recipe> getAvailableRecipes() {
    return [
      ...Recipes.all,
      Recipes.getBackpackRecipe(_inventory.capacity),
    ];
  }

  final List<LogEntry> _notifications = [];
  List<LogEntry> get notifications => List.unmodifiable(_notifications);
  final List<Timer> _notificationTimers = [];

  void triggerNotification(String message, LogType type) {
    final entry = LogEntry(timestamp: DateTime.now(), message: message, type: type);
    _notifications.add(entry);
    notifyListeners();
    
    final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (isTest) {
      // Clear immediately or keep it simple for tests without pending timers
      _notifications.remove(entry);
      return;
    }

    late Timer timer;
    timer = Timer(const Duration(milliseconds: 2800), () {
      _notifications.remove(entry);
      _notificationTimers.remove(timer);
      notifyListeners();
    });
    _notificationTimers.add(timer);
  }

  // Logging helper
  void log(String message, [LogType type = LogType.info]) {
    _logs.insert(0, LogEntry(
      timestamp: DateTime.now(),
      message: message,
      type: type,
    ));
    if (_logs.length > 50) {
      _logs.removeLast();
    }
    
    // Auto-trigger notifications for success, warning, error, levelUp
    if (type == LogType.success || type == LogType.levelUp || type == LogType.warning || type == LogType.error) {
      triggerNotification(message, type);
    } else {
      notifyListeners();
    }
  }

  // Travel
  void travelTo(Zone zone) {
    if (zone.id == _currentZone.id) return;
    if (!_unlockedZoneIds.contains(zone.id)) {
      log("You cannot travel to ${zone.name} yet! It is locked.", LogType.error);
      return;
    }
    
    // Stop current action
    cancelAction();
    cancelMasterwork();

    _currentZone = zone;
    log("Traveled to ${zone.name}.", LogType.info);

    _notifyQuestObservers(ZoneVisitedEvent(zone.id));
    recordRegionDiscovered(zone.id);

    if (zone.id == 'town_square') {
      checkShopRestock();
    }

    notifyListeners();
  }

  void unlockZone(String zoneId) {
    if (_unlockedZoneIds.contains(zoneId)) return;
    _unlockedZoneIds.add(zoneId);
    final zone = Zones.findById(zoneId);
    log("🗺️ New Zone Discovered: ${zone.name}!", LogType.success);
    notifyListeners();
  }

  /// Calculate global XP multiplier based on Lore skill level and perks
  double getXpMultiplier() {
    final loreSkill = _skills[SkillType.lore];
    if (loreSkill == null) return 1.0;
    double mult = 1.0 + (loreSkill.level - 1) * 0.03;
    if (loreSkill.levelCap > 10) mult += 0.15;
    if (loreSkill.levelCap > 20) mult += 0.25;
    return mult;
  }

  /// Get total action speed bonus (combines level-based, masterwork perks, and equipped tool)
  double getSkillSpeedBonus(SkillType type) {
    final skill = _skills[type];
    if (skill == null) return 0.0;
    
    double bonus = (skill.level - 1) * 0.02; // +2% per level above 1
    if (skill.levelCap > 10) bonus += 0.20; // Lvl 10 Perk (+20% speed)
    if (skill.levelCap > 20) bonus += 0.30; // Lvl 20 Perk (+30% speed)

    final toolSlot = _equippedToolSlots[type];
    if (toolSlot != null) {
      bonus += getItemSpeedBonus(toolSlot.item, toolSlot.quality, toolSlot.affixIds);
    }
    return bonus;
  }

  /// Get total success chance bonus (combines level-based and equipped tool success bonuses)
  double getSkillSuccessBonus(SkillType type) {
    final skill = _skills[type];
    if (skill == null) return 0.0;

    double bonus = (skill.level - 1) * 0.01; // +1% per level above 1
    
    final toolSlot = _equippedToolSlots[type];
    if (toolSlot != null) {
      bonus += getItemSuccessBonus(toolSlot.item, toolSlot.quality, toolSlot.affixIds);
    }
    return bonus;
  }

  /// Get modified energy cost for a skill-based action, recipe, or structure
  int getModifiedEnergyCost(int baseCost, SkillType? skillType) {
    if (baseCost <= 0 || skillType == null) return baseCost;
    final skill = _skills[skillType];
    if (skill == null) return baseCost;

    // Level-based reduction: -1% energy cost per level above 1
    double reduction = (skill.level - 1) * 0.01;
    double cost = baseCost * (1.0 - reduction);

    // Masterwork flat reductions (Tier 10 perk)
    if (skill.levelCap > 10) {
      switch (skillType) {
        case SkillType.woodcutting:
          cost -= 2;
          break;
        case SkillType.mining:
          cost -= 3;
          break;
        case SkillType.herbalism:
          cost -= 1;
          break;
        case SkillType.wayfinding:
          cost -= 2;
          break;
        case SkillType.crafting:
        case SkillType.cooking:
          cost -= 1;
          break;
        default:
          break;
      }
    }

    // Apply tool/weapon/armor affixes!
    final toolSlot = _equippedToolSlots[skillType];
    if (toolSlot != null) {
      if (toolSlot.affixIds.contains('frugal')) {
        cost *= 0.90;
      }
      if (toolSlot.affixIds.contains('ergonomic')) {
        cost -= 1.0;
      }
    }

    if (skillType == SkillType.combat) {
      if (_equippedWeaponSlot != null && _equippedWeaponSlot!.affixIds.contains('frugal')) {
        cost *= 0.90;
      }
      if (_equippedArmorSlot != null && _equippedArmorSlot!.affixIds.contains('frugal')) {
        cost *= 0.90;
      }
    }

    return max(0, cost.round());
  }

  // Timer Tick Action
  void startAction(ZoneAction action) {
    // 0. Combat specific health check
    if (action.isCombat && _playerStats.currentHealth <= 0) {
      log("You are too weak to fight! Rest at the Town Inn or eat food.", LogType.error);
      return;
    }

    // 1. Skill requirement check
    if (action.requiredSkill != null) {
      final skill = _skills[action.requiredSkill!];
      if (skill == null || skill.level < action.requiredLevel) {
        log("Requirements not met: Needs Level ${action.requiredLevel} ${action.requiredSkill!.name}.", LogType.error);
        return;
      }

      // 2. Gate check (Masterwork lock)
      if (skill.isGated) {
        log("Level Capped! Complete the Level ${skill.levelCap} Masterwork Trial to continue.", LogType.warning);
        return;
      }
    }

    // 3. Energy check
    // If energyCost is positive (consumption), ensure we have enough.
    // Negative energyCost means we are recovering energy (e.g. resting).
    final actualEnergyCost = getModifiedEnergyCost(action.energyCost, action.requiredSkill);
    if (actualEnergyCost > 0 && _playerStats.currentEnergy < actualEnergyCost) {
      log("Not enough energy! Rest at the Town Inn or eat food.", LogType.error);
      return;
    }

    // 4. Gold check for Inn Rest
    if (action.id == 'inn_rest' && _playerStats.gold < 15) {
      log("Not enough gold! You need 15 Gold to rest at the Inn.", LogType.error);
      return;
    }

    // Cancel previous
    cancelAction();

    // Initialize combat state if combat action
    if (action.isCombat && action.beastId != null) {
      final beast = Beasts.findById(action.beastId!);
      if (beast == null) {
        log("Error: Beast ${action.beastId} not found!", LogType.error);
        return;
      }
      _activeCombat = CombatState(
        beast: beast,
        beastCurrentHealth: beast.maxHealth,
        playerStartHealth: _playerStats.currentHealth,
        combatLog: ["Tracked down ${beast.icon} ${beast.name}!"],
      );
    }

    // Calculate speed bonus from skill level and equipped tools
    double speedBonus = 0.0;
    if (action.requiredSkill != null) {
      speedBonus = getSkillSpeedBonus(action.requiredSkill!);
    }

    // Apply zone speed modifiers
    // Duration = BaseDuration / (1 + speedBonus) / zoneSpeedModifier
    double duration = action.durationSeconds.toDouble();
    if (action.isCombat) {
      // Combat round duration is fixed at 1.5s, modified by Combat Perk 20
      duration = 1.5;
      final combatSkill = _skills[SkillType.combat];
      if (combatSkill != null && combatSkill.levelCap > 20) {
        duration = duration / 1.15; // 15% speed increase
      }
    } else {
      duration = duration / (1.0 + speedBonus);
      duration = duration / _currentZone.speedModifier;
    }
    if (duration < 1.0) duration = 1.0;

    _playerAction = ActiveActionState(
      action: action,
      progress: 0.0,
      durationSeconds: duration,
    );
    _startTimerIfNeeded();
    notifyListeners();
  }

  void _executeCombatRound(ZoneAction action) {
    if (_activeCombat == null) return;

    final beast = _activeCombat!.beast;
    
    // Player attacks Beast
    int playerDamage = max(1, getPlayerAttack() - beast.defense);
    final variance = 0.85 + _random.nextDouble() * 0.30;
    playerDamage = (playerDamage * variance).round().clamp(1, 9999);

    int nextBeastHealth = max(0, _activeCombat!.beastCurrentHealth - playerDamage);
    
    final updatedLog = List<String>.from(_activeCombat!.combatLog);
    updatedLog.add("⚔️ You strike ${beast.name} for $playerDamage damage!");

    _activeCombat = _activeCombat!.copyWith(
      beastCurrentHealth: nextBeastHealth,
      combatLog: updatedLog,
    );

    if (nextBeastHealth <= 0) {
      updatedLog.add("🎉 ${beast.name} has been defeated!");
      return;
    }

    // Beast attacks Player
    int beastDamage = max(1, beast.attackPower - getPlayerDefense());
    final beastVariance = 0.85 + _random.nextDouble() * 0.30;
    beastDamage = (beastDamage * beastVariance).round().clamp(1, 9999);

    int nextPlayerHealth = max(0, _playerStats.currentHealth - beastDamage);
    updatedLog.add("${beast.icon} ${beast.name} strikes you for $beastDamage damage!");

    _playerStats = _playerStats.copyWith(currentHealth: nextPlayerHealth);
    _activeCombat = _activeCombat!.copyWith(combatLog: updatedLog);

    if (nextPlayerHealth <= 0) {
      updatedLog.add("💀 You collapsed from your wounds...");
    }
  }

  Set<String> get knownRecipeIds => _knownRecipeIds;

  bool isRecipeUnlocked(Recipe r) {
    if (r.id == 'leather_backpack' || r.id == 'backpack_upgrade') {
      final skill = _skills[r.requiredSkill];
      final skillLevel = skill?.level ?? 1;
      return skillLevel >= r.requiredLevel;
    }
    final skill = _skills[r.requiredSkill];
    final skillLevel = skill?.level ?? 1;
    
    final isCommonAndUnlocked = (r.rarity == RecipeRarity.common && skillLevel >= r.requiredLevel);
    final isLearned = _knownRecipeIds.contains(r.id);

    return isCommonAndUnlocked || isLearned;
  }

  List<Recipe> getRecipesForStation(String stationId, {bool showLocked = false}) {
    final allRecipes = getAvailableRecipes();
    return allRecipes.where((r) {
      if (r.stationId != stationId) return false;
      if (showLocked) return true;
      return isRecipeUnlocked(r);
    }).toList();
  }

  bool canCraftRecipe(Recipe recipe) {
    final stationKey = "${_currentZone.id}::${recipe.stationId}";
    final instance = _stationInstances[stationKey];
    return instance != null && !instance.isRuined;
  }

  void startCrafting(Recipe recipe) {
    final stationId = recipe.stationId;
    final stationKey = "${_currentZone.id}::$stationId";
    
    // Quick queue with default choices
    final Map<int, String> slotChoices = {};
    for (int i = 0; i < recipe.slots.length; i++) {
      slotChoices[i] = recipe.slots[i].acceptedItems.first.itemId;
    }
    
    queueStationCraft(stationKey, recipe.id, slotChoices, count: 1);
  }

  void queueStationCraft(String stationKey, String recipeId, Map<int, String> slotChoices, {String? modifierItemId, int count = 1}) {
    final recipe = Recipes.findById(recipeId);
    if (recipe == null) return;

    final instance = _stationInstances[stationKey];
    if (instance == null || instance.isRuined) {
      log("This station is not built or is ruined!", LogType.error);
      return;
    }

    final station = Stations.findById(instance.stationId);
    if (station == null) return;

    final maxSlots = station.getTier(instance.tier).queueSlots;
    final currentActive = (instance.currentCraft != null ? 1 : 0) + instance.queue.length;
    if (currentActive >= maxSlots) {
      log("Station queue is full! Upgrade the station to unlock more slots.", LogType.error);
      return;
    }

    // Verify level requirement
    final skill = _skills[recipe.requiredSkill];
    if (skill == null || skill.level < recipe.requiredLevel) {
      log("Requirements not met: Needs Level ${recipe.requiredLevel} ${recipe.requiredSkill.name}.", LogType.error);
      return;
    }

    // Verify materials and reserve them
    final Map<String, int> reservation = {};
    for (int i = 0; i < recipe.slots.length; i++) {
      final slot = recipe.slots[i];
      final choiceItemId = slotChoices[i] ?? slot.acceptedItems.first.itemId;
      reservation[choiceItemId] = (reservation[choiceItemId] ?? 0) + slot.quantity * count;
    }

    if (modifierItemId != null) {
      reservation[modifierItemId] = (reservation[modifierItemId] ?? 0) + count;
    }

    for (var entry in reservation.entries) {
      if (!_inventory.hasItem(entry.key, entry.value)) {
        final item = Items.findById(entry.key);
        log("Not enough ingredients! Missing: ${item?.name ?? entry.key} x${entry.value}.", LogType.error);
        return;
      }
    }

    // Consume (reserve) from inventory
    for (var entry in reservation.entries) {
      _inventory = _inventory.removeItem(entry.key, entry.value);
    }

    // Add to queue
    final entry = QueuedCraft(
      recipeId: recipeId,
      count: count,
      slotChoices: slotChoices,
      modifierItemId: modifierItemId,
    );
    instance.queue.add(entry);

    log("Queued ${recipe.name} x$count at ${station.name}.", LogType.success);

    if (instance.currentCraft == null) {
      _startNextStationCraft(instance);
    } else {
      notifyListeners();
    }
  }

  void cancelStationQueueEntry(String stationKey, int entryIndex) {
    final instance = _stationInstances[stationKey];
    if (instance == null || instance.queue.length <= entryIndex) return;

    final entry = instance.queue[entryIndex];
    final recipe = Recipes.findById(entry.recipeId);
    if (recipe == null) return;

    // Calculate refund
    final Map<String, int> refund = {};
    for (int i = 0; i < recipe.slots.length; i++) {
      final slot = recipe.slots[i];
      final choiceItemId = entry.slotChoices[i] ?? slot.acceptedItems.first.itemId;
      refund[choiceItemId] = (refund[choiceItemId] ?? 0) + slot.quantity * entry.count;
    }

    if (entry.modifierItemId != null) {
      refund[entry.modifierItemId!] = (refund[entry.modifierItemId!] ?? 0) + entry.count;
    }

    // Refund to inventory
    for (var refundEntry in refund.entries) {
      final item = Items.findById(refundEntry.key);
      if (item != null) {
        _inventory = _inventory.addItem(item, refundEntry.value);
      }
    }

    log("Cancelled queue entry for ${recipe.name} x${entry.count}. Refunded materials.", LogType.info);

    if (entryIndex == 0) {
      instance.currentCraft = null;
      instance.queue.removeAt(0);
      _startNextStationCraft(instance);
    } else {
      instance.queue.removeAt(entryIndex);
      notifyListeners();
    }
  }

  void _startNextStationCraft(StationInstance instance) {
    if (instance.queue.isEmpty) {
      instance.currentCraft = null;
      notifyListeners();
      return;
    }

    final queued = instance.queue.first;
    final recipe = Recipes.findById(queued.recipeId);
    if (recipe == null) {
      instance.queue.removeAt(0);
      _startNextStationCraft(instance);
      return;
    }

    double duration = recipe.durationSeconds.toDouble();
    duration = duration / (1.0 + getSkillSpeedBonus(recipe.requiredSkill));
    if (duration < 1.0) duration = 1.0;

    instance.currentCraft = ActiveActionState(
      recipe: recipe,
      progress: 0.0,
      durationSeconds: duration,
    );
    notifyListeners();
  }

  void startRestoringStation(String stationId) {
    if (_playerAction != null) {
      log("You are already busy with another action!", LogType.error);
      return;
    }

    final station = Stations.findById(stationId);
    if (station == null) {
      log("Station not found!", LogType.error);
      return;
    }

    final stationKey = "${_currentZone.id}::$stationId";
    final instance = _stationInstances[stationKey];
    if (instance == null || !instance.isRuined) {
      log("This station does not need restoration!", LogType.error);
      return;
    }

    final Map<String, int> cost = (stationId == 'crafting_bench')
        ? {'oak_log': 5, 'river_clay': 3}
        : {'oak_log': 3, 'river_clay': 5};
    final int durationSeconds = 10;
    final int energyCost = 5;
    final int requiredLevel = 1;

    final skill = _skills[station.primarySkill];
    if (skill == null || skill.level < requiredLevel) {
      log("Requirements not met: Needs Level $requiredLevel ${station.primarySkill.name}.", LogType.error);
      return;
    }

    final actualEnergyCost = getModifiedEnergyCost(energyCost, station.primarySkill);
    if (actualEnergyCost > 0 && _playerStats.currentEnergy < actualEnergyCost) {
      log("Not enough energy to start restoring!", LogType.error);
      return;
    }

    for (var entry in cost.entries) {
      if (!_inventory.hasItem(entry.key, entry.value)) {
        final item = Items.findById(entry.key);
        log("Not enough ingredients! Missing: ${item?.name ?? entry.key} x${entry.value}.", LogType.error);
        return;
      }
    }

    for (var entry in cost.entries) {
      _inventory = _inventory.removeItem(entry.key, entry.value);
    }

    double duration = durationSeconds.toDouble();
    duration = duration / (1.0 + getSkillSpeedBonus(station.primarySkill));
    if (duration < 1.0) duration = 1.0;

    _playerAction = ActiveActionState(
      station: station,
      isRestoration: true,
      targetZoneId: _currentZone.id,
      progress: 0.0,
      durationSeconds: duration,
    );

    instance.restoration = _playerAction;
    _startTimerIfNeeded();
    notifyListeners();
  }

  void startUpgradingStation(String stationId) {
    if (_playerAction != null) {
      log("You are already busy with another action!", LogType.error);
      return;
    }

    final station = Stations.findById(stationId);
    if (station == null) {
      log("Station not found!", LogType.error);
      return;
    }

    final stationKey = "${_currentZone.id}::$stationId";
    final instance = _stationInstances[stationKey];
    if (instance == null || instance.isRuined) {
      log("Station must be built and restored before upgrading!", LogType.error);
      return;
    }

    if (instance.tier >= station.maxTier) {
      log("Station is already at maximum tier!", LogType.error);
      return;
    }

    final nextTierVal = instance.tier + 1;
    final nextTier = station.getTier(nextTierVal);

    final skill = _skills[station.primarySkill];
    if (skill == null || skill.level < nextTier.requiredSkillLevel) {
      log("Requirements not met: Needs Level ${nextTier.requiredSkillLevel} ${station.primarySkill.name}.", LogType.error);
      return;
    }

    final actualEnergyCost = getModifiedEnergyCost(nextTier.upgradeEnergyCost, station.primarySkill);
    if (actualEnergyCost > 0 && _playerStats.currentEnergy < actualEnergyCost) {
      log("Not enough energy to start upgrade!", LogType.error);
      return;
    }

    for (var entry in nextTier.upgradeCost.entries) {
      if (!_inventory.hasItem(entry.key, entry.value)) {
        final item = Items.findById(entry.key);
        log("Not enough ingredients! Missing: ${item?.name ?? entry.key} x${entry.value}.", LogType.error);
        return;
      }
    }

    for (var entry in nextTier.upgradeCost.entries) {
      _inventory = _inventory.removeItem(entry.key, entry.value);
    }

    double duration = nextTier.upgradeDurationSeconds.toDouble();
    duration = duration / (1.0 + getSkillSpeedBonus(station.primarySkill));
    if (duration < 1.0) duration = 1.0;

    _playerAction = ActiveActionState(
      station: station,
      isUpgrade: true,
      targetZoneId: _currentZone.id,
      progress: 0.0,
      durationSeconds: duration,
    );

    instance.tierUpgrade = _playerAction;
    _startTimerIfNeeded();
    notifyListeners();
  }


  void rollBlueprintScrollDrop(int zoneTier) {
    if (_random.nextDouble() > 0.02) return;

    BlueprintItem? droppedScroll;
    if (zoneTier == 1) {
      droppedScroll = Items.blueprintSteelPlate;
    } else if (zoneTier == 2) {
      if (_random.nextBool()) {
        droppedScroll = Items.blueprintSteelPlate;
      } else {
        droppedScroll = Items.blueprintSteelGreatsword;
      }
    } else if (zoneTier >= 3) {
      final r = _random.nextDouble();
      if (r < 0.3) {
        droppedScroll = Items.blueprintGreaterSteelGreatsword;
      } else if (r < 0.6) {
        droppedScroll = Items.blueprintElixir4;
      } else if (r < 0.9) {
        droppedScroll = Items.blueprintGlyphMastery;
      } else {
        droppedScroll = Items.blueprintSteelGreatsword;
      }
    }

    if (droppedScroll != null) {
      if (_inventory.isFull) {
        log("Your inventory is full! A blueprint scroll was dropped.", LogType.error);
      } else {
        _inventory = _inventory.addItem(droppedScroll, 1);
        log("✨ Discovery! Found a ${droppedScroll.name}!", LogType.success);
        _lootController.add(LootEvent(droppedScroll.icon, droppedScroll.name));
      }
    }
  }


  void startBuilding(Structure structure, String zoneId) {
    if (zoneId == 'town_square') {
      log("You cannot build structures in the Town Square!", LogType.error);
      return;
    }

    if (hasStructureInZone(zoneId, structure.id)) {
      log("You have already built a ${structure.name} in this zone!", LogType.error);
      return;
    }

    // 1. Skill requirement check
    final skill = _skills[structure.requiredSkill];
    if (skill == null || skill.level < structure.requiredLevel) {
      log("Requirements not met: Needs Level ${structure.requiredLevel} ${structure.requiredSkill.name}.", LogType.error);
      return;
    }

    // 2. Gate check (Masterwork lock)
    if (skill.isGated) {
      log("Level Capped! Complete the Level ${skill.levelCap} Masterwork Trial to continue.", LogType.warning);
      return;
    }

    // 3. Energy check
    final actualEnergyCost = getModifiedEnergyCost(structure.energyCost, structure.requiredSkill);
    if (actualEnergyCost > 0 && _playerStats.currentEnergy < actualEnergyCost) {
      log("Not enough energy! Rest or eat food.", LogType.error);
      return;
    }

    // 4. Ingredients check
    for (var entry in structure.cost.entries) {
      final itemId = entry.key;
      final requiredQty = entry.value;
      if (!_inventory.hasItem(itemId, requiredQty)) {
        final item = Items.findById(itemId);
        final itemName = item != null ? item.name : itemId;
        log("Not enough ingredients! Missing: $itemName x$requiredQty.", LogType.error);
        return;
      }
    }

    // Cancel previous player action
    cancelAction();

    // Consume ingredients immediately
    for (var entry in structure.cost.entries) {
      _inventory = _inventory.removeItem(entry.key, entry.value);
    }

    double duration = structure.durationSeconds.toDouble();
    duration = duration / (1.0 + getSkillSpeedBonus(structure.requiredSkill));
    if (duration < 1.0) duration = 1.0;

    _playerAction = ActiveActionState(
      structure: structure,
      targetZoneId: zoneId,
      progress: 0.0,
      durationSeconds: duration,
    );
    _startTimerIfNeeded();
    notifyListeners();
  }

  void _completePlayerAction() {
    if (_playerAction == null) return;
    final state = _playerAction!;

    if (state.action != null && state.action!.isCombat) {
      final action = state.action!;
      // 1. Deduct Energy
      final actualEnergyCost = getModifiedEnergyCost(action.energyCost, action.requiredSkill ?? SkillType.combat);
      int newEnergy = _playerStats.currentEnergy - actualEnergyCost;
      newEnergy = newEnergy.clamp(0, _playerStats.maxEnergy);
      _playerStats = _playerStats.copyWith(currentEnergy: newEnergy);

      // 2. Award Combat XP
      final oldSkill = _skills[SkillType.combat]!;
      final xpReward = action.xpReward * getXpMultiplier();
      final newSkill = oldSkill.addXp(xpReward);
      _skills[SkillType.combat] = newSkill;

      if (newSkill.level > oldSkill.level) {
        log("Level Up! Your Combat is now Level ${newSkill.level}!", LogType.levelUp);
        _levelUpController.add(LevelUpEvent(SkillType.combat, newSkill.level));
      } else if (newSkill.isGated && !oldSkill.isGated) {
        log("Limit Reached! Level ${newSkill.levelCap} Masterwork Trial is now unlocked. Check the Skills tab.", LogType.warning);
      }
      _maybeOfferMasterworkQuest(SkillType.combat);

      // 3. Award Monster drops
      bool doubleLoot = false;
      if (oldSkill.levelCap > 20) {
        if (_random.nextDouble() <= 0.15) {
          doubleLoot = true;
        }
      }

      bool inventoryFullError = false;
      final beast = _activeCombat?.beast;
      final List<String> drops = [];
      if (beast != null) {
        for (var loot in beast.lootTable) {
          final roll = _random.nextDouble();
          if (roll <= loot.chance) {
            int qty = loot.minQuantity;
            if (loot.maxQuantity > loot.minQuantity) {
              qty = loot.minQuantity + _random.nextInt(loot.maxQuantity - loot.minQuantity + 1);
            }
            if (doubleLoot) {
              qty *= 2;
            }
            drops.add(loot.item.id);
            if (_inventory.isFull) {
              inventoryFullError = true;
            } else {
              _inventory = _inventory.addItem(loot.item, qty);
              log("Defeated ${beast.name}! Obtained: ${loot.item.icon} ${loot.item.name} x$qty", LogType.success);
              _lootController.add(LootEvent(loot.item.icon, loot.item.name));
            }
          }
        }
        rollBlueprintScrollDrop(_currentZone.tier);

        recordBestiary(beast.id, drops);
        _notifyQuestObservers(BeastDefeatedEvent(beast.id));
      }

      if (doubleLoot && !inventoryFullError) {
        log("✨ Gladiator's Grace Perk: Yield quantities doubled!", LogType.success);
      }

      if (inventoryFullError) {
        log("Your inventory is full! Some monster drops were lost.", LogType.error);
      }

      log("Success! Finished Hunting ${beast?.name ?? action.name} (+${xpReward.toInt()} Combat XP).", LogType.success);

      _activeCombat = null;
      _playerAction = null;
      notifyListeners();

      // Auto-repeat combat
      startAction(action);
      return;
    }

    if (state.structure != null) {
      final structure = state.structure!;
      final zoneId = state.targetZoneId!;

      // Deduct Energy
      final actualEnergyCost = getModifiedEnergyCost(structure.energyCost, structure.requiredSkill);
      int newEnergy = _playerStats.currentEnergy - actualEnergyCost;
      newEnergy = newEnergy.clamp(0, _playerStats.maxEnergy);
      _playerStats = _playerStats.copyWith(currentEnergy: newEnergy);

      // Award XP
      final oldSkill = _skills[structure.requiredSkill]!;
      final xpReward = structure.xpReward * getXpMultiplier();
      final newSkill = oldSkill.addXp(xpReward);
      _skills[structure.requiredSkill] = newSkill;

      if (newSkill.level > oldSkill.level) {
        log("Level Up! Your ${structure.requiredSkill.name} is now Level ${newSkill.level}!", LogType.levelUp);
        _levelUpController.add(LevelUpEvent(structure.requiredSkill, newSkill.level));
      } else if (newSkill.isGated && !oldSkill.isGated) {
        log("Limit Reached! Level ${newSkill.levelCap} Masterwork Trial is now unlocked. Check the Skills tab.", LogType.warning);
      }
      _maybeOfferMasterworkQuest(structure.requiredSkill);

      // Add to structures list for that zone (create/add StationInstance)
      final stationKey = "$zoneId::${structure.id}";
      _stationInstances[stationKey] = StationInstance(
        zoneId: zoneId,
        stationId: structure.id,
        tier: 1,
        isRuined: false,
        queue: [],
      );

      log("Success! Finished building ${structure.name} (+${xpReward.toInt()} ${structure.requiredSkill.name} XP).", LogType.success);

      _playerAction = null;
      notifyListeners();
      return;
    }

    if (state.station != null) {
      final station = state.station!;
      final zoneId = state.targetZoneId!;
      final stationKey = "$zoneId::${station.id}";
      final instance = _stationInstances[stationKey];

      if (state.isRestoration) {
        if (instance != null) {
          instance.isRuined = false;
          log("Success! Restored ${station.name} in Town Square! It is now fully operational.", LogType.success);
          _notifyQuestObservers(StationRestoredEvent(zoneId, station.id));
        }
      } else if (state.isUpgrade) {
        if (instance != null) {
          instance.tier = min(station.maxTier, instance.tier + 1);
          log("Success! Upgraded ${station.name} in ${zoneId} to Tier ${instance.tier}!", LogType.success);
          _notifyQuestObservers(StationUpgradedEvent(zoneId, station.id, instance.tier));
        }
      }

      _playerAction = null;
      notifyListeners();
      return;
    }

    final action = state.action!;

    // Deduct/Recover Energy
    final actualEnergyCost = getModifiedEnergyCost(action.energyCost, action.requiredSkill);
    int newEnergy = _playerStats.currentEnergy - actualEnergyCost;
    newEnergy = newEnergy.clamp(0, _playerStats.maxEnergy);

    // Apply Gold Cost if Inn Rest
    int newGold = _playerStats.gold;
    if (action.id == 'inn_rest') {
      newGold = max(0, newGold - 15);
    }

    _playerStats = _playerStats.copyWith(
      currentEnergy: newEnergy,
      gold: newGold,
    );

    // Roll hazard / damage
    if (action.healthCost > 0 && action.hazardChance > 0) {
      final roll = _random.nextDouble();
      if (roll <= action.hazardChance) {
        int damage = action.healthCost;
        int newHealth = max(0, _playerStats.currentHealth - damage);
        _playerStats = _playerStats.copyWith(currentHealth: newHealth);
        log("Hazard! You were struck by a falling hazard for $damage damage!", LogType.warning);

        if (_playerStats.isDead) {
          faint();
          return;
        }
      }
    } else if (action.healthCost < 0) {
      // Recovery (negative cost)
      int healed = -action.healthCost;
      int newHealth = min(_playerStats.maxHealth, _playerStats.currentHealth + healed);
      _playerStats = _playerStats.copyWith(currentHealth: newHealth);
    }

    // Bare-handed harvesting check
    bool hasRequiredTool = true;
    if (action.requiredSkill != null) {
      final isHarvestingSkill = action.requiredSkill == SkillType.woodcutting ||
          action.requiredSkill == SkillType.mining ||
          action.requiredSkill == SkillType.herbalism;
          
      if (isHarvestingSkill) {
        final equippedTool = _equippedToolSlots[action.requiredSkill!];
        final skillState = _skills[action.requiredSkill!];
        final isImmuneToBareHanded = skillState != null && skillState.levelCap > 10;
        
        if (equippedTool == null) {
          hasRequiredTool = false;
          
          if (!isImmuneToBareHanded) {
            int bareDamage = 0;
            String damageReason = "";
            if (action.requiredSkill == SkillType.woodcutting) {
              bareDamage = 5;
              damageReason = "bruised knuckles and wood splinters";
            } else if (action.requiredSkill == SkillType.mining) {
              bareDamage = 8;
              damageReason = "cut fingers and sharp stone shards";
            } else if (action.requiredSkill == SkillType.herbalism) {
              bareDamage = 3;
              damageReason = "rose pricks and skin irritation";
            }
            
            int bareHealth = max(0, _playerStats.currentHealth - bareDamage);
            _playerStats = _playerStats.copyWith(currentHealth: bareHealth);
            log("🩹 Ouch! Harvesting ${action.requiredSkill!.name.toLowerCase()} with your bare hands dealt $bareDamage damage ($damageReason)!", LogType.warning);
            
            if (_playerStats.isDead) {
              faint();
              return;
            }
          }
        }
      }
    }

    // Award XP
    if (action.requiredSkill != null) {
      final oldSkill = _skills[action.requiredSkill!]!;
      final xpReward = action.xpReward * getXpMultiplier();
      final newSkill = oldSkill.addXp(xpReward);
      _skills[action.requiredSkill!] = newSkill;

      if (newSkill.level > oldSkill.level) {
        log("Level Up! Your ${action.requiredSkill!.name} is now Level ${newSkill.level}!", LogType.levelUp);
        _levelUpController.add(LevelUpEvent(action.requiredSkill!, newSkill.level));
      } else if (newSkill.isGated && !oldSkill.isGated) {
        log("Limit Reached! Level ${newSkill.levelCap} Masterwork Trial is now unlocked. Check the Skills tab.", LogType.warning);
      }
      _maybeOfferMasterworkQuest(action.requiredSkill!);
    }

    // Roll Loot table
    bool inventoryFullError = false;
    
    // Retrieve success bonus from equipped tool and level
    double successBonus = 0.0;
    if (action.requiredSkill != null) {
      successBonus = getSkillSuccessBonus(action.requiredSkill!);
    }

    // Check Woodcutting, Mining, Herbalism Level 20 Perk: 15% chance to double yield
    bool doubleYield = false;
    if (action.requiredSkill != null &&
        (action.requiredSkill == SkillType.woodcutting ||
         action.requiredSkill == SkillType.mining ||
         action.requiredSkill == SkillType.herbalism)) {
      final skill = _skills[action.requiredSkill!];
      if (skill != null && skill.levelCap > 20) {
        if (_random.nextDouble() <= 0.15) {
          doubleYield = true;
        }
      }
    }

    for (var loot in action.lootTable) {
      final roll = _random.nextDouble();
      double finalChance = loot.chance + successBonus + _currentZone.successModifier;
      if (!hasRequiredTool) {
        finalChance = finalChance - 0.30;
        if (finalChance < 0.10) finalChance = 0.10;
      }
      if (roll <= finalChance) {
        int qty = loot.minQuantity;
        if (loot.maxQuantity > loot.minQuantity) {
          qty = loot.minQuantity + _random.nextInt(loot.maxQuantity - loot.minQuantity + 1);
        }
        if (doubleYield) {
          qty *= 2;
        }

        if (_inventory.isFull) {
          inventoryFullError = true;
        } else {
          _inventory = _inventory.addItem(loot.item, qty);
          log("Gathered: ${loot.item.icon} ${loot.item.name} x$qty", LogType.success);
          _lootController.add(LootEvent(loot.item.icon, loot.item.name));
          _notifyQuestObservers(ItemGatheredEvent(loot.item.id, qty));
        }
      }
    }

    if (doubleYield && !inventoryFullError) {
      log("✨ Masterwork Perk: Yield quantities doubled!", LogType.success);
    }

    if (inventoryFullError) {
      log("Your inventory is full! Some items were dropped.", LogType.error);
    }

    // Success logs
    final displayXp = ((action.requiredSkill != null ? action.xpReward : 0.0) * getXpMultiplier()).toInt();
    if (action.id == 'inn_rest') {
      log("You feel rested and energized. Health and energy fully restored.", LogType.success);
    } else if (action.id == 'shelter_rest') {
      log("You rested in the shelter. Health and energy recovered (+${((action.xpReward > 0 ? action.xpReward : 5.0) * getXpMultiplier()).toInt()} Wayfinding XP).", LogType.success);
    } else if (action.id == 'chat_townsfolk') {
      log("You learned some local history (+${((action.xpReward > 0 ? action.xpReward : 12.0) * getXpMultiplier()).toInt()} Lore XP).", LogType.success);
    } else {
      String skillName = action.requiredSkill != null ? action.requiredSkill!.name : 'General';
      log("Success! Finished ${action.name} (+${displayXp} $skillName XP).", LogType.success);
    }

    // Handle progressive exploration zone unlock actions
    if (action.id == 'explore_forest_paths' ||
        action.id == 'explore_rocky_trails' ||
        action.id == 'explore_deep_woods' ||
        action.id == 'explore_lower_shafts') {
      
      final currentProgress = _explorationProgress[action.id] ?? 0.0;
      if (currentProgress < 1.0) {
        double increment = 0.25;
        final wayfindingSkill = _skills[SkillType.wayfinding];
        if (wayfindingSkill != null && wayfindingSkill.levelCap > 20) {
          if (_random.nextDouble() <= 0.15) {
            increment = 0.50;
            log("🗺️ Void Wanderer Perk! Double exploration progress achieved!", LogType.success);
          }
        }
        final newProgress = min(1.0, currentProgress + increment);
        _explorationProgress[action.id] = newProgress;
        
        if (newProgress >= 1.0) {
          _notifyQuestObservers(ScoutCompletedEvent(action.id));
          // Milestone reach: unlock zone and award discovery chest!
          if (action.id == 'explore_forest_paths') {
            unlockZone('whispering_woods_1');
            
            _playerStats = _playerStats.copyWith(gold: _playerStats.gold + 10);
            _inventory = _inventory.addItem(Items.wildBerries, 5);
            _inventory = _inventory.addItem(Items.oakLog, 5);
            _inventory = _inventory.addItem(Items.wildflower, 2);
            log("🎁 DISCOVERY CHEST: You charted a path to the Whispering Woods! Found 10 Gold, 5 Wild Berries, 5 Oak Logs, and 2 Wildflowers!", LogType.success);
            _notifyQuestObservers(ItemGatheredEvent(Items.wildBerries.id, 5));
            _notifyQuestObservers(ItemGatheredEvent(Items.oakLog.id, 5));
            _notifyQuestObservers(ItemGatheredEvent(Items.wildflower.id, 2));
          } else if (action.id == 'explore_rocky_trails') {
            unlockZone('darkstone_mine_1');
            
            _playerStats = _playerStats.copyWith(gold: _playerStats.gold + 10);
            _inventory = _inventory.addItem(Items.copperOre, 5);
            _inventory = _inventory.addItem(Items.tinOre, 3);
            _inventory = _inventory.addItem(Items.wildBerries, 3);
            log("🎁 DISCOVERY CHEST: You charted a path to the Darkstone Mine! Found 10 Gold, 5 Copper Ore, 3 Tin Ore, and 3 Wild Berries!", LogType.success);
            _notifyQuestObservers(ItemGatheredEvent(Items.copperOre.id, 5));
            _notifyQuestObservers(ItemGatheredEvent(Items.tinOre.id, 3));
            _notifyQuestObservers(ItemGatheredEvent(Items.wildBerries.id, 3));
          } else if (action.id == 'explore_deep_woods') {
            unlockZone('whispering_woods_2');
            
            _playerStats = _playerStats.copyWith(gold: _playerStats.gold + 100);
            _inventory = _inventory.addItem(Items.leatherBackpack, 1);
            _inventory = _inventory.addItem(Items.willowLog, 3);
            log("🎁 DISCOVERY CHEST: You successfully charted the Deep Woods Canopy! Found 100 Gold, 1 Leather Backpack, and 3 Willow Logs!", LogType.success);
            _notifyQuestObservers(ItemGatheredEvent(Items.leatherBackpack.id, 1));
            _notifyQuestObservers(ItemGatheredEvent(Items.willowLog.id, 3));
          } else if (action.id == 'explore_lower_shafts') {
            unlockZone('darkstone_mine_2');
            
            _playerStats = _playerStats.copyWith(gold: _playerStats.gold + 100);
            _inventory = _inventory.addItem(Items.backpackUpgrade, 1);
            _inventory = _inventory.addItem(Items.ironOre, 3);
            log("🎁 DISCOVERY CHEST: You successfully charted the Lower Caverns! Found 100 Gold, 1 Backpack Upgrade, and 3 Iron Ore!", LogType.success);
            _notifyQuestObservers(ItemGatheredEvent(Items.backpackUpgrade.id, 1));
            _notifyQuestObservers(ItemGatheredEvent(Items.ironOre.id, 3));
          }
        } else {
          // Progressive step: Roll on Random Exploration Loot Table!
          String pathName = "";
          if (action.id == 'explore_forest_paths') {
            pathName = "Forest Paths";
            
            final roll = _random.nextDouble();
            if (roll < 0.40) {
              final goldAmt = 5 + _random.nextInt(8);
              _playerStats = _playerStats.copyWith(gold: _playerStats.gold + goldAmt);
              log("🔍 Exploration Event: You found a small purse with $goldAmt Gold along the trail!", LogType.success);
            } else if (roll < 0.70) {
              final qty = 1 + _random.nextInt(3);
              _inventory = _inventory.addItem(Items.wildBerries, qty);
              log("🔍 Exploration Event: You gathered $qty Wild Berries from a thicket!", LogType.success);
              _notifyQuestObservers(ItemGatheredEvent(Items.wildBerries.id, qty));
            } else if (roll < 0.85) {
              _inventory = _inventory.addItem(Items.wildflower, 1);
              log("🔍 Exploration Event: You found a pristine Wild wildflower!", LogType.success);
              _notifyQuestObservers(ItemGatheredEvent(Items.wildflower.id, 1));
            }
          } else if (action.id == 'explore_rocky_trails') {
            pathName = "Rocky Trails";
            
            final roll = _random.nextDouble();
            if (roll < 0.45) {
              final goldAmt = 5 + _random.nextInt(8);
              _playerStats = _playerStats.copyWith(gold: _playerStats.gold + goldAmt);
              log("🔍 Exploration Event: You found a small purse with $goldAmt Gold along the trail!", LogType.success);
            } else if (roll < 0.75) {
              final item = _random.nextBool() ? Items.copperOre : Items.tinOre;
              _inventory = _inventory.addItem(item, 1);
              log("🔍 Exploration Event: You chipped loose a chunk of ${item.name} from a boulder!", LogType.success);
              _notifyQuestObservers(ItemGatheredEvent(item.id, 1));
            } else if (roll < 0.90) {
              _inventory = _inventory.addItem(Items.riverClay, 1);
              log("🔍 Exploration Event: You dug up some River Clay from a dry creekbed!", LogType.success);
              _notifyQuestObservers(ItemGatheredEvent(Items.riverClay.id, 1));
            }
          } else if (action.id == 'explore_deep_woods') {
            pathName = "Deep Woods Canopy";
            
            final roll = _random.nextDouble();
            if (roll < 0.40) {
              final goldAmt = 10 + _random.nextInt(16);
              _playerStats = _playerStats.copyWith(gold: _playerStats.gold + goldAmt);
              log("🔍 Exploration Event: You found an old woodland chest with $goldAmt Gold!", LogType.success);
            } else if (roll < 0.70) {
              final qty = 1 + _random.nextInt(3);
              _inventory = _inventory.addItem(Items.willowLog, qty);
              log("🔍 Exploration Event: You gathered $qty Willow Logs from a fallen tree!", LogType.success);
              _notifyQuestObservers(ItemGatheredEvent(Items.willowLog.id, qty));
            } else if (roll < 0.90) {
              _inventory = _inventory.addItem(Items.nightshade, 1);
              log("🔍 Exploration Event: You carefully harvested a batch of rare Nightshade Berries!", LogType.success);
              _notifyQuestObservers(ItemGatheredEvent(Items.nightshade.id, 1));
            }
          } else if (action.id == 'explore_lower_shafts') {
            pathName = "Lower Caverns";
            
            final roll = _random.nextDouble();
            if (roll < 0.40) {
              final goldAmt = 10 + _random.nextInt(16);
              _playerStats = _playerStats.copyWith(gold: _playerStats.gold + goldAmt);
              log("🔍 Exploration Event: You found an abandoned miner pack with $goldAmt Gold!", LogType.success);
            } else if (roll < 0.75) {
              final item = _random.nextBool() ? Items.copperOre : Items.tinOre;
              final qty = 1 + _random.nextInt(2);
              _inventory = _inventory.addItem(item, qty);
              log("🔍 Exploration Event: You chipped loose $qty ${item.name} from an exposed vein!", LogType.success);
              _notifyQuestObservers(ItemGatheredEvent(item.id, qty));
            } else if (roll < 0.95) {
              final qty = 1 + _random.nextInt(2);
              _inventory = _inventory.addItem(Items.rawPotato, qty);
              log("🔍 Exploration Event: You found $qty wild Raw Potatoes in a fertile patch!", LogType.success);
              _notifyQuestObservers(ItemGatheredEvent(Items.rawPotato.id, qty));
            } else {
              _inventory = _inventory.addItem(Items.copperPickaxe, 1);
              log("🔍 Exploration Event: Rare find! You found a rusty Copper Pickaxe left in a mine cart!", LogType.success);
              _notifyQuestObservers(ItemGatheredEvent(Items.copperPickaxe.id, 1));
            }
          }
          
          log("🗺️ Exploration progress for $pathName increased to ${(newProgress * 100).toInt()}%.", LogType.info);
        }
      }
    }

    rollBlueprintScrollDrop(_currentZone.tier);
    _playerAction = null;
    notifyListeners();

    // Auto-repeat zone action if possible
    startAction(action);
  }

  void cancelAction() {
    _playerAction = null;
    _activeCombat = null;
    notifyListeners();
  }

  void cancelStationCraft(String stationKey) {
    final instance = _stationInstances[stationKey];
    if (instance == null || instance.currentCraft == null) return;
    
    final recipe = instance.currentCraft!.recipe;
    if (recipe != null) {
      // Refund ingredients
      for (var entry in recipe.inputs.entries) {
        final item = Items.findById(entry.key);
        if (item != null) {
          _inventory = _inventory.addItem(item, entry.value);
        }
      }
      log("Cancelled crafting ${recipe.name}. Ingredients refunded.", LogType.info);
    }
    instance.currentCraft = null;
    notifyListeners();
  }

  void _completeStationCraft(StationInstance instance) {
    if (instance.currentCraft == null || instance.currentCraft!.recipe == null) return;
    final recipe = instance.currentCraft!.recipe!;

    if (instance.queue.isEmpty) return; // safety check
    final queued = instance.queue.first;
    final slotChoices = queued.slotChoices;
    final modifierItemId = queued.modifierItemId;

    // Award XP
    final oldSkill = _skills[recipe.requiredSkill]!;
    double xpMultiplier = getXpMultiplier();
    if (modifierItemId == 'wildflower') {
      xpMultiplier *= 1.5;
    }
    final xpReward = recipe.xpReward * xpMultiplier;
    final newSkill = oldSkill.addXp(xpReward);
    _skills[recipe.requiredSkill] = newSkill;

    if (newSkill.level > oldSkill.level) {
      log("Level Up! Your ${recipe.requiredSkill.name} is now Level ${newSkill.level}!", LogType.levelUp);
      _levelUpController.add(LevelUpEvent(recipe.requiredSkill, newSkill.level));
    } else if (newSkill.isGated && !oldSkill.isGated) {
      log("Limit Reached! Level ${newSkill.levelCap} Masterwork Trial is now unlocked. Check the Skills tab.", LogType.warning);
    }
    _maybeOfferMasterworkQuest(recipe.requiredSkill);

    // Check refund modifiers / perks
    bool saveMaterials = false;
    if (modifierItemId == 'river_clay') {
      if (_random.nextDouble() <= 0.30) {
        saveMaterials = true;
      }
    }
    if (!saveMaterials && recipe.requiredSkill == SkillType.crafting && oldSkill.levelCap > 20) {
      if (_random.nextDouble() <= 0.15) {
        saveMaterials = true;
        log("🛠️ Artisan's Touch Perk! Saved all ingredients!", LogType.success);
      }
    }

    if (saveMaterials) {
      for (int i = 0; i < recipe.slots.length; i++) {
        final slot = recipe.slots[i];
        final choiceItemId = slotChoices[i] ?? slot.acceptedItems.first.itemId;
        final choiceItem = Items.findById(choiceItemId);
        if (choiceItem != null) {
          _inventory = _inventory.addItem(choiceItem, slot.quantity);
        }
      }
      if (modifierItemId == 'river_clay') {
        log("🧱 River Clay modifier! Saved all ingredients!", LogType.success);
      }
    }

    // Award result item
    final resultItem = recipe.resultItem;
    if (resultItem != null) {
      int finalQty = recipe.resultQuantity;
      if (modifierItemId == 'boar_tusk') {
        finalQty += 1;
      }
      if (recipe.requiredSkill == SkillType.cooking && oldSkill.levelCap > 20) {
        if (_random.nextDouble() <= 0.20) {
          finalQty *= 2;
          log("🍳 Master Culinarian Perk! Output doubled!", LogType.success);
        }
      }

      final skillLevel = oldSkill.level;
      final stationBias = getStationQualityBias(instance.tier);
      
      double substituteBias = 0.0;
      bool hasBelowCanonical = false;
      for (int i = 0; i < recipe.slots.length; i++) {
        final slot = recipe.slots[i];
        final choiceItemId = slotChoices[i] ?? slot.acceptedItems.first.itemId;
        final choiceIdx = slot.acceptedItems.indexWhere((c) => c.itemId == choiceItemId);
        if (choiceIdx >= 0) {
          final choice = slot.acceptedItems[choiceIdx];
          substituteBias += choice.qualityBias;
          if (choice.qualityBias < 0.0) {
            hasBelowCanonical = true;
          }
        }
      }

      final roll = _random.nextDouble();
      double qualityScore = roll + 0.020 * (skillLevel - recipe.requiredLevel) + stationBias + substituteBias;
      if (hasBelowCanonical) {
        qualityScore -= 0.10;
      }

      var quality = rollQuality(qualityScore);
      // Apply modifier floors
      if (modifierItemId == 'wild_berries') {
        if (quality == QualityTier.crude) {
          quality = QualityTier.standard;
        }
      } else if (modifierItemId == 'troll_claw') {
        if (quality == QualityTier.crude || quality == QualityTier.standard) {
          quality = QualityTier.fine;
        }
      }

      var affixes = rollAffixes(quality, resultItem.type);
      if (modifierItemId == 'nightshade' && affixes.isEmpty) {
        affixes = rollAffixesForced(resultItem.type);
      }

      if (_inventory.isFull) {
        log("Your inventory is full! The ${resultItem.name} was dropped.", LogType.error);
      } else {
        _inventory = _inventory.addItem(resultItem, finalQty, quality, affixes);
        
        String affixSuffix = affixes.isNotEmpty ? " [${affixes.map((a) => Affixes.findById(a)?.name ?? a).join(', ')}]" : "";
        String qualLabel = quality == QualityTier.standard ? "" : "${quality.name.toUpperCase()} ";

        log("Crafted: ${resultItem.icon} ${qualLabel}${resultItem.name}$affixSuffix x$finalQty at ${instance.stationId}", LogType.success);
        _lootController.add(LootEvent(resultItem.icon, "${qualLabel}${resultItem.name}$affixSuffix", quality, affixes));
        _notifyQuestObservers(ItemCraftedEvent(recipe.id, quality, finalQty));
      }
    }

    log("Success! Finished crafting ${recipe.name} (+${xpReward.toInt()} ${recipe.requiredSkill.name} XP).", LogType.success);

    // Advance the queue
    queued.count--;
    if (queued.count <= 0) {
      instance.queue.removeAt(0);
      _startNextStationCraft(instance);
    } else {
      double duration = recipe.durationSeconds.toDouble();
      duration = duration / (1.0 + getSkillSpeedBonus(recipe.requiredSkill));
      if (duration < 1.0) duration = 1.0;

      instance.currentCraft = ActiveActionState(
        recipe: recipe,
        progress: 0.0,
        durationSeconds: duration,
      );
    }
    notifyListeners();
  }

  void _tick() {
    if (_isPaused) return;
    _checkMilestones();

    bool stateChanged = false;

    // 1. Tick Player Action
    if (_playerAction != null) {
      final state = _playerAction!;
      if (state.action != null && state.action!.isCombat) {
        double nextProgress = state.progress + (0.1 / state.durationSeconds);
        if (nextProgress >= 1.0) {
          if (_activeCombat != null) {
            _executeCombatRound(state.action!);
            if (_activeCombat!.beastCurrentHealth <= 0) {
              _playerAction = state.copyWith(progress: 1.0);
              _completePlayerAction();
            } else if (_playerStats.currentHealth <= 0) {
              faint();
            } else {
              _playerAction = state.copyWith(progress: 0.0);
            }
          } else {
            _playerAction = state.copyWith(progress: 1.0);
            _completePlayerAction();
          }
        } else {
          _playerAction = state.copyWith(progress: nextProgress);
        }
      } else {
        double nextProgress = state.progress + (0.1 / state.durationSeconds);
        if (nextProgress >= 1.0) {
          _playerAction = state.copyWith(progress: 1.0);
          if (state.station != null) {
            final stationKey = "${state.targetZoneId}::${state.station!.id}";
            final inst = _stationInstances[stationKey];
            if (inst != null) {
              if (state.isRestoration) {
                inst.restoration = _playerAction;
              } else if (state.isUpgrade) {
                inst.tierUpgrade = _playerAction;
              }
            }
          }
          _completePlayerAction();
        } else {
          _playerAction = state.copyWith(progress: nextProgress);
          if (state.station != null) {
            final stationKey = "${state.targetZoneId}::${state.station!.id}";
            final inst = _stationInstances[stationKey];
            if (inst != null) {
              if (state.isRestoration) {
                inst.restoration = _playerAction;
              } else if (state.isUpgrade) {
                inst.tierUpgrade = _playerAction;
              }
            }
          }
        }
      }
      stateChanged = true;
    }

    // 2. Tick Stations
    for (var instance in _stationInstances.values) {
      if (instance.isRuined) continue;

      if (instance.currentCraft != null) {
        final state = instance.currentCraft!;

        if (state.progress == 0.0) {
          final recipe = state.recipe!;
          final actualEnergyCost = getModifiedEnergyCost(recipe.energyCost, recipe.requiredSkill);
          if (_playerStats.currentEnergy < actualEnergyCost) {
            final stationKey = "${instance.zoneId}::${instance.stationId}";
            if (!_idleWarnedStations.contains(stationKey)) {
              log("Station idle: not enough energy to continue crafting ${recipe.name}.", LogType.warning);
              _idleWarnedStations.add(stationKey);
            }
            continue;
          } else {
            // Deduct energy
            int newEnergy = _playerStats.currentEnergy - actualEnergyCost;
            newEnergy = newEnergy.clamp(0, _playerStats.maxEnergy);
            _playerStats = _playerStats.copyWith(currentEnergy: newEnergy);
            final stationKey = "${instance.zoneId}::${instance.stationId}";
            _idleWarnedStations.remove(stationKey);
            stateChanged = true;
          }
        }

        double nextProgress = state.progress + (0.1 / state.durationSeconds);
        if (nextProgress >= 1.0) {
          instance.currentCraft = state.copyWith(progress: 1.0);
          _completeStationCraft(instance);
        } else {
          instance.currentCraft = state.copyWith(progress: nextProgress);
        }
        stateChanged = true;
      }
    }

    if (stateChanged) {
      notifyListeners();
    }
  }

  // Consuming Food
  void eatFood(Item item, [QualityTier? quality, List<String>? affixIds]) {
    if (item.type != ItemType.food) return;
    final affs = affixIds ?? const [];
    if (!_inventory.hasItem(item.id, 1)) return;

    _inventory = _inventory.removeItem(item.id, 1, quality, affs);

    // Apply cooking skill restoration multiplier
    final cookingSkill = _skills[SkillType.cooking];
    double foodMultiplier = 1.0;
    if (cookingSkill != null) {
      foodMultiplier += (cookingSkill.level - 1) * 0.015; // +1.5% per level above 1
      if (cookingSkill.levelCap > 10) {
        foodMultiplier += 0.15; // Lvl 10 Perk (+15%)
      }
      if (cookingSkill.levelCap > 20) {
        foodMultiplier += 0.30; // Lvl 20 Perk (+30%)
      }
    }

    int baseHeal = getItemHealAmount(item, quality, affs);
    int baseEnergy = getItemEnergyAmount(item, quality, affs);

    int healed = (baseHeal * foodMultiplier).round();
    int energyRestored = (baseEnergy * foodMultiplier).round();

    if (affs.contains('plentiful')) {
      healed *= 2;
      energyRestored *= 2;
    }

    int newHealth = min(_playerStats.maxHealth, _playerStats.currentHealth + healed);
    int newEnergy = min(_playerStats.maxEnergy, _playerStats.currentEnergy + energyRestored);

    _playerStats = _playerStats.copyWith(
      currentHealth: newHealth,
      currentEnergy: newEnergy,
    );

    String flourish = affs.contains('plentiful') ? " (Double Bite!)" : "";
    String qualPrefix = quality != null ? "[${quality.name.toUpperCase()}] " : "";
    log("Consumed ${item.icon} $qualPrefix${item.name}$flourish (Restored +$healed HP, +$energyRestored Energy).", LogType.success);
    notifyListeners();
  }

  void useItem(Item item, [QualityTier? quality, List<String>? affixIds]) {
    if (!_inventory.hasItem(item.id, 1)) return;

    if (item.id == 'leather_backpack') {
      _inventory = _inventory.removeItem(item.id, 1);
      _inventory = _inventory.copyWith(capacity: _inventory.capacity + 4);
      log("🎒 You used the Leather Backpack! Your inventory capacity is permanently increased to ${_inventory.capacity} slots.", LogType.success);
      
      int prevSlots = _maxEquipmentSlots;
      _maxEquipmentSlots = (_maxEquipmentSlots + 1).clamp(1, 3);
      if (_maxEquipmentSlots > prevSlots) {
        log("🛡️ Your maximum equipment slots increased to $_maxEquipmentSlots!", LogType.success);
      }
      notifyListeners();
    } else if (item.id == 'backpack_upgrade') {
      _inventory = _inventory.removeItem(item.id, 1);
      _inventory = _inventory.copyWith(capacity: _inventory.capacity + 1);
      log("🎒 You used a Backpack Upgrade! Your inventory capacity is permanently increased to ${_inventory.capacity} slots.", LogType.success);
      
      int prevSlots = _maxEquipmentSlots;
      _maxEquipmentSlots = (_maxEquipmentSlots + 1).clamp(1, 3);
      if (_maxEquipmentSlots > prevSlots) {
        log("🛡️ Your maximum equipment slots increased to $_maxEquipmentSlots!", LogType.success);
      }
      notifyListeners();
    } else if (item.isFood) {
      eatFood(item, quality, affixIds);
    }
  }

  // Merchant operations
  void buyItem(Item item) {
    if (_playerStats.gold < item.value) {
      log("Not enough gold to buy ${item.name}!", LogType.error);
      return;
    }
    if (_inventory.isFull) {
      log("Inventory full! Free some slots first.", LogType.error);
      return;
    }

    _inventory = _inventory.addItem(item, 1);
    _playerStats = _playerStats.copyWith(gold: _playerStats.gold - item.value);
    log("Purchased ${item.icon} ${item.name} for ${item.value} Gold.", LogType.success);
    notifyListeners();
  }

  void buyShopItem(ShopListing listing, int quantity) {
    final cost = listing.effectiveBuyPrice * quantity;
    if (_playerStats.gold < cost) {
      log("Not enough gold to buy ${listing.item.name} x$quantity!", LogType.error);
      _shopController.add(ShopEvent(type: 'error', item: listing.item, quantity: quantity, goldAmount: 0));
      return;
    }

    bool canAdd = true;
    if (listing.item.type == ItemType.tool) {
      final freeSlots = _inventory.capacity - _inventory.slots.length;
      if (freeSlots < quantity) canAdd = false;
    } else {
      final hasSlot = _inventory.slots.any((s) => s.item.id == listing.item.id);
      if (!hasSlot && _inventory.slots.length >= _inventory.capacity) {
        canAdd = false;
      }
    }

    if (!canAdd) {
      log("Inventory full! Free some slots first.", LogType.error);
      _shopController.add(ShopEvent(type: 'error', item: listing.item, quantity: quantity, goldAmount: 0));
      return;
    }

    if (listing.stock != null) {
      if (listing.stock! < quantity) {
        log("Not enough stock of ${listing.item.name}!", LogType.error);
        _shopController.add(ShopEvent(type: 'error', item: listing.item, quantity: quantity, goldAmount: 0));
        return;
      }
    }

    _inventory = _inventory.addItem(listing.item, quantity);
    _playerStats = _playerStats.copyWith(gold: _playerStats.gold - cost);

    if (listing.stock != null) {
      final currentMerchantId = _shopState.currentMerchant.id;
      final currentList = _shopState.merchantListings[currentMerchantId] ?? [];
      final newList = currentList.map((l) {
        if (l.item.id == listing.item.id) {
          return l.copyWith(stock: l.stock! - quantity);
        }
        return l;
      }).toList();

      final newMerchantListings = Map<String, List<ShopListing>>.from(_shopState.merchantListings);
      newMerchantListings[currentMerchantId] = newList;
      _shopState = _shopState.copyWith(merchantListings: newMerchantListings);
    }

    log("Purchased ${listing.item.icon} ${listing.item.name} x$quantity for $cost Gold.", LogType.success);
    _shopController.add(ShopEvent(type: 'purchase', item: listing.item, quantity: quantity, goldAmount: cost));
    notifyListeners();
  }

  void sellItem(Item item, int quantity, [QualityTier? quality, List<String>? affixIds]) {
    final affs = affixIds ?? const [];
    if (_inventory.getItemCountPrecise(item.id, quality, affs) < quantity) {
      log("You don't have $quantity ${item.name} to sell!", LogType.error);
      _shopController.add(ShopEvent(type: 'error', item: item, quantity: quantity, goldAmount: 0));
      return;
    }

    _inventory = _inventory.removeItem(item.id, quantity, quality, affs);
    final computedVal = getItemGoldValue(item, quality, affs);
    final sellPrice = max(1, (computedVal * 0.5).toInt());
    final earnings = sellPrice * quantity;
    _playerStats = _playerStats.copyWith(gold: _playerStats.gold + earnings);

    final currentMerchantId = _shopState.currentMerchant.id;
    final currentList = _shopState.merchantListings[currentMerchantId] ?? [];
    final hasItemInList = currentList.any((l) => l.item.id == item.id);
    if (hasItemInList) {
      final newList = currentList.map((l) {
        if (l.item.id == item.id && l.stock != null) {
          final newStock = min(l.maxStock ?? 99, l.stock! + quantity);
          return l.copyWith(stock: newStock);
        }
        return l;
      }).toList();

      final newMerchantListings = Map<String, List<ShopListing>>.from(_shopState.merchantListings);
      newMerchantListings[currentMerchantId] = newList;
      _shopState = _shopState.copyWith(merchantListings: newMerchantListings);
    }

    String qualLabel = quality != null ? "[${quality.name.toUpperCase()}] " : "";
    log("Sold ${item.icon} $qualLabel${item.name} x$quantity for $earnings Gold.", LogType.success);
    _shopController.add(ShopEvent(type: 'sale', item: item, quantity: quantity, goldAmount: earnings));
    notifyListeners();
  }

  void setActiveMerchantIndex(int index) {
    if (index >= 0 && index < _shopState.activeMerchants.length) {
      _shopState = _shopState.copyWith(activeMerchantIndex: index);
      notifyListeners();
    }
  }

  void checkShopRestock() {
    final now = DateTime.now();
    if (now.difference(_shopState.lastRestockTime) >= const Duration(minutes: 5)) {
      final allMerchants = List<Merchant>.from(Merchant.all);
      allMerchants.shuffle(_random);
      final active = [allMerchants[0], allMerchants[1]];

      _shopState = _shopState.copyWith(
        activeMerchants: active,
        activeMerchantIndex: 0,
      ).withRefreshedDeals(_random);

      log("🏪 The market square merchants have rotated! Check out their new stock.", LogType.info);
      notifyListeners();
    }
  }

  // Masterwork Scenario Methods
  void startMasterworkChallenge(MasterworkTask task) {
    cancelAction();
    _activeMasterwork = MasterworkRunState(
      task: task,
      currentStepId: task.startStepId,
    );
    log("Started Masterwork Challenge: ${task.title}!", LogType.info);
    notifyListeners();
  }

  void chooseMasterworkOption(MasterworkOption option) {
    if (_activeMasterwork == null) return;

    // 1. Check requirements
    if (option.requiredSkill != null) {
      final skill = _skills[option.requiredSkill!];
      if (skill == null || skill.level < option.requiredLevel) {
        log("Choice locked: Requires Level ${option.requiredLevel} ${option.requiredSkill!.name}.", LogType.error);
        return;
      }
    }

    if (option.requiredItemId != null) {
      if (!_inventory.hasItem(option.requiredItemId!, option.requiredItemCount)) {
        final item = Items.findById(option.requiredItemId!);
        final itemName = item != null ? item.name : option.requiredItemId!;
        log("Choice locked: Requires ${option.requiredItemCount}x $itemName.", LogType.error);
        return;
      }
    }

    if (option.energyCost > 0 && _playerStats.currentEnergy < option.energyCost) {
      log("Choice locked: Requires ${option.energyCost} Energy.", LogType.error);
      return;
    }

    if (option.goldCost > 0 && _playerStats.gold < option.goldCost) {
      log("Choice locked: Requires ${option.goldCost} Gold.", LogType.error);
      return;
    }

    // 2. Consume requirements
    int newEnergy = max(0, _playerStats.currentEnergy - option.energyCost);
    int newGold = max(0, _playerStats.gold - option.goldCost);
    _playerStats = _playerStats.copyWith(
      currentEnergy: newEnergy,
      gold: newGold,
    );

    if (option.requiredItemId != null) {
      _inventory = _inventory.removeItem(option.requiredItemId!, option.requiredItemCount);
    }

    // 3. Health adjustment / damage
    if (option.healthCost != 0) {
      int newHealth = (_playerStats.currentHealth - option.healthCost).clamp(0, _playerStats.maxHealth);
      _playerStats = _playerStats.copyWith(currentHealth: newHealth);

      if (_playerStats.isDead) {
        log(option.feedback, LogType.warning);
        faint();
        return;
      }
    }

    // 4. Print narrative feedback to logs
    log(option.feedback, option.isSuccess ? LogType.success : LogType.info);

    // 5. Navigate or end
    if (option.nextStepId != null) {
      _activeMasterwork = _activeMasterwork!.copyWith(currentStepId: option.nextStepId);
    } else {
      // Challenge finished!
      final skillType = _activeMasterwork!.task.skillType;
      final taskTitle = _activeMasterwork!.task.title;
      _activeMasterwork = null;

      if (option.isSuccess) {
        // Unlock cap!
        final oldSkill = _skills[skillType]!;
        final newSkill = oldSkill.unlockCap();
        _skills[skillType] = newSkill;

        log("CONGRATULATIONS! You completed the '$taskTitle' Masterwork Trial!", LogType.levelUp);
        log("Your ${skillType.name} level cap is unlocked up to level ${newSkill.levelCap}!", LogType.levelUp);
        _notifyQuestObservers(MasterworkCompletedEvent(skillType));
      } else {
        log("Trial Failed! You couldn't complete the '$taskTitle' challenge. Try again when prepared.", LogType.error);
      }
    }

    notifyListeners();
  }

  void cancelMasterwork() {
    if (_activeMasterwork == null) return;
    log("Abandoned Masterwork Challenge: ${_activeMasterwork!.task.title}.", LogType.warning);
    _activeMasterwork = null;
    notifyListeners();
  }

  // Collapsing
  void faint() {
    cancelAction();
    cancelMasterwork();

    // 10% Gold Penalty up to 100 gold
    int penalty = (_playerStats.gold * 0.10).toInt();
    if (penalty > 100) penalty = 100;
    int newGold = max(0, _playerStats.gold - penalty);

    // Revive stats
    int revivedHealth = (_playerStats.maxHealth * 0.25).toInt(); // revive at 25% health
    int revivedEnergy = (_playerStats.maxEnergy * 0.50).toInt(); // revive at 50% energy

    _playerStats = _playerStats.copyWith(
      currentHealth: revivedHealth,
      currentEnergy: revivedEnergy,
      gold: newGold,
    );

    _currentZone = Zones.townSquare;

    log("💥 YOU COLLAPSED! A wandering merchant found you unconscious and brought you to the Town Square Inn.", LogType.error);
    if (penalty > 0) {
      log("The merchant charged you $penalty Gold for medical supplies.", LogType.warning);
    }

    notifyListeners();
  }

  double getItemAttackPower(Item item, QualityTier? quality, List<String> affixIds) {
    if (item.type != ItemType.weapon) return 0.0;
    double base = item.attackPower.toDouble();
    if (quality != null) {
      base *= quality.multiplier;
    }
    double percentBonus = 0.0;
    double flatBonus = 0.0;
    for (final affixId in affixIds) {
      final affix = Affixes.findById(affixId);
      if (affix != null) {
        if (affix.effect.type == AffixEffectType.attackPercent) {
          percentBonus += affix.effect.value;
        } else if (affix.effect.type == AffixEffectType.attackFlat) {
          flatBonus += affix.effect.value;
        }
      }
    }
    return base * (1.0 + percentBonus) + flatBonus;
  }

  double getItemDefense(Item item, QualityTier? quality, List<String> affixIds) {
    if (item.type != ItemType.armor) return 0.0;
    double base = item.defense.toDouble();
    if (quality != null) {
      base *= quality.multiplier;
    }
    double percentBonus = 0.0;
    double flatBonus = 0.0;
    for (final affixId in affixIds) {
      final affix = Affixes.findById(affixId);
      if (affix != null) {
        if (affix.effect.type == AffixEffectType.defensePercent) {
          percentBonus += affix.effect.value;
        } else if (affix.effect.type == AffixEffectType.defenseFlat) {
          flatBonus += affix.effect.value;
        }
      }
    }
    return base * (1.0 + percentBonus) + flatBonus;
  }

  double getItemSpeedBonus(Item item, QualityTier? quality, List<String> affixIds) {
    if (item.type != ItemType.tool) return 0.0;
    double base = item.speedBonus;
    if (quality != null) {
      base *= quality.multiplier;
    }
    double bonus = 0.0;
    for (final affixId in affixIds) {
      final affix = Affixes.findById(affixId);
      if (affix != null) {
        if (affix.effect.type == AffixEffectType.speedBonus) {
          bonus += affix.effect.value;
        } else if (affix.effect.type == AffixEffectType.toolStatBoost) {
          bonus += affix.effect.value;
        }
      }
    }
    return base + bonus;
  }

  double getItemSuccessBonus(Item item, QualityTier? quality, List<String> affixIds) {
    if (item.type != ItemType.tool) return 0.0;
    double base = item.successBonus;
    if (quality != null) {
      base *= quality.multiplier;
    }
    double bonus = 0.0;
    for (final affixId in affixIds) {
      final affix = Affixes.findById(affixId);
      if (affix != null) {
        if (affix.effect.type == AffixEffectType.successBonus) {
          bonus += affix.effect.value;
        } else if (affix.effect.type == AffixEffectType.toolStatBoost) {
          bonus += affix.effect.value;
        }
      }
    }
    return base + bonus;
  }

  int getItemHealAmount(Item item, QualityTier? quality, List<String> affixIds) {
    if (item.type != ItemType.food) return 0;
    double base = item.healAmount.toDouble();
    if (quality != null) {
      base *= quality.multiplier;
    }
    double percentBonus = 0.0;
    for (final affixId in affixIds) {
      final affix = Affixes.findById(affixId);
      if (affix != null && affix.effect.type == AffixEffectType.healPercent) {
        percentBonus += affix.effect.value;
      }
    }
    return (base * (1.0 + percentBonus)).round();
  }

  int getItemEnergyAmount(Item item, QualityTier? quality, List<String> affixIds) {
    if (item.type != ItemType.food) return 0;
    double base = item.energyAmount.toDouble();
    if (quality != null) {
      base *= quality.multiplier;
    }
    double percentBonus = 0.0;
    for (final affixId in affixIds) {
      final affix = Affixes.findById(affixId);
      if (affix != null && affix.effect.type == AffixEffectType.energyPercent) {
        percentBonus += affix.effect.value;
      }
    }
    return (base * (1.0 + percentBonus)).round();
  }

  int getItemGoldValue(Item item, QualityTier? quality, List<String> affixIds) {
    double base = item.value.toDouble();
    if (quality != null) {
      base *= quality.multiplier;
    }
    double percentBonus = 0.0;
    for (final affixId in affixIds) {
      final affix = Affixes.findById(affixId);
      if (affix != null && affix.effect.type == AffixEffectType.goldValuePercent) {
        percentBonus += affix.effect.value;
      }
    }
    return (base * (1.0 + percentBonus)).round();
  }

  double getStationQualityBias(int tier) {
    if (tier == 2) return 0.05;
    if (tier == 3) return 0.12;
    return 0.00;
  }

  QualityTier rollQuality(double qualityScore) {
    if (qualityScore < 0.10) return QualityTier.crude;
    if (qualityScore < 0.65) return QualityTier.standard;
    if (qualityScore < 0.90) return QualityTier.fine;
    return QualityTier.masterwork;
  }

  List<String> rollAffixes(QualityTier quality, ItemType itemType) {
    final count = quality.affixCount;
    if (count == 0) return const [];

    final possibleAffixes = Affixes.all.where((a) => a.appliesTo.contains(itemType)).toList();
    if (possibleAffixes.isEmpty) return const [];

    final rolled = <String>[];
    final available = List<Affix>.from(possibleAffixes);
    
    for (int i = 0; i < count; i++) {
      if (available.isEmpty) break;
      final index = _random.nextInt(available.length);
      rolled.add(available[index].id);
      available.removeAt(index);
    }
    
    rolled.sort();
    return rolled;
  }

  List<String> rollAffixesForced(ItemType itemType) {
    final possibleAffixes = Affixes.all.where((a) => a.appliesTo.contains(itemType)).toList();
    if (possibleAffixes.isEmpty) return const [];
    final idx = _random.nextInt(possibleAffixes.length);
    return [possibleAffixes[idx].id];
  }

  void resetGame() {
    cancelAction();
    cancelMasterwork();
    _playerStats = PlayerStats.initial();
    _inventory = Inventory.initial();
    _currentZone = Zones.townSquare;
    _unlockedZoneIds.clear();
    _unlockedZoneIds.add('town_square');
    _initializeRuinedStations();
    _knownRecipeIds.clear();
    _logs.clear();
    _playerAction = null;
    _activeMasterwork = null;
    _equippedToolSlots.clear();
    _maxEquipmentSlots = 1;
    _equippedWeaponSlot = null;
    _equippedArmorSlot = null;
    _activeCombat = null;
    _explorationProgress.clear();
    _explorationProgress['explore_forest_paths'] = 0.0;
    _explorationProgress['explore_rocky_trails'] = 0.0;
    _explorationProgress['explore_deep_woods'] = 0.0;
    _explorationProgress['explore_lower_shafts'] = 0.0;

    // Re-initialize skills
    for (var type in SkillType.values) {
      _skills[type] = SkillState.initial(type);
    }

    // Add initial logs
    log("Welcome to Elaria RPG! Set off, gather resources, and level up.", LogType.info);
    log("Tavern rumor: Complete a Masterwork Trial every 10 levels to break your limits.", LogType.info);
    notifyListeners();
  }

  // --- Quest & Codex Engine Integration ---

  void _notifyQuestObservers(QuestEvent event) {
    for (final quest in _activeQuests) {
      if (quest.status != QuestStatus.active) continue;
      for (final objective in quest.objectives) {
        if (objective.isComplete) continue;
        if (_matches(objective, event)) {
          if (objective.kind == ObjectiveKind.upgrade && event is StationUpgradedEvent) {
            objective.currentCount = event.newTier.clamp(0, objective.targetCount);
          } else {
            objective.currentCount = (objective.currentCount + event.count)
                .clamp(0, objective.targetCount);
          }
          _questController.add(event);
        }
      }
      _maybeCompleteQuest(quest);
    }
    notifyListeners();
  }

  bool _matches(QuestObjective objective, QuestEvent event) {
    switch (objective.kind) {
      case ObjectiveKind.gather:
        return event is ItemGatheredEvent && event.itemId == objective.targetId;
      case ObjectiveKind.kill:
        return event is BeastDefeatedEvent &&
            (objective.targetId == null || objective.targetId == 'any' || event.beastId == objective.targetId);
      case ObjectiveKind.craft:
        return event is ItemCraftedEvent && event.recipeId == objective.targetId;
      case ObjectiveKind.visit:
        return event is ZoneVisitedEvent && event.zoneId == objective.targetId;
      case ObjectiveKind.scout:
        return event is ScoutCompletedEvent && event.actionId == objective.targetId;
      case ObjectiveKind.restore:
        return event is StationRestoredEvent && event.stationId == objective.targetId;
      case ObjectiveKind.upgrade:
        return event is StationUpgradedEvent &&
            event.stationId == objective.targetId &&
            event.newTier >= objective.targetCount;
      case ObjectiveKind.masterwork:
        return event is MasterworkCompletedEvent && event.skill.name == objective.targetId;
      case ObjectiveKind.codexRead:
        return event is CodexFragmentReadEvent;
      case ObjectiveKind.cleanse:
        return false; // Not implemented in Spec 1
      case ObjectiveKind.custom:
        return false;
    }
  }

  void _maybeCompleteQuest(Quest quest) {
    if (quest.isComplete) {
      if (quest.turnInLocation == null) {
        // Auto turn in!
        quest.status = QuestStatus.completed;
        _activeQuests.remove(quest);
        _completedQuests.add(quest);
        log("Completed Quest: ${quest.title}!", LogType.success);
        for (var r in quest.rewards) {
          _grantReward(r);
        }
      } else {
        quest.status = QuestStatus.completed;
      }
    }
  }

  void _grantReward(QuestReward reward) {
    switch (reward.kind) {
      case RewardKind.gold:
        _playerStats = _playerStats.copyWith(gold: _playerStats.gold + reward.amount);
        log("Received: +${reward.amount} Gold", LogType.success);
        break;
      case RewardKind.skillXp:
        if (reward.targetId != null) {
          final skillType = SkillType.values.firstWhere((s) => s.name == reward.targetId);
          final oldSkill = _skills[skillType]!;
          final newSkill = oldSkill.addXp(reward.amount.toDouble() * getXpMultiplier());
          _skills[skillType] = newSkill;
          log("Received: +${reward.amount} ${skillType.name} XP", LogType.success);
          if (newSkill.level > oldSkill.level) {
            log("Level Up! Your ${skillType.name} is now Level ${newSkill.level}!", LogType.levelUp);
            _levelUpController.add(LevelUpEvent(skillType, newSkill.level));
          }
          _maybeOfferMasterworkQuest(skillType);
        }
        break;
      case RewardKind.item:
        if (reward.targetId != null) {
          final item = Items.findById(reward.targetId!);
          if (item != null) {
            if (_inventory.isFull) {
              log("Inventory full! Reward item ${item.name} was dropped.", LogType.error);
            } else {
              _inventory = _inventory.addItem(item, reward.amount);
              log("Received: ${item.icon} ${item.name} x${reward.amount}", LogType.success);
            }
          }
        }
        break;
      case RewardKind.blueprint:
        if (reward.targetId != null) {
          final item = Items.findById(reward.targetId!);
          if (item != null) {
            if (_inventory.isFull) {
              log("Inventory full! Blueprint scroll ${item.name} was dropped.", LogType.error);
            } else {
              _inventory = _inventory.addItem(item, reward.amount);
              log("Received Blueprint: ${item.icon} ${item.name}", LogType.success);
            }
          }
        }
        break;
      case RewardKind.worldEvent:
        if (reward.targetId != null) {
          _engineFlags.add(reward.targetId!);
          _checkMilestones();
        }
        break;
      case RewardKind.unlock:
        if (reward.targetId != null) {
          _engineFlags.add(reward.targetId!);
        }
        break;
    }
  }

  void offerQuest(Quest quest) {
    if (_activeQuests.any((q) => q.id == quest.id) ||
        _completedQuests.any((q) => q.id == quest.id)) {
      return;
    }
    quest.status = QuestStatus.active; // In Spec 1, offered quests start active
    _activeQuests.add(quest);
    log("New Quest: ${quest.title}", LogType.info);
    notifyListeners();
  }

  void acceptQuest(String questId) {
    final idx = _activeQuests.indexWhere((q) => q.id == questId);
    if (idx != -1 && _activeQuests[idx].status == QuestStatus.available) {
      _activeQuests[idx].status = QuestStatus.active;
      log("Accepted Quest: ${_activeQuests[idx].title}", LogType.info);
      notifyListeners();
    }
  }

  void turnInQuest(String questId) {
    final idx = _activeQuests.indexWhere((q) => q.id == questId);
    if (idx == -1) return;
    final quest = _activeQuests[idx];
    if (!quest.isComplete) return;
    if (quest.turnInLocation != null && quest.turnInLocation != _currentZone.id) {
      log("You must be at ${quest.turnInLocation} to turn in this quest.", LogType.error);
      return;
    }
    _activeQuests.removeAt(idx);
    quest.status = QuestStatus.turnedIn;
    _completedQuests.add(quest);
    log("Turned in Quest: ${quest.title}", LogType.success);
    for (var r in quest.rewards) {
      _grantReward(r);
    }
    notifyListeners();
  }

  void abandonQuest(String questId) {
    final idx = _activeQuests.indexWhere((q) => q.id == questId);
    if (idx != -1) {
      final quest = _activeQuests[idx];
      _activeQuests.removeAt(idx);
      log("Abandoned Quest: ${quest.title}", LogType.warning);
      notifyListeners();
    }
  }

  void _checkMilestones() {
    for (final m in Milestones.all) {
      if (_firedMilestoneIds.contains(m.id)) continue;
      if (m.trigger(this)) {
        _firedMilestoneIds.add(m.id);
        m.onFire?.call(this);
        if (m.severity == MilestoneSeverity.major) {
          _isPaused = true;
        }
        _milestoneController.add(m);
        log(m.body, LogType.worldEvent);
      }
    }
  }

  void _bootstrapStarterQuests() {
    offerQuest(Quest(
      id: 'main_restore_town_square',
      type: QuestType.main,
      title: 'Restore Town Square',
      description: 'The cartographer\'s tent stands abandoned, and the local crafts have crumbled. Restore them to draw the town back to life.',
      objectives: [
        QuestObjective(kind: ObjectiveKind.restore, targetId: 'crafting_bench', targetCount: 1),
        QuestObjective(kind: ObjectiveKind.restore, targetId: 'field_kitchen', targetCount: 1),
      ],
      rewards: [
        QuestReward(kind: RewardKind.gold, amount: 50),
        QuestReward(kind: RewardKind.skillXp, targetId: SkillType.wayfinding.name, amount: 100),
        QuestReward(kind: RewardKind.worldEvent, targetId: 'town_square_restored', amount: 1),
        QuestReward(kind: RewardKind.unlock, targetId: 'cartographers_tent', amount: 1),
      ],
      turnInLocation: null,
    ));
  }

  void _maybeOfferMasterworkQuest(SkillType skill) {
    final questId = 'side_masterwork_${skill.name.toLowerCase()}';
    if (_activeQuests.any((q) => q.id == questId)) return;
    if (_completedQuests.any((q) => q.id == questId)) return;

    final state = _skills[skill]!;
    if (state.level < state.levelCap) return;

    final task = MasterworkTasks.findForSkill(skill, state.levelCap);
    if (task == null) return;

    offerQuest(Quest(
      id: questId,
      type: QuestType.side,
      title: 'Skill Trial: ${task.title}',
      description: task.description,
      objectives: [
        QuestObjective(kind: ObjectiveKind.masterwork, targetId: skill.name, targetCount: 1),
      ],
      rewards: [
        QuestReward(kind: RewardKind.skillXp, targetId: skill.name, amount: 50),
        QuestReward(kind: RewardKind.gold, amount: 25),
      ],
      turnInLocation: null,
    ));
  }

  void recordBestiary(String beastId, List<String> droppedItemIds) {
    final existing = _bestiary[beastId];
    if (existing == null) {
      _bestiary[beastId] = BestiaryEntry(
        beastId: beastId,
        firstDefeated: DateTime.now(),
        defeatCount: 1,
        droppedItemIds: droppedItemIds.toSet(),
      );
    } else {
      existing.defeatCount++;
      existing.droppedItemIds.addAll(droppedItemIds);
    }
  }

  void recordRegionDiscovered(String zoneId) {
    if (!_regionStatus.containsKey(zoneId)) {
      _regionStatus[zoneId] = RegionStatusInfo(
        zoneId: zoneId,
        status: RegionStatus.anomalous,
        discoveredAt: DateTime.now(),
      );
    }
  }

  void readCodexFragment(String fragmentId) {
    if (_knownCodexFragmentIds.contains(fragmentId)) return;
    _knownCodexFragmentIds.add(fragmentId);
    log("You read a new Codex Fragment: ${CodexFragments.findById(fragmentId)?.title ?? fragmentId}", LogType.info);
    _notifyQuestObservers(CodexFragmentReadEvent(fragmentId));
    notifyListeners();
  }

  void resumeGame() {
    if (_isPaused) {
      _isPaused = false;
      log("Game resumed.", LogType.info);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _globalTimer?.cancel();
    for (var t in _notificationTimers) {
      t.cancel();
    }
    _notificationTimers.clear();
    _lootController.close();
    _levelUpController.close();
    _shopController.close();
    _questController.close();
    _milestoneController.close();
    super.dispose();
  }
}

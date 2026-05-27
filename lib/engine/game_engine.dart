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
import '../models/main_quests.dart';
import '../models/weather.dart';
import '../models/combat.dart';
import '../models/random_event.dart';
import '../models/reagent_spawn.dart';
import '../models/daily_task.dart';
import '../models/title.dart';
import '../models/player_progression.dart';
import 'achievement_engine.dart';
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
  final Map<String, int>? consumedItems;

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
    this.consumedItems,
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
    Map<String, int>? consumedItems,
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
      consumedItems: consumedItems ?? this.consumedItems,
    );
  }
}

class CombatState {
  final Beast beast;
  final int beastCurrentHealth;
  final int playerStartHealth;
  final List<String> combatLog;
  final List<CombatRound> roundHistory;
  final int roundsSinceLastTelegraph;
  final BeastTelegraph? activeTelegraph;
  final PlayerStance? pendingStance;
  final DateTime? roundDeadline;
  final int? pendingQuickslotIndex;
  final int currentRoundNumber;
  final int activePhaseIndex;
  final BeastAbility? activePhaseAbility;
  final BeastPassive? activePhasePassive;
  final int sourceQuakeCounter;
  final int sourceSedimentStacks;
  final int sourcePollenCounter;

  const CombatState({
    required this.beast,
    required this.beastCurrentHealth,
    required this.playerStartHealth,
    required this.combatLog,
    this.roundHistory = const [],
    this.roundsSinceLastTelegraph = 0,
    this.activeTelegraph,
    this.pendingStance,
    this.roundDeadline,
    this.pendingQuickslotIndex,
    this.currentRoundNumber = 1,
    this.activePhaseIndex = -1,
    this.activePhaseAbility,
    this.activePhasePassive,
    this.sourceQuakeCounter = 0,
    this.sourceSedimentStacks = 0,
    this.sourcePollenCounter = 0,
  });

  CombatState copyWith({
    Beast? beast,
    int? beastCurrentHealth,
    int? playerStartHealth,
    List<String>? combatLog,
    List<CombatRound>? roundHistory,
    int? roundsSinceLastTelegraph,
    BeastTelegraph? activeTelegraph,
    bool clearActiveTelegraph = false,
    PlayerStance? pendingStance,
    bool clearPendingStance = false,
    DateTime? roundDeadline,
    int? pendingQuickslotIndex,
    bool clearPendingQuickslotIndex = false,
    int? currentRoundNumber,
    int? activePhaseIndex,
    BeastAbility? activePhaseAbility,
    BeastPassive? activePhasePassive,
    bool clearActivePhaseAbility = false,
    bool clearActivePhasePassive = false,
    int? sourceQuakeCounter,
    int? sourceSedimentStacks,
    int? sourcePollenCounter,
  }) {
    return CombatState(
      beast: beast ?? this.beast,
      beastCurrentHealth: beastCurrentHealth ?? this.beastCurrentHealth,
      playerStartHealth: playerStartHealth ?? this.playerStartHealth,
      combatLog: combatLog ?? this.combatLog,
      roundHistory: roundHistory ?? this.roundHistory,
      roundsSinceLastTelegraph: roundsSinceLastTelegraph ?? this.roundsSinceLastTelegraph,
      activeTelegraph: clearActiveTelegraph ? null : (activeTelegraph ?? this.activeTelegraph),
      pendingStance: clearPendingStance ? null : (pendingStance ?? this.pendingStance),
      roundDeadline: roundDeadline ?? this.roundDeadline,
      pendingQuickslotIndex: clearPendingQuickslotIndex ? null : (pendingQuickslotIndex ?? this.pendingQuickslotIndex),
      currentRoundNumber: currentRoundNumber ?? this.currentRoundNumber,
      activePhaseIndex: activePhaseIndex ?? this.activePhaseIndex,
      activePhaseAbility: clearActivePhaseAbility ? null : (activePhaseAbility ?? this.activePhaseAbility),
      activePhasePassive: clearActivePhasePassive ? null : (activePhasePassive ?? this.activePhasePassive),
      sourceQuakeCounter: sourceQuakeCounter ?? this.sourceQuakeCounter,
      sourceSedimentStacks: sourceSedimentStacks ?? this.sourceSedimentStacks,
      sourcePollenCounter: sourcePollenCounter ?? this.sourcePollenCounter,
    );
  }
}

class QueuedCraft {
  final String recipeId;
  int count; // remaining iterations
  final Map<int, String> slotChoices; // slotIndex -> chosen item id
  final String? modifierItemId;
  final Map<String, int> consumedItems;

  QueuedCraft({
    required this.recipeId,
    required this.count,
    required this.slotChoices,
    this.modifierItemId,
    required this.consumedItems,
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
  final List<ReagentSpawn> _reagentSpawns = [];
  final Set<String> _knownCodexFragmentIds = {};
  final Map<String, BestiaryEntry> _bestiary = {};
  final Map<String, RegionStatusInfo> _regionStatus = {};
  final Set<String> _earnedAchievementIds = {};
  final Set<String> _firedMilestoneIds = {};
  final Set<String> _engineFlags = {};
  String? _activeTitleId;
  bool _isPaused = false;

  final Set<String> _readCodexFragmentIds = {};
  final Set<CodexTag> _solvedTagPuzzles = {};
  final Map<CodexTag, int> _puzzleAttempts = {};
  final StreamController<PuzzleResult> _puzzleResultController = StreamController<PuzzleResult>.broadcast();

  final Map<String, int> _glyphUses = {};
  int _pastryBuffActionsRemaining = 0;
  String? _pastryBuffStat;
  DateTime? _lastGardenTime;
  DateTime? _lastGroveTime;

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

  CoastWeatherState _coastWeather = CoastWeatherState(
    current: CoastWeather.calm,
    nextRollAt: DateTime.now(),
  );

  CoastWeather get coastWeather => _coastWeather.current;
  DateTime get nextWeatherRollAt => _coastWeather.nextRollAt;

  int _maxEquipmentSlots = 1;
  final Map<SkillType, InventorySlot> _equippedToolSlots = {};
  InventorySlot? _equippedWeaponSlot;
  InventorySlot? _equippedArmorSlot;
  CombatState? _activeCombat;
  final List<String?> _quickslots = [null, null, null];
  final Map<SkillType, String> _skillSpecs = {};
  final Map<SkillType, String> _skillSubSpecs = {};
  final Map<String, MerchantReputation> _merchantRep = {};
  final Set<String> _claimedGifts = {};
  List<DailyTask> _todaysTasks = [];
  bool _dailyBonusClaimed = false;
  bool _tavernRequested = false;
  int _lifetimeGold = 10; // start with initial gold
  bool _anyRepairThisRun = false;
  final Set<String> _firstEnteredZones = {'town_square'};
  int _totalCrafts = 0;
  int _masterworkCrafts = 0;
  int _brewCrafts = 0;
  ActiveRandomEventState? _activeRandomEvent;
  final StreamController<RandomEvent> _randomEventStream = StreamController<RandomEvent>.broadcast();

  ActiveRandomEventState? get activeRandomEvent => _activeRandomEvent;
  Stream<RandomEvent> get randomEvents => _randomEventStream.stream;

  List<String?> get quickslots => List.unmodifiable(_quickslots);
  Map<SkillType, String> get skillSpecs => Map.unmodifiable(_skillSpecs);
  Map<SkillType, String> get skillSubSpecs => Map.unmodifiable(_skillSubSpecs);

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

  bool _pendingYouWinModal = false;
  final Set<String> _endgameAmbientFired = {};

  bool get shouldShowYouWinModal => _pendingYouWinModal;
  void dismissYouWinModal() {
    _pendingYouWinModal = false;
    notifyListeners();
  }

  void _maybeFireEndgameAmbient(String tag, String line) {
    if (!_engineFlags.contains('source_cleanser')) return;
    if (_endgameAmbientFired.contains(tag)) return;
    _endgameAmbientFired.add(tag);
    log(line, LogType.info);
  }

  final Random _random;

  GameEngine({int? seed}) : _random = Random(seed) {
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
  InventorySlot? get equippedWeaponSlot {
    if (_equippedWeaponSlot == null) return null;
    final stamped = ensureDurabilityStamped(_equippedWeaponSlot!);
    if (stamped != _equippedWeaponSlot) {
      _equippedWeaponSlot = stamped;
    }
    return _equippedWeaponSlot;
  }
  InventorySlot? get equippedArmorSlot {
    if (_equippedArmorSlot == null) return null;
    final stamped = ensureDurabilityStamped(_equippedArmorSlot!);
    if (stamped != _equippedArmorSlot) {
      _equippedArmorSlot = stamped;
    }
    return _equippedArmorSlot;
  }
  CombatState? get activeCombat => _activeCombat;

  int getPlayerAttack() {
    int base = 5;
    if (_equippedWeaponSlot != null && !isSlotWorn(_equippedWeaponSlot)) {
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
    if (_equippedArmorSlot != null && !isSlotWorn(_equippedArmorSlot)) {
      base += getItemDefense(_equippedArmorSlot!.item, _equippedArmorSlot!.quality, _equippedArmorSlot!.affixIds).round();
    }
    // Combat Perk 10 (Slayer's Might): +1 Defense
    final combatSkill = _skills[SkillType.combat];
    if (combatSkill != null && combatSkill.levelCap > 10) {
      base += 1;
    }
    // Guardian Spec: +1 Defense
    if (_skillSpecs[SkillType.combat] == 'combat_guardian') {
      base += 1;
    }
    // Bastion Subspec: +3 Defense
    if (_skillSubSpecs[SkillType.combat] == 'combat_bastion') {
      base += 3;
    }
    // Pastrycook defense buff: +2 Defense
    if (_pastryBuffActionsRemaining > 0 && _pastryBuffStat == 'defense') {
      base += 2;
    }
    return base;
  }

  void equipWeapon(Item item, [QualityTier? quality, List<String>? affixIds]) {
    if (item.type != ItemType.weapon) return;
    if (!_inventory.hasItem(item.id, 1)) return;

    InventoryKey? targetKey;
    final sortedAffs = affixIds != null ? (List<String>.from(affixIds)..sort()) : null;
    for (var key in _inventory.items.keys) {
      if (key.itemId == item.id) {
        if (quality != null && key.quality != quality) continue;
        if (sortedAffs != null && !listEquals(key.affixIds, sortedAffs)) continue;
        targetKey = key;
        break;
      }
    }

    if (targetKey == null) {
      log("Could not find matching ${item.name} in inventory.", LogType.error);
      return;
    }

    // Remove from inventory using the specific quality/affixes we found
    _inventory = _inventory.removeItem(item.id, 1, targetKey.quality, targetKey.affixIds);

    // Unequip current weapon if any
    if (_equippedWeaponSlot != null) {
      if (_inventory.isFull) {
        log("Inventory is full! Cannot unequip current weapon.", LogType.error);
        _inventory = _inventory.addItem(item, 1, targetKey.quality, targetKey.affixIds, targetKey.currentDurability, targetKey.maxDurability);
        return;
      }
      _inventory = _inventory.addItem(_equippedWeaponSlot!.item, 1, _equippedWeaponSlot!.quality, _equippedWeaponSlot!.affixIds, _equippedWeaponSlot!.currentDurability, _equippedWeaponSlot!.maxDurability);
    }

    int curDur = targetKey.currentDurability;
    int maxDur = targetKey.maxDurability;
    if (maxDur == 0 && item.value > 0) {
      maxDur = calculateMaxDurability(item, targetKey.quality, targetKey.affixIds);
      curDur = maxDur;
    }

    _equippedWeaponSlot = InventorySlot(
      item: item,
      quantity: 1,
      quality: targetKey.quality,
      affixIds: targetKey.affixIds,
      currentDurability: curDur,
      maxDurability: maxDur,
    );
    log("Equipped ⚔️ ${item.name} (Attack +${getItemAttackPower(item, targetKey.quality, targetKey.affixIds).toInt()}).", LogType.success);
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
    _inventory = _inventory.addItem(slot.item, 1, slot.quality, slot.affixIds, slot.currentDurability, slot.maxDurability);
    log("Unequipped ⚔️ ${slot.item.name}.", LogType.info);
    notifyListeners();
  }

  void equipArmor(Item item, [QualityTier? quality, List<String>? affixIds]) {
    if (item.type != ItemType.armor) return;
    if (!_inventory.hasItem(item.id, 1)) return;

    InventoryKey? targetKey;
    final sortedAffs = affixIds != null ? (List<String>.from(affixIds)..sort()) : null;
    for (var key in _inventory.items.keys) {
      if (key.itemId == item.id) {
        if (quality != null && key.quality != quality) continue;
        if (sortedAffs != null && !listEquals(key.affixIds, sortedAffs)) continue;
        targetKey = key;
        break;
      }
    }

    if (targetKey == null) {
      log("Could not find matching ${item.name} in inventory.", LogType.error);
      return;
    }

    // Remove from inventory
    _inventory = _inventory.removeItem(item.id, 1, targetKey.quality, targetKey.affixIds);

    // Unequip current armor if any
    if (_equippedArmorSlot != null) {
      if (_inventory.isFull) {
        log("Inventory is full! Cannot unequip current armor.", LogType.error);
        _inventory = _inventory.addItem(item, 1, targetKey.quality, targetKey.affixIds, targetKey.currentDurability, targetKey.maxDurability);
        return;
      }
      _inventory = _inventory.addItem(_equippedArmorSlot!.item, 1, _equippedArmorSlot!.quality, _equippedArmorSlot!.affixIds, _equippedArmorSlot!.currentDurability, _equippedArmorSlot!.maxDurability);
    }

    int curDur = targetKey.currentDurability;
    int maxDur = targetKey.maxDurability;
    if (maxDur == 0 && item.value > 0) {
      maxDur = calculateMaxDurability(item, targetKey.quality, targetKey.affixIds);
      curDur = maxDur;
    }

    _equippedArmorSlot = InventorySlot(
      item: item,
      quantity: 1,
      quality: targetKey.quality,
      affixIds: targetKey.affixIds,
      currentDurability: curDur,
      maxDurability: maxDur,
    );
    log("Equipped 🛡️ ${item.name} (Defense +${getItemDefense(item, targetKey.quality, targetKey.affixIds).toInt()}).", LogType.success);
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
    _inventory = _inventory.addItem(slot.item, 1, slot.quality, slot.affixIds, slot.currentDurability, slot.maxDurability);
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
  Map<SkillType, InventorySlot> get equippedToolSlots {
    _equippedToolSlots.forEach((skill, slot) {
      final stamped = ensureDurabilityStamped(slot);
      if (stamped != slot) {
        _equippedToolSlots[skill] = stamped;
      }
    });
    return _equippedToolSlots;
  }

  void equipTool(Item item, [QualityTier? quality, List<String>? affixIds]) {
    if (!item.isTool || item.toolSkill == null) {
      log("This item cannot be equipped as a tool!", LogType.error);
      return;
    }

    final skill = item.toolSkill!;

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

    InventoryKey? targetKey;
    final sortedAffs = affixIds != null ? (List<String>.from(affixIds)..sort()) : null;
    for (var key in _inventory.items.keys) {
      if (key.itemId == item.id) {
        if (quality != null && key.quality != quality) continue;
        if (sortedAffs != null && !listEquals(key.affixIds, sortedAffs)) continue;
        targetKey = key;
        break;
      }
    }

    if (targetKey == null) {
      log("Could not find matching ${item.name} in inventory.", LogType.error);
      return;
    }

    cancelAction();

    // Remove tool from inventory
    _inventory = _inventory.removeItem(item.id, 1, targetKey.quality, targetKey.affixIds);

    // Save previous tool if any
    final oldToolSlot = _equippedToolSlots[skill];

    int curDur = targetKey.currentDurability;
    int maxDur = targetKey.maxDurability;
    if (maxDur == 0 && item.value > 0) {
      maxDur = calculateMaxDurability(item, targetKey.quality, targetKey.affixIds);
      curDur = maxDur;
    }

    // Equip new tool
    _equippedToolSlots[skill] = InventorySlot(
      item: item,
      quantity: 1,
      quality: targetKey.quality,
      affixIds: targetKey.affixIds,
      currentDurability: curDur,
      maxDurability: maxDur,
    );
    log("Equipped ${item.icon} ${item.name} for ${skill.name}.", LogType.success);

    // Return previous tool to inventory
    if (oldToolSlot != null) {
      _inventory = _inventory.addItem(oldToolSlot.item, 1, oldToolSlot.quality, oldToolSlot.affixIds, oldToolSlot.currentDurability, oldToolSlot.maxDurability);
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
    _inventory = _inventory.addItem(toolSlot.item, 1, toolSlot.quality, toolSlot.affixIds, toolSlot.currentDurability, toolSlot.maxDurability);
    log("Unequipped ${toolSlot.item.icon} ${toolSlot.item.name} for ${skill.name}.", LogType.success);

    notifyListeners();
  }

  Zone get currentZone => _currentZone;
  Set<String> get unlockedZoneIds {
    final copy = Set<String>.from(_unlockedZoneIds);
    if (_engineFlags.contains('nexus_unlockable') &&
        _inventory.hasItem('wilds_cleansing_token', 1) &&
        _inventory.hasItem('stone_cleansing_token', 1) &&
        _inventory.hasItem('tide_cleansing_token', 1)) {
      copy.add('nexus_of_echoes');
    }
    return copy;
  }

  bool isZoneUnlocked(Zone zone) => unlockedZoneIds.contains(zone.id);

  Map<String, double> get explorationProgress => _explorationProgress;
  List<LogEntry> get logs => List.unmodifiable(_logs);
  ActiveActionState? get activeAction => _playerAction;
  MasterworkRunState? get activeMasterwork => _activeMasterwork;

  List<Quest> get activeQuests => List.unmodifiable(_activeQuests);
  List<Quest> get completedQuests => List.unmodifiable(_completedQuests);
  List<ReagentSpawn> get reagentSpawns => List.unmodifiable(_reagentSpawns);
  Set<String> get knownCodexFragmentIds => Set.unmodifiable(_knownCodexFragmentIds);
  Map<String, BestiaryEntry> get bestiary => Map.unmodifiable(_bestiary);
  Map<String, RegionStatusInfo> get regionStatus => Map.unmodifiable(_regionStatus);
  Set<String> get earnedAchievementIds => Set.unmodifiable(_earnedAchievementIds);
  Set<String> get firedMilestoneIds => Set.unmodifiable(_firedMilestoneIds);
  Set<String> get engineFlags => Set.unmodifiable(_engineFlags);
  String? get activeTitleId => _activeTitleId;
  List<DailyTask> get todaysTasks => _todaysTasks;
  bool get dailyBonusClaimed => _dailyBonusClaimed;
  Map<String, MerchantReputation> get merchantRep => Map.unmodifiable(_merchantRep);
  bool get tavernRequested => _tavernRequested;
  set tavernRequested(bool val) {
    _tavernRequested = val;
    notifyListeners();
  }
  int get lifetimeGold => _lifetimeGold;
  bool get anyRepairThisRun => _anyRepairThisRun;
  int get totalCrafts => _totalCrafts;
  int get masterworkCrafts => _masterworkCrafts;
  int get brewCrafts => _brewCrafts;
  int get knownRecipesCount => _knownRecipeIds.length;

  bool get isPaused => _isPaused;

  Set<String> get readCodexFragmentIds => Set.unmodifiable(_readCodexFragmentIds);
  Set<CodexTag> get solvedTagPuzzles => Set.unmodifiable(_solvedTagPuzzles);
  Stream<PuzzleResult> get puzzleResults => _puzzleResultController.stream;
  Map<CodexTag, int> get puzzleAttempts => Map.unmodifiable(_puzzleAttempts);

  void setEngineFlag(String flag) {
    if (!_engineFlags.contains(flag)) {
      _engineFlags.add(flag);
      _checkMilestones();
      notifyListeners();
    }
  }

  bool isActionVisible(ZoneAction action) {
    if (action.id == 'walk_eastern_coastal_path') {
      return _engineFlags.contains('breaches_concept_known');
    }
    if (action.id == 'wharfmaster_travel') {
      return _engineFlags.contains('wharfmaster_pier_visible');
    }
    if (action.id == 'hunt_echo_of_tide') {
      return _engineFlags.contains('drowned_lighthouse_spoken');
    }
    if (action.id == 'burn_wilds_echo_essence') {
      return _inventory.hasItem('wilds_echo_essence', 1) && !_engineFlags.contains('breach_wilds_cleansed');
    }
    if (action.id == 'burn_stone_echo_essence') {
      return _inventory.hasItem('stone_echo_essence', 1) && !_engineFlags.contains('breach_stone_cleansed');
    }
    if (action.id == 'burn_tide_echo_essence') {
      return _inventory.hasItem('tide_echo_essence', 1) && !_engineFlags.contains('breach_tide_cleansed');
    }
    return true;
  }


  void advanceQuestObjective(String targetId, {int amount = 1}) {
    _notifyQuestObservers(CustomQuestEvent(targetId, amount));
  }


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
    if (!unlockedZoneIds.contains(zone.id)) {
      log("You cannot travel to ${zone.name} yet! It is locked.", LogType.error);
      return;
    }

    _maybeRollCoastWeather();
    final isCoastZone = zone.id == 'sundered_coast_1' || zone.id == 'sundered_coast_2' || zone.id == 'sundered_coast_3';
    if (isCoastZone && _coastWeather.current == CoastWeather.stormSwell) {
      log("The Wharfmaster shakes his head. 'No travel today. The seas have swallowed the pier.'", LogType.error);
      return;
    }

    
    // Stop current action
    cancelAction();
    cancelMasterwork();

    _currentZone = zone;
    _generateSessionSpawns(); // Ensure spawns are generated on travel
    log("Traveled to ${zone.name}.", LogType.info);

    if (zone.id == 'nexus_of_echoes') {
      // Advance visit objective for Source Convergence
      for (final quest in List<Quest>.from(_activeQuests)) {
        if (quest.id == 'main_source_convergence') {
          for (final obj in quest.objectives) {
            if (obj.kind == ObjectiveKind.visit && obj.targetId == 'nexus_of_echoes') {
              obj.currentCount = obj.targetCount;
              obj.comingSoon = false;
            }
          }
          _maybeCompleteQuest(quest);
        }
      }
    }

    _notifyQuestObservers(ZoneVisitedEvent(zone.id));
    recordRegionDiscovered(zone.id);

    if (zone.id == 'town_square') {
      checkShopRestock();
      _maybeFireEndgameAmbient('travel_town_square', "The cartographer raises his cup as you pass. 'You did this,' he says. He does not name what 'this' is.");
    }

    _checkMilestones();
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
    if (toolSlot != null && !isSlotWorn(toolSlot)) {
      bonus += getItemSpeedBonus(toolSlot.item, toolSlot.quality, toolSlot.affixIds);
    }

    if (_pastryBuffActionsRemaining > 0 && _pastryBuffStat == 'speed') {
      bonus += 0.10;
    }

    return bonus;
  }

  /// Get total success chance bonus (combines level-based and equipped tool success bonuses)
  double getSkillSuccessBonus(SkillType type) {
    final skill = _skills[type];
    if (skill == null) return 0.0;

    double bonus = (skill.level - 1) * 0.01; // +1% per level above 1
    
    final toolSlot = _equippedToolSlots[type];
    if (toolSlot != null && !isSlotWorn(toolSlot)) {
      bonus += getItemSuccessBonus(toolSlot.item, toolSlot.quality, toolSlot.affixIds);
    }

    if (_pastryBuffActionsRemaining > 0 && _pastryBuffStat == 'success') {
      bonus += 0.05;
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
    if (action.id == 'visit_tavern') {
      _tavernRequested = true;
      _generateTodaysTasks();
      _notifyQuestObservers(ZoneVisitedEvent('tavern'));
      notifyListeners();
      return;
    }

    // Cooldown check for Wildflower Garden
    if (action.id == 'wildflower_garden') {
      if (_lastGardenTime != null) {
        final elapsed = DateTime.now().difference(_lastGardenTime!);
        final cooldown = const Duration(minutes: 10);
        if (elapsed < cooldown) {
          final remaining = cooldown - elapsed;
          log("Your garden is recovering. Please wait ${remaining.inMinutes}m ${remaining.inSeconds % 60}s.", LogType.warning);
          return;
        }
      }
    }

    // Cooldown check for Examine Grove
    if (action.id == 'examine_grove') {
      if (_lastGroveTime != null) {
        final elapsed = DateTime.now().difference(_lastGroveTime!);
        final cooldown = Duration(minutes: _skillSubSpecs[SkillType.woodcutting] == 'woodcutting_sapling_mender' ? 5 : 10);
        if (elapsed < cooldown) {
          final remaining = cooldown - elapsed;
          log("The grove is recovering. Please wait ${remaining.inMinutes}m ${remaining.inSeconds % 60}s.", LogType.warning);
          return;
        }
      }
    }

    // Weather restrictions
    if (action.id == 'dive_pearl_shell' || action.id == 'dredge_pearl_bed') {
      _maybeRollCoastWeather();
      if (_coastWeather.current != CoastWeather.calm) {
        log("The pools churn. Wait for the seas to settle.", LogType.error);
        return;
      }
    }

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
      final initialLog = ["Tracked down ${beast.icon} ${beast.name}!"];
      if (beast.phases != null && beast.phases!.isNotEmpty) {
        initialLog.add("⚠️ [Phase Transition] ${beast.phases!.first.entryNarration}");
      }
      _activeCombat = CombatState(
        beast: beast,
        beastCurrentHealth: beast.maxHealth,
        playerStartHealth: _playerStats.currentHealth,
        combatLog: initialLog,
        roundHistory: const [],
        roundsSinceLastTelegraph: 0,
        activeTelegraph: null,
        pendingStance: null,
        roundDeadline: DateTime.now().add(Duration(milliseconds: combatRoundDurationMs)),
        pendingQuickslotIndex: null,
        currentRoundNumber: 1,
        activePhaseIndex: beast.phases != null && beast.phases!.isNotEmpty ? 0 : -1,
        activePhaseAbility: beast.phases != null && beast.phases!.isNotEmpty ? beast.phases!.first.ability : beast.ability,
        activePhasePassive: beast.phases != null && beast.phases!.isNotEmpty ? beast.phases!.first.passive : BeastPassive.none,
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

      // Sub-specialization speed multipliers
      if (action.requiredSkill == SkillType.woodcutting) {
        if (_skillSubSpecs[SkillType.woodcutting] == 'woodcutting_clearcutter') {
          duration *= 1.4;
        } else if (_skillSubSpecs[SkillType.woodcutting] == 'woodcutting_speedchopper') {
          duration *= 0.6;
        }
      }
      if (action.requiredSkill == SkillType.herbalism) {
        if (_skillSubSpecs[SkillType.herbalism] == 'herbalism_bloomseer') {
          duration *= 0.75;
        }
      }

      // Wayfinding Path-Mapper: instant scout in already-scouted zones
      if (_skillSubSpecs[SkillType.wayfinding] == 'wayfinding_path_mapper') {
        if (action.id == 'scout_cliff_path' && _unlockedZoneIds.contains('sundered_coast_2')) {
          duration = 0.05;
        } else if (action.id == 'scout_lighthouse_path' && _unlockedZoneIds.contains('sundered_coast_3')) {
          duration = 0.05;
        }
      }
    }
    if (duration < 1.0 && duration != 0.05) duration = 1.0;

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
    if (!hasInputsForRecipe(recipe, slotChoices, modifierItemId: modifierItemId, count: count)) {
      log("Not enough ingredients!", LogType.error);
      return;
    }

    final consumed = consumeInputsForRecipe(recipe, slotChoices, modifierItemId: modifierItemId, count: count);

    // Add to queue
    final entry = QueuedCraft(
      recipeId: recipeId,
      count: count,
      slotChoices: slotChoices,
      modifierItemId: modifierItemId,
      consumedItems: consumed,
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

    // Refund to inventory
    for (var refundEntry in entry.consumedItems.entries) {
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
      consumedItems: queued.consumedItems,
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
      final xpReward = action.xpReward * getXpMultiplier();
      final oldSkill = _skills[SkillType.combat]!;
      _grantSkillXp(SkillType.combat, xpReward);
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
        if (_equippedWeaponSlot == null) {
          _engineFlags.add('ach_barehanded_kill');
        }
        _notifyQuestObservers(BeastDefeatedEvent(beast.id));
        _updateDailyTaskProgress(BeastDefeatedEvent(beast.id));
        final regionTag = _regionTagForBeast(beast.id);
        if (regionTag != null) {
          tryDropFragment(regionTag, 0.08);
        }
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
      final xpReward = structure.xpReward * getXpMultiplier();
      _grantSkillXp(structure.requiredSkill, xpReward);
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
    bool isWildWalkerHerbalism = action.requiredSkill == SkillType.herbalism && _skillSpecs[SkillType.herbalism] == 'herbalism_wild_walker';
    if (action.healthCost > 0 && action.hazardChance > 0 && !isWildWalkerHerbalism) {
      double hazardChance = action.hazardChance;
      if (action.requiredSkill == SkillType.mining && _skillSubSpecs[SkillType.mining] == 'mining_tunnel_caller') {
        hazardChance *= 0.50;
      }
      final roll = _random.nextDouble();
      if (roll <= hazardChance) {
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
      final xpReward = action.xpReward * getXpMultiplier();
      _grantSkillXp(action.requiredSkill!, xpReward);
      _maybeOfferMasterworkQuest(action.requiredSkill!);
      
      if (action.requiredSkill == SkillType.woodcutting ||
          action.requiredSkill == SkillType.mining ||
          action.requiredSkill == SkillType.herbalism) {
        if (!_engineFlags.contains('ach_first_gather')) {
          _engineFlags.add('ach_first_gather');
          _checkAndUnlockAchievements();
        }
      }
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

    // Handle Custom Specialization Actions: Wildflower Garden & Examine Grove
    if (action.id == 'wildflower_garden') {
      _lastGardenTime = DateTime.now();
      final qty = 1 + _random.nextInt(2);
      if (!_inventory.isFull) {
        _inventory = _inventory.addItem(Items.wildflower, qty);
        log("Gathered: 🌸 Wildflowers x$qty", LogType.success);
        _lootController.add(LootEvent(Items.wildflower.icon, Items.wildflower.name));
        _notifyQuestObservers(ItemGatheredEvent(Items.wildflower.id, qty));
      }
      
      if (_skillSubSpecs[SkillType.herbalism] == 'herbalism_botanist') {
        if (!_inventory.isFull) {
          _inventory = _inventory.addItem(Items.wildBerries, 1);
          log("Gathered: 🍓 Wild Berries x1", LogType.success);
          _lootController.add(LootEvent(Items.wildBerries.icon, Items.wildBerries.name));
          _notifyQuestObservers(ItemGatheredEvent(Items.wildBerries.id, 1));
        }
      }
      
      if (_skillSubSpecs[SkillType.herbalism] == 'herbalism_hedge_witch') {
        if (_random.nextDouble() <= 0.10 && !_inventory.isFull) {
          _inventory = _inventory.addItem(Items.nightshade, 1);
          log("Gathered: 🌿 Nightshade x1", LogType.success);
          _lootController.add(LootEvent(Items.nightshade.icon, Items.nightshade.name));
          _notifyQuestObservers(ItemGatheredEvent(Items.nightshade.id, 1));
        }
      }
    }

    if (action.id == 'examine_grove') {
      _lastGroveTime = DateTime.now();
      final isHeartwoodReader = _skillSubSpecs[SkillType.woodcutting] == 'woodcutting_heartwood_reader';
      if (isHeartwoodReader && _random.nextDouble() <= 0.10) {
        if (!_inventory.isFull) {
          _inventory = _inventory.addItem(Items.heartwood, 1);
          log("Gathered: 🪵 Heartwood x1", LogType.success);
          _lootController.add(LootEvent(Items.heartwood.icon, Items.heartwood.name));
          _notifyQuestObservers(ItemGatheredEvent(Items.heartwood.id, 1));
        }
      } else {
        final logItem = _random.nextBool() ? Items.oakLog : Items.willowLog;
        if (!_inventory.isFull) {
          _inventory = _inventory.addItem(logItem, 1);
          log("Gathered: ${logItem.icon} ${logItem.name} x1", LogType.success);
          _lootController.add(LootEvent(logItem.icon, logItem.name));
          _notifyQuestObservers(ItemGatheredEvent(logItem.id, 1));
        }
      }
    }

    // Mining Vein Hunter: +20% chance for a hidden ore per mining action
    if (action.requiredSkill == SkillType.mining && _skillSubSpecs[SkillType.mining] == 'mining_vein_hunter') {
      if (_random.nextDouble() <= 0.20) {
        const ores = ['iron_ore', 'gold_ore', 'darkstone_ore', 'coal'];
        final randomOreId = ores[_random.nextInt(ores.length)];
        final randomOre = Items.findById(randomOreId);
        if (randomOre != null && !_inventory.isFull) {
          _inventory = _inventory.addItem(randomOre, 1);
          log("🔍 Vein Hunter! You discovered a hidden ${randomOre.name}!", LogType.success);
          _lootController.add(LootEvent(randomOre.icon, randomOre.name));
          _notifyQuestObservers(ItemGatheredEvent(randomOre.id, 1));
        }
      }
    }

    // Pastrycook Buff decrease
    if (_pastryBuffActionsRemaining > 0) {
      _pastryBuffActionsRemaining--;
      if (_pastryBuffActionsRemaining == 0) {
        log("🍰 Pastrycook Perk: Your pastry buff has worn off.", LogType.info);
      }
    }

    for (var loot in action.lootTable) {
      final roll = _random.nextDouble();
      double finalChance = loot.chance + successBonus + _currentZone.successModifier;
      if (!hasRequiredTool) {
        finalChance = finalChance - 0.30;
        if (finalChance < 0.10) finalChance = 0.10;
      }

      // Mining Prospector: +50% rare ore drop (gold, iron, darkstone)
      if (action.requiredSkill == SkillType.mining && _skillSpecs[SkillType.mining] == 'mining_prospector') {
        final isRareOre = loot.item.id == 'gold_ore' || loot.item.id == 'darkstone_ore' || loot.item.id == 'iron_ore';
        if (isRareOre) {
          finalChance += loot.chance * 0.50;
        }
      }

      // Herbalism Wild-Walker: +50% rare herb chance (nightshade)
      if (action.requiredSkill == SkillType.herbalism && _skillSpecs[SkillType.herbalism] == 'herbalism_wild_walker') {
        if (loot.item.id == 'nightshade') {
          finalChance += loot.chance * 0.50;
        }
      }

      if (roll <= finalChance) {
        int qty = loot.minQuantity;
        if (loot.maxQuantity > loot.minQuantity) {
          qty = loot.minQuantity + _random.nextInt(loot.maxQuantity - loot.minQuantity + 1);
        }

        // Specialization yield multipliers
        if (action.requiredSkill == SkillType.woodcutting) {
          if (_skillSpecs[SkillType.woodcutting] == 'woodcutting_logger') {
            qty = (qty * 1.3).round();
            if (_random.nextDouble() <= 0.20) {
              qty *= 2;
              log("🪓 Logger Cleaving Strike! You felled two trees at once!", LogType.success);
            }
          }
          if (_skillSubSpecs[SkillType.woodcutting] == 'woodcutting_clearcutter') {
            qty = (qty * 1.5).round();
          }
        } else if (action.requiredSkill == SkillType.mining) {
          if (_skillSpecs[SkillType.mining] == 'mining_prospector') {
            qty = (qty * 1.3).round();
            if (_random.nextDouble() <= 0.20) {
              qty *= 2;
              log("⛏️ Double Vein! You uncovered a rich vein!", LogType.success);
            }
          }
        } else if (action.requiredSkill == SkillType.herbalism) {
          if (loot.item.id == 'nightshade' && _skillSubSpecs[SkillType.herbalism] == 'herbalism_poison_picker') {
            qty += 1;
          }
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

    // Spec 3 Coast unlocks
    if (action.id == 'walk_eastern_coastal_path') {
      if (!_engineFlags.contains('coast_unlocked')) {
        _engineFlags.add('coast_unlocked');
        _engineFlags.add('wharfmaster_pier_visible');
        _unlockedZoneIds.add('sundered_coast_1');
        log("🗺️ New Zone Discovered: Sundered Coast I!", LogType.success);
        _checkMilestones();
        offerQuest(MainQuests.investigateTide());
      }
    }
    if (action.id == 'wharfmaster_travel') {
      travelTo(Zones.sunderedCoastTier1);
    }
    if (action.id == 'scout_cliff_path') {
      unlockZone('sundered_coast_2');
    }
    if (action.id == 'scout_lighthouse_path') {
      unlockZone('sundered_coast_3');
    }
    if (action.id == 'approach_lamp_room') {
      if (!_engineFlags.contains('drowned_lighthouse_spoken')) {
        _engineFlags.add('drowned_lighthouse_spoken');
        log("You approach the lamp room at the top of the lighthouse. The air is cold and smelling of salt. A voice whispers from the dark...", LogType.worldEvent);
        _checkMilestones();
      }
    }

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

    // Fragment drops by action id
    if (action.id == 'inspect_obelisk') {
      final startCount = _knownCodexFragmentIds.length;
      tryDropFragment(CodexTag.wilds, 0.10);
      tryDropFragment(CodexTag.oldEmpire, 0.01);
      final endCount = _knownCodexFragmentIds.length;
      if (endCount - startCount >= 2) {
        _engineFlags.add('ach_obelisk_double_drop');
        _checkAndUnlockAchievements();
      }
    }
    if (action.id == 'inspect_glyph') {
      tryDropFragment(CodexTag.stone, 0.10);
      tryDropFragment(CodexTag.oldEmpire, 0.01);
    }
    if (action.id == 'explore_forest_paths' || action.id == 'explore_deep_woods') {
      tryDropFragment(CodexTag.wilds, 0.05);
    }
    if (action.id == 'explore_rocky_trails' || action.id == 'explore_lower_shafts') {
      tryDropFragment(CodexTag.stone, 0.05);
    }
    // Spec 3 Coast drops
    if (action.id == 'inspect_pier_glyph') {
      tryDropFragment(CodexTag.tide, 0.10);
      tryDropFragment(CodexTag.oldEmpire, 0.01);
    }
    if (action.id == 'inspect_wharf_glyph') {
      tryDropFragment(CodexTag.tide, 0.10);
      tryDropFragment(CodexTag.oldEmpire, 0.02);
    }
    if (action.id == 'read_lighthouse_plaque') {
      tryDropFragment(CodexTag.tide, 0.15);
      tryDropFragment(CodexTag.oldEmpire, 0.03);
    }
    if (action.id == 'walk_eastern_coastal_path') {
      tryDropFragment(CodexTag.tide, 0.20);
    }
    if (action.id == 'scout_cliff_path') {
      tryDropFragment(CodexTag.tide, 0.05);
    }
    if (action.id == 'scout_lighthouse_path') {
      tryDropFragment(CodexTag.tide, 0.05);
    }

    // Tier-3 gathering — Source pool gate prevents firing until first_breach_cleansed
    if (_currentZone.tier >= 3 && !action.isCombat) {
      tryDropFragment(CodexTag.source, 0.03);
    }

    rollBlueprintScrollDrop(_currentZone.tier);
    if (!action.isCombat && action.requiredSkill != null) {
      final tool = _equippedToolSlots[action.requiredSkill!];
      if (tool != null) {
        _decrementDurability(tool, slot: 'tool', skill: action.requiredSkill);
      }
    }
    if (_currentZone.id != 'town_square') {
      _maybeFireEndgameAmbient('complete_action_outside_town', "The light is different now. You notice it without being able to say how. The road feels longer in a quieter way.");
    }
    _playerAction = null;
    notifyListeners();

    if (!action.isCombat) {
      _maybeFireRandomEvent(action);
    }

    if (_activeRandomEvent != null) {
      return;
    }

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
    double xpMultiplier = getXpMultiplier();
    if (modifierItemId == 'wildflower') {
      xpMultiplier *= 1.5;
    }
    final xpReward = recipe.xpReward * xpMultiplier;
    final oldSkill = _skills[recipe.requiredSkill]!;
    _grantSkillXp(recipe.requiredSkill, xpReward);
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
      if (instance.stationId == 'smelter') {
        if (_skillSpecs[SkillType.mining] == 'mining_refiner') {
          finalQty += 1;
        }
        if (_skillSubSpecs[SkillType.mining] == 'mining_smelt_master') {
          finalQty *= 2;
        }
      }
      if (modifierItemId == 'spirit_sap') {
        finalQty *= 2;
      }

      final skillLevel = oldSkill.level;
      final stationBias = getStationQualityBias(instance.tier);
      
      double substituteBias = 0.0;
      bool hasBelowCanonical = false;
      final consumed = instance.currentCraft!.consumedItems;
      if (consumed != null) {
        substituteBias = calculateRecipeQualityBias(recipe, consumed);
        final tempConsumed = Map<String, int>.from(consumed);
        for (final slot in recipe.slots) {
          for (final choice in slot.acceptedItems) {
            if (choice.qualityBias < 0.0) {
              final available = tempConsumed[choice.itemId] ?? 0;
              if (available > 0) {
                hasBelowCanonical = true;
                break;
              }
            }
          }
        }
      } else {
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
      }

      final roll = _random.nextDouble();
      double specBias = _getSpecCraftQualityBias(recipe, resultItem, instance.stationId);
      double qualityScore = roll + 0.020 * (skillLevel - recipe.requiredLevel) + stationBias + substituteBias + specBias;
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
      } else if (modifierItemId == 'wisp_light') {
        quality = QualityTier.masterwork;
      }

      var affixes = rollAffixes(quality, resultItem.type);
      if ((modifierItemId == 'nightshade' || modifierItemId == 'moonpetal') && affixes.isEmpty) {
        affixes = rollAffixesForced(resultItem.type);
      }
      if (modifierItemId == 'hollow_bone' && resultItem.type == ItemType.weapon) {
        if (!affixes.contains('brutal')) {
          affixes = List<String>.from(affixes)..add('brutal');
        }
      }
      if (modifierItemId == 'sea_tear' && resultItem.type == ItemType.armor) {
        if (!affixes.contains('tempered')) {
          affixes = List<String>.from(affixes)..add('tempered');
        }
      }
      if (modifierItemId == 'coalblood') {
        if (!affixes.contains('frugal')) {
          affixes = List<String>.from(affixes)..add('frugal');
        }
      }
      if (_skillSubSpecs[SkillType.cooking] == 'cooking_brewmaster' &&
          recipe.requiredSkill == SkillType.cooking &&
          instance.stationId == 'field_kitchen' &&
          instance.zoneId == 'town_square') {
        affixes = List<String>.from(affixes)..add('brewmaster_aged');
      }

      if (_inventory.isFull) {
        log("Your inventory is full! The ${resultItem.name} was dropped.", LogType.error);
      } else {
        final maxDur = calculateMaxDurability(resultItem, quality, affixes);
        _inventory = _inventory.addItem(resultItem, finalQty, quality, affixes, maxDur, maxDur);
        
        _totalCrafts += finalQty;
        if (quality == QualityTier.masterwork) {
          _masterworkCrafts += finalQty;
        }
        if (resultItem.type == ItemType.brew) {
          _brewCrafts += finalQty;
        }

        String affixSuffix = affixes.isNotEmpty ? " [${affixes.map((a) => Affixes.findById(a)?.name ?? a).join(', ')}]" : "";
        String qualLabel = quality == QualityTier.standard ? "" : "${quality.name.toUpperCase()} ";

        log("Crafted: ${resultItem.icon} ${qualLabel}${resultItem.name}$affixSuffix x$finalQty at ${instance.stationId}", LogType.success);
        _lootController.add(LootEvent(resultItem.icon, "${qualLabel}${resultItem.name}$affixSuffix", quality, affixes));
        _notifyQuestObservers(ItemCraftedEvent(recipe.id, quality, finalQty));
        _updateDailyTaskProgress(ItemCraftedEvent(recipe.id, quality, finalQty));
        _checkAndUnlockAchievements();
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

    // Check combat round timer
    if (_activeCombat != null &&
        _activeCombat!.roundDeadline != null &&
        DateTime.now().isAfter(_activeCombat!.roundDeadline!)) {
      _onRoundTimerExpired();
    }

    _checkMilestones();
    _maybeRollCoastWeather();

    bool stateChanged = false;

    // 1. Tick Player Action
    if (_playerAction != null) {
      final state = _playerAction!;
      if (state.action != null && state.action!.isCombat) {
        if (_activeCombat != null && _activeCombat!.roundDeadline != null) {
          final remaining = _activeCombat!.roundDeadline!.difference(DateTime.now());
          final maxMs = combatRoundDurationMs;
          final pct = (1.0 - (remaining.inMilliseconds.clamp(0, maxMs) / maxMs.toDouble())).clamp(0.0, 1.0);
          _playerAction = state.copyWith(progress: pct);
          stateChanged = true;
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

    // Glyph-Carver & Rune-Weaver glyph uses
    int totalAllowedUses = 1;
    if (item.id.contains('glyph')) {
      if (_skillSpecs[SkillType.lore] == 'lore_glyph_carver') {
        totalAllowedUses += 1;
      }
      if (_skillSubSpecs[SkillType.lore] == 'lore_rune_weaver') {
        totalAllowedUses += 1;
      }
    }

    bool shouldRemove = true;
    if (item.id.contains('glyph') && totalAllowedUses > 1) {
      final key = "${item.id}_${quality?.name}_${affs.join(',')}";
      final currentUses = _glyphUses[key] ?? 0;
      if (currentUses < totalAllowedUses - 1) {
        _glyphUses[key] = currentUses + 1;
        shouldRemove = false;
        log("Runic preservation: ${item.name} has ${totalAllowedUses - 1 - currentUses} uses remaining.", LogType.info);
      } else {
        _glyphUses[key] = 0; // reset
      }
    }

    if (shouldRemove) {
      _inventory = _inventory.removeItem(item.id, 1, quality, affs);
    }

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

    // Lore Glyph-Carver: Glyph items +50% effect
    if (item.id.contains('glyph') && _skillSpecs[SkillType.lore] == 'lore_glyph_carver') {
      baseHeal = (baseHeal * 1.5).round();
      baseEnergy = (baseEnergy * 1.5).round();
    }

    // Cooking Brewmaster: Foods crafted at Inn-only stations (with brewmaster_aged affix) also restore +30% energy
    if (affs.contains('brewmaster_aged')) {
      baseEnergy = (baseEnergy * 1.30).round();
    }

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

    // Cooking Pastrycook perk: Gained random buff
    if (_skillSubSpecs[SkillType.cooking] == 'cooking_pastrycook') {
      _pastryBuffActionsRemaining = 3;
      final rolled = _random.nextInt(3);
      if (rolled == 0) {
        _pastryBuffStat = 'speed';
        log("🍰 Pastrycook Perk: Gained +10% action speed for 3 actions!", LogType.success);
      } else if (rolled == 1) {
        _pastryBuffStat = 'success';
        log("🍰 Pastrycook Perk: Gained +5% success chance for 3 actions!", LogType.success);
      } else {
        _pastryBuffStat = 'defense';
        log("🍰 Pastrycook Perk: Gained +2 Defense for 3 actions!", LogType.success);
      }
    }

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

    final maxDur = calculateMaxDurability(item, QualityTier.standard, const []);
    _inventory = _inventory.addItem(item, 1, QualityTier.standard, const [], maxDur, maxDur);
    _playerStats = _playerStats.copyWith(gold: _playerStats.gold - item.value);
    log("Purchased ${item.icon} ${item.name} for ${item.value} Gold.", LogType.success);
    notifyListeners();
  }

  void buyShopItem(ShopListing listing, int quantity) {
    final rep = getMerchantReputation(_shopState.currentMerchant.id);
    final finalBuyPrice = listing.getBuyPrice(rep.tier.discountPercent);
    final cost = finalBuyPrice * quantity;
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

    final maxDur = calculateMaxDurability(listing.item, QualityTier.standard, const []);
    _inventory = _inventory.addItem(listing.item, quantity, QualityTier.standard, const [], maxDur, maxDur);
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
    
    addMerchantReputation(_shopState.currentMerchant.id, cost * 2);
    if (!_engineFlags.contains('ach_first_trade')) {
      _engineFlags.add('ach_first_trade');
      _checkAndUnlockAchievements();
    }

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
    
    _lifetimeGold += earnings;
    addMerchantReputation(_shopState.currentMerchant.id, earnings * 1);
    if (!_engineFlags.contains('ach_first_trade')) {
      _engineFlags.add('ach_first_trade');
      _checkAndUnlockAchievements();
    }

    notifyListeners();
  }

  void setActiveMerchantIndex(int index) {
    if (index >= 0 && index < _shopState.activeMerchants.length) {
      _shopState = _shopState.copyWith(activeMerchantIndex: index);
      _maybeFireEndgameAmbient('focus_merchant', "The shopkeeper hesitates before naming a price. 'For the one who quieted the Source,' they say. 'On the house, this time.'");
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

      // Reset session reputation for all merchants on rotation/restock
      for (final id in _merchantRep.keys) {
        _merchantRep[id] = _merchantRep[id]!.copyWith(sessionReputation: 0);
      }

      log("🏪 The market square merchants have rotated! Check out their new stock.", LogType.info);
      notifyListeners();
    }
  }

  void forceRestockForTesting() {
    _shopState = _shopState.copyWith(
      lastRestockTime: DateTime.now().subtract(const Duration(minutes: 10)),
    );
    checkShopRestock();
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
      final taskId = _activeMasterwork!.task.id;
      _activeMasterwork = null;

      if (option.isSuccess) {
        if (!_engineFlags.contains('ach_first_masterwork')) {
          _engineFlags.add('ach_first_masterwork');
        }
        if (taskId.startsWith('cleansing_')) {
          _onCleansingComplete(taskId.substring('cleansing_'.length));
        } else {
          // Unlock cap!
          final oldSkill = _skills[skillType]!;
          final newSkill = oldSkill.unlockCap();
          _skills[skillType] = newSkill;

          if (option.specPath != null) {
            _skillSpecs[skillType] = option.specPath!;
            log("You have walked the ${_specDisplayName(option.specPath!)} path. Forevermore, your craft knows your name.", LogType.success);
          }
          if (option.subSpecPath != null) {
            _skillSubSpecs[skillType] = option.subSpecPath!;
            log("You have refined further into ${_subSpecDisplayName(option.subSpecPath!)}.", LogType.success);
          }

          log("CONGRATULATIONS! You completed the '$taskTitle' Masterwork Trial!", LogType.levelUp);
          log("Your ${skillType.name} level cap is unlocked up to level ${newSkill.levelCap}!", LogType.levelUp);
          _notifyQuestObservers(MasterworkCompletedEvent(skillType));
        }
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

  void _maybeRollCoastWeather() {
    if (DateTime.now().isBefore(_coastWeather.nextRollAt)) return;

    final stormChance = _calculateStormChance();
    const fogChance = 0.25;
    final roll = _random.nextDouble();

    final CoastWeather next;
    if (roll < stormChance) {
      next = CoastWeather.stormSwell;
    } else if (roll < stormChance + fogChance) {
      next = CoastWeather.seaFog;
    } else {
      next = CoastWeather.calm;
    }

    if (next != _coastWeather.current) {
      log('Coast weather: ${_weatherDisplayName(next)}', LogType.info);
    }
    _coastWeather = CoastWeatherState(
      current: next,
      nextRollAt: DateTime.now().add(const Duration(minutes: 5)),
    );
    notifyListeners();
  }

  double _calculateStormChance() {
    double chance = 0.05;
    final breachTagsWithFragments = <CodexTag>{};
    for (final id in _knownCodexFragmentIds) {
      final f = CodexFragments.findById(id);
      if (f != null && (f.tag == CodexTag.wilds || f.tag == CodexTag.stone || f.tag == CodexTag.tide)) {
        breachTagsWithFragments.add(f.tag);
      }
    }
    if (_engineFlags.contains('breach_wilds_cleansed')) breachTagsWithFragments.remove(CodexTag.wilds);
    if (_engineFlags.contains('breach_stone_cleansed')) breachTagsWithFragments.remove(CodexTag.stone);
    if (_engineFlags.contains('breach_tide_cleansed')) breachTagsWithFragments.remove(CodexTag.tide);
    chance += breachTagsWithFragments.length * 0.05;
    return chance.clamp(0.0, 0.50);
  }

  String _weatherDisplayName(CoastWeather weather) {
    switch (weather) {
      case CoastWeather.calm:
        return '🌤️ Calm';
      case CoastWeather.seaFog:
        return '🌫️ Sea Fog';
      case CoastWeather.stormSwell:
        return '⛈️ Storm Swell';
    }
  }

  @visibleForTesting
  void forceCoastWeatherForTest(CoastWeather weather) {
    _coastWeather = CoastWeatherState(
      current: weather,
      nextRollAt: DateTime.now().add(const Duration(minutes: 5)),
    );
    notifyListeners();
  }

  @visibleForTesting
  double calculateStormChancePublic() {
    return _calculateStormChance();
  }

  @visibleForTesting
  void completeScoutForTest(String actionId) {
    final action = Zones.townSquare.actions.firstWhere((a) => a.id == actionId);
    _playerAction = ActiveActionState(
      action: action,
      progress: 1.0,
      durationSeconds: 1.0,
    );
    _completePlayerAction();
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

  int get combatRoundDurationMs {
    int base = 2000;
    if (_skillSubSpecs[SkillType.combat] == 'combat_skirmisher') {
      base = (base / 1.25).round();
    }
    final combatSkill = _skills[SkillType.combat];
    if (combatSkill != null && combatSkill.levelCap > 20) {
      base = (base / 1.15).round();
    }
    return base;
  }

  double _getSpecCraftQualityBias(Recipe recipe, Item resultItem, String stationId) {
    double bias = 0.0;
    if (_skillSpecs[SkillType.crafting] == 'crafting_smith') {
      if (resultItem.type == ItemType.weapon || resultItem.type == ItemType.armor) {
        bias += 0.10;
      }
    }
    if (_skillSubSpecs[SkillType.crafting] == 'crafting_weaponsmith') {
      if (resultItem.type == ItemType.weapon) {
        bias += 0.15;
      }
    }
    if (_skillSubSpecs[SkillType.crafting] == 'crafting_armorsmith') {
      if (resultItem.type == ItemType.armor) {
        bias += 0.15;
      }
    }
    if (_skillSpecs[SkillType.crafting] == 'crafting_tinker') {
      if (resultItem.type == ItemType.tool) {
        bias += 0.10;
      }
    }
    if (_skillSubSpecs[SkillType.crafting] == 'crafting_toolmaker') {
      if (resultItem.type == ItemType.tool) {
        bias += 0.15;
      }
    }
    if (_skillSpecs[SkillType.mining] == 'mining_refiner') {
      if (stationId == 'smelter') {
        bias += 0.10;
      }
    }
    if (_skillSubSpecs[SkillType.mining] == 'mining_slag_cutter') {
      if (stationId == 'smelter') {
        bias += 0.15;
      }
    }
    return bias;
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
    _reagentSpawns.clear();
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

    _skillSpecs.clear();
    _skillSubSpecs.clear();
    _glyphUses.clear();
    _pastryBuffActionsRemaining = 0;
    _pastryBuffStat = null;
    _lastGardenTime = null;
    _lastGroveTime = null;

    _merchantRep.clear();
    _claimedGifts.clear();
    _todaysTasks = [];
    _dailyBonusClaimed = false;
    _tavernRequested = false;
    _lifetimeGold = 10;
    _anyRepairThisRun = false;
    _firstEnteredZones.clear();
    _firstEnteredZones.add('town_square');
    _totalCrafts = 0;
    _masterworkCrafts = 0;
    _brewCrafts = 0;
    _earnedAchievementIds.clear();
    _activeTitleId = null;
    _pendingYouWinModal = false;
    _endgameAmbientFired.clear();
    _engineFlags.clear();

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
    _updateDailyTaskProgress(event);
    for (final quest in List<Quest>.from(_activeQuests)) {
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
    if (objective.comingSoon) return false;

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
        if (event is! CodexFragmentReadEvent) return false;
        if (objective.targetTag == null) return true;
        final fragment = CodexFragments.findById(event.fragmentId);
        return fragment != null && fragment.tag.name == objective.targetTag;
      case ObjectiveKind.cleanse:
        return false; // Not implemented in Spec 1
      case ObjectiveKind.custom:
        return event is CustomQuestEvent && event.eventId == objective.targetId;
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
          final skillType = SkillType.values.firstWhere((s) => s.name.toLowerCase() == reward.targetId?.toLowerCase());
          final xpReward = reward.amount.toDouble() * getXpMultiplier();
          log("Received: +${reward.amount} ${skillType.name} XP", LogType.success);
          _grantSkillXp(skillType, xpReward);
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
      case RewardKind.offerQuest:
        if (reward.targetId != null) {
          final next = MainQuests.findById(reward.targetId!);
          if (next != null) offerQuest(next);
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

    offerQuest(MainQuests.discoverSickness());
  }

  void _maybeOfferMasterworkQuest(SkillType skill) {
    final state = _skills[skill]!;
    if (state.level < state.levelCap) return;

    if (state.levelCap == 10) {
      final questId = 'side_masterwork_${skill.name.toLowerCase()}';
      if (_activeQuests.any((q) => q.id == questId)) return;
      if (_completedQuests.any((q) => q.id == questId)) return;

      final task = MasterworkTasks.findForSkill(skill, 10);
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
    } else if (state.levelCap == 20) {
      final spec = _skillSpecs[skill];
      if (spec == null) return;

      final questId = 'task_lvl20_$spec';
      if (_activeQuests.any((q) => q.id == questId)) return;
      if (_completedQuests.any((q) => q.id == questId)) return;

      final task = MasterworkTasks.findForSkill(skill, 20, spec);
      if (task == null) return;

      offerQuest(Quest(
        id: questId,
        type: QuestType.side,
        title: 'Specialization: ${task.title}',
        description: task.description,
        objectives: [
          QuestObjective(kind: ObjectiveKind.masterwork, targetId: skill.name, targetCount: 1),
        ],
        rewards: [
          QuestReward(kind: RewardKind.skillXp, targetId: skill.name, amount: 100),
          QuestReward(kind: RewardKind.gold, amount: 50),
        ],
        turnInLocation: null,
      ));
    }
  }

  String _specDisplayName(String path) {
    const names = {
      'combat_berserker': 'Berserker', 'combat_guardian': 'Guardian',
      'crafting_smith': 'Smith', 'crafting_tinker': 'Tinker',
      'cooking_innkeeper': 'Innkeeper', 'cooking_field_chef': 'Field-Chef',
      'herbalism_garden_keeper': 'Garden-Keeper', 'herbalism_wild_walker': 'Wild-Walker',
      'woodcutting_logger': 'Logger', 'woodcutting_arborist': 'Arborist',
      'mining_prospector': 'Prospector', 'mining_refiner': 'Refiner',
      'wayfinding_cartographer': 'Cartographer', 'wayfinding_tracker': 'Tracker',
      'lore_loremaster': 'Loremaster', 'lore_glyph_carver': 'Glyph-Carver',
    };
    return names[path] ?? path;
  }

  String _subSpecDisplayName(String path) {
    const names = {
      'combat_skirmisher': 'Skirmisher', 'combat_reaper': 'Reaper',
      'combat_bastion': 'Bastion', 'combat_sentinel': 'Sentinel',
      'crafting_weaponsmith': 'Weaponsmith', 'crafting_armorsmith': 'Armorsmith',
      'crafting_toolmaker': 'Toolmaker', 'crafting_backpacker': 'Backpacker',
      'cooking_brewmaster': 'Brewmaster', 'cooking_pastrycook': 'Pastrycook',
      'cooking_trailcook': 'Trailcook', 'cooking_stewmaster': 'Stewmaster',
      'herbalism_botanist': 'Botanist', 'herbalism_hedge_witch': 'Hedge-Witch',
      'herbalism_poison_picker': 'Poison-Picker', 'herbalism_bloomseer': 'Bloomseer',
      'woodcutting_clearcutter': 'Clearcutter', 'woodcutting_speedchopper': 'Speedchopper',
      'woodcutting_sapling_mender': 'Sapling-Mender', 'woodcutting_heartwood_reader': 'Heartwood-Reader',
      'mining_vein_hunter': 'Vein-Hunter', 'mining_tunnel_caller': 'Tunnel-Caller',
      'mining_smelt_master': 'Smelt-Master', 'mining_slag_cutter': 'Slag-Cutter',
      'wayfinding_sea_reader': 'Sea-Reader', 'wayfinding_path_mapper': 'Path-Mapper',
      'wayfinding_beast_lurer': 'Beast-Lurer', 'wayfinding_spoor_reader': 'Spoor-Reader',
      'lore_polymath': 'Polymath', 'lore_translator': 'Translator',
      'lore_rune_weaver': 'Rune-Weaver', 'lore_engraver': 'Engraver',
    };
    return names[path] ?? path;
  }

  String specDisplayName(String path) => _specDisplayName(path);
  String subSpecDisplayName(String path) => _subSpecDisplayName(path);
  String specDisplayNameForTest(String path) => _specDisplayName(path);
  String subSpecDisplayNameForTest(String path) => _subSpecDisplayName(path);

  @visibleForTesting
  void maybeOfferLvl20MasterworkForTest(SkillType s) => _maybeOfferMasterworkQuest(s);

  @visibleForTesting
  void completeMasterworkForTest(String taskId, {String? specPath, String? subSpecPath, bool useFirstSuccessOption = false}) {
    final task = MasterworkTasks.findById(taskId);
    if (task == null) return;
    if (taskId.startsWith('cleansing_')) {
      _onCleansingComplete(taskId.substring('cleansing_'.length));
      return;
    }
    _skills[task.skillType] = _skills[task.skillType]!.unlockCap();
    if (specPath != null) {
      _skillSpecs[task.skillType] = specPath;
    }
    if (subSpecPath != null) {
      _skillSubSpecs[task.skillType] = subSpecPath;
    }
    notifyListeners();
  }

  @visibleForTesting
  void setCraftingLevelForTest(int level) {
    _skills[SkillType.crafting] = _skills[SkillType.crafting]!.copyWith(level: level);
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
    if (!_knownCodexFragmentIds.contains(fragmentId)) return;
    final alreadyRead = _readCodexFragmentIds.contains(fragmentId);
    _readCodexFragmentIds.add(fragmentId);

    if (!alreadyRead) {
      final fragment = CodexFragments.findById(fragmentId)!;
      final skillType = SkillType.lore;
      log("Read Codex Fragment: ${fragment.title} (+15 Lore XP)", LogType.success);
      _grantSkillXp(skillType, 15.0 * getXpMultiplier());
      _maybeOfferMasterworkQuest(skillType);
      
      _notifyQuestObservers(CodexFragmentReadEvent(fragmentId));
      _updateDailyTaskProgress(CodexFragmentReadEvent(fragmentId));
      _checkMilestones();
    }
    notifyListeners();
  }

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
      case CodexTag.wilds:
        return true;
      case CodexTag.stone:
        return _regionStatus.containsKey('darkstone_mine_1');
      case CodexTag.tide:
        return _engineFlags.contains('coast_unlocked');
      case CodexTag.source:
        return _engineFlags.contains('first_breach_cleansed');
      case CodexTag.oldEmpire:
        return true;
      case CodexTag.misc:
        return true;
    }
  }

  void _grantFragment(CodexFragment fragment) {
    _knownCodexFragmentIds.add(fragment.id);
    log("📜 Codex Fragment found: ${fragment.title}", LogType.success);
    _checkMilestones();
    notifyListeners();
  }

  CodexTag? _regionTagForBeast(String beastId) {
    switch (beastId) {
      case 'forest_boar':
      case 'shadow_wolf':
      case 'echo_of_wilds':
        return CodexTag.wilds;
      case 'cave_spider':
      case 'cavern_troll':
      case 'echo_of_stone':
        return CodexTag.stone;
      case 'tide_hound':
      case 'brine_crawler':
      case 'salt_touched_drowned':
      case 'echo_of_tide':
        return CodexTag.tide;
      default:
        return null;
    }
  }

  @visibleForTesting
  CodexTag? regionTagForBeastPublic(String beastId) {
    return _regionTagForBeast(beastId);
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
      if (_solvedTagPuzzles.contains(tag)) return;
      _solvedTagPuzzles.add(tag);
      _engineFlags.add('puzzle_${tag.name}_solved');
      final reading = CodexReadings.forTag(tag);
      if (reading != null) {
        for (var r in reading.rewards) _grantReward(r);
      }
      log("✨ Puzzle solved: ${tag.name} — Reading unlocked.", LogType.success);
      _puzzleResultController.add(
        PuzzleResult(tag: tag, correctness: correctness, reading: reading),
      );
      advanceQuestObjective('puzzle_${tag.name}_solved');
      _checkMilestones();
    } else {
      _puzzleAttempts[tag] = (_puzzleAttempts[tag] ?? 0) + 1;
      final loreSkill = _skills[SkillType.lore]!;
      final newXp = (loreSkill.xp - 3.0).clamp(0.0, double.infinity);
      _skills[SkillType.lore] = loreSkill.copyWith(xp: newXp);
      final correctCount = correctness.where((c) => c).length;
      log(
        "Puzzle attempt failed (−3 Lore XP). $correctCount of ${correctness.length} in place.",
        LogType.info,
      );
      _puzzleResultController.add(
        PuzzleResult(tag: tag, correctness: correctness, reading: null),
      );
    }
    notifyListeners();
  }

  // Combat Stance & Turn Resolution APIs
  void setCombatStance(PlayerStance stance, {int? quickslotIndex}) {
    if (_activeCombat == null || _activeCombat!.pendingStance != null) return;
    final cost = _stanceCost(stance);
    if (_playerStats.currentEnergy < cost) {
      log("Not enough energy for that action.", LogType.warning);
      return;
    }
    _playerStats = _playerStats.copyWith(
      currentEnergy: _playerStats.currentEnergy - cost,
    );
    _activeCombat = _activeCombat!.copyWith(
      pendingStance: stance,
      pendingQuickslotIndex: quickslotIndex,
    );
    notifyListeners();
    _resolveCombatRound();
  }

  int _stanceCost(PlayerStance s) {
    switch (s) {
      case PlayerStance.strike: return 0;
      case PlayerStance.heavyStrike:
        return (_skillSpecs[SkillType.combat] == 'combat_berserker') ? 4
            : (_skillSpecs[SkillType.combat] == 'combat_guardian') ? 8
            : 5;
      case PlayerStance.defend: return 2;
      case PlayerStance.readTells: return 3;
      case PlayerStance.item: return 0;
    }
  }

  int getStanceCost(PlayerStance s) => _stanceCost(s);

  void _resolveCombatRound() {
    if (_activeCombat == null || _activeCombat!.pendingStance == null) return;
    final state = _activeCombat!;
    final beast = state.beast;
    final stance = state.pendingStance!;

    int playerDmgDealt = 0;
    int playerDmgTaken = 0;
    bool wasCrit = false;

    // Determine telegraph state
    final hasActiveTelegraph = state.activeTelegraph != null;

    final updatedLog = List<String>.from(state.combatLog);

    int quakeCounter = state.sourceQuakeCounter;
    int nextSedimentStacks = state.sourceSedimentStacks;
    int pollenCounter = state.sourcePollenCounter;

    PlayerStance currentStance = stance;
    if (state.activePhasePassive == BeastPassive.sourcePollenCloud) {
      pollenCounter += 1;
      if (pollenCounter % 2 == 0) {
        final others = PlayerStance.values.where((s) => s != currentStance).toList();
        final rolled = others[_random.nextInt(others.length)];
        updatedLog.add("⚠️ Pollen clouds your sight — your stance shifts to ${rolled.name}.");
        log("Pollen clouds your sight — your stance shifts to ${rolled.name}.", LogType.warning);
        currentStance = rolled;
      }
    }

    // Resolve based on stance
    switch (currentStance) {
      case PlayerStance.strike:
      case PlayerStance.heavyStrike:
        bool isSedimentBlocked = false;
        if (state.activePhasePassive == BeastPassive.sourceSedimentStack) {
          if (state.sourceSedimentStacks >= 3) {
            isSedimentBlocked = true;
          }
        }

        if (isSedimentBlocked) {
          playerDmgDealt = 0;
          nextSedimentStacks = 0;
          wasCrit = false;
          updatedLog.add("🛡️ Your strike sinks into sediment and finds nothing. (Stacks consumed.)");
          log("Your strike sinks into sediment and finds nothing.", LogType.warning);
        } else {
          // Player deals damage
          int baseDmg = getPlayerAttack() - beast.defense;
          if (baseDmg < 1) baseDmg = 1;
          // Apply random variance
          final variance = 0.85 + _random.nextDouble() * 0.30;
          baseDmg = (baseDmg * variance).round();
          if (baseDmg < 1) baseDmg = 1;

          double dmgMultiplier = 1.0;
          if (currentStance == PlayerStance.heavyStrike) {
            final isBerserker = _skillSpecs[SkillType.combat] == 'combat_berserker';
            dmgMultiplier = isBerserker ? 1.8 : 1.5;
          }
          // Sea Fog crit
          double critChance = 0.0;
          if (_currentZone.id.startsWith('sundered_coast_') &&
              _coastWeather.current == CoastWeather.seaFog) {
            critChance += 0.20;
          }
          if (_skillSubSpecs[SkillType.combat] == 'combat_reaper') {
            critChance += 0.15;
          }
          // reducedAccuracy (Tide P2) - halve crit chance
          if (state.activePhasePassive == BeastPassive.reducedAccuracy) {
            critChance *= 0.5;
          }
          wasCrit = _random.nextDouble() < critChance;
          if (wasCrit) {
            final isReaper = _skillSubSpecs[SkillType.combat] == 'combat_reaper';
            dmgMultiplier *= isReaper ? 2.5 : 1.5;
          }

          playerDmgDealt = (baseDmg * dmgMultiplier).round();
          // damageReduction (Stone P2) - reduce damage by 25%
          if (state.activePhasePassive == BeastPassive.damageReduction) {
            playerDmgDealt = (playerDmgDealt * 0.75).round();
          }
          if (playerDmgDealt < 1) playerDmgDealt = 1;

          if (wasCrit) {
            updatedLog.add("⚡ Critical Strike! You hit ${beast.name} for $playerDmgDealt damage!");
            log("⚡ Critical Strike! $playerDmgDealt damage", LogType.success);
          } else {
            updatedLog.add("⚔️ You strike ${beast.name} for $playerDmgDealt damage!");
          }

          if (playerDmgDealt > 0 && state.activePhasePassive == BeastPassive.sourceSedimentStack) {
            nextSedimentStacks += 1;
            if (nextSedimentStacks == 3) {
              updatedLog.add("⚠️ Sediment thickens around the Source — your next strike will sink.");
              log("Sediment thickens around the Source — your next strike will sink.", LogType.warning);
            }
          }
        }

        // Heavy Strike: beast acts first
        if (currentStance == PlayerStance.heavyStrike) {
          playerDmgTaken = _calculateBeastDamage(beast, hasActiveTelegraph);
          updatedLog.add("${beast.icon} ${beast.name} strikes you for $playerDmgTaken damage!");
        }
        // Apply player damage to beast
        final newBeastHp = (state.beastCurrentHealth - playerDmgDealt).clamp(0, beast.maxHealth);
        // Apply beast damage to player (if not Heavy Strike, beast acts after)
        if (currentStance != PlayerStance.heavyStrike) {
          playerDmgTaken = _calculateBeastDamage(beast, hasActiveTelegraph);
          updatedLog.add("${beast.icon} ${beast.name} strikes you for $playerDmgTaken damage!");
        }
        _playerStats = _playerStats.copyWith(
          currentHealth: (_playerStats.currentHealth - playerDmgTaken).clamp(0, _playerStats.maxHealth),
        );
        _activeCombat = state.copyWith(
          beastCurrentHealth: newBeastHp,
          clearPendingStance: true,
          combatLog: updatedLog,
          currentRoundNumber: state.currentRoundNumber + 1,
          roundsSinceLastTelegraph: hasActiveTelegraph ? 0 : state.roundsSinceLastTelegraph + 1,
          clearActiveTelegraph: true,
          roundHistory: [
            ...state.roundHistory,
            CombatRound(
              roundNumber: state.currentRoundNumber,
              chosenStance: currentStance,
              playerDamageDealt: playerDmgDealt,
              playerDamageTaken: playerDmgTaken,
              wasCrit: wasCrit,
            ),
          ],
          roundDeadline: DateTime.now().add(Duration(milliseconds: combatRoundDurationMs)),
        );
        break;

      case PlayerStance.defend:
        // Halve incoming damage
        int incoming = _calculateBeastDamage(beast, hasActiveTelegraph);
        incoming = (incoming / 2).floor();
        if (incoming < 1) incoming = 1;
        // Counter damage (Guardian spec only)
        final isGuardian = _skillSpecs[SkillType.combat] == 'combat_guardian';
        final isSentinel = _skillSubSpecs[SkillType.combat] == 'combat_sentinel';
        int counter = 0;
        if (isGuardian) counter = isSentinel ? 10 : 5;

        updatedLog.add("🛡️ You defend! Incoming damage halved: $incoming taken.");
        if (counter > 0) {
          updatedLog.add("🛡️ Guardian Counter! You deal $counter damage to ${beast.name}!");
        }
        updatedLog.add("${beast.icon} ${beast.name} strikes you for $incoming damage!");

        int healAmt = 0;
        if (_skillSubSpecs[SkillType.combat] == 'combat_bastion') {
          healAmt = 5;
          updatedLog.add("🛡️ Bastion Defense! You regenerate $healAmt HP!");
        }

        _playerStats = _playerStats.copyWith(
          currentHealth: (_playerStats.currentHealth - incoming + healAmt).clamp(0, _playerStats.maxHealth),
        );
        final newBeastHp = (state.beastCurrentHealth - counter).clamp(0, beast.maxHealth);
        _activeCombat = state.copyWith(
          beastCurrentHealth: newBeastHp,
          clearPendingStance: true,
          combatLog: updatedLog,
          currentRoundNumber: state.currentRoundNumber + 1,
          roundsSinceLastTelegraph: hasActiveTelegraph ? 0 : state.roundsSinceLastTelegraph + 1,
          clearActiveTelegraph: true,
          roundDeadline: DateTime.now().add(Duration(milliseconds: combatRoundDurationMs)),
          roundHistory: [
            ...state.roundHistory,
            CombatRound(
              roundNumber: state.currentRoundNumber,
              chosenStance: currentStance,
              playerDamageDealt: counter,
              playerDamageTaken: incoming,
              wasCrit: false,
            ),
          ],
        );
        break;

      case PlayerStance.readTells:
        // No damage; reveal next telegraph
        final updatedTelegraph = state.activeTelegraph != null
            ? BeastTelegraph(
                abilityId: state.activeTelegraph!.abilityId,
                text: state.activeTelegraph!.text,
                reveal: true,
              )
            : null;
        updatedLog.add("👁️ You read the tells of ${beast.name}.");
        if (updatedTelegraph != null) {
          updatedLog.add("👁️ Glimpsed: ${beast.name} preparing ${updatedTelegraph.abilityId}!");
        } else {
          updatedLog.add("👁️ No active ability telegraphed.");
        }
        _activeCombat = state.copyWith(
          clearPendingStance: true,
          combatLog: updatedLog,
          currentRoundNumber: state.currentRoundNumber + 1,
          activeTelegraph: updatedTelegraph,
          roundDeadline: DateTime.now().add(Duration(milliseconds: combatRoundDurationMs)),
          roundHistory: [
            ...state.roundHistory,
            CombatRound(
              roundNumber: state.currentRoundNumber,
              chosenStance: currentStance,
              playerDamageDealt: 0,
              playerDamageTaken: 0,
              wasCrit: false,
            ),
          ],
        );
        break;

      case PlayerStance.item:
        // Consume Quick-Slot item
        final idx = state.pendingQuickslotIndex;
        if (idx != null && idx >= 0 && idx < _quickslots.length) {
          final itemId = _quickslots[idx];
          if (itemId != null) {
            final item = Items.findById(itemId);
            if (item != null) {
              _playerStats = _playerStats.copyWith(
                currentHealth: (_playerStats.currentHealth + item.healAmount).clamp(0, _playerStats.maxHealth),
                currentEnergy: (_playerStats.currentEnergy + item.energyAmount).clamp(0, _playerStats.maxEnergy),
              );
              _quickslots[idx] = null;
              updatedLog.add("🎒 Used ${item.icon} ${item.name}: +${item.healAmount} HP, +${item.energyAmount} energy.");
              log("Used ${item.icon} ${item.name}: +${item.healAmount} HP, +${item.energyAmount} energy.", LogType.success);
            }
          }
        }
        // Beast still acts
        int incoming = _calculateBeastDamage(beast, hasActiveTelegraph);
        updatedLog.add("${beast.icon} ${beast.name} strikes you for $incoming damage!");
        _playerStats = _playerStats.copyWith(
          currentHealth: (_playerStats.currentHealth - incoming).clamp(0, _playerStats.maxHealth),
        );
        _activeCombat = state.copyWith(
          clearPendingStance: true,
          clearPendingQuickslotIndex: true,
          combatLog: updatedLog,
          currentRoundNumber: state.currentRoundNumber + 1,
          roundsSinceLastTelegraph: hasActiveTelegraph ? 0 : state.roundsSinceLastTelegraph + 1,
          clearActiveTelegraph: true,
          roundDeadline: DateTime.now().add(Duration(milliseconds: combatRoundDurationMs)),
          roundHistory: [
            ...state.roundHistory,
            CombatRound(
              roundNumber: state.currentRoundNumber,
              chosenStance: currentStance,
              playerDamageDealt: 0,
              playerDamageTaken: incoming,
              wasCrit: false,
            ),
          ],
        );
        break;
    }

    // Decrement durability
    if (currentStance == PlayerStance.strike || currentStance == PlayerStance.heavyStrike) {
      if (_equippedWeaponSlot != null) {
        _decrementDurability(_equippedWeaponSlot!, slot: 'weapon');
      }
    }
    if (playerDmgTaken > 0 && _equippedArmorSlot != null) {
      _decrementDurability(_equippedArmorSlot!, slot: 'armor');
    }

    // Check phase transition
    _checkEchoPhaseTransition();

    // Apply Quake passive (energy drain on telegraphed cadence)
    if (_activeCombat != null && _activeCombat!.activePhasePassive == BeastPassive.sourceQuake) {
      quakeCounter += 1;
      final tempLog = List<String>.from(_activeCombat!.combatLog);
      if (quakeCounter % 3 == 2) {
        tempLog.add("⚠️ The ground beneath you trembles violently.");
        log("The ground beneath you trembles violently.", LogType.warning);
      } else if (quakeCounter % 3 == 0) {
        tempLog.add("⚠️ The ground erupts in a quake! You lose 10 energy.");
        log("The ground erupts in a quake! You lose 10 energy.", LogType.warning);
        _playerStats = _playerStats.copyWith(
          currentEnergy: (_playerStats.currentEnergy - 10).clamp(0, _playerStats.maxEnergy),
        );
      }
      _activeCombat = _activeCombat!.copyWith(
        combatLog: tempLog,
      );
    }

    // Write back updated Source mechanics counters to active combat state
    if (_activeCombat != null) {
      _activeCombat = _activeCombat!.copyWith(
        sourceQuakeCounter: quakeCounter,
        sourceSedimentStacks: nextSedimentStacks,
        sourcePollenCounter: pollenCounter,
      );
    }

    // Apply healOnHit passive if active and beast is not defeated
    if (_activeCombat != null &&
        _activeCombat!.beastCurrentHealth > 0 &&
        _activeCombat!.activePhasePassive == BeastPassive.healOnHit) {
      final healed = (_activeCombat!.beastCurrentHealth + 3).clamp(0, beast.maxHealth);
      final updatedLog2 = List<String>.from(_activeCombat!.combatLog);
      updatedLog2.add("💚 The Echo healed 3 HP from its passive vines.");
      _activeCombat = _activeCombat!.copyWith(
        beastCurrentHealth: healed,
        combatLog: updatedLog2,
      );
      log("The Echo healed 3 HP.", LogType.info);
    }

    // Check end conditions
    if (_activeCombat!.beastCurrentHealth <= 0) {
      final victoryLog = List<String>.from(_activeCombat!.combatLog);
      victoryLog.add("🎉 ${beast.name} has been defeated!");
      _activeCombat = _activeCombat!.copyWith(combatLog: victoryLog);
      _onBeastDefeated(beast);
      return;
    }
    if (_playerStats.currentHealth <= 0) {
      final defeatLog = List<String>.from(_activeCombat!.combatLog);
      defeatLog.add("💀 You collapsed from your wounds...");
      _activeCombat = _activeCombat!.copyWith(combatLog: defeatLog);
      _onPlayerDefeated();
      return;
    }

    // Check for telegraph fire next round
    _maybeFireBeastTelegraph();
    notifyListeners();
  }

  int _calculateBeastDamage(Beast beast, bool hasActiveTelegraph) {
    int baseDmg = beast.attackPower - getPlayerDefense();
    if (baseDmg < 1) baseDmg = 1;
    // Apply random variance
    final beastVariance = 0.85 + _random.nextDouble() * 0.30;
    baseDmg = (baseDmg * beastVariance).round();
    if (baseDmg < 1) baseDmg = 1;

    // If a telegraph is active, this round IS the special — apply effect
    if (hasActiveTelegraph) {
      final ability = _activeCombat?.activePhaseAbility ?? beast.ability;
      if (ability != null) {
        switch (ability.effect) {
          case BeastSpecialEffect.bigHit: return baseDmg * 2;
          case BeastSpecialEffect.bigHitStun: return baseDmg * 2;
          default: return baseDmg;
        }
      }
    }
    return baseDmg;
  }

  void _maybeFireBeastTelegraph() {
    if (_activeCombat == null) return;
    final state = _activeCombat!;
    final ability = state.activePhaseAbility ?? state.beast.ability;
    if (ability == null) return;
    
    // enrage (P3) - reduce cooldown
    final effectiveCooldown = (state.activePhasePassive == BeastPassive.enrage)
        ? max(1, ability.cooldownRounds - 1)
        : ability.cooldownRounds;

    // Telegraph fires N-1 rounds in (so on round N, ability triggers)
    if (state.roundsSinceLastTelegraph >= effectiveCooldown - 1) {
      final wasRevealed = state.activeTelegraph?.reveal ?? false;
      _activeCombat = state.copyWith(
        activeTelegraph: BeastTelegraph(
          abilityId: ability.id,
          text: ability.telegraphText,
          reveal: wasRevealed,
        ),
      );
    }
    notifyListeners();
  }

  void _onRoundTimerExpired() {
    if (_activeCombat == null || _activeCombat!.pendingStance != null) return;
    setCombatStance(PlayerStance.strike);
  }

  void _onBeastDefeated(Beast beast) {
    if (beast.id == 'echo_of_wilds') {
      log("The Echo collapses into a brittle husk. A green mote pulses where its heart was — you pluck it free. Carry it home. Burn it where the cartographer keeps his fire.", LogType.worldEvent);
      playSfx('ui_masterwork_complete');
      _unlockAndAdvanceObjective('main_cleanse_hollow', 'echo_wilds_defeated');
    }
    if (beast.id == 'echo_of_stone') {
      log("The Echo cracks open like a geode. A cold crystalline mote slides into your palm. Carry it home. Burn it at the town center.", LogType.worldEvent);
      playSfx('ui_masterwork_complete');
      _unlockAndAdvanceObjective('main_cleanse_vein', 'echo_stone_defeated');
    }
    if (beast.id == 'echo_of_tide') {
      log("The Echo recedes into the surf, leaving a briny mote behind that pulses faintly in your hand. Carry it home. Burn it at the town center.", LogType.worldEvent);
      playSfx('ui_masterwork_complete');
      _unlockAndAdvanceObjective('main_cleanse_tide', 'echo_tide_defeated');
    }
    if (beast.id == 'the_source') {
      _onSourceDefeated();
    }
    if (_playerAction != null) {
      _playerAction = _playerAction!.copyWith(progress: 1.0);
      _completePlayerAction();
    }
  }

  void _onSourceDefeated() {
    // 1. Consume the 3 Cleansing Tokens
    _inventory = _inventory.removeItem('wilds_cleansing_token', 1);
    _inventory = _inventory.removeItem('stone_cleansing_token', 1);
    _inventory = _inventory.removeItem('tide_cleansing_token', 1);

    // 2. Advance quest custom objective
    _unlockAndAdvanceObjective('main_source_convergence', 'source_defeated');

    // 3. Set persistent-in-session victory flag
    setEngineFlag('source_cleanser');

    // 4. Evaluate achievements
    _checkAndUnlockAchievements();

    // 5. Recompute title to apply override
    _recomputeTitle();

    // 6. Post-fight log line
    log('The three lights fall silent. The Source is quieted.', LogType.success);

    // 7. Trigger the You-Win modal
    _pendingYouWinModal = true;
    notifyListeners();
  }

  void _unlockAndAdvanceObjective(String questId, String targetId) {
    for (final quest in List<Quest>.from(_activeQuests)) {
      if (quest.id == questId) {
        for (final obj in quest.objectives) {
          if (obj.targetId == targetId) {
            obj.comingSoon = false;
            obj.currentCount = obj.targetCount;
          }
        }
        _maybeCompleteQuest(quest);
      }
    }
  }

  void _onPlayerDefeated() {
    faint();
  }

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
      final updatedLog = List<String>.from(_activeCombat!.combatLog);
      updatedLog.add("⚠️ [Phase Transition] ${currentPhase.entryNarration}");
      
      int nextSediment = _activeCombat!.sourceSedimentStacks;
      if (currentPhase.passive == BeastPassive.sourcePollenCloud) {
        nextSediment = 0;
      }

      _activeCombat = _activeCombat!.copyWith(
        activePhaseIndex: newIndex,
        activePhaseAbility: currentPhase.ability,
        activePhasePassive: currentPhase.passive,
        sourceSedimentStacks: nextSediment,
        combatLog: updatedLog,
      );
      log(currentPhase.entryNarration, LogType.warning);
      playSfx('ui_info_chime');
    }
  }

  void playSfx(String name) {
    // Audio system not implemented
  }

  void _startCleansingRitual(String breachTag) {
    final task = MasterworkTasks.findById('cleansing_$breachTag');
    if (task == null) return;
    startMasterworkChallenge(task);
  }

  void _onCleansingComplete(String breachTag) {
    setEngineFlag('breach_${breachTag}_cleansed');

    if (!_engineFlags.contains('first_breach_cleansed')) {
      setEngineFlag('first_breach_cleansed');
      // Alternate Coast unlock: if first breach cleansed and coast_unlocked is not in _engineFlags, unlock Coast I, Wharfmaster pier, and offer investigate tide quest
      if (!_engineFlags.contains('coast_unlocked')) {
        _engineFlags.add('coast_unlocked');
        _engineFlags.add('wharfmaster_pier_visible');
        _unlockedZoneIds.add('sundered_coast_1');
        log("🗺️ New Zone Discovered: Sundered Coast I!", LogType.success);
        offerQuest(MainQuests.investigateTide());
      }
    }

    final tokenId = '${breachTag}_cleansing_token';
    final token = Items.findById(tokenId);
    if (token != null) {
      _inventory = _inventory.addItem(token, 1);
      log("Obtained: ${token.icon} ${token.name} x1", LogType.success);
    }

    // Advance cleanse main quest objective
    for (final quest in List<Quest>.from(_activeQuests)) {
      for (final obj in quest.objectives) {
        if (obj.kind == ObjectiveKind.cleanse && obj.targetId == 'breach_$breachTag') {
          obj.currentCount = obj.targetCount;
          obj.comingSoon = false;
        }
      }
      _maybeCompleteQuest(quest);
    }

    // Offer Source Convergence if all three cleansed
    if (_engineFlags.contains('breach_wilds_cleansed') &&
        _engineFlags.contains('breach_stone_cleansed') &&
        _engineFlags.contains('breach_tide_cleansed')) {
      if (!_activeQuests.any((q) => q.id == 'main_source_convergence') &&
          !_completedQuests.any((q) => q.id == 'main_source_convergence')) {
        offerQuest(MainQuests.sourceConvergence());
      }
    }

    _notifyQuestObservers(CustomQuestEvent('breach_cleansed'));
    _updateDailyTaskProgress(CustomQuestEvent('breach_cleansed'));
    _checkAndUnlockAchievements();
    _checkMilestones();
    playSfx('ui_masterwork_complete');
    notifyListeners();
  }

  // Quick-Slot State Management APIs
  void setQuickslot(int index, String? itemId) {
    if (index < 0 || index >= 3) return;
    if (itemId != null) {
      final item = Items.findById(itemId);
      if (item == null || item.type != ItemType.food) return;
    }
    _quickslots[index] = itemId;
    notifyListeners();
  }

  void useQuickslot(int index) {
    if (index < 0 || index >= 3) return;
    final itemId = _quickslots[index];
    if (itemId == null) return;

    if (_activeCombat != null) {
      setCombatStance(PlayerStance.item, quickslotIndex: index);
    } else {
      final item = Items.findById(itemId)!;
      // Deduct item from inventory
      if (!_inventory.hasItem(itemId, 1)) return;
      _inventory = _inventory.removeItem(itemId, 1);

      // Apply cooking multiplier if any (as in eatFood)
      final cookingSkill = _skills[SkillType.cooking];
      double foodMultiplier = 1.0;
      if (cookingSkill != null) {
        foodMultiplier += (cookingSkill.level - 1) * 0.015;
        if (cookingSkill.levelCap > 10) foodMultiplier += 0.15;
        if (cookingSkill.levelCap > 20) foodMultiplier += 0.30;
      }
      int healed = (item.healAmount * foodMultiplier).round();
      int energyRestored = (item.energyAmount * foodMultiplier).round();

      _playerStats = _playerStats.copyWith(
        currentHealth: (_playerStats.currentHealth + healed).clamp(0, _playerStats.maxHealth),
        currentEnergy: (_playerStats.currentEnergy + energyRestored).clamp(0, _playerStats.maxEnergy),
      );
      log("Used ${item.icon} ${item.name}: +$healed HP, +$energyRestored energy.", LogType.success);
      _quickslots[index] = null;
      notifyListeners();
    }
  }

  // Specialization state helpers
  String? specForSkill(SkillType s) => _skillSpecs[s];
  String? subSpecForSkill(SkillType s) => _skillSubSpecs[s];

  // Testing helpers
  @visibleForTesting
  void startBoarHuntForTest() {
    _activeCombat = CombatState(
      beast: Beasts.forestBoar,
      beastCurrentHealth: Beasts.forestBoar.maxHealth,
      playerStartHealth: _playerStats.currentHealth,
      combatLog: const ["Tracked down 🐗 Forest Boar!"],
      roundHistory: const [],
      roundsSinceLastTelegraph: 0,
      activeTelegraph: null,
      pendingStance: null,
      roundDeadline: DateTime.now().add(Duration(milliseconds: combatRoundDurationMs)),
      pendingQuickslotIndex: null,
      currentRoundNumber: 1,
    );
    notifyListeners();
  }

  @visibleForTesting
  void tickRoundTimerForTest(Duration elapsed) {
    if (_activeCombat == null) return;
    _activeCombat = _activeCombat!.copyWith(
      roundDeadline: DateTime.now().subtract(elapsed),
    );
    _onRoundTimerExpired();
  }

  @visibleForTesting
  void setPlayerStatsForTest(PlayerStats stats) {
    _playerStats = stats;
    notifyListeners();
  }

  bool hasInputsForRecipe(Recipe recipe, Map<int, String> slotChoices, {String? modifierItemId, int count = 1}) {
    final Map<String, int> needed = {};
    for (int i = 0; i < recipe.slots.length; i++) {
      final slot = recipe.slots[i];
      final choiceItemId = slotChoices[i] ?? slot.acceptedItems.first.itemId;
      needed[choiceItemId] = (needed[choiceItemId] ?? 0) + slot.quantity * count;
    }
    if (modifierItemId != null) {
      needed[modifierItemId] = (needed[modifierItemId] ?? 0) + count;
    }

    final tempInventory = Map<String, int>.from(
      Map.fromEntries(_inventory.slots.map((slot) => MapEntry(slot.item.id, slot.quantity)))
    );

    for (var entry in needed.entries) {
      final itemId = entry.key;
      final requiredQty = entry.value;
      int available = tempInventory[itemId] ?? 0;
      if (available >= requiredQty) {
        tempInventory[itemId] = available - requiredQty;
      } else {
        // Not enough. Can we substitute driftwood for oak_log?
        if (itemId == 'oak_log') {
          final missing = requiredQty - available;
          final driftwoodAvailable = tempInventory['driftwood'] ?? 0;
          if (driftwoodAvailable >= missing) {
            tempInventory[itemId] = 0;
            tempInventory['driftwood'] = driftwoodAvailable - missing;
          } else {
            return false;
          }
        } else {
          return false;
        }
      }
    }
    return true;
  }

  Map<String, int> consumeInputsForRecipe(Recipe recipe, Map<int, String> slotChoices, {String? modifierItemId, int count = 1}) {
    final Map<String, int> needed = {};
    for (int i = 0; i < recipe.slots.length; i++) {
      final slot = recipe.slots[i];
      final choiceItemId = slotChoices[i] ?? slot.acceptedItems.first.itemId;
      needed[choiceItemId] = (needed[choiceItemId] ?? 0) + slot.quantity * count;
    }
    if (modifierItemId != null) {
      needed[modifierItemId] = (needed[modifierItemId] ?? 0) + count;
    }

    final Map<String, int> consumed = {};
    for (var entry in needed.entries) {
      final itemId = entry.key;
      final qty = entry.value;
      if (itemId == 'oak_log') {
        final driftwoodQty = _inventory.getItemCount('driftwood');
        final driftwoodToConsume = min(qty, driftwoodQty);
        final oakToConsume = qty - driftwoodToConsume;

        if (driftwoodToConsume > 0) {
          _inventory = _inventory.removeItem('driftwood', driftwoodToConsume);
          consumed['driftwood'] = (consumed['driftwood'] ?? 0) + driftwoodToConsume;
        }
        if (oakToConsume > 0) {
          _inventory = _inventory.removeItem('oak_log', oakToConsume);
          consumed['oak_log'] = (consumed['oak_log'] ?? 0) + oakToConsume;
        }
      } else {
        _inventory = _inventory.removeItem(itemId, qty);
        consumed[itemId] = (consumed[itemId] ?? 0) + qty;
      }
    }
    return consumed;
  }

  double calculateRecipeQualityBias(Recipe recipe, Map<String, int> consumedItems) {
    double bias = 0.0;
    final tempConsumed = Map<String, int>.from(consumedItems);
    
    for (final slot in recipe.slots) {
      int neededQty = slot.quantity;
      bool hasSubstitution = false;
      double slotBias = 0.0;

      for (final choice in slot.acceptedItems) {
        final itemId = choice.itemId;
        final available = tempConsumed[itemId] ?? 0;
        if (available > 0) {
          final matched = min(neededQty, available);
          if (slotBias == 0.0) {
            slotBias = choice.qualityBias;
          }
          tempConsumed[itemId] = available - matched;
          neededQty -= matched;
          if (neededQty <= 0) break;
        }
      }

      if (neededQty > 0 && slot.acceptedItems.any((c) => c.itemId == 'oak_log')) {
        final availableDriftwood = tempConsumed['driftwood'] ?? 0;
        if (availableDriftwood > 0) {
          final matched = min(neededQty, availableDriftwood);
          hasSubstitution = true;
          tempConsumed['driftwood'] = availableDriftwood - matched;
          neededQty -= matched;
        }
      }

      if (hasSubstitution) {
        slotBias = (_skillSpecs[SkillType.woodcutting] == 'woodcutting_arborist') ? 0.30 : 0.03;
      }
      bias += slotBias;
    }
    return bias;
  }

  @visibleForTesting
  bool hasInputsForRecipeForTest(Recipe recipe) {
    final Map<int, String> slotChoices = {};
    for (int i = 0; i < recipe.slots.length; i++) {
      slotChoices[i] = recipe.slots[i].acceptedItems.first.itemId;
    }
    return hasInputsForRecipe(recipe, slotChoices);
  }

  @visibleForTesting
  Map<String, int> consumeInputsForRecipeForTest(Recipe recipe) {
    final Map<int, String> slotChoices = {};
    for (int i = 0; i < recipe.slots.length; i++) {
      slotChoices[i] = recipe.slots[i].acceptedItems.first.itemId;
    }
    return consumeInputsForRecipe(recipe, slotChoices);
  }

  @visibleForTesting
  double calculateRecipeQualityBiasForTest(Recipe recipe, Map<String, int> consumedItems) {
    return calculateRecipeQualityBias(recipe, consumedItems);
  }

  void _fireRandomEvent(RandomEvent event) {
    _activeRandomEvent = ActiveRandomEventState(event: event, startedAt: DateTime.now());
    _randomEventStream.add(event);
    notifyListeners();
  }

  @visibleForTesting
  void forceRandomEventForTest(RandomEvent event) => _fireRandomEvent(event);

  void _maybeFireRandomEvent(ZoneAction action) {
    if (_activeRandomEvent != null) return;
    final roll = _random.nextDouble();
    EventCategory? category;
    if (roll < 0.02) category = EventCategory.interruption;
    else if (roll < 0.035) category = EventCategory.discovery;
    else if (roll < 0.045) category = EventCategory.traveler;
    else if (roll < 0.045 + _omenChance()) category = EventCategory.omen;
    else return;

    final eligible = RandomEvents.all.where((e) {
      if (e.category != category) return false;
      if (e.triggerSkills != null && action.requiredSkill != null && !e.triggerSkills!.contains(action.requiredSkill)) return false;
      if (e.triggerZoneTiers != null && !e.triggerZoneTiers!.contains(_currentZone.tier)) return false;
      return true;
    }).toList();

    if (eligible.isEmpty) return;
    final event = eligible[_random.nextInt(eligible.length)];
    _fireRandomEvent(event);
  }

  double _omenChance() {
    int count = 0;
    final tags = <CodexTag>{};
    for (final id in _knownCodexFragmentIds) {
      final f = CodexFragments.findById(id);
      if (f != null && (f.tag == CodexTag.wilds || f.tag == CodexTag.stone || f.tag == CodexTag.tide)) {
        tags.add(f.tag);
      }
    }
    if (_engineFlags.contains('breach_wilds_cleansed')) tags.remove(CodexTag.wilds);
    if (_engineFlags.contains('breach_stone_cleansed')) tags.remove(CodexTag.stone);
    if (_engineFlags.contains('breach_tide_cleansed')) tags.remove(CodexTag.tide);
    count = tags.length;
    return (0.0025 + count * 0.004).clamp(0.0025, 0.015);
  }

  void resolveRandomEvent(int optionIndex) {
    if (_activeRandomEvent == null) return;
    final event = _activeRandomEvent!.event;
    if (optionIndex < 0 || optionIndex >= event.options.length) return;
    final option = event.options[optionIndex];

    if (option.requiredSkill != null) {
      final skill = _skills[option.requiredSkill!];
      if (skill == null || skill.level < option.requiredLevel) return;
    }
    if (option.requiredItemId != null && !_inventory.hasItem(option.requiredItemId!, option.requiredItemCount)) return;

    // Apply costs
    _playerStats = _playerStats.copyWith(
      currentEnergy: (_playerStats.currentEnergy - option.energyCost).clamp(0, _playerStats.maxEnergy),
      currentHealth: (_playerStats.currentHealth - option.healthCost).clamp(0, _playerStats.maxHealth),
      gold: (_playerStats.gold - option.goldCost).clamp(0, 999999),
    );
    if (option.requiredItemId != null) {
      _inventory = _inventory.removeItem(option.requiredItemId!, option.requiredItemCount);
    }

    for (final r in option.rewards) {
      _grantEventReward(r);
    }

    log(option.feedback, LogType.info);
    _activeRandomEvent = null;
    notifyListeners();
  }

  void _grantEventReward(EventReward r) {
    switch (r.kind) {
      case EventRewardKind.item:
        final item = Items.findById(r.targetId!);
        if (item != null) _inventory = _inventory.addItem(item, r.amount);
        break;
      case EventRewardKind.gold:
        _playerStats = _playerStats.copyWith(gold: _playerStats.gold + r.amount);
        break;
      case EventRewardKind.skillXp:
        final skill = SkillType.values.firstWhere((s) => s.name == r.targetId);
        _grantSkillXp(skill, r.amount.toDouble());
        break;
      case EventRewardKind.fragment:
        final tag = CodexTag.values.firstWhere((t) => t.name == r.targetId);
        tryDropFragment(tag, 1.0);
        break;
    }
  }

  void resumeGame() {
    if (_isPaused) {
      _isPaused = false;
      log("Game resumed.", LogType.info);
      notifyListeners();
    }
  }

  @visibleForTesting
  void buildStructureForTest(String zoneId, String structureId) {
    final struct = Structures.findById(structureId);
    if (struct == null) return;
    final stationKey = "$zoneId::$structureId";
    _stationInstances[stationKey] = StationInstance(
      zoneId: zoneId,
      stationId: structureId,
      tier: 1,
      isRuined: false,
      queue: [],
    );
    notifyListeners();
  }

  @visibleForTesting
  void rebuildStationForTest(String zoneId, String stationId) {
    final stationKey = "$zoneId::$stationId";
    final instance = _stationInstances[stationKey];
    if (instance != null) {
      instance.isRuined = false;
    } else {
      _stationInstances[stationKey] = StationInstance(
        zoneId: zoneId,
        stationId: stationId,
        tier: 1,
        isRuined: false,
        queue: [],
      );
    }
    notifyListeners();
  }

  @visibleForTesting
  void startCraftingForTest(Recipe recipe, String stationKey) {
    final Map<int, String> slotChoices = {};
    for (int i = 0; i < recipe.slots.length; i++) {
      slotChoices[i] = recipe.slots[i].acceptedItems.first.itemId;
    }
    final instance = _stationInstances[stationKey];
    if (instance == null) return;
    
    final entry = QueuedCraft(
      recipeId: recipe.id,
      count: 1,
      slotChoices: slotChoices,
      modifierItemId: null,
      consumedItems: const {},
    );
    instance.queue.add(entry);
    _startNextStationCraft(instance);
    _completeStationCraft(instance);
  }

  @visibleForTesting
  double getSpecCraftQualityBiasForTest(Recipe recipe, Item resultItem, String stationId) {
    return _getSpecCraftQualityBias(recipe, resultItem, stationId);
  }

  @visibleForTesting
  void startEchoFightForTest(String beastId) {
    final beast = Beasts.findById(beastId)!;
    _activeCombat = CombatState(
      beast: beast,
      beastCurrentHealth: beast.maxHealth,
      playerStartHealth: _playerStats.currentHealth,
      combatLog: [],
      roundHistory: const [],
      roundsSinceLastTelegraph: 0,
      activeTelegraph: null,
      pendingStance: null,
      roundDeadline: DateTime.now().add(const Duration(seconds: 2)),
      pendingQuickslotIndex: null,
      currentRoundNumber: 1,
      activePhaseIndex: 0,
      activePhaseAbility: beast.phases?.first.ability ?? beast.ability,
      activePhasePassive: beast.phases?.first.passive,
    );
    notifyListeners();
  }

  @visibleForTesting
  void setBeastHpForTest(int hp) {
    if (_activeCombat == null) return;
    _activeCombat = _activeCombat!.copyWith(beastCurrentHealth: hp);
  }

  @visibleForTesting
  void checkEchoPhaseTransitionForTest() => _checkEchoPhaseTransition();

  @visibleForTesting
  void applyEchoPassiveForTest() {
    if (_activeCombat == null || _activeCombat!.activePhasePassive != BeastPassive.healOnHit) return;
    final beast = _activeCombat!.beast;
    final healed = (_activeCombat!.beastCurrentHealth + 3).clamp(0, beast.maxHealth);
    _activeCombat = _activeCombat!.copyWith(beastCurrentHealth: healed);
  }

  @visibleForTesting
  void unlockZoneForTest(String zoneId) => unlockZone(zoneId);

  @visibleForTesting
  void cleanseAllBreachesForTest() {
    setEngineFlag('nexus_unlockable');
    setEngineFlag('breach_wilds_cleansed');
    setEngineFlag('breach_stone_cleansed');
    setEngineFlag('breach_tide_cleansed');
    _unlockedZoneIds.add('whispering_woods_1');
    _unlockedZoneIds.add('darkstone_mine_1');
    _unlockedZoneIds.add('sundered_coast_1');
    final wildsToken = Items.findById('wilds_cleansing_token');
    final stoneToken = Items.findById('stone_cleansing_token');
    final tideToken = Items.findById('tide_cleansing_token');
    if (wildsToken != null) _inventory = _inventory.addItem(wildsToken, 1);
    if (stoneToken != null) _inventory = _inventory.addItem(stoneToken, 1);
    if (tideToken != null) _inventory = _inventory.addItem(tideToken, 1);
    offerQuest(MainQuests.sourceConvergence());
    notifyListeners();
  }

  @visibleForTesting
  void runCombatToVictoryForTest(String beastId) {
    final beast = Beasts.findById(beastId)!;
    final action = _currentZone.actions.firstWhere((a) => a.isCombat && a.beastId == beastId);
    _playerAction = ActiveActionState(
      action: action,
      progress: 0.0,
      durationSeconds: 1.0,
    );
    _activeCombat = CombatState(
      beast: beast,
      beastCurrentHealth: 0,
      playerStartHealth: _playerStats.currentHealth,
      combatLog: [],
      roundHistory: const [],
      roundsSinceLastTelegraph: 0,
      activeTelegraph: null,
      pendingStance: null,
      roundDeadline: DateTime.now().add(const Duration(seconds: 2)),
      pendingQuickslotIndex: null,
      currentRoundNumber: 1,
    );
    _onBeastDefeated(beast);
  }

  @visibleForTesting
  void completeActionForTest(String actionId) {
    final action = _currentZone.actions.firstWhere((a) => a.id == actionId);
    _playerAction = ActiveActionState(
      action: action,
      progress: 1.0,
      durationSeconds: 1.0,
    );
    _completePlayerAction();
  }

  int calculateMaxDurability(Item item, QualityTier? quality, List<String> affixIds) {
    if (item.value == 0) return 0;
    int base;
    switch (quality ?? QualityTier.standard) {
      case QualityTier.crude: base = 75;
      case QualityTier.standard: base = 100;
      case QualityTier.fine: base = 150;
      case QualityTier.masterwork: base = 250;
    }
    if (affixIds.contains('sturdy')) base = (base * 1.5).round();
    return base;
  }

  InventorySlot ensureDurabilityStamped(InventorySlot slot) {
    if (slot.maxDurability == 0 && slot.item.value > 0 &&
        (slot.item.isTool || slot.item.isWeapon || slot.item.isArmor)) {
      final maxDur = calculateMaxDurability(slot.item, slot.quality, slot.affixIds);
      return slot.copyWith(currentDurability: maxDur, maxDurability: maxDur);
    }
    return slot;
  }

  @visibleForTesting
  int calculateMaxDurabilityForTest(Item item, QualityTier? quality, List<String> affixIds) =>
      calculateMaxDurability(item, quality, affixIds);

  final Set<String> _lowDurabilityWarned = {};

  void _decrementDurability(InventorySlot equipped, {required String slot, SkillType? skill}) {
    if (equipped.maxDurability == 0) return;
    final newDur = (equipped.currentDurability - 1).clamp(0, equipped.maxDurability);
    final updated = equipped.copyWith(currentDurability: newDur);

    switch (slot) {
      case 'tool':
        _equippedToolSlots[skill!] = updated;
        break;
      case 'weapon':
        _equippedWeaponSlot = updated;
        break;
      case 'armor':
        _equippedArmorSlot = updated;
        break;
    }

    final pct = newDur / equipped.maxDurability;
    if (pct <= 0.25 && !_lowDurabilityWarned.contains(equipped.item.id)) {
      _lowDurabilityWarned.add(equipped.item.id);
      log("⚠️ ${equipped.item.icon} ${equipped.item.name} is wearing thin (${newDur}/${equipped.maxDurability}).", LogType.warning);
      // AudioEngine mock call or no-op since no audio is present
    }
    notifyListeners();
  }

  @visibleForTesting
  void equipForTest(Item item, SkillType skill) {
    final maxDur = calculateMaxDurability(item, QualityTier.standard, []);
    _equippedToolSlots[skill] = InventorySlot(
      item: item,
      quantity: 1,
      quality: QualityTier.standard,
      affixIds: [],
      currentDurability: maxDur,
      maxDurability: maxDur,
    );
  }

  @visibleForTesting
  void equipWeaponForTest(Item item) {
    final maxDur = calculateMaxDurability(item, QualityTier.standard, []);
    _equippedWeaponSlot = InventorySlot(
      item: item,
      quantity: 1,
      quality: QualityTier.standard,
      affixIds: [],
      currentDurability: maxDur,
      maxDurability: maxDur,
    );
  }

  @visibleForTesting
  void equipArmorForTest(Item item) {
    final maxDur = calculateMaxDurability(item, QualityTier.standard, []);
    _equippedArmorSlot = InventorySlot(
      item: item,
      quantity: 1,
      quality: QualityTier.standard,
      affixIds: [],
      currentDurability: maxDur,
      maxDurability: maxDur,
    );
  }

  @visibleForTesting
  void completeGatherActionForTest(SkillType skill) {
    final tool = _equippedToolSlots[skill];
    if (tool != null) {
      _decrementDurability(tool, slot: 'tool', skill: skill);
    }
  }

  @visibleForTesting
  void runCombatRoundForTest(PlayerStance stance) {
    if (stance == PlayerStance.strike || stance == PlayerStance.heavyStrike) {
      if (_equippedWeaponSlot != null) {
        _decrementDurability(_equippedWeaponSlot!, slot: 'weapon');
      }
    }
  }

  @visibleForTesting
  void simulateCombatDamageForTest({required int playerDmgTaken}) {
    if (playerDmgTaken > 0 && _equippedArmorSlot != null) {
      _decrementDurability(_equippedArmorSlot!, slot: 'armor');
    }
  }

  bool isSlotWorn(InventorySlot? slot) {
    if (slot == null || slot.maxDurability == 0) return false;
    return slot.currentDurability <= 0;
  }

  @visibleForTesting
  void setEquippedWeaponForTest(InventorySlot slot) {
    _equippedWeaponSlot = slot;
  }

  @visibleForTesting
  void setEquippedArmorForTest(InventorySlot slot) {
    _equippedArmorSlot = slot;
  }

  @visibleForTesting
  void forceEquippedDurabilityForTest(SkillType skill, int newDur) {
    final tool = _equippedToolSlots[skill]!;
    _equippedToolSlots[skill] = tool.copyWith(currentDurability: newDur);
  }

  @visibleForTesting
  List<LogEntry> get logsForTest => _logs;

  void _setEquippedSlot(String slot, InventorySlot updated, {SkillType? skill}) {
    switch (slot) {
      case 'tool':
        _equippedToolSlots[skill!] = updated;
        break;
      case 'weapon':
        _equippedWeaponSlot = updated;
        break;
      case 'armor':
        _equippedArmorSlot = updated;
        break;
    }
  }

  Map<String, int> calculateRepairCost(InventorySlot slot) {
    final recipe = Recipes.findByResultItemId(slot.item.id);
    if (recipe == null) return {};
    return recipe.inputs.map((id, qty) => MapEntry(id, max(1, (qty * 0.25).ceil())));
  }

  bool canRepairWithMaterials(InventorySlot slot) {
    final cost = calculateRepairCost(slot);
    if (cost.isEmpty) return false;
    for (final entry in cost.entries) {
      if (!_inventory.hasItem(entry.key, entry.value)) return false;
    }
    return true;
  }

  void repairWithMaterials(InventorySlot equipped, {required String slot, SkillType? skill}) {
    final cost = calculateRepairCost(equipped);
    if (cost.isEmpty) return;
    for (final entry in cost.entries) {
      if (!_inventory.hasItem(entry.key, entry.value)) return;
    }
    for (final entry in cost.entries) {
      _inventory = _inventory.removeItem(entry.key, entry.value);
    }
    final updated = equipped.copyWith(currentDurability: equipped.maxDurability);
    _setEquippedSlot(slot, updated, skill: skill);
    log("Repaired ${equipped.item.icon} ${equipped.item.name} at the Crafting Bench.", LogType.success);
    _lowDurabilityWarned.remove(equipped.item.id);
    _anyRepairThisRun = true;
    _engineFlags.add('ach_first_repair');
    _checkAndUnlockAchievements();
    notifyListeners();
  }

  int calculateRepairGoldCost(InventorySlot slot) {
    if (slot.maxDurability == 0) return 0;
    final damagePct = (slot.maxDurability - slot.currentDurability) / slot.maxDurability;
    return max(1, (slot.item.value * 0.25 * damagePct).ceil());
  }

  void repairWithGold(InventorySlot equipped, {required String slot, SkillType? skill}) {
    final cost = calculateRepairGoldCost(equipped);
    if (_playerStats.gold < cost) return;
    _playerStats = _playerStats.copyWith(gold: _playerStats.gold - cost);
    final updated = equipped.copyWith(currentDurability: equipped.maxDurability);
    _setEquippedSlot(slot, updated, skill: skill);
    log("Repaired ${equipped.item.icon} ${equipped.item.name} (-$cost gold).", LogType.success);
    _lowDurabilityWarned.remove(equipped.item.id);
    _anyRepairThisRun = true;
    _engineFlags.add('ach_first_repair');
    _checkAndUnlockAchievements();
    notifyListeners();
  }

  @visibleForTesting
  Map<String, int> calculateRepairCostForTest(InventorySlot slot) => calculateRepairCost(slot);

  @visibleForTesting
  int calculateRepairGoldCostForTest(InventorySlot slot) => calculateRepairGoldCost(slot);

  @visibleForTesting
  bool isFragmentPoolOpenForTest(CodexTag tag) => _isFragmentPoolOpen(tag);

  @visibleForTesting
  Set<String> get firedMilestoneIdsForTest => firedMilestoneIds;

  void _generateSessionSpawns() {
    if (_reagentSpawns.isNotEmpty) return;

    final rng = Random();
    final count = rng.nextInt(3) + 2; // 2 to 4 spawns

    final reagents = [
      const ReagentSpawn(
        itemId: 'moonpetal',
        noticeText: 'A glowing Moonpetal blossom catches your eye in the brush.',
        requiredSkill: SkillType.herbalism,
        zoneId: '',
      ),
      const ReagentSpawn(
        itemId: 'spirit_sap',
        noticeText: 'A rare glob of glowing Spirit Sap clings to a nearby trunk.',
        requiredSkill: SkillType.woodcutting,
        zoneId: '',
      ),
      const ReagentSpawn(
        itemId: 'hollow_bone',
        noticeText: 'A weightless, ancient Hollow Bone lies near the path.',
        requiredSkill: SkillType.combat,
        zoneId: '',
      ),
      const ReagentSpawn(
        itemId: 'sea_tear',
        noticeText: 'A shimmering, frozen Sea-Tear glints in a tidal pool.',
        requiredSkill: SkillType.wayfinding,
        zoneId: '',
      ),
      const ReagentSpawn(
        itemId: 'coalblood',
        noticeText: 'A pool of dark, viscous Coalblood seeps from a rock fissure.',
        requiredSkill: SkillType.mining,
        zoneId: '',
      ),
      const ReagentSpawn(
        itemId: 'wisp_light',
        noticeText: 'A flickering Wisp-Light dances near the ancient inscriptions.',
        requiredSkill: SkillType.lore,
        zoneId: '',
      ),
    ];

    final biomesMap = {
      'moonpetal': ['whispering_woods_1', 'whispering_woods_2'],
      'spirit_sap': ['whispering_woods_1', 'whispering_woods_2'],
      'hollow_bone': ['whispering_woods_2', 'darkstone_mine_1', 'darkstone_mine_2'],
      'sea_tear': ['sundered_coast_1', 'sundered_coast_2'],
      'coalblood': ['darkstone_mine_1', 'darkstone_mine_2'],
      'wisp_light': ['whispering_woods_3', 'darkstone_mine_3', 'sundered_coast_3'],
    };

    final potentialFallbackZones = _unlockedZoneIds.where((id) => id != 'town_square').toList();
    if (potentialFallbackZones.isEmpty) return; // Can't spawn if only town square is unlocked

    for (int i = 0; i < count; i++) {
      final baseReagent = reagents[rng.nextInt(reagents.length)];
      final biomes = biomesMap[baseReagent.itemId] ?? [];
      final validUnlockedBiomes = biomes.where((id) => _unlockedZoneIds.contains(id)).toList();

      String chosenZoneId;
      if (validUnlockedBiomes.isNotEmpty) {
        chosenZoneId = validUnlockedBiomes[rng.nextInt(validUnlockedBiomes.length)];
      } else {
        chosenZoneId = potentialFallbackZones[rng.nextInt(potentialFallbackZones.length)];
      }

      _reagentSpawns.add(baseReagent.copyWith(zoneId: chosenZoneId));
    }
  }

  List<ReagentSpawn> getUncollectedSpawnsForZone(String zoneId) {
    return _reagentSpawns.where((s) => s.zoneId == zoneId && !s.isCollected).toList();
  }

  void collectReagentSpawn(ReagentSpawn spawn) {
    if (spawn.isCollected) {
      log("This reagent has already been collected!", LogType.error);
      return;
    }
    if (_playerStats.currentEnergy < spawn.energyCost) {
      log("Not enough energy to collect ${Items.findById(spawn.itemId)?.name ?? 'reagent'}!", LogType.error);
      return;
    }
    final skillState = _skills[spawn.requiredSkill];
    if (skillState == null || skillState.level < spawn.requiredLevel) {
      log("Requires ${spawn.requiredSkill.name} level ${spawn.requiredLevel} to collect this!", LogType.error);
      return;
    }
    if (_inventory.isFull) {
      log("Inventory full! Cannot collect ${Items.findById(spawn.itemId)?.name ?? 'reagent'}.", LogType.error);
      return;
    }

    _playerStats = _playerStats.copyWith(currentEnergy: _playerStats.currentEnergy - spawn.energyCost);

    final idx = _reagentSpawns.indexWhere((s) => s.itemId == spawn.itemId && s.zoneId == spawn.zoneId && !s.isCollected);
    if (idx != -1) {
      _reagentSpawns[idx] = spawn.copyWith(isCollected: true);
    }

    final item = Items.findById(spawn.itemId)!;
    _inventory = _inventory.addItem(item, 1);

    log("Gathered ${item.icon} ${item.name} using ${spawn.requiredSkill.name}.", LogType.success);
    notifyListeners();
  }

  // --- Spec 6a & 6b helper methods ---

  void _grantSkillXp(SkillType type, double amount) {
    final playerXpGain = (amount * 0.2).round();
    if (playerXpGain > 0) {
      _addPlayerXp(playerXpGain);
    }

    final oldSkill = _skills[type]!;
    final newSkill = oldSkill.addXp(amount);
    _skills[type] = newSkill;

    if (newSkill.level > oldSkill.level) {
      final skillNameFormatted = type.name[0].toUpperCase() + type.name.substring(1);
      log("Level Up! Your $skillNameFormatted is now Level ${newSkill.level}!", LogType.levelUp);
      _levelUpController.add(LevelUpEvent(type, newSkill.level));
      _recomputeTitle();
    } else if (newSkill.isGated && !oldSkill.isGated) {
      log("Limit Reached! Level ${newSkill.levelCap} Masterwork Trial is now unlocked. Check the Skills tab.", LogType.warning);
    }

    _checkAndUnlockAchievements();
  }

  void grantSkillXpForTesting(SkillType type, double amount) {
    _grantSkillXp(type, amount);
  }

  void addEngineFlagForTesting(String flag) {
    _engineFlags.add(flag);
    _checkAndUnlockAchievements();
    notifyListeners();
  }

  void earnAchievementForTesting(String id) {
    _earnedAchievementIds.add(id);
    _checkAndUnlockAchievements();
    notifyListeners();
  }

  void _addPlayerXp(int amount) {
    final prevLvl = _playerStats.playerLevel;
    final res = PlayerProgression.applyXp(_playerStats.playerLevel, _playerStats.playerXp, amount);
    _playerStats = _playerStats.copyWith(
      playerLevel: res.level,
      playerXp: res.xp,
    );

    if (res.didLevelUp) {
      for (int l = prevLvl + 1; l <= res.level; l++) {
        log("🌟 Player Leveled Up! Level $l reached!", LogType.levelUp);
      }
      _checkAndUnlockAchievements();
    }
  }

  void _recomputeTitle() {
    if (_engineFlags.contains('source_cleanser')) {
      if (_playerStats.title != 'Source Cleanser') {
        _playerStats = _playerStats.copyWith(title: 'Source Cleanser');
        log("🏷️ Earned Title: Source Cleanser!", LogType.success);
      }
      return;
    }

    final title = TitleResolver.resolve(_skills);
    if (_playerStats.title != title) {
      _playerStats = _playerStats.copyWith(title: title);
      log("🏷️ Earned Title: $title!", LogType.success);
    }
  }

  void _checkAndUnlockAchievements() {
    final newlyUnlocked = AchievementEngine.checkAll(this);
    if (newlyUnlocked.isNotEmpty) {
      for (final id in newlyUnlocked) {
        _earnedAchievementIds.add(id);
        final ach = Achievements.all.firstWhere((a) => a.id == id);
        log("🏆 Achievement Unlocked: ${ach.name}! ${ach.description}", LogType.success);
      }
      notifyListeners();
    }
  }

  MerchantReputation getMerchantReputation(String merchantId) {
    return _merchantRep.putIfAbsent(merchantId, () => MerchantReputation(merchantId: merchantId));
  }

  bool isGiftClaimed(String merchantId) {
    return _claimedGifts.contains(merchantId);
  }

  void claimHonoredFriendGift(String merchantId) {
    if (_claimedGifts.contains(merchantId)) return;
    _claimedGifts.add(merchantId);

    switch (merchantId) {
      case 'cedric':
        unlockRandomBlueprintRecipe();
        break;
      case 'hilda':
        final learnable = Recipes.all.where((r) => r.rarity != RecipeRarity.common && !_knownRecipeIds.contains(r.id)).toList();
        if (learnable.isNotEmpty) {
          final selected = learnable[_random.nextInt(learnable.length)];
          _knownRecipeIds.add(selected.id);
          log("📘 Hilda gifted you a rare blueprint: ${selected.name}!", LogType.success);
        } else {
          _playerStats = _playerStats.copyWith(gold: _playerStats.gold + 100);
          log("Hilda gifted you 100 Gold since you know all recipes!", LogType.success);
        }
        break;
      case 'pippin':
        _inventory = _inventory.addItem(Items.wispLight, 1);
        log("🧪 Pippin gifted you a Wisp-Light!", LogType.success);
        break;
      case 'silas':
        final unread = CodexFragments.all.where((f) => f.tag == CodexTag.oldEmpire && !_knownCodexFragmentIds.contains(f.id)).toList();
        if (unread.isNotEmpty) {
          final selected = unread[_random.nextInt(unread.length)];
          _grantFragment(selected);
          _notifyQuestObservers(CodexFragmentReadEvent(selected.id));
          log("📖 Silas gifted you an ancient Old Empire Codex fragment: ${selected.title}!", LogType.success);
        } else {
          _playerStats = _playerStats.copyWith(gold: _playerStats.gold + 100);
          log("Silas gifted you 100 Gold since you read all Old Empire fragments!", LogType.success);
        }
        break;
      case 'maeve':
        final tools = [Items.copperAxe, Items.copperPickaxe, Items.reinforcedGloves];
        final tool = tools[_random.nextInt(tools.length)];
        final maxDur = calculateMaxDurability(tool, QualityTier.standard, const []);
        _inventory = _inventory.addItem(tool, 1, QualityTier.standard, const [], maxDur, maxDur);
        log("🏹 Maeve gifted you a Fine tool: ${tool.name}!", LogType.success);
        break;
      case 'bram':
        _inventory = _inventory.addItem(Items.bakedPotato, 5);
        log("🍺 Bram gifted you 5 Baked Potatoes!", LogType.success);
        break;
    }
    _checkAndUnlockAchievements();
    notifyListeners();
  }

  void setActiveMerchantById(String merchantId) {
    final idx = _shopState.activeMerchants.indexWhere((m) => m.id == merchantId);
    if (idx != -1) {
      _shopState = _shopState.copyWith(activeMerchantIndex: idx);
    } else {
      final merchant = Merchant.all.firstWhere((m) => m.id == merchantId, orElse: () => Merchant.bram);
      final newActive = List<Merchant>.from(_shopState.activeMerchants)..add(merchant);
      _shopState = _shopState.copyWith(
        activeMerchants: newActive,
        activeMerchantIndex: newActive.length - 1,
      );
    }
    _maybeFireEndgameAmbient('focus_merchant', "The shopkeeper hesitates before naming a price. 'For the one who quieted the Source,' they say. 'On the house, this time.'");
    notifyListeners();
  }

  void addMerchantReputation(String merchantId, int amount) {
    final current = getMerchantReputation(merchantId);
    if (current.sessionReputation >= 200) {
      return;
    }
    final allowed = (200 - current.sessionReputation).clamp(0, amount);
    if (allowed <= 0) return;

    final updated = current.copyWith(
      totalReputation: current.totalReputation + allowed,
      sessionReputation: current.sessionReputation + allowed,
    );
    _merchantRep[merchantId] = updated;

    _checkReputationFragmentUnlocks(merchantId, current.tier, updated.tier);
    _checkAndUnlockAchievements();
    notifyListeners();
  }

  void _checkReputationFragmentUnlocks(String merchantId, ReputationTier oldTier, ReputationTier newTier) {
    if (oldTier != ReputationTier.swornCompanion && newTier == ReputationTier.swornCompanion) {
      final fragmentId = 'companion_$merchantId';
      unlockFragmentDirectly(fragmentId);
    }
  }

  void unlockFragmentDirectly(String fragmentId) {
    if (_knownCodexFragmentIds.contains(fragmentId)) return;
    final fragment = CodexFragments.findById(fragmentId);
    if (fragment != null) {
      _grantFragment(fragment);
      _notifyQuestObservers(CodexFragmentReadEvent(fragmentId));
    }
  }

  void _generateTodaysTasks() {
    if (_todaysTasks.isNotEmpty) return;

    final eligibleTemplates = DailyTasks.all.where((t) {
      if (t.requiredSkill == null) return true;
      final skillLevel = _skills[t.requiredSkill]?.level ?? 1;
      return skillLevel >= t.requiredLevel;
    }).toList();

    if (eligibleTemplates.isEmpty) return;

    eligibleTemplates.shuffle(_random);
    final selected = eligibleTemplates.take(3).toList();
    _todaysTasks = selected.map((t) {
      return DailyTask(
        id: t.id,
        name: t.name,
        category: t.category,
        targetId: t.targetId,
        targetCount: t.targetCount,
        rewardGold: t.rewardGold,
      );
    }).toList();

    // Reset session reputation for all merchants when daily tasks refresh (new day)
    for (final id in _merchantRep.keys) {
      _merchantRep[id] = _merchantRep[id]!.copyWith(sessionReputation: 0);
    }

    _dailyBonusClaimed = false;
    log("📝 Check the Daily Notice Board for today's requests!", LogType.info);
  }

  void forceGenerateDailyTasksForTesting() {
    _todaysTasks = [];
    _generateTodaysTasks();
  }

  void _updateDailyTaskProgress(QuestEvent event) {
    if (_todaysTasks.isEmpty) return;
    bool changed = false;
    for (int i = 0; i < _todaysTasks.length; i++) {
      final task = _todaysTasks[i];
      if (task.isCompleted) continue;

      bool matches = false;
      int increment = event.count;

      switch (task.category) {
        case DailyTaskCategory.gather:
          matches = event is ItemGatheredEvent && event.itemId == task.targetId;
          break;
        case DailyTaskCategory.hunt:
          matches = event is BeastDefeatedEvent && event.beastId == task.targetId;
          break;
        case DailyTaskCategory.visit:
          matches = event is ZoneVisitedEvent && event.zoneId == task.targetId;
          break;
        case DailyTaskCategory.craft:
          matches = event is ItemCraftedEvent && (task.targetId == 'any' || event.recipeId == task.targetId);
          break;
        case DailyTaskCategory.codex:
          matches = event is CodexFragmentReadEvent;
          break;
        case DailyTaskCategory.cleanse:
          matches = event is CustomQuestEvent && event.eventId == task.targetId;
          break;
      }

      if (matches) {
        final newCount = min(task.targetCount, task.currentCount + increment);
        if (newCount != task.currentCount) {
          _todaysTasks[i] = task.copyWith(
            currentCount: newCount,
            isCompleted: newCount >= task.targetCount,
          );
          changed = true;
          if (_todaysTasks[i].isCompleted) {
            log("📝 Daily Task Completed: ${task.name}!", LogType.success);
          }
        }
      }
    }
    if (changed) {
      _checkAndUnlockAchievements();
      notifyListeners();
    }
  }

  void claimDailyTaskReward(String taskId) {
    final idx = _todaysTasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final task = _todaysTasks[idx];
    if (!task.isCompleted || task.isClaimed) return;

    _todaysTasks[idx] = task.copyWith(isClaimed: true);
    _playerStats = _playerStats.copyWith(gold: _playerStats.gold + task.rewardGold);
    _lifetimeGold += task.rewardGold;
    log("💰 Claimed ${task.rewardGold}g reward for completing daily task: ${task.name}.", LogType.success);

    _checkAndUnlockAchievements();
    notifyListeners();
  }

  void claimDailyBonus() {
    if (_todaysTasks.isEmpty || !_todaysTasks.every((t) => t.isCompleted)) return;
    if (_dailyBonusClaimed) return;

    _dailyBonusClaimed = true;
    _playerStats = _playerStats.copyWith(gold: _playerStats.gold + 120);
    _lifetimeGold += 120;
    log("🎁 Claimed Daily Notice Board Bonus! +120 Gold.", LogType.success);

    final rolledBlueprint = _random.nextDouble() < 0.05;
    if (rolledBlueprint) {
      unlockRandomBlueprintRecipe();
    } else {
      log("No blueprint found in the notice board rewards today.", LogType.info);
    }

    _checkAndUnlockAchievements();
    notifyListeners();
  }

  void unlockRandomBlueprintRecipe() {
    final learnable = Recipes.all.where((r) => r.rarity != RecipeRarity.common && !_knownRecipeIds.contains(r.id)).toList();
    if (learnable.isNotEmpty) {
      final selected = learnable[_random.nextInt(learnable.length)];
      _knownRecipeIds.add(selected.id);
      log("📘 Discovered Recipe Blueprint: ${selected.name}!", LogType.success);
      _checkAndUnlockAchievements();
      notifyListeners();
    } else {
      log("You have already unlocked all available recipe blueprints!", LogType.info);
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
    _puzzleResultController.close();
    super.dispose();
  }
}

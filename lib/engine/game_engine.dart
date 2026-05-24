import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/player_stats.dart';
import '../models/skill.dart';
import '../models/item.dart';
import '../models/inventory.dart';
import '../models/zone.dart';
import '../models/masterwork.dart';
import '../models/recipe.dart';
import '../models/structure.dart';
import '../models/beast.dart';
import 'activity_log.dart';

class ActiveActionState {
  final ZoneAction? action;
  final Recipe? recipe;
  final Structure? structure;
  final String? targetZoneId;
  final double progress; // 0.0 to 1.0
  final double durationSeconds;

  const ActiveActionState({
    this.action,
    this.recipe,
    this.structure,
    this.targetZoneId,
    required this.progress,
    required this.durationSeconds,
  });

  ActiveActionState copyWith({
    ZoneAction? action,
    Recipe? recipe,
    Structure? structure,
    String? targetZoneId,
    double? progress,
    double? durationSeconds,
  }) {
    return ActiveActionState(
      action: action ?? this.action,
      recipe: recipe ?? this.recipe,
      structure: structure ?? this.structure,
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

class GameEngine extends ChangeNotifier {
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

  int _maxEquipmentSlots = 1;
  final Map<SkillType, Item> _equippedTools = {};
  Item? _equippedWeapon;
  Item? _equippedArmor;
  CombatState? _activeCombat;

  ActiveActionState? _activeAction;
  Timer? _actionTimer;

  MasterworkRunState? _activeMasterwork;

  final Random _random = Random();
  final Map<String, List<String>> _zoneStructures = {};

  GameEngine() {
    // Initialize skills
    for (var type in SkillType.values) {
      _skills[type] = SkillState.initial(type);
    }
    // Add initial logs
    log("Welcome to Elaria RPG! Set off, gather resources, and level up.", LogType.info);
    log("Tavern rumor: Complete a Masterwork Trial every 10 levels to break your limits.", LogType.info);
  }

  // Getters
  PlayerStats get playerStats => _playerStats;
  set playerStats(PlayerStats val) {
    _playerStats = val;
    notifyListeners();
  }

  Item? get equippedWeapon => _equippedWeapon;
  Item? get equippedArmor => _equippedArmor;
  CombatState? get activeCombat => _activeCombat;

  int getPlayerAttack() {
    int base = 5;
    if (_equippedWeapon != null) {
      base += _equippedWeapon!.attackPower;
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
    if (_equippedArmor != null) {
      base += _equippedArmor!.defense;
    }
    // Combat Perk 10 (Slayer's Might): +1 Defense
    final combatSkill = _skills[SkillType.combat];
    if (combatSkill != null && combatSkill.levelCap > 10) {
      base += 1;
    }
    return base;
  }

  void equipWeapon(Item item) {
    if (item.type != ItemType.weapon) return;
    if (!_inventory.hasItem(item.id, 1)) return;

    // Remove from inventory
    _inventory = _inventory.removeItem(item.id, 1);

    // Unequip current weapon if any
    if (_equippedWeapon != null) {
      if (_inventory.isFull) {
        log("Inventory is full! Cannot unequip current weapon.", LogType.error);
        _inventory = _inventory.addItem(item, 1);
        return;
      }
      _inventory = _inventory.addItem(_equippedWeapon!, 1);
    }

    _equippedWeapon = item;
    log("Equipped ⚔️ ${item.name} (Attack +${item.attackPower}).", LogType.success);
    notifyListeners();
  }

  void unequipWeapon() {
    if (_equippedWeapon == null) return;
    if (_inventory.isFull) {
      log("Inventory is full! Cannot unequip current weapon.", LogType.error);
      return;
    }

    final tool = _equippedWeapon!;
    _equippedWeapon = null;
    _inventory = _inventory.addItem(tool, 1);
    log("Unequipped ⚔️ ${tool.name}.", LogType.info);
    notifyListeners();
  }

  void equipArmor(Item item) {
    if (item.type != ItemType.armor) return;
    if (!_inventory.hasItem(item.id, 1)) return;

    // Remove from inventory
    _inventory = _inventory.removeItem(item.id, 1);

    // Unequip current armor if any
    if (_equippedArmor != null) {
      if (_inventory.isFull) {
        log("Inventory is full! Cannot unequip current armor.", LogType.error);
        _inventory = _inventory.addItem(item, 1);
        return;
      }
      _inventory = _inventory.addItem(_equippedArmor!, 1);
    }

    _equippedArmor = item;
    log("Equipped 🛡️ ${item.name} (Defense +${item.defense}).", LogType.success);
    notifyListeners();
  }

  void unequipArmor() {
    if (_equippedArmor == null) return;
    if (_inventory.isFull) {
      log("Inventory is full! Cannot unequip current armor.", LogType.error);
      return;
    }

    final armor = _equippedArmor!;
    _equippedArmor = null;
    _inventory = _inventory.addItem(armor, 1);
    log("Unequipped 🛡️ ${armor.name}.", LogType.info);
    notifyListeners();
  }

  Map<SkillType, SkillState> get skills => _skills;
  
  Inventory get inventory => _inventory;
  set inventory(Inventory val) {
    _inventory = val;
    notifyListeners();
  }

  Map<String, List<String>> get zoneStructures => _zoneStructures;

  List<String> getBuiltStructuresForZone(String zoneId) {
    return _zoneStructures[zoneId] ?? [];
  }

  bool hasStructureInZone(String zoneId, String structureId) {
    return _zoneStructures[zoneId]?.contains(structureId) ?? false;
  }

  int get maxEquipmentSlots => _maxEquipmentSlots;
  Map<SkillType, Item> get equippedTools => _equippedTools;

  void equipTool(Item item) {
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
    if (!_equippedTools.containsKey(skill) && _equippedTools.length >= _maxEquipmentSlots) {
      log("All equipment slots full ($_maxEquipmentSlots/$_maxEquipmentSlots)! Unequip a tool first or upgrade your backpack.", LogType.error);
      return;
    }

    cancelAction();

    // Remove tool from inventory
    _inventory = _inventory.removeItem(item.id, 1);

    // Save previous tool if any
    final oldTool = _equippedTools[skill];

    // Equip new tool
    _equippedTools[skill] = item;
    log("Equipped ${item.icon} ${item.name} for ${skill.name}.", LogType.success);

    // Return previous tool to inventory
    if (oldTool != null) {
      _inventory = _inventory.addItem(oldTool, 1);
      log("Returned ${oldTool.icon} ${oldTool.name} to inventory.", LogType.info);
    }

    notifyListeners();
  }

  void unequipTool(SkillType skill) {
    final tool = _equippedTools[skill];
    if (tool == null) {
      log("No tool equipped for ${skill.name}.", LogType.error);
      return;
    }

    if (_inventory.isFull) {
      log("Inventory full! Free some slots first to unequip ${tool.name}.", LogType.error);
      return;
    }

    cancelAction();

    _equippedTools.remove(skill);
    _inventory = _inventory.addItem(tool, 1);
    log("Unequipped ${tool.icon} ${tool.name} for ${skill.name}.", LogType.success);

    notifyListeners();
  }

  Zone get currentZone => _currentZone;
  Set<String> get unlockedZoneIds => _unlockedZoneIds;
  Map<String, double> get explorationProgress => _explorationProgress;
  List<LogEntry> get logs => List.unmodifiable(_logs);
  ActiveActionState? get activeAction => _activeAction;
  MasterworkRunState? get activeMasterwork => _activeMasterwork;


  List<Recipe> getAvailableRecipes() {
    return [
      ...Recipes.all,
      Recipes.getBackpackRecipe(_inventory.capacity),
    ];
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
    notifyListeners();
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

    final tool = _equippedTools[type];
    if (tool != null) {
      bonus += tool.speedBonus;
    }
    return bonus;
  }

  /// Get total success chance bonus (combines level-based and equipped tool success bonuses)
  double getSkillSuccessBonus(SkillType type) {
    final skill = _skills[type];
    if (skill == null) return 0.0;

    double bonus = (skill.level - 1) * 0.01; // +1% per level above 1
    
    final tool = _equippedTools[type];
    if (tool != null) {
      bonus += tool.successBonus;
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

    return max(1, cost.round());
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

    _activeAction = ActiveActionState(
      action: action,
      progress: 0.0,
      durationSeconds: duration,
    );
    notifyListeners();

    // Start 100ms updates
    const tickMs = 100;
    final totalTicks = (duration * 1000) / tickMs;
    int currentTick = 0;

    _actionTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      currentTick++;
      double progress = currentTick / totalTicks;

      if (progress >= 1.0) {
        if (_activeCombat != null) {
          // Combat round completes
          _executeCombatRound(action);
          
          if (_activeCombat!.beastCurrentHealth <= 0) {
            // Beast is dead! End action.
            _activeAction = _activeAction!.copyWith(progress: 1.0);
            timer.cancel();
            _completeAction();
          } else if (_playerStats.currentHealth <= 0) {
            // Player is dead! Faint.
            timer.cancel();
            faint();
          } else {
            // Both alive: reset tick for next round
            currentTick = 0;
            _activeAction = _activeAction!.copyWith(progress: 0.0);
            notifyListeners();
          }
        } else {
          // Normal action completes
          _activeAction = _activeAction!.copyWith(progress: 1.0);
          timer.cancel();
          _completeAction();
        }
      } else {
        _activeAction = _activeAction!.copyWith(progress: progress);
        notifyListeners();
      }
    });
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

  bool canCraftRecipe(Recipe recipe) {
    if (_currentZone.id == 'town_square') return true;
    final structures = _zoneStructures[_currentZone.id] ?? [];
    if (recipe.requiredSkill == SkillType.crafting || recipe.requiredSkill == SkillType.lore) {
      return structures.contains('crafting_bench');
    }
    if (recipe.requiredSkill == SkillType.cooking || recipe.requiredSkill == SkillType.herbalism) {
      return structures.contains('field_kitchen');
    }
    return false;
  }

  void startCrafting(Recipe recipe) {
    // 0. Location check: Crafting/cooking only allowed in Town Square or with appropriate local structure
    if (!canCraftRecipe(recipe)) {
      final structureName = (recipe.requiredSkill == SkillType.crafting || recipe.requiredSkill == SkillType.lore)
          ? 'Crafting Bench'
          : 'Field Kitchen';
      log("You need a $structureName to craft or cook here!", LogType.error);
      return;
    }

    // 1. Skill requirement check
    final skill = _skills[recipe.requiredSkill];
    if (skill == null || skill.level < recipe.requiredLevel) {
      log("Requirements not met: Needs Level ${recipe.requiredLevel} ${recipe.requiredSkill.name}.", LogType.error);
      return;
    }

    // 2. Gate check (Masterwork lock)
    if (skill.isGated) {
      log("Level Capped! Complete the Level ${skill.levelCap} Masterwork Trial to continue.", LogType.warning);
      return;
    }

    // 3. Energy check
    final actualEnergyCost = getModifiedEnergyCost(recipe.energyCost, recipe.requiredSkill);
    if (actualEnergyCost > 0 && _playerStats.currentEnergy < actualEnergyCost) {
      log("Not enough energy! Rest at the Town Inn or eat food.", LogType.error);
      return;
    }

    // 4. Ingredients check
    for (var entry in recipe.inputs.entries) {
      final itemId = entry.key;
      final requiredQty = entry.value;
      if (!_inventory.hasItem(itemId, requiredQty)) {
        final item = Items.findById(itemId);
        final itemName = item != null ? item.name : itemId;
        log("Not enough ingredients! Missing: $itemName x$requiredQty.", LogType.error);
        return;
      }
    }

    // Cancel previous
    cancelAction();

    // Consume ingredients immediately
    for (var entry in recipe.inputs.entries) {
      _inventory = _inventory.removeItem(entry.key, entry.value);
    }

    double duration = recipe.durationSeconds.toDouble();
    duration = duration / (1.0 + getSkillSpeedBonus(recipe.requiredSkill));
    if (duration < 1.0) duration = 1.0;

    _activeAction = ActiveActionState(
      recipe: recipe,
      progress: 0.0,
      durationSeconds: duration,
    );
    notifyListeners();

    // Start 100ms updates
    const tickMs = 100;
    final totalTicks = (duration * 1000) / tickMs;
    int currentTick = 0;

    _actionTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      currentTick++;
      double progress = currentTick / totalTicks;

      if (progress >= 1.0) {
        _activeAction = _activeAction!.copyWith(progress: 1.0);
        timer.cancel();
        _completeAction();
      } else {
        _activeAction = _activeAction!.copyWith(progress: progress);
        notifyListeners();
      }
    });
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

    // Cancel previous
    cancelAction();

    // Consume ingredients immediately
    for (var entry in structure.cost.entries) {
      _inventory = _inventory.removeItem(entry.key, entry.value);
    }

    double duration = structure.durationSeconds.toDouble();
    duration = duration / (1.0 + getSkillSpeedBonus(structure.requiredSkill));
    if (duration < 1.0) duration = 1.0;

    _activeAction = ActiveActionState(
      structure: structure,
      targetZoneId: zoneId,
      progress: 0.0,
      durationSeconds: duration,
    );
    notifyListeners();

    // Start 100ms updates
    const tickMs = 100;
    final totalTicks = (duration * 1000) / tickMs;
    int currentTick = 0;

    _actionTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      currentTick++;
      double progress = currentTick / totalTicks;

      if (progress >= 1.0) {
        _activeAction = _activeAction!.copyWith(progress: 1.0);
        timer.cancel();
        _completeAction();
      } else {
        _activeAction = _activeAction!.copyWith(progress: progress);
        notifyListeners();
      }
    });
  }


  void cancelAction() {
    _actionTimer?.cancel();
    _activeAction = null;
    _activeCombat = null;
    notifyListeners();
  }

  void _completeAction() {
    if (_activeAction == null) return;

    if (_activeAction!.action != null && _activeAction!.action!.isCombat) {
      final action = _activeAction!.action!;
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
      } else if (newSkill.isGated && !oldSkill.isGated) {
        log("Limit Reached! Level ${newSkill.levelCap} Masterwork Trial is now unlocked. Check the Skills tab.", LogType.warning);
      }

      // 3. Award Monster drops (with double loot perk check)
      bool doubleLoot = false;
      if (oldSkill.levelCap > 20) {
        if (_random.nextDouble() <= 0.15) {
          doubleLoot = true;
        }
      }

      bool inventoryFullError = false;
      final beast = _activeCombat?.beast;
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
            if (_inventory.isFull) {
              inventoryFullError = true;
            } else {
              _inventory = _inventory.addItem(loot.item, qty);
              log("Defeated ${beast.name}! Obtained: ${loot.item.icon} ${loot.item.name} x$qty", LogType.success);
            }
          }
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
      _activeAction = null;
      notifyListeners();

      // Auto-repeat
      startAction(action);
      return;
    }

    if (_activeAction!.structure != null) {
      final structure = _activeAction!.structure!;
      final zoneId = _activeAction!.targetZoneId!;

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
      } else if (newSkill.isGated && !oldSkill.isGated) {
        log("Limit Reached! Level ${newSkill.levelCap} Masterwork Trial is now unlocked. Check the Skills tab.", LogType.warning);
      }

      // Add to structures list for that zone
      if (!_zoneStructures.containsKey(zoneId)) {
        _zoneStructures[zoneId] = [];
      }
      if (!_zoneStructures[zoneId]!.contains(structure.id)) {
        _zoneStructures[zoneId]!.add(structure.id);
      }

      log("Success! Finished building ${structure.name} (+${xpReward.toInt()} ${structure.requiredSkill.name} XP).", LogType.success);

      _activeAction = null;
      notifyListeners();
      return;
    }

    if (_activeAction!.recipe != null) {
      final recipe = _activeAction!.recipe!;

      // Deduct Energy
      final actualEnergyCost = getModifiedEnergyCost(recipe.energyCost, recipe.requiredSkill);
      int newEnergy = _playerStats.currentEnergy - actualEnergyCost;
      newEnergy = newEnergy.clamp(0, _playerStats.maxEnergy);
      _playerStats = _playerStats.copyWith(currentEnergy: newEnergy);

      // Award XP
      final oldSkill = _skills[recipe.requiredSkill]!;
      final xpReward = recipe.xpReward * getXpMultiplier();
      final newSkill = oldSkill.addXp(xpReward);
      _skills[recipe.requiredSkill] = newSkill;

      if (newSkill.level > oldSkill.level) {
        log("Level Up! Your ${recipe.requiredSkill.name} is now Level ${newSkill.level}!", LogType.levelUp);
      } else if (newSkill.isGated && !oldSkill.isGated) {
        log("Limit Reached! Level ${newSkill.levelCap} Masterwork Trial is now unlocked. Check the Skills tab.", LogType.warning);
      }

      // Check Crafting Level 20 Perk: 15% chance to save all inputs
      if (recipe.requiredSkill == SkillType.crafting && oldSkill.levelCap > 20) {
        if (_random.nextDouble() <= 0.15) {
          for (var entry in recipe.inputs.entries) {
            final item = Items.findById(entry.key);
            if (item != null) {
              _inventory = _inventory.addItem(item, entry.value);
            }
          }
          log("🛠️ Artisan's Touch Perk! Saved all ingredients!", LogType.success);
        }
      }

      // Award result item
      final resultItem = recipe.resultItem;
      if (resultItem != null) {
        int finalQty = recipe.resultQuantity;
        // Check Cooking Level 20 Perk: 20% chance to double output
        if (recipe.requiredSkill == SkillType.cooking && oldSkill.levelCap > 20) {
          if (_random.nextDouble() <= 0.20) {
            finalQty *= 2;
            log("🍳 Master Culinarian Perk! Output doubled!", LogType.success);
          }
        }

        if (_inventory.isFull) {
          log("Your inventory is full! The ${resultItem.name} was dropped.", LogType.error);
        } else {
          _inventory = _inventory.addItem(resultItem, finalQty);
          log("Crafted: ${resultItem.icon} ${resultItem.name} x$finalQty", LogType.success);
        }
      }

      log("Success! Finished crafting ${recipe.name} (+${xpReward.toInt()} ${recipe.requiredSkill.name} XP).", LogType.success);

      _activeAction = null;
      notifyListeners();

      // Auto-repeat recipe if requirements are met
      startCrafting(recipe);
      return;
    }

    final action = _activeAction!.action!;

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
        final equippedTool = _equippedTools[action.requiredSkill!];
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
      } else if (newSkill.isGated && !oldSkill.isGated) {
        log("Limit Reached! Level ${newSkill.levelCap} Masterwork Trial is now unlocked. Check the Skills tab.", LogType.warning);
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
          // Milestone reach: unlock zone and award discovery chest!
          if (action.id == 'explore_forest_paths') {
            unlockZone('whispering_woods_1');
            
            _playerStats = _playerStats.copyWith(gold: _playerStats.gold + 10);
            _inventory = _inventory.addItem(Items.wildBerries, 5);
            _inventory = _inventory.addItem(Items.oakLog, 5);
            _inventory = _inventory.addItem(Items.wildflower, 2);
            log("🎁 DISCOVERY CHEST: You charted a path to the Whispering Woods! Found 10 Gold, 5 Wild Berries, 5 Oak Logs, and 2 Wildflowers!", LogType.success);
          } else if (action.id == 'explore_rocky_trails') {
            unlockZone('darkstone_mine_1');
            
            _playerStats = _playerStats.copyWith(gold: _playerStats.gold + 10);
            _inventory = _inventory.addItem(Items.copperOre, 5);
            _inventory = _inventory.addItem(Items.tinOre, 3);
            _inventory = _inventory.addItem(Items.wildBerries, 3);
            log("🎁 DISCOVERY CHEST: You charted a path to the Darkstone Mine! Found 10 Gold, 5 Copper Ore, 3 Tin Ore, and 3 Wild Berries!", LogType.success);
          } else if (action.id == 'explore_deep_woods') {
            unlockZone('whispering_woods_2');
            
            _playerStats = _playerStats.copyWith(gold: _playerStats.gold + 100);
            _inventory = _inventory.addItem(Items.leatherBackpack, 1);
            _inventory = _inventory.addItem(Items.willowLog, 3);
            log("🎁 DISCOVERY CHEST: You successfully charted the Deep Woods Canopy! Found 100 Gold, 1 Leather Backpack, and 3 Willow Logs!", LogType.success);
          } else if (action.id == 'explore_lower_shafts') {
            unlockZone('darkstone_mine_2');
            
            _playerStats = _playerStats.copyWith(gold: _playerStats.gold + 100);
            _inventory = _inventory.addItem(Items.backpackUpgrade, 1);
            _inventory = _inventory.addItem(Items.ironOre, 3);
            log("🎁 DISCOVERY CHEST: You successfully charted the Lower Caverns! Found 100 Gold, 1 Backpack Upgrade, and 3 Iron Ore!", LogType.success);
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
            } else if (roll < 0.85) {
              _inventory = _inventory.addItem(Items.wildflower, 1);
              log("🔍 Exploration Event: You picked a beautiful Wild Bluebell growing by the rocks.", LogType.success);
            } else if (roll < 0.95) {
              _inventory = _inventory.addItem(Items.oakLog, 1);
              log("🔍 Exploration Event: You snapped a fallen branch into a usable Oak Log.", LogType.success);
            } else {
              log("🔍 Exploration Event: You scanned the terrain and noted the local plant life.", LogType.info);
            }
            
          } else if (action.id == 'explore_rocky_trails') {
            pathName = "Rocky Trails";
            
            final roll = _random.nextDouble();
            if (roll < 0.40) {
              final goldAmt = 5 + _random.nextInt(8);
              _playerStats = _playerStats.copyWith(gold: _playerStats.gold + goldAmt);
              log("🔍 Exploration Event: You found a coin pouch wedged between rocks with $goldAmt Gold!", LogType.success);
            } else if (roll < 0.70) {
              final qty = 1 + _random.nextInt(2);
              _inventory = _inventory.addItem(Items.copperOre, qty);
              log("🔍 Exploration Event: You chipped $qty Copper Ore from a surface vein!", LogType.success);
            } else if (roll < 0.85) {
              _inventory = _inventory.addItem(Items.tinOre, 1);
              log("🔍 Exploration Event: You spotted a glint of tin in the gravel!", LogType.success);
            } else if (roll < 0.95) {
              _inventory = _inventory.addItem(Items.wildBerries, 2);
              log("🔍 Exploration Event: You found some berries growing in a rocky crevice.", LogType.success);
            } else {
              log("🔍 Exploration Event: You surveyed the trail and marked the terrain.", LogType.info);
            }
            
          } else if (action.id == 'explore_deep_woods') {
            pathName = "Deep Woods Canopy";
            
            final roll = _random.nextDouble();
            if (roll < 0.40) {
              final goldAmt = 10 + _random.nextInt(16);
              _playerStats = _playerStats.copyWith(gold: _playerStats.gold + goldAmt);
              log("🔍 Exploration Event: You found a lost trader pouch with $goldAmt Gold!", LogType.success);
            } else if (roll < 0.75) {
              final item = _random.nextBool() ? Items.riverClay : Items.wildflower;
              final qty = 1 + _random.nextInt(2);
              _inventory = _inventory.addItem(item, qty);
              log("🔍 Exploration Event: You unearthed $qty ${item.name} near the marshy banks!", LogType.success);
            } else if (roll < 0.95) {
              final qty = 1 + _random.nextInt(2);
              _inventory = _inventory.addItem(Items.rawTrout, qty);
              log("🔍 Exploration Event: You caught $qty Raw Trout in a shallow pool!", LogType.success);
            } else {
              _inventory = _inventory.addItem(Items.copperAxe, 1);
              log("🔍 Exploration Event: Rare find! You found a discarded Copper Axe wedged in an old stump!", LogType.success);
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
            } else if (roll < 0.95) {
              final qty = 1 + _random.nextInt(2);
              _inventory = _inventory.addItem(Items.rawPotato, qty);
              log("🔍 Exploration Event: You found $qty wild Raw Potatoes in a fertile patch!", LogType.success);
            } else {
              _inventory = _inventory.addItem(Items.copperPickaxe, 1);
              log("🔍 Exploration Event: Rare find! You found a rusty Copper Pickaxe left in a mine cart!", LogType.success);
            }
          }
          
          log("🗺️ Exploration progress for $pathName increased to ${(newProgress * 100).toInt()}%.", LogType.info);
        }
      }
    }

    _activeAction = null;
    notifyListeners();

    // Auto-repeat zone action if possible
    startAction(action);
  }

  // Consuming Food
  void eatFood(Item item) {
    if (item.type != ItemType.food) return;
    if (!_inventory.hasItem(item.id, 1)) return;

    _inventory = _inventory.removeItem(item.id, 1);

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

    int healed = (item.healAmount * foodMultiplier).round();
    int energyRestored = (item.energyAmount * foodMultiplier).round();

    int newHealth = min(_playerStats.maxHealth, _playerStats.currentHealth + healed);
    int newEnergy = min(_playerStats.maxEnergy, _playerStats.currentEnergy + energyRestored);

    _playerStats = _playerStats.copyWith(
      currentHealth: newHealth,
      currentEnergy: newEnergy,
    );

    log("Consumed ${item.icon} ${item.name} (Restored +$healed HP, +$energyRestored Energy).", LogType.success);
    notifyListeners();
  }

  void useItem(Item item) {
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
      eatFood(item);
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

  void sellItem(Item item, int quantity) {
    if (!_inventory.hasItem(item.id, quantity)) {
      log("You don't have $quantity ${item.name} to sell!", LogType.error);
      return;
    }

    _inventory = _inventory.removeItem(item.id, quantity);
    int earnings = item.value * quantity;
    _playerStats = _playerStats.copyWith(gold: _playerStats.gold + earnings);
    log("Sold ${item.icon} ${item.name} x$quantity for $earnings Gold.", LogType.success);
    notifyListeners();
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

  void resetGame() {
    cancelAction();
    cancelMasterwork();
    _playerStats = PlayerStats.initial();
    _inventory = Inventory.initial();
    _currentZone = Zones.townSquare;
    _unlockedZoneIds.clear();
    _unlockedZoneIds.add('town_square');
    _zoneStructures.clear();
    _logs.clear();
    _activeAction = null;
    _activeMasterwork = null;
    _equippedTools.clear();
    _maxEquipmentSlots = 1;
    _equippedWeapon = null;
    _equippedArmor = null;
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

  @override
  void dispose() {
    _actionTimer?.cancel();
    super.dispose();
  }
}

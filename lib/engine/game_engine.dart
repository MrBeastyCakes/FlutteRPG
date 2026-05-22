import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/player_stats.dart';
import '../models/skill.dart';
import '../models/item.dart';
import '../models/inventory.dart';
import '../models/zone.dart';
import '../models/masterwork.dart';
import 'activity_log.dart';

class ActiveActionState {
  final ZoneAction action;
  final double progress; // 0.0 to 1.0
  final double durationSeconds;

  const ActiveActionState({
    required this.action,
    required this.progress,
    required this.durationSeconds,
  });

  ActiveActionState copyWith({
    ZoneAction? action,
    double? progress,
    double? durationSeconds,
  }) {
    return ActiveActionState(
      action: action ?? this.action,
      progress: progress ?? this.progress,
      durationSeconds: durationSeconds ?? this.durationSeconds,
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

  ActiveActionState? _activeAction;
  Timer? _actionTimer;

  MasterworkRunState? _activeMasterwork;

  final Random _random = Random();

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
  Map<SkillType, SkillState> get skills => _skills;
  Inventory get inventory => _inventory;
  Zone get currentZone => _currentZone;
  List<LogEntry> get logs => List.unmodifiable(_logs);
  ActiveActionState? get activeAction => _activeAction;
  MasterworkRunState? get activeMasterwork => _activeMasterwork;

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
    
    // Stop current action
    cancelAction();
    cancelMasterwork();

    _currentZone = zone;
    log("Traveled to ${zone.name}.", LogType.info);
    notifyListeners();
  }

  // Timer Tick Action
  void startAction(ZoneAction action) {
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
    if (action.energyCost > 0 && _playerStats.currentEnergy < action.energyCost) {
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

    // Calculate speed bonus from equipped tools
    double speedBonus = 0.0;
    if (action.requiredSkill != null) {
      final bestTool = _inventory.getBestToolFor(action.requiredSkill!);
      if (bestTool != null) {
        speedBonus = bestTool.speedBonus;
      }
    }

    // Apply zone speed modifiers
    // Duration = BaseDuration / (1 + speedBonus) / zoneSpeedModifier
    double duration = action.durationSeconds.toDouble();
    duration = duration / (1.0 + speedBonus);
    duration = duration / _currentZone.speedModifier;
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
    notifyListeners();
  }

  void _completeAction() {
    if (_activeAction == null) return;
    final action = _activeAction!.action;

    // Deduct/Recover Energy
    int newEnergy = _playerStats.currentEnergy - action.energyCost;
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

    // Award XP
    if (action.requiredSkill != null) {
      final oldSkill = _skills[action.requiredSkill!]!;
      final newSkill = oldSkill.addXp(action.xpReward);
      _skills[action.requiredSkill!] = newSkill;

      if (newSkill.level > oldSkill.level) {
        log("Level Up! Your ${action.requiredSkill!.name} is now Level ${newSkill.level}!", LogType.levelUp);
      } else if (newSkill.isGated && !oldSkill.isGated) {
        log("Limit Reached! Level ${newSkill.levelCap} Masterwork Trial is now unlocked. Check the Skills tab.", LogType.warning);
      }
    }

    // Roll Loot table
    bool inventoryFullError = false;
    for (var loot in action.lootTable) {
      final roll = _random.nextDouble();
      if (roll <= loot.chance) {
        int qty = loot.minQuantity;
        if (loot.maxQuantity > loot.minQuantity) {
          qty = loot.minQuantity + _random.nextInt(loot.maxQuantity - loot.minQuantity + 1);
        }

        if (_inventory.isFull) {
          inventoryFullError = true;
        } else {
          _inventory = _inventory.addItem(loot.item, qty);
          log("Gathered: ${loot.item.icon} ${loot.item.name} x$qty", LogType.success);
        }
      }
    }

    if (inventoryFullError) {
      log("Your inventory is full! Some items were dropped.", LogType.error);
    }

    // Success logs
    if (action.id == 'inn_rest') {
      log("You feel rested and energized. Health and energy fully restored.", LogType.success);
    } else if (action.id == 'chat_townsfolk') {
      log("You learned some local history (+12 Lore XP).", LogType.success);
    } else {
      String skillName = action.requiredSkill != null ? action.requiredSkill!.name : 'General';
      log("Success! Finished ${action.name} (+${action.xpReward.toInt()} $skillName XP).", LogType.success);
    }

    _activeAction = null;
    notifyListeners();
  }

  // Consuming Food
  void eatFood(Item item) {
    if (item.type != ItemType.food) return;
    if (!_inventory.hasItem(item.id, 1)) return;

    _inventory = _inventory.removeItem(item.id, 1);

    int newHealth = min(_playerStats.maxHealth, _playerStats.currentHealth + item.healAmount);
    int newEnergy = min(_playerStats.maxEnergy, _playerStats.currentEnergy + item.energyAmount);

    _playerStats = _playerStats.copyWith(
      currentHealth: newHealth,
      currentEnergy: newEnergy,
    );

    log("Consumed ${item.icon} ${item.name} (Restored +${item.healAmount} HP, +${item.energyAmount} Energy).", LogType.success);
    notifyListeners();
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

  @override
  void dispose() {
    _actionTimer?.cancel();
    super.dispose();
  }
}

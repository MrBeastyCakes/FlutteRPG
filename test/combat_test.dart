import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/item.dart';
import 'package:flutter_text_based_rpg/models/skill.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';
import 'package:flutter_text_based_rpg/models/beast.dart';

void main() {
  group('Combat & Beast Hunting System Tests', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
      // Clear inventory and add bronze sword/leather jerkin
      engine.inventory = engine.inventory
          .addItem(Items.bronzeSword, 1)
          .addItem(Items.leatherChest, 1);
    });

    test('Equipping weapons and armor increases attack and defense', () {
      // Starting base stats
      expect(engine.getPlayerAttack(), 5);
      expect(engine.getPlayerDefense(), 0);

      // Equip Weapon
      engine.equipWeapon(Items.bronzeSword);
      expect(engine.equippedWeapon, Items.bronzeSword);
      expect(engine.getPlayerAttack(), 13); // 5 base + 8 sword

      // Equip Armor
      engine.equipArmor(Items.leatherChest);
      expect(engine.equippedArmor, Items.leatherChest);
      expect(engine.getPlayerDefense(), 2); // 0 base + 2 jerkin
    });

    test('Unequipping weapons and armor returns them to inventory', () {
      engine.equipWeapon(Items.bronzeSword);
      engine.equipArmor(Items.leatherChest);
      expect(engine.inventory.hasItem('bronze_sword'), false);
      expect(engine.inventory.hasItem('leather_chest'), false);

      engine.unequipWeapon();
      expect(engine.equippedWeapon, null);
      expect(engine.inventory.hasItem('bronze_sword'), true);

      engine.unequipArmor();
      expect(engine.equippedArmor, null);
      expect(engine.inventory.hasItem('leather_chest'), true);
    });

    test('Combat Level 10 and Level 20 perks affect stats and round speed', () {
      // 1. Initial Combat cap is 10. Unlock level cap by 10 (cap becomes 20, unlocking Perk 10)
      final combatSkill = engine.skills[SkillType.combat]!;
      engine.skills[SkillType.combat] = combatSkill.unlockCap(); // Level cap = 20 (Perk 10 active)

      expect(engine.getPlayerAttack(), 8); // 5 base + 3 Perk 10
      expect(engine.getPlayerDefense(), 1); // 0 base + 1 Perk 10

      // 2. Unlock level cap by another 10 (cap becomes 30, unlocking Perk 20)
      engine.skills[SkillType.combat] = engine.skills[SkillType.combat]!.unlockCap(); // Level cap = 30 (Perk 20 active)

      // Test combat speed modifier in startAction
      engine.unlockZone('whispering_woods_1');
      engine.travelTo(Zones.whisperingWoodsTier1);
      final huntAction = Zones.whisperingWoodsTier1.actions.firstWhere((a) => a.id == 'hunt_boar');
      
      engine.startAction(huntAction);
      expect(engine.activeAction!.durationSeconds, closeTo(1.5 / 1.15, 0.01)); // 1.5s base / 1.15 speed modifier
    });

    test('Starting a combat action initializes activeCombat state', () {
      engine.unlockZone('whispering_woods_1');
      engine.travelTo(Zones.whisperingWoodsTier1);
      final huntAction = Zones.whisperingWoodsTier1.actions.firstWhere((a) => a.id == 'hunt_boar');

      expect(engine.activeCombat, null);
      engine.startAction(huntAction);

      expect(engine.activeCombat != null, true);
      expect(engine.activeCombat!.beast.id, 'forest_boar');
      expect(engine.activeCombat!.beastCurrentHealth, 35);
      expect(engine.activeCombat!.combatLog.isNotEmpty, true);
    });

    test('Flee combat safely exits combat and cancels timer', () {
      engine.unlockZone('whispering_woods_1');
      engine.travelTo(Zones.whisperingWoodsTier1);
      final huntAction = Zones.whisperingWoodsTier1.actions.firstWhere((a) => a.id == 'hunt_boar');

      engine.startAction(huntAction);
      expect(engine.activeCombat != null, true);
      expect(engine.activeAction != null, true);

      engine.cancelAction(); // Flee
      expect(engine.activeCombat, null);
      expect(engine.activeAction, null);
    });
  });
}

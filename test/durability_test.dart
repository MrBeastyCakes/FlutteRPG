import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/inventory.dart';
import 'package:flutter_text_based_rpg/models/item.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/crafted_item.dart';
import 'package:flutter_text_based_rpg/models/skill.dart';
import 'package:flutter_text_based_rpg/models/combat.dart';

void main() {
  group('InventorySlot durability', () {
    test('Default durability is 0/0 (unset)', () {
      final slot = InventorySlot(item: Items.stoneAxe, quantity: 1, affixIds: []);
      expect(slot.currentDurability, 0);
      expect(slot.maxDurability, 0);
    });

    test('Can construct with durability values', () {
      final slot = InventorySlot(
        item: Items.stoneAxe, quantity: 1, affixIds: [],
        currentDurability: 80, maxDurability: 100,
      );
      expect(slot.currentDurability, 80);
      expect(slot.maxDurability, 100);
    });

    test('copyWith preserves durability', () {
      final slot = InventorySlot(
        item: Items.stoneAxe, quantity: 1, affixIds: [],
        currentDurability: 50, maxDurability: 100,
      );
      final copy = slot.copyWith(quantity: 2);
      expect(copy.currentDurability, 50);
      expect(copy.maxDurability, 100);
    });

    test('copyWith can update durability', () {
      final slot = InventorySlot(
        item: Items.stoneAxe, quantity: 1, affixIds: [],
        currentDurability: 100, maxDurability: 100,
      );
      final copy = slot.copyWith(currentDurability: 80);
      expect(copy.currentDurability, 80);
      expect(copy.maxDurability, 100);
    });
  });

  group('calculateMaxDurability', () {
    test('Crude = 75, Standard = 100, Fine = 150, Masterwork = 250', () {
      final engine = GameEngine();
      expect(engine.calculateMaxDurabilityForTest(Items.stoneAxe, QualityTier.crude, []), 75);
      expect(engine.calculateMaxDurabilityForTest(Items.stoneAxe, QualityTier.standard, []), 100);
      expect(engine.calculateMaxDurabilityForTest(Items.stoneAxe, QualityTier.fine, []), 150);
      expect(engine.calculateMaxDurabilityForTest(Items.stoneAxe, QualityTier.masterwork, []), 250);
    });

    test('Sturdy affix adds 50%', () {
      final engine = GameEngine();
      expect(engine.calculateMaxDurabilityForTest(Items.stoneAxe, QualityTier.standard, ['sturdy']), 150);
    });

    test('Quest items (value 0) get no durability stamp', () {
      final engine = GameEngine();
      final cleansingToken = Item(id: 'wilds_cleansing_token', name: 'Test', description: '', icon: '🟢', type: ItemType.resource, value: 0);
      expect(engine.calculateMaxDurabilityForTest(cleansingToken, QualityTier.standard, []), 0);
    });
  });

  group('Durability decrement', () {
    test('Tool decrements on gathering action completion', () {
      final engine = GameEngine();
      engine.equipForTest(Items.stoneAxe, SkillType.woodcutting);
      final before = engine.equippedToolSlots[SkillType.woodcutting]!.currentDurability;
      engine.completeGatherActionForTest(SkillType.woodcutting);
      final after = engine.equippedToolSlots[SkillType.woodcutting]!.currentDurability;
      expect(after, before - 1);
    });

    test('Weapon decrements on Strike or Heavy Strike round only', () {
      final engine = GameEngine();
      engine.equipWeaponForTest(Items.bronzeSword);
      final before = engine.equippedWeaponSlot!.currentDurability;
      engine.runCombatRoundForTest(PlayerStance.strike);
      expect(engine.equippedWeaponSlot!.currentDurability, before - 1);

      final after = engine.equippedWeaponSlot!.currentDurability;
      engine.runCombatRoundForTest(PlayerStance.defend);
      expect(engine.equippedWeaponSlot!.currentDurability, after, reason: 'Defend should not tick weapon');
    });

    test('Armor decrements only on damage taken', () {
      final engine = GameEngine();
      engine.equipArmorForTest(Items.leatherChest);
      final before = engine.equippedArmorSlot!.currentDurability;
      engine.simulateCombatDamageForTest(playerDmgTaken: 5);
      expect(engine.equippedArmorSlot!.currentDurability, before - 1);

      final after = engine.equippedArmorSlot!.currentDurability;
      engine.simulateCombatDamageForTest(playerDmgTaken: 0);
      expect(engine.equippedArmorSlot!.currentDurability, after, reason: 'Zero damage should not tick armor');
    });

    test('Low-durability warning fires once per session per item', () {
      final engine = GameEngine();
      engine.equipForTest(Items.stoneAxe, SkillType.woodcutting);
      final slot = engine.equippedToolSlots[SkillType.woodcutting]!;
      engine.forceEquippedDurabilityForTest(SkillType.woodcutting, (slot.maxDurability * 0.26).round());
      final logCountBefore = engine.logsForTest.length;
      engine.completeGatherActionForTest(SkillType.woodcutting);
      final newLogs = engine.logsForTest.length - logCountBefore;
      expect(newLogs, greaterThan(0));
      final lastLog = engine.logsForTest.first;
      expect(lastLog.message, contains('wearing thin'));

      final logCountAfterFirst = engine.logsForTest.length;
      engine.completeGatherActionForTest(SkillType.woodcutting);
      expect(engine.logsForTest.length, logCountAfterFirst);
    });
  });

  group('Worn equipment', () {
    test('isSlotWorn returns true at 0 durability', () {
      final engine = GameEngine();
      final slot = InventorySlot(item: Items.bronzeSword, quantity: 1, affixIds: [],
        currentDurability: 0, maxDurability: 100);
      expect(engine.isSlotWorn(slot), true);
    });

    test('isSlotWorn returns false at any positive durability', () {
      final engine = GameEngine();
      final slot = InventorySlot(item: Items.bronzeSword, quantity: 1, affixIds: [],
        currentDurability: 1, maxDurability: 100);
      expect(engine.isSlotWorn(slot), false);
    });

    test('Worn weapon ignored in getPlayerAttack', () {
      final engine = GameEngine();
      final fresh = InventorySlot(item: Items.bronzeSword, quantity: 1, affixIds: [],
        currentDurability: 100, maxDurability: 100);
      engine.setEquippedWeaponForTest(fresh);
      final attackFresh = engine.getPlayerAttack();

      final worn = fresh.copyWith(currentDurability: 0);
      engine.setEquippedWeaponForTest(worn);
      final attackWorn = engine.getPlayerAttack();

      expect(attackWorn, lessThan(attackFresh));
    });

    test('Worn armor ignored in getPlayerDefense', () {
      final engine = GameEngine();
      final fresh = InventorySlot(item: Items.leatherChest, quantity: 1, affixIds: [],
        currentDurability: 100, maxDurability: 100);
      engine.setEquippedArmorForTest(fresh);
      final defenseFresh = engine.getPlayerDefense();

      final worn = fresh.copyWith(currentDurability: 0);
      engine.setEquippedArmorForTest(worn);
      final defenseWorn = engine.getPlayerDefense();

      expect(defenseWorn, lessThan(defenseFresh));
    });
  });

  group('Repair API', () {
    test('calculateRepairCost returns 25% of recipe inputs', () {
      final engine = GameEngine();
      final slot = InventorySlot(item: Items.stoneAxe, quantity: 1, affixIds: [],
        currentDurability: 50, maxDurability: 100);
      final cost = engine.calculateRepairCostForTest(slot);
      expect(cost['oak_log'], 1);  // 3 * 0.25 = 0.75 -> ceil -> 1
      expect(cost['river_clay'], 1);  // 2 * 0.25 = 0.5 -> ceil -> 1
    });

    test('repairWithMaterials consumes inputs and restores durability', () {
      final engine = GameEngine();
      engine.inventory = engine.inventory.addItem(Items.oakLog, 5);
      engine.inventory = engine.inventory.addItem(Items.riverClay, 5);
      engine.equipForTest(Items.stoneAxe, SkillType.woodcutting);
      engine.forceEquippedDurabilityForTest(SkillType.woodcutting, 20);

      final oakBefore = engine.inventory.getItemCount('oak_log');
      engine.repairWithMaterials(engine.equippedToolSlots[SkillType.woodcutting]!,
        slot: 'tool', skill: SkillType.woodcutting);

      final after = engine.equippedToolSlots[SkillType.woodcutting]!;
      expect(after.currentDurability, after.maxDurability);
      expect(engine.inventory.getItemCount('oak_log'), oakBefore - 1);
    });

    test('calculateRepairGoldCost scales with damage percent', () {
      final engine = GameEngine();
      final slot = InventorySlot(item: Items.bronzeSword, quantity: 1, affixIds: [],
        currentDurability: 50, maxDurability: 100);  // 50% damaged
      final cost = engine.calculateRepairGoldCostForTest(slot);
      // value 150 * 0.25 * 0.5 = 18.75 -> ceil -> 19
      expect(cost, 19);
    });

    test('repairWithGold consumes gold and restores durability', () {
      final engine = GameEngine();
      engine.playerStats = engine.playerStats.copyWith(gold: 100);
      engine.equipWeaponForTest(Items.bronzeSword);
      engine.setEquippedWeaponForTest(engine.equippedWeaponSlot!.copyWith(currentDurability: 50));

      final goldBefore = engine.playerStats.gold;
      engine.repairWithGold(engine.equippedWeaponSlot!, slot: 'weapon');
      expect(engine.equippedWeaponSlot!.currentDurability, engine.equippedWeaponSlot!.maxDurability);
      expect(engine.playerStats.gold, lessThan(goldBefore));
    });
  });
}

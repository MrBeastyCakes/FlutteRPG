import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/item.dart';
import 'package:flutter_text_based_rpg/models/skill.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';

void main() {
  group('Equipment System Tests', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
      engine.inventory = engine.inventory
          .addItem(Items.stoneAxe, 1)
          .addItem(Items.stonePickaxe, 1);
    });

    test('Initial equipment slots and variables check', () {
      expect(engine.maxEquipmentSlots, 1);
      expect(engine.equippedTools.isEmpty, true);
    });

    test('Equip tool removes it from inventory and places it in equipped list', () {
      // Setup: Stone Axe is in starting inventory
      expect(engine.inventory.hasItem('stone_axe'), true);

      // Equip Stone Axe
      engine.equipTool(Items.stoneAxe);

      // Check results
      expect(engine.inventory.hasItem('stone_axe'), false);
      expect(engine.equippedTools[SkillType.woodcutting], Items.stoneAxe);
      expect(engine.equippedTools.length, 1);
    });

    test('Equipping a second tool is blocked when max equipment slots is 1', () {
      // Equip Stone Axe first
      engine.equipTool(Items.stoneAxe);
      expect(engine.equippedTools.length, 1);

      // Try to equip Stone Pickaxe (also in starting inventory)
      expect(engine.inventory.hasItem('stone_pickaxe'), true);
      engine.equipTool(Items.stonePickaxe);

      // Should be blocked: Stone Pickaxe remains in inventory, not equipped
      expect(engine.inventory.hasItem('stone_pickaxe'), true);
      expect(engine.equippedTools.containsKey(SkillType.mining), false);
      expect(engine.equippedTools.length, 1);
      expect(engine.logs.any((l) => l.message.contains('slots full')), true);
    });

    test('Swapping a tool for the same skill slot is allowed even at slot capacity', () {
      // 1. Equip Stone Axe
      engine.equipTool(Items.stoneAxe);
      expect(engine.equippedTools.length, 1);

      // 2. Add Iron Axe to inventory manually
      engine.playerStats = engine.playerStats.copyWith(gold: 1000);
      engine.buyItem(Items.ironAxe);
      expect(engine.inventory.hasItem('iron_axe'), true);

      // 3. Swap: Equip Iron Axe (capacity limit is 1, but this is a swap in the same skill slot)
      engine.equipTool(Items.ironAxe);

      // 4. Verify swap succeeded
      expect(engine.equippedTools[SkillType.woodcutting], Items.ironAxe);
      expect(engine.inventory.hasItem('iron_axe'), false);
      
      // Old Stone Axe should be returned to inventory
      expect(engine.inventory.hasItem('stone_axe'), true);
      expect(engine.equippedTools.length, 1);
    });

    test('Backpack upgrades increase maximum equipment slots up to 3', () {
      // Buy and use Leather Backpack
      engine.playerStats = engine.playerStats.copyWith(gold: 1000);
      engine.buyItem(Items.leatherBackpack);
      expect(engine.inventory.hasItem('leather_backpack'), true);

      engine.useItem(Items.leatherBackpack);
      expect(engine.maxEquipmentSlots, 2);

      // Now we can equip a second tool
      engine.equipTool(Items.stoneAxe);
      engine.equipTool(Items.stonePickaxe);
      expect(engine.equippedTools.length, 2);
      expect(engine.equippedTools[SkillType.woodcutting], Items.stoneAxe);
      expect(engine.equippedTools[SkillType.mining], Items.stonePickaxe);

      // Max capacity is 3. Buy and use another backpack upgrade to reach 3
      engine.buyItem(Items.backpackUpgrade);
      engine.useItem(Items.backpackUpgrade);
      expect(engine.maxEquipmentSlots, 3);
    });

    test('Unequip tool returns it to inventory', () {
      engine.equipTool(Items.stoneAxe);
      expect(engine.equippedTools.containsKey(SkillType.woodcutting), true);
      expect(engine.inventory.hasItem('stone_axe'), false);

      engine.unequipTool(SkillType.woodcutting);
      expect(engine.equippedTools.containsKey(SkillType.woodcutting), false);
      expect(engine.inventory.hasItem('stone_axe'), true);
    });

    test('Unequip fails if inventory is completely full', () {
      // Equip tool (removes stone_axe from inventory; stone_pickaxe remains)
      engine.equipTool(Items.stoneAxe);

      // Fill up inventory to capacity (4 slots) with distinct items.
      // Slot 1: stone_pickaxe (from setUp). Add 3 more unique items for slots 2-4.
      engine.inventory = engine.inventory
          .addItem(Items.wildBerries, 1)
          .addItem(Items.oakLog, 1)
          .addItem(Items.copperOre, 1);
      expect(engine.inventory.isFull, true);

      // Try to unequip
      engine.unequipTool(SkillType.woodcutting);

      // Verify it failed: tool is still equipped, and inventory remains full
      expect(engine.equippedTools.containsKey(SkillType.woodcutting), true);
      expect(engine.logs.any((l) => l.message.contains('Inventory full')), true);
    });

    test('Equipped tools apply speed bonus during gather actions', () {
      engine.unlockZone('whispering_woods_1');
      engine.travelTo(Zones.whisperingWoodsTier1);

      // Base duration of woodcutting action (Chop Young Oak: 4s base)
      final action = Zones.whisperingWoodsTier1.actions.firstWhere((a) => a.id == 'chop_oak');
      
      // Starting action without tool
      engine.startAction(action);
      final durationNoTool = engine.activeAction!.durationSeconds;
      engine.cancelAction();

      // Equip Stone Axe (+5% speed bonus)
      engine.equipTool(Items.stoneAxe);
      engine.startAction(action);
      final durationWithStoneAxe = engine.activeAction!.durationSeconds;
      engine.cancelAction();

      // Buy and equip Iron Axe (+15% speed bonus)
      engine.playerStats = engine.playerStats.copyWith(gold: 1000);
      engine.buyItem(Items.ironAxe);
      engine.equipTool(Items.ironAxe);
      engine.startAction(action);
      final durationWithIronAxe = engine.activeAction!.durationSeconds;
      
      expect(durationWithStoneAxe < durationNoTool, true);
      expect(durationWithIronAxe < durationWithStoneAxe, true);
    });

    test('resetGame clears equipped tools and resets max slots to 1', () {
      // Set some state
      engine.playerStats = engine.playerStats.copyWith(gold: 1000);
      engine.buyItem(Items.leatherBackpack);
      engine.useItem(Items.leatherBackpack);
      engine.equipTool(Items.stoneAxe);

      expect(engine.maxEquipmentSlots, 2);
      expect(engine.equippedTools.isNotEmpty, true);

      // Reset
      engine.resetGame();

      // Verify reset
      expect(engine.maxEquipmentSlots, 1);
      expect(engine.equippedTools.isEmpty, true);
    });
  });
}

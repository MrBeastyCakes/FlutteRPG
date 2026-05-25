import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/item.dart';
import 'package:flutter_text_based_rpg/models/recipe.dart';
import 'package:flutter_text_based_rpg/models/skill.dart';
import 'package:flutter_text_based_rpg/models/combat.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';

void main() {
  group('Spec 4 Specialization & Sub-specialization Effects Tests', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
    });

    test('Arborist driftwood substitution yields +0.30 quality bias', () {
      final stoneAxe = Recipes.all.firstWhere((r) => r.id == 'stone_axe');
      final consumed = {'driftwood': 3, 'river_clay': 2};

      // No arborist spec: default bias 0.03
      expect(engine.calculateRecipeQualityBiasForTest(stoneAxe, consumed), closeTo(0.03, 0.001));

      // Unlock woodcutting_arborist spec
      engine.completeMasterworkForTest('wc_lvl_10', specPath: 'woodcutting_arborist');
      expect(engine.calculateRecipeQualityBiasForTest(stoneAxe, consumed), closeTo(0.30, 0.001));
    });

    test('Refiner and Smelt-Master increase smelter ingot yields', () {
      // Setup smelter station
      engine.unlockZone('darkstone_mine_1');
      engine.buildStructureForTest('darkstone_mine_1', 'smelter');
      
      final recipe = Recipes.all.firstWhere((r) => r.id == 'bronze_ingot_recipe'); // copper + tin -> bronze
      
      // Default: base yield 1
      engine.inventory = engine.inventory.addItem(Items.copperOre, 5);
      engine.inventory = engine.inventory.addItem(Items.tinOre, 5);
      engine.startCraftingForTest(recipe, 'darkstone_mine_1::smelter');
      expect(engine.inventory.getItemCount('bronze_ingot'), 1);

      // Refiner active: +1 yield -> total 2
      engine.inventory = engine.inventory.removeItem('bronze_ingot', 2);
      engine.completeMasterworkForTest('min_lvl_10', specPath: 'mining_refiner');
      engine.inventory = engine.inventory.addItem(Items.copperOre, 5);
      engine.inventory = engine.inventory.addItem(Items.tinOre, 5);
      engine.startCraftingForTest(recipe, 'darkstone_mine_1::smelter');
      expect(engine.inventory.getItemCount('bronze_ingot'), 2);

      // Smelt-Master active: finalQty * 2 -> total 4
      engine.inventory = engine.inventory.removeItem('bronze_ingot', 4);
      engine.completeMasterworkForTest('task_lvl20_mining_refiner', subSpecPath: 'mining_smelt_master');
      engine.inventory = engine.inventory.addItem(Items.copperOre, 5);
      engine.inventory = engine.inventory.addItem(Items.tinOre, 5);
      engine.startCraftingForTest(recipe, 'darkstone_mine_1::smelter');
      expect(engine.inventory.getItemCount('bronze_ingot'), 4);
    });

    test('Smith and Weaponsmith add quality bias to weapons', () {
      final recipe = Recipes.all.firstWhere((r) => r.id == 'bronze_sword');
      final resultItem = recipe.resultItem!;
      
      // Default
      expect(engine.getSpecCraftQualityBiasForTest(recipe, resultItem, 'crafting_bench'), 0.0);

      // Smith Spec: +0.10 for weapon
      engine.completeMasterworkForTest('craft_lvl_10', specPath: 'crafting_smith');
      expect(engine.getSpecCraftQualityBiasForTest(recipe, resultItem, 'crafting_bench'), closeTo(0.10, 0.001));

      // Weaponsmith Subspec: +0.15 extra (total 0.25)
      engine.completeMasterworkForTest('task_lvl20_crafting_smith', subSpecPath: 'crafting_weaponsmith');
      expect(engine.getSpecCraftQualityBiasForTest(recipe, resultItem, 'crafting_bench'), closeTo(0.25, 0.001));
    });

    test('Brewmaster injects brewmaster_aged affix at town kitchen', () {
      // Build Town kitchen
      engine.rebuildStationForTest('town_square', 'field_kitchen');
      engine.completeMasterworkForTest('task_lvl20_cooking_innkeeper', subSpecPath: 'cooking_brewmaster');

      final recipe = Recipes.all.firstWhere((r) => r.id == 'cooked_trout');
      engine.inventory = engine.inventory.addItem(Items.rawTrout, 5);
      engine.startCraftingForTest(recipe, 'town_square::field_kitchen');

      final inventoryItems = engine.inventory.slots.where((s) => s.item.id == 'cooked_fish').toList();
      expect(inventoryItems.isNotEmpty, true);
      expect(inventoryItems.first.affixIds, contains('brewmaster_aged'));
    });

    test('Bastion Defend heals player and Skirmisher speeds up timer', () {
      engine.completeMasterworkForTest('task_lvl20_combat_guardian', subSpecPath: 'combat_bastion');
      engine.unlockZone('whispering_woods_1');
      engine.travelTo(Zones.whisperingWoodsTier1);
      engine.startBoarHuntForTest();

      engine.setPlayerStatsForTest(engine.playerStats.copyWith(currentHealth: 50));
      final hpBefore = engine.playerStats.currentHealth;
      
      engine.setCombatStance(PlayerStance.defend);
      
      // Halve beast dmg (boar attack is 8, defense is 0, base dmg ~8, halve -> 4 dmg)
      // Bastion heals +5 HP
      // Net change: hpBefore - 4 + 5 = hpBefore + 1
      expect(engine.playerStats.currentHealth, greaterThan(hpBefore));

      // Check Skirmisher timer speedup
      final defaultDuration = engine.combatRoundDurationMs;
      engine.completeMasterworkForTest('task_lvl20_combat_berserker', subSpecPath: 'combat_skirmisher');
      final skirmisherDuration = engine.combatRoundDurationMs;
      expect(skirmisherDuration, lessThan(defaultDuration));
    });
  });
}

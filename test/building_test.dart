import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/item.dart';
import 'package:flutter_text_based_rpg/models/recipe.dart';
import 'package:flutter_text_based_rpg/models/skill.dart';
import 'package:flutter_text_based_rpg/models/structure.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';

void main() {
  group('Building System Tests', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
    });

    test('Cannot build in Town Square', () {
      // Town Square is the default zone.
      expect(engine.currentZone.id, 'town_square');
      
      // Let's try to build a Crafting Bench in Town Square.
      engine.startBuilding(Structures.craftingBench, 'town_square');
      
      // Verification:
      // Action should not be active since building in Town Square is prohibited.
      expect(engine.activeAction, isNull);
      expect(engine.logs.any((e) => e.message.contains('cannot build structures in the Town Square')), true);
    });

    test('Cannot build structure without meeting skill requirements', () {
      // Travel to Whispering Woods Tier 1 (unlock it first)
      engine.unlockZone('whispering_woods_1');
      engine.travelTo(Zones.whisperingWoodsTier1);
      expect(engine.currentZone.id, 'whispering_woods_1');

      // Crafting level is initially 1. Crafting Bench requires Crafting level 4.
      expect(engine.skills[SkillType.crafting]?.level, 1);

      // Try to build
      engine.startBuilding(Structures.craftingBench, 'whispering_woods_1');

      // Action should fail because of level requirement
      expect(engine.activeAction, isNull);
      expect(engine.logs.any((e) => e.message.contains('Requirements not met')), true);
    });

    test('Cannot build structure without sufficient materials', () {
      // Travel to Whispering Woods Tier 1
      engine.unlockZone('whispering_woods_1');
      engine.travelTo(Zones.whisperingWoodsTier1);

      // Level up Crafting to 5 to meet requirement
      engine.skills[SkillType.crafting] = SkillState(
        type: SkillType.crafting,
        level: 5,
        xp: 1000,
        levelCap: 10,
      );

      // Try to build a Crafting Bench. We don't have the materials in our starting inventory.
      // (Crafting Bench costs: 10 oak_log, 5 river_clay, 2 copper_ore)
      engine.startBuilding(Structures.craftingBench, 'whispering_woods_1');

      // Action should fail because of missing ingredients
      expect(engine.activeAction, isNull);
      expect(engine.logs.any((e) => e.message.contains('Not enough ingredients')), true);
    });

    test('Successful building consumes materials, locks action, and completes building after duration', () {
      fakeAsync((async) {
        // Travel to Whispering Woods Tier 1
        engine.unlockZone('whispering_woods_1');
        engine.travelTo(Zones.whisperingWoodsTier1);

        // Level up Crafting to 5
        engine.skills[SkillType.crafting] = SkillState(
          type: SkillType.crafting,
          level: 5,
          xp: 1000,
          levelCap: 10,
        );

        // Expand inventory capacity so we can hold all the ingredients
        engine.inventory = engine.inventory.copyWith(capacity: 20);

        // Add required materials: 10 oak_log, 5 river_clay, 2 copper_ore
        for (int i = 0; i < 10; i++) {
          engine.inventory = engine.inventory.addItem(Items.oakLog, 1);
        }
        for (int i = 0; i < 5; i++) {
          engine.inventory = engine.inventory.addItem(Items.riverClay, 1);
        }
        for (int i = 0; i < 2; i++) {
          engine.inventory = engine.inventory.addItem(Items.copperOre, 1);
        }

        expect(engine.inventory.hasItem('oak_log', 10), true);
        expect(engine.inventory.hasItem('river_clay', 5), true);
        expect(engine.inventory.hasItem('copper_ore', 2), true);

        // Start building
        final initialEnergy = engine.playerStats.currentEnergy;
        engine.startBuilding(Structures.craftingBench, 'whispering_woods_1');

        // Ingredients should be deducted immediately
        expect(engine.inventory.hasItem('oak_log', 1), false);
        expect(engine.inventory.hasItem('river_clay', 1), false);
        expect(engine.inventory.hasItem('copper_ore', 1), false);

        // Active action state should be populated
        expect(engine.activeAction, isNotNull);
        expect(engine.activeAction!.structure!.id, 'crafting_bench');
        expect(engine.activeAction!.progress, 0.0);

        // Elapse partial duration (duration is 15 seconds)
        async.elapse(const Duration(seconds: 5));
        expect(engine.activeAction, isNotNull);
        expect(engine.activeAction!.progress > 0.0 && engine.activeAction!.progress < 1.0, true);

        // Elapse remaining duration
        async.elapse(const Duration(seconds: 10));

        // Action should complete
        expect(engine.activeAction, isNull);

        // Verify structure is registered in the zone
        expect(engine.hasStructureInZone('whispering_woods_1', 'crafting_bench'), true);
        expect(engine.getBuiltStructuresForZone('whispering_woods_1').contains('crafting_bench'), true);

        // Energy should be deducted (energyCost is 10)
        expect(engine.playerStats.currentEnergy, initialEnergy - 10);

        // XP should be awarded (+50.0 Crafting XP)
        expect(engine.skills[SkillType.crafting]?.xp, 1050.0);

        // Success log should exist
        expect(engine.logs.any((e) => e.message.contains('Finished building Crafting Bench')), true);
      });
    });

    test('Local Crafting/Cooking is enabled only when corresponding structures are built', () {
      fakeAsync((async) {
        // Unlock Whispering Woods Tier 1
        engine.unlockZone('whispering_woods_1');
        engine.travelTo(Zones.whisperingWoodsTier1);

        // Try to craft in whispering_woods_1 (no crafting bench yet)
        // Copper Axe requires crafting.
        final copperAxeRecipe = Recipes.copperAxe;
        expect(engine.canCraftRecipe(copperAxeRecipe), false);

        // Level up Crafting to 5 and add ingredients for Crafting Bench
        engine.skills[SkillType.crafting] = SkillState(
          type: SkillType.crafting,
          level: 5,
          xp: 1000,
          levelCap: 10,
        );
        engine.inventory = engine.inventory.copyWith(capacity: 30);
        for (int i = 0; i < 10; i++) {
          engine.inventory = engine.inventory.addItem(Items.oakLog, 1);
        }
        for (int i = 0; i < 5; i++) {
          engine.inventory = engine.inventory.addItem(Items.riverClay, 1);
        }
        for (int i = 0; i < 2; i++) {
          engine.inventory = engine.inventory.addItem(Items.copperOre, 1);
        }

        // Build Crafting Bench
        engine.startBuilding(Structures.craftingBench, 'whispering_woods_1');
        async.elapse(const Duration(seconds: 15));

        // Now that the Crafting Bench is built, we should be able to craft!
        expect(engine.canCraftRecipe(copperAxeRecipe), true);
      });
    });

    test('Outpost Shelter adds free rest action and restores health/energy', () {
      fakeAsync((async) {
        // Travel to Whispering Woods Tier 1
        engine.unlockZone('whispering_woods_1');
        engine.travelTo(Zones.whisperingWoodsTier1);

        // Level up Wayfinding to 5 to meet requirement
        engine.skills[SkillType.wayfinding] = SkillState(
          type: SkillType.wayfinding,
          level: 5,
          xp: 1000,
          levelCap: 10,
        );

        // Add materials for Outpost Shelter: 15 oak_log, 10 river_clay
        engine.inventory = engine.inventory.copyWith(capacity: 30);
        for (int i = 0; i < 15; i++) {
          engine.inventory = engine.inventory.addItem(Items.oakLog, 1);
        }
        for (int i = 0; i < 10; i++) {
          engine.inventory = engine.inventory.addItem(Items.riverClay, 1);
        }

        // Build Outpost Shelter
        engine.startBuilding(Structures.outpostShelter, 'whispering_woods_1');
        async.elapse(const Duration(seconds: 20));

        expect(engine.hasStructureInZone('whispering_woods_1', 'outpost_shelter'), true);

        // Set player health and energy to low values to test recovery
        engine.playerStats = engine.playerStats.copyWith(
          currentHealth: 30,
          currentEnergy: 20,
        );

        // Rest in Shelter (defined as id: shelter_rest, healthCost: -20, energyCost: -30)
        const shelterRestAction = ZoneAction(
          id: 'shelter_rest',
          name: 'Rest in Shelter',
          description: 'Rest inside the outpost shelter to recover health and energy for free.',
          durationSeconds: 4,
          energyCost: -30,
          healthCost: -20,
          xpReward: 5,
          requiredSkill: SkillType.wayfinding,
          requiredLevel: 1,
          lootTable: [],
        );

        engine.startAction(shelterRestAction);
        expect(engine.activeAction, isNotNull);

        async.elapse(const Duration(seconds: 4));

        // After completion, health and energy should be recovered
        // health: 30 - (-20) = 50. energy: 20 - (-30) = 50.
        expect(engine.playerStats.currentHealth, 50);
        expect(engine.playerStats.currentEnergy, 50);
        expect(engine.skills[SkillType.wayfinding]?.xp, 1065.0); // +60 for building, +5 for resting
        expect(engine.logs.any((e) => e.message.contains('You rested in the shelter')), true);
      });
    });

    test('Engine reset clears all built structures', () {
      fakeAsync((async) {
        // Travel to Whispering Woods Tier 1
        engine.unlockZone('whispering_woods_1');
        engine.travelTo(Zones.whisperingWoodsTier1);

        // Build Crafting Bench
        engine.skills[SkillType.crafting] = SkillState(
          type: SkillType.crafting,
          level: 5,
          xp: 1000,
          levelCap: 10,
        );
        engine.inventory = engine.inventory.copyWith(capacity: 30);
        for (int i = 0; i < 10; i++) {
          engine.inventory = engine.inventory.addItem(Items.oakLog, 1);
        }
        for (int i = 0; i < 5; i++) {
          engine.inventory = engine.inventory.addItem(Items.riverClay, 1);
        }
        for (int i = 0; i < 2; i++) {
          engine.inventory = engine.inventory.addItem(Items.copperOre, 1);
        }

        engine.startBuilding(Structures.craftingBench, 'whispering_woods_1');
        async.elapse(const Duration(seconds: 15));

        expect(engine.hasStructureInZone('whispering_woods_1', 'crafting_bench'), true);

        // Reset game
        engine.resetGame();

        // Structure list for the zone should be empty/cleared
        expect(engine.hasStructureInZone('whispering_woods_1', 'crafting_bench'), false);
        expect(engine.getBuiltStructuresForZone('whispering_woods_1'), isEmpty);
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/item.dart';
import 'package:flutter_text_based_rpg/models/recipe.dart';

void main() {
  group('Driftwood substitution for oak_log', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
    });

    test('Recipe with driftwood available passes _hasInputsForRecipe', () {
      engine.inventory = engine.inventory.addItem(Items.driftwood, 5);
      engine.inventory = engine.inventory.addItem(Items.riverClay, 5);
      final stoneAxe = Recipes.all.firstWhere((r) => r.id == 'stone_axe');
      expect(engine.hasInputsForRecipeForTest(stoneAxe), true);
    });

    test('Recipe with no oak or driftwood fails _hasInputsForRecipe', () {
      final stoneAxe = Recipes.all.firstWhere((r) => r.id == 'stone_axe');
      expect(engine.hasInputsForRecipeForTest(stoneAxe), false);
    });

    test('Driftwood is consumed when oak_log not available', () {
      engine.inventory = engine.inventory.addItem(Items.driftwood, 5);
      engine.inventory = engine.inventory.addItem(Items.riverClay, 5);
      final stoneAxe = Recipes.all.firstWhere((r) => r.id == 'stone_axe');
      final consumed = engine.consumeInputsForRecipeForTest(stoneAxe);
      expect(consumed['driftwood'], greaterThan(0));
      expect(consumed['oak_log'] ?? 0, 0);
    });

    test('Quality bias +0.03 when driftwood substituted for oak_log', () {
      final stoneAxe = Recipes.all.firstWhere((r) => r.id == 'stone_axe');
      final consumed = {'driftwood': 3, 'river_clay': 2};  // 3 driftwood as oak substitute
      expect(engine.calculateRecipeQualityBiasForTest(stoneAxe, consumed), closeTo(0.03, 0.001));
    });
  });
}

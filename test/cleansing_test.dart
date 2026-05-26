import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/item.dart';
import 'package:flutter_text_based_rpg/models/masterwork.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';
import 'package:flutter_text_based_rpg/models/codex.dart';
import 'package:flutter_text_based_rpg/models/milestone.dart';

void main() {
  group('Cleansing ritual tasks', () {
    test('3 cleansing rituals exist', () {
      for (final id in ['cleansing_wilds', 'cleansing_stone', 'cleansing_tide']) {
        expect(MasterworkTasks.findById(id), isNotNull, reason: 'Missing: $id');
      }
    });

    test('Each cleansing ritual has 3 steps (start + 2 terminals)', () {
      for (final id in ['cleansing_wilds', 'cleansing_stone', 'cleansing_tide']) {
        final task = MasterworkTasks.findById(id)!;
        expect(task.steps.length, 3, reason: 'Wrong step count for $id');
      }
    });

    test('Each terminal option has isSuccess: true', () {
      for (final id in ['cleansing_wilds', 'cleansing_stone', 'cleansing_tide']) {
        final task = MasterworkTasks.findById(id)!;
        final terminals = task.steps.values
            .expand((s) => s.options)
            .where((o) => o.nextStepId == null);
        expect(terminals.length, 2);
        expect(terminals.every((o) => o.isSuccess), true);
      }
    });
  });

  group('Cleansing dispatch & visibility', () {
    test('Burn action visibility gates', () {
      final engine = GameEngine();
      engine.travelTo(Zones.townSquare);
      // Not visible without essence
      expect(engine.isActionVisible(Zones.townSquare.actions.firstWhere((a) => a.id == 'burn_wilds_echo_essence')), false);

      // Add essence
      engine.inventory = engine.inventory.addItem(Items.wildsEchoEssence, 1);
      expect(engine.isActionVisible(Zones.townSquare.actions.firstWhere((a) => a.id == 'burn_wilds_echo_essence')), true);

      // Cleanse it
      engine.setEngineFlag('breach_wilds_cleansed');
      expect(engine.isActionVisible(Zones.townSquare.actions.firstWhere((a) => a.id == 'burn_wilds_echo_essence')), false);
    });

    test('Burn action consumes Essence and launches ritual', () {
      final engine = GameEngine();
      engine.travelTo(Zones.townSquare);
      engine.inventory = engine.inventory.addItem(Items.wildsEchoEssence, 1);
      engine.completeActionForTest('burn_wilds_echo_essence');

      expect(engine.inventory.hasItem('wilds_echo_essence', 1), false);
      expect(engine.activeMasterwork?.task.id, 'cleansing_wilds');
    });

    test('Cleansing success sets breach flag + grants Token + sets first_breach_cleansed', () {
      final engine = GameEngine();
      engine.travelTo(Zones.townSquare);
      engine.inventory = engine.inventory.addItem(Items.wildsEchoEssence, 1);
      engine.completeActionForTest('burn_wilds_echo_essence');
      engine.completeMasterworkForTest('cleansing_wilds', useFirstSuccessOption: true);

      expect(engine.engineFlags.contains('breach_wilds_cleansed'), true);
      expect(engine.engineFlags.contains('first_breach_cleansed'), true);
      expect(engine.inventory.hasItem('wilds_cleansing_token', 1), true);
    });

    test('All-three cleansed sets nexus_unlockable and offers Source Convergence', () {
      final engine = GameEngine();
      engine.travelTo(Zones.townSquare);
      // Force all 3 cleansings
      for (final tag in ['wilds', 'stone', 'tide']) {
        engine.inventory = engine.inventory.addItem(Items.findById('${tag}_echo_essence')!, 1);
        engine.completeActionForTest('burn_${tag}_echo_essence');
        engine.completeMasterworkForTest('cleansing_$tag', useFirstSuccessOption: true);
      }

      expect(engine.engineFlags.contains('nexus_unlockable'), true);
      expect(engine.activeQuests.any((q) => q.id == 'main_source_convergence'), true);
    });
  });

  group('Spec 5 milestones existence', () {
    test('7 new milestones exist', () {
      final ids = Milestones.all.map((m) => m.id).toSet();
      for (final id in [
        'bloomwither_entered', 'glowing_vein_entered', 'drowned_lighthouse_spoken',
        'breach_wilds_cleansed_milestone', 'breach_stone_cleansed_milestone',
        'breach_tide_cleansed_milestone', 'all_breaches_cleansed_milestone',
      ]) {
        expect(ids, contains(id), reason: 'Missing milestone: $id');
      }
    });
  });
}

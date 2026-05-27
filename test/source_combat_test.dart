import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/beast.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';
import 'package:flutter_text_based_rpg/models/item.dart';
import 'package:flutter_text_based_rpg/models/quest.dart';
import 'package:flutter_text_based_rpg/models/combat.dart';
import 'package:flutter_text_based_rpg/models/codex.dart';

void main() {
  group('Source Combat Tests', () {
    test('The Source model exists and has correct stats & phases', () {
      final source = Beasts.findById('the_source');
      expect(source, isNotNull);
      expect(source!.maxHealth, 1100);
      expect(source.phases, isNotNull);
      expect(source.phases!.length, 3);
      expect(source.phases![0].hpThreshold, 1.00);
      expect(source.phases![0].passive, BeastPassive.sourceQuake);
      expect(source.phases![1].hpThreshold, 0.66);
      expect(source.phases![1].passive, BeastPassive.sourceSedimentStack);
      expect(source.phases![2].hpThreshold, 0.33);
      expect(source.phases![2].passive, BeastPassive.sourcePollenCloud);
    });

    test('Quake passive (P1) drains energy on round % 3 == 0, telegraphs round % 3 == 2', () {
      final engine = GameEngine();
      engine.resetGame();
      
      // Start combat against the Source
      engine.setEngineFlag('nexus_unlockable');
      engine.inventory = engine.inventory.addItem(Items.findById('wilds_cleansing_token')!, 1);
      engine.inventory = engine.inventory.addItem(Items.findById('stone_cleansing_token')!, 1);
      engine.inventory = engine.inventory.addItem(Items.findById('tide_cleansing_token')!, 1);
      engine.travelTo(Zones.nexusOfEchoes);
      
      // Start combat confront_the_source
      engine.startAction(Zones.nexusOfEchoes.actions.first);
      
      // Initially: Quake counter is 0
      expect(engine.activeCombat, isNotNull);
      expect(engine.activeCombat!.sourceQuakeCounter, 0);
      expect(engine.playerStats.currentEnergy, 100);

      // Round 1
      engine.setCombatStance(PlayerStance.strike);
      expect(engine.activeCombat!.sourceQuakeCounter, 1);
      expect(engine.activeCombat!.combatLog.any((l) => l.contains('trembles')), false);

      // Round 2 -> should telegraph
      engine.setCombatStance(PlayerStance.strike);
      expect(engine.activeCombat!.sourceQuakeCounter, 2);
      expect(engine.activeCombat!.combatLog.any((l) => l.contains('The ground beneath you trembles violently.')), true);
      expect(engine.playerStats.currentEnergy, 100); // no drain yet

      // Round 3 -> should drain 10 energy
      engine.setCombatStance(PlayerStance.strike);
      expect(engine.activeCombat!.sourceQuakeCounter, 3);
      expect(engine.activeCombat!.combatLog.any((l) => l.contains('The ground erupts in a quake! You lose 10 energy.')), true);
      expect(engine.playerStats.currentEnergy, 90);
    });

    test('Sediment Stack passive (P2) blocks 4th strike, resets to 0 on exit', () {
      final engine = GameEngine();
      engine.resetGame();

      engine.setEngineFlag('nexus_unlockable');
      engine.inventory = engine.inventory.addItem(Items.findById('wilds_cleansing_token')!, 1);
      engine.inventory = engine.inventory.addItem(Items.findById('stone_cleansing_token')!, 1);
      engine.inventory = engine.inventory.addItem(Items.findById('tide_cleansing_token')!, 1);
      engine.travelTo(Zones.nexusOfEchoes);
      engine.startAction(Zones.nexusOfEchoes.actions.first);

      // Force HP to P2 threshold (e.g. 700 HP)
      engine.setBeastHpForTest(700);
      
      // Tick combat round to trigger transition checks
      engine.setCombatStance(PlayerStance.readTells);
      expect(engine.activeCombat!.activePhasePassive, BeastPassive.sourceSedimentStack);
      expect(engine.activeCombat!.sourceSedimentStacks, 0);

      // 1st Strike -> lands, stacks = 1
      engine.setCombatStance(PlayerStance.strike);
      expect(engine.activeCombat!.sourceSedimentStacks, 1);

      // 2nd Strike -> lands, stacks = 2
      engine.setCombatStance(PlayerStance.strike);
      expect(engine.activeCombat!.sourceSedimentStacks, 2);

      // 3rd Strike -> lands, stacks = 3 (telegraph warning)
      engine.setCombatStance(PlayerStance.strike);
      expect(engine.activeCombat!.sourceSedimentStacks, 3);
      expect(engine.activeCombat!.combatLog.any((l) => l.contains('Sediment thickens')), true);

      // 4th Strike -> blocked (deals 0 damage, consumes stacks, resets to 0)
      final preBeastHp = engine.activeCombat!.beastCurrentHealth;
      engine.setCombatStance(PlayerStance.strike);
      expect(engine.activeCombat!.sourceSedimentStacks, 0);
      expect(engine.activeCombat!.beastCurrentHealth, preBeastHp);
      expect(engine.activeCombat!.combatLog.any((l) => l.contains('Your strike sinks into sediment')), true);

      // Defeat to transition into P3 -> sediment stacks should reset to 0
      engine.setBeastHpForTest(360); // below 33% (363 HP)
      
      // Trigger round -> P3 transition resets sediment stacks to 0
      engine.setCombatStance(PlayerStance.readTells);
      expect(engine.activeCombat!.activePhasePassive, BeastPassive.sourcePollenCloud);
      expect(engine.activeCombat!.sourceSedimentStacks, 0);
    });

    test('Pollen Cloud passive (P3) randomizes player stance on round % 2 == 0', () {
      final engine = GameEngine(seed: 42); // seed for deterministic stance roll
      engine.resetGame();

      engine.setEngineFlag('nexus_unlockable');
      engine.inventory = engine.inventory.addItem(Items.findById('wilds_cleansing_token')!, 1);
      engine.inventory = engine.inventory.addItem(Items.findById('stone_cleansing_token')!, 1);
      engine.inventory = engine.inventory.addItem(Items.findById('tide_cleansing_token')!, 1);
      engine.travelTo(Zones.nexusOfEchoes);
      engine.startAction(Zones.nexusOfEchoes.actions.first);

      // Force HP to P3 threshold (e.g. 300 HP)
      engine.setBeastHpForTest(300);
      
      // Trigger P3 transition (transition happens at the end of this round)
      engine.setCombatStance(PlayerStance.readTells);
      expect(engine.activeCombat!.activePhasePassive, BeastPassive.sourcePollenCloud);
      expect(engine.activeCombat!.sourcePollenCounter, 0); // 0 at the end of transition round

      // First round of P3 (counter becomes 1, odd round, stance should not randomize)
      engine.setCombatStance(PlayerStance.readTells);
      expect(engine.activeCombat!.sourcePollenCounter, 1);

      // Second round of P3 (counter becomes 2, even round, stance randomizes!)
      // Let's request heavyStrike and see what it shifts to
      engine.setCombatStance(PlayerStance.heavyStrike);
      expect(engine.activeCombat!.sourcePollenCounter, 2);
      expect(engine.activeCombat!.combatLog.any((l) => l.contains('Pollen clouds your sight')), true);
    });

    test('Source victory cleanses tokens, rewards achievement, sets title, triggers modal and ambient logs', () {
      final engine = GameEngine();
      engine.resetGame();

      // Cleanse breaches & add tokens
      engine.cleanseAllBreachesForTest();
      engine.travelTo(Zones.nexusOfEchoes);

      expect(engine.inventory.hasItem('wilds_cleansing_token', 1), true);
      expect(engine.playerStats.title, 'Wayfarer'); // default title

      // Defeat the Source
      engine.runCombatToVictoryForTest('the_source');

      // Tokens are consumed
      expect(engine.inventory.hasItem('wilds_cleansing_token', 1), false);
      expect(engine.inventory.hasItem('stone_cleansing_token', 1), false);
      expect(engine.inventory.hasItem('tide_cleansing_token', 1), false);

      // Flag, achievement, quest complete, milestone
      expect(engine.engineFlags.contains('source_cleanser'), true);
      expect(engine.earnedAchievementIds, contains('source_cleansed'));
      expect(engine.playerStats.title, 'Source Cleanser');
      expect(engine.shouldShowYouWinModal, true);
      expect(engine.firedMilestoneIdsForTest, contains('source_defeated'));

      // Check Ambient 1: Travel to town square
      expect(engine.logs.any((e) => e.message.contains('cartographer raises his cup')), false);
      engine.travelTo(Zones.townSquare);
      expect(engine.logs.any((e) => e.message.contains('cartographer raises his cup')), true);

      // Check Ambient 2: Visit merchant
      expect(engine.logs.any((e) => e.message.contains('shopkeeper hesitates')), false);
      engine.setActiveMerchantIndex(0);
      expect(engine.logs.any((e) => e.message.contains('shopkeeper hesitates')), true);

      // Check Ambient 3: Non-town overworld action complete
      expect(engine.logs.any((e) => e.message.contains('The light is different now')), false);
      engine.travelTo(Zones.findById('whispering_woods_1')!);
      engine.completeActionForTest('chop_oak');
      expect(engine.logs.any((e) => e.message.contains('The light is different now')), true);

      // Reset clears everything
      engine.resetGame();
      expect(engine.engineFlags.contains('source_cleanser'), false);
      expect(engine.shouldShowYouWinModal, false);
      expect(engine.playerStats.title, 'Wayfarer');
    });
  });
}

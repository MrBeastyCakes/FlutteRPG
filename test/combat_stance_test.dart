import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/combat.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/beast.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';
import 'package:flutter_text_based_rpg/models/weather.dart';
import 'package:flutter_text_based_rpg/models/skill.dart';
import 'package:flutter_text_based_rpg/models/item.dart';

void main() {
  group('PlayerStance enum', () {
    test('5 stances exist', () {
      expect(PlayerStance.values.length, 5);
      expect(PlayerStance.values, containsAll([
        PlayerStance.strike,
        PlayerStance.heavyStrike,
        PlayerStance.defend,
        PlayerStance.readTells,
        PlayerStance.item,
      ]));
    });

    test('CombatRound holds round number and damage stats', () {
      const round = CombatRound(
        roundNumber: 3,
        chosenStance: PlayerStance.defend,
        playerDamageDealt: 0,
        playerDamageTaken: 4,
        wasCrit: false,
      );
      expect(round.roundNumber, 3);
      expect(round.chosenStance, PlayerStance.defend);
      expect(round.wasCrit, false);
    });

    test('BeastTelegraph carries abilityId, text, and reveal flag', () {
      const tg = BeastTelegraph(
        abilityId: 'charge',
        text: 'The boar paws the dirt.',
        reveal: false,
      );
      expect(tg.abilityId, 'charge');
      expect(tg.reveal, false);
    });
  });

  group('Stance API & Round Resolution', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
      engine.unlockZone('whispering_woods_1');
      engine.travelTo(Zones.whisperingWoodsTier1);
      engine.startBoarHuntForTest(); // helper to begin combat against Forest Boar
    });

    test('setCombatStance assigns pending stance on active combat', () {
      engine.setCombatStance(PlayerStance.strike);
      // It immediately resolves when we set it, clearing pendingStance back to null
      expect(engine.activeCombat!.pendingStance, isNull);
      expect(engine.activeCombat!.currentRoundNumber, 2);
    });

    test('Heavy Strike costs 5 energy by default (no Berserker spec)', () {
      final energyBefore = engine.playerStats.currentEnergy;
      engine.setCombatStance(PlayerStance.heavyStrike);
      expect(engine.playerStats.currentEnergy, energyBefore - 5);
    });

    test('Defend costs 2 energy', () {
      final energyBefore = engine.playerStats.currentEnergy;
      engine.setCombatStance(PlayerStance.defend);
      expect(engine.playerStats.currentEnergy, energyBefore - 2);
    });

    test('Strike costs 0 energy', () {
      final energyBefore = engine.playerStats.currentEnergy;
      engine.setCombatStance(PlayerStance.strike);
      expect(engine.playerStats.currentEnergy, energyBefore);
    });

    test('Stance is blocked when energy is insufficient', () {
      // Reduce energy below Heavy Strike cost
      engine.setPlayerStatsForTest(engine.playerStats.copyWith(currentEnergy: 3));
      engine.setCombatStance(PlayerStance.heavyStrike);
      // No round progress, currentRoundNumber stays at 1
      expect(engine.activeCombat!.currentRoundNumber, 1);
    });

    test('Strike deals base damage to beast', () {
      final beastHpBefore = engine.activeCombat!.beastCurrentHealth;
      engine.setCombatStance(PlayerStance.strike);
      expect(engine.activeCombat!.beastCurrentHealth, lessThan(beastHpBefore));
    });

    test('Heavy Strike deals more damage than Strike', () {
      final beastHp1 = engine.activeCombat!.beastCurrentHealth;
      engine.setCombatStance(PlayerStance.heavyStrike);
      final dmg1 = beastHp1 - engine.activeCombat!.beastCurrentHealth;

      // Reset
      engine.startBoarHuntForTest();
      final beastHp2 = engine.activeCombat!.beastCurrentHealth;
      engine.setCombatStance(PlayerStance.strike);
      final dmg2 = beastHp2 - engine.activeCombat!.beastCurrentHealth;

      expect(dmg1, greaterThan(dmg2));
    });

    test('Defend halves incoming damage', () {
      final playerHpBefore = engine.playerStats.currentHealth;
      engine.setCombatStance(PlayerStance.defend);
      final defendDmg = playerHpBefore - engine.playerStats.currentHealth;

      engine.startBoarHuntForTest();
      final playerHpBefore2 = engine.playerStats.currentHealth;
      engine.setCombatStance(PlayerStance.strike);
      final strikeDmg = playerHpBefore2 - engine.playerStats.currentHealth;

      expect(defendDmg, lessThan(strikeDmg));
    });

    test('Default Strike fires on timer expiry without input', () {
      final beastHpBefore = engine.activeCombat!.beastCurrentHealth;
      // Force timer expiry
      engine.tickRoundTimerForTest(const Duration(seconds: 3));
      expect(engine.activeCombat!.beastCurrentHealth, lessThan(beastHpBefore));
    });
  });

  group('Sea Fog crit', () {
    test('Sea Fog in Coast zone adds +20% crit chance', () {
      final engine = GameEngine();
      engine.setEngineFlag('coast_unlocked');
      engine.unlockZone('sundered_coast_1');
      engine.travelTo(Zones.sunderedCoastTier1);
      engine.forceCoastWeatherForTest(CoastWeather.seaFog);
      // Run 100 attacks; expect ~20% crit rate
      int crits = 0;
      for (int i = 0; i < 100; i++) {
        engine.setPlayerStatsForTest(engine.playerStats.copyWith(currentHealth: engine.playerStats.maxHealth));
        engine.startBoarHuntForTest();
        engine.setCombatStance(PlayerStance.strike);
        if (engine.activeCombat!.roundHistory.last.wasCrit) crits++;
      }
      expect(crits, inInclusiveRange(10, 35)); // ~20% with variance
    });

    test('Calm weather has no crit bonus', () {
      final engine = GameEngine();
      engine.setEngineFlag('coast_unlocked');
      engine.unlockZone('sundered_coast_1');
      engine.travelTo(Zones.sunderedCoastTier1);
      engine.forceCoastWeatherForTest(CoastWeather.calm);
      int crits = 0;
      for (int i = 0; i < 100; i++) {
        engine.setPlayerStatsForTest(engine.playerStats.copyWith(currentHealth: engine.playerStats.maxHealth));
        engine.startBoarHuntForTest();
        engine.setCombatStance(PlayerStance.strike);
        if (engine.activeCombat!.roundHistory.last.wasCrit) crits++;
      }
      expect(crits, lessThan(5)); // baseline near-zero crit
    });
  });

  group('Quick-Slot Bar engine state', () {
    test('Default 3 empty slots', () {
      final engine = GameEngine();
      expect(engine.quickslots.length, 3);
      expect(engine.quickslots, [null, null, null]);
    });

    test('setQuickslot stores an itemId', () {
      final engine = GameEngine();
      engine.setQuickslot(0, 'baked_potato');
      expect(engine.quickslots[0], 'baked_potato');
    });

    test('setQuickslot rejects non-food items', () {
      final engine = GameEngine();
      engine.setQuickslot(0, 'oak_log'); // resource, not food
      expect(engine.quickslots[0], isNull);
    });

    test('useQuickslot out of combat heals/energizes player and clears slot', () {
      final engine = GameEngine();
      engine.inventory = engine.inventory.addItem(Items.bakedPotato, 1);
      engine.setQuickslot(0, 'baked_potato');
      engine.setPlayerStatsForTest(engine.playerStats.copyWith(currentHealth: 50));
      final hpBefore = engine.playerStats.currentHealth;
      engine.useQuickslot(0);
      expect(engine.playerStats.currentHealth, greaterThan(hpBefore));
      expect(engine.quickslots[0], isNull);
    });
  });
}

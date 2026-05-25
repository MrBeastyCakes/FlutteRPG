import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/beast.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/combat.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';

void main() {
  group('BeastAbility assignments', () {
    test('Forest Boar has Charge ability with bigHit effect', () {
      final ability = Beasts.forestBoar.ability;
      expect(ability, isNotNull);
      expect(ability!.id, 'charge');
      expect(ability.effect, BeastSpecialEffect.bigHit);
      expect(ability.cooldownRounds, 3);
    });

    test('Cave Spider has Web ability with stun effect', () {
      expect(Beasts.caveSpider.ability!.effect, BeastSpecialEffect.stun);
    });

    test('Shadow Wolf has Howl ability with summonAlly effect', () {
      expect(Beasts.shadowWolf.ability!.effect, BeastSpecialEffect.summonAlly);
    });

    test('Cavern Troll has Smash ability with bigHitStun effect', () {
      expect(Beasts.cavernTroll.ability!.effect, BeastSpecialEffect.bigHitStun);
    });

    test('Tide Hound has Salt Splash with accuracyDebuff', () {
      expect(Beasts.tideHound.ability!.effect, BeastSpecialEffect.accuracyDebuff);
    });

    test('Brine Crawler has Pincer Lock with drainOverTime', () {
      expect(Beasts.brineCrawler.ability!.effect, BeastSpecialEffect.drainOverTime);
    });

    test('Salt-Touched Drowned has Death Wail with bigHitStun', () {
      expect(Beasts.saltTouchedDrowned.ability!.effect, BeastSpecialEffect.bigHitStun);
    });
  });

  group('Telegraph behavior', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
      engine.unlockZone('whispering_woods_1');
      engine.travelTo(Zones.whisperingWoodsTier1);
      engine.startBoarHuntForTest();
    });

    test('Telegraph appears on round 2 (before round 3 ability fires)', () {
      expect(engine.activeCombat!.activeTelegraph, isNull);
      engine.setCombatStance(PlayerStance.strike); // round 1
      expect(engine.activeCombat!.activeTelegraph, isNull);
      engine.setCombatStance(PlayerStance.strike); // round 2
      expect(engine.activeCombat!.activeTelegraph, isNotNull);
      expect(engine.activeCombat!.activeTelegraph!.abilityId, 'charge');
      expect(engine.activeCombat!.activeTelegraph!.reveal, false);
    });

    test('Defend during telegraph round halves incoming Charge', () {
      engine.setCombatStance(PlayerStance.strike);
      engine.setCombatStance(PlayerStance.strike); // telegraph appears
      final hpBefore = engine.playerStats.currentHealth;
      engine.setCombatStance(PlayerStance.defend); // Charge fires this round
      final dmgWithDefend = hpBefore - engine.playerStats.currentHealth;

      engine.startBoarHuntForTest();
      engine.setCombatStance(PlayerStance.strike);
      engine.setCombatStance(PlayerStance.strike);
      final hpBefore2 = engine.playerStats.currentHealth;
      engine.setCombatStance(PlayerStance.strike); // take full Charge
      final dmgWithStrike = hpBefore2 - engine.playerStats.currentHealth;

      expect(dmgWithDefend, lessThan(dmgWithStrike));
    });

    test('Read Tells reveals telegraph', () {
      engine.setCombatStance(PlayerStance.strike);
      engine.setCombatStance(PlayerStance.strike); // telegraph appears
      expect(engine.activeCombat!.activeTelegraph!.reveal, false);
      engine.setCombatStance(PlayerStance.readTells);
      expect(engine.activeCombat!.activeTelegraph!.reveal, true);
    });
  });
}

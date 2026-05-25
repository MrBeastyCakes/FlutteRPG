import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/weather.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';
import 'package:flutter_text_based_rpg/models/codex.dart';


void main() {
  group('Coast Weather Tests', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
    });

    test('Storm chance is 0.05 baseline with no fragments', () {
      expect(engine.calculateStormChancePublic(), 0.05);
    });

    test('Storm chance rises +0.05 per breach-tag with fragments (capped at 0.50)', () {
      // Add a wilds fragment
      engine.tryDropFragment(CodexTag.wilds, 1.0);
      expect(engine.calculateStormChancePublic(), closeTo(0.10, 0.001));

      // Add a stone fragment (opens stone pool first)
      engine.recordRegionDiscovered('darkstone_mine_1');
      engine.tryDropFragment(CodexTag.stone, 1.0);
      expect(engine.calculateStormChancePublic(), closeTo(0.15, 0.001));

      // Add a tide fragment (opens tide pool first)
      engine.setEngineFlag('coast_unlocked');
      engine.tryDropFragment(CodexTag.tide, 1.0);
      expect(engine.calculateStormChancePublic(), closeTo(0.20, 0.001));
    });

    test('Cleansing flag reduces storm chance', () {
      engine.tryDropFragment(CodexTag.wilds, 1.0);
      expect(engine.calculateStormChancePublic(), 0.10);

      // Cleanse wilds breach
      engine.setEngineFlag('breach_wilds_cleansed');
      expect(engine.calculateStormChancePublic(), 0.05);
    });

    test('Storm Swell blocks travelTo Coast zones, Calm allows it', () {
      // Unlock Coast I first
      engine.unlockZone('sundered_coast_1');

      // Calm weather
      engine.forceCoastWeatherForTest(CoastWeather.calm);
      engine.travelTo(Zones.sunderedCoastTier1);
      expect(engine.currentZone.id, 'sundered_coast_1');

      // Go back to town square
      engine.travelTo(Zones.townSquare);
      expect(engine.currentZone.id, 'town_square');

      // Force Storm Swell
      engine.forceCoastWeatherForTest(CoastWeather.stormSwell);
      engine.travelTo(Zones.sunderedCoastTier1);
      // Travel should be blocked, player remains in Town Square
      expect(engine.currentZone.id, 'town_square');
    });
  });
}

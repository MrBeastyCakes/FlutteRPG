import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/random_event.dart';
import 'package:flutter_text_based_rpg/models/item.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';

void main() {
  group('Random Event model', () {
    test('EventCategory has 4 values', () {
      expect(EventCategory.values.length, 4);
      expect(EventCategory.values, containsAll([
        EventCategory.interruption,
        EventCategory.discovery,
        EventCategory.traveler,
        EventCategory.omen,
      ]));
    });

    test('EventRewardKind has 4 values', () {
      expect(EventRewardKind.values.length, 4);
      expect(EventRewardKind.values, containsAll([
        EventRewardKind.item,
        EventRewardKind.gold,
        EventRewardKind.skillXp,
        EventRewardKind.fragment,
      ]));
    });
  });

  group('New items', () {
    test('Honeycomb exists as food', () {
      final i = Items.findById('honeycomb')!;
      expect(i.type, ItemType.food);
      expect(i.healAmount, 8);
      expect(i.energyAmount, 12);
    });

    test("Traveler's Feather exists as resource", () {
      final i = Items.findById('travelers_feather')!;
      expect(i.type, ItemType.resource);
      expect(i.value, 25);
    });
  });

  group('Event Registry', () {
    test('contains 20 total events', () {
      expect(RandomEvents.all.length, 20);
    });

    test('has exactly 5 events per category', () {
      final categoriesCount = <EventCategory, int>{};
      for (final event in RandomEvents.all) {
        categoriesCount[event.category] = (categoriesCount[event.category] ?? 0) + 1;
      }
      expect(categoriesCount[EventCategory.interruption], 5);
      expect(categoriesCount[EventCategory.discovery], 5);
      expect(categoriesCount[EventCategory.traveler], 5);
      expect(categoriesCount[EventCategory.omen], 5);
    });

    test('all events have unique IDs', () {
      final ids = RandomEvents.all.map((e) => e.id).toSet();
      expect(ids.length, 20);
    });

    test('bee_swarm options are correctly configured', () {
      final beeSwarm = RandomEvents.all.firstWhere((e) => e.id == 'bee_swarm');
      expect(beeSwarm.options.length, 3);
      expect(beeSwarm.options[0].text, 'Endure the stings');
      expect(beeSwarm.options[0].healthCost, 8);
      expect(beeSwarm.options[1].text, 'Smoke them out');
      expect(beeSwarm.options[1].requiredItemId, 'oak_log');
      expect(beeSwarm.options[2].text, 'Retreat');
    });
  });

  group('Random event engine', () {
    test('Forced event becomes active and emits on stream', () async {
      final engine = GameEngine();
      final events = <RandomEvent>[];
      final sub = engine.randomEvents.listen(events.add);

      engine.forceRandomEventForTest(RandomEvents.beeSwarm);
      expect(engine.activeRandomEvent, isNotNull);
      expect(engine.activeRandomEvent!.event.id, 'bee_swarm');
      await Future.delayed(Duration.zero);
      expect(events.length, 1);
      await sub.cancel();
    });

    test('Resolve event clears active state', () {
      final engine = GameEngine();
      engine.forceRandomEventForTest(RandomEvents.beeSwarm);
      engine.resolveRandomEvent(2);  // Retreat option
      expect(engine.activeRandomEvent, isNull);
    });

    test('Resolve grants rewards (item)', () {
      final engine = GameEngine();
      engine.forceRandomEventForTest(RandomEvents.beeSwarm);
      final wildflowerBefore = engine.inventory.getItemCount('wildflower');
      engine.resolveRandomEvent(0);  // Endure option
      expect(engine.inventory.getItemCount('wildflower'), wildflowerBefore + 2);
    });
  });
}

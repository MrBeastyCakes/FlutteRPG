import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/beast.dart';

void main() {
  group('Coast beasts', () {
    test('3 new Coast beasts exist with expected stats', () {
      final hound = Beasts.findById('tide_hound')!;
      expect(hound.maxHealth, 40);
      expect(hound.attackPower, 6);

      final crawler = Beasts.findById('brine_crawler')!;
      expect(crawler.maxHealth, 75);
      expect(crawler.attackPower, 12);

      final drowned = Beasts.findById('salt_touched_drowned')!;
      expect(drowned.maxHealth, 140);
      expect(drowned.attackPower, 20);
    });

    test('Coast beasts slot between existing Forest/Cave beasts on HP', () {
      // Tide Hound (40) between Forest Boar (35) and Cave Spider (55)
      expect(Beasts.findById('tide_hound')!.maxHealth, greaterThan(Beasts.findById('forest_boar')!.maxHealth));
      expect(Beasts.findById('tide_hound')!.maxHealth, lessThan(Beasts.findById('cave_spider')!.maxHealth));
      // Salt-Touched Drowned (140) under Cavern Troll (160)
      expect(Beasts.findById('salt_touched_drowned')!.maxHealth, lessThan(Beasts.findById('cavern_troll')!.maxHealth));
    });
  });
}

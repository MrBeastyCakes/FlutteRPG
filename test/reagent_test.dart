import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/item.dart';

void main() {
  group('Spec 6a items', () {
    test('6 reagent items exist with single-emoji icons', () {
      for (final id in ['moonpetal', 'spirit_sap', 'hollow_bone', 'sea_tear', 'coalblood', 'wisp_light']) {
        final item = Items.findById(id);
        expect(item, isNotNull, reason: 'Missing: $id');
        expect(item!.icon.runes.length, lessThanOrEqualTo(2), reason: 'Compound emoji forbidden: $id');
      }
    });

    test('Wisp-Light is highest-value reagent (200g)', () {
      expect(Items.findById('wisp_light')!.value, 200);
    });

    test('Bram Trusted Patron items exist', () {
      for (final id in ['tinkers_bauble', 'elixir_of_twilight', 'taverns_best']) {
        expect(Items.findById(id), isNotNull, reason: 'Missing: $id');
      }
    });

    test("Elixir of Twilight restores 30 HP and 50 energy", () {
      final item = Items.findById('elixir_of_twilight')!;
      expect(item.healAmount, 30);
      expect(item.energyAmount, 50);
    });
  });
}

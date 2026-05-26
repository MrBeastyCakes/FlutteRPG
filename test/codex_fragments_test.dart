import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/codex.dart';

void main() {
  group('CodexFragments data invariants', () {
    test('Exactly 56 fragments exist', () {
      expect(CodexFragments.all.length, 56);
    });

    test('Each tag has exactly 10 fragments', () {
      for (final tag in [
        CodexTag.wilds,
        CodexTag.stone,
        CodexTag.tide,
        CodexTag.source,
        CodexTag.oldEmpire,
      ]) {
        final count = CodexFragments.all.where((f) => f.tag == tag).length;
        expect(count, 10, reason: 'Tag $tag should have 10 fragments');
      }
    });

    test('Every fragment has a unique id', () {
      final ids = CodexFragments.all.map((f) => f.id).toSet();
      expect(ids.length, 56);
    });

    test('Every (tag, orderInTag) pair is unique', () {
      final pairs = CodexFragments.all
          .map((f) => '${f.tag.name}_${f.orderInTag}')
          .toSet();
      expect(pairs.length, 56);
    });

    test('Each tag has orderInTag values 1 through 10', () {
      for (final tag in CodexTag.values.where((t) => t != CodexTag.misc)) {
        final orders = CodexFragments.all
            .where((f) => f.tag == tag)
            .map((f) => f.orderInTag)
            .toSet();
        expect(orders, {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
            reason: 'Tag $tag should have orderInTag 1..10');
      }
    });

    test('findById returns the right fragment for a sample of ids', () {
      final fragment = CodexFragments.findById('wilds_01');
      expect(fragment, isNotNull);
      expect(fragment!.tag, CodexTag.wilds);
      expect(fragment.orderInTag, 1);
    });

    test('findById returns null for unknown id', () {
      expect(CodexFragments.findById('nonexistent'), isNull);
    });
  });

  group('CodexReadings data invariants', () {
    test('CodexReadings.forTag returns non-null for each playable tag', () {
      for (final tag in [
        CodexTag.wilds,
        CodexTag.stone,
        CodexTag.tide,
        CodexTag.source,
        CodexTag.oldEmpire,
      ]) {
        expect(CodexReadings.forTag(tag), isNotNull,
            reason: 'Reading missing for tag $tag');
      }
    });

    test('Wilds Reading title is The Warden\'s Account', () {
      final reading = CodexReadings.forTag(CodexTag.wilds)!;
      expect(reading.title, "The Warden's Account");
      expect(reading.body.length, greaterThan(300));
      expect(reading.rewards, isNotEmpty);
    });
  });
}

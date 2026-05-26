import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/shop.dart';
import 'package:flutter_text_based_rpg/models/item.dart';

void main() {
  group('Reputation System Tests', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
      engine.resetGame();
    });

    test('Initial reputation is empty / stranger', () {
      final rep = engine.getMerchantReputation('cedric');
      expect(rep.totalReputation, 0);
      expect(rep.tier, ReputationTier.stranger);
      expect(rep.tier.discountPercent, 0.0);
    });

    test('Add reputation increments total and session rep', () {
      engine.addMerchantReputation('cedric', 40);
      final rep = engine.getMerchantReputation('cedric');
      expect(rep.totalReputation, 40);
      expect(rep.sessionReputation, 40);
      expect(rep.tier, ReputationTier.stranger);
    });

    test('Reputation tier boundaries', () {
      final repStranger = const MerchantReputation(merchantId: 'cedric', totalReputation: 0);
      expect(repStranger.tier, ReputationTier.stranger);
      expect(repStranger.tier.discountPercent, 0.0);

      final repFamiliar = const MerchantReputation(merchantId: 'cedric', totalReputation: 50);
      expect(repFamiliar.tier, ReputationTier.familiar);
      expect(repFamiliar.tier.discountPercent, 0.0);

      final repTrusted = const MerchantReputation(merchantId: 'cedric', totalReputation: 150);
      expect(repTrusted.tier, ReputationTier.trustedPatron);
      expect(repTrusted.tier.discountPercent, 0.10);

      final repHonored = const MerchantReputation(merchantId: 'cedric', totalReputation: 300);
      expect(repHonored.tier, ReputationTier.honoredFriend);
      expect(repHonored.tier.discountPercent, 0.20);

      final repCompanion = const MerchantReputation(merchantId: 'cedric', totalReputation: 500);
      expect(repCompanion.tier, ReputationTier.swornCompanion);
      expect(repCompanion.tier.discountPercent, 0.30);
    });

    test('Session cap of 200 reputation', () {
      engine.addMerchantReputation('cedric', 150);
      expect(engine.getMerchantReputation('cedric').sessionReputation, 150);

      engine.addMerchantReputation('cedric', 100); // Exceeds cap (150 + 100 = 250)
      final rep = engine.getMerchantReputation('cedric');
      expect(rep.sessionReputation, 200); // capped at 200
      expect(rep.totalReputation, 200);
    });

    test('Reputation discount adjusts item buy price', () {
      final listing = ShopListing(item: Items.bakedPotato, buyPrice: 10, sellPrice: 4, category: ShopCategory.provisions);
      
      expect(listing.getBuyPrice(0.0), 10);
      expect(listing.getBuyPrice(0.10), 9); // 10 * 0.9 = 9
      expect(listing.getBuyPrice(0.20), 8); // 10 * 0.8 = 8
      expect(listing.getBuyPrice(0.30), 7); // 10 * 0.7 = 7
    });

    test('Sworn Companion unlocks companion fragment after session resets', () {
      // Initially not known
      expect(engine.knownCodexFragmentIds.contains('companion_cedric'), false);

      // Add 200 reputation (session 1 cap)
      engine.addMerchantReputation('cedric', 200);
      expect(engine.getMerchantReputation('cedric').totalReputation, 200);
      expect(engine.knownCodexFragmentIds.contains('companion_cedric'), false);

      // Simulate a shop rotation / new day to reset session cap
      engine.forceRestockForTesting();
      expect(engine.getMerchantReputation('cedric').sessionReputation, 0);

      // Add another 200 reputation (session 2, total 400)
      engine.addMerchantReputation('cedric', 200);
      expect(engine.getMerchantReputation('cedric').totalReputation, 400);
      expect(engine.knownCodexFragmentIds.contains('companion_cedric'), false);

      // Simulate another restock
      engine.forceRestockForTesting();

      // Add 100 reputation (session 3, total 500)
      engine.addMerchantReputation('cedric', 100);
      expect(engine.getMerchantReputation('cedric').totalReputation, 500);
      expect(engine.getMerchantReputation('cedric').tier, ReputationTier.swornCompanion);

      // Should unlock Sworn Companion Codex fragment!
      expect(engine.knownCodexFragmentIds.contains('companion_cedric'), true);
    });

    test('Claiming honored friend gift changes claimed status and triggers reward', () {
      expect(engine.isGiftClaimed('cedric'), false);

      // Trigger companion tier direct sets or mock it
      // Let's reach 300 reputation via multiple sessions
      engine.addMerchantReputation('cedric', 200);
      engine.forceRestockForTesting();
      engine.addMerchantReputation('cedric', 100);
      
      expect(engine.getMerchantReputation('cedric').totalReputation, 300);
      expect(engine.getMerchantReputation('cedric').tier, ReputationTier.honoredFriend);

      engine.claimHonoredFriendGift('cedric');
      expect(engine.isGiftClaimed('cedric'), true);
    });
  });
}

import 'dart:math';
import 'item.dart';

enum ShopCategory {
  supplies,
  tools,
  weapons,
  armor,
  provisions,
  specials,
}

class ShopListing {
  final Item item;
  final int buyPrice;
  final int sellPrice;
  final int? stock;
  final int? maxStock;
  final ShopCategory category;
  final bool isNew;
  final bool isFeatured;
  final int discountPercent;

  const ShopListing({
    required this.item,
    required this.buyPrice,
    required this.sellPrice,
    this.stock,
    this.maxStock,
    required this.category,
    this.isNew = false,
    this.isFeatured = false,
    this.discountPercent = 0,
  });

  int getBuyPrice(double reputationDiscountPercent) {
    final totalDiscount = (discountPercent / 100.0) + reputationDiscountPercent;
    final discounted = buyPrice * (1.0 - totalDiscount);
    return max(1, discounted.toInt());
  }

  int get effectiveBuyPrice {
    return getBuyPrice(0.0);
  }

  ShopListing copyWith({
    Item? item,
    int? buyPrice,
    int? sellPrice,
    int? stock,
    int? maxStock,
    ShopCategory? category,
    bool? isNew,
    bool? isFeatured,
    int? discountPercent,
  }) {
    return ShopListing(
      item: item ?? this.item,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      stock: stock != null ? stock : this.stock,
      maxStock: maxStock != null ? maxStock : this.maxStock,
      category: category ?? this.category,
      isNew: isNew ?? this.isNew,
      isFeatured: isFeatured ?? this.isFeatured,
      discountPercent: discountPercent ?? this.discountPercent,
    );
  }
}

class Merchant {
  final String id;
  final String name;
  final String title;
  final String icon; // Emoji
  final List<String> greetings;
  final List<ShopListing> baseListings;

  const Merchant({
    required this.id,
    required this.name,
    required this.title,
    required this.icon,
    required this.greetings,
    required this.baseListings,
  });

  // Master Trader (generalist)
  static final Merchant cedric = Merchant(
    id: 'cedric',
    name: 'Cedric',
    title: 'Master Trader',
    icon: '🧙',
    greetings: [
      'Welcome, traveler! Only the finest goods pass through my cart.',
      'Ah, a potential customer! Let us talk trade.',
      'Gold coins are heavy, but my goods are light and reliable!',
      'Need raw materials? Or perhaps some fresh provisions?',
    ],
    baseListings: [
      // Supplies
      ShopListing(item: Items.oakLog, buyPrice: 7, sellPrice: 2, stock: 20, maxStock: 20, category: ShopCategory.supplies),
      ShopListing(item: Items.wildflower, buyPrice: 4, sellPrice: 1, stock: 15, maxStock: 15, category: ShopCategory.supplies),
      ShopListing(item: Items.riverClay, buyPrice: 8, sellPrice: 3, stock: 12, maxStock: 12, category: ShopCategory.supplies),
      ShopListing(item: Items.rawPotato, buyPrice: 4, sellPrice: 1, category: ShopCategory.supplies), // Shop-exclusive resource, unlimited
      ShopListing(item: Items.hotWater, buyPrice: 3, sellPrice: 1, category: ShopCategory.supplies), // Shop-exclusive resource, unlimited
      
      // Basic Tools
      ShopListing(item: Items.stoneAxe, buyPrice: 70, sellPrice: 25, stock: 1, maxStock: 1, category: ShopCategory.tools),
      ShopListing(item: Items.stonePickaxe, buyPrice: 70, sellPrice: 25, stock: 1, maxStock: 1, category: ShopCategory.tools),
      ShopListing(item: Items.foragingGloves, buyPrice: 168, sellPrice: 60, stock: 1, maxStock: 1, category: ShopCategory.tools),
      
      // Provisions
      ShopListing(item: Items.wildBerries, buyPrice: 3, sellPrice: 1, category: ShopCategory.provisions),
      ShopListing(item: Items.bakedPotato, buyPrice: 11, sellPrice: 4, stock: 10, maxStock: 10, category: ShopCategory.provisions),
      ShopListing(item: Items.herbalTea, buyPrice: 17, sellPrice: 6, stock: 8, maxStock: 8, category: ShopCategory.provisions),
    ],
  );

  // Blacksmith (weapons, armor, tools)
  static final Merchant hilda = Merchant(
    id: 'hilda',
    name: 'Hilda',
    title: 'Master Blacksmith',
    icon: '🧝‍♀️',
    greetings: [
      'Need something strong enough to crack a troll\'s skull? I forged it myself.',
      'Quality metalwork isn\'t cheap, but it saves your life. Whatcha looking at?',
      'Careful around the forge! Now, you buying or just blocking the heat?',
      'Let me guess... you need more iron ore? Or a sharper sword?',
    ],
    baseListings: [
      // Supplies
      ShopListing(item: Items.copperOre, buyPrice: 6, sellPrice: 2, stock: 15, maxStock: 15, category: ShopCategory.supplies),
      ShopListing(item: Items.tinOre, buyPrice: 6, sellPrice: 2, stock: 15, maxStock: 15, category: ShopCategory.supplies),
      ShopListing(item: Items.ironOre, buyPrice: 14, sellPrice: 5, stock: 8, maxStock: 8, category: ShopCategory.supplies),
      
      // Tools
      ShopListing(item: Items.copperAxe, buyPrice: 140, sellPrice: 50, stock: 1, maxStock: 1, category: ShopCategory.tools),
      ShopListing(item: Items.copperPickaxe, buyPrice: 140, sellPrice: 50, stock: 1, maxStock: 1, category: ShopCategory.tools),
      ShopListing(item: Items.ironAxe, buyPrice: 280, sellPrice: 100, stock: 1, maxStock: 1, category: ShopCategory.tools),
      ShopListing(item: Items.ironPickaxe, buyPrice: 280, sellPrice: 100, stock: 1, maxStock: 1, category: ShopCategory.tools),
      
      // Weapons
      ShopListing(item: Items.bronzeSword, buyPrice: 210, sellPrice: 75, stock: 1, maxStock: 1, category: ShopCategory.weapons),
      ShopListing(item: Items.ironSword, buyPrice: 350, sellPrice: 125, stock: 1, maxStock: 1, category: ShopCategory.weapons),
      ShopListing(item: Items.steelGreatsword, buyPrice: 700, sellPrice: 250, stock: 1, maxStock: 1, category: ShopCategory.weapons),
      
      // Armor
      ShopListing(item: Items.bronzeChest, buyPrice: 280, sellPrice: 100, stock: 1, maxStock: 1, category: ShopCategory.armor),
      ShopListing(item: Items.steelPlate, buyPrice: 630, sellPrice: 225, stock: 1, maxStock: 1, category: ShopCategory.armor),
    ],
  );

  // Alchemist (potions, food, ingredients)
  static final Merchant pippin = Merchant(
    id: 'pippin',
    name: 'Pippin',
    title: 'Wandering Alchemist',
    icon: '🧪',
    greetings: [
      'Care for a taste of my latest concoction? Side effects are... mostly minor.',
      'Potions, herbs, and ingredients for the curious mind! Step closer!',
      'Restoring health? Restoring energy? I have a flask for that!',
      'Ah! Watch out for that blue bottle. It reacts to... breathing.',
    ],
    baseListings: [
      // Supplies
      ShopListing(item: Items.wildflower, buyPrice: 4, sellPrice: 1, stock: 20, maxStock: 20, category: ShopCategory.supplies),
      ShopListing(item: Items.nightshade, buyPrice: 25, sellPrice: 9, stock: 6, maxStock: 6, category: ShopCategory.supplies),
      ShopListing(item: Items.hotWater, buyPrice: 3, sellPrice: 1, category: ShopCategory.supplies),
      
      // Provisions
      ShopListing(item: Items.wildBerries, buyPrice: 3, sellPrice: 1, category: ShopCategory.provisions),
      ShopListing(item: Items.elixirOfLife1, buyPrice: 21, sellPrice: 7, stock: 5, maxStock: 5, category: ShopCategory.provisions),
      ShopListing(item: Items.elixirOfLife2, buyPrice: 42, sellPrice: 15, stock: 3, maxStock: 3, category: ShopCategory.provisions),
      ShopListing(item: Items.elixirOfLife3, buyPrice: 84, sellPrice: 30, stock: 2, maxStock: 2, category: ShopCategory.provisions),
      ShopListing(item: Items.philterOfClarity, buyPrice: 70, sellPrice: 25, stock: 4, maxStock: 4, category: ShopCategory.provisions),
      ShopListing(item: Items.spicedTea, buyPrice: 35, sellPrice: 12, stock: 6, maxStock: 6, category: ShopCategory.provisions),
    ],
  );

  // Lore Keeper (glyphs, high-end, rare)
  static final Merchant silas = Merchant(
    id: 'silas',
    name: 'Silas',
    title: 'Lore Keeper',
    icon: '📖',
    greetings: [
      'Knowledge is the ultimate currency, but today I will settle for gold.',
      'Runes, glyphs, and forgotten artifacts. Speak softly in their presence.',
      'Curious about the ancient ways? These tablets hold power.',
      'A true adventurer seeks to understand. What knowledge do you seek?',
    ],
    baseListings: [
      // Supplies
      ShopListing(item: Items.riverClay, buyPrice: 8, sellPrice: 3, stock: 15, maxStock: 15, category: ShopCategory.supplies),
      ShopListing(item: Items.trollClaw, buyPrice: 63, sellPrice: 22, stock: 3, maxStock: 3, category: ShopCategory.supplies),
      ShopListing(item: Items.spiderFang, buyPrice: 21, sellPrice: 7, stock: 5, maxStock: 5, category: ShopCategory.supplies),
      
      // Glyphs
      ShopListing(item: Items.glyphSwiftness, buyPrice: 35, sellPrice: 12, stock: 3, maxStock: 3, category: ShopCategory.provisions),
      ShopListing(item: Items.glyphFortitude, buyPrice: 56, sellPrice: 20, stock: 3, maxStock: 3, category: ShopCategory.provisions),
      
      // High end tools
      ShopListing(item: Items.backpackUpgrade, buyPrice: 560, sellPrice: 200, stock: 1, maxStock: 1, category: ShopCategory.tools),
    ],
  );

  // Wilderness Outfitter (backpacks, tools, hunting drops)
  static final Merchant maeve = Merchant(
    id: 'maeve',
    name: 'Maeve',
    title: 'Wilderness Outfitter',
    icon: '🏹',
    greetings: [
      'Heading deep into the woods? Don\'t go without a proper pack.',
      'I collect pelts, tusks, and logs. Buy some, or sell me yours.',
      'Surviving out there requires the right gear. Let\'s get you outfitted.',
      'The wild is harsh, but my leatherwork is harsher and tougher.',
    ],
    baseListings: [
      // Supplies
      ShopListing(item: Items.oakLog, buyPrice: 7, sellPrice: 2, stock: 25, maxStock: 25, category: ShopCategory.supplies),
      ShopListing(item: Items.willowLog, buyPrice: 17, sellPrice: 6, stock: 10, maxStock: 10, category: ShopCategory.supplies),
      ShopListing(item: Items.wolfPelt, buyPrice: 35, sellPrice: 12, stock: 4, maxStock: 4, category: ShopCategory.supplies),
      ShopListing(item: Items.boarTusk, buyPrice: 14, sellPrice: 5, stock: 8, maxStock: 8, category: ShopCategory.supplies),
      ShopListing(item: Items.spiderSilk, buyPrice: 17, sellPrice: 6, stock: 8, maxStock: 8, category: ShopCategory.supplies),
      ShopListing(item: Items.driftwood, buyPrice: 11, sellPrice: 3, stock: 15, maxStock: 15, category: ShopCategory.supplies),
      ShopListing(item: Items.saltCrystal, buyPrice: 20, sellPrice: 5, stock: 8, maxStock: 8, category: ShopCategory.supplies),
      ShopListing(item: Items.pearlShell, buyPrice: 31, sellPrice: 8, stock: 4, maxStock: 4, category: ShopCategory.supplies),
      ShopListing(item: Items.kelp, buyPrice: 8, sellPrice: 2, stock: 12, maxStock: 12, category: ShopCategory.supplies),
      
      // Packs & Gear
      ShopListing(item: Items.leatherBackpack, buyPrice: 420, sellPrice: 150, stock: 1, maxStock: 1, category: ShopCategory.tools),
      ShopListing(item: Items.backpackUpgrade, buyPrice: 560, sellPrice: 200, stock: 1, maxStock: 1, category: ShopCategory.tools),
      ShopListing(item: Items.reinforcedGloves, buyPrice: 280, sellPrice: 100, stock: 1, maxStock: 1, category: ShopCategory.tools),
      ShopListing(item: Items.masterworkGloves, buyPrice: 490, sellPrice: 175, stock: 1, maxStock: 1, category: ShopCategory.tools),
      
      // Armor
      ShopListing(item: Items.leatherChest, buyPrice: 168, sellPrice: 60, stock: 1, maxStock: 1, category: ShopCategory.armor),
      
      // Provisions
      ShopListing(item: Items.boarMeat, buyPrice: 11, sellPrice: 4, stock: 10, maxStock: 10, category: ShopCategory.provisions),
    ],
  );

  // Tavern-Keeper Bram (🍺)
  static final Merchant bram = Merchant(
    id: 'bram',
    name: 'Bram',
    title: 'Tavern-Keeper',
    icon: '🍺',
    greetings: [
      'Welcome to the Boar & Hearth! Grab a drink, rest your feet.',
      'Gold is always good, but gossip is better. What are you buying?',
      'Best brew in the valley, brewed it myself! Take a look.',
      'A warm fire and a cold drink, what more does a traveler need?',
    ],
    baseListings: [
      ShopListing(item: Items.wildBerries, buyPrice: 3, sellPrice: 1, category: ShopCategory.provisions),
      ShopListing(item: Items.bakedPotato, buyPrice: 11, sellPrice: 4, stock: 10, maxStock: 10, category: ShopCategory.provisions),
      ShopListing(item: Items.tavernsBest, buyPrice: 20, sellPrice: 5, category: ShopCategory.provisions),
      // Trusted Patron items:
      ShopListing(item: Items.elixirOfTwilight, buyPrice: 45, sellPrice: 15, stock: 2, maxStock: 2, category: ShopCategory.provisions),
      ShopListing(item: Items.tinkersBauble, buyPrice: 150, sellPrice: 50, stock: 1, maxStock: 1, category: ShopCategory.tools),
    ],
  );

  static final List<Merchant> all = [cedric, hilda, pippin, silas, maeve, bram];
}

enum ReputationTier {
  stranger,
  familiar,
  trustedPatron,
  honoredFriend,
  swornCompanion,
}

extension ReputationTierExtension on ReputationTier {
  String get name {
    switch (this) {
      case ReputationTier.stranger: return 'Stranger';
      case ReputationTier.familiar: return 'Familiar';
      case ReputationTier.trustedPatron: return 'Trusted Patron';
      case ReputationTier.honoredFriend: return 'Honored Friend';
      case ReputationTier.swornCompanion: return 'Sworn Companion';
    }
  }

  int get requiredReputation {
    switch (this) {
      case ReputationTier.stranger: return 0;
      case ReputationTier.familiar: return 50;
      case ReputationTier.trustedPatron: return 150;
      case ReputationTier.honoredFriend: return 300;
      case ReputationTier.swornCompanion: return 500;
    }
  }

  double get discountPercent {
    switch (this) {
      case ReputationTier.stranger: return 0.0;
      case ReputationTier.familiar: return 0.0;
      case ReputationTier.trustedPatron: return 0.10;
      case ReputationTier.honoredFriend: return 0.20;
      case ReputationTier.swornCompanion: return 0.30;
    }
  }
}

class MerchantReputation {
  final String merchantId;
  final int totalReputation;
  final int sessionReputation; // Capped at 200/session/merchant

  const MerchantReputation({
    required this.merchantId,
    this.totalReputation = 0,
    this.sessionReputation = 0,
  });

  ReputationTier get tier {
    if (totalReputation >= 500) return ReputationTier.swornCompanion;
    if (totalReputation >= 300) return ReputationTier.honoredFriend;
    if (totalReputation >= 150) return ReputationTier.trustedPatron;
    if (totalReputation >= 50) return ReputationTier.familiar;
    return ReputationTier.stranger;
  }

  int get repToNextTier {
    final t = tier;
    if (t == ReputationTier.swornCompanion) return 0;
    final next = ReputationTier.values[t.index + 1];
    return next.requiredReputation - totalReputation;
  }

  double get progressToNextTier {
    final t = tier;
    if (t == ReputationTier.swornCompanion) return 1.0;
    final currentMin = t.requiredReputation;
    final next = ReputationTier.values[t.index + 1];
    final nextMin = next.requiredReputation;
    final range = nextMin - currentMin;
    if (range <= 0) return 1.0;
    return ((totalReputation - currentMin) / range).clamp(0.0, 1.0);
  }

  MerchantReputation copyWith({
    String? merchantId,
    int? totalReputation,
    int? sessionReputation,
  }) {
    return MerchantReputation(
      merchantId: merchantId ?? this.merchantId,
      totalReputation: totalReputation ?? this.totalReputation,
      sessionReputation: sessionReputation ?? this.sessionReputation,
    );
  }
}

class ShopState {
  final List<Merchant> activeMerchants;
  final int activeMerchantIndex; // 0 or 1
  final Map<String, List<ShopListing>> merchantListings; // merchantId -> current listings (with stock and deal overrides)
  final Map<String, String> currentGreetings; // merchantId -> greeting
  final DateTime lastRestockTime;

  ShopState({
    required this.activeMerchants,
    required this.activeMerchantIndex,
    required this.merchantListings,
    required this.currentGreetings,
    required this.lastRestockTime,
  });

  Merchant get currentMerchant => activeMerchants[activeMerchantIndex];
  List<ShopListing> get currentListings => merchantListings[currentMerchant.id] ?? [];
  String get currentGreeting => currentGreetings[currentMerchant.id] ?? '';

  factory ShopState.initial() {
    // Start with Cedric and Maeve
    final active = [Merchant.cedric, Merchant.maeve];
    final listings = <String, List<ShopListing>>{};
    final greetings = <String, String>{};

    for (var m in Merchant.all) {
      // Initialize listings from base list
      listings[m.id] = List.from(m.baseListings);
      greetings[m.id] = m.greetings[0];
    }

    // Set daily deal for active ones
    final state = ShopState(
      activeMerchants: active,
      activeMerchantIndex: 0,
      merchantListings: listings,
      currentGreetings: greetings,
      lastRestockTime: DateTime.now().subtract(const Duration(minutes: 10)), // Force restock immediately on check
    );
    return state.withRefreshedDeals(Random());
  }

  ShopState withRefreshedDeals(Random random) {
    final newListings = Map<String, List<ShopListing>>.from(merchantListings);
    final newGreetings = Map<String, String>.from(currentGreetings);

    for (var m in Merchant.all) {
      final list = List<ShopListing>.from(m.baseListings);
      
      // Select one listing to be a featured daily deal if category matches
      final potentialDeals = list.where((l) => l.item.value > 2).toList();
      if (potentialDeals.isNotEmpty) {
        final dealIndex = random.nextInt(potentialDeals.length);
        final dealItem = potentialDeals[dealIndex];
        final discount = 20 + random.nextInt(3) * 10; // 20%, 30%, 40%
        
        for (var i = 0; i < list.length; i++) {
          if (list[i].item.id == dealItem.item.id) {
            list[i] = list[i].copyWith(
              isFeatured: true,
              discountPercent: discount,
            );
          }
        }
      }

      newListings[m.id] = list;
      newGreetings[m.id] = m.greetings[random.nextInt(m.greetings.length)];
    }

    return ShopState(
      activeMerchants: activeMerchants,
      activeMerchantIndex: activeMerchantIndex,
      merchantListings: newListings,
      currentGreetings: newGreetings,
      lastRestockTime: DateTime.now(),
    );
  }

  ShopState copyWith({
    List<Merchant>? activeMerchants,
    int? activeMerchantIndex,
    Map<String, List<ShopListing>>? merchantListings,
    Map<String, String>? currentGreetings,
    DateTime? lastRestockTime,
  }) {
    return ShopState(
      activeMerchants: activeMerchants ?? this.activeMerchants,
      activeMerchantIndex: activeMerchantIndex ?? this.activeMerchantIndex,
      merchantListings: merchantListings ?? this.merchantListings,
      currentGreetings: currentGreetings ?? this.currentGreetings,
      lastRestockTime: lastRestockTime ?? this.lastRestockTime,
    );
  }
}

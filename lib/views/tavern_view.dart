import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/game_engine.dart';
import '../models/daily_task.dart';
import '../models/shop.dart';
import '../models/item.dart';
import '../theme/game_theme.dart';
import '../widgets/custom_progress_bar.dart';
import '../widgets/item_dashboard_modal.dart';
import '../widgets/bounce_tap.dart';
import '../widgets/coin_animation.dart';

class TavernView extends StatefulWidget {
  const TavernView({Key? key}) : super(key: key);

  @override
  State<TavernView> createState() => _TavernViewState();
}

class _TavernViewState extends State<TavernView> {
  @override
  void initState() {
    super.initState();
    // Ensure Bram is set as the active merchant in engine so item modal works
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<GameEngine>(context, listen: false).setActiveMerchantById('bram');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<GameEngine>(context);
    final rep = engine.getMerchantReputation('bram');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: GameTheme.background,
        appBar: AppBar(
          backgroundColor: GameTheme.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Row(
            children: [
              Text('🍻 ', style: TextStyle(fontSize: 20)),
              Text(
                'THE BOAR & HEARTH TAVERN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            indicatorColor: GameTheme.accentGold,
            labelColor: GameTheme.accentGold,
            unselectedLabelColor: GameTheme.textMuted,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(
                icon: Icon(Icons.assignment_outlined, size: 20),
                text: 'Notice Board',
              ),
              Tab(
                icon: Icon(Icons.storefront_outlined, size: 20),
                text: "Bram's Wares",
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNoticeBoardTab(context, engine),
            _buildBramShopTab(context, engine, rep),
          ],
        ),
      ),
    );
  }

  // ================= NOTICE BOARD TAB =================
  Widget _buildNoticeBoardTab(BuildContext context, GameEngine engine) {
    final tasks = engine.todaysTasks;
    final bonusClaimed = engine.dailyBonusClaimed;
    final allCompleted = tasks.isNotEmpty && tasks.every((t) => t.isCompleted);
    final completedCount = tasks.where((t) => t.isCompleted).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Notice Board Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: GameTheme.glassCardDecoration(
            customBg: const Color(0xFF1E2833).withOpacity(0.8),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📝 DAILY NOTICE BOARD',
                style: TextStyle(
                  color: GameTheme.accentGold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Bram posts local requests here daily. Help the villagers to earn gold, reputation, and special bonuses.",
                style: TextStyle(color: GameTheme.textLight, fontSize: 12, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (tasks.isEmpty)
          const Card(
            color: GameTheme.cardBg,
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                "Notice board is currently empty. Check back tomorrow!",
                textAlign: TextAlign.center,
                style: TextStyle(color: GameTheme.textMuted, fontStyle: FontStyle.italic),
              ),
            ),
          )
        else ...[
          // Tasks list
          ...tasks.map((task) {
            final double progress = task.targetCount > 0 ? (task.currentCount / task.targetCount).clamp(0.0, 1.0) : 0.0;
            final isCompleted = task.isCompleted;
            final isClaimed = task.isClaimed;

            return Card(
              color: GameTheme.cardBg,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isClaimed
                      ? GameTheme.border.withOpacity(0.3)
                      : (isCompleted ? Colors.green.withOpacity(0.5) : GameTheme.border),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCategoryEmoji(task.category),
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.name,
                                style: TextStyle(
                                  color: isClaimed ? GameTheme.textMuted : Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  decoration: isClaimed ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Reward: 💰 ${task.rewardGold} Gold',
                                style: const TextStyle(
                                  color: GameTheme.accentGold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isClaimed)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Claimed',
                              style: TextStyle(color: GameTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          )
                        else if (isCompleted)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: () {
                              engine.claimDailyTaskReward(task.id);
                            },
                            child: const Text('Claim 💰', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: GameTheme.accentGold.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: GameTheme.accentGold.withOpacity(0.3)),
                            ),
                            child: Text(
                              '${task.currentCount}/${task.targetCount}',
                              style: const TextStyle(color: GameTheme.accentGold, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    if (!isClaimed) ...[
                      const SizedBox(height: 10),
                      CustomProgressBar(
                        progress: progress,
                        color: isCompleted ? Colors.green : GameTheme.accentGold,
                        height: 6,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
          // Daily Completion Bonus Card
          Card(
            color: const Color(0xFF16202B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: bonusClaimed
                    ? GameTheme.border.withOpacity(0.3)
                    : (allCompleted ? GameTheme.accentGold.withOpacity(0.8) : GameTheme.border),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text('🎁', style: TextStyle(fontSize: 26)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daily NOTICE BOARD BONUS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Complete and claim rewards for all 3 tasks.',
                              style: TextStyle(color: GameTheme.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: GameTheme.border),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🎁 Bonus Gold',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '+120 Gold',
                            style: TextStyle(color: GameTheme.accentGold, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        width: 1.5,
                        height: 30,
                        color: GameTheme.border,
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📘 Blueprint Chance',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '5% Chance',
                            style: TextStyle(color: Colors.purpleAccent, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (bonusClaimed)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Bonus Claimed 🎁',
                        style: TextStyle(color: GameTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: allCompleted ? GameTheme.accentGold : Colors.grey.shade800,
                        foregroundColor: allCompleted ? Colors.black : GameTheme.textMuted,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: allCompleted
                          ? () {
                              engine.claimDailyBonus();
                            }
                          : null,
                      child: Text(
                        allCompleted
                            ? 'Claim Daily Bonus'
                            : 'Tasks Completed: $completedCount / 3',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getCategoryEmoji(DailyTaskCategory cat) {
    switch (cat) {
      case DailyTaskCategory.gather:
        return '🌲';
      case DailyTaskCategory.hunt:
        return '⚔️';
      case DailyTaskCategory.visit:
        return '🧭';
      case DailyTaskCategory.craft:
        return '⚒️';
      case DailyTaskCategory.codex:
        return '📜';
      case DailyTaskCategory.cleanse:
        return '🟣';
    }
  }

  // ================= BRAM SHOP TAB =================
  Widget _buildBramShopTab(BuildContext context, GameEngine engine, MerchantReputation rep) {
    final listings = engine.shopState.merchantListings['bram'] ?? Merchant.bram.baseListings;
    final isHonored = rep.tier.index >= ReputationTier.honoredFriend.index;
    final giftClaimed = engine.isGiftClaimed('bram');

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Bram profile greeting
            Container(
              padding: const EdgeInsets.all(12),
              decoration: GameTheme.glassCardDecoration(
                customBg: const Color(0xFF1E2833).withOpacity(0.8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: GameTheme.cardBg,
                      border: Border.all(color: GameTheme.accentGold, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(Merchant.bram.icon, style: const TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Bram (Tavern-Keeper)",
                          style: TextStyle(color: GameTheme.accentGold, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Merchant.bram.greetings[0],
                          style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Reputation progress panel
            Card(
              color: GameTheme.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: GameTheme.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reputation Tier: ${rep.tier.name}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          rep.tier == ReputationTier.swornCompanion
                              ? 'MAX'
                              : 'Next Tier: ${rep.totalReputation} / ${ReputationTier.values[rep.tier.index + 1].requiredReputation}',
                          style: const TextStyle(color: GameTheme.accentGold, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CustomProgressBar(
                      progress: rep.progressToNextTier,
                      color: GameTheme.accentGold,
                      height: 8,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Shop Discount: ${(rep.tier.discountPercent * 100).toInt()}%',
                          style: const TextStyle(color: GameTheme.textMuted, fontSize: 11),
                        ),
                        if (isHonored) ...[
                          if (giftClaimed)
                            const Text(
                              'Honored Gift Claimed 🎁',
                              style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            )
                          else
                            BounceTap(
                              onTap: () {
                                engine.claimHonoredFriendGift('bram');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.purpleAccent.withOpacity(0.5)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('🎁 ', style: TextStyle(fontSize: 10)),
                                    Text(
                                      'Claim Honored Gift',
                                      style: TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bram's listings header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                '🍺 TA Tavern Stock',
                style: TextStyle(
                  color: GameTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Listings Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 80),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.3,
              ),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                final listing = listings[index];
                final item = listing.item;
                final price = listing.getBuyPrice(rep.tier.discountPercent);
                final isSoldOut = listing.stock != null && listing.stock! <= 0;

                // Check gate lock for Twilight Elixir and Tinker Bauble
                final bool isLockedItem = item.id == 'elixir_of_twilight' || item.id == 'tinkers_bauble';
                final bool isGated = isLockedItem && rep.tier.index < ReputationTier.trustedPatron.index;

                return BounceTap(
                  onTap: () {
                    if (isGated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🔒 This item requires Trusted Patron reputation tier with Bram!'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    ItemDashboardModal.show(
                      context,
                      engine,
                      item,
                      contextType: ItemModalContext.shop,
                    );
                  },
                  child: Stack(
                    children: [
                      Container(
                        decoration: GameTheme.glassCardDecoration(),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Text(item.icon, style: const TextStyle(fontSize: 26)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          listing.stock == null
                                              ? 'Stock: ∞'
                                              : (isSoldOut ? 'SOLD OUT' : 'Stock: ${listing.stock}'),
                                          style: TextStyle(
                                            color: isSoldOut
                                                ? Colors.redAccent
                                                : (listing.stock != null && listing.stock! <= 2
                                                    ? Colors.orangeAccent
                                                    : GameTheme.textMuted),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(color: GameTheme.border, height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    if (listing.discountPercent > 0) ...[
                                      Text(
                                        '${listing.buyPrice}g',
                                        style: const TextStyle(
                                          color: GameTheme.textMuted,
                                          fontSize: 10,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      '$price g',
                                      style: const TextStyle(
                                        color: GameTheme.accentGold,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Text('🪙', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Lock Overlay if reputation requirements not met
                      if (isGated)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              color: Colors.black.withOpacity(0.85),
                              alignment: Alignment.center,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_outline, color: Colors.redAccent, size: 24),
                                  SizedBox(height: 4),
                                  Text(
                                    'Trusted Patron Only',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),

        // Sell Satchel Button (floating at bottom)
        Positioned(
          left: 16,
          right: 16,
          bottom: 12,
          child: BounceTap(
            onTap: () => _showSellSatchelBottomSheet(context, engine),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: GameTheme.accentGold,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sell_outlined, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    '💰 Open Sell Satchel',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSellSatchelBottomSheet(BuildContext context, GameEngine engine) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GameTheme.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final localEngine = Provider.of<GameEngine>(context);
            final slots = localEngine.inventory.slots;

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '💰 SELL SATCHEL (0.5x Value)',
                          style: TextStyle(color: GameTheme.accentGold, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: GameTheme.textMuted),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: GameTheme.border, height: 16),
                    Expanded(
                      child: slots.isEmpty
                          ? const Center(
                              child: Text(
                                'Your satchel is empty!',
                                style: TextStyle(color: GameTheme.textMuted, fontStyle: FontStyle.italic),
                              ),
                            )
                          : ListView.builder(
                              itemCount: slots.length,
                              itemBuilder: (context, index) {
                                final slot = slots[index];
                                final item = slot.item;
                                final qty = slot.quantity;
                                final sellPrice = max(1, (item.value * 0.5).toInt());

                                bool isEquipped = false;
                                if (item.isTool && item.toolSkill != null) {
                                  isEquipped = localEngine.equippedTools[item.toolSkill!]?.id == item.id;
                                } else if (item.isWeapon) {
                                  isEquipped = localEngine.equippedWeapon?.id == item.id;
                                } else if (item.isArmor) {
                                  isEquipped = localEngine.equippedArmor?.id == item.id;
                                }

                                return Card(
                                  color: const Color(0xFF1E2833),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(color: GameTheme.border, width: 1),
                                  ),
                                  child: ListTile(
                                    leading: Text(item.icon, style: const TextStyle(fontSize: 24)),
                                    title: Text(
                                      item.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      isEquipped ? 'EQUIPPED • Cannot Sell' : 'Qty: $qty • Value: $sellPrice g',
                                      style: TextStyle(
                                        color: isEquipped ? Colors.redAccent : GameTheme.textMuted,
                                        fontSize: 11,
                                        fontWeight: isEquipped ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    trailing: isEquipped
                                        ? null
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: GameTheme.accentGold,
                                                  side: const BorderSide(color: GameTheme.accentGold, width: 1),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                onPressed: () {
                                                  final RenderBox? box = context.findRenderObject() as RenderBox?;
                                                  Offset sourceOffset = Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height * 0.5);
                                                  if (box != null) {
                                                    sourceOffset = box.localToGlobal(Offset.zero) + Offset(box.size.width / 2, box.size.height / 2);
                                                  }

                                                  final targetOffset = Offset(MediaQuery.of(context).size.width * 0.8, 50);
                                                  final overlayState = Overlay.of(context);

                                                  localEngine.sellItem(item, 1);

                                                  CoinBurstOverlay.show(
                                                    overlayState: overlayState,
                                                    source: sourceOffset,
                                                    target: targetOffset,
                                                    isBuy: false,
                                                  );
                                                },
                                                child: const Text('Sell 1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                              const SizedBox(width: 6),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: GameTheme.healthRed.withOpacity(0.15),
                                                  foregroundColor: Colors.white,
                                                  side: const BorderSide(color: GameTheme.healthRed, width: 1),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                onPressed: () {
                                                  final RenderBox? box = context.findRenderObject() as RenderBox?;
                                                  Offset sourceOffset = Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height * 0.5);
                                                  if (box != null) {
                                                    sourceOffset = box.localToGlobal(Offset.zero) + Offset(box.size.width / 2, box.size.height / 2);
                                                  }
                                                  final targetOffset = Offset(MediaQuery.of(context).size.width * 0.8, 50);
                                                  final overlayState = Overlay.of(context);

                                                  localEngine.sellItem(item, qty);

                                                  CoinBurstOverlay.show(
                                                    overlayState: overlayState,
                                                    source: sourceOffset,
                                                    target: targetOffset,
                                                    isBuy: false,
                                                  );
                                                },
                                                child: const Text('Sell All', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

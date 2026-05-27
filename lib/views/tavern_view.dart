import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/game_engine.dart';
import '../models/daily_task.dart';
import '../models/shop.dart';
import '../models/item.dart';
import '../theme/design_tokens.dart';
import '../widgets/coin_animation.dart';
import '../widgets/bounce_tap.dart';
import '../widgets/item_dashboard_modal.dart';

import '../widgets/game/game_card.dart';
import '../widgets/game/game_progress_bar.dart';
import '../widgets/game/game_chip.dart';
import '../widgets/game/game_avatar.dart';
import '../widgets/game/game_sheet.dart';
import '../widgets/game/game_button.dart';
import '../widgets/game/game_toast.dart';
import '../widgets/game/game_tabs.dart';
import '../widgets/game/game_list_item.dart';

class TavernView extends StatefulWidget {
  const TavernView({Key? key}) : super(key: key);

  @override
  State<TavernView> createState() => _TavernViewState();
}

class _TavernViewState extends State<TavernView> {
  int _activeTab = 0; // 0 = Notice Board, 1 = Bram's Wares

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

    return Scaffold(
      backgroundColor: DSColors.surface0,
      appBar: AppBar(
        backgroundColor: DSColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DSColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text('🍻 ', style: TextStyle(fontSize: 20)),
            Text(
              'THE BOAR & HEARTH TAVERN',
              style: DSText.headingSmall(context).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Premium Custom GameTabs
          GameTabs(
            tabs: const [
              GameTab(label: 'Notice Board', icon: Icons.assignment_outlined),
              GameTab(label: "Bram's Wares", icon: Icons.storefront_outlined),
            ],
            selectedIndex: _activeTab,
            onChanged: (index) {
              setState(() {
                _activeTab = index;
              });
            },
          ),
          Expanded(
            child: _activeTab == 0
                ? _buildNoticeBoardTab(context, engine)
                : _buildBramShopTab(context, engine, rep),
          ),
        ],
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
      padding: const EdgeInsets.all(DSSpace.md),
      children: [
        // Notice Board Header
        GameCard(
          elevation: 1,
          accentColor: DSColors.accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('📝', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'DAILY NOTICE BOARD',
                    style: DSText.label(context).copyWith(color: DSColors.accent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Bram posts local requests here daily. Help the villagers to earn gold, reputation, and special bonuses.",
                style: DSText.bodyMedium(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (tasks.isEmpty)
          GameCard(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                "Notice board is currently empty. Check back tomorrow!",
                textAlign: TextAlign.center,
                style: DSText.bodyMedium(context).copyWith(color: DSColors.textMuted, fontStyle: FontStyle.italic),
              ),
            ),
          )
        else ...[
          // Tasks list
          ...tasks.map((task) {
            final double progress = task.targetCount > 0 ? (task.currentCount / task.targetCount).clamp(0.0, 1.0) : 0.0;
            final isCompleted = task.isCompleted;
            final isClaimed = task.isClaimed;

            // Build trailing status / action
            Widget? trailingWidget;
            if (isClaimed) {
              trailingWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DSColors.surface3,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Claimed',
                  style: DSText.label(context).copyWith(fontSize: 10, color: DSColors.textDisabled, fontWeight: FontWeight.bold),
                ),
              );
            } else if (isCompleted) {
              trailingWidget = GameButton(
                variant: GameButtonVariant.primary,
                size: GameButtonSize.sm,
                label: 'Claim 💰',
                onPressed: () {
                  engine.claimDailyTaskReward(task.id);
                  GameToast.show(context, 'Claimed task reward!');
                },
              );
            } else {
              trailingWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DSColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: DSColors.accent.withOpacity(0.3)),
                ),
                child: Text(
                  '${task.currentCount}/${task.targetCount}',
                  style: DSText.numeric(context).copyWith(color: DSColors.accent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              );
            }

            return GameCard(
              elevation: 1,
              accentColor: isClaimed ? null : (isCompleted ? DSColors.success : DSColors.borderDefault),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GameListItem(
                    padding: EdgeInsets.zero,
                    leading: GameAvatar(
                      emoji: _getCategoryEmoji(task.category),
                      size: GameAvatarSize.sm,
                    ),
                    title: Text(
                      task.name,
                      style: DSText.bodyMedium(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: isClaimed ? DSColors.textDisabled : DSColors.textPrimary,
                        decoration: isClaimed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(
                      'Reward: 💰 ${task.rewardGold} Gold',
                      style: DSText.label(context).copyWith(
                        color: DSColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: trailingWidget,
                  ),
                  if (!isClaimed) ...[
                    const SizedBox(height: 10),
                    GameProgressBar(
                      progress: progress,
                      color: isCompleted ? DSColors.success : DSColors.accent,
                      height: 6,
                    ),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 8),
          // Daily Completion Bonus Card
          GameCard(
            elevation: 2,
            accentColor: bonusClaimed ? null : (allCompleted ? DSColors.accent : null),
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
                          Text(
                            'Daily NOTICE BOARD BONUS',
                            style: DSText.headingSmall(context).copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Complete and claim rewards for all 3 tasks.',
                            style: DSText.bodySmall(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: DSColors.borderSubtle),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎁 Bonus Gold',
                          style: DSText.bodySmall(context).copyWith(color: DSColors.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '+120 Gold',
                          style: DSText.numeric(context).copyWith(color: DSColors.accent, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      width: 1.5,
                      height: 30,
                      color: DSColors.borderSubtle,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📘 Blueprint Chance',
                          style: DSText.bodySmall(context).copyWith(color: DSColors.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '5% Chance',
                          style: DSText.numeric(context).copyWith(color: Colors.purpleAccent, fontSize: 14, fontWeight: FontWeight.bold),
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
                      color: DSColors.surface3,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Bonus Claimed 🎁',
                      style: DSText.button(context).copyWith(color: DSColors.textMuted, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  GameButton(
                    variant: allCompleted ? GameButtonVariant.primary : GameButtonVariant.ghost,
                    label: allCompleted ? 'Claim Daily Bonus' : 'Tasks Completed: $completedCount / 3',
                    onPressed: allCompleted
                        ? () {
                            engine.claimDailyBonus();
                          }
                        : null,
                  ),
              ],
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
          padding: const EdgeInsets.all(DSSpace.md),
          children: [
            // Bram profile greeting
            GameCard(
              elevation: 1,
              accentColor: DSColors.accent,
              child: Row(
                children: [
                  GameAvatar(
                    emoji: Merchant.bram.icon,
                    size: GameAvatarSize.md,
                    ringColor: DSColors.accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bram (Tavern-Keeper)",
                          style: DSText.headingSmall(context).copyWith(color: DSColors.accent, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Merchant.bram.greetings[0],
                          style: DSText.bodyMedium(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Reputation progress panel
            GameCard(
              elevation: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reputation:',
                        style: DSText.bodyMedium(context).copyWith(fontWeight: FontWeight.bold),
                      ),
                      GameChip.reputationTier(rep.tier, size: GameChipSize.sm),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        rep.tier == ReputationTier.swornCompanion
                            ? 'MAX'
                            : 'Next Tier progress:',
                        style: DSText.bodySmall(context),
                      ),
                      if (rep.tier != ReputationTier.swornCompanion)
                        Text(
                          '${rep.totalReputation} / ${ReputationTier.values[rep.tier.index + 1].requiredReputation}',
                          style: DSText.numeric(context).copyWith(color: DSColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GameProgressBar(
                    progress: rep.progressToNextTier,
                    color: DSColors.accent,
                    height: 8,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Shop Discount: ${(rep.tier.discountPercent * 100).toInt()}%',
                        style: DSText.bodySmall(context),
                      ),
                      if (isHonored) ...[
                        if (giftClaimed)
                          Text(
                            'Honored Gift Claimed 🎁',
                            style: DSText.bodySmall(context).copyWith(color: DSColors.success, fontWeight: FontWeight.bold),
                          )
                        else
                          GameButton(
                            variant: GameButtonVariant.primary,
                            size: GameButtonSize.sm,
                            label: '🎁 Claim Gift',
                            onPressed: () {
                              engine.claimHonoredFriendGift('bram');
                              GameToast.show(context, 'Claimed Honored Friend gift!');
                            },
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bram's listings header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                '🍺 TAVERN STOCK',
                style: DSText.label(context),
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
                childAspectRatio: 1.15,
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

                return GameCard(
                  elevation: 1,
                  onTap: () {
                    if (isGated) {
                      GameToast.show(context, '🔒 This item requires Trusted Patron reputation tier with Bram!', isError: true);
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              GameAvatar(
                                emoji: item.icon,
                                size: GameAvatarSize.sm,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: DSText.bodyMedium(context).copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      listing.stock == null
                                          ? 'Stock: ∞'
                                          : (isSoldOut ? 'SOLD OUT' : 'Stock: ${listing.stock}'),
                                      style: DSText.bodySmall(context).copyWith(
                                        color: isSoldOut
                                            ? DSColors.error
                                            : (listing.stock != null && listing.stock! <= 2
                                                ? DSColors.warning
                                                : DSColors.textMuted),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: DSColors.borderSubtle, height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  if (listing.discountPercent > 0) ...[
                                    Text(
                                      '${listing.buyPrice}g',
                                      style: DSText.numeric(context).copyWith(
                                        color: DSColors.textDisabled,
                                        fontSize: 10,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    '$price g',
                                    style: DSText.numeric(context).copyWith(
                                      color: DSColors.accent,
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
                      // Lock Overlay if reputation requirements not met
                      if (isGated)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(DSRadius.md),
                            child: Container(
                              color: Colors.black.withOpacity(0.85),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.lock_outline, color: DSColors.error, size: 24),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Trusted Patron Only',
                                    style: DSText.label(context).copyWith(
                                      color: DSColors.error,
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
          child: GameButton(
            variant: GameButtonVariant.primary,
            label: '💰 Open Sell Satchel',
            onPressed: () => _showSellSatchelBottomSheet(context, engine),
          ),
        ),
      ],
    );
  }

  void _showSellSatchelBottomSheet(BuildContext context, GameEngine engine) {
    GameSheet.show(
      context: context,
      title: '💰 SELL SATCHEL (0.5x Value)',
      child: ListenableBuilder(
        listenable: engine,
        builder: (context, _) {
          final slots = engine.inventory.slots;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              slots.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Text(
                          'Your satchel is empty!',
                          style: DSText.bodyMedium(context).copyWith(color: DSColors.textMuted, fontStyle: FontStyle.italic),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: slots.length,
                      itemBuilder: (context, index) {
                        final slot = slots[index];
                        final item = slot.item;
                        final qty = slot.quantity;
                        final sellPrice = max(1, (item.value * 0.5).toInt());

                        bool isEquipped = false;
                        if (item.isTool && item.toolSkill != null) {
                          isEquipped = engine.equippedTools[item.toolSkill!]?.id == item.id;
                        } else if (item.isWeapon) {
                          isEquipped = engine.equippedWeapon?.id == item.id;
                        } else if (item.isArmor) {
                          isEquipped = engine.equippedArmor?.id == item.id;
                        }

                        return GameCard(
                          elevation: 1,
                          child: Row(
                            children: [
                              GameAvatar(
                                emoji: item.icon,
                                size: GameAvatarSize.sm,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: DSText.bodyMedium(context).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isEquipped ? 'EQUIPPED • Cannot Sell' : 'Qty: $qty • Value: $sellPrice g',
                                      style: DSText.bodySmall(context).copyWith(
                                        color: isEquipped ? DSColors.error : DSColors.textMuted,
                                        fontWeight: isEquipped ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isEquipped) ...[
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GameButton(
                                      variant: GameButtonVariant.ghost,
                                      label: 'Sell 1',
                                      size: GameButtonSize.sm,
                                      onPressed: () {
                                        final RenderBox? box = context.findRenderObject() as RenderBox?;
                                        Offset sourceOffset = Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height * 0.5);
                                        if (box != null) {
                                          sourceOffset = box.localToGlobal(Offset.zero) + Offset(box.size.width / 2, box.size.height / 2);
                                        }

                                        final targetOffset = Offset(MediaQuery.of(context).size.width * 0.8, 50);
                                        final overlayState = Overlay.of(context);

                                        engine.sellItem(item, 1);

                                        CoinBurstOverlay.show(
                                          overlayState: overlayState,
                                          source: sourceOffset,
                                          target: targetOffset,
                                          isBuy: false,
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    GameButton(
                                      variant: GameButtonVariant.danger,
                                      label: 'Sell All',
                                      size: GameButtonSize.sm,
                                      onPressed: () {
                                        final RenderBox? box = context.findRenderObject() as RenderBox?;
                                        Offset sourceOffset = Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height * 0.5);
                                        if (box != null) {
                                          sourceOffset = box.localToGlobal(Offset.zero) + Offset(box.size.width / 2, box.size.height / 2);
                                        }
                                        final targetOffset = Offset(MediaQuery.of(context).size.width * 0.8, 50);
                                        final overlayState = Overlay.of(context);

                                        engine.sellItem(item, qty);

                                        CoinBurstOverlay.show(
                                          overlayState: overlayState,
                                          source: sourceOffset,
                                          target: targetOffset,
                                          isBuy: false,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ],
          );
        },
      ),
    );
  }
}

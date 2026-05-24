import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_engine.dart';
import '../models/quest.dart';
import '../models/codex.dart';
import '../models/beast.dart';
import '../models/zone.dart';
import '../models/item.dart';
import '../theme/game_theme.dart';

class CodexView extends StatelessWidget {
  const CodexView({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<GameEngine>(context);
    
    final showFragments = engine.knownCodexFragmentIds.isNotEmpty;
    final showAchievements = engine.earnedAchievementIds.isNotEmpty;

    final List<Tab> tabs = [];
    final List<Widget> tabViews = [];

    tabs.add(const Tab(text: 'QUESTS'));
    tabViews.add(_buildQuestsTab(context, engine));

    tabs.add(const Tab(text: 'BEASTS'));
    tabViews.add(_buildBeastsTab(context, engine));

    tabs.add(const Tab(text: 'REGIONS'));
    tabViews.add(_buildRegionsTab(context, engine));

    if (showFragments) {
      tabs.add(const Tab(text: 'FRAGMENTS'));
      tabViews.add(_buildFragmentsTab(context, engine));
    }

    if (showAchievements) {
      tabs.add(const Tab(text: 'ACHIEVEMENTS'));
      tabViews.add(_buildAchievementsTab(context, engine));
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'CODEX & MAPS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 16,
            ),
          ),
          backgroundColor: const Color(0xFF0C1014),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: GameTheme.accentGold),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            tabs: tabs,
            isScrollable: tabs.length > 3,
            indicatorColor: GameTheme.accentGold,
            labelColor: GameTheme.accentGold,
            unselectedLabelColor: GameTheme.textMuted,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF10171E),
          ),
          child: TabBarView(
            children: tabViews,
          ),
        ),
      ),
    );
  }

  // --- Quests Tab ---
  Widget _buildQuestsTab(BuildContext context, GameEngine engine) {
    final active = engine.activeQuests;
    final completed = engine.completedQuests;

    if (active.isEmpty && completed.isEmpty) {
      return const Center(
        child: Text(
          'No quests recorded.',
          style: TextStyle(color: GameTheme.textMuted),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (active.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Text(
              'ACTIVE QUESTS',
              style: TextStyle(
                color: GameTheme.accentGold,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.0,
              ),
            ),
          ),
          ...active.map((q) => _buildQuestCodexCard(context, engine, q)),
          const SizedBox(height: 16),
        ],
        if (completed.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Text(
              'COMPLETED QUESTS',
              style: TextStyle(
                color: GameTheme.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.0,
              ),
            ),
          ),
          ...completed.map((q) => _buildQuestCodexCard(context, engine, q, isCompletedHistory: true)),
        ],
      ],
    );
  }

  Widget _buildQuestCodexCard(BuildContext context, GameEngine engine, Quest quest, {bool isCompletedHistory = false}) {
    Color typeColor;
    switch (quest.type) {
      case QuestType.main:
        typeColor = const Color(0xFFAB47BC);
        break;
      case QuestType.side:
        typeColor = const Color(0xFF29B6F6);
        break;
      case QuestType.daily:
        typeColor = const Color(0xFF66BB6A);
        break;
    }

    if (isCompletedHistory) {
      typeColor = GameTheme.textMuted;
    }

    final bool isReady = quest.isComplete && !isCompletedHistory;

    return Card(
      color: GameTheme.cardBg,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isReady
              ? GameTheme.accentGold
              : isCompletedHistory
                  ? GameTheme.border.withOpacity(0.3)
                  : typeColor.withOpacity(0.4),
          width: isReady ? 1.8 : 1.0,
        ),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              quest.type == QuestType.main
                  ? '📜'
                  : quest.type == QuestType.side
                      ? '🧭'
                      : '📅',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                quest.title,
                style: TextStyle(
                  color: isCompletedHistory ? GameTheme.textMuted : GameTheme.textLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  decoration: isCompletedHistory ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            isCompletedHistory
                ? 'Completed'
                : isReady
                    ? 'Ready to Turn In'
                    : 'Active',
            style: TextStyle(
              color: isReady
                  ? GameTheme.accentGold
                  : isCompletedHistory
                      ? GameTheme.textMuted
                      : typeColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        collapsedIconColor: GameTheme.textMuted,
        iconColor: GameTheme.accentGold,
        childrenPadding: const EdgeInsets.all(12),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              quest.description,
              style: const TextStyle(color: GameTheme.textMuted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Objectives:',
              style: TextStyle(color: GameTheme.textLight, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 6),
          ...quest.objectives.map((obj) => _buildObjectiveRow(obj, isCompletedHistory)),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Rewards:',
              style: TextStyle(color: GameTheme.textLight, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: quest.rewards.map((r) => _buildRewardChip(r)).toList(),
            ),
          ),
          if (isReady && quest.turnInLocation != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  engine.turnInQuest(quest.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameTheme.accentGold,
                  foregroundColor: const Color(0xFF10171E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Turn In', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildObjectiveRow(QuestObjective obj, bool isParentCompleted) {
    final bool isDone = obj.isComplete || isParentCompleted;
    final progress = obj.targetCount > 0 ? (obj.currentCount / obj.targetCount) : 0.0;

    String targetLabel = obj.targetId ?? '';
    if (obj.kind == ObjectiveKind.restore || obj.kind == ObjectiveKind.upgrade) {
      targetLabel = targetLabel.replaceAll('_', ' ').split(' ').map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '').join(' ');
    } else if (obj.kind == ObjectiveKind.gather || obj.kind == ObjectiveKind.craft) {
      final item = Items.findById(obj.targetId ?? '');
      if (item != null) targetLabel = "${item.icon} ${item.name}";
    } else if (obj.kind == ObjectiveKind.masterwork) {
      targetLabel = "${obj.targetId} Trial";
    }

    String kindText = '';
    switch (obj.kind) {
      case ObjectiveKind.gather: kindText = 'Gather'; break;
      case ObjectiveKind.kill: kindText = 'Defeat'; break;
      case ObjectiveKind.craft: kindText = 'Craft'; break;
      case ObjectiveKind.visit: kindText = 'Visit'; break;
      case ObjectiveKind.scout: kindText = 'Scout'; break;
      case ObjectiveKind.restore: kindText = 'Restore'; break;
      case ObjectiveKind.upgrade: kindText = 'Upgrade'; break;
      case ObjectiveKind.masterwork: kindText = 'Complete'; break;
      case ObjectiveKind.codexRead: kindText = 'Read Codex Fragments'; break;
      default: kindText = 'Objective'; break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '• $kindText $targetLabel',
                  style: TextStyle(
                    color: isDone ? GameTheme.textMuted : GameTheme.textLight,
                    fontSize: 12,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isParentCompleted ? '${obj.targetCount}/${obj.targetCount}' : '${obj.currentCount}/${obj.targetCount}',
                style: TextStyle(
                  color: isDone ? GameTheme.textMuted : GameTheme.textLight,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isParentCompleted ? 1.0 : progress,
              backgroundColor: GameTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone ? GameTheme.textMuted : GameTheme.accentGold,
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardChip(QuestReward reward) {
    String label = '';
    IconData icon = Icons.help;
    Color color = GameTheme.textLight;

    switch (reward.kind) {
      case RewardKind.gold:
        label = '${reward.amount}g';
        icon = Icons.monetization_on;
        color = GameTheme.accentGold;
        break;
      case RewardKind.skillXp:
        label = '${reward.amount} XP';
        icon = Icons.star;
        color = GameTheme.wayfindingBlue;
        break;
      case RewardKind.item:
      case RewardKind.blueprint:
        final item = Items.findById(reward.targetId ?? '');
        label = '${item?.icon ?? '📦'} ${item?.name ?? reward.targetId} x${reward.amount}';
        icon = Icons.inventory;
        color = const Color(0xFF81C784);
        break;
      case RewardKind.worldEvent:
        label = 'World Event';
        icon = Icons.event;
        color = Colors.cyanAccent;
        break;
      case RewardKind.unlock:
        label = 'Unlock';
        icon = Icons.vpn_key;
        color = Colors.purpleAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // --- Beasts Tab ---
  Widget _buildBeastsTab(BuildContext context, GameEngine engine) {
    final list = engine.bestiary.keys.toList();

    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🐗',
                style: TextStyle(fontSize: 48),
              ),
              SizedBox(height: 16),
              Text(
                'No beasts catalogued yet.',
                style: TextStyle(color: GameTheme.textLight, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Defeat beasts in combat during travel to record their stats and drop history here.',
                style: TextStyle(color: GameTheme.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final beastId = list[index];
        final entry = engine.bestiary[beastId]!;
        final beast = Beasts.findById(beastId);
        if (beast == null) return const SizedBox.shrink();

        final duration = DateTime.now().difference(entry.firstDefeated);
        String timeAgo = 'just now';
        if (duration.inDays > 0) {
          timeAgo = '${duration.inDays} day${duration.inDays > 1 ? 's' : ''} ago';
        } else if (duration.inHours > 0) {
          timeAgo = '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} ago';
        } else if (duration.inMinutes > 0) {
          timeAgo = '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''} ago';
        }

        return Card(
          color: GameTheme.cardBg,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: GameTheme.border.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Text(beast.icon, style: const TextStyle(fontSize: 32)),
            title: Text(
              beast.name,
              style: const TextStyle(
                color: GameTheme.textLight,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Defeated: ${entry.defeatCount} time${entry.defeatCount > 1 ? 's' : ''}',
                    style: const TextStyle(color: GameTheme.textMuted, fontSize: 12),
                  ),
                  Text(
                    'First slain: $timeAgo',
                    style: const TextStyle(color: GameTheme.textMuted, fontSize: 11),
                  ),
                  if (entry.droppedItemIds.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('Drops seen: ', style: TextStyle(color: GameTheme.textMuted, fontSize: 11)),
                        Wrap(
                          spacing: 4,
                          children: entry.droppedItemIds.map((itemId) {
                            final item = Items.findById(itemId);
                            return Text(item?.icon ?? '❓', style: const TextStyle(fontSize: 12));
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: GameTheme.textMuted),
            onTap: () => _showBeastStatsModal(context, beast),
          ),
        );
      },
    );
  }

  void _showBeastStatsModal(BuildContext context, Beast beast) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131920),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: GameTheme.border, width: 1.5),
          ),
          title: Row(
            children: [
              Text(beast.icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Text(
                beast.name,
                style: const TextStyle(color: GameTheme.textLight, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBeastStatRow('❤️ Max Health', '${beast.maxHealth} HP'),
              _buildBeastStatRow('⚔️ Attack Power', '${beast.attackPower}'),
              _buildBeastStatRow('🛡️ Defense', '${beast.defense}'),
              _buildBeastStatRow('⭐ XP Granted', '${beast.xpReward} Combat XP'),
              const Divider(color: GameTheme.border, height: 20),
              const Text(
                'POSSIBLE LOOT',
                style: TextStyle(
                  color: GameTheme.accentGold,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              ...beast.lootTable.map((loot) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(loot.item.icon),
                          const SizedBox(width: 8),
                          Text(
                            loot.item.name,
                            style: const TextStyle(color: GameTheme.textLight, fontSize: 13),
                          ),
                        ],
                      ),
                      Text(
                        '${(loot.chance * 100).toInt()}% (${loot.minQuantity}-${loot.maxQuantity})',
                        style: const TextStyle(color: GameTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: GameTheme.accentGold, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBeastStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: GameTheme.textMuted, fontSize: 13)),
          Text(value, style: const TextStyle(color: GameTheme.textLight, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  // --- Regions Tab ---
  Widget _buildRegionsTab(BuildContext context, GameEngine engine) {
    final list = engine.regionStatus.keys.toList();

    if (list.isEmpty) {
      return const Center(
        child: Text(
          'No regions discovered.',
          style: TextStyle(color: GameTheme.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final zoneId = list[index];
        final info = engine.regionStatus[zoneId]!;
        final zone = Zones.all.firstWhere((z) => z.id == zoneId, orElse: () => Zones.townSquare);

        final duration = info.discoveredAt != null
            ? DateTime.now().difference(info.discoveredAt!)
            : null;
            
        String timeAgo = 'just now';
        if (duration != null) {
          if (duration.inDays > 0) {
            timeAgo = '${duration.inDays} day${duration.inDays > 1 ? 's' : ''} ago';
          } else if (duration.inHours > 0) {
            timeAgo = '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} ago';
          } else if (duration.inMinutes > 0) {
            timeAgo = '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''} ago';
          }
        }

        String emoji = _getZoneEmoji(zone.id);

        return Card(
          color: GameTheme.cardBg,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: GameTheme.border.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            zone.name,
                            style: const TextStyle(
                              color: GameTheme.textLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.amber.withOpacity(0.4), width: 1),
                            ),
                            child: const Text(
                              'Anomalous',
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        zone.description,
                        style: const TextStyle(color: GameTheme.textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Discovered: $timeAgo',
                        style: TextStyle(color: GameTheme.textMuted.withOpacity(0.7), fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getZoneEmoji(String zoneId) {
    if (zoneId == 'town_square') return '🏡';
    if (zoneId.contains('woods') || zoneId.contains('forest')) return '🌲';
    if (zoneId.contains('mine') || zoneId.contains('caverns') || zoneId.contains('shafts')) return '⛏️';
    return '🗺️';
  }

  // --- Stubs for future expansions ---
  Widget _buildFragmentsTab(BuildContext context, GameEngine engine) {
    return const Center(
      child: Text(
        'Fragments Tab (Under Construction)',
        style: TextStyle(color: GameTheme.textMuted),
      ),
    );
  }

  Widget _buildAchievementsTab(BuildContext context, GameEngine engine) {
    return const Center(
      child: Text(
        'Achievements Tab (Under Construction)',
        style: TextStyle(color: GameTheme.textMuted),
      ),
    );
  }
}

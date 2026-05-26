import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_engine.dart';
import '../models/quest.dart';
import '../models/codex.dart';
import '../models/beast.dart';
import '../models/zone.dart';
import '../models/item.dart';
import '../models/main_quests.dart';
import '../theme/game_theme.dart';
import '../widgets/reading_overlay.dart';
import '../widgets/pulsing_weather_chip.dart';
import '../models/weather.dart';
import 'codex_puzzle_view.dart';
import '../models/shop.dart';


class CodexView extends StatelessWidget {
  const CodexView({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<GameEngine>(context);
    
    final showFragments = engine.knownCodexFragmentIds.isNotEmpty;
    final showReputation = engine.merchantRep.values.any((r) => r.totalReputation > 0);

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

    if (showReputation) {
      tabs.add(const Tab(text: 'REPUTATION'));
      tabViews.add(_buildReputationTab(context, engine));
    }

    tabs.add(const Tab(text: 'ACHIEVEMENTS'));
    tabViews.add(_buildAchievementsTab(context, engine));

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
      case RewardKind.offerQuest:
        final nextQuest = MainQuests.findById(reward.targetId ?? '');
        label = 'Quest: ${nextQuest?.title ?? reward.targetId}';
        icon = Icons.assignment;
        color = Colors.orangeAccent;
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
            leading: Text(
              beast.icon,
              style: TextStyle(
                fontSize: 32,
                color: GameTheme.getBeastIconColor(beast.id),
              ),
            ),
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
            onTap: () => _showBeastStatsModal(context, engine, beast),
          ),
        );
      },
    );
  }

  String _getBeastSpecHint(String beastId) {
    switch (beastId) {
      case 'forest_boar':
        return "Boars paw the dirt before they charge. Use the Defend stance to mitigate the heavy impact, or Sentinel to reflect it back!";
      case 'cave_spider':
        return "Spiders web up their prey to lock them in place. Use Read Tells to anticipate their sticky traps, or Skirmisher timer speedups to strike first!";
      case 'shadow_wolf':
        return "Wolves howl to summon support, raising their defense. Use Berserker's Heavy Strike to smash through their fortified guard!";
      case 'cavern_troll':
        return "Cavern trolls strike slow but hit incredibly hard. Use Defend to trigger a Guardian counter-strike, or Bastion's health regen to weather the blows!";
      case 'tide_hound':
        return "Tide hounds leap quickly through the sea mist. Under Sea Fog, the Reaper's crit chance increases to overwhelm their swift dodging!";
      case 'brine_crawler':
        return "Brine crawlers spit acidic salt water. Carry quick-slot foods like Kelp Wrap or Pearl Tonic to cleanse the burn and restore energy!";
      case 'salt_touched_drowned':
        return "The drowned wail at low health, dealing fatal decay damage. Read their Tells to know when to execute them with a final Reaper blow!";
      default:
        return "Analyze their telegraphs and select matching stances to gain a tactical edge.";
    }
  }

  void _showBeastStatsModal(BuildContext context, GameEngine engine, Beast beast) {
    final entry = engine.bestiary[beast.id];
    final defeatCount = entry?.defeatCount ?? 0;
    final hasWeaknessUnlocked = beast.weaknessHint != null &&
        Achievements.all.any((ach) =>
            ach.bestiaryHintBeastId == beast.id &&
            engine.earnedAchievementIds.contains(ach.id));

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
              Text(
                beast.icon,
                style: TextStyle(
                  fontSize: 28,
                  color: GameTheme.getBeastIconColor(beast.id),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                beast.name,
                style: const TextStyle(color: GameTheme.textLight, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBeastStatRow('❤️ Max Health', '${beast.maxHealth} HP'),
                _buildBeastStatRow('⚔️ Attack Power', '${beast.attackPower}'),
                _buildBeastStatRow('🛡️ Defense', '${beast.defense}'),
                _buildBeastStatRow('⭐ XP Granted', '${beast.xpReward} Combat XP'),
                if (hasWeaknessUnlocked)
                  _buildBeastStatRow('🎯 Weak to', beast.weaknessHint!),
                
                if (defeatCount >= 3) ...[
                  const Divider(color: GameTheme.border, height: 20),
                  const Text(
                    '💡 SPECIALIZATION COMBAT HINT',
                    style: TextStyle(
                      color: GameTheme.accentGold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: GameTheme.accentGold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GameTheme.accentGold.withOpacity(0.3)),
                    ),
                    child: Text(
                      _getBeastSpecHint(beast.id),
                      style: const TextStyle(color: GameTheme.textLight, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],

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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                              if (zone.id.contains('coast')) ...[
                                const SizedBox(width: 6),
                                PulsingWeatherChip(weather: engine.coastWeather),
                              ],
                            ],
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
    if (zoneId.contains('coast')) return '🌊';
    return '🗺️';
  }

  // --- Stubs for future expansions ---
  Widget _buildFragmentsTab(BuildContext context, GameEngine engine) {
    final tags = CodexTag.values.where((t) => t != CodexTag.misc).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...tags.map((tag) {
            final fragmentsInTag = CodexFragments.all
                .where((f) => f.tag == tag && engine.knownCodexFragmentIds.contains(f.id))
                .toList();

            if (fragmentsInTag.isEmpty) {
              return const SizedBox.shrink();
            }

            final isSolved = engine.solvedTagPuzzles.contains(tag);
            final reading = CodexReadings.forTag(tag);

            return Card(
              color: GameTheme.cardBg,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSolved ? GameTheme.accentGold.withOpacity(0.5) : GameTheme.border,
                  width: isSolved ? 2 : 1,
                ),
              ),
              child: ExpansionTile(
                key: PageStorageKey<String>('fragments_tag_${tag.name}'),
                title: Row(
                  children: [
                    Text(
                      tag.name.toUpperCase(),
                      style: TextStyle(
                        color: isSolved ? GameTheme.accentGold : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: GameTheme.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${fragmentsInTag.length}/10',
                        style: const TextStyle(fontSize: 10, color: GameTheme.textLight),
                      ),
                    ),
                    if (isSolved) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle, color: GameTheme.accentGold, size: 16),
                    ],
                  ],
                ),
                subtitle: Text(
                  isSolved
                      ? 'Reading unlocked: ${reading?.title ?? ""}'
                      : 'Gather fragments to unlock puzzle',
                  style: const TextStyle(fontSize: 12, color: GameTheme.textMuted),
                ),
                childrenPadding: const EdgeInsets.all(16),
                children: [
                  ...fragmentsInTag.map((fragment) {
                    final isRead = engine.readCodexFragmentIds.contains(fragment.id);
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isRead ? Icons.menu_book : Icons.bookmark,
                        color: isRead ? GameTheme.textMuted : GameTheme.accentGold,
                        size: 16,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isRead ? fragment.title : '???',
                              style: TextStyle(
                                color: isRead ? Colors.white : GameTheme.textMuted,
                                fontStyle: isRead ? FontStyle.normal : FontStyle.italic,
                              ),
                            ),
                          ),
                          if (!isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: GameTheme.accentGold,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      onTap: () => _showFragmentDialog(context, engine, fragment),
                    );
                  }),
                  const SizedBox(height: 12),
                  if (isSolved && reading != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showReading(context, reading),
                        icon: const Icon(Icons.menu_book, size: 16),
                        label: Text('Read the ${reading.title}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GameTheme.accentGold,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ] else if (fragmentsInTag.length >= 3) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CodexPuzzleView(tag: tag),
                            ),
                          );
                        },
                        icon: const Icon(Icons.extension, size: 16),
                        label: const Text('Solve Puzzle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GameTheme.wayfindingBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          _buildSynthesisSection(context, engine),
        ],
      ),
    );
  }

  void _showFragmentDialog(BuildContext context, GameEngine engine, CodexFragment fragment) {
    if (!engine.readCodexFragmentIds.contains(fragment.id)) {
      engine.readCodexFragment(fragment.id);
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GameTheme.cardBg,
        title: Text(fragment.title, style: const TextStyle(color: Colors.white)),
        content: Text(
          fragment.text,
          style: const TextStyle(color: GameTheme.textLight, fontStyle: FontStyle.italic),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showReading(BuildContext context, CodexReading reading) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Reading',
      pageBuilder: (context, _, __) => ReadingOverlay(
        reading: reading,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildSynthesisSection(BuildContext context, GameEngine engine) {
    final solvedCount = engine.solvedTagPuzzles.length;
    if (solvedCount < 4) {
      return const SizedBox.shrink();
    }

    final isAllSolved = solvedCount == 5;

    return Card(
      color: GameTheme.cardBg,
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAllSolved ? GameTheme.accentGold.withOpacity(0.8) : GameTheme.border,
          width: isAllSolved ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: GameTheme.accentGold, size: 20),
                SizedBox(width: 8),
                Text(
                  'SYNTHESIS',
                  style: TextStyle(
                    color: GameTheme.accentGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isAllSolved) ...[
              const Text(
                'One more reading awaits...',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text(
                'Solve the last tag\'s puzzle to unlock the Synthesis.',
                style: TextStyle(color: GameTheme.textMuted, fontSize: 13),
              ),
            ] else ...[
              const Text(
                'All readings united. The full timeline is clear.',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showReading(context, CodexReadings.synthesisReading),
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Read the Synthesis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameTheme.accentGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReputationTab(BuildContext context, GameEngine engine) {
    final merchants = Merchant.all;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: merchants.length,
      itemBuilder: (context, index) {
        final merchant = merchants[index];
        final rep = engine.getMerchantReputation(merchant.id);
        final tier = rep.tier;

        Color tierColor;
        switch (tier) {
          case ReputationTier.stranger:
            tierColor = Colors.grey;
            break;
          case ReputationTier.familiar:
            tierColor = const Color(0xFF80DEEA); // Light teal
            break;
          case ReputationTier.trustedPatron:
            tierColor = const Color(0xFF64B5F6); // Blue
            break;
          case ReputationTier.honoredFriend:
            tierColor = GameTheme.accentGold; // Gold
            break;
          case ReputationTier.swornCompanion:
            tierColor = const Color(0xFFBA68C8); // Purple
            break;
        }

        final bool isMax = tier == ReputationTier.swornCompanion;
        final nextTierMin = isMax ? 500 : ReputationTier.values[tier.index + 1].requiredReputation;
        final progressText = isMax ? 'MAX' : '${rep.totalReputation} / $nextTierMin rep';

        final bool canClaimGift = tier.index >= ReputationTier.honoredFriend.index && !engine.isGiftClaimed(merchant.id);

        return Card(
          color: GameTheme.cardBg,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: canClaimGift ? GameTheme.accentGold : GameTheme.border.withOpacity(0.5),
              width: canClaimGift ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      merchant.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            merchant.name,
                            style: const TextStyle(
                              color: GameTheme.textLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            merchant.title,
                            style: const TextStyle(
                              color: GameTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: tierColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: tierColor.withOpacity(0.4), width: 1),
                      ),
                      child: Text(
                        tier.name.toUpperCase(),
                        style: TextStyle(
                          color: tierColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Discount: ${(tier.discountPercent * 100).toInt()}%',
                      style: const TextStyle(
                        color: GameTheme.textLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      progressText,
                      style: const TextStyle(
                        color: GameTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: rep.progressToNextTier,
                    backgroundColor: GameTheme.border,
                    valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                    minHeight: 6,
                  ),
                ),
                if (canClaimGift) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        engine.claimHonoredFriendGift(merchant.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF131920),
                            content: Text(
                              'Claimed Honored Friend gift from ${merchant.name}!',
                              style: const TextStyle(color: GameTheme.accentGold, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.card_giftcard, size: 16),
                      label: const Text(
                        'Claim Honored Gift',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameTheme.accentGold,
                        foregroundColor: const Color(0xFF10171E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _categoryName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.firstSteps: return 'First Steps';
      case AchievementCategory.mastery: return 'Mastery';
      case AchievementCategory.combat: return 'Combat';
      case AchievementCategory.crafting: return 'Crafting & Cooking';
      case AchievementCategory.lore: return 'Lore & History';
      case AchievementCategory.economy: return 'Wealth & Economy';
      case AchievementCategory.hidden: return 'Secrets';
    }
  }

  Widget _buildAchievementsTab(BuildContext context, GameEngine engine) {
    final earned = engine.earnedAchievementIds;
    final categories = AchievementCategory.values;

    final List<Widget> children = [];

    final totalVisible = Achievements.all.where((a) => !a.hidden).length;
    final totalEarned = earned.length;
    final totalEarnedVisible = Achievements.all.where((a) => !a.hidden && earned.contains(a.id)).length;

    children.add(
      Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0C1014),
          border: Border(bottom: BorderSide(color: GameTheme.border.withOpacity(0.5))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COMPLETION',
                  style: TextStyle(
                    color: GameTheme.accentGold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalEarned earned ($totalEarnedVisible visible / $totalVisible total)',
                  style: const TextStyle(color: GameTheme.textLight, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: GameTheme.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GameTheme.accentGold.withOpacity(0.4)),
              ),
              child: Text(
                '${((totalEarned / 40.0) * 100).toInt()}%',
                style: const TextStyle(
                  color: GameTheme.accentGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    for (final category in categories) {
      final categoryAchievements = Achievements.all.where((ach) {
        if (ach.category != category) return false;
        if (earned.contains(ach.id)) return true;
        return !ach.hidden;
      }).toList();

      if (categoryAchievements.isEmpty) continue;

      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            _categoryName(category).toUpperCase(),
            style: const TextStyle(
              color: GameTheme.accentGold,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );

      children.addAll(
        categoryAchievements.map((ach) {
          final isEarned = earned.contains(ach.id);

          return Card(
            color: isEarned ? GameTheme.cardBg : GameTheme.cardBg.withOpacity(0.5),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isEarned
                    ? GameTheme.accentGold.withOpacity(0.4)
                    : GameTheme.border.withOpacity(0.2),
                width: isEarned ? 1.5 : 1.0,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isEarned ? GameTheme.accentGold.withOpacity(0.1) : Colors.black.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  isEarned ? ach.icon : '❔',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              title: Text(
                isEarned ? ach.name : '❔ ???',
                style: TextStyle(
                  color: isEarned ? GameTheme.textLight : GameTheme.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  ach.description,
                  style: TextStyle(
                    color: isEarned ? GameTheme.textLight.withOpacity(0.7) : GameTheme.textMuted.withOpacity(0.8),
                    fontSize: 11,
                    fontStyle: isEarned ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ),
              trailing: isEarned
                  ? const Icon(Icons.check_circle, color: GameTheme.accentGold, size: 20)
                  : const Icon(Icons.lock_outline, color: GameTheme.textMuted, size: 18),
            ),
          );
        }),
      );

      children.add(const SizedBox(height: 16));
    }

    return ListView(
      children: children,
    );
  }
}

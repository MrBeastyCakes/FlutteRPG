import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/game_engine.dart';
import '../models/player_progression.dart';
import '../models/skill.dart';
import '../models/quest.dart';
import '../models/main_quests.dart';
import '../models/zone.dart';
import '../models/structure.dart';
import '../theme/game_theme.dart';
import '../widgets/custom_progress_bar.dart';
import '../widgets/item_dashboard_modal.dart';
import '../models/item.dart';
import '../models/inventory.dart';
import '../models/crafted_item.dart';
import 'dart:async';
import '../widgets/bounce_tap.dart';
import '../widgets/pulsing_dot.dart';
import '../widgets/reagent_notice_card.dart';
import '../models/reagent_spawn.dart';
import '../widgets/fluid_wave_background.dart';
import '../widgets/flying_item_overlay.dart';
import '../widgets/coin_animation.dart';
import '../widgets/particle_explosion.dart';
import '../models/weather.dart';
import '../widgets/pulsing_weather_chip.dart';
import '../widgets/quick_slot_bar.dart';
import '../widgets/combat_action_bar.dart';


class DashboardView extends StatefulWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  StreamSubscription? _lootSubscription;
  StreamSubscription? _levelUpSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final engine = Provider.of<GameEngine>(context, listen: false);
      
      _lootSubscription = engine.lootEvents.listen((event) {
        if (!mounted) return;
        final size = MediaQuery.of(context).size;
        final startPos = Offset(size.width * 0.35, size.height * 0.4);
        FlyingItemOverlay.show(context, icon: event.icon, startPosition: startPos, quality: event.quality);
      });

      _levelUpSubscription = engine.levelUpEvents.listen((event) {
        if (!mounted) return;
        final size = MediaQuery.of(context).size;
        final centerPos = Offset(size.width * 0.5, size.height * 0.45);
        ParticleExplosionOverlay.show(context, centerPos, color: GameTheme.getSkillColor(event.skillType));
      });
    });
  }

  @override
  void dispose() {
    _lootSubscription?.cancel();
    _levelUpSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<GameEngine>(context);
    final stats = engine.playerStats;
    final currentZone = engine.currentZone;

    if (engine.tavernRequested) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          engine.tavernRequested = false;
          Navigator.pushNamed(context, '/tavern');
        }
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildQuestLogChip(context, engine),
          _buildStationStatusStrip(context, engine),
          // 1. HEADER: Character Info & Stats
          _buildHeader(stats, engine),
          const SizedBox(height: 12),

          // 2. CURRENT LOCATION CARD
          _buildLocationCard(currentZone),
          const SizedBox(height: 12),

          if (engine.activeCombat != null) ...[
            _buildCombatDashboardCard(context, engine),
            const SizedBox(height: 12),
          ],

          _buildActiveRecipeCard(engine),
          
          _buildQuickUseFoodBar(context, engine),

          // 3. MAIN SECTION: Split layout (Actions on Left, Stats/Inv on Right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: Zone Actions
              Expanded(
                flex: 11,
                child: _buildZoneActions(engine, currentZone),
              ),
              const SizedBox(width: 12),
              // Right side: Skills & Inventory
              Expanded(
                flex: 9,
                child: Column(
                  children: [
                    _buildSkillsPanel(engine),
                    const SizedBox(height: 12),
                    const QuickSlotBar(),
                    const SizedBox(height: 12),
                    _buildInventoryPanel(engine),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic stats, GameEngine engine) {
    final playerLvl = stats.playerLevel;
    final title = stats.title;
    final nextXp = PlayerProgression.xpToNextLevel(playerLvl);
    final xpPercent = (stats.playerXp / nextXp).clamp(0.0, 1.0);

    return Container(
      decoration: GameTheme.glassCardDecoration(
        customBg: const Color(0xFF1E2732).withOpacity(0.85),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Name, Level/Title & Gold
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stats.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Lvl $playerLvl $title',
                  style: const TextStyle(
                    color: GameTheme.accentGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                GoldCounter(
                  gold: stats.gold,
                  fontSize: 12,
                  showIcon: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Health, Energy & Player XP bars
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Health
              Row(
                children: [
                  const Icon(Icons.favorite, color: GameTheme.healthRed, size: 14),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 120,
                    child: CustomProgressBar(
                      progress: stats.currentHealth / stats.maxHealth,
                      color: GameTheme.healthRed,
                      height: 10,
                      label: 'HP: ${stats.currentHealth}/${stats.maxHealth}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Energy
              Row(
                children: [
                  const Icon(Icons.bolt, color: GameTheme.energyYellow, size: 14),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 120,
                    child: CustomProgressBar(
                      progress: stats.currentEnergy / stats.maxEnergy,
                      color: GameTheme.energyBlue,
                      height: 10,
                      label: 'Energy: ${stats.currentEnergy}/${stats.maxEnergy}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Player XP
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.purpleAccent, size: 14),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 120,
                    child: GameProgressBar(
                      progress: xpPercent,
                      color: Colors.purpleAccent,
                      label: 'XP: ${stats.playerXp}/$nextXp',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCombatLogColor(String line) {
    if (line.contains(" strike ") || line.contains("You strike")) {
      return const Color(0xFF81C784); // light green
    }
    if (line.contains(" strikes you ")) {
      return const Color(0xFFE57373); // light red
    }
    if (line.contains("defeated")) {
      return GameTheme.accentGold;
    }
    if (line.contains("collapsed")) {
      return Colors.red;
    }
    return Colors.white;
  }

  Widget _buildCombatDashboardCard(BuildContext context, GameEngine engine) {
    final combatState = engine.activeCombat;
    if (combatState == null) return const SizedBox.shrink();

    final beast = combatState.beast;
    final beastHp = combatState.beastCurrentHealth;
    final beastMaxHp = beast.maxHealth;
    final beastHpPercent = (beastHp / beastMaxHp).clamp(0.0, 1.0);

    final playerHp = engine.playerStats.currentHealth;
    final playerMaxHp = engine.playerStats.maxHealth;
    final playerHpPercent = (playerHp / playerMaxHp).clamp(0.0, 1.0);

    final reversedLogs = combatState.combatLog.reversed.toList();

    return Container(
      decoration: GameTheme.glassCardDecoration(
        customBg: const Color(0xFF1E2833).withOpacity(0.8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Battle status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('⚔️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  const Text(
                    'BATTLE IN PROGRESS',
                    style: TextStyle(
                      color: GameTheme.accentGold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameTheme.healthRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () {
                  engine.cancelAction();
                },
                icon: const Icon(Icons.run_circle_outlined, size: 16),
                label: const Text(
                  'Flee Battle',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Two columns: Player Health vs Beast Health
          Row(
            children: [
              // Player stats summary
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '👤 Player Health',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: playerHpPercent,
                      backgroundColor: Colors.black.withOpacity(0.5),
                      valueColor: const AlwaysStoppedAnimation<Color>(GameTheme.healthRed),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$playerHp / $playerMaxHp HP',
                      style: const TextStyle(color: GameTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Beast stats summary
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          beast.icon,
                          style: TextStyle(
                            fontSize: 13,
                            color: GameTheme.getBeastIconColor(beast.id),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          beast.name,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: beastHpPercent,
                      backgroundColor: Colors.black.withOpacity(0.5),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$beastHp / $beastMaxHp HP',
                      style: const TextStyle(color: GameTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const CombatActionBar(),
          const SizedBox(height: 16),

          // Scrolling Log Console
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFF0C1014).withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GameTheme.border.withOpacity(0.5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListView.builder(
              reverse: true,
              itemCount: reversedLogs.length,
              itemBuilder: (context, index) {
                final line = reversedLogs[index];
                final color = _getCombatLogColor(line);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    line,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Zone currentZone) {
    final engine = Provider.of<GameEngine>(context, listen: false);
    return BounceTap(
      onTap: () => _showZoneTravelSheet(context, engine),
      child: Container(
        decoration: GameTheme.glassCardDecoration(
          customBg: const Color(0xFF16212D).withOpacity(0.85),
        ).copyWith(
          border: Border.all(
            color: GameTheme.accentGold.withOpacity(0.4),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Mini location thumbnail representation
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF233040),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GameTheme.border, width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                _getZoneEmoji(currentZone.id),
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 12),
            // Location names
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Current Location',
                        style: TextStyle(color: GameTheme.textMuted, fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.explore_outlined,
                        color: GameTheme.accentGold.withOpacity(0.7),
                        size: 11,
                      ),
                    ],
                  ),
                  Text(
                    currentZone.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (currentZone.id.contains('coast')) ...[
                    Builder(
                      builder: (context) {
                        final remaining = engine.nextWeatherRollAt.difference(DateTime.now());
                        final minutes = remaining.inMinutes;
                        final seconds = remaining.inSeconds % 60;
                        final timeStr = remaining.isNegative ? "0:00" : "$minutes:${seconds.toString().padLeft(2, '0')}";
                        return Row(
                          children: [
                            const Text(
                              'Weather: ',
                              style: TextStyle(
                                color: GameTheme.accentGold,
                                fontSize: 12,
                              ),
                            ),
                            PulsingWeatherChip(weather: engine.coastWeather),
                            const SizedBox(width: 6),
                            Text(
                              '($timeStr)',
                              style: const TextStyle(
                                color: GameTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                  ] else ...[
                    Text(
                      'Weather: ${currentZone.weatherBonusDescription}',
                      style: const TextStyle(
                        color: GameTheme.accentGold,
                        fontSize: 12,
                      ),
                    ),
                  ],

                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x334CAF50),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: const Text(
                    'Active Zone',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tap to Travel',
                      style: TextStyle(
                        color: GameTheme.accentGold.withOpacity(0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right,
                      color: GameTheme.accentGold.withOpacity(0.9),
                      size: 12,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showZoneTravelSheet(BuildContext context, GameEngine engine) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeZone = engine.currentZone;
            final allZones = Zones.all;
            final unlockedZones = allZones.where((z) => engine.unlockedZoneIds.contains(z.id)).toList();
            final hasLockedZones = unlockedZones.length < allZones.length;

            return Container(
              decoration: BoxDecoration(
                color: GameTheme.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: GameTheme.border, width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle / Top Header
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: GameTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.map, color: GameTheme.accentGold, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Choose Destination',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: GameTheme.textMuted, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: unlockedZones.length + (hasLockedZones ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == unlockedZones.length) {
                          return Card(
                            color: GameTheme.cardBg.withOpacity(0.5),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: GameTheme.border.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Text(
                                    '🧭',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Keep Exploring!',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Explore current zones further to discover and unlock new destinations.',
                                          style: TextStyle(
                                            color: GameTheme.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final zone = unlockedZones[index];
                        final isCurrent = activeZone.id == zone.id;
                        final isUnlocked = true;

                        String? unlockActionId;
                        if (zone.id == 'whispering_woods_1') {
                          unlockActionId = 'explore_forest_paths';
                        } else if (zone.id == 'darkstone_mine_1') {
                          unlockActionId = 'explore_rocky_trails';
                        } else if (zone.id == 'whispering_woods_2') {
                          unlockActionId = 'explore_deep_woods';
                        } else if (zone.id == 'darkstone_mine_2') {
                          unlockActionId = 'explore_lower_shafts';
                        }

                        final double progress = unlockActionId != null
                            ? (engine.explorationProgress[unlockActionId] ?? 0.0)
                            : 0.0;

                        final cardWidget = Card(
                          color: GameTheme.cardBg,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isCurrent
                                  ? GameTheme.accentGold
                                  : isUnlocked
                                      ? GameTheme.border.withOpacity(0.5)
                                      : GameTheme.border.withOpacity(0.2),
                              width: isCurrent ? 1.5 : 1,
                            ),
                          ),
                          elevation: isUnlocked ? 3 : 1,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Zone Header
                                Row(
                                  children: [
                                    Text(
                                      isUnlocked ? _getZoneEmoji(zone.id) : '🔒',
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            zone.name,
                                            style: TextStyle(
                                              color: isUnlocked ? Colors.white : GameTheme.textMuted,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Zone Tier ${zone.tier}',
                                            style: const TextStyle(
                                              color: GameTheme.textMuted,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.green.withOpacity(0.5)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.location_on, color: Colors.greenAccent, size: 10),
                                            SizedBox(width: 4),
                                            Text(
                                              'Current',
                                              style: TextStyle(
                                                color: Colors.greenAccent,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (isUnlocked)
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: GameTheme.accentGold,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                        onPressed: () {
                                          engine.travelTo(zone);
                                          // Force the modal list to rebuild in case travel triggers changes,
                                          // but we are popping anyway so let's close the sheet first
                                          Navigator.pop(context);
                                        },
                                        icon: const Icon(Icons.directions_run, size: 12),
                                        label: const Text(
                                          'Travel',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.lock, color: Colors.redAccent, size: 10),
                                            SizedBox(width: 4),
                                            Text(
                                              'Locked',
                                              style: TextStyle(
                                                color: Colors.redAccent,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Hint / Description
                                Text(
                                  isUnlocked ? zone.description : 'Unlock Hint: ${zone.unlockHint}',
                                  style: TextStyle(
                                    color: isUnlocked ? GameTheme.textLight : GameTheme.textMuted,
                                    fontSize: 12,
                                    fontStyle: isUnlocked ? FontStyle.normal : FontStyle.italic,
                                  ),
                                ),

                                if (!isUnlocked && progress > 0.0) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Discovery Progress',
                                        style: TextStyle(
                                          color: GameTheme.accentGold,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${(progress * 100).toInt()}%',
                                        style: const TextStyle(
                                          color: GameTheme.accentGold,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  CustomProgressBar(
                                    progress: progress,
                                    color: GameTheme.accentGold,
                                    height: 6,
                                  ),
                                ],

                                if (isUnlocked) ...[
                                  const SizedBox(height: 8),
                                  // Weather effect
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF151D26),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: GameTheme.border.withOpacity(0.6)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.cloudy_snowing, color: GameTheme.accentGold, size: 12),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Weather: ',
                                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10),
                                        ),
                                        Expanded(
                                          child: Text(
                                            zone.weatherBonusDescription,
                                            style: const TextStyle(
                                              color: GameTheme.accentGold,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Structures
                                  Builder(
                                    builder: (context) {
                                      final builtStructures = engine.getBuiltStructuresForZone(zone.id);
                                      if (builtStructures.isEmpty) return const SizedBox.shrink();
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Structures: ',
                                              style: TextStyle(
                                                color: GameTheme.textMuted,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Wrap(
                                                spacing: 4,
                                                runSpacing: 2,
                                                children: builtStructures.map((sId) {
                                                  final struct = Structures.findById(sId);
                                                  if (struct == null) return const SizedBox.shrink();
                                                  return Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: GameTheme.craftingCyan.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(color: GameTheme.craftingCyan.withOpacity(0.3)),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(struct.icon, style: const TextStyle(fontSize: 9)),
                                                        const SizedBox(width: 3),
                                                        Text(
                                                          struct.name,
                                                          style: const TextStyle(
                                                            color: GameTheme.craftingCyan,
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                                  // Collapsible preview activities
                                  Theme(
                                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      title: const Text(
                                        'Preview Zone Activities',
                                        style: TextStyle(color: GameTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                      dense: true,
                                      tilePadding: EdgeInsets.zero,
                                      children: zone.actions.map((act) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                                          child: Row(
                                            children: [
                                              Text(
                                                act.requiredSkill?.icon ?? '⚡',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  act.name,
                                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                                ),
                                              ),
                                              if (act.requiredSkill != null)
                                                Text(
                                                  'Lvl ${act.requiredLevel} ${act.requiredSkill!.name}',
                                                  style: const TextStyle(color: GameTheme.textMuted, fontSize: 9),
                                                )
                                              else
                                                const Text(
                                                  'No Requirements',
                                                  style: const TextStyle(color: GameTheme.textMuted, fontSize: 9),
                                                ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );

                        if (!isUnlocked) {
                          return Opacity(
                            opacity: 0.65,
                            child: cardWidget,
                          );
                        }
                        return cardWidget;
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getZoneEmoji(String zoneId) {
    if (zoneId.contains('woods')) return '🌲';
    if (zoneId.contains('mine')) return '⛰️';
    return '🏡';
  }

  Widget _buildActiveRecipeCard(GameEngine engine) {
    final activeState = engine.activeAction;
    if (activeState == null) {
      return const SizedBox.shrink();
    }

    if (activeState.recipe == null && activeState.structure == null) {
      return const SizedBox.shrink();
    }

    final String name;
    final String icon;
    final String subtitle;
    final Color progressColor;
    final Color cardBg;

    if (activeState.recipe != null) {
      final recipe = activeState.recipe!;
      name = 'Currently Crafting: ${recipe.name}';
      icon = recipe.icon;
      subtitle = 'Restores or creates valuable items';
      progressColor = GameTheme.accentGold;
      cardBg = GameTheme.accentGold.withOpacity(0.05);
    } else {
      final structure = activeState.structure!;
      name = 'Building: ${structure.name}';
      icon = structure.icon;
      subtitle = 'Constructing permanent structure';
      progressColor = GameTheme.craftingCyan;
      cardBg = GameTheme.craftingCyan.withOpacity(0.05);
    }

    final progress = activeState.progress;
    final percent = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: GameTheme.glassCardDecoration(
        customBg: cardBg,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$subtitle | $percent%',
                      style: const TextStyle(color: GameTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: GameTheme.healthRed),
                onPressed: () => engine.cancelAction(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CustomProgressBar(
            progress: progress,
            color: progressColor,
            height: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildZoneActions(GameEngine engine, Zone zone) {
    final activeActionState = engine.activeAction;

    final actionsList = List<ZoneAction>.from(zone.actions);
    actionsList.removeWhere((action) => !engine.isActionVisible(action));
    if (engine.hasStructureInZone(zone.id, 'outpost_shelter')) {

      actionsList.add(const ZoneAction(
        id: 'shelter_rest',
        name: 'Rest in Shelter',
        description: 'Rest inside the outpost shelter to recover health and energy for free.',
        durationSeconds: 4,
        energyCost: -30,
        healthCost: -20,
        xpReward: 5,
        requiredSkill: SkillType.wayfinding,
        requiredLevel: 1,
        lootTable: [],
      ));
    }

    final uncollectedSpawns = engine.getUncollectedSpawnsForZone(zone.id);

    return Container(
      decoration: GameTheme.glassCardDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ZONE ACTIONS',
            style: TextStyle(
              color: GameTheme.accentGold,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          if (uncollectedSpawns.isNotEmpty)
            ...uncollectedSpawns.map((spawn) => ReagentNoticeCard(spawn: spawn, engine: engine)),
          ...actionsList.map((action) {
            final isRunningThis = activeActionState?.action?.id == action.id;
            final runningState = isRunningThis ? activeActionState : null;
            final isRunningAny = activeActionState != null;
            final hasLevelReq = action.requiredSkill == null ||
                (engine.skills[action.requiredSkill!]?.level ?? 0) >= action.requiredLevel;
            final isSkillGated = action.requiredSkill != null &&
                (engine.skills[action.requiredSkill!]?.isGated ?? false);

            final isInteractionEnabled = !(isRunningAny && !isRunningThis);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: BounceTap(
                onTap: isInteractionEnabled
                    ? () {
                        if (isRunningThis) {
                          engine.cancelAction();
                        } else {
                          engine.startAction(action);
                        }
                      }
                    : null,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: isRunningThis
                        ? const Color(0xFF2C3947)
                        : (isInteractionEnabled ? const Color(0xFF222C37) : const Color(0xFF1B232C)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isRunningThis
                          ? GameTheme.accentGold
                          : GameTheme.border.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Fluid wave animation (only visible when running)
                      if (isRunningThis)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FluidWaveBackground(
                              color: GameTheme.getSkillColor(action.requiredSkill ?? SkillType.lore),
                            ),
                          ),
                        ),
                      // Content representation
                      Opacity(
                        opacity: isInteractionEnabled ? 1.0 : 0.4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              // Icon representation
                              Text(
                                action.requiredSkill?.icon ?? '⚡',
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 10),
                              // Action Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      action.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isRunningThis) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const PulsingDot(
                                            color: Colors.greenAccent,
                                            size: 7.0,
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Repeating...',
                                            style: TextStyle(
                                              color: Colors.greenAccent,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (engine.explorationProgress.containsKey(action.id)) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Discovery Progress: ${(engine.explorationProgress[action.id]! * 100).toInt()}%',
                                        style: const TextStyle(
                                          color: GameTheme.accentGold,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 2),
                                    if (action.requiredSkill != null)
                                      Text(
                                        isSkillGated
                                          ? '🔒 Level Capped'
                                          : 'Req: ${action.requiredSkill!.name} Lvl ${action.requiredLevel}+',
                                        style: TextStyle(
                                          color: isSkillGated
                                              ? GameTheme.healthRed
                                              : (hasLevelReq ? GameTheme.textMuted : GameTheme.healthRed),
                                          fontSize: 11,
                                          fontWeight: isSkillGated ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      )
                                    else
                                      const Text(
                                        'Resting Area',
                                        style: TextStyle(color: GameTheme.textMuted, fontSize: 11),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Progress overlay
                      if (runningState != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: AnimatedFractionallySizedBox(
                                  duration: const Duration(milliseconds: 100),
                                  curve: Curves.linear,
                                  widthFactor: runningState.progress,
                                  child: Container(
                                    color: GameTheme.accentGold.withOpacity(0.12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Small progress bar at bottom of card if running
                      if (runningState != null)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: SizedBox(
                            height: 3,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: AnimatedFractionallySizedBox(
                                duration: const Duration(milliseconds: 100),
                                curve: Curves.linear,
                                widthFactor: runningState.progress,
                                child: Container(
                                  color: GameTheme.accentGold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          if (zone.id == 'town_square' && engine.engineFlags.contains('cartographers_tent')) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1B2631),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: GameTheme.border,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Text('🗺️', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Cartographer's Tent",
                          style: TextStyle(
                            color: GameTheme.textLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Review your maps, notes, and trials.",
                          style: TextStyle(
                            color: GameTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/codex');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GameTheme.accentGold,
                      foregroundColor: const Color(0xFF10171E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Open Codex', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillsPanel(GameEngine engine) {
    // Get all skills that have been trained (level > 1 or xp > 0)
    final activeSkills = engine.skills.values
        .where((skill) => skill.level > 1 || skill.xp > 0)
        .toList();

    // Sort by level descending, then by xp descending
    activeSkills.sort((a, b) {
      int cmp = b.level.compareTo(a.level);
      if (cmp != 0) return cmp;
      return b.xp.compareTo(a.xp);
    });

    return Container(
      decoration: GameTheme.glassCardDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'CHARACTER & ACTIVE SKILLS',
            style: TextStyle(
              color: GameTheme.accentGold,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          if (activeSkills.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'No active skills trained yet. Start performing actions in travel zones to level up!',
                style: TextStyle(
                  color: GameTheme.textMuted,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...activeSkills.map((skill) {
              final type = skill.type;
              final color = GameTheme.getSkillColor(type);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${type.icon} ${type.name}: ${skill.level}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          skill.isGated
                              ? '🔒 Gate'
                              : '(${((skill.progress) * 100).toInt()}% to ${skill.level + 1})',
                          style: TextStyle(
                            fontSize: 10,
                            color: skill.isGated ? GameTheme.healthRed : GameTheme.textMuted,
                            fontWeight: skill.isGated ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    CustomProgressBar(
                      progress: skill.progress,
                      color: skill.isGated ? GameTheme.healthRed : color,
                      height: 8,
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildInventoryPanel(GameEngine engine) {
    final inventory = engine.inventory;

    // Show dynamic capacity of slots
    final displayCount = inventory.capacity;

    return Container(
      decoration: GameTheme.glassCardDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'INVENTORY',
                style: TextStyle(
                  color: GameTheme.accentGold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '${inventory.occupiedSlots}/${inventory.capacity} Slots',
                style: const TextStyle(color: GameTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < inventory.slots.length) {
                final slot = inventory.slots[index];
                return BounceTap(
                  onTap: () => ItemDashboardModal.show(
                    context,
                    engine,
                    slot.item,
                    quantity: slot.quantity,
                    contextType: ItemModalContext.inventory,
                    quality: slot.quality,
                    affixIds: slot.affixIds,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF222C37),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: GameTheme.getQualityColor(slot.quality),
                        width: slot.quality != null && slot.quality != QualityTier.standard ? 2.0 : 1.5,
                      ),
                      boxShadow: [
                        if (slot.quality == QualityTier.fine)
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.2),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          ),
                        if (slot.quality == QualityTier.masterwork)
                          BoxShadow(
                            color: GameTheme.accentGold.withOpacity(0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Item Emoji
                        Text(
                          slot.item.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                        // Quantity indicator
                        if (slot.quantity > 1)
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Text(
                              '${slot.quantity}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                    offset: Offset(1, 1),
                                  )
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
            } else {
                // Empty slot representation
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF10171E).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GameTheme.border.withOpacity(0.4), width: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickUseFoodBar(BuildContext context, GameEngine engine) {
    final foodSlots = engine.inventory.slots.where((slot) => slot.item.isFood).toList();

    if (foodSlots.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: GameTheme.glassCardDecoration(
        customBg: Colors.green.withOpacity(0.04),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('🍲', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              const Text(
                'QUICK USE FOOD',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '${foodSlots.length} item type(s)',
                style: const TextStyle(color: GameTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: foodSlots.length,
              itemBuilder: (context, index) {
                final slot = foodSlots[index];
                final item = slot.item;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: BounceTap(
                    onTap: () {
                      engine.useItem(item);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2833),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: GameTheme.border, width: 1.2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.icon, style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 6),
                          Text(
                            '${item.name} (${slot.quantity})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationStatusStrip(BuildContext context, GameEngine engine) {
    final currentZone = engine.currentZone;
    final stations = engine.stationInstances.values
        .where((inst) => inst.zoneId == currentZone.id && !inst.isRuined)
        .toList();

    if (stations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stations.length,
        itemBuilder: (context, index) {
          final inst = stations[index];
          final station = Stations.findById(inst.stationId);
          if (station == null) return const SizedBox.shrink();

          // Determine status, progress, color, active action
          bool isActive = false;
          double progress = 0.0;
          String statusText = 'Idle';
          Color accentColor = GameTheme.textMuted;
          String actionIcon = '';

          if (inst.currentCraft != null) {
            isActive = true;
            progress = inst.currentCraft!.progress;
            final recipe = inst.currentCraft!.recipe;
            statusText = recipe?.name ?? 'Crafting';
            accentColor = GameTheme.craftingCyan;
            actionIcon = recipe?.resultItem?.icon ?? '⚒️';
          } else if (inst.tierUpgrade != null) {
            isActive = true;
            progress = inst.tierUpgrade!.progress;
            statusText = 'Upgrading to T${inst.tier + 1}';
            accentColor = Colors.blueAccent;
            actionIcon = '⚙️';
          } else if (inst.restoration != null) {
            isActive = true;
            progress = inst.restoration!.progress;
            statusText = 'Restoring';
            accentColor = GameTheme.healthRed;
            actionIcon = '🛠️';
          }

          return BounceTap(
            onTap: () {
              engine.focusStation(inst.stationId);
            },
            child: Container(
              width: 170,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: GameTheme.glassCardDecoration(
                customBg: (isActive ? accentColor : Colors.black).withOpacity(isActive ? 0.08 : 0.4),
              ).copyWith(
                border: Border.all(
                  color: isActive ? accentColor.withOpacity(0.5) : GameTheme.border,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(station.icon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          station.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: GameTheme.background.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: accentColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          'T${inst.tier}',
                          style: TextStyle(
                            color: isActive ? Colors.white : GameTheme.textMuted,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isActive && actionIcon.isNotEmpty) ...[
                        Text(actionIcon, style: const TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          statusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isActive ? Colors.white : GameTheme.textMuted,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      if (isActive)
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: GameTheme.background,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestLogChip(BuildContext context, GameEngine engine) {
    if (engine.activeQuests.isEmpty) return const SizedBox.shrink();

    // Prioritize active quests: main > side > daily
    Quest? activeQuest;
    for (var type in [QuestType.main, QuestType.side, QuestType.daily]) {
      final matches = engine.activeQuests.where((q) => q.type == type && q.status == QuestStatus.active).toList();
      if (matches.isNotEmpty) {
        activeQuest = matches.first;
        break;
      }
    }
    
    // If no active quest found, check for any completed but not turned in
    if (activeQuest == null) {
      final completedNotTurnedIn = engine.activeQuests.where((q) => q.isComplete).toList();
      if (completedNotTurnedIn.isNotEmpty) {
        activeQuest = completedNotTurnedIn.first;
      }
    }

    if (activeQuest == null) return const SizedBox.shrink();

    final completedObjectives = activeQuest.objectives.where((o) => o.isComplete).length;
    final totalObjectives = activeQuest.objectives.length;

    Color tintColor;
    String prefix;
    switch (activeQuest.type) {
      case QuestType.main:
        tintColor = const Color(0xFFAB47BC); // purple
        prefix = '📜';
        break;
      case QuestType.side:
        tintColor = const Color(0xFF29B6F6); // blue
        prefix = '🧭';
        break;
      case QuestType.daily:
        tintColor = const Color(0xFF66BB6A); // green
        prefix = '📅';
        break;
    }

    final isQuestComplete = activeQuest.isComplete;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showQuestLogBottomSheet(context, engine),
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: tintColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tintColor.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Text(prefix, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        activeQuest.title,
                        style: const TextStyle(
                          color: GameTheme.textLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isQuestComplete ? 'Ready to turn in' : 'Progress: $completedObjectives/$totalObjectives objectives',
                        style: TextStyle(
                          color: isQuestComplete ? GameTheme.accentGold : GameTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  isQuestComplete ? Icons.check_circle : Icons.play_circle_fill,
                  color: isQuestComplete ? GameTheme.accentGold : tintColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQuestLogBottomSheet(BuildContext context, GameEngine engine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF131920),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border.all(
              color: GameTheme.border.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: GameTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'QUEST LOG',
                style: TextStyle(
                  color: GameTheme.accentGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Ready to turn in
                    ...engine.activeQuests.where((q) => q.isComplete).map((q) => _buildQuestCard(context, engine, q, isReady: true)),
                    
                    // In progress
                    ...engine.activeQuests.where((q) => !q.isComplete).map((q) => _buildQuestCard(context, engine, q, isReady: false)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // View Full Codex button
              ElevatedButton.icon(
                onPressed: engine.engineFlags.contains('cartographers_tent')
                    ? () {
                        Navigator.pop(context);
                        // Navigate to Codex View
                        Navigator.pushNamed(context, '/codex');
                      }
                    : null,
                icon: const Icon(Icons.map, size: 18),
                label: const Text('View Full Codex'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameTheme.accentGold,
                  foregroundColor: const Color(0xFF10171E),
                  disabledBackgroundColor: GameTheme.border.withOpacity(0.5),
                  disabledForegroundColor: GameTheme.textMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestCard(BuildContext context, GameEngine engine, Quest quest, {required bool isReady}) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: GameTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReady ? GameTheme.accentGold : typeColor.withOpacity(0.4),
          width: isReady ? 1.8 : 1.2,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                quest.title,
                style: const TextStyle(
                  color: GameTheme.textLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (isReady)
                const Text(
                  'READY',
                  style: TextStyle(
                    color: GameTheme.accentGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            quest.description,
            style: const TextStyle(
              color: GameTheme.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Objectives:',
            style: TextStyle(
              color: GameTheme.textLight,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          ...quest.objectives.map((obj) => _buildObjectiveRow(obj)),
          const SizedBox(height: 10),
          const Text(
            'Rewards:',
            style: TextStyle(
              color: GameTheme.textLight,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: quest.rewards.map((r) => _buildRewardChip(r)).toList(),
          ),
          if (isReady && quest.turnInLocation != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                engine.turnInQuest(quest.id);
                // Refresh sheet state
                Navigator.pop(context);
                _showQuestLogBottomSheet(context, engine);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GameTheme.accentGold,
                foregroundColor: const Color(0xFF10171E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text('Turn In'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildObjectiveRow(QuestObjective obj) {
    final bool isDone = obj.isComplete;
    final bool isComingSoon = obj.comingSoon;
    final progress = obj.targetCount > 0 ? (obj.currentCount / obj.targetCount) : 0.0;
    
    // Format target name nicely
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
      case ObjectiveKind.cleanse: kindText = 'Cleanse'; break;
      default: kindText = 'Objective'; break;
    }

    final Color textColor = isComingSoon 
        ? GameTheme.textMuted 
        : (isDone ? GameTheme.textMuted : GameTheme.textLight);

    String labelText = '$kindText $targetLabel';
    if (isComingSoon) {
      labelText += ' (Coming Soon)';
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
                child: Row(
                  children: [
                    if (isComingSoon) ...[
                      const Icon(Icons.lock_clock, color: GameTheme.textMuted, size: 14),
                      const SizedBox(width: 4),
                    ] else ...[
                      Text(
                        '• ',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    Expanded(
                      child: Text(
                        labelText,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isComingSoon)
                Text(
                  '${obj.currentCount}/${obj.targetCount}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isComingSoon ? 0.0 : progress,
              backgroundColor: GameTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComingSoon 
                    ? GameTheme.textMuted.withOpacity(0.3) 
                    : (isDone ? GameTheme.textMuted : GameTheme.accentGold),
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
}

class GameProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final String label;

  const GameProgressBar({
    Key? key,
    required this.progress,
    required this.color,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomProgressBar(
      progress: progress,
      color: color,
      label: label,
      height: 10,
    );
  }
}

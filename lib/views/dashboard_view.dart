import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/game_engine.dart';
import '../models/skill.dart';
import '../models/zone.dart';
import '../models/structure.dart';
import '../theme/game_theme.dart';
import '../theme/design_tokens.dart';
import '../widgets/flying_item_overlay.dart';
import '../widgets/particle_explosion.dart';
import '../widgets/you_win_modal.dart';
import 'dashboard/player_hand_section.dart';
import 'dashboard/now_playing_section.dart';
import 'dashboard/world_pulse_section.dart';
import 'dashboard/recent_log_section.dart';

/// Thin dashboard orchestrator: composes the four migrated sections
/// (player hand, now playing, world pulse, recent log) plus the dashboard-level
/// fixtures that were intentionally NOT migrated (the zone-travel sheet, the
/// Cartographer's Tent / Open Codex card, and the YouWin modal).
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
    final engine = context.watch<GameEngine>();

    // PR2: replace with: if (engine.activeCombat != null) return const CombatHud();

    if (engine.tavernRequested) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          engine.tavernRequested = false;
          Navigator.pushNamed(context, '/tavern');
        }
      });
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: DSSpace.section,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PlayerHandSection(),
              const SizedBox(height: DSSpace.md),
              // World Pulse (zone + station status chips) is placed directly
              // beneath the player hand so the station chips stay within the
              // initial viewport (the smoke test taps them without scrolling).
              WorldPulseSection(onZoneTap: () => _showZoneTravelSheet(context, engine)),
              const SizedBox(height: DSSpace.md),
              NowPlayingSection(onTravel: () => _showZoneTravelSheet(context, engine)),
              // Cartographer's Tent card (contains the 'Open Codex' button).
              // Intentionally kept on the dashboard; gated identically to the
              // legacy build (town hub + cartographers_tent flag).
              _buildCartographersTentCard(context, engine),
              const SizedBox(height: DSSpace.md),
              const RecentLogSection(),
            ],
          ),
        ),
        if (engine.shouldShowYouWinModal)
          Positioned.fill(
            child: YouWinModal(
              onContinue: () => engine.dismissYouWinModal(),
            ),
          ),
      ],
    );
  }

  /// Cartographer's Tent card — preserves the dashboard's 'Open Codex' button.
  /// Shown only in the town hub once the `cartographers_tent` flag is set,
  /// matching the legacy gating inside `_buildZoneActions`.
  Widget _buildCartographersTentCard(BuildContext context, GameEngine engine) {
    if (engine.currentZone.id != 'town_square' ||
        !engine.engineFlags.contains('cartographers_tent')) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: DSSpace.md),
      child: Container(
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
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: GameTheme.border,
                                      valueColor: const AlwaysStoppedAnimation<Color>(GameTheme.accentGold),
                                      minHeight: 6,
                                    ),
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
                                                  style: TextStyle(color: GameTheme.textMuted, fontSize: 9),
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
    if (zoneId.contains('sundered_coast')) return '🌊';
    if (zoneId.contains('nexus')) return '🌀';
    return '🏡';
  }
}

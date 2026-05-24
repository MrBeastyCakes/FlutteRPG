import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/game_engine.dart';
import '../models/skill.dart';
import '../models/zone.dart';
import '../theme/game_theme.dart';
import '../widgets/custom_progress_bar.dart';
import '../widgets/activity_log_console.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<GameEngine>(context);
    final stats = engine.playerStats;
    final currentZone = engine.currentZone;

    // Calculate total character level
    int totalLevel = engine.skills.values.fold(0, (sum, skill) => sum + skill.level);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HEADER: Character Info & Stats
          _buildHeader(stats, totalLevel),
          const SizedBox(height: 12),

          // 2. CURRENT LOCATION CARD
          _buildLocationCard(currentZone),
          const SizedBox(height: 12),

          if (engine.activeCombat != null) ...[
            _buildCombatDashboardCard(context, engine),
            const SizedBox(height: 12),
          ],

          _buildActiveRecipeCard(engine),

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
                    _buildInventoryPanel(engine),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4. ACTIVITY LOG
          const ActivityLogConsole(),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic stats, int totalLevel) {
    return Container(
      decoration: GameTheme.glassCardDecoration(
        customBg: const Color(0xFF1E2732).withOpacity(0.85),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Name & Gold
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${stats.name}, Lvl $totalLevel ${stats.title}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    'Gold: ',
                    style: TextStyle(color: GameTheme.textMuted, fontSize: 13),
                  ),
                  Text(
                    '${stats.gold}',
                    style: const TextStyle(
                      color: GameTheme.accentGold,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.monetization_on,
                    color: GameTheme.accentGold,
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
          // Health & Energy bars
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Health
              Row(
                children: [
                  const Icon(Icons.favorite, color: GameTheme.healthRed, size: 16),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 110,
                    child: CustomProgressBar(
                      progress: stats.currentHealth / stats.maxHealth,
                      color: GameTheme.healthRed,
                      height: 12,
                      label: 'Health: ${stats.currentHealth}/${stats.maxHealth}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Energy
              Row(
                children: [
                  const Icon(Icons.bolt, color: GameTheme.energyYellow, size: 16),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 110,
                    child: CustomProgressBar(
                      progress: stats.currentEnergy / stats.maxEnergy,
                      color: GameTheme.energyBlue,
                      height: 12,
                      label: 'Energy: ${stats.currentEnergy}/${stats.maxEnergy}',
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
                    Text(
                      '${beast.icon} ${beast.name}',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
    return Container(
      decoration: GameTheme.glassCardDecoration(
        customBg: const Color(0xFF16212D).withOpacity(0.8),
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
                const Text(
                  'Current Location',
                  style: TextStyle(color: GameTheme.textMuted, fontSize: 11),
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
                Text(
                  'Weather: ${currentZone.weatherBonusDescription}',
                  style: const TextStyle(
                    color: GameTheme.accentGold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
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
        ],
      ),
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
          ...actionsList.map((action) {
            final isRunningThis = activeActionState?.action?.id == action.id;
            final runningState = isRunningThis ? activeActionState : null;
            final isRunningAny = activeActionState != null;
            final hasLevelReq = action.requiredSkill == null ||
                (engine.skills[action.requiredSkill!]?.level ?? 0) >= action.requiredLevel;
            final isSkillGated = action.requiredSkill != null &&
                (engine.skills[action.requiredSkill!]?.isGated ?? false);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Stack(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRunningThis
                          ? const Color(0xFF2C3947)
                          : const Color(0xFF222C37),
                      foregroundColor: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isRunningThis
                              ? GameTheme.accentGold
                              : GameTheme.border.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                    ),
                    onPressed: isRunningAny && !isRunningThis
                        ? null // cannot tap while another runs
                        : () {
                            if (isRunningThis) {
                              engine.cancelAction();
                            } else {
                              engine.startAction(action);
                            }
                          },
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
            );
          }).toList(),
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
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF222C37),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GameTheme.border, width: 1.5),
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
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/game_engine.dart';
import '../models/skill.dart';
import '../models/structure.dart';
import '../models/item.dart';
import '../theme/game_theme.dart';
import '../widgets/custom_progress_bar.dart';

class BuildView extends StatelessWidget {
  const BuildView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<GameEngine>(context);
    final currentZone = engine.currentZone;
    final isTownSquare = currentZone.id == 'town_square';
    final builtStructures = engine.getBuiltStructuresForZone(currentZone.id);
    final activeAction = engine.activeAction;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Glassmorphism Header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: GameTheme.glassCardDecoration(
              customBg: GameTheme.craftingCyan.withOpacity(0.05),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.construction,
                  color: GameTheme.craftingCyan,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CONSTRUCTION SITE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Establish permanent structures to unlock crafting, cooking, and resting in exploration zones.',
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
          const SizedBox(height: 12),

          // Current Zone Info Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: GameTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GameTheme.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: GameTheme.accentGold, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'Location: ',
                      style: TextStyle(color: GameTheme.textMuted, fontSize: 13),
                    ),
                    Text(
                      currentZone.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (!isTownSquare) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Built here: ',
                        style: TextStyle(color: GameTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: builtStructures.isEmpty
                            ? const Text(
                                'No structures built in this zone yet.',
                                style: TextStyle(
                                  color: GameTheme.textMuted,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: builtStructures.map((sId) {
                                  final struct = Structures.findById(sId);
                                  if (struct == null) return const SizedBox.shrink();
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: GameTheme.craftingCyan.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: GameTheme.craftingCyan.withOpacity(0.25)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(struct.icon, style: const TextStyle(fontSize: 10)),
                                        const SizedBox(width: 4),
                                        Text(
                                          struct.name,
                                          style: const TextStyle(
                                            color: GameTheme.craftingCyan,
                                            fontSize: 10,
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
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Town Square Warning Banner
          if (isTownSquare) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GameTheme.healthRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GameTheme.healthRed.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: GameTheme.healthRed, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'TOWN SQUARE RESTRICTION',
                          style: TextStyle(
                            color: GameTheme.healthRed,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Construction is prohibited in the Town Square. Travel to an exploration zone (e.g., Whispering Woods) to start building structures.',
                          style: TextStyle(color: GameTheme.textLight, fontSize: 11, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Active construction overlay (if building in a different zone or generally active)
          if (activeAction != null && activeAction.structure != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: GameTheme.glassCardDecoration(
                customBg: GameTheme.craftingCyan.withOpacity(0.08),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.construction_rounded, color: GameTheme.craftingCyan, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Building ${activeAction.structure!.name}...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(activeAction.progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: GameTheme.craftingCyan,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CustomProgressBar(
                    progress: activeAction.progress,
                    color: GameTheme.craftingCyan,
                    height: 10,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Location: ${activeAction.targetZoneId == 'town_square' ? 'Town Square' : (activeAction.targetZoneId == 'whispering_woods_1' ? 'Whispering Woods Tier 1' : activeAction.targetZoneId ?? '')}',
                        style: const TextStyle(color: GameTheme.textMuted, fontSize: 10),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: GameTheme.healthRed,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(60, 24),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => engine.cancelAction(),
                        icon: const Icon(Icons.cancel, size: 12),
                        label: const Text('Cancel', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Scrollable structures cards list
          Expanded(
            child: ListView.builder(
              itemCount: Structures.all.length,
              itemBuilder: (context, index) {
                final struct = Structures.all[index];
                final alreadyBuilt = engine.hasStructureInZone(currentZone.id, struct.id);
                final skillState = engine.skills[struct.requiredSkill];
                final levelMet = skillState != null && skillState.level >= struct.requiredLevel;
                final isGated = skillState?.isGated ?? false;

                // Check materials costs
                bool hasMaterials = true;
                final costChips = <Widget>[];
                struct.cost.forEach((itemId, qty) {
                  final currentQty = engine.inventory.getItemCount(itemId);
                  final item = Items.findById(itemId);
                  final name = item?.name ?? itemId;
                  final icon = item?.icon ?? '📦';
                  final met = currentQty >= qty;
                  if (!met) {
                    hasMaterials = false;
                  }
                  costChips.add(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151D26),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: met ? GameTheme.border.withOpacity(0.5) : GameTheme.healthRed.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(icon, style: const TextStyle(fontSize: 10)),
                          const SizedBox(width: 4),
                          Text(
                            '$name: ',
                            style: const TextStyle(color: GameTheme.textMuted, fontSize: 10),
                          ),
                          Text(
                            '$currentQty/$qty',
                            style: TextStyle(
                              color: met ? Colors.white : GameTheme.healthRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                });

                // Overall checks
                final energyMet = engine.playerStats.currentEnergy >= struct.energyCost;
                final meetsReqs = levelMet && !isGated && hasMaterials && !alreadyBuilt;
                final canBuild = meetsReqs && energyMet && !isTownSquare && engine.activeAction == null;
                final isCurrentlyBuilding = activeAction != null &&
                    activeAction.structure?.id == struct.id &&
                    activeAction.targetZoneId == currentZone.id;

                return Card(
                  color: GameTheme.cardBg,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isCurrentlyBuilding
                          ? GameTheme.craftingCyan
                          : alreadyBuilt
                              ? GameTheme.border.withOpacity(0.3)
                              : GameTheme.border.withOpacity(0.5),
                      width: isCurrentlyBuilding ? 1.5 : 1,
                    ),
                  ),
                  elevation: alreadyBuilt ? 1 : 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card Header (Icon, Name, Status)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              struct.icon,
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    struct.name,
                                    style: TextStyle(
                                      color: alreadyBuilt ? GameTheme.textMuted : Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      decoration: alreadyBuilt ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    struct.description,
                                    style: const TextStyle(color: GameTheme.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            if (alreadyBuilt)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.green.withOpacity(0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check, color: Colors.greenAccent, size: 10),
                                    SizedBox(width: 4),
                                    Text(
                                      'Built Here',
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Requirements & Cost stats
                        Row(
                          children: [
                            Icon(
                              Icons.psychology,
                              size: 13,
                              color: levelMet ? GameTheme.textMuted : GameTheme.healthRed,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Req: ${struct.requiredSkill.name} Lvl ${struct.requiredLevel}',
                              style: TextStyle(
                                color: isGated
                                    ? GameTheme.healthRed
                                    : (levelMet ? GameTheme.textMuted : GameTheme.healthRed),
                                fontSize: 10,
                                fontWeight: isGated ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            if (isGated) ...[
                              const SizedBox(width: 4),
                              const Text(
                                '(Locked)',
                                style: TextStyle(color: GameTheme.healthRed, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              '⚡: ${struct.energyCost} | ⏱️: ${struct.durationSeconds}s | XP: +${struct.xpReward.toInt()}',
                              style: const TextStyle(color: GameTheme.textMuted, fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Materials Costs Grid/Wrap
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: costChips,
                        ),
                        const SizedBox(height: 10),

                        // Build Action Button
                        if (isCurrentlyBuilding)
                          Row(
                            children: [
                              Expanded(
                                child: CustomProgressBar(
                                  progress: activeAction.progress,
                                  color: GameTheme.craftingCyan,
                                  height: 12,
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GameTheme.healthRed,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: () => engine.cancelAction(),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                            ],
                          )
                        else
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canBuild ? GameTheme.craftingCyan : const Color(0xFF222C37),
                              foregroundColor: canBuild ? Colors.black : GameTheme.textMuted,
                              minimumSize: const Size.fromHeight(36),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: BorderSide(
                                  color: canBuild ? GameTheme.craftingCyan.withOpacity(0.5) : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                            ),
                            onPressed: canBuild
                                ? () => engine.startBuilding(struct, currentZone.id)
                                : null,
                            child: Text(
                              alreadyBuilt
                                  ? 'Already Built'
                                  : isTownSquare
                                      ? 'Cannot Build in Town Square'
                                      : !levelMet
                                          ? 'Level ${struct.requiredLevel} ${struct.requiredSkill.name} Required'
                                          : isGated
                                              ? 'Unlock Level Cap via Skills Trial'
                                              : !hasMaterials
                                                  ? 'Missing Materials'
                                                  : !energyMet
                                                      ? 'Not Enough Energy'
                                                      : activeAction != null
                                                          ? 'Busy doing another action'
                                                          : 'Build',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
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
    );
  }
}

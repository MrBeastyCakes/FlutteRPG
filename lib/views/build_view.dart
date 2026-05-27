import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/game_engine.dart';
import '../models/skill.dart';
import '../models/structure.dart';
import '../models/inventory.dart';
import '../models/item.dart';
import '../models/recipe.dart';
import '../models/crafted_item.dart';
import '../theme/design_tokens.dart';

import '../widgets/game/game_card.dart';
import '../widgets/game/game_button.dart';
import '../widgets/game/game_chip.dart';
import '../widgets/game/game_progress_bar.dart';
import '../widgets/game/game_tabs.dart';
import '../widgets/game/game_list_item.dart';
import '../widgets/game/game_avatar.dart';
import '../widgets/game/game_sheet.dart';
import '../widgets/game/game_toast.dart';
import '../widgets/game/game_tooltip.dart';
import '../widgets/game/game_input.dart';

class BuildView extends StatefulWidget {
  const BuildView({Key? key}) : super(key: key);

  @override
  State<BuildView> createState() => _BuildViewState();
}

class _BuildViewState extends State<BuildView> {
  int _activeSubTab = 0; // 0 = Craft, 1 = Build
  String _selectedStationId = 'crafting_bench';
  String _recipeSearchQuery = '';
  String _selectedCategory = 'All';
  bool _showLocked = false;
  bool _craftableOnly = false;
  int _currentPageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<GameEngine>(context);
    final currentZone = engine.currentZone;
    
    // Switch station if the engine has requested a focus focusStationId
    if (engine.focusedStationId != null) {
      final requestedId = engine.focusedStationId!;
      // Make sure the station is built and operational here before auto-selecting
      final stationKey = "${currentZone.id}::$requestedId";
      if (engine.stationInstances.containsKey(stationKey) && !engine.stationInstances[stationKey]!.isRuined) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _selectedStationId = requestedId;
            _activeSubTab = 0; // Jump to Craft tab
          });
          engine.clearFocusedStation();
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _activeSubTab = 1; // Jump to Build tab to show user
          });
          engine.clearFocusedStation();
        });
      }
    }

    final isTownSquare = currentZone.id == 'town_square';

    // Retrieve built structures
    final builtOperationalStations = engine.stationInstances.values
        .where((s) => s.zoneId == currentZone.id && !s.isRuined)
        .toList();

    // Trail Cook perk: dynamic virtual field kitchen in any zone
    final hasTrailCook = engine.skillSubSpecs[SkillType.cooking] == 'cooking_trailcook';
    if (hasTrailCook) {
      final virtualTrailKitchen = StationInstance(
        zoneId: currentZone.id,
        stationId: 'field_kitchen',
        tier: 1,
        isRuined: false,
        queue: [],
      );
      if (!builtOperationalStations.any((s) => s.stationId == 'field_kitchen')) {
        builtOperationalStations.add(virtualTrailKitchen);
      }
    }

    return Container(
      color: DSColors.surface0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Workshop Dashboard Indicator
          _buildZoneHeader(context, currentZone, builtOperationalStations),

          // Sub-Tab Switcher using GameTabs
          GameTabs(
            tabs: const [
              GameTab(label: 'CRAFT RECIPES', icon: Icons.handyman),
              GameTab(label: 'BUILD STATIONS', icon: Icons.domain),
            ],
            selectedIndex: _activeSubTab,
            onChanged: (index) {
              setState(() {
                _activeSubTab = index;
              });
            },
          ),

          // Active tab view body
          Expanded(
            child: _activeSubTab == 0
                ? _buildCraftTab(context, engine, currentZone, builtOperationalStations)
                : _buildBuildTab(context, engine, currentZone, isTownSquare),
          ),
        ],
      ),
    );
  }

  // Zone Header showing stations and activity indicator
  Widget _buildZoneHeader(BuildContext context, dynamic currentZone, List<StationInstance> builtOperationalStations) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DSSpace.lg, vertical: DSSpace.md),
      decoration: const BoxDecoration(
        color: DSColors.surface1,
        border: Border(bottom: BorderSide(color: DSColors.borderSubtle, width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: DSColors.accent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      currentZone.name.toUpperCase(),
                      style: DSText.headingSmall(context).copyWith(
                        color: DSColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Explore zones to build specialist facilities.',
                  style: DSText.bodySmall(context).copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          // Stations list row
          if (builtOperationalStations.isEmpty)
            Text(
              'No active stations',
              style: DSText.bodySmall(context).copyWith(fontSize: 10, fontStyle: FontStyle.italic),
            )
          else
            Row(
              children: builtOperationalStations.map((inst) {
                final station = Stations.findById(inst.stationId);
                if (station == null) return const SizedBox.shrink();

                // Determine color based on activity
                Color statusColor = DSColors.success;
                if (inst.restoration != null) {
                  statusColor = DSColors.error; // Ruined / Restoring
                } else if (inst.tierUpgrade != null) {
                  statusColor = DSColors.info; // Upgrading
                } else if (inst.currentCraft != null) {
                  statusColor = DSColors.warning; // Crafting active
                }

                String romanTier = _getRomanNumeral(inst.tier);

                return GameTooltip(
                  message: '${station.name} Tier $romanTier',
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: DSColors.surface3,
                      borderRadius: BorderRadius.circular(DSRadius.sm),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(station.icon, style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 2),
                        Text(
                          romanTier,
                          style: DSText.numeric(context).copyWith(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // CRAFT RECIPES TAB
  Widget _buildCraftTab(
      BuildContext context,
      GameEngine engine,
      dynamic currentZone,
      List<StationInstance> builtOperationalStations) {
    if (builtOperationalStations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(DSSpace.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.handyman, size: 64, color: DSColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No Operational Stations Here',
              textAlign: TextAlign.center,
              style: DSText.headingMedium(context),
            ),
            const SizedBox(height: 8),
            Text(
              currentZone.id == 'town_square'
                  ? 'The Town Square stations are ruined. You must restore them in the BUILD STATIONS sub-tab first.'
                  : 'You have not built any crafting or production facilities in ${currentZone.name} yet. Travel to the BUILD STATIONS tab to create one.',
              textAlign: TextAlign.center,
              style: DSText.bodyMedium(context).copyWith(color: DSColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 20),
            GameButton(
              variant: GameButtonVariant.primary,
              label: 'Go Build & Restore',
              onPressed: () {
                setState(() {
                  _activeSubTab = 1; // Swap to build tab
                });
              },
            ),
          ],
        ),
      );
    }

    // Auto-select first operational station if current selection is invalid
    final selectedExists = builtOperationalStations.any((s) => s.stationId == _selectedStationId);
    if (!selectedExists) {
      _selectedStationId = builtOperationalStations.first.stationId;
    }

    final selectedInstance = builtOperationalStations.firstWhere((s) => s.stationId == _selectedStationId);
    final selectedStation = Stations.findById(_selectedStationId)!;
    final recipes = engine.getRecipesForStation(_selectedStationId, showLocked: _showLocked);

    // Categories depend on the station type
    final List<String> categories = ['All'];
    if (_selectedStationId == 'crafting_bench') {
      categories.addAll(['Tools', 'Weapons', 'Armor', 'Glyphs']);
    } else if (_selectedStationId == 'field_kitchen') {
      categories.addAll(['Food/Potions']);
    } else if (_selectedStationId == 'smelter') {
      categories.addAll(['Ingots']);
    } else if (_selectedStationId == 'tannery') {
      categories.addAll(['Leather/Silk']);
    } else if (_selectedStationId == 'apothecary') {
      categories.addAll(['Food/Potions']);
    }

    // Reset selected category if not available on current station
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = 'All';
    }

    // Filter recipes
    final filteredRecipes = recipes.where((r) {
      if (_recipeSearchQuery.isNotEmpty && !r.name.toLowerCase().contains(_recipeSearchQuery.toLowerCase())) {
        return false;
      }
      if (_selectedCategory != 'All') {
        if (_selectedCategory == 'Tools' && r.resultItem?.type != ItemType.tool) return false;
        if (_selectedCategory == 'Weapons' && r.resultItem?.type != ItemType.weapon) return false;
        if (_selectedCategory == 'Armor' && r.resultItem?.type != ItemType.armor) return false;
        if (_selectedCategory == 'Food/Potions' && r.resultItem?.isFood != true) return false;
        if (_selectedCategory == 'Ingots' && !r.resultItemId.contains('ingot')) return false;
        if (_selectedCategory == 'Leather/Silk' && !r.resultItemId.contains('leather') && !r.resultItemId.contains('silk')) return false;
        if (_selectedCategory == 'Glyphs' && !r.resultItemId.contains('glyph')) return false;
      }
      if (_craftableOnly) {
        // Can craft if player has at least slot requirements of some choice
        bool canCraftAllSlots = true;
        for (var slot in r.slots) {
          bool hasAnyChoice = false;
          for (var choice in slot.acceptedItems) {
            if (engine.inventory.getItemCount(choice.itemId) >= slot.quantity) {
              hasAnyChoice = true;
              break;
            }
          }
          if (!hasAnyChoice) {
            canCraftAllSlots = false;
            break;
          }
        }
        if (!canCraftAllSlots) return false;
      }
      return true;
    }).toList();

    // Paginate recipes into chunks of 4 (2x2 grid)
    final List<List<Recipe>> pages = [];
    for (var i = 0; i < filteredRecipes.length; i += 4) {
      pages.add(filteredRecipes.sublist(i, min(i + 4, filteredRecipes.length)));
    }

    // Reset page index if pages shrunk
    if (_currentPageIndex >= pages.length && pages.isNotEmpty) {
      _currentPageIndex = pages.length - 1;
    }

    final double activeStationQualityBias = engine.getStationQualityBias(selectedInstance.tier);

    final List<Widget> materialRepairWidgets = [];
    if (_selectedStationId == 'crafting_bench') {
      // Check tools
      engine.equippedToolSlots.forEach((skill, slot) {
        final stamped = engine.ensureDurabilityStamped(slot);
        if (stamped.currentDurability < stamped.maxDurability) {
          materialRepairWidgets.add(_buildMaterialRepairItemRow(context, engine, stamped, slotName: 'tool', skill: skill));
        }
      });
      // Check weapon
      if (engine.equippedWeaponSlot != null) {
        final stamped = engine.ensureDurabilityStamped(engine.equippedWeaponSlot!);
        if (stamped.currentDurability < stamped.maxDurability) {
          materialRepairWidgets.add(_buildMaterialRepairItemRow(context, engine, stamped, slotName: 'weapon'));
        }
      }
      // Check armor
      if (engine.equippedArmorSlot != null) {
        final stamped = engine.ensureDurabilityStamped(engine.equippedArmorSlot!);
        if (stamped.currentDurability < stamped.maxDurability) {
          materialRepairWidgets.add(_buildMaterialRepairItemRow(context, engine, stamped, slotName: 'armor'));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Station selection row
        _buildStationSelectorRow(builtOperationalStations),

        // Info details of the station
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DSSpace.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${selectedStation.name} Lvl ${selectedInstance.tier}',
                style: DSText.headingSmall(context).copyWith(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                'Quality Bias: +${(activeStationQualityBias * 100).toInt()}% | Slots: ${selectedStation.getTier(selectedInstance.tier).queueSlots}',
                style: DSText.label(context).copyWith(color: DSColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Search & Filters Panel
        _buildSearchAndFiltersPanel(categories),

        if (materialRepairWidgets.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(DSSpace.lg, 8, DSSpace.lg, 8),
            child: GameCard(
              elevation: 2,
              accentColor: DSColors.skill(SkillType.crafting),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text('🛠️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        'EQUIPMENT MAINTENANCE (BENCH REPAIRS)',
                        style: DSText.label(context).copyWith(
                          color: DSColors.skill(SkillType.crafting),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...materialRepairWidgets,
                ],
              ),
            ),
          ),

        // Recipe PageView grid
        Expanded(
          child: pages.isEmpty
              ? _buildEmptyRecipesPlaceholder()
              : _buildRecipeBrowserPageView(pages, engine, selectedInstance),
        ),

        // Queue collapsed drawer
        _buildQueueCollapsedDrawer(engine, selectedInstance),
      ],
    );
  }

  // Horizontal operational station selection row
  Widget _buildStationSelectorRow(List<StationInstance> builtOperationalStations) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: builtOperationalStations.length,
        itemBuilder: (context, index) {
          final inst = builtOperationalStations[index];
          final station = Stations.findById(inst.stationId);
          if (station == null) return const SizedBox.shrink();
          final isSelected = inst.stationId == _selectedStationId;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(station.icon),
                  const SizedBox(width: 6),
                  Text(
                    station.name,
                    style: TextStyle(
                      color: isSelected ? DSColors.textOnAccent : DSColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black.withOpacity(0.2) : DSColors.surface4,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getRomanNumeral(inst.tier),
                      style: TextStyle(
                        color: isSelected ? DSColors.textOnAccent : DSColors.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              selectedColor: DSColors.accent,
              backgroundColor: DSColors.surface2,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedStationId = inst.stationId;
                    _currentPageIndex = 0;
                    if (_pageController.hasClients) {
                      _pageController.jumpToPage(0);
                    }
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaterialRepairItemRow(
    BuildContext context,
    GameEngine engine,
    InventorySlot slot, {
    required String slotName,
    SkillType? skill,
  }) {
    final cost = engine.calculateRepairCost(slot);
    final canRepair = engine.canRepairWithMaterials(slot);

    final costSpans = <TextSpan>[];
    int idx = 0;
    cost.forEach((itemId, qtyNeeded) {
      final item = Items.findById(itemId);
      if (item != null) {
        final count = engine.inventory.getItemCount(itemId);
        final hasEnough = count >= qtyNeeded;
        if (idx > 0) {
          costSpans.add(const TextSpan(text: ', ', style: TextStyle(color: DSColors.textSecondary)));
        }
        costSpans.add(TextSpan(
          text: '${item.icon} ${item.name} ($count/$qtyNeeded)',
          style: TextStyle(
            color: hasEnough ? DSColors.accent : DSColors.error,
            fontWeight: FontWeight.bold,
          ),
        ));
        idx++;
      }
    });

    final currentDurability = slot.currentDurability;
    final maxDurability = slot.maxDurability;
    final progressVal = maxDurability > 0 ? currentDurability / maxDurability : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DSColors.surface3,
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: DSColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GameAvatar(
                emoji: slot.item.icon,
                size: GameAvatarSize.sm,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${slot.quality != null && slot.quality != QualityTier.standard ? "${slot.quality!.name.toUpperCase()} " : ""}${slot.item.name}',
                      style: DSText.bodyMedium(context).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: GameProgressBar(
                            progress: progressVal,
                            color: progressVal == 0
                                ? DSColors.error
                                : progressVal < 0.25
                                    ? DSColors.warning
                                    : DSColors.accent,
                            height: 6,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$currentDurability/$maxDurability',
                          style: DSText.numeric(context).copyWith(fontSize: 10, color: DSColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GameButton(
                variant: canRepair ? GameButtonVariant.primary : GameButtonVariant.ghost,
                label: 'Repair',
                size: GameButtonSize.sm,
                onPressed: canRepair
                    ? () {
                        engine.repairWithMaterials(slot, slot: slotName, skill: skill);
                        GameToast.show(context, 'Successfully repaired ${slot.item.name}!');
                      }
                    : null,
              ),
            ],
          ),
          if (costSpans.isNotEmpty) ...[
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: DSText.bodySmall(context),
                children: [
                  const TextSpan(text: 'Requires: ', style: TextStyle(color: DSColors.textMuted)),
                  ...costSpans,
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Search, category chips, showLocked toggle, craftableOnly toggle
  Widget _buildSearchAndFiltersPanel(List<String> categories) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DSSpace.lg),
      child: Column(
        children: [
          // Search box + Toggle row
          Row(
            children: [
              Expanded(
                child: GameInput(
                  hintText: 'Search recipes...',
                  prefixIcon: const Icon(Icons.search, color: DSColors.textMuted, size: 16),
                  onChanged: (val) {
                    setState(() {
                      _recipeSearchQuery = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Locked toggle
              _buildFilterIconButton(
                icon: _showLocked ? Icons.visibility : Icons.visibility_off,
                active: _showLocked,
                onPressed: () {
                  setState(() {
                    _showLocked = !_showLocked;
                  });
                },
              ),
              const SizedBox(width: 8),
              // Craftable toggle
              _buildFilterIconButton(
                icon: Icons.flash_on,
                active: _craftableOnly,
                onPressed: () {
                  setState(() {
                    _craftableOnly = !_craftableOnly;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Category row (horizontal scroll list)
          if (categories.length > 1)
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0, top: 4, bottom: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? DSColors.accent.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? DSColors.accent : DSColors.borderDefault,
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: DSText.label(context).copyWith(
                              color: isSelected ? DSColors.textPrimary : DSColors.textMuted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

  Widget _buildFilterIconButton({required IconData icon, required bool active, required VoidCallback onPressed}) {
    return Material(
      color: active ? DSColors.accent.withOpacity(0.12) : DSColors.surface2,
      borderRadius: BorderRadius.circular(DSRadius.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(DSRadius.md),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DSRadius.md),
            border: Border.all(color: active ? DSColors.accent : DSColors.borderDefault),
          ),
          child: Icon(
            icon,
            size: 16,
            color: active ? DSColors.accent : DSColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRecipesPlaceholder() {
    final isSaltPress = _selectedStationId == 'salt_press';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DSSpace.xl),
        child: Text(
          isSaltPress
              ? 'No recipes available yet. (Future content)'
              : 'No recipes match the active filters.\nTry enabling "Show Locked" or clearing search query.',
          textAlign: TextAlign.center,
          style: DSText.bodyMedium(context).copyWith(color: DSColors.textMuted, height: 1.4),
        ),
      ),
    );
  }

  // PageView showing 2x2 cards
  Widget _buildRecipeBrowserPageView(List<List<Recipe>> pages, GameEngine engine, StationInstance selectedInstance) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: (idx) {
              setState(() {
                _currentPageIndex = idx;
              });
            },
            itemBuilder: (context, pageIdx) {
              final pageRecipes = pages[pageIdx];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: DSSpace.lg, vertical: DSSpace.sm),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.76,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: pageRecipes.length,
                  itemBuilder: (context, idx) {
                    final recipe = pageRecipes[idx];
                    final isUnlocked = engine.isRecipeUnlocked(recipe);
                    return _buildRecipeCard(context, engine, recipe, isUnlocked, selectedInstance);
                  },
                ),
              );
            },
          ),
        ),
        // Dots indicator
        if (pages.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (index) {
                final isSelected = index == _currentPageIndex;
                return Container(
                  width: isSelected ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isSelected ? DSColors.accent : DSColors.borderDefault,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  // Individual Recipe Card
  Widget _buildRecipeCard(BuildContext context, GameEngine engine, Recipe recipe, bool isUnlocked, StationInstance inst) {
    final resultItem = recipe.resultItem;
    if (resultItem == null) return const SizedBox.shrink();

    // Custom coloring based on recipe rarity
    Color rarityBorder = DSColors.borderSubtle;
    Color? accentBar;
    if (recipe.rarity == RecipeRarity.rare) {
      rarityBorder = DSColors.info;
      accentBar = DSColors.info;
    } else if (recipe.rarity == RecipeRarity.legendary) {
      rarityBorder = DSColors.accent;
      accentBar = DSColors.accent;
    }

    final skillState = engine.skills[recipe.requiredSkill];
    final levelMet = skillState != null && skillState.level >= recipe.requiredLevel;

    // Check if player has default ingredients
    bool canQuickQueue = isUnlocked && levelMet;
    for (var slot in recipe.slots) {
      final canonicalItem = slot.acceptedItems.first.itemId;
      if (engine.inventory.getItemCount(canonicalItem) < slot.quantity) {
        canQuickQueue = false;
        break;
      }
    }

    return GameCard(
      elevation: isUnlocked ? 1 : 0,
      accentColor: accentBar,
      onTap: () {
        if (!isUnlocked) {
          GameToast.show(context, '🔒 Recipe Locked: Find the blueprint scroll for "${recipe.name}" to unlock.', isError: true);
          return;
        }
        if (!levelMet) {
          GameToast.show(context, '⚠️ Requires level ${recipe.requiredLevel} ${recipe.requiredSkill.name}.', isError: true);
          return;
        }
        // Open Configuration Sheet
        _showRecipeConfigSheet(context, engine, recipe, inst);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon and Name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GameAvatar(
                emoji: resultItem.icon,
                size: GameAvatarSize.sm,
                backgroundColor: isUnlocked ? DSColors.surface3 : DSColors.surface1,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  recipe.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DSText.headingSmall(context).copyWith(
                    color: isUnlocked ? DSColors.textPrimary : DSColors.textDisabled,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Req level
          Row(
            children: [
              Icon(
                Icons.psychology,
                size: 11,
                color: levelMet ? DSColors.textMuted : DSColors.error,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  '${recipe.requiredSkill.name.substring(0, min(5, recipe.requiredSkill.name.length))} Lvl ${recipe.requiredLevel}',
                  style: DSText.bodySmall(context).copyWith(
                    color: levelMet ? DSColors.textMuted : DSColors.error,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Input items horizontal row
          Row(
            children: recipe.slots.map((slot) {
              final item = Items.findById(slot.acceptedItems.first.itemId);
              final hasEnough = engine.inventory.getItemCount(slot.acceptedItems.first.itemId) >= slot.quantity;
              return Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: DSColors.surface0,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: hasEnough ? DSColors.borderSubtle : DSColors.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item?.icon ?? '📦', style: const TextStyle(fontSize: 9)),
                    const SizedBox(width: 1),
                    Text(
                      '${slot.quantity}',
                      style: DSText.numeric(context).copyWith(
                        color: hasEnough ? DSColors.textSecondary : DSColors.error,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          // Queue Button
          GameButton(
            variant: canQuickQueue ? GameButtonVariant.primary : GameButtonVariant.ghost,
            label: 'Quick Queue',
            size: GameButtonSize.sm,
            onPressed: canQuickQueue
                ? () {
                    engine.startCrafting(recipe);
                    GameToast.show(context, 'Queued 1x ${recipe.name}!');
                  }
                : null,
          ),
        ],
      ),
    );
  }

  // Collapsed single-line queue drawer at bottom
  Widget _buildQueueCollapsedDrawer(GameEngine engine, StationInstance inst) {
    final activeCraft = inst.currentCraft;
    final totalQueued = inst.queue.fold<int>(0, (sum, item) => sum + item.count);

    if (activeCraft == null && totalQueued == 0) {
      return const SizedBox.shrink();
    }

    final recipe = activeCraft?.recipe;

    return InkWell(
      onTap: () {
        _showExpandedQueueSheet(context, engine, inst);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: DSSpace.lg, vertical: 10.0),
        decoration: const BoxDecoration(
          color: DSColors.surface1,
          border: Border(top: BorderSide(color: DSColors.borderDefault, width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: DSColors.accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activeCraft != null
                        ? 'Crafting: ${recipe?.name ?? ""} (${(activeCraft.progress * 100).toInt()}%)'
                        : 'Idle (Wait for energy)',
                    style: DSText.bodyMedium(context).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (totalQueued > 0)
                  Text(
                    '+ $totalQueued queued',
                    style: DSText.numeric(context).copyWith(color: DSColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_up, color: DSColors.textMuted, size: 16),
              ],
            ),
            if (activeCraft != null) ...[
              const SizedBox(height: 6),
              GameProgressBar(
                progress: activeCraft.progress,
                color: DSColors.accent,
                height: 4,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Expanded Queue Sheet Modal
  void _showExpandedQueueSheet(BuildContext context, GameEngine engine, StationInstance inst) {
    GameSheet.show(
      context: context,
      title: '${Stations.findById(inst.stationId)?.name ?? ""} Queue',
      child: ListenableBuilder(
        listenable: engine,
        builder: (context, _) {
          final activeCraft = inst.currentCraft;
          final queueList = inst.queue;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Head: Current Craft
              if (activeCraft != null) ...[
                Text(
                  'IN PROGRESS',
                  style: DSText.label(context),
                ),
                const SizedBox(height: 6),
                GameCard(
                  elevation: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          GameAvatar(
                            emoji: activeCraft.recipe?.resultItem?.icon ?? '📦',
                            size: GameAvatarSize.sm,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              activeCraft.recipe?.name ?? '',
                              style: DSText.bodyMedium(context).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            '${(activeCraft.progress * 100).toInt()}%',
                            style: DSText.numeric(context).copyWith(color: DSColors.accent, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GameProgressBar(
                        progress: activeCraft.progress,
                        color: DSColors.accent,
                        height: 8,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Remaining time: ${(activeCraft.durationSeconds * (1.0 - activeCraft.progress)).toStringAsFixed(1)}s',
                            style: DSText.bodySmall(context).copyWith(color: DSColors.textMuted),
                          ),
                          GameButton(
                            variant: GameButtonVariant.danger,
                            label: 'Cancel',
                            size: GameButtonSize.sm,
                            onPressed: () {
                              engine.cancelStationQueueEntry("${inst.zoneId}::${inst.stationId}", 0);
                              if (inst.queue.isEmpty && inst.currentCraft == null) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DSColors.surface2,
                    borderRadius: BorderRadius.circular(DSRadius.md),
                  ),
                  child: Center(
                    child: Text(
                      _selectedStationId == 'salt_press'
                          ? 'Idle — no recipes to queue.'
                          : 'Station is currently idle.',
                      style: DSText.bodyMedium(context).copyWith(color: DSColors.textMuted, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Queue entries list
              Text(
                'QUEUE LINE',
                style: DSText.label(context),
              ),
              const SizedBox(height: 6),
              queueList.length <= 1
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'No other items in queue.',
                          style: DSText.bodyMedium(context).copyWith(color: DSColors.textMuted),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: queueList.length - 1,
                      itemBuilder: (context, index) {
                        // queueList[0] is in-flight, so list index starts from 1
                        final queueIdx = index + 1;
                        final entry = queueList[queueIdx];
                        final recipe = Recipes.findById(entry.recipeId);
                        if (recipe == null) return const SizedBox.shrink();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: DSColors.surface2,
                            borderRadius: BorderRadius.circular(DSRadius.md),
                            border: Border.all(color: DSColors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              GameAvatar(
                                emoji: recipe.resultItem?.icon ?? '📦',
                                size: GameAvatarSize.sm,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recipe.name,
                                      style: DSText.bodyMedium(context).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Count: ${entry.count} iterations',
                                      style: DSText.bodySmall(context),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: DSColors.error, size: 18),
                                onPressed: () {
                                  engine.cancelStationQueueEntry("${inst.zoneId}::${inst.stationId}", queueIdx);
                                },
                              ),
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

  // Configuration Modal Sheet for slots choices, modifiers, and count
  void _showRecipeConfigSheet(BuildContext context, GameEngine engine, Recipe recipe, StationInstance inst) {
    final resultItem = recipe.resultItem;
    if (resultItem == null) return;

    // Track chosen item IDs for each slot (slotIndex -> chosenItemId)
    final Map<int, String> slotChoices = {};
    for (int i = 0; i < recipe.slots.length; i++) {
      final slot = recipe.slots[i];
      // Pick first item the player actually has, or canonical as fallback
      String bestChoice = slot.acceptedItems.first.itemId;
      for (var choice in slot.acceptedItems) {
        if (engine.inventory.getItemCount(choice.itemId) >= slot.quantity) {
          bestChoice = choice.itemId;
          break;
        }
      }
      slotChoices[i] = bestChoice;
    }

    String? selectedModifierItemId;
    int craftCount = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Find valid modifiers
            final List<Item> availableModifiers = [];
            final modifierCandidates = [
              Items.wildflower,  // XP
              Items.nightshade,  // Affix
              Items.riverClay,   // Save mats
              Items.wildBerries, // Standard Floor
              Items.trollClaw,   // Fine Floor
              Items.boarTusk,    // Extra qty
              Items.moonpetal,   // Forces affix roll
              Items.spiritSap,   // Doubles craft output
              Items.hollowBone,  // Grants Brutal weapon affix
              Items.seaTear,     // Grants Tempered armor affix
              Items.coalblood,   // Grants Frugal affix
              Items.wispLight,   // Guarantees Masterwork quality
            ];
            for (var m in modifierCandidates) {
              if (engine.inventory.getItemCount(m.id) > 0) {
                availableModifiers.add(m);
              }
            }

            // Calculate max craft count based on ingredients
            int maxCraftCount = 999;
            for (int i = 0; i < recipe.slots.length; i++) {
              final slot = recipe.slots[i];
              final chosenItemId = slotChoices[i]!;
              final inventoryQty = engine.inventory.getItemCount(chosenItemId);
              final slotMax = inventoryQty ~/ slot.quantity;
              if (slotMax < maxCraftCount) {
                maxCraftCount = slotMax;
              }
            }

            if (selectedModifierItemId != null) {
              final modInvQty = engine.inventory.getItemCount(selectedModifierItemId!);
              if (modInvQty < maxCraftCount) {
                maxCraftCount = modInvQty;
              }
            }

            if (maxCraftCount == 0) {
              maxCraftCount = 1; // display at least 1
            }

            if (craftCount > maxCraftCount) {
              craftCount = maxCraftCount;
            }

            return GameSheet(
              title: 'Configure: ${recipe.name}',
              actions: [
                GameButton(
                  variant: GameButtonVariant.primary,
                  label: 'Queue $craftCount x ${recipe.name}',
                  onPressed: () {
                    // Check if player has all choices multiplied by craftCount
                    bool hasAll = true;
                    for (int i = 0; i < recipe.slots.length; i++) {
                      final slot = recipe.slots[i];
                      final chosen = slotChoices[i]!;
                      if (engine.inventory.getItemCount(chosen) < slot.quantity * craftCount) {
                        hasAll = false;
                        break;
                      }
                    }
                    if (selectedModifierItemId != null) {
                      if (engine.inventory.getItemCount(selectedModifierItemId!) < craftCount) {
                        hasAll = false;
                      }
                    }

                    if (!hasAll) {
                      GameToast.show(context, '⚠️ Missing required materials for selected quantity!', isError: true);
                      return;
                    }

                    // Queue it in the engine
                    final stationKey = "${inst.zoneId}::${inst.stationId}";
                    engine.queueStationCraft(
                      stationKey,
                      recipe.id,
                      slotChoices,
                      modifierItemId: selectedModifierItemId,
                      count: craftCount,
                    );

                    Navigator.pop(context);
                  },
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Slots inputs
                  Text(
                    'REQUIRED INGREDIENTS',
                    style: DSText.label(context),
                  ),
                  const SizedBox(height: 6),
                  Column(
                    children: List.generate(recipe.slots.length, (slotIdx) {
                      final slot = recipe.slots[slotIdx];
                      final chosenItemId = slotChoices[slotIdx]!;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: DSColors.surface2,
                          borderRadius: BorderRadius.circular(DSRadius.md),
                          border: Border.all(color: DSColors.borderDefault),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Slot ${slotIdx + 1} (${slot.quantity}x): ',
                              style: DSText.label(context).copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButton<String>(
                                value: chosenItemId,
                                isExpanded: true,
                                dropdownColor: DSColors.surface2,
                                underline: const SizedBox.shrink(),
                                style: DSText.bodyMedium(context),
                                onChanged: (newVal) {
                                  if (newVal != null) {
                                    setModalState(() {
                                      slotChoices[slotIdx] = newVal;
                                    });
                                  }
                                },
                                items: slot.acceptedItems.map((choice) {
                                  final item = Items.findById(choice.itemId);
                                  final invQty = engine.inventory.getItemCount(choice.itemId);
                                  final reqQty = slot.quantity * craftCount;
                                  final enough = invQty >= reqQty;

                                  String biasLabel = '';
                                  if (choice.qualityBias != 0.0) {
                                    final sign = choice.qualityBias > 0 ? '+' : '';
                                    biasLabel = ' ($sign${(choice.qualityBias * 100).toInt()}% Qual)';
                                  }

                                  return DropdownMenuItem<String>(
                                    value: choice.itemId,
                                    child: Row(
                                      children: [
                                        Text(item?.icon ?? '📦'),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${item?.name ?? choice.itemId}$biasLabel',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: enough ? DSColors.textPrimary : DSColors.error,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '$invQty/$reqQty',
                                          style: DSText.numeric(context).copyWith(
                                            color: enough ? DSColors.textMuted : DSColors.error,
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
                      );
                    }),
                  ),
                  const SizedBox(height: 8),

                  // Modifier slot
                  Text(
                    'ACTIVE MODIFIER (OPTIONAL)',
                    style: DSText.label(context),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: DSColors.surface2,
                      borderRadius: BorderRadius.circular(DSRadius.md),
                      border: Border.all(color: DSColors.borderDefault),
                    ),
                    child: DropdownButton<String?>(
                      value: selectedModifierItemId,
                      isExpanded: true,
                      dropdownColor: DSColors.surface2,
                      underline: const SizedBox.shrink(),
                      hint: Text('Select a modifier item (none)', style: DSText.bodyMedium(context).copyWith(color: DSColors.textDisabled)),
                      style: DSText.bodyMedium(context),
                      onChanged: (newVal) {
                        if (newVal == 'hollow_bone' && recipe.resultItem?.type != ItemType.weapon) {
                          _showModifierWarningDialog(
                            context,
                            'Hollow Bone',
                            'weapons',
                            recipe.resultItem?.name ?? 'this item',
                            () {
                              setModalState(() {
                                selectedModifierItemId = newVal;
                              });
                            },
                            () {
                              setModalState(() {
                                selectedModifierItemId = null;
                              });
                            },
                          );
                        } else if (newVal == 'sea_tear' && recipe.resultItem?.type != ItemType.armor) {
                          _showModifierWarningDialog(
                            context,
                            'Sea-Tear',
                            'armor',
                            recipe.resultItem?.name ?? 'this item',
                            () {
                              setModalState(() {
                                selectedModifierItemId = newVal;
                              });
                            },
                            () {
                              setModalState(() {
                                selectedModifierItemId = null;
                              });
                            },
                          );
                        } else {
                          setModalState(() {
                            selectedModifierItemId = newVal;
                          });
                        }
                      },
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('None (No modifier active)'),
                        ),
                        ...availableModifiers.map((m) {
                          final invQty = engine.inventory.getItemCount(m.id);

                          String effectDesc = '';
                          if (m.id == 'wildflower') effectDesc = '+50% XP';
                          if (m.id == 'nightshade') effectDesc = 'Force Affix';
                          if (m.id == 'river_clay') effectDesc = '30% Save Chance';
                          if (m.id == 'wild_berries') effectDesc = 'Standard Quality Floor';
                          if (m.id == 'troll_claw') effectDesc = 'Fine Quality Floor';
                          if (m.id == 'boar_tusk') effectDesc = '+1 Output Qty';
                          if (m.id == 'moonpetal') effectDesc = 'Force Affix (Moonpetal)';
                          if (m.id == 'spirit_sap') effectDesc = 'Double Output (Spirit Sap)';
                          if (m.id == 'hollow_bone') effectDesc = 'Brutal Weapon Affix (Hollow Bone)';
                          if (m.id == 'sea_tear') effectDesc = 'Tempered Armor Affix (Sea-Tear)';
                          if (m.id == 'coalblood') effectDesc = 'Frugal Affix (Coalblood)';
                          if (m.id == 'wisp_light') effectDesc = 'Guaranteed Masterwork (Wisp-Light)';

                          return DropdownMenuItem<String?>(
                            value: m.id,
                            child: Row(
                              children: [
                                Text(m.icon),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${m.name} ($effectDesc)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'Qty: $invQty',
                                  style: DSText.bodySmall(context),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Count Picker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CRAFT QUANTITY',
                        style: DSText.bodyMedium(context).copyWith(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: DSColors.accent),
                            onPressed: craftCount > 1
                                ? () {
                                    setModalState(() {
                                      craftCount--;
                                    });
                                  }
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: DSColors.surface2,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: DSColors.borderDefault),
                            ),
                            child: Text(
                              '$craftCount',
                              style: DSText.numeric(context).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: DSColors.accent),
                            onPressed: craftCount < maxCraftCount
                                ? () {
                                    setModalState(() {
                                      craftCount++;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // BUILD STATIONS SUB-TAB
  Widget _buildBuildTab(
      BuildContext context,
      GameEngine engine,
      dynamic currentZone,
      bool isTownSquare) {
    
    // In Town Square, we display the preplaced stations in "ruined" or operational/upgrade state
    if (isTownSquare) {
      final benchInst = engine.stationInstances['town_square::crafting_bench'];
      final kitchenInst = engine.stationInstances['town_square::field_kitchen'];

      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            // Town Square Warning Banner
            GameCard(
              elevation: 0,
              accentColor: DSColors.error,
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: DSColors.error, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOWN SQUARE RESTRICTION',
                          style: DSText.label(context).copyWith(
                            color: DSColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Building from scratch is prohibited here. Only the pre-existing ruined Crafting Bench and Field Kitchen can be restored.',
                          style: DSText.bodySmall(context).copyWith(color: DSColors.textPrimary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (benchInst != null) _buildTownSquareStationCard(context, engine, Stations.craftingBench, benchInst),
            if (kitchenInst != null) _buildTownSquareStationCard(context, engine, Stations.fieldKitchen, kitchenInst),
          ],
        ),
      );
    }

    // In exploration zones, we list all structures from Structures.all
    final activeAction = engine.activeAction;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Active action banner if upgrading/restoring/building
          if (activeAction != null && activeAction.station != null) ...[
            GameCard(
              elevation: 2,
              accentColor: DSColors.accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.construction_rounded, color: DSColors.accent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        activeAction.isRestoration
                            ? 'Restoring ${activeAction.station!.name}...'
                            : activeAction.isUpgrade
                                ? 'Upgrading ${activeAction.station!.name}...'
                                : 'Building ${activeAction.station!.name}...',
                        style: DSText.bodyMedium(context).copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '${(activeAction.progress * 100).toInt()}%',
                        style: DSText.numeric(context).copyWith(color: DSColors.accent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GameProgressBar(
                    progress: activeAction.progress,
                    color: DSColors.accent,
                    height: 10,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Remaining: ${(activeAction.durationSeconds * (1.0 - activeAction.progress)).toStringAsFixed(1)}s',
                        style: DSText.bodySmall(context),
                      ),
                      GameButton(
                        variant: GameButtonVariant.danger,
                        label: 'Cancel',
                        size: GameButtonSize.sm,
                        onPressed: () => engine.cancelAction(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else if (activeAction != null && activeAction.structure != null) ...[
            GameCard(
              elevation: 2,
              accentColor: DSColors.accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.construction_rounded, color: DSColors.accent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Building ${activeAction.structure!.name}...',
                        style: DSText.bodyMedium(context).copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '${(activeAction.progress * 100).toInt()}%',
                        style: DSText.numeric(context).copyWith(color: DSColors.accent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GameProgressBar(
                    progress: activeAction.progress,
                    color: DSColors.accent,
                    height: 10,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Remaining: ${(activeAction.durationSeconds * (1.0 - activeAction.progress)).toStringAsFixed(1)}s',
                        style: DSText.bodySmall(context),
                      ),
                      GameButton(
                        variant: GameButtonVariant.danger,
                        label: 'Cancel',
                        size: GameButtonSize.sm,
                        onPressed: () => engine.cancelAction(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Expanded(
            child: ListView.builder(
              itemCount: Structures.all.length,
              itemBuilder: (context, index) {
                final struct = Structures.all[index];
                final station = Stations.findById(struct.id)!;
                final stationKey = "${currentZone.id}::${struct.id}";
                final inst = engine.stationInstances[stationKey];

                return _buildExplorationStationCard(context, engine, struct, station, inst, currentZone);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Station card for ruined Town Square instances
  Widget _buildTownSquareStationCard(
      BuildContext context, GameEngine engine, Station station, StationInstance inst) {
    final activeAction = engine.activeAction;
    final isCurrentlyRestoring = activeAction != null &&
        activeAction.isRestoration &&
        activeAction.station?.id == station.id;
    final isCurrentlyUpgrading = activeAction != null &&
        activeAction.isUpgrade &&
        activeAction.station?.id == station.id;

    if (inst.isRuined) {
      // Show Ruined restoration card
      final Map<String, int> restorationCost = (station.id == 'crafting_bench')
          ? {'oak_log': 5, 'river_clay': 3}
          : {'oak_log': 3, 'river_clay': 5};
      const int energyCost = 5;
      const int durationSeconds = 10;

      // Verify materials
      bool hasMaterials = true;
      final costChips = <Widget>[];
      restorationCost.forEach((itemId, qty) {
        final currentQty = engine.inventory.getItemCount(itemId);
        final item = Items.findById(itemId);
        final met = currentQty >= qty;
        if (!met) hasMaterials = false;

        costChips.add(_buildCostChip(item?.icon ?? '📦', item?.name ?? itemId, currentQty, qty, met));
      });

      final energyMet = engine.playerStats.currentEnergy >= energyCost;
      final canRestore = hasMaterials && energyMet && activeAction == null;

      return GameCard(
        elevation: 2,
        accentColor: DSColors.error,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                GameAvatar(emoji: station.icon, size: GameAvatarSize.md, ringColor: DSColors.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ruined ${station.name}',
                        style: DSText.headingSmall(context).copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'This town square facility is ruined. Restore it to operational state to unlock crafting recipes.',
                        style: DSText.bodySmall(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.psychology, size: 12, color: DSColors.textMuted),
                const SizedBox(width: 4),
                Text('Req: Level 1 in primary skill', style: DSText.bodySmall(context)),
                const Spacer(),
                Text('⚡: 5 | ⏱️: 10s', style: DSText.bodySmall(context)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 4, children: costChips),
            const SizedBox(height: 10),
            if (isCurrentlyRestoring)
              Row(
                children: [
                  Expanded(
                    child: GameProgressBar(
                      progress: activeAction!.progress,
                      color: DSColors.error,
                      height: 12,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GameButton(
                    variant: GameButtonVariant.danger,
                    label: 'Cancel',
                    size: GameButtonSize.sm,
                    onPressed: () => engine.cancelAction(),
                  ),
                ],
              )
            else
              GameButton(
                variant: canRestore ? GameButtonVariant.primary : GameButtonVariant.ghost,
                label: !hasMaterials
                    ? 'Missing Materials'
                    : !energyMet
                        ? 'Not Enough Energy'
                        : activeAction != null
                            ? 'Busy'
                            : 'Restore Station',
                onPressed: canRestore ? () => engine.startRestoringStation(station.id) : null,
              ),
          ],
        ),
      );
    } else {
      // Operational, show upgrade card
      final isMaxed = inst.tier >= station.maxTier;
      final nextTierVal = inst.tier + 1;
      final nextTier = isMaxed ? null : station.getTier(nextTierVal);

      bool hasMaterials = true;
      final costChips = <Widget>[];
      if (nextTier != null) {
        nextTier.upgradeCost.forEach((itemId, qty) {
          final currentQty = engine.inventory.getItemCount(itemId);
          final item = Items.findById(itemId);
          final met = currentQty >= qty;
          if (!met) hasMaterials = false;

          costChips.add(_buildCostChip(item?.icon ?? '📦', item?.name ?? itemId, currentQty, qty, met));
        });
      }

      final primarySkill = engine.skills[station.primarySkill];
      final levelMet = nextTier == null || (primarySkill != null && primarySkill.level >= nextTier.requiredSkillLevel);
      final energyMet = nextTier == null || engine.playerStats.currentEnergy >= nextTier.upgradeEnergyCost;
      final canUpgrade = nextTier != null && levelMet && hasMaterials && energyMet && activeAction == null;

      return GameCard(
        elevation: 2,
        accentColor: isCurrentlyUpgrading ? DSColors.accent : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                GameAvatar(emoji: station.icon, size: GameAvatarSize.md),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${station.name} (Tier ${inst.tier})',
                        style: DSText.headingSmall(context).copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isMaxed
                            ? 'Fully upgraded and operational!'
                            : 'Upgrading unlocks quality bonuses, faster crafting, and parallel slots.',
                        style: DSText.bodySmall(context),
                      ),
                    ],
                  ),
                ),
                if (isMaxed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: DSColors.accent.withOpacity(0.15),
                      border: Border.all(color: DSColors.accent),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('MAX TIER', style: TextStyle(color: DSColors.accent, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (!isMaxed && nextTier != null) ...[
              Row(
                children: [
                  Icon(Icons.psychology, size: 12, color: levelMet ? DSColors.textMuted : DSColors.error),
                  const SizedBox(width: 4),
                  Text(
                    'Req: Lvl ${nextTier.requiredSkillLevel} ${station.primarySkill.name}',
                    style: DSText.bodySmall(context).copyWith(color: levelMet ? DSColors.textMuted : DSColors.error),
                  ),
                  const Spacer(),
                  Text(
                    '⚡: ${nextTier.upgradeEnergyCost} | ⏱️: ${nextTier.upgradeDurationSeconds}s',
                    style: DSText.bodySmall(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 4, children: costChips),
              const SizedBox(height: 10),
              if (isCurrentlyUpgrading)
                Row(
                  children: [
                    Expanded(
                      child: GameProgressBar(
                        progress: activeAction!.progress,
                        color: DSColors.accent,
                        height: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GameButton(
                      variant: GameButtonVariant.danger,
                      label: 'Cancel',
                      size: GameButtonSize.sm,
                      onPressed: () => engine.cancelAction(),
                    ),
                  ],
                )
              else
                GameButton(
                  variant: canUpgrade ? GameButtonVariant.primary : GameButtonVariant.ghost,
                  label: !levelMet
                      ? 'Requires Lvl ${nextTier.requiredSkillLevel} ${station.primarySkill.name}'
                      : !hasMaterials
                          ? 'Missing Materials'
                          : !energyMet
                              ? 'Not Enough Energy'
                              : activeAction != null
                                  ? 'Busy'
                                  : 'Upgrade to Tier $nextTierVal',
                  onPressed: canUpgrade ? () => engine.startUpgradingStation(station.id) : null,
                ),
            ],
          ],
        ),
      );
    }
  }

  // Station card for exploration zones
  Widget _buildExplorationStationCard(
      BuildContext context, GameEngine engine, Structure struct, Station station, StationInstance? inst, dynamic currentZone) {
    final activeAction = engine.activeAction;
    final alreadyBuilt = inst != null;

    final isCurrentlyBuilding = activeAction != null &&
        !activeAction.isUpgrade &&
        !activeAction.isRestoration &&
        activeAction.structure?.id == struct.id &&
        activeAction.targetZoneId == currentZone.id;
    final isCurrentlyUpgrading = activeAction != null &&
        activeAction.isUpgrade &&
        activeAction.station?.id == station.id &&
        activeAction.targetZoneId == currentZone.id;

    if (!alreadyBuilt) {
      // Not built card
      bool hasMaterials = true;
      final costChips = <Widget>[];
      struct.cost.forEach((itemId, qty) {
        final currentQty = engine.inventory.getItemCount(itemId);
        final item = Items.findById(itemId);
        final met = currentQty >= qty;
        if (!met) hasMaterials = false;

        costChips.add(_buildCostChip(item?.icon ?? '📦', item?.name ?? itemId, currentQty, qty, met));
      });

      final skillState = engine.skills[struct.requiredSkill];
      final levelMet = skillState != null && skillState.level >= struct.requiredLevel;
      final energyMet = engine.playerStats.currentEnergy >= struct.energyCost;
      final canBuild = levelMet && hasMaterials && energyMet && activeAction == null;

      return GameCard(
        elevation: 2,
        accentColor: isCurrentlyBuilding ? DSColors.accent : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                GameAvatar(emoji: struct.icon, size: GameAvatarSize.md),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Build ${struct.name}',
                        style: DSText.headingSmall(context).copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        struct.description,
                        style: DSText.bodySmall(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.psychology, size: 12, color: levelMet ? DSColors.textMuted : DSColors.error),
                const SizedBox(width: 4),
                Text(
                  'Req: Level ${struct.requiredLevel} ${struct.requiredSkill.name}',
                  style: DSText.bodySmall(context).copyWith(color: levelMet ? DSColors.textMuted : DSColors.error),
                ),
                const Spacer(),
                Text(
                  '⚡: ${struct.energyCost} | ⏱️: ${struct.durationSeconds}s | XP: +${struct.xpReward.toInt()}',
                  style: DSText.bodySmall(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 4, children: costChips),
            const SizedBox(height: 10),
            if (isCurrentlyBuilding)
              Row(
                children: [
                  Expanded(
                    child: GameProgressBar(
                      progress: activeAction!.progress,
                      color: DSColors.accent,
                      height: 12,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GameButton(
                    variant: GameButtonVariant.danger,
                    label: 'Cancel',
                    size: GameButtonSize.sm,
                    onPressed: () => engine.cancelAction(),
                  ),
                ],
              )
            else
              GameButton(
                variant: canBuild ? GameButtonVariant.primary : GameButtonVariant.ghost,
                label: !levelMet
                    ? 'Requires Lvl ${struct.requiredLevel} ${struct.requiredSkill.name}'
                    : !hasMaterials
                        ? 'Missing Materials'
                        : !energyMet
                            ? 'Not Enough Energy'
                            : activeAction != null
                                ? 'Busy'
                                : 'Build Station',
                onPressed: canBuild ? () => engine.startBuilding(struct, currentZone.id) : null,
              ),
          ],
        ),
      );
    } else {
      // Built, show upgrade options
      final isMaxed = inst.tier >= station.maxTier;
      final nextTierVal = inst.tier + 1;
      final nextTier = isMaxed ? null : station.getTier(nextTierVal);

      bool hasMaterials = true;
      final costChips = <Widget>[];
      if (nextTier != null) {
        nextTier.upgradeCost.forEach((itemId, qty) {
          final currentQty = engine.inventory.getItemCount(itemId);
          final item = Items.findById(itemId);
          final met = currentQty >= qty;
          if (!met) hasMaterials = false;

          costChips.add(_buildCostChip(item?.icon ?? '📦', item?.name ?? itemId, currentQty, qty, met));
        });
      }

      final primarySkill = engine.skills[station.primarySkill];
      final levelMet = nextTier == null || (primarySkill != null && primarySkill.level >= nextTier.requiredSkillLevel);
      final energyMet = nextTier == null || engine.playerStats.currentEnergy >= nextTier.upgradeEnergyCost;
      final canUpgrade = nextTier != null && levelMet && hasMaterials && energyMet && activeAction == null;

      return GameCard(
        elevation: 2,
        accentColor: isCurrentlyUpgrading ? DSColors.accent : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                GameAvatar(emoji: station.icon, size: GameAvatarSize.md),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${station.name} (Tier ${inst.tier})',
                        style: DSText.headingSmall(context).copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isMaxed
                            ? 'Fully upgraded and operational!'
                            : 'Upgrading unlocks quality bonuses, faster crafting, and parallel slots.',
                        style: DSText.bodySmall(context),
                      ),
                    ],
                  ),
                ),
                if (isMaxed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: DSColors.accent.withOpacity(0.15),
                      border: Border.all(color: DSColors.accent),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('MAX TIER', style: TextStyle(color: DSColors.accent, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (!isMaxed && nextTier != null) ...[
              Row(
                children: [
                  Icon(Icons.psychology, size: 12, color: levelMet ? DSColors.textMuted : DSColors.error),
                  const SizedBox(width: 4),
                  Text(
                    'Req: Lvl ${nextTier.requiredSkillLevel} ${station.primarySkill.name}',
                    style: DSText.bodySmall(context).copyWith(color: levelMet ? DSColors.textMuted : DSColors.error),
                  ),
                  const Spacer(),
                  Text(
                    '⚡: ${nextTier.upgradeEnergyCost} | ⏱️: ${nextTier.upgradeDurationSeconds}s',
                    style: DSText.bodySmall(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 4, children: costChips),
              const SizedBox(height: 10),
              if (isCurrentlyUpgrading)
                Row(
                  children: [
                    Expanded(
                      child: GameProgressBar(
                        progress: activeAction!.progress,
                        color: DSColors.accent,
                        height: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GameButton(
                      variant: GameButtonVariant.danger,
                      label: 'Cancel',
                      size: GameButtonSize.sm,
                      onPressed: () => engine.cancelAction(),
                    ),
                  ],
                )
              else
                GameButton(
                  variant: canUpgrade ? GameButtonVariant.primary : GameButtonVariant.ghost,
                  label: !levelMet
                      ? 'Requires Lvl ${nextTier.requiredSkillLevel} ${station.primarySkill.name}'
                      : !hasMaterials
                          ? 'Missing Materials'
                          : !energyMet
                              ? 'Not Enough Energy'
                              : activeAction != null
                                  ? 'Busy'
                                  : 'Upgrade to Tier $nextTierVal',
                  onPressed: canUpgrade ? () => engine.startUpgradingStation(station.id) : null,
                ),
            ],
          ],
        ),
      );
    }
  }

  // Cost chip helper
  Widget _buildCostChip(String icon, String name, int current, int required, bool met) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: DSColors.surface0,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: met ? DSColors.borderSubtle : DSColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text('$name: ', style: DSText.bodySmall(context)),
          Text(
            '$current/$required',
            style: DSText.numeric(context).copyWith(
              color: met ? DSColors.textPrimary : DSColors.error,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // Convert number to Roman numerals helper
  String _getRomanNumeral(int tier) {
    if (tier == 1) return 'I';
    if (tier == 2) return 'II';
    if (tier == 3) return 'III';
    return '$tier';
  }

  void _showModifierWarningDialog(
    BuildContext context,
    String modifierName,
    String requiredType,
    String actualName,
    VoidCallback onConfirm,
    VoidCallback onCancel,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: DSColors.surface2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: DSColors.borderDefault, width: 1.5),
          ),
          title: Row(
            children: const [
              Text('⚠️ ', style: TextStyle(fontSize: 20)),
              Text(
                'Modifier Mismatch',
                style: TextStyle(color: DSColors.accent, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'The $modifierName modifier is designed for $requiredType, but you are crafting $actualName. The modifier\'s special effect will not apply to this craft.\n\nDo you want to use it anyway?',
            style: DSText.bodyMedium(context).copyWith(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onCancel();
              },
              child: Text('Cancel', style: DSText.button(context).copyWith(color: DSColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DSColors.accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text('Use Anyway', style: DSText.button(context).copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

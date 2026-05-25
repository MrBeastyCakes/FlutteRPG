import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/game_engine.dart';
import '../models/skill.dart';
import '../models/structure.dart';
import '../models/item.dart';
import '../models/recipe.dart';
import '../models/crafted_item.dart';
import '../theme/game_theme.dart';
import '../widgets/custom_progress_bar.dart';

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
      color: GameTheme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Workshop Dashboard Indicator
          _buildZoneHeader(context, currentZone, builtOperationalStations),

          // Sub-Tab Switcher
          _buildSubTabSwitcher(),

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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: GameTheme.cardBg,
        border: const Border(bottom: BorderSide(color: GameTheme.border, width: 1.0)),
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
                    const Icon(Icons.location_on, color: GameTheme.accentGold, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      currentZone.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Explore zones to build specialist facilities.',
                  style: TextStyle(color: GameTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          // Stations list row
          if (builtOperationalStations.isEmpty)
            const Text(
              'No active stations',
              style: TextStyle(color: GameTheme.textMuted, fontSize: 10, fontStyle: FontStyle.italic),
            )
          else
            Row(
              children: builtOperationalStations.map((inst) {
                final station = Stations.findById(inst.stationId);
                if (station == null) return const SizedBox.shrink();

                // Determine color based on activity
                Color statusColor = Colors.greenAccent;
                if (inst.restoration != null) {
                  statusColor = GameTheme.healthRed; // Ruined / Restoring
                } else if (inst.tierUpgrade != null) {
                  statusColor = Colors.blueAccent; // Upgrading
                } else if (inst.currentCraft != null) {
                  statusColor = GameTheme.energyYellow; // Crafting active
                }

                String romanTier = _getRomanNumeral(inst.tier);

                return Tooltip(
                  message: '${station.name} Tier $romanTier',
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: GameTheme.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(station.icon, style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 2),
                        Text(
                          romanTier,
                          style: TextStyle(
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

  // Sub-Tab switcher
  Widget _buildSubTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            child: _buildSubTabButton('CRAFT RECIPES', 0, Icons.handyman),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSubTabButton('BUILD STATIONS', 1, Icons.domain),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(String text, int index, IconData icon) {
    final active = _activeSubTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _activeSubTab = index;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          color: active ? GameTheme.craftingCyan.withOpacity(0.12) : GameTheme.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? GameTheme.craftingCyan : GameTheme.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? GameTheme.craftingCyan : GameTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: active ? Colors.white : GameTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.handyman, size: 64, color: GameTheme.textMuted),
            const SizedBox(height: 16),
            const Text(
              'No Operational Stations Here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              currentZone.id == 'town_square'
                  ? 'The Town Square stations are ruined. You must restore them in the BUILD STATIONS sub-tab first.'
                  : 'You have not built any crafting or production facilities in ${currentZone.name} yet. Travel to the BUILD STATIONS tab to create one.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: GameTheme.textMuted, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GameTheme.craftingCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                setState(() {
                  _activeSubTab = 1; // Swap to build tab
                });
              },
              child: const Text('Go Build & Restore', style: TextStyle(fontWeight: FontWeight.bold)),
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
        if (_selectedCategory == 'Food/Potions' && r.resultItem?.type != ItemType.food) return false;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Station selection row
        _buildStationSelectorRow(builtOperationalStations),

        // Info details of the station
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${selectedStation.name} Lvl ${selectedInstance.tier}',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                'Quality Bias: +${(activeStationQualityBias * 100).toInt()}% | Slots: ${selectedStation.getTier(selectedInstance.tier).queueSlots}',
                style: const TextStyle(color: GameTheme.craftingCyan, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Search & Filters Panel
        _buildSearchAndFiltersPanel(categories),

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
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black.withOpacity(0.12) : const Color(0xFF2C3E50),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getRomanNumeral(inst.tier),
                      style: TextStyle(
                        color: isSelected ? Colors.black : GameTheme.craftingCyan,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              selectedColor: GameTheme.craftingCyan,
              backgroundColor: GameTheme.cardBg,
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

  // Search, category chips, showLocked toggle, craftableOnly toggle
  Widget _buildSearchAndFiltersPanel(List<String> categories) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Search box + Toggle row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: GameTheme.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GameTheme.border),
                  ),
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        _recipeSearchQuery = val;
                      });
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Search recipes...',
                      hintStyle: TextStyle(color: GameTheme.textMuted, fontSize: 12),
                      prefixIcon: Icon(Icons.search, color: GameTheme.textMuted, size: 16),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Locked toggle
              _buildFilterIconButton(
                icon: _showLocked ? Icons.visibility : Icons.visibility_off,
                active: _showLocked,
                tooltip: 'Show Locked Recipes',
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
                tooltip: 'Show Craftable Only',
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
                          color: isSelected ? GameTheme.craftingCyan.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? GameTheme.craftingCyan : GameTheme.border,
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : GameTheme.textMuted,
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

  Widget _buildFilterIconButton({required IconData icon, required bool active, required String tooltip, required VoidCallback onPressed}) {
    return Material(
      color: active ? GameTheme.craftingCyan.withOpacity(0.12) : GameTheme.cardBg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? GameTheme.craftingCyan : GameTheme.border),
          ),
          child: Icon(
            icon,
            size: 16,
            color: active ? GameTheme.craftingCyan : GameTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRecipesPlaceholder() {
    final isSaltPress = _selectedStationId == 'salt_press';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          isSaltPress
              ? 'No recipes available yet. (Future content)'
              : 'No recipes match the active filters.\nTry enabling "Show Locked" or clearing search query.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: GameTheme.textMuted, fontSize: 12, height: 1.4),
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.82,
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
                    color: isSelected ? GameTheme.craftingCyan : GameTheme.border,
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

    // Rarity colors
    Color rarityBorder = GameTheme.border.withOpacity(0.6);
    Color glowColor = Colors.transparent;
    if (recipe.rarity == RecipeRarity.rare) {
      rarityBorder = Colors.blueAccent.withOpacity(0.5);
      glowColor = Colors.blueAccent.withOpacity(0.04);
    } else if (recipe.rarity == RecipeRarity.legendary) {
      rarityBorder = GameTheme.accentGold.withOpacity(0.5);
      glowColor = GameTheme.accentGold.withOpacity(0.04);
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

    return Card(
      color: isUnlocked ? GameTheme.cardBg : GameTheme.cardBg.withOpacity(0.4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: rarityBorder, width: isUnlocked ? 1.2 : 0.8),
      ),
      child: InkWell(
        onTap: () {
          if (!isUnlocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🔒 Recipe Locked: Find the blueprint scroll for "${recipe.name}" to unlock.'),
                backgroundColor: GameTheme.healthRed,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          if (!levelMet) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Requires level ${recipe.requiredLevel} ${recipe.requiredSkill.name}.'),
                backgroundColor: GameTheme.healthRed,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          // Open Configuration Sheet
          _showRecipeConfigSheet(context, engine, recipe, inst);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: glowColor,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon and Name
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(resultItem.icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isUnlocked ? Colors.white : GameTheme.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Req level
              Row(
                children: [
                  Icon(
                    Icons.psychology,
                    size: 11,
                    color: levelMet ? GameTheme.textMuted : GameTheme.healthRed,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      '${recipe.requiredSkill.name.substring(0, min(5, recipe.requiredSkill.name.length))} Lvl ${recipe.requiredLevel}',
                      style: TextStyle(
                        color: levelMet ? GameTheme.textMuted : GameTheme.healthRed,
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
                      color: const Color(0xFF131A21),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: hasEnough ? GameTheme.border.withOpacity(0.3) : GameTheme.healthRed.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item?.icon ?? '📦', style: const TextStyle(fontSize: 9)),
                        const SizedBox(width: 1),
                        Text(
                          '${slot.quantity}',
                          style: TextStyle(
                            color: hasEnough ? Colors.white70 : GameTheme.healthRed,
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
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canQuickQueue ? GameTheme.craftingCyan : const Color(0xFF23303D),
                  foregroundColor: canQuickQueue ? Colors.black : GameTheme.textMuted,
                  minimumSize: const Size.fromHeight(24),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: canQuickQueue
                    ? () {
                        // Quick queue with default choices
                        engine.startCrafting(recipe);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Queued 1x ${recipe.name}!'),
                            backgroundColor: Colors.greenAccent,
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    : null,
                child: const Text('Quick Queue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: const BoxDecoration(
          color: Color(0xFF1E2833),
          border: Border(top: BorderSide(color: GameTheme.border, width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: GameTheme.craftingCyan, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activeCraft != null
                        ? 'Crafting: ${recipe?.name ?? ""} (${(activeCraft.progress * 100).toInt()}%)'
                        : 'Idle (Wait for energy)',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                if (totalQueued > 0)
                  Text(
                    '+ $totalQueued queued',
                    style: const TextStyle(color: GameTheme.accentGold, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_up, color: GameTheme.textMuted, size: 16),
              ],
            ),
            if (activeCraft != null) ...[
              const SizedBox(height: 6),
              CustomProgressBar(
                progress: activeCraft.progress,
                color: GameTheme.craftingCyan,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: GameTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: GameTheme.border, width: 1.5),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Listen to game engine ticks to update progress in modal!
            return ListenableBuilder(
              listenable: engine,
              builder: (context, _) {
                final activeCraft = inst.currentCraft;
                final queueList = inst.queue;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.hourglass_bottom, color: GameTheme.craftingCyan),
                              const SizedBox(width: 8),
                              Text(
                                '${Stations.findById(inst.stationId)?.name ?? ""} Queue',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: GameTheme.textMuted),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(color: GameTheme.border),
                      const SizedBox(height: 8),
                      // Head: Current Craft
                      if (activeCraft != null) ...[
                        const Text(
                          'IN PROGRESS',
                          style: TextStyle(color: GameTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: GameTheme.cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: GameTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Text(activeCraft.recipe?.resultItem?.icon ?? '📦', style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      activeCraft.recipe?.name ?? '',
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Text(
                                    '${(activeCraft.progress * 100).toInt()}%',
                                    style: const TextStyle(color: GameTheme.craftingCyan, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              CustomProgressBar(
                                progress: activeCraft.progress,
                                color: GameTheme.craftingCyan,
                                height: 8,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Remaining time: ${(activeCraft.durationSeconds * (1.0 - activeCraft.progress)).toStringAsFixed(1)}s',
                                    style: const TextStyle(color: GameTheme.textMuted, fontSize: 10),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: GameTheme.healthRed,
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(60, 20),
                                    ),
                                    onPressed: () {
                                      // Cancel the queue index 0
                                      engine.cancelStationQueueEntry("${inst.zoneId}::${inst.stationId}", 0);
                                      if (inst.queue.isEmpty && inst.currentCraft == null) {
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: const Text('Cancel & Refund', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
                            color: GameTheme.cardBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              _selectedStationId == 'salt_press'
                                  ? 'Idle — no recipes to queue.'
                                  : 'Station is currently idle.',
                              style: const TextStyle(color: GameTheme.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Queue entries list
                      const Text(
                        'QUEUE LINE',
                        style: TextStyle(color: GameTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: queueList.length <= 1
                            ? const Center(
                                child: Text(
                                  'No other items in queue.',
                                  style: TextStyle(color: GameTheme.textMuted, fontSize: 11),
                                ),
                              )
                            : ListView.builder(
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
                                      color: GameTheme.cardBg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: GameTheme.border.withOpacity(0.5)),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(recipe.resultItem?.icon ?? '📦', style: const TextStyle(fontSize: 18)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                recipe.name,
                                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Count: ${entry.count} iterations',
                                                style: const TextStyle(color: GameTheme.textMuted, fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: GameTheme.healthRed, size: 18),
                                          onPressed: () {
                                            engine.cancelStationQueueEntry("${inst.zoneId}::${inst.stationId}", queueIdx);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
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
      },
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
      backgroundColor: GameTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: GameTheme.border, width: 1.5),
      ),
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

            return Padding(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Text(resultItem.icon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Configure: ${recipe.name}',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: GameTheme.textMuted),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: GameTheme.border),
                    const SizedBox(height: 8),

                    // Slots inputs
                    const Text(
                      'REQUIRED INGREDIENTS',
                      style: TextStyle(color: GameTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
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
                            color: GameTheme.cardBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: GameTheme.border),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Slot ${slotIdx + 1} (${slot.quantity}x): ',
                                style: const TextStyle(color: GameTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButton<String>(
                                  value: chosenItemId,
                                  isExpanded: true,
                                  dropdownColor: GameTheme.cardBg,
                                  underline: const SizedBox.shrink(),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
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
                                                color: enough ? Colors.white : GameTheme.healthRed,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '$invQty/$reqQty',
                                            style: TextStyle(
                                              color: enough ? GameTheme.textMuted : GameTheme.healthRed,
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
                    const Text(
                      'ACTIVE MODIFIER (OPTIONAL)',
                      style: TextStyle(color: GameTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: GameTheme.cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: GameTheme.border),
                      ),
                      child: DropdownButton<String?>(
                        value: selectedModifierItemId,
                        isExpanded: true,
                        dropdownColor: GameTheme.cardBg,
                        underline: const SizedBox.shrink(),
                        hint: const Text('Select a modifier item (none)', style: TextStyle(color: GameTheme.textMuted, fontSize: 12)),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        onChanged: (newVal) {
                          setModalState(() {
                            selectedModifierItemId = newVal;
                          });
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
                                    style: const TextStyle(color: GameTheme.textMuted, fontSize: 10),
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
                        const Text(
                          'CRAFT QUANTITY',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: GameTheme.craftingCyan),
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
                                color: GameTheme.cardBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: GameTheme.border),
                              ),
                              child: Text(
                                '$craftCount',
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: GameTheme.craftingCyan),
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

                    // Queue Craft Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameTheme.craftingCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚠️ Missing required materials for selected quantity!'),
                              backgroundColor: GameTheme.healthRed,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
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
                      child: Text(
                        'Queue $craftCount x ${recipe.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
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
                          'Building from scratch is prohibited here. Only the pre-existing ruined Crafting Bench and Field Kitchen can be restored.',
                          style: TextStyle(color: GameTheme.textLight, fontSize: 11, height: 1.3),
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
                        activeAction.isRestoration
                            ? 'Restoring ${activeAction.station!.name}...'
                            : activeAction.isUpgrade
                                ? 'Upgrading ${activeAction.station!.name}...'
                                : 'Building ${activeAction.station!.name}...',
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
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Remaining time: ${(activeAction.durationSeconds * (1.0 - activeAction.progress)).toStringAsFixed(1)}s',
                        style: const TextStyle(color: GameTheme.textMuted, fontSize: 10),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: GameTheme.healthRed,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(60, 24),
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
          ] else if (activeAction != null && activeAction.structure != null) ...[
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
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Remaining: ${(activeAction.durationSeconds * (1.0 - activeAction.progress)).toStringAsFixed(1)}s',
                        style: const TextStyle(color: GameTheme.textMuted, fontSize: 10),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: GameTheme.healthRed,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(60, 24),
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

      return Card(
        color: GameTheme.cardBg,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isCurrentlyRestoring ? GameTheme.healthRed : GameTheme.healthRed.withOpacity(0.3),
            width: isCurrentlyRestoring ? 1.5 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(station.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ruined ${station.name}',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'This town square facility is ruined. Restore it to operational state to unlock crafting recipes.',
                          style: TextStyle(color: GameTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Icon(Icons.psychology, size: 12, color: GameTheme.textMuted),
                  SizedBox(width: 4),
                  Text('Req: Level 1 in primary skill', style: TextStyle(color: GameTheme.textMuted, fontSize: 10)),
                  Spacer(),
                  Text('⚡: 5 | ⏱️: 10s', style: TextStyle(color: GameTheme.textMuted, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 4, children: costChips),
              const SizedBox(height: 10),
              if (isCurrentlyRestoring)
                Row(
                  children: [
                    Expanded(
                      child: CustomProgressBar(
                        progress: activeAction!.progress,
                        color: GameTheme.healthRed,
                        height: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameTheme.healthRed,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: () => engine.cancelAction(),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canRestore ? GameTheme.healthRed : const Color(0xFF222C37),
                    foregroundColor: canRestore ? Colors.white : GameTheme.textMuted,
                  ),
                  onPressed: canRestore ? () => engine.startRestoringStation(station.id) : null,
                  child: Text(
                    !hasMaterials
                        ? 'Missing Materials'
                        : !energyMet
                            ? 'Not Enough Energy'
                            : activeAction != null
                                ? 'Busy'
                                : 'Restore Station',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
            ],
          ),
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

      return Card(
        color: GameTheme.cardBg,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isCurrentlyUpgrading ? GameTheme.craftingCyan : GameTheme.border.withOpacity(0.5),
            width: isCurrentlyUpgrading ? 1.5 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(station.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${station.name} (Tier ${inst.tier})',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isMaxed
                              ? 'Fully upgraded and operational!'
                              : 'Upgrading unlocks quality bonuses, faster crafting, and parallel slots.',
                          style: const TextStyle(color: GameTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (isMaxed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: GameTheme.accentGold.withOpacity(0.15),
                        border: Border.all(color: GameTheme.accentGold),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('MAX TIER', style: TextStyle(color: GameTheme.accentGold, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (!isMaxed && nextTier != null) ...[
                Row(
                  children: [
                    Icon(Icons.psychology, size: 12, color: levelMet ? GameTheme.textMuted : GameTheme.healthRed),
                    const SizedBox(width: 4),
                    Text(
                      'Req: Lvl ${nextTier.requiredSkillLevel} ${station.primarySkill.name}',
                      style: TextStyle(color: levelMet ? GameTheme.textMuted : GameTheme.healthRed, fontSize: 10),
                    ),
                    const Spacer(),
                    Text(
                      '⚡: ${nextTier.upgradeEnergyCost} | ⏱️: ${nextTier.upgradeDurationSeconds}s',
                      style: const TextStyle(color: GameTheme.textMuted, fontSize: 10),
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
                        child: CustomProgressBar(
                          progress: activeAction!.progress,
                          color: GameTheme.craftingCyan,
                          height: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GameTheme.healthRed,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        onPressed: () => engine.cancelAction(),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canUpgrade ? GameTheme.craftingCyan : const Color(0xFF222C37),
                      foregroundColor: canUpgrade ? Colors.black : GameTheme.textMuted,
                    ),
                    onPressed: canUpgrade ? () => engine.startUpgradingStation(station.id) : null,
                    child: Text(
                      !levelMet
                          ? 'Requires Lvl ${nextTier.requiredSkillLevel} ${station.primarySkill.name}'
                          : !hasMaterials
                              ? 'Missing Materials'
                              : !energyMet
                                  ? 'Not Enough Energy'
                                  : activeAction != null
                                      ? 'Busy'
                                      : 'Upgrade to Tier $nextTierVal',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
              ],
            ],
          ),
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

      return Card(
        color: GameTheme.cardBg,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isCurrentlyBuilding ? GameTheme.craftingCyan : GameTheme.border.withOpacity(0.5),
            width: isCurrentlyBuilding ? 1.5 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(struct.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Build ${struct.name}',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          struct.description,
                          style: const TextStyle(color: GameTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.psychology, size: 12, color: levelMet ? GameTheme.textMuted : GameTheme.healthRed),
                  const SizedBox(width: 4),
                  Text(
                    'Req: Level ${struct.requiredLevel} ${struct.requiredSkill.name}',
                    style: TextStyle(color: levelMet ? GameTheme.textMuted : GameTheme.healthRed, fontSize: 10),
                  ),
                  const Spacer(),
                  Text(
                    '⚡: ${struct.energyCost} | ⏱️: ${struct.durationSeconds}s | XP: +${struct.xpReward.toInt()}',
                    style: const TextStyle(color: GameTheme.textMuted, fontSize: 10),
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
                      child: CustomProgressBar(
                        progress: activeAction!.progress,
                        color: GameTheme.craftingCyan,
                        height: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameTheme.healthRed,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: () => engine.cancelAction(),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canBuild ? GameTheme.craftingCyan : const Color(0xFF222C37),
                    foregroundColor: canBuild ? Colors.black : GameTheme.textMuted,
                  ),
                  onPressed: canBuild ? () => engine.startBuilding(struct, currentZone.id) : null,
                  child: Text(
                    !levelMet
                        ? 'Requires Lvl ${struct.requiredLevel} ${struct.requiredSkill.name}'
                        : !hasMaterials
                            ? 'Missing Materials'
                            : !energyMet
                                ? 'Not Enough Energy'
                                : activeAction != null
                                    ? 'Busy'
                                    : 'Build Station',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
            ],
          ),
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

      return Card(
        color: GameTheme.cardBg,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isCurrentlyUpgrading ? GameTheme.craftingCyan : GameTheme.border.withOpacity(0.5),
            width: isCurrentlyUpgrading ? 1.5 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(station.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${station.name} (Tier ${inst.tier})',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isMaxed
                              ? 'Fully upgraded and operational!'
                              : 'Upgrading unlocks quality bonuses, faster crafting, and parallel slots.',
                          style: const TextStyle(color: GameTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (isMaxed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: GameTheme.accentGold.withOpacity(0.15),
                        border: Border.all(color: GameTheme.accentGold),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('MAX TIER', style: TextStyle(color: GameTheme.accentGold, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (!isMaxed && nextTier != null) ...[
                Row(
                  children: [
                    Icon(Icons.psychology, size: 12, color: levelMet ? GameTheme.textMuted : GameTheme.healthRed),
                    const SizedBox(width: 4),
                    Text(
                      'Req: Lvl ${nextTier.requiredSkillLevel} ${station.primarySkill.name}',
                      style: TextStyle(color: levelMet ? GameTheme.textMuted : GameTheme.healthRed, fontSize: 10),
                    ),
                    const Spacer(),
                    Text(
                      '⚡: ${nextTier.upgradeEnergyCost} | ⏱️: ${nextTier.upgradeDurationSeconds}s',
                      style: const TextStyle(color: GameTheme.textMuted, fontSize: 10),
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
                        child: CustomProgressBar(
                          progress: activeAction!.progress,
                          color: GameTheme.craftingCyan,
                          height: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GameTheme.healthRed,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        onPressed: () => engine.cancelAction(),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canUpgrade ? GameTheme.craftingCyan : const Color(0xFF222C37),
                      foregroundColor: canUpgrade ? Colors.black : GameTheme.textMuted,
                    ),
                    onPressed: canUpgrade ? () => engine.startUpgradingStation(station.id) : null,
                    child: Text(
                      !levelMet
                          ? 'Requires Lvl ${nextTier.requiredSkillLevel} ${station.primarySkill.name}'
                          : !hasMaterials
                              ? 'Missing Materials'
                              : !energyMet
                                  ? 'Not Enough Energy'
                                  : activeAction != null
                                      ? 'Busy'
                                      : 'Upgrade to Tier $nextTierVal',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
              ],
            ],
          ),
        ),
      );
    }
  }

  // Cost chip helper
  Widget _buildCostChip(String icon, String name, int current, int required, bool met) {
    return Container(
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
          Text('$name: ', style: const TextStyle(color: GameTheme.textMuted, fontSize: 10)),
          Text(
            '$current/$required',
            style: TextStyle(
              color: met ? Colors.white : GameTheme.healthRed,
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
}

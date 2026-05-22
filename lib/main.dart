import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'engine/game_engine.dart';
import 'theme/game_theme.dart';
import 'views/dashboard_view.dart';
import 'views/skills_view.dart';
import 'views/inventory_view.dart';
import 'views/zones_view.dart';
import 'views/lore_view.dart';
import 'models/item.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameEngine(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elaria RPG',
      debugShowCheckedModeBanner: false,
      theme: GameTheme.themeData,
      home: const MainGameShell(),
    );
  }
}

class MainGameShell extends StatefulWidget {
  const MainGameShell({super.key});

  @override
  State<MainGameShell> createState() => _MainGameShellState();
}

class _MainGameShellState extends State<MainGameShell> {
  int _currentIndex = 0;

  final List<Widget> _views = const [
    DashboardView(),
    SkillsView(),
    InventoryView(),
    ZonesView(),
    LoreView(),
  ];

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<GameEngine>(context);
    final activeMasterwork = engine.activeMasterwork;

    // Build the app body. Swap to Masterwork Scenario Screen if active.
    Widget appBody;
    if (activeMasterwork != null) {
      appBody = _buildMasterworkScenarioView(engine, activeMasterwork);
    } else {
      appBody = _views[_currentIndex];
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.castle, color: GameTheme.accentGold, size: 22),
            const SizedBox(width: 8),
            Text(
              'ELARIA RPG',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontFamily: GameTheme.themeData.textTheme.titleLarge?.fontFamily,
              ),
            ),
          ],
        ),
        backgroundColor: GameTheme.background,
        elevation: 0,
        actions: [
          // Display current zone name in Appbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2833),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: GameTheme.border, width: 0.5),
                ),
                child: Text(
                  engine.currentZone.name,
                  style: const TextStyle(
                    color: GameTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(child: appBody),
      bottomNavigationBar: activeMasterwork != null
          ? null // Hide navigation bar during a trial to focus user attention
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.psychology),
                  label: 'Skills',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.backpack),
                  label: 'Inventory',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map),
                  label: 'Travel',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book),
                  label: 'Lore',
                ),
              ],
            ),
    );
  }

  Widget _buildMasterworkScenarioView(GameEngine engine, MasterworkRunState runState) {
    final step = runState.currentStep;
    final task = runState.task;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. TRIAL LOGO & TITLE
            Container(
              decoration: GameTheme.glassCardDecoration(
                customBg: GameTheme.healthRed.withOpacity(0.08),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: GameTheme.healthRed,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${task.skillType.name} Limit Break Challenge (Lvl ${task.levelGate})',
                    style: const TextStyle(
                      color: GameTheme.healthRed,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. SCENARIO PROMPT
            Container(
              decoration: GameTheme.glassCardDecoration(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SITUATION:',
                    style: TextStyle(
                      color: GameTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.prompt,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. OPTIONS HEADER
            const Padding(
              padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
              child: Text(
                'YOUR ACTIONS:',
                style: TextStyle(
                  color: GameTheme.accentGold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),

            // 4. ACTION OPTIONS
            ...step.options.map((option) {
              // Check option requirements
              final hasSkill = option.requiredSkill == null ||
                  (engine.skills[option.requiredSkill!]?.level ?? 0) >= option.requiredLevel;
              final hasItems = option.requiredItemId == null ||
                  engine.inventory.hasItem(option.requiredItemId!, option.requiredItemCount);
              final hasEnergy = engine.playerStats.currentEnergy >= option.energyCost;
              final hasGold = engine.playerStats.gold >= option.goldCost;

              final isLocked = !hasSkill || !hasItems || !hasEnergy || !hasGold;

              // Build description requirements text
              List<String> reqTexts = [];
              if (option.requiredSkill != null) {
                reqTexts.add('${option.requiredSkill!.name} Lvl ${option.requiredLevel}+');
              }
              if (option.requiredItemId != null) {
                final item = Items.findById(option.requiredItemId!);
                final itemName = item != null ? item.name : option.requiredItemId!;
                reqTexts.add('Needs $itemName x${option.requiredItemCount}');
              }
              if (option.energyCost > 0) {
                reqTexts.add('Costs ${option.energyCost} Energy');
              }
              if (option.goldCost > 0) {
                reqTexts.add('Costs ${option.goldCost} Gold');
              }

              return Card(
                color: isLocked ? const Color(0xFF161C23) : const Color(0xFF222C37),
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isLocked ? GameTheme.border.withOpacity(0.3) : GameTheme.border,
                    width: 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: isLocked
                      ? null
                      : () {
                          engine.chooseMasterworkOption(option);
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isLocked ? Icons.lock : Icons.play_arrow_rounded,
                              size: 16,
                              color: isLocked ? GameTheme.textMuted : GameTheme.accentGold,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                option.text,
                                style: TextStyle(
                                  color: isLocked ? GameTheme.textMuted : Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  decoration: isLocked ? TextDecoration.none : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (reqTexts.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: reqTexts.map((req) {
                              // Identify if this requirement is missing
                              bool missing = false;
                              if (req.contains('Lvl') && !hasSkill) missing = true;
                              if (req.contains('Needs') && !hasItems) missing = true;
                              if (req.contains('Energy') && !hasEnergy) missing = true;
                              if (req.contains('Gold') && !hasGold) missing = true;

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: missing
                                      ? GameTheme.healthRed.withOpacity(0.12)
                                      : const Color(0xFF16212D),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: missing ? GameTheme.healthRed : GameTheme.border,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  req,
                                  style: TextStyle(
                                    color: missing ? GameTheme.healthRed : GameTheme.textMuted,
                                    fontSize: 10,
                                    fontWeight: missing ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 16),

            // 5. ABANDON BUTTON
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: GameTheme.textMuted,
                side: const BorderSide(color: GameTheme.border, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                engine.cancelMasterwork();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Abandon Trial', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'engine/game_engine.dart';
import 'theme/game_theme.dart';
import 'views/dashboard_view.dart';
import 'views/skills_view.dart';
import 'views/inventory_view.dart';
import 'views/build_view.dart';
import 'models/item.dart';
import 'models/masterwork.dart';
import 'widgets/floating_notification.dart';
import 'widgets/narrative_event_modal.dart';

import 'views/codex_view.dart';
import 'views/tavern_view.dart';
import 'widgets/world_event_widgets.dart';

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
      home: const WorldEventListener(
        child: NarrativeEventListener(
          child: MainGameShell(),
        ),
      ),
      routes: {
        '/codex': (context) => const CodexView(),
        '/tavern': (context) => const TavernView(),
      },
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
    BuildView(),
  ];

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<GameEngine>(context);
    final activeMasterwork = engine.activeMasterwork;
    final int currentIndex = engine.activeTabIndex;

    // Build the app body. Swap to Masterwork Scenario Screen if active.
    Widget appBody;
    if (activeMasterwork != null) {
      appBody = _buildMasterworkScenarioView(engine, activeMasterwork);
    } else {
      appBody = AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(currentIndex),
          child: _views[currentIndex],
        ),
      );
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
          IconButton(
            icon: const Icon(Icons.restart_alt, color: GameTheme.textMuted, size: 20),
            tooltip: 'Reset Game',
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: GameTheme.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: GameTheme.border, width: 1.5),
                    ),
                    title: const Text('Reset Game?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    content: const Text(
                      'This will permanently delete all your progress, items, gold, and stats. Are you sure you want to start a new game?',
                      style: TextStyle(color: GameTheme.textLight, fontSize: 14),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: GameTheme.textMuted)),
                      ),
                      TextButton(
                        onPressed: () {
                          engine.resetGame();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🎮 Started a new game!'),
                              backgroundColor: GameTheme.accentGold,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text('Reset', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          // Display current zone name in Appbar
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 4.0),
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
      body: SafeArea(
        child: Stack(
          children: [
            appBody,
            FloatingNotificationOverlay(notifications: engine.notifications),
          ],
        ),
      ),
      bottomNavigationBar: activeMasterwork != null
          ? null // Hide navigation bar during a trial to focus user attention
          : BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) {
                engine.setActiveTabIndex(index);
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
                  icon: Icon(Icons.construction),
                  label: 'Workshop',
                ),
              ],
            ),
    );
  }

  Widget _buildMasterworkScenarioView(GameEngine engine, MasterworkRunState runState) {
    final step = runState.currentStep;
    final task = runState.task;

    return NarrativeEventModal(
      title: task.title.toUpperCase(),
      prompt: step.prompt,
      variant: NarrativeEventVariant.masterwork,
      onAbandon: () {
        engine.cancelMasterwork();
      },
      choices: [
        for (final option in step.options)
          _buildMasterworkChoice(engine, option),
      ],
    );
  }

  NarrativeEventChoice _buildMasterworkChoice(GameEngine engine, MasterworkOption option) {
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

    final preview = reqTexts.isEmpty ? null : reqTexts.join(', ');

    return NarrativeEventChoice(
      label: option.text,
      preview: preview,
      isLocked: isLocked,
      onTap: () {
        engine.chooseMasterworkOption(option);
      },
    );
  }
}

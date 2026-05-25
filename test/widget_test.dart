import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/main.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';
import 'package:flutter_text_based_rpg/models/codex.dart';
import 'package:flutter_text_based_rpg/views/codex_puzzle_view.dart';

void main() {
  testWidgets('Elaria RPG layout and tab switching smoke test', (WidgetTester tester) async {
    // Build our app under the provider and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GameEngine(),
        child: const MyApp(),
      ),
    );

    // Verify that the title 'ELARIA RPG' is present.
    expect(find.text('ELARIA RPG'), findsOneWidget);

    // Verify default view is the Dashboard (e.g. shows 'Town Square' location)
    expect(find.text('Town Square'), findsAtLeastNWidgets(1));

    // Tap on the 'Skills' tab in bottom navigation.
    await tester.tap(find.text('Skills'));
    await tester.pumpAndSettle();

    // Verify we are now on the Skills tab and it displays 'Woodcutting'.
    expect(find.text('Woodcutting'), findsOneWidget);
  });

  testWidgets('Elaria RPG Build tab shows warnings and updates on travel', (WidgetTester tester) async {
    final engine = GameEngine();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => engine,
        child: const MyApp(),
      ),
    );

    // Tap on the 'Workshop' tab in bottom navigation.
    await tester.tap(find.text('Workshop'));
    await tester.pumpAndSettle();

    // Verify build view is displayed
    expect(find.text('BUILD STATIONS'), findsOneWidget);

    // Switch to BUILD STATIONS subtab to see the warning banner
    await tester.tap(find.text('BUILD STATIONS'));
    await tester.pumpAndSettle();
    
    // Verify the warning banner for Town Square is shown
    expect(find.text('TOWN SQUARE RESTRICTION'), findsOneWidget);

    // Unlock and travel to Whispering Woods
    engine.unlockZone('whispering_woods_1');
    engine.travelTo(Zones.whisperingWoodsTier1);
    await tester.pumpAndSettle();

    // Verify the warning is gone and Whispering Woods is the current zone
    expect(find.text('TOWN SQUARE RESTRICTION'), findsNothing);
    expect(find.textContaining(RegExp('Whispering Woods \\(Tier 1\\)', caseSensitive: false)), findsAtLeastNWidgets(1));
  });

  testWidgets('Dashboard displays station status chip and handles navigation on tap', (WidgetTester tester) async {
    final engine = GameEngine();
    
    // Setup: Mark Town Square crafting bench as restored (operational)
    final benchKey = 'town_square::crafting_bench';
    final bench = engine.stationInstances[benchKey];
    if (bench != null) {
      bench.isRuined = false;
    }

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => engine,
        child: const MyApp(),
      ),
    );

    // Verify the station status chip for Crafting Bench T1 is displayed on the Dashboard
    expect(find.text('Crafting Bench'), findsOneWidget);
    expect(find.text('T1'), findsOneWidget);
    expect(find.text('Idle'), findsOneWidget);

    // Tap on the chip to focus the station and navigate to Workshop
    await tester.tap(find.text('Crafting Bench'));
    await tester.pump();

    // Verify engine state changes during build
    expect(engine.activeTabIndex, 3);
    expect(engine.focusedStationId, isNull);

    await tester.pumpAndSettle();

    // Verify the UI transitioned to Workshop view (e.g. shows subtab text)
    expect(find.text('CRAFT RECIPES'), findsOneWidget);
  });

  testWidgets('Codex Fragments Tab visibility, puzzle navigation, and reading display', (WidgetTester tester) async {
    final engine = GameEngine();
    engine.setEngineFlag('cartographers_tent');

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => engine,
        child: const MyApp(),
      ),
    );

    // Tap on the 'Open Codex' button on the Dashboard
    expect(find.text('Open Codex'), findsOneWidget);
    await tester.ensureVisible(find.text('Open Codex'));
    await tester.tap(find.text('Open Codex'));
    await tester.pumpAndSettle();

    // Verify Codex view is active
    expect(find.text('QUESTS'), findsOneWidget);
    expect(find.text('BEASTS'), findsOneWidget);
    expect(find.text('REGIONS'), findsOneWidget);
    
    // Fragments tab is not visible yet since knownCodexFragmentIds is empty
    expect(find.text('FRAGMENTS'), findsNothing);

    // Close Codex
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Artificially unlock 3 fragments from the Wilds tag
    engine.tryDropFragment(CodexTag.wilds, 1.0);
    engine.tryDropFragment(CodexTag.wilds, 1.0);
    engine.tryDropFragment(CodexTag.wilds, 1.0);
    await tester.pumpAndSettle();

    // Tap Open Codex again
    await tester.ensureVisible(find.text('Open Codex'));
    await tester.tap(find.text('Open Codex'));
    await tester.pumpAndSettle();

    // The Fragments tab should now appear
    expect(find.text('FRAGMENTS'), findsOneWidget);

    // Tap on the 'FRAGMENTS' tab
    await tester.tap(find.text('FRAGMENTS'));
    await tester.pumpAndSettle();

    // Check that the WILDS section is shown and has a count of 3/10
    expect(find.textContaining('WILDS'), findsOneWidget);
    expect(find.text('3/10'), findsOneWidget);

    // Tap on the WILDS expansion tile to expand it
    await tester.tap(find.textContaining('WILDS'));
    await tester.pumpAndSettle();

    // Verify that the "Solve Puzzle" button is shown (since count >= 3)
    expect(find.text('Solve Puzzle'), findsOneWidget);

    // Tap on "Solve Puzzle" to navigate to the CodexPuzzleView
    await tester.tap(find.text('Solve Puzzle'));
    await tester.pumpAndSettle();

    // Now we should be on the CodexPuzzleView page
    expect(find.textContaining('Order the Fragments'), findsOneWidget);
    expect(find.text('Lock Sequence'), findsOneWidget);

    // Verify list displays drag handles
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));

    // Tap "Lock Sequence". Since we only have 3 of 10, the button should be disabled (onPressed is null)
    final lockButton = tester.widget<ElevatedButton>(find.ancestor(
      of: find.text('Lock Sequence'),
      matching: find.byType(ElevatedButton),
    ));
    expect(lockButton.onPressed, isNull);

    // Now let's go back
    final puzzleFinder = find.byType(CodexPuzzleView);
    expect(puzzleFinder, findsOneWidget);
    Navigator.pop(tester.element(puzzleFinder));
    await tester.pumpAndSettle();

    // Verify we are back on Codex view
    expect(find.text('FRAGMENTS'), findsOneWidget);
  });
}

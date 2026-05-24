import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/main.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';

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
}

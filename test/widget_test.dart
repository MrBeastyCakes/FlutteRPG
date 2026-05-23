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

    // Tap on the 'Build' tab in bottom navigation.
    await tester.tap(find.text('Build'));
    await tester.pumpAndSettle();

    // Verify build view is displayed
    expect(find.text('CONSTRUCTION SITE'), findsOneWidget);
    
    // Verify the warning banner for Town Square is shown
    expect(find.text('TOWN SQUARE RESTRICTION'), findsOneWidget);

    // Unlock and travel to Whispering Woods
    engine.unlockZone('whispering_woods_1');
    engine.travelTo(Zones.whisperingWoodsTier1);
    await tester.pumpAndSettle();

    // Verify the warning is gone and Whispering Woods is the current zone
    expect(find.text('TOWN SQUARE RESTRICTION'), findsNothing);
    expect(find.text('Whispering Woods (Tier 1)'), findsNWidgets(2));
  });
}

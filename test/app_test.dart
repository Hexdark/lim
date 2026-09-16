import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_two/app.dart';
import 'package:we_two/controller.dart';

void main() {
  testWidgets(
    'Demo sends a mood and note, reader cannot compose, logout clears it',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = AppController(
        widgetUpdater: (_, {demo = false}) async {},
      );
      await tester.pumpWidget(FafelGuideApp(controller: controller));
      await tester.ensureVisible(find.text('Zobacz demo'));
      await tester.tap(find.text('Zobacz demo'));
      await tester.pumpAndSettle();
      expect(find.text('Jak się dzisiaj czujesz?'), findsOneWidget);
      expect(find.text('Fąfel Guide'), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(2));
      expect(find.text('Nasza przestrzeń'), findsNothing);
      expect(find.textContaining('Każdy dzień może być inny'), findsNothing);
      await tester.scrollUntilVisible(find.text('Daj znać, co u Ciebie'), 220);
      await tester.tap(find.text('Daj znać, co u Ciebie'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mood-2')));
      await tester.scrollUntilVisible(
        find.byType(TextField),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.byType(TextField),
        'Potrzebuję dziś przytulenia.',
      );
      await tester.scrollUntilVisible(
        find.text('Wyślij mały sygnał'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Wyślij mały sygnał'));
      await tester.pumpAndSettle();
      expect(controller.entries.first.mood, 2);
      expect(controller.entries.first.note, 'Potrzebuję dziś przytulenia.');
      expect(find.text('Potrzebuję dziś przytulenia.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zmień'));
      await tester.pumpAndSettle();
      expect(find.text('Daj znać, co u Ciebie'), findsNothing);
      expect(find.text('Małe wieści od niej.'), findsOneWidget);
      await tester.tap(find.byTooltip('Zamknij demo'));
      await tester.pumpAndSettle();
      expect(controller.entries, isEmpty);
      expect(find.text('Zobacz demo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Small phone layout is scrollable and does not overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppController(
      widgetUpdater: (_, {demo = false}) async {},
    );
    await controller.enterDemo();
    await tester.pumpWidget(FafelGuideApp(controller: controller));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Daj znać, co u Ciebie'), 220);
    await tester.tap(find.text('Daj znać, co u Ciebie'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

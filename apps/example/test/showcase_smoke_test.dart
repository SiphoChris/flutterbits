// Smoke tests for the showcase app: every category must build and render without
// throwing (overflows, layout asserts, null-token lookups, etc.), in both
// brightnesses and both text directions. This is the example app's safety net —
// it compiles + exercises every engine capability the showcase touches.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbits_example/showcase/common.dart';
import 'package:flutterbits_example/showcase/showcase_app.dart';

void main() {
  // A generous surface so wide demos (palette grid, layout grid) don't trip
  // horizontal-overflow errors that would mask real failures.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ShowcaseApp());
    await tester.pumpAndSettle();
  }

  testWidgets('every category renders without exceptions', (tester) async {
    await pumpApp(tester);
    expect(tester.takeException(), isNull);

    for (final category in ShowcaseCategory.values) {
      // The tab label appears first in the tree (header → tab bar → content),
      // so `.first` targets the tab, not a section heading of the same name.
      await tester.tap(find.text(category.label).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'category "${category.label}" threw');
    }
  });

  testWidgets('switching the semantic theme reskins every category cleanly', (tester) async {
    await pumpApp(tester);
    // Starts on the Default theme.
    expect(find.text('Theme: Default'), findsOneWidget);

    // Cycle to the Claude theme (the pasted tweakcn theme) and let it animate.
    await tester.tap(find.textContaining('Theme:'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Theme: Claude'), findsOneWidget);

    // Every category must render under the swapped theme — proves the 32 tokens
    // (incl. chart/sidebar), the 1rem radius, and the custom shadows all resolve.
    for (final category in ShowcaseCategory.values) {
      await tester.tap(find.text(category.label).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Claude theme "${category.label}" threw');
    }

    // And in Claude + dark.
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('dark + RTL toggles animate cleanly across every category', (tester) async {
    await pumpApp(tester);

    // Toggle to dark (the button label shows the current brightness).
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Dark'), findsOneWidget);

    // Toggle to RTL.
    await tester.tap(find.text('LTR'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('RTL'), findsOneWidget);

    // Re-render every category in dark + RTL.
    for (final category in ShowcaseCategory.values) {
      await tester.tap(find.text(category.label).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'dark+RTL "${category.label}" threw');
    }
  });
}

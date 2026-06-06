import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

Widget _wrap(Widget child) => Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  group('FwRow', () {
    testWidgets('builds a horizontal Flex with native spacing from gap units', (t) async {
      await t.pumpWidget(_wrap(const FwRow(gap: 2, children: [SizedBox(), SizedBox()])));
      final flex = t.widget<Flex>(find.byType(Flex));
      expect(flex.direction, Axis.horizontal);
      expect(flex.spacing, 8.0); // gap 2 × 4px
      expect(flex.children.length, 2);
    });

    testWidgets('defaults: gap 0, mainAxisSize.max', (t) async {
      await t.pumpWidget(_wrap(const FwRow(children: [SizedBox()])));
      final flex = t.widget<Flex>(find.byType(Flex));
      expect(flex.spacing, 0.0);
      expect(flex.mainAxisSize, MainAxisSize.max);
    });

    testWidgets('passes through alignment + mainAxisSize', (t) async {
      await t.pumpWidget(
        _wrap(
          const FwRow(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [SizedBox()],
          ),
        ),
      );
      final flex = t.widget<Flex>(find.byType(Flex));
      expect(flex.mainAxisAlignment, MainAxisAlignment.spaceBetween);
      expect(flex.crossAxisAlignment, CrossAxisAlignment.end);
      expect(flex.mainAxisSize, MainAxisSize.min);
    });
  });

  group('FwColumn', () {
    testWidgets('builds a vertical Flex with native spacing', (t) async {
      await t.pumpWidget(_wrap(const FwColumn(gap: 3, children: [SizedBox()])));
      final flex = t.widget<Flex>(find.byType(Flex));
      expect(flex.direction, Axis.vertical);
      expect(flex.spacing, 12.0); // gap 3 × 4px
    });
  });

  testWidgets('a flex widget can itself be styled with .tw', (t) async {
    await t.pumpWidget(_wrap(const FwRow(children: [SizedBox()]).tw.p(2)));
    expect(find.byType(FwStyled), findsOneWidget);
    expect(find.byType(FwRow), findsOneWidget);
  });

  test('negative gap asserts', () {
    expect(() => FwRow(gap: -1, children: const []), throwsAssertionError);
  });

  test('FwFlexPatch asserts non-negative gap', () {
    expect(() => FwFlexPatch(gap: -1), throwsAssertionError);
  });

  group('responsive', () {
    // The frame's viewport width drives which patches apply.
    Widget frameViewport(double width, Widget child) => MediaQuery(
      data: MediaQueryData(size: Size(width, 600)),
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    );

    testWidgets('static box has no MediaQuery/LayoutBuilder inserted', (t) async {
      await t.pumpWidget(_wrap(const FwRow(gap: 2, children: [SizedBox()])));
      // No LayoutBuilder for a non-container, non-responsive row.
      expect(find.byType(LayoutBuilder), findsNothing);
    });

    testWidgets('viewport patch overrides gap at/above the breakpoint', (t) async {
      const row = FwRow(
        gap: 2,
        viewport: {FwBreakpoint.md: FwFlexPatch(gap: 6)},
        children: [SizedBox(), SizedBox()],
      );
      // Below md (768): base gap 2 → 8px.
      await t.pumpWidget(frameViewport(500, row));
      expect(t.widget<Flex>(find.byType(Flex)).spacing, 8.0);
      // At/above md: patch gap 6 → 24px.
      await t.pumpWidget(frameViewport(800, row));
      expect(t.widget<Flex>(find.byType(Flex)).spacing, 24.0);
    });

    testWidgets('largest matching viewport breakpoint wins (mobile-first cascade)', (t) async {
      const row = FwRow(
        gap: 1,
        viewport: {FwBreakpoint.md: FwFlexPatch(gap: 4), FwBreakpoint.lg: FwFlexPatch(gap: 8)},
        children: [SizedBox()],
      );
      await t.pumpWidget(frameViewport(800, row)); // md only
      expect(t.widget<Flex>(find.byType(Flex)).spacing, 16.0);
      await t.pumpWidget(frameViewport(1100, row)); // md + lg → lg wins
      expect(t.widget<Flex>(find.byType(Flex)).spacing, 32.0);
    });

    testWidgets('container patch keys off the enclosing constraint, not the screen', (t) async {
      // Wide screen, but the row is boxed to 300px, so containerMd (768) must NOT
      // apply while a containerSm (640)… here we use sm vs the 300px box.
      const row = FwRow(
        gap: 1,
        container: {FwBreakpoint.sm: FwFlexPatch(gap: 5)},
        children: [SizedBox()],
      );
      // Center loosens the root's tight constraints so the SizedBox can take its
      // own width — otherwise the box is forced to the surface width.
      await t.pumpWidget(
        frameViewport(2000, const Center(child: SizedBox(width: 300, child: row))),
      );
      // 300px box < sm(640): base gap 1 → 4px (screen width is irrelevant here).
      expect(find.byType(LayoutBuilder), findsOneWidget);
      expect(t.widget<Flex>(find.byType(Flex)).spacing, 4.0);
      await t.pumpWidget(
        frameViewport(2000, const Center(child: SizedBox(width: 700, child: row))),
      );
      // 700px box >= sm(640): patch gap 5 → 20px.
      expect(t.widget<Flex>(find.byType(Flex)).spacing, 20.0);
    });

    testWidgets('patch can also override alignment + mainAxisSize', (t) async {
      const row = FwRow(
        viewport: {
          FwBreakpoint.md: FwFlexPatch(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
          ),
        },
        children: [SizedBox()],
      );
      await t.pumpWidget(frameViewport(800, row));
      final flex = t.widget<Flex>(find.byType(Flex));
      expect(flex.mainAxisAlignment, MainAxisAlignment.spaceBetween);
      expect(flex.mainAxisSize, MainAxisSize.min);
    });
  });
}

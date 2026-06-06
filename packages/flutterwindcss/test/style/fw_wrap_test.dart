import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

Widget _wrap(Widget child) => Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  testWidgets('FwWrap maps gap/runGap units to Wrap spacing/runSpacing', (t) async {
    await t.pumpWidget(_wrap(const FwWrap(gap: 2, runGap: 3, children: [SizedBox(), SizedBox()])));
    final w = t.widget<Wrap>(find.byType(Wrap));
    expect(w.spacing, 8.0); // gap 2 × 4
    expect(w.runSpacing, 12.0); // runGap 3 × 4
    expect(w.children.length, 2);
  });

  testWidgets('defaults: zero spacing, horizontal direction', (t) async {
    await t.pumpWidget(_wrap(const FwWrap(children: [SizedBox()])));
    final w = t.widget<Wrap>(find.byType(Wrap));
    expect(w.spacing, 0.0);
    expect(w.runSpacing, 0.0);
    expect(w.direction, Axis.horizontal);
  });

  testWidgets('passes through alignment', (t) async {
    await t.pumpWidget(
      _wrap(
        const FwWrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [SizedBox()],
        ),
      ),
    );
    final w = t.widget<Wrap>(find.byType(Wrap));
    expect(w.alignment, WrapAlignment.center);
    expect(w.runAlignment, WrapAlignment.spaceBetween);
    expect(w.crossAxisAlignment, WrapCrossAlignment.end);
  });

  test('negative gap / runGap assert', () {
    expect(() => FwWrap(gap: -1, children: const []), throwsAssertionError);
    expect(() => FwWrap(runGap: -1, children: const []), throwsAssertionError);
  });

  test('FwWrapPatch asserts non-negative gap / runGap', () {
    expect(() => FwWrapPatch(gap: -1), throwsAssertionError);
    expect(() => FwWrapPatch(runGap: -1), throwsAssertionError);
  });

  group('responsive', () {
    Widget frameViewport(double width, Widget child) => MediaQuery(
      data: MediaQueryData(size: Size(width, 600)),
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    );

    testWidgets('viewport patch overrides spacing + alignment at the breakpoint', (t) async {
      const wrap = FwWrap(
        gap: 1,
        runGap: 1,
        viewport: {
          FwBreakpoint.md: FwWrapPatch(gap: 3, runGap: 2, alignment: WrapAlignment.center),
        },
        children: [SizedBox()],
      );
      await t.pumpWidget(frameViewport(500, wrap)); // below md
      var w = t.widget<Wrap>(find.byType(Wrap));
      expect(w.spacing, 4.0);
      expect(w.runSpacing, 4.0);
      expect(w.alignment, WrapAlignment.start);
      await t.pumpWidget(frameViewport(800, wrap)); // at md
      w = t.widget<Wrap>(find.byType(Wrap));
      expect(w.spacing, 12.0);
      expect(w.runSpacing, 8.0);
      expect(w.alignment, WrapAlignment.center);
    });

    testWidgets('static wrap inserts no LayoutBuilder', (t) async {
      await t.pumpWidget(frameViewport(800, const FwWrap(children: [SizedBox()])));
      expect(find.byType(LayoutBuilder), findsNothing);
    });

    testWidgets('container patch keys off the enclosing constraint (LayoutBuilder)', (t) async {
      const wrap = FwWrap(
        gap: 1,
        container: {FwBreakpoint.sm: FwWrapPatch(gap: 5)},
        children: [SizedBox()],
      );
      await t.pumpWidget(
        frameViewport(2000, const Center(child: SizedBox(width: 300, child: wrap))),
      );
      expect(find.byType(LayoutBuilder), findsOneWidget);
      expect(t.widget<Wrap>(find.byType(Wrap)).spacing, 4.0); // 300 < sm(640) → base 1 → 4
      await t.pumpWidget(
        frameViewport(2000, const Center(child: SizedBox(width: 700, child: wrap))),
      );
      expect(t.widget<Wrap>(find.byType(Wrap)).spacing, 20.0); // 700 >= sm → 5 → 20
    });
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Executable RTL-mirroring assertions (AGENTS.md §3.3 directional-by-default).
// Until now RTL was only exercised by goldens, which are non-authoritative on a
// dev machine (CI Linux is the source of truth) — so directional correctness had
// no local pixel-level net. These tests pump real geometry and assert that
// start-anchored layout physically flips between LTR and RTL via tester.getRect.

const _box = Color(0xFF3366CC);

Widget _frame(TextDirection dir, Widget child) =>
    Directionality(textDirection: dir, child: Center(child: child));

Iterable<BoxDecoration> _decorations(WidgetTester t) =>
    t
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((DecoratedBox d) => d.decoration)
        .whereType<BoxDecoration>();

void main() {
  testWidgets('FwRow children physically reverse under RTL', (t) async {
    Widget row() => const FwRow(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 20, height: 20, key: Key('first')),
        SizedBox(width: 20, height: 20, key: Key('second')),
      ],
    );

    await t.pumpWidget(_frame(TextDirection.ltr, row()));
    expect(
      t.getCenter(find.byKey(const Key('first'))).dx,
      lessThan(t.getCenter(find.byKey(const Key('second'))).dx),
      reason: 'LTR: first child sits to the left of the second',
    );

    await t.pumpWidget(_frame(TextDirection.rtl, row()));
    expect(
      t.getCenter(find.byKey(const Key('first'))).dx,
      greaterThan(t.getCenter(find.byKey(const Key('second'))).dx),
      reason: 'RTL: first child sits to the right of the second',
    );
  });

  testWidgets('.ps() start-padding maps to the left in LTR and the right in RTL', (t) async {
    Widget padded() => const SizedBox(width: 10, height: 10, key: Key('child')).tw.ps(6).bg(_box);

    await t.pumpWidget(_frame(TextDirection.ltr, padded()));
    var box = t.getTopLeft(find.byType(FwStyled));
    var child = t.getTopLeft(find.byKey(const Key('child')));
    expect(child.dx - box.dx, 24.0, reason: 'LTR: 6-unit start padding (24px) on the left');

    await t.pumpWidget(_frame(TextDirection.rtl, padded()));
    box = t.getTopLeft(find.byType(FwStyled));
    child = t.getTopLeft(find.byKey(const Key('child')));
    expect(
      child.dx - box.dx,
      0.0,
      reason: 'RTL: start padding moves to the right, child flush left',
    );
  });

  testWidgets('FwPositioned start-inset anchors to the right edge under RTL', (t) async {
    Widget stack() => const SizedBox(
      width: 100,
      height: 100,
      child: FwStack(
        children: [
          FwPositioned(start: 4, top: 0, child: SizedBox(width: 10, height: 10, key: Key('p'))),
        ],
      ),
    );

    await t.pumpWidget(_frame(TextDirection.ltr, stack()));
    var stackBox = t.getTopLeft(find.byType(FwStack));
    var p = t.getTopLeft(find.byKey(const Key('p')));
    expect(p.dx - stackBox.dx, 16.0, reason: 'LTR: 4-unit start inset (16px) from the left edge');

    await t.pumpWidget(_frame(TextDirection.rtl, stack()));
    stackBox = t.getTopLeft(find.byType(FwStack));
    p = t.getTopLeft(find.byKey(const Key('p')));
    // RTL: 16px from the right edge → left = 100 - 10 - 16 = 74.
    expect(p.dx - stackBox.dx, 74.0, reason: 'RTL: start inset anchors to the right edge');
  });

  testWidgets('directional border (borderS) stays a logical BorderDirectional so it '
      'mirrors edges automatically (not a physical left/right Border)', (t) async {
    Widget box() => const SizedBox(width: 20, height: 20).tw.borderS(width: 4, color: _box);

    // BorderDirectional carries the side logically (`start`) and Flutter paints it
    // on the physical left (LTR) / right (RTL) at paint time — there is no public
    // resolve(), so the executable net is "it's a BorderDirectional with only the
    // start edge set", which is exactly what guarantees the §3.3 mirror. A physical
    // Border(left:/right:) here would be the bug.
    await t.pumpWidget(_frame(TextDirection.ltr, box()));
    final ltrBorder = _decorations(t).map((d) => d.border).whereType<BorderDirectional>().first;
    expect(ltrBorder.start.width, 4);
    expect(ltrBorder.start.color, _box);
    expect(ltrBorder.end, BorderSide.none);

    // Under RTL the divider must STILL be a BorderDirectional with start set — the
    // engine never branches to a physical edge per direction.
    await t.pumpWidget(_frame(TextDirection.rtl, box()));
    final rtlBorder = _decorations(t).map((d) => d.border).whereType<BorderDirectional>().first;
    expect(rtlBorder, isA<BorderDirectional>());
    expect(rtlBorder.start.width, 4);
    expect(rtlBorder.end, BorderSide.none);
  });

  testWidgets('directional radius (roundedS) resolves to the leading corners — left in '
      'LTR, right in RTL', (t) async {
    Widget box() => const SizedBox(width: 20, height: 20).tw.roundedS(8).bg(_box);

    await t.pumpWidget(_frame(TextDirection.ltr, box()));
    final radius =
        _decorations(t).map((d) => d.borderRadius).whereType<BorderRadiusDirectional>().first;
    // BorderRadiusDirectional IS resolvable — prove the physical corner mapping.
    final ltr = radius.resolve(TextDirection.ltr);
    expect(ltr.topLeft.x, 8, reason: 'LTR: start corners are the left corners');
    expect(ltr.topRight.x, 0);
    final rtl = radius.resolve(TextDirection.rtl);
    expect(rtl.topRight.x, 8, reason: 'RTL: start corners flip to the right');
    expect(rtl.topLeft.x, 0);
  });
}

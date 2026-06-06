import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Geometry-based tests for the real CSS-grid RenderObject (RenderFwGrid). The
// grid is laid out under a width-bounded, top-left-anchored box so child global
// rects equal grid-local coordinates; we assert on those rects (the grid no
// longer composes Row/Expanded/SizedBox, so structure assertions are gone — we
// verify actual layout instead).

Widget _box(String k, {double w = 20, double h = 20}) => SizedBox(key: Key(k), width: w, height: h);

Future<void> _pump(
  WidgetTester t,
  FwGrid grid, {
  double width = 100,
  TextDirection dir = TextDirection.ltr,
}) => t.pumpWidget(
  Directionality(
    textDirection: dir,
    child: Align(alignment: Alignment.topLeft, child: SizedBox(width: width, child: grid)),
  ),
);

Rect _rect(WidgetTester t, String k) => t.getRect(find.byKey(Key(k)));

void main() {
  group('track sizing (stretch fills the cell, so child rect == cell rect)', () {
    testWidgets('two fr columns split the width evenly', (t) async {
      await _pump(
        t,
        FwGrid(columns: const [FwFr(), FwFr()], children: [_box('a'), _box('b')]),
        width: 100,
      );
      expect(_rect(t, 'a').left, 0);
      expect(_rect(t, 'a').width, 50);
      expect(_rect(t, 'b').left, 50);
      expect(_rect(t, 'b').width, 50);
    });

    testWidgets('px track is fixed, fr takes the rest', (t) async {
      await _pump(
        t,
        FwGrid(columns: const [FwPx(30), FwFr()], children: [_box('a'), _box('b')]),
        width: 100,
      );
      expect(_rect(t, 'a').width, 30);
      expect(_rect(t, 'b').left, 30);
      expect(_rect(t, 'b').width, 70);
    });

    testWidgets('auto track sizes to its item content width', (t) async {
      await _pump(
        t,
        FwGrid(columns: const [FwAuto(), FwFr()], children: [_box('a', w: 40), _box('b')]),
        width: 200,
      );
      expect(_rect(t, 'a').width, 40); // content-sized
      expect(_rect(t, 'b').left, 40);
      expect(_rect(t, 'b').width, 160);
    });

    testWidgets('minmax(80, 1fr) floors the fr track at its minimum', (t) async {
      // Two minmax(80,1fr) tracks in a 100px grid: each fr share would be 50, but
      // the 80 floor pins both → they overflow to 80 each (CSS behavior).
      await _pump(
        t,
        FwGrid(
          columns: const [FwMinMax(80, FwFr()), FwMinMax(80, FwFr())],
          children: [_box('a'), _box('b')],
        ),
        width: 100,
      );
      expect(_rect(t, 'a').width, 80);
      expect(_rect(t, 'b').width, 80);
    });

    testWidgets('column gap offsets the tracks', (t) async {
      await _pump(
        t,
        FwGrid(columns: const [FwFr(), FwFr()], columnGap: 1, children: [_box('a'), _box('b')]),
        width: 100,
      );
      // gap 1u = 4px; free = 96; each fr = 48; b starts at 48 + 4 = 52.
      expect(_rect(t, 'a').width, 48);
      expect(_rect(t, 'b').left, 52);
    });
  });

  group('placement', () {
    testWidgets('items flow row-major into a new row when columns fill', (t) async {
      await _pump(
        t,
        FwGrid(
          columns: const [FwFr(), FwFr()],
          children: [_box('a'), _box('b'), _box('c')], // 3 → 2 rows
        ),
        width: 100,
      );
      expect(_rect(t, 'a').top, 0);
      expect(_rect(t, 'b').top, 0);
      expect(_rect(t, 'c').top, 20); // below row 0 (row height = 20)
      expect(_rect(t, 'c').left, 0); // first column of row 1
    });

    testWidgets('row gap offsets wrapped rows', (t) async {
      await _pump(
        t,
        FwGrid(
          columns: const [FwFr(), FwFr()],
          rowGap: 2, // 8px
          children: [_box('a'), _box('b'), _box('c')],
        ),
        width: 100,
      );
      expect(_rect(t, 'c').top, 28); // 20 + 8 gap
    });

    testWidgets('FwGridItem columnSpan covers multiple columns', (t) async {
      await _pump(
        t,
        FwGrid(
          columns: const [FwFr(), FwFr(), FwFr()],
          children: [
            const FwGridItem(columnSpan: 2, child: SizedBox(key: Key('a'), height: 20)),
            _box('b'),
          ],
        ),
        width: 90,
      );
      // 3 × 30px tracks; 'a' spans 2 → 60px at x0; 'b' at the 3rd track.
      expect(_rect(t, 'a').width, 60);
      expect(_rect(t, 'b').left, 60);
      expect(_rect(t, 'b').width, 30);
    });

    testWidgets('dense packing backfills a hole a span-2 item left behind', (t) async {
      // 3 cols. a(span2)→row0 c0-1; b(span2) doesn't fit row0's lone c2 → row1;
      // that leaves a hole at row0 c2. c(span1): sparse lands it at row1 c2;
      // dense backfills it into row0 c2.
      FwGrid grid({required bool dense}) => FwGrid(
        columns: const [FwFr(), FwFr(), FwFr()],
        dense: dense,
        children: [
          const FwGridItem(columnSpan: 2, child: SizedBox(key: Key('a'), height: 20)),
          const FwGridItem(columnSpan: 2, child: SizedBox(key: Key('b'), height: 20)),
          _box('c'),
        ],
      );

      await _pump(t, grid(dense: false), width: 90);
      expect(_rect(t, 'c').top, 20); // sparse: pushed to row 1
      expect(_rect(t, 'c').left, 60);

      await _pump(t, grid(dense: true), width: 90);
      expect(_rect(t, 'c').top, 0); // dense: backfilled into row 0's hole
      expect(_rect(t, 'c').left, 60);
    });

    testWidgets('FwGridItem explicit columnStart pins the column', (t) async {
      await _pump(
        t,
        FwGrid(
          columns: const [FwFr(), FwFr(), FwFr()],
          children: [
            const FwGridItem(
              columnStart: 3,
              child: SizedBox(key: Key('a'), height: 20),
            ), // 1-based → 3rd col
          ],
        ),
        width: 90,
      );
      expect(_rect(t, 'a').left, 60); // third 30px track
    });
  });

  group('alignment (non-stretch keeps the child its own size within the cell)', () {
    testWidgets('justifyItems start / center / end position a small child', (t) async {
      Future<void> pumpAlign(FwGridAlign a) => _pump(
        t,
        FwGrid(
          columns: const [FwFr()],
          justifyItems: a,
          alignItems: FwGridAlign.start,
          children: [_box('a', w: 20, h: 20)],
        ),
        width: 100,
      );

      await pumpAlign(FwGridAlign.start);
      expect(_rect(t, 'a').left, 0);
      await pumpAlign(FwGridAlign.center);
      expect(_rect(t, 'a').left, 40); // (100 - 20) / 2
      await pumpAlign(FwGridAlign.end);
      expect(_rect(t, 'a').left, 80); // 100 - 20
    });
  });

  group('RTL', () {
    testWidgets('column order mirrors: the first item sits on the right', (t) async {
      await _pump(
        t,
        FwGrid(columns: const [FwFr(), FwFr()], children: [_box('a'), _box('b')]),
        width: 100,
        dir: TextDirection.rtl,
      );
      expect(_rect(t, 'a').left, 50); // first column → right half under RTL
      expect(_rect(t, 'b').left, 0);
    });

    testWidgets('justify start anchors to the right under RTL', (t) async {
      await _pump(
        t,
        FwGrid(
          columns: const [FwFr()],
          justifyItems: FwGridAlign.start,
          alignItems: FwGridAlign.start,
          children: [_box('a', w: 20)],
        ),
        width: 100,
        dir: TextDirection.rtl,
      );
      expect(_rect(t, 'a').left, 80); // start = right edge in RTL
    });
  });

  group('responsive (geometry, not widget structure)', () {
    Widget frameViewport(double vw, Widget child) => MediaQuery(
      data: MediaQueryData(size: Size(vw, 600)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(alignment: Alignment.topLeft, child: SizedBox(width: 120, child: child)),
      ),
    );

    testWidgets('viewport patch changes the column count (1 → 3)', (t) async {
      final grid = FwGrid(
        columns: const [FwFr()],
        viewport: const {
          FwBreakpoint.md: FwGridPatch(columns: [FwFr(), FwFr(), FwFr()]),
        },
        children: [_box('a'), _box('b'), _box('c')],
      );
      // Narrow (< md): 1 column → all stacked (distinct rows).
      await t.pumpWidget(frameViewport(500, grid));
      expect(_rect(t, 'a').top, 0);
      expect(_rect(t, 'b').top, 20);
      expect(_rect(t, 'c').top, 40);
      // Wide (>= md): 3 columns → one row (same top, increasing left).
      await t.pumpWidget(frameViewport(800, grid));
      expect(_rect(t, 'a').top, 0);
      expect(_rect(t, 'b').top, 0);
      expect(_rect(t, 'c').top, 0);
      expect(_rect(t, 'a').left, lessThan(_rect(t, 'b').left));
    });
  });

  group('guards', () {
    test('empty columns asserts', () {
      expect(() => FwGrid(columns: const [], children: const []), throwsAssertionError);
    });

    test('track guards: FwFr > 0, FwPx >= 0, FwMinMax min >= 0 + no nested minmax', () {
      expect(() => FwFr(0), throwsAssertionError);
      expect(() => FwPx(-1), throwsAssertionError);
      expect(() => FwMinMax(-1, const FwFr()), throwsAssertionError);
      expect(() => FwMinMax(0, const FwMinMax(0, FwPx(1))), throwsAssertionError);
      expect(const FwAuto(), isA<FwGridTrack>());
    });

    test('FwGridItem guards: spans >= 1, line numbers >= 1', () {
      expect(() => FwGridItem(columnSpan: 0, child: const SizedBox()), throwsAssertionError);
      expect(() => FwGridItem(rowSpan: 0, child: const SizedBox()), throwsAssertionError);
      expect(() => FwGridItem(columnStart: 0, child: const SizedBox()), throwsAssertionError);
    });

    test('FwTrack.repeat expands a track list', () {
      expect(FwTrack.repeat(3, const FwFr()).length, 3);
      expect(() => FwTrack.repeat(0, const FwFr()), throwsAssertionError);
    });

    test('FwGridPatch asserts non-negative gaps', () {
      expect(() => FwGridPatch(columnGap: -1), throwsAssertionError);
      expect(() => FwGridPatch(rowGap: -1), throwsAssertionError);
    });
  });
}

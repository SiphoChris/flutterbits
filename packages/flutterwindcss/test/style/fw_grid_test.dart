import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

Widget _wrap(Widget child) => Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  group('FwGridTrack', () {
    test('FwFr defaults to flex 1 and asserts > 0', () {
      expect(const FwFr().flex, 1);
      expect(const FwFr(2).flex, 2);
      expect(() => FwFr(0), throwsAssertionError);
    });

    test('FwPx carries a logical-px size and asserts >= 0', () {
      expect(const FwPx(200).size, 200.0);
      expect(() => FwPx(-1), throwsAssertionError);
    });
  });

  testWidgets('fr tracks become Expanded(flex:), px tracks become SizedBox(width:)', (t) async {
    await t.pumpWidget(
      _wrap(FwGrid(columns: const [FwPx(200), FwFr(2)], children: const [SizedBox(), SizedBox()])),
    );
    final row = t.widget<Row>(find.byType(Row));
    expect(row.children.length, 2);
    final fixed = row.children[0] as SizedBox;
    expect(fixed.width, 200.0);
    final flexible = row.children[1] as Expanded;
    expect(flexible.flex, 2);
  });

  testWidgets('children chunk row-major into rows of columns.length', (t) async {
    await t.pumpWidget(
      _wrap(
        FwGrid(
          columns: const [FwFr(), FwFr()],
          children: const [SizedBox(), SizedBox(), SizedBox()], // 3 → 2 rows
        ),
      ),
    );
    expect(find.byType(Row), findsNWidgets(2));
  });

  testWidgets('a partial last row is padded to full track structure', (t) async {
    await t.pumpWidget(
      _wrap(
        FwGrid(
          columns: const [FwFr(), FwFr()],
          children: const [SizedBox(), SizedBox(), SizedBox()],
        ),
      ),
    );
    final rows = t.widgetList<Row>(find.byType(Row)).toList();
    // Every row keeps both tracks so columns line up across rows.
    expect(rows[0].children.length, 2);
    expect(rows[1].children.length, 2);
  });

  testWidgets('column/row gaps map utility units to native spacing', (t) async {
    await t.pumpWidget(
      _wrap(
        FwGrid(
          columns: const [FwFr(), FwFr()],
          columnGap: 2,
          rowGap: 3,
          children: const [SizedBox(), SizedBox(), SizedBox(), SizedBox()],
        ),
      ),
    );
    final outer = t.widget<Column>(find.byType(Column));
    expect(outer.spacing, 12.0); // rowGap 3 × 4
    final row = t.widget<Row>(find.byType(Row).first);
    expect(row.spacing, 8.0); // columnGap 2 × 4
  });

  test('empty columns asserts', () {
    expect(() => FwGrid(columns: const [], children: const []), throwsAssertionError);
  });

  test('FwGridPatch asserts non-negative gaps', () {
    expect(() => FwGridPatch(columnGap: -1), throwsAssertionError);
    expect(() => FwGridPatch(rowGap: -1), throwsAssertionError);
  });

  group('responsive', () {
    Widget frameViewport(double width, Widget child) => MediaQuery(
      data: MediaQueryData(size: Size(width, 600)),
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    );

    testWidgets('viewport patch changes the column count (grid-cols responsive)', (t) async {
      final grid = FwGrid(
        columns: const [FwFr()], // 1 column below md
        viewport: const {
          FwBreakpoint.md: FwGridPatch(columns: [FwFr(), FwFr(), FwFr()]), // 3 columns at md
        },
        children: const [SizedBox(), SizedBox(), SizedBox()],
      );
      // 1 column → 3 rows.
      await t.pumpWidget(frameViewport(500, grid));
      expect(find.byType(Row), findsNWidgets(3));
      // 3 columns → 1 row.
      await t.pumpWidget(frameViewport(800, grid));
      expect(find.byType(Row), findsNWidgets(1));
    });

    testWidgets('viewport patch changes the gaps', (t) async {
      final grid = FwGrid(
        columns: const [FwFr(), FwFr()],
        columnGap: 1,
        rowGap: 1,
        viewport: const {FwBreakpoint.md: FwGridPatch(columnGap: 3, rowGap: 4)},
        children: const [SizedBox(), SizedBox(), SizedBox(), SizedBox()],
      );
      await t.pumpWidget(frameViewport(800, grid));
      expect(t.widget<Column>(find.byType(Column)).spacing, 16.0); // rowGap 4 × 4
      expect(t.widget<Row>(find.byType(Row).first).spacing, 12.0); // columnGap 3 × 4
    });

    testWidgets('static grid inserts no LayoutBuilder', (t) async {
      await t.pumpWidget(
        frameViewport(800, FwGrid(columns: const [FwFr()], children: const [SizedBox()])),
      );
      expect(find.byType(LayoutBuilder), findsNothing);
    });
  });
}

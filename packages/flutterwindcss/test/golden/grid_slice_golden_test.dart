import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Golden slice for the real CSS-grid engine (RenderFwGrid). A 3-track grid
// (px + fr + auto) with a column-spanning item and a fixed-track item, proving
// track sizing + spanning + row-major placement render directionally. Local
// generation is non-authoritative; CI (Linux) is the source of truth (spec §10).
Widget _frame(FwTokens tokens, TextDirection dir, Widget child) => FwTheme(
  tokens: tokens,
  child: Directionality(
    textDirection: dir,
    child: MediaQuery(
      data: const MediaQueryData(size: Size(220, 160)),
      child: ColoredBox(
        color: tokens.colors.background,
        child: Center(child: SizedBox(width: 160, child: child)),
      ),
    ),
  ),
);

Widget _cell(Color c, {double? w, double h = 18}) => SizedBox(width: w, height: h).tw.bg(c);

Widget _grid(BuildContext context) {
  final c = context.fw.colors;
  return FwGrid(
    columns: const [FwPx(40), FwFr(), FwAuto()],
    columnGap: 1,
    rowGap: 1,
    children: [
      // Spans the first two tracks (40px + fr).
      FwGridItem(columnSpan: 2, child: _cell(c.primary)),
      _cell(c.accent, w: 28), // lands in the auto track → sizes it to 28
      _cell(c.secondary), // wraps to row 1, first track (40px)
      _cell(c.muted),
      _cell(c.destructive, w: 28), // auto track again
    ],
  );
}

void main() {
  testWidgets('grid slice — light LTR (span + px/fr/auto tracks)', (t) async {
    await t.pumpWidget(_frame(FwTokens.light, TextDirection.ltr, Builder(builder: _grid)));
    await expectLater(find.byType(FwGrid), matchesGoldenFile('goldens/grid_light_ltr.png'));
  });

  testWidgets('grid slice — dark RTL (column order mirrors)', (t) async {
    await t.pumpWidget(_frame(FwTokens.dark, TextDirection.rtl, Builder(builder: _grid)));
    await expectLater(find.byType(FwGrid), matchesGoldenFile('goldens/grid_dark_rtl.png'));
  });
}

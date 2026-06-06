import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Golden slice for the module 8 layout widgets. Each frame proves directional
// layout: FwRow children flow start→end (mirroring in RTL), FwPositioned inset is
// directional, and FwGrid lays out row-major start→end. Local generation is
// non-authoritative; CI (Linux, pinned font) is the source of truth (spec §10).
Widget _frame(FwTokens tokens, TextDirection dir, Widget child) => FwTheme(
  tokens: tokens,
  child: Directionality(
    textDirection: dir,
    child: MediaQuery(
      data: const MediaQueryData(size: Size(220, 160)),
      child: ColoredBox(color: tokens.colors.background, child: Center(child: child)),
    ),
  ),
);

Widget _swatch(Color c, {double w = 10, double h = 8}) =>
    const SizedBox.shrink().tw.w(w).h(h).bg(c);

Widget _flex(BuildContext context) {
  final c = context.fw.colors;
  return FwRow(
    gap: 2,
    mainAxisSize: MainAxisSize.min,
    children: [_swatch(c.primary), _swatch(c.secondary), _swatch(c.accent)],
  );
}

Widget _stack(BuildContext context) {
  final c = context.fw.colors;
  return FwStack(
    children: [
      _swatch(c.muted, w: 24, h: 24),
      FwPositioned(start: 1, top: 1, z: 10, child: _swatch(c.primary, w: 8, h: 8)),
    ],
  );
}

Widget _grid(BuildContext context) {
  final c = context.fw.colors;
  return SizedBox(
    width: 120,
    child: FwGrid(
      columns: const [FwPx(40), FwFr()],
      columnGap: 1,
      rowGap: 1,
      children: [
        _swatch(c.primary, w: 40),
        _swatch(c.secondary),
        _swatch(c.accent, w: 40),
        _swatch(c.destructive),
      ],
    ),
  );
}

Widget _scene(BuildContext context) => FwColumn(
  gap: 3,
  mainAxisSize: MainAxisSize.min,
  children: [_flex(context), _stack(context), _grid(context)],
);

void main() {
  testWidgets('layout slice — light LTR (row/stack/grid flow start→end)', (t) async {
    await t.pumpWidget(_frame(FwTokens.light, TextDirection.ltr, const Builder(builder: _scene)));
    await expectLater(find.byType(FwColumn), matchesGoldenFile('goldens/layout_light_ltr.png'));
  });

  testWidgets('layout slice — dark RTL (everything mirrors)', (t) async {
    await t.pumpWidget(_frame(FwTokens.dark, TextDirection.rtl, const Builder(builder: _scene)));
    await expectLater(find.byType(FwColumn), matchesGoldenFile('goldens/layout_dark_rtl.png'));
  });
}

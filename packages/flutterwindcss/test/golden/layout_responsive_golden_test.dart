import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Golden slice for the module 8 *responsive* layout layering. The SAME scene is
// pumped at a narrow (below md) and a wide (≥ md) viewport: the FwRow gap grows
// and the FwGrid goes from one column (stacked) to three (single row). Proving
// the viewport-keyed FwFlexPatch / FwGridPatch resolution end-to-end. Local
// generation is non-authoritative; CI (Linux) is the source of truth (spec §10).
Widget _frame(double width, FwTokens tokens, Widget child) => FwTheme(
  tokens: tokens,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(size: Size(width, 220)),
      child: ColoredBox(color: tokens.colors.background, child: Center(child: child)),
    ),
  ),
);

Widget _swatch(Color c) => const SizedBox.shrink().tw.h(10).bg(c);

Widget _scene(BuildContext context) {
  final c = context.fw.colors;
  return SizedBox(
    width: 180,
    child: FwColumn(
      gap: 2,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Responsive gap: 1u below md, 5u at md+.
        FwRow(
          gap: 1,
          viewport: const {FwBreakpoint.md: FwFlexPatch(gap: 5)},
          children: [
            Expanded(child: _swatch(c.primary)),
            Expanded(child: _swatch(c.secondary)),
            Expanded(child: _swatch(c.accent)),
          ],
        ),
        // Responsive columns: 1 below md, 3 at md+.
        FwGrid(
          columns: const [FwFr()],
          columnGap: 1,
          rowGap: 1,
          viewport: const {FwBreakpoint.md: FwGridPatch(columns: [FwFr(), FwFr(), FwFr()])},
          children: [_swatch(c.primary), _swatch(c.secondary), _swatch(c.accent)],
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('responsive layout — narrow viewport (below md: tight gap, 1 column)', (t) async {
    await t.pumpWidget(_frame(500, FwTokens.light, const Builder(builder: _scene)));
    await expectLater(find.byType(FwColumn), matchesGoldenFile('goldens/layout_responsive_narrow.png'));
  });

  testWidgets('responsive layout — wide viewport (md+: wide gap, 3 columns)', (t) async {
    await t.pumpWidget(_frame(900, FwTokens.light, const Builder(builder: _scene)));
    await expectLater(find.byType(FwColumn), matchesGoldenFile('goldens/layout_responsive_wide.png'));
  });
}

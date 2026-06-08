import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Golden slice for the module 16/17 *visual* completeness features that the
// structural/value unit tests (test/style/fw_module17_test.dart, fw_divide_test
// .dart) deliberately cannot catch: a compositing or paint regression is only
// visible in pixels. Four scenes, each captured light + dark:
//
//   1. divide  — FwRow draws an END-edge border BETWEEN children (Tailwind
//                `divide-x`). A paint regression (wrong edge, dropped border)
//                shows here, not in the BorderDirectional value asserted in unit.
//   2. blend   — mix-blend-mode `multiply`: two overlapping squares on a pinned
//                opaque backing. Catches the blend silently degrading to srcOver.
//   3. card3d  — 3D `rotateY` under a `perspective` projection: the foreshorten
//                (one edge nearer/farther) is a paint-matrix effect a value test
//                can only sample, not see.
//   4. textShadow — a coloured offset glyph shadow flowing through DefaultTextStyle.
//
// scroll-snap (M16) and bgImage (M17) are intentionally NOT here: scroll-snap is
// behavioural (it has no still-frame), and bgImage needs a bundled raster asset
// (a synthetic AssetImage fails to load async — see fw_module17_test.dart), so a
// golden of it would capture an empty fill, catching nothing.
//
// Cross-platform note (AGENTS.md §9 / spec §10): mix-blend `saveLayer` + the 3D
// projection matrix carry higher rasteriser divergence risk than the existing
// flat-colour goldens. CI (Linux `ubuntu-latest`, the pinned Flutter 3.41.9) is
// the AUTHORITATIVE golden platform: the committed baselines were generated
// locally and must be confirmed by CI — if CI diff-fails, re-baseline there
// (ci.yaml uploads the failure images as an artifact). To keep the blend
// deterministic the scenes that depend on a backdrop pin it explicitly rather
// than relying on the theme background (see `_blend`).
Widget _frame(FwTokens tokens, TextDirection dir, Widget child) => FwTheme(
  tokens: tokens,
  child: Directionality(
    textDirection: dir,
    child: MediaQuery(
      data: const MediaQueryData(size: Size(180, 160)),
      child: ColoredBox(color: tokens.colors.background, child: Center(child: child)),
    ),
  ),
);

/// Scene 1 — `divide`: three muted cells with a high-contrast `primary` divider
/// drawn on the end edge of every non-last cell.
Widget _divide(BuildContext context) {
  final c = context.fw.colors;
  Widget cell() => const SizedBox(width: 28, height: 48).tw.bg(c.muted);
  return FwRow(
    mainAxisSize: MainAxisSize.min,
    divideWidth: 3,
    divideColor: c.primary,
    children: <Widget>[cell(), cell(), cell()],
  );
}

/// Scene 2 — `blend` (mix-blend-mode `multiply`). mix-blend composites against
/// whatever is painted *behind* it, so we pin an opaque white backing and key the
/// whole panel for capture: the multiply is then identical and well-defined in
/// both themes (yellow ∧ cyan → green in the overlap; the non-overlap halves stay
/// yellow/cyan over white). Fixed colours are intentional here — a multiply of two
/// theme greys yields no visible third colour, and this is a test fixture, not a
/// component, so the §3.1 semantic-only rule does not apply.
Widget _blend(BuildContext context) {
  Widget square(Color color, {BlendMode? blend}) {
    final w = const SizedBox(width: 60, height: 60).tw.bg(color);
    return blend == null ? w : w.blendMode(blend);
  }

  return RepaintBoundary(
    key: const ValueKey<String>('blend'),
    child: SizedBox(
      width: 100,
      height: 100,
      child: ColoredBox(
        color: const Color(0xFFFFFFFF),
        child: Stack(
          children: <Widget>[
            Positioned(top: 8, left: 8, child: square(const Color(0xFFFFD600))),
            Positioned(
              top: 32,
              left: 32,
              child: square(const Color(0xFF00BCD4), blend: BlendMode.multiply),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Scene 3 — a `primary` card rotated about the Y axis under a `perspective`
/// projection, so one vertical edge foreshortens toward the viewer.
Widget _card3d(BuildContext context) {
  final c = context.fw.colors;
  return const SizedBox(
    width: 80,
    height: 56,
  ).tw.bg(c.primary).rounded(context.fw.radii.lg).perspective(500).rotateY(35);
}

/// Scene 4 — big bold `foreground` text carrying a coloured offset drop shadow
/// (Tailwind `text-shadow`), visible against the theme background in both modes.
Widget _textShadow(BuildContext context) {
  final c = context.fw.colors;
  return const Text(
    'Ag',
  ).tw.text(c.foreground).textSize(FwFontSize.xl4.px).weight(FwFontWeight.bold).textShadow(
    const <Shadow>[Shadow(color: Color(0xFF3B82F6), blurRadius: 6, offset: Offset(3, 3))],
  );
}

void main() {
  group('module 16/17 visual slice', () {
    testWidgets('divide — light', (t) async {
      await t.pumpWidget(
        _frame(FwTokens.light, TextDirection.ltr, const Builder(builder: _divide)),
      );
      await expectLater(find.byType(FwRow), matchesGoldenFile('goldens/m1617_divide_light.png'));
    });

    testWidgets('divide — dark', (t) async {
      await t.pumpWidget(_frame(FwTokens.dark, TextDirection.ltr, const Builder(builder: _divide)));
      await expectLater(find.byType(FwRow), matchesGoldenFile('goldens/m1617_divide_dark.png'));
    });

    testWidgets('mix-blend multiply — light', (t) async {
      await t.pumpWidget(_frame(FwTokens.light, TextDirection.ltr, const Builder(builder: _blend)));
      await expectLater(
        find.byKey(const ValueKey<String>('blend')),
        matchesGoldenFile('goldens/m1617_blend_light.png'),
      );
    });

    testWidgets('mix-blend multiply — dark', (t) async {
      await t.pumpWidget(_frame(FwTokens.dark, TextDirection.ltr, const Builder(builder: _blend)));
      await expectLater(
        find.byKey(const ValueKey<String>('blend')),
        matchesGoldenFile('goldens/m1617_blend_dark.png'),
      );
    });

    testWidgets('rotateY + perspective — light', (t) async {
      await t.pumpWidget(
        _frame(FwTokens.light, TextDirection.ltr, const Builder(builder: _card3d)),
      );
      await expectLater(
        find.byType(FwStyled).first,
        matchesGoldenFile('goldens/m1617_card3d_light.png'),
      );
    });

    testWidgets('rotateY + perspective — dark', (t) async {
      await t.pumpWidget(_frame(FwTokens.dark, TextDirection.ltr, const Builder(builder: _card3d)));
      await expectLater(
        find.byType(FwStyled).first,
        matchesGoldenFile('goldens/m1617_card3d_dark.png'),
      );
    });

    testWidgets('text-shadow — light', (t) async {
      await t.pumpWidget(
        _frame(FwTokens.light, TextDirection.ltr, const Builder(builder: _textShadow)),
      );
      await expectLater(
        find.byType(FwStyled).first,
        matchesGoldenFile('goldens/m1617_textshadow_light.png'),
      );
    });

    testWidgets('text-shadow — dark', (t) async {
      await t.pumpWidget(
        _frame(FwTokens.dark, TextDirection.ltr, const Builder(builder: _textShadow)),
      );
      await expectLater(
        find.byType(FwStyled).first,
        matchesGoldenFile('goldens/m1617_textshadow_dark.png'),
      );
    });
  });
}

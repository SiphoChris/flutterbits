import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';
import 'package:flutterbits_gallery/components/ui/button.dart';

/// Minimal theme frame: FwTheme + Directionality + MediaQuery + a background-
/// coloured surface.  Using [ColoredBox] over `tokens.colors.background` means
/// translucent hover-state alphas (e.g. primary/90) composite against the
/// correct surface colour rather than transparent-black, matching how the
/// component renders in a real app.
///
/// The [UnconstrainedBox] lets the [RepaintBoundary] inside [child] grow
/// horizontally beyond the surface width so button labels ("destructive",
/// "secondary") never trigger a RenderFlex overflow, keeping the golden clean.
Widget _frame(FwTokens tokens, TextDirection dir, Widget child) => FwTheme(
  tokens: tokens,
  child: Directionality(
    textDirection: dir,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: ColoredBox(
        color: tokens.colors.background,
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: UnconstrainedBox(child: Padding(padding: const EdgeInsets.all(16), child: child)),
        ),
      ),
    ),
  ),
);

/// One row per variant + one disabled row; one column per size.
///
/// Wrapped in a [RepaintBoundary] so [matchesGoldenFile] captures a clean,
/// stable paint boundary that is unaffected by other on-screen widgets.
Widget _grid() {
  Widget cell(ButtonVariant v, ButtonSize s) => Button(
    variant: v,
    size: s,
    onPressed: () {},
    child: s == ButtonSize.icon ? const Text('+') : Text(v.name),
  );

  return RepaintBoundary(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final v in ButtonVariant.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final s in ButtonSize.values)
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: cell(v, s)),
              ],
            ),
          ),
        // Disabled row — uses primary variant (most visible) across all sizes.
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in ButtonSize.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Button(
                    size: s,
                    onPressed: null,
                    child: s == ButtonSize.icon ? const Text('+') : const Text('off'),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

void main() {
  // Surface just needs to be tall enough for 7 rows.  Width is unconstrained
  // via [UnconstrainedBox] in _frame, so the RepaintBoundary captures the
  // true content width regardless of surface width.
  const surfaceSize = Size(800, 500);

  testWidgets('button grid — light LTR', (t) async {
    await t.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(_frame(FwTokens.light, TextDirection.ltr, _grid()));
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('goldens/button_grid_light.png'),
    );
  });

  testWidgets('button grid — dark LTR', (t) async {
    await t.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(_frame(FwTokens.dark, TextDirection.ltr, _grid()));
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('goldens/button_grid_dark.png'),
    );
  });

  testWidgets('button grid — light RTL (directional padding/border mirrors)', (t) async {
    await t.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(_frame(FwTokens.light, TextDirection.rtl, _grid()));
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('goldens/button_grid_rtl.png'),
    );
  });
}

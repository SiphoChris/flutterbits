import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Golden slice for the module 9 transform setters. A rounded primary square is
// rotated + scaled (paint-only) over the app background. Transforms are not
// directional, but the light/dark pair keeps harness symmetry and covers both
// themes. Local generation is non-authoritative; CI (Linux) is the source of
// truth (spec §10).
Widget _frame(FwTokens tokens, Widget child) => FwTheme(
  tokens: tokens,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(size: Size(160, 160)),
      child: ColoredBox(color: tokens.colors.background, child: Center(child: child)),
    ),
  ),
);

Widget _shape(BuildContext context) {
  final c = context.fw.colors;
  return const SizedBox(
    width: 60,
    height: 40,
  ).tw.bg(c.primary).rounded(context.fw.radii.md).rotate(20).scale(1.2);
}

void main() {
  testWidgets('transform slice — light (rotate 20° + scale 1.2)', (t) async {
    await t.pumpWidget(_frame(FwTokens.light, const Builder(builder: _shape)));
    await expectLater(find.byType(FwStyled), matchesGoldenFile('goldens/transform_light.png'));
  });

  testWidgets('transform slice — dark (rotate 20° + scale 1.2)', (t) async {
    await t.pumpWidget(_frame(FwTokens.dark, const Builder(builder: _shape)));
    await expectLater(find.byType(FwStyled), matchesGoldenFile('goldens/transform_dark.png'));
  });
}

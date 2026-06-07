import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Golden slice for module 15 ergonomics/utilities: gradient direction sugar, the
// focus `ring`, a dashed "drop-zone" border, and the named-scale shadow/radius
// sugar — all resolved against the theme. Light + dark. Local generation is
// non-authoritative; CI (Linux) is the source of truth (spec §10).
Widget _frame(FwTokens tokens, Widget child) => FwTheme(
  tokens: tokens,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(size: Size(360, 140)),
      child: ColoredBox(color: tokens.colors.background, child: Center(child: child)),
    ),
  ),
);

Widget _row(BuildContext context) {
  final c = context.fw.colors;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      // Gradient direction sugar + named radius.
      const SizedBox(
        width: 70,
        height: 70,
      ).tw.m(2).roundedLg.bgGradientToBottomEnd(<Color>[c.primary, c.accent]),
      // Focus ring + named radius + named shadow.
      const SizedBox(
        width: 70,
        height: 70,
      ).tw.m(2).bg(c.card).roundedMd.shadowMd.ring(3, color: c.ring),
      // Dashed "drop to upload" zone.
      const SizedBox(
        width: 70,
        height: 70,
      ).tw.m(2).bg(c.muted).rounded(10).border(2, color: c.mutedForeground).borderDashed,
    ],
  );
}

void main() {
  testWidgets('sugar slice — light', (t) async {
    await t.pumpWidget(_frame(FwTokens.light, const Builder(builder: _row)));
    await expectLater(find.byType(Row), matchesGoldenFile('goldens/sugar_light.png'));
  });

  testWidgets('sugar slice — dark', (t) async {
    await t.pumpWidget(_frame(FwTokens.dark, const Builder(builder: _row)));
    await expectLater(find.byType(Row), matchesGoldenFile('goldens/sugar_dark.png'));
  });
}

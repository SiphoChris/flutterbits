import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Golden slice for the module 7 effects. A rounded box uses the high-contrast
// `primary` fill (so it reads against the app background in both themes), with a
// theme drop shadow (FwShadows scale) and group opacity, so the shadow and
// translucency are both visible. Backdrop blur needs a textured backdrop and is
// covered by render_chain_test instead (noted in the plan). Local generation is
// non-authoritative; CI (Linux) is the source of truth (spec §10).
Widget _frame(FwTokens tokens, TextDirection dir, Widget child) => FwTheme(
  tokens: tokens,
  child: Directionality(
    textDirection: dir,
    child: MediaQuery(
      data: const MediaQueryData(size: Size(200, 140)),
      child: ColoredBox(color: tokens.colors.background, child: Center(child: child)),
    ),
  ),
);

Widget _card(BuildContext context) {
  final c = context.fw.colors;
  return const SizedBox.shrink().tw
      .w(28)
      .h(18)
      .bg(c.primary)
      .rounded(context.fw.radii.lg)
      .shadow(context.fw.shadows.lg)
      .opacity(0.9);
}

void main() {
  testWidgets('effects slice — light LTR (shadow + opacity)', (t) async {
    await t.pumpWidget(_frame(FwTokens.light, TextDirection.ltr, const Builder(builder: _card)));
    await expectLater(
      find.byType(FwStyled).first,
      matchesGoldenFile('goldens/effects_light_ltr.png'),
    );
  });

  testWidgets('effects slice — dark RTL (shadow + opacity)', (t) async {
    await t.pumpWidget(_frame(FwTokens.dark, TextDirection.rtl, const Builder(builder: _card)));
    await expectLater(
      find.byType(FwStyled).first,
      matchesGoldenFile('goldens/effects_dark_rtl.png'),
    );
  });
}

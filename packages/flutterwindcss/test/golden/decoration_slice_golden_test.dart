import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Golden slice for the module 5 color/border/radius setters. The box carries a
// semantic background, a thick **start** border + thin **end** border (so RTL
// mirrors them), start-corner rounding, and an antialias clip (exercising the
// Finding #3 radius deflation) — proving the typed decoration setters drive the
// directional render chain end-to-end. Local generation is non-authoritative;
// CI (Linux, pinned font) is the source of truth for these bytes (spec §10).
Widget _frame(FwTokens tokens, TextDirection dir, Widget child) => FwTheme(
  tokens: tokens,
  child: Directionality(
    textDirection: dir,
    child: MediaQuery(
      data: const MediaQueryData(size: Size(200, 140)),
      child: Center(child: child),
    ),
  ),
);

Widget _box(BuildContext context) {
  final c = context.fw.colors;
  return SizedBox.shrink()
      .tw
      .w(28)
      .h(20)
      .bg(c.card)
      .borderS(width: 4, color: c.ring)
      .borderE(width: 1, color: c.border)
      .roundedS(context.fw.radii.lg)
      .clip();
}

void main() {
  testWidgets('decoration slice — light LTR', (t) async {
    await t.pumpWidget(_frame(FwTokens.light, TextDirection.ltr, Builder(builder: _box)));
    await expectLater(
      find.byType(FwStyled).first,
      matchesGoldenFile('goldens/decoration_light_ltr.png'),
    );
  });

  testWidgets('decoration slice — dark RTL (start border + start radius mirror)', (t) async {
    await t.pumpWidget(_frame(FwTokens.dark, TextDirection.rtl, Builder(builder: _box)));
    await expectLater(
      find.byType(FwStyled).first,
      matchesGoldenFile('goldens/decoration_dark_rtl.png'),
    );
  });
}

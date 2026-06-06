import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Golden slice for the module 6 typography setters. A styled Text in a padded
// card exercises color + size + weight + leading + start-alignment + underline.
// Text renders with Flutter's built-in deterministic test font (no bundled
// face), so size/color/alignment/decoration are visible and CI-stable; weight is
// unit-tested rather than golden-tested (not visually distinct under that font).
// `align(TextAlign.start)` + a fixed width makes RTL mirror the text to the end.
// Local generation is non-authoritative; CI (Linux) is the source of truth.
Widget _frame(FwTokens tokens, TextDirection dir, Widget child) => FwTheme(
  tokens: tokens,
  child: Directionality(
    textDirection: dir,
    child: MediaQuery(
      data: const MediaQueryData(size: Size(220, 120)),
      child: Center(child: child),
    ),
  ),
);

Widget _text(BuildContext context) {
  final c = context.fw.colors;
  return const Text('Ag')
      .tw
      .w(40)
      .p(2)
      .bg(c.card)
      .text(c.cardForeground)
      .textSize(FwFontSize.xl2.px)
      .weight(FwFontWeight.bold)
      .leading(FwLeading.tight)
      .align(TextAlign.start)
      .underline;
}

void main() {
  testWidgets('typography slice — light LTR', (t) async {
    await t.pumpWidget(_frame(FwTokens.light, TextDirection.ltr, const Builder(builder: _text)));
    await expectLater(
      find.byType(FwStyled).first,
      matchesGoldenFile('goldens/typography_light_ltr.png'),
    );
  });

  testWidgets('typography slice — dark RTL (start alignment mirrors to the end)', (t) async {
    await t.pumpWidget(_frame(FwTokens.dark, TextDirection.rtl, const Builder(builder: _text)));
    await expectLater(
      find.byType(FwStyled).first,
      matchesGoldenFile('goldens/typography_dark_rtl.png'),
    );
  });
}

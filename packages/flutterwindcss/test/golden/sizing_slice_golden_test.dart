import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Golden slice for the module 4 spacing/sizing setters. The box carries a
// **start** margin (so RTL mirrors it to the opposite side), a fixed width +
// min-height, and a semantic background — proving the typed setters drive the
// directional render chain end-to-end. Local generation is non-authoritative;
// CI (Linux, pinned font) is the source of truth for these bytes (spec §10).
Widget _frame(FwTokens tokens, TextDirection dir, Widget child) => FwTheme(
  tokens: tokens,
  child: Directionality(
    textDirection: dir,
    child: MediaQuery(
      data: const MediaQueryData(size: Size(200, 120)),
      child: Center(child: child),
    ),
  ),
);

void main() {
  testWidgets('sizing slice — light LTR (start margin, fixed w + min-h)', (t) async {
    await t.pumpWidget(
      _frame(
        FwTokens.light,
        TextDirection.ltr,
        Builder(
          builder:
              (context) =>
                  const SizedBox.shrink().tw.ms(6).w(18).minH(10).bg(context.fw.colors.primary),
        ),
      ),
    );
    await expectLater(find.byType(FwStyled), matchesGoldenFile('goldens/sizing_light_ltr.png'));
  });

  testWidgets('sizing slice — dark RTL (start margin mirrors to the right)', (t) async {
    await t.pumpWidget(
      _frame(
        FwTokens.dark,
        TextDirection.rtl,
        Builder(
          builder:
              (context) =>
                  const SizedBox.shrink().tw.ms(6).w(18).minH(10).bg(context.fw.colors.primary),
        ),
      ),
    );
    await expectLater(find.byType(FwStyled), matchesGoldenFile('goldens/sizing_dark_rtl.png'));
  });
}

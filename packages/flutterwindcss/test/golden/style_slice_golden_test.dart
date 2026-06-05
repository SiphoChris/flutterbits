import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

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
  testWidgets('padding+bg slice — light LTR', (t) async {
    await t.pumpWidget(
      _frame(
        FwTokens.light,
        TextDirection.ltr,
        Builder(
          builder:
              (context) =>
                  const SizedBox(width: 80, height: 40).tw.p(3).bg(context.fw.colors.primary),
        ),
      ),
    );
    await expectLater(find.byType(FwStyled), matchesGoldenFile('goldens/slice_light_ltr.png'));
  });

  testWidgets('padding+bg slice — dark RTL (start padding mirrors)', (t) async {
    await t.pumpWidget(
      _frame(
        FwTokens.dark,
        TextDirection.rtl,
        Builder(
          builder:
              (context) =>
                  const SizedBox(width: 80, height: 40).tw.ps(6).bg(context.fw.colors.primary),
        ),
      ),
    );
    await expectLater(find.byType(FwStyled), matchesGoldenFile('goldens/slice_dark_rtl.png'));
  });
}

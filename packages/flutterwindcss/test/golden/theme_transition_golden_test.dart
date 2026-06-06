import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Golden slice for module 10 (FwAnimatedTheme). A primary-filled card is captured
// MID-TRANSITION (50% of a light→dark tween), so its fill is the lerped midpoint
// between the light and dark `primary` — proving FwTokens.lerp drives the
// crossfade. Local generation is non-authoritative; CI (Linux) is the source of
// truth (spec §10).
Widget _card(BuildContext context) =>
    const SizedBox(width: 80, height: 40).tw.bg(context.fw.colors.primary).rounded(8);

Widget _app(FwTokens tokens) => FwAnimatedTheme(
  tokens: tokens,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(size: Size(140, 100)),
      child: ColoredBox(
        color: tokens.colors.background,
        child: const Center(child: Builder(builder: _card)),
      ),
    ),
  ),
);

void main() {
  testWidgets('theme transition slice — 50% between light and dark', (t) async {
    await t.pumpWidget(_app(FwTokens.light));
    await t.pumpWidget(_app(FwTokens.dark)); // retarget the animation
    await t.pump(const Duration(milliseconds: 100)); // 50% of the 200ms default
    await expectLater(find.byType(FwStyled), matchesGoldenFile('goldens/theme_transition_mid.png'));
  });
}

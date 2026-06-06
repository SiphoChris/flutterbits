import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

void main() {
  late FwTokens got;

  Widget app(FwTokens tokens, {Duration duration = const Duration(milliseconds: 200)}) =>
      Directionality(
        textDirection: TextDirection.ltr,
        child: FwAnimatedTheme(
          tokens: tokens,
          duration: duration,
          child: Builder(
            builder: (context) {
              got = context.fw;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

  testWidgets('provides the tokens via an FwTheme (drop-in for FwTheme)', (t) async {
    await t.pumpWidget(app(FwTokens.light));
    expect(find.byType(FwTheme), findsOneWidget);
    expect(got, FwTokens.light);
  });

  testWidgets('tweens old→new via FwTokens.lerp at the linear midpoint', (t) async {
    await t.pumpWidget(app(FwTokens.light));
    await t.pumpWidget(app(FwTokens.dark)); // retarget
    await t.pump(const Duration(milliseconds: 100)); // 50% of 200ms, linear curve
    expect(got, FwTokens.lerp(FwTokens.light, FwTokens.dark, 0.5));
    // It is genuinely mid-flight (neither endpoint).
    expect(got, isNot(FwTokens.light));
    expect(got, isNot(FwTokens.dark));
    await t.pumpAndSettle();
    expect(got, FwTokens.dark);
  });

  testWidgets('zero duration swaps immediately (no in-between frame)', (t) async {
    await t.pumpWidget(app(FwTokens.light, duration: Duration.zero));
    await t.pumpWidget(app(FwTokens.dark, duration: Duration.zero));
    await t.pump();
    expect(got, FwTokens.dark);
  });
}

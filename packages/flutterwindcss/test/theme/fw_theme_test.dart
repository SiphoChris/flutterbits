import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

void main() {
  testWidgets('maybeOf returns the active tokens to a descendant', (tester) async {
    FwTokens? seen;
    await tester.pumpWidget(
      FwTheme(
        tokens: FwTokens.light,
        child: Builder(
          builder: (context) {
            seen = FwTheme.maybeOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(seen, same(FwTokens.light));
  });

  testWidgets('maybeOf returns null when no FwTheme is present', (tester) async {
    FwTokens? seen = FwTokens.light;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          seen = FwTheme.maybeOf(context);
          return const SizedBox.shrink();
        },
      ),
    );

    expect(seen, isNull);
  });

  testWidgets('dependents rebuild only when the tokens value changes', (tester) async {
    var builds = 0;
    // One stable dependent instance reused across pumps: it can only rebuild
    // because of an inherited-dependency change, isolating updateShouldNotify.
    final probe = Builder(
      builder: (context) {
        FwTheme.maybeOf(context);
        builds++;
        return const SizedBox.shrink();
      },
    );
    Widget app(FwTokens tokens) => FwTheme(tokens: tokens, child: probe);

    await tester.pumpWidget(app(FwTokens.light));
    expect(builds, 1);

    // Same value (different instance) → no notify, no dependent rebuild.
    await tester.pumpWidget(app(FwTokens.light));
    expect(builds, 1);

    // Different value → notify, dependent rebuilds.
    await tester.pumpWidget(app(FwTokens.dark));
    expect(builds, 2);
  });
}

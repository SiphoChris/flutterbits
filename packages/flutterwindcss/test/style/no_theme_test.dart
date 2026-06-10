import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// "You are not forced into a theme." A developer can use the raw palette and
// their own fonts with NO FwTheme / FwThemeExtension at all. Only the *theme
// role* sugars (`fontSans`/`roundedMd`/`shadowMd`) consult a theme — and when
// none is present they fall back to the stock FwTokens.light defaults rather
// than crash. (Semantic colour tokens read via `context.fw` still need a theme.)
Widget _bare(Widget child) => Directionality(textDirection: TextDirection.ltr, child: child);

BoxDecoration? _radiusDeco(WidgetTester t) {
  for (final d in t.widgetList<DecoratedBox>(find.byType(DecoratedBox))) {
    final deco = d.decoration;
    if (deco is BoxDecoration && deco.borderRadius != null) return deco;
  }
  return null;
}

void main() {
  testWidgets('raw palette + raw styling renders with no theme', (t) async {
    await t.pumpWidget(
      _bare(
        const Text(
          'hi',
        ).tw.p(4).bg(FwPalette.blue.shade500).text(FwPalette.slate.shade50).rounded(8),
      ),
    );
    expect(t.takeException(), isNull);
    expect(find.text('hi'), findsOneWidget);
  });

  testWidgets('a literal custom font works with no theme', (t) async {
    await t.pumpWidget(_bare(const Text('hi').tw.font('MyCustomFont')));
    expect(t.takeException(), isNull);
    final dts = t.widget<DefaultTextStyle>(find.byType(DefaultTextStyle).last);
    expect(dts.style.fontFamily, 'MyCustomFont');
  });

  testWidgets('fontSans with no theme falls back to the stock sans (no crash)', (t) async {
    String? family;
    await t.pumpWidget(
      _bare(
        FwStyled(
          style: const FwStyle().fontSans,
          child: Builder(
            builder: (ctx) {
              family = DefaultTextStyle.of(ctx).style.fontFamily;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(t.takeException(), isNull);
    expect(family, FwTokens.light.typography.sans); // stock 'sans-serif'
  });

  testWidgets('roundedMd / shadowMd with no theme use the stock defaults (no crash)', (t) async {
    await t.pumpWidget(
      _bare(
        const SizedBox(width: 40, height: 40).tw.bg(FwPalette.zinc.shade200).roundedMd.shadowMd,
      ),
    );
    expect(t.takeException(), isNull);
    expect(
      _radiusDeco(t)!.borderRadius!.resolve(TextDirection.ltr).topLeft,
      Radius.circular(FwTokens.light.radii.md),
    );
  });
}

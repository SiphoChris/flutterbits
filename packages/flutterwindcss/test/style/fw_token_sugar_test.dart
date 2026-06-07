import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Module 15 — named-scale sugar for theme-derived tokens (radius + shadow). The
// setters store a *step* enum; FwStyled resolves it against context.fw at build
// (the one gated, opt-in theme read in the otherwise theme-agnostic pipeline), so
// `roundedMd()` == `rounded(context.fw.radii.md)` and tracks the theme. resolve()
// itself stays context-free.
BoxDecoration? _deco(WidgetTester t) {
  for (final d in t.widgetList<DecoratedBox>(find.byType(DecoratedBox))) {
    if (d.decoration is BoxDecoration) return d.decoration as BoxDecoration;
  }
  return null;
}

BorderRadius? _radiusOf(WidgetTester t) {
  for (final d in t.widgetList<DecoratedBox>(find.byType(DecoratedBox))) {
    final deco = d.decoration;
    if (deco is BoxDecoration && deco.borderRadius != null) {
      return deco.borderRadius!.resolve(TextDirection.ltr);
    }
  }
  return null;
}

Widget _themed(Widget child) => FwTheme(
  tokens: FwTokens.light,
  child: Directionality(textDirection: TextDirection.ltr, child: child),
);

void main() {
  test('roundedSm/Md/Lg/Xl store a radius step', () {
    expect(const FwStyle().roundedSm.radiusStep, FwRadiusStep.sm);
    expect(const FwStyle().roundedMd.radiusStep, FwRadiusStep.md);
    expect(const FwStyle().roundedLg.radiusStep, FwRadiusStep.lg);
    expect(const FwStyle().roundedXl.radiusStep, FwRadiusStep.xl);
  });

  test('shadow steps store a shadow step', () {
    expect(const FwStyle().shadowMd.shadowStep, FwShadowStep.md);
    expect(const FwStyle().shadowNone.shadowStep, FwShadowStep.none);
    expect(const FwStyle().shadow2xl.shadowStep, FwShadowStep.xl2);
  });

  testWidgets('roundedMd resolves to the theme radii.md at build', (t) async {
    await t.pumpWidget(
      _themed(const SizedBox(width: 40, height: 40).tw.bg(const Color(0xFF111111)).roundedMd),
    );
    final expected = FwTokens.light.radii.md;
    expect(_radiusOf(t)!.topLeft, Radius.circular(expected));
  });

  testWidgets('shadowMd resolves to the theme shadows.md at build', (t) async {
    await t.pumpWidget(
      _themed(const SizedBox(width: 40, height: 40).tw.bg(const Color(0xFF111111)).shadowMd),
    );
    expect(_deco(t)!.boxShadow, FwTokens.light.shadows.md);
  });

  testWidgets('shadowNone resolves to an empty shadow list (no shadow layer)', (t) async {
    await t.pumpWidget(
      _themed(const SizedBox(width: 40, height: 40).tw.bg(const Color(0xFF111111)).shadowNone),
    );
    // No DecoratedBox should carry a non-empty boxShadow.
    final hasShadow = t
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .any(
          (d) =>
              d.decoration is BoxDecoration &&
              (d.decoration as BoxDecoration).boxShadow?.isNotEmpty == true,
        );
    expect(hasShadow, isFalse);
  });

  testWidgets('a hover shadow step resolves in a layer', (t) async {
    await t.pumpWidget(
      _themed(
        const SizedBox(
          width: 40,
          height: 40,
        ).tw.bg(const Color(0xFF111111)).shadowSm.hover((s) => s.shadowLg),
      ),
    );
    // Not hovered: sm.
    expect(_deco(t)!.boxShadow, FwTokens.light.shadows.sm);
  });

  testWidgets('mixing a radius step with a raw radius in one chain asserts', (t) async {
    await t.pumpWidget(_themed(const SizedBox(width: 40, height: 40).tw.rounded(4).roundedMd));
    expect(t.takeException(), isAssertionError);
  });
}

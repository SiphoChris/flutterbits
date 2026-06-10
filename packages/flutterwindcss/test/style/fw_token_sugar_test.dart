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

  testWidgets('mixing a shadow step with a raw shadow in one chain asserts', (t) async {
    // Symmetric to the radius case: a step and a raw value both feed the same
    // render input (boxShadow), so the resolver asserts they can't coexist.
    await t.pumpWidget(
      _themed(
        const SizedBox(width: 40, height: 40).tw.bg(const Color(0xFF111111)).shadow(
          const <BoxShadow>[BoxShadow(color: Color(0x33000000), blurRadius: 2)],
        ).shadowMd,
      ),
    );
    expect(t.takeException(), isAssertionError);
  });

  // ---- Font roles (theme-resolved fontSans/Serif/Mono) ----

  // A theme with distinctive families so a resolved role is unambiguous.
  const customType = FwTypographyTheme(sans: 'Outfit', serif: 'Lora', mono: 'JetBrains Mono');
  final customTheme = FwTokens(
    radiusBase: FwTokens.light.radiusBase,
    radii: FwTokens.light.radii,
    shadows: FwTokens.light.shadows,
    typography: customType,
    colors: FwTokens.light.colors,
  );

  // The effective default text family at a probe; [style] (if any) is applied via
  // a styled box wrapping the probe. Captures inside the builder (no `find`, since
  // DefaultTextStyle.merge also uses a Builder).
  Future<String?> familyUnder(WidgetTester t, {FwStyle? style}) async {
    String? captured;
    Widget probe = Builder(
      builder: (ctx) {
        captured = DefaultTextStyle.of(ctx).style.fontFamily;
        return const SizedBox();
      },
    );
    if (style != null) probe = FwStyled(style: style, child: probe);
    await t.pumpWidget(
      FwTheme(
        tokens: customTheme,
        child: Directionality(textDirection: TextDirection.ltr, child: probe),
      ),
    );
    return captured;
  }

  test('fontSans/Serif/Mono store a font role (not a literal family)', () {
    expect(const FwStyle().fontSans.fontFamilyStep, FwFontStep.sans);
    expect(const FwStyle().fontSans.fontFamily, isNull);
    expect(const FwStyle().fontSerif.fontFamilyStep, FwFontStep.serif);
    expect(const FwStyle().fontMono.fontFamilyStep, FwFontStep.mono);
  });

  testWidgets('FwTheme applies the theme sans as the default text family', (t) async {
    // A plain box (no font setter) still inherits the theme's sans family.
    expect(await familyUnder(t), 'Outfit');
  });

  testWidgets('fontSerif / fontMono resolve to the theme families at build', (t) async {
    expect(await familyUnder(t, style: const FwStyle().fontSerif), 'Lora');
    expect(await familyUnder(t, style: const FwStyle().fontMono), 'JetBrains Mono');
  });

  testWidgets('fontSans resolves to the theme sans at build', (t) async {
    expect(await familyUnder(t, style: const FwStyle().fontSans), 'Outfit');
  });

  testWidgets('mixing a font role with a literal font() in one chain asserts', (t) async {
    await t.pumpWidget(_themed(const SizedBox(width: 40, height: 40).tw.font('Inter').fontSans));
    expect(t.takeException(), isAssertionError);
  });
}

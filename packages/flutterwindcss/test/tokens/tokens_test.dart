import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

void main() {
  test('light and dark are distinct const themes', () {
    expect(FwTokens.light, isNot(equals(FwTokens.dark)));
    expect(FwTokens.light.colors.background, isNot(FwTokens.dark.colors.background));
  });

  test('radii derive from the theme base', () {
    expect(FwTokens.light.radii.base, FwTokens.light.radiusBase);
  });

  test('lerp(light, dark, 0) == light and (.,.,1) == dark', () {
    expect(
      FwTokens.lerp(FwTokens.light, FwTokens.dark, 0).colors.background,
      FwTokens.light.colors.background,
    );
    expect(
      FwTokens.lerp(FwTokens.light, FwTokens.dark, 1).colors.background,
      FwTokens.dark.colors.background,
    );
  });

  test('light theme literals match baked palette swatches', () {
    expect(FwTokens.light.colors.border, FwPalette.neutral.shade200);
    expect(FwTokens.dark.colors.background, FwPalette.neutral.shade950);
  });

  // Comprehensive provenance test: every one of the 19 color roles in both
  // light and dark is pinned — either to the named palette swatch from its
  // annotation comment, or (for alpha-on-white values) to the explicit literal.
  // This catches any typo in a hex literal that the annotation comment would
  // otherwise conceal.
  test('every annotated theme literal matches its named palette swatch', () {
    // ── light theme (19 roles) ────────────────────────────────────────────────
    expect(FwTokens.light.colors.background, FwPalette.white);
    expect(FwTokens.light.colors.foreground, FwPalette.neutral.shade950);
    expect(FwTokens.light.colors.card, FwPalette.white);
    expect(FwTokens.light.colors.cardForeground, FwPalette.neutral.shade950);
    expect(FwTokens.light.colors.popover, FwPalette.white);
    expect(FwTokens.light.colors.popoverForeground, FwPalette.neutral.shade950);
    expect(FwTokens.light.colors.primary, FwPalette.neutral.shade900);
    expect(FwTokens.light.colors.primaryForeground, FwPalette.neutral.shade50);
    expect(FwTokens.light.colors.secondary, FwPalette.neutral.shade100);
    expect(FwTokens.light.colors.secondaryForeground, FwPalette.neutral.shade900);
    expect(FwTokens.light.colors.muted, FwPalette.neutral.shade100);
    expect(FwTokens.light.colors.mutedForeground, FwPalette.neutral.shade500);
    expect(FwTokens.light.colors.accent, FwPalette.neutral.shade100);
    expect(FwTokens.light.colors.accentForeground, FwPalette.neutral.shade900);
    expect(FwTokens.light.colors.destructive, FwPalette.red.shade600);
    expect(FwTokens.light.colors.destructiveForeground, FwPalette.white);
    expect(FwTokens.light.colors.border, FwPalette.neutral.shade200);
    expect(FwTokens.light.colors.input, FwPalette.neutral.shade200);
    expect(FwTokens.light.colors.ring, FwPalette.neutral.shade400);

    // ── dark theme (19 roles) ─────────────────────────────────────────────────
    expect(FwTokens.dark.colors.background, FwPalette.neutral.shade950);
    expect(FwTokens.dark.colors.foreground, FwPalette.neutral.shade50);
    expect(FwTokens.dark.colors.card, FwPalette.neutral.shade900);
    expect(FwTokens.dark.colors.cardForeground, FwPalette.neutral.shade50);
    expect(FwTokens.dark.colors.popover, FwPalette.neutral.shade900);
    expect(FwTokens.dark.colors.popoverForeground, FwPalette.neutral.shade50);
    expect(FwTokens.dark.colors.primary, FwPalette.neutral.shade50);
    expect(FwTokens.dark.colors.primaryForeground, FwPalette.neutral.shade900);
    expect(FwTokens.dark.colors.secondary, FwPalette.neutral.shade800);
    expect(FwTokens.dark.colors.secondaryForeground, FwPalette.neutral.shade50);
    expect(FwTokens.dark.colors.muted, FwPalette.neutral.shade800);
    expect(FwTokens.dark.colors.mutedForeground, FwPalette.neutral.shade400);
    expect(FwTokens.dark.colors.accent, FwPalette.neutral.shade800);
    expect(FwTokens.dark.colors.accentForeground, FwPalette.neutral.shade50);
    expect(FwTokens.dark.colors.destructive, FwPalette.red.shade400);
    expect(FwTokens.dark.colors.destructiveForeground, FwPalette.neutral.shade950);
    // border and input use alpha-on-white composites (not plain palette swatches);
    // pin them to their explicit literal values so a typo is still caught.
    expect(FwTokens.dark.colors.border, const Color(0x1AFFFFFF)); // white/10%
    expect(FwTokens.dark.colors.input, const Color(0x26FFFFFF)); // white/15%
    expect(FwTokens.dark.colors.ring, FwPalette.neutral.shade500);
  });

  test('equality includes typography', () {
    const other = FwTypographyTheme(family: 'CustomSans');
    const a = FwTokens.light;
    final b = FwTokens(
      colors: a.colors,
      radii: a.radii,
      shadows: a.shadows,
      typography: other,
      radiusBase: a.radiusBase,
    );
    expect(a == b, isFalse);
    expect(a.hashCode == b.hashCode, isFalse);
  });

  test('lerp carries typography across the t=0.5 threshold', () {
    const tA = FwTypographyTheme(family: 'A');
    const tB = FwTypographyTheme(family: 'B');
    final a = FwTokens(
      colors: FwTokens.light.colors,
      radii: FwTokens.light.radii,
      shadows: FwTokens.light.shadows,
      typography: tA,
      radiusBase: FwTokens.light.radiusBase,
    );
    final b = FwTokens(
      colors: FwTokens.dark.colors,
      radii: FwTokens.dark.radii,
      shadows: FwTokens.dark.shadows,
      typography: tB,
      radiusBase: FwTokens.dark.radiusBase,
    );
    expect(FwTokens.lerp(a, b, 0.0).typography, tA);
    expect(FwTokens.lerp(a, b, 0.49).typography, tA);
    expect(FwTokens.lerp(a, b, 0.5).typography, tB);
    expect(FwTokens.lerp(a, b, 1.0).typography, tB);
  });

  test('lerp interpolates radiusBase', () {
    final a = FwTokens(
      colors: FwTokens.light.colors,
      radii: FwTokens.light.radii,
      shadows: FwTokens.light.shadows,
      typography: FwTypographyTheme.standard,
      radiusBase: 0,
    );
    final b = FwTokens(
      colors: FwTokens.dark.colors,
      radii: FwTokens.dark.radii,
      shadows: FwTokens.dark.shadows,
      typography: FwTypographyTheme.standard,
      radiusBase: 10,
    );
    expect(FwTokens.lerp(a, b, 0.5).radiusBase, 5.0);
  });

  test('theme radii use the shadcn default base (10px) and stay in sync', () {
    expect(FwTokens.light.radiusBase, 10);
    // Derived from fromBase, not restated literals — cannot silently desync.
    expect(FwTokens.light.radii, const FwRadii.fromBase(10));
    expect(FwTokens.dark.radii, FwRadii.fromBase(FwTokens.dark.radiusBase));
  });

  test('lerp boundaries carry the whole non-color object intact', () {
    final lo = FwTokens.lerp(FwTokens.light, FwTokens.dark, 0);
    expect(lo.radiusBase, FwTokens.light.radiusBase);
    expect(lo.radii, FwTokens.light.radii);
    expect(lo.shadows, FwTokens.light.shadows);
    expect(lo.typography, FwTokens.light.typography);
    final hi = FwTokens.lerp(FwTokens.light, FwTokens.dark, 1);
    expect(hi.radiusBase, FwTokens.dark.radiusBase);
    expect(hi.radii, FwTokens.dark.radii);
  });
}

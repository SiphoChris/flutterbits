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
}

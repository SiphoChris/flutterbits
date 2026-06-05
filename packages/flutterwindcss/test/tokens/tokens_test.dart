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
}

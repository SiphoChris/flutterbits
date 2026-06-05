// test/tokens/palette_baked_test.dart
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/tokens/palette.g.dart';

void main() {
  test('baked palette has known Tailwind v4 sRGB values', () {
    expect(fwBakedPalette['blue-500'], const Color(0xFF2B7FFF));
    expect(fwBakedPalette['neutral-950'], const Color(0xFF0A0A0A));
    expect(fwBakedPalette['white'], const Color(0xFFFFFFFF));
  });

  test('every non-tone hue has all 11 shades', () {
    const shades = ['50', '100', '200', '300', '400', '500', '600', '700', '800', '900', '950'];
    for (final hue in ['neutral', 'blue']) {
      for (final s in shades) {
        expect(fwBakedPalette['$hue-$s'], isNotNull, reason: '$hue-$s missing');
      }
    }
  });
}

// White-box test of the GENERATED artifact palette.g.dart. Intentionally imports src/ to verify
// generation completeness; not a consumer-facing import.
// test/tokens/palette_baked_test.dart
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/tokens/palette.g.dart';

void main() {
  // Out-of-gamut contract (engine spec §4.1 / R4): the baked palette must match
  // Tailwind's PUBLISHED (gamut-clipped) hex, NOT a re-derived gamut-mapped value.
  // These saturated shades are out of the sRGB gamut, so the two methods differ —
  // pinning Tailwind's published hex guards against anyone "fixing" the palette by
  // gamut-mapping it (which would silently diverge from Tailwind). Values from
  // tailwindcss.com/docs/colors.
  test('out-of-gamut swatches match Tailwind published hex (not gamut-mapped)', () {
    expect(fwBakedPalette['orange-500'], const Color(0xFFFF6900));
    expect(fwBakedPalette['orange-400'], const Color(0xFFFF8904));
    expect(fwBakedPalette['amber-500'], const Color(0xFFFE9A00));
    expect(fwBakedPalette['fuchsia-500'], const Color(0xFFE12AFB));
    expect(fwBakedPalette['lime-400'], const Color(0xFF9AE600));
  });

  test('every non-tone hue has all 11 shades', () {
    const shades = <String>[
      '50',
      '100',
      '200',
      '300',
      '400',
      '500',
      '600',
      '700',
      '800',
      '900',
      '950',
    ];
    const hues = <String>[
      'slate',
      'gray',
      'zinc',
      'neutral',
      'stone',
      'red',
      'orange',
      'amber',
      'yellow',
      'lime',
      'green',
      'emerald',
      'teal',
      'cyan',
      'sky',
      'blue',
      'indigo',
      'violet',
      'purple',
      'fuchsia',
      'pink',
      'rose',
    ];
    for (final hue in hues) {
      for (final s in shades) {
        expect(fwBakedPalette['$hue-$s'], isNotNull, reason: '$hue-$s missing');
      }
    }
  });

  test('generated map is fully populated — black and white single-tone entries exist', () {
    expect(fwBakedPalette['black'], isNotNull);
    expect(fwBakedPalette['white'], isNotNull);
  });
}

// White-box test of the GENERATED artifact palette.g.dart. Intentionally imports src/ to verify
// generation completeness; not a consumer-facing import.
// test/tokens/palette_baked_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/tokens/palette.g.dart';

void main() {
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

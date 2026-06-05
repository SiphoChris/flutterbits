import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

void main() {
  test('FwPalette exposes hues and shades', () {
    expect(FwPalette.blue.shade500, const Color(0xFF2B7FFF));
    expect(FwPalette.neutral.shade950, const Color(0xFF0A0A0A));
  });

  test('FwPalette exposes single tones', () {
    expect(FwPalette.white, const Color(0xFFFFFFFF));
    expect(FwPalette.black, const Color(0xFF000000));
  });

  test('FwSwatch.shade(n) returns the exact shade', () {
    expect(FwPalette.blue.shade(500), FwPalette.blue.shade500);
    expect(FwPalette.blue.shade(950), FwPalette.blue.shade950);
  });

  test('FwSwatch.shade throws on an undefined shade (no silent black)', () {
    expect(() => FwPalette.blue.shade(550), throwsArgumentError);
    expect(() => FwPalette.blue.shade(1000), throwsArgumentError);
  });
}

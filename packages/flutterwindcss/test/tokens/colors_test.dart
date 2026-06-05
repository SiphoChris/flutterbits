import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

void main() {
  const a = FwColors(
    background: Color(0xFF000000),
    foreground: Color(0xFFFFFFFF),
    card: Color(0xFF000000),
    cardForeground: Color(0xFFFFFFFF),
    popover: Color(0xFF000000),
    popoverForeground: Color(0xFFFFFFFF),
    primary: Color(0xFF000000),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFF000000),
    secondaryForeground: Color(0xFFFFFFFF),
    muted: Color(0xFF000000),
    mutedForeground: Color(0xFFFFFFFF),
    accent: Color(0xFF000000),
    accentForeground: Color(0xFFFFFFFF),
    destructive: Color(0xFF000000),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0xFF000000),
    input: Color(0xFF000000),
    ring: Color(0xFF000000),
  );

  test('lerp(a, a, .5) == a for every field', () {
    final r = FwColors.lerp(a, a, 0.5);
    expect(r, a);
  });

  test('lerp interpolates primary halfway', () {
    final b = a.copyWith(primary: const Color(0xFFFFFFFF));
    final r = FwColors.lerp(a, b, 0.5);
    expect(r.primary, Color.lerp(const Color(0xFF000000), const Color(0xFFFFFFFF), 0.5));
  });
}

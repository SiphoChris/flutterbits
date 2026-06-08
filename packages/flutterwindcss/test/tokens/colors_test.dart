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
    chart1: Color(0xFF000000),
    chart2: Color(0xFF000000),
    chart3: Color(0xFF000000),
    chart4: Color(0xFF000000),
    chart5: Color(0xFF000000),
    sidebar: Color(0xFF000000),
    sidebarForeground: Color(0xFFFFFFFF),
    sidebarPrimary: Color(0xFF000000),
    sidebarPrimaryForeground: Color(0xFFFFFFFF),
    sidebarAccent: Color(0xFF000000),
    sidebarAccentForeground: Color(0xFFFFFFFF),
    sidebarBorder: Color(0xFF000000),
    sidebarRing: Color(0xFF000000),
  );

  test('lerp(a, a, .5) == a for every field', () {
    final r = FwColors.lerp(a, a, 0.5);
    expect(r, a);
  });

  test('chart + sidebar tokens participate in lerp / copyWith / == (the new '
      'shadcn vocabulary is fully wired, not just stored)', () {
    // copyWith touches a chart and a sidebar field → not equal, and the field
    // actually changed.
    final b = a.copyWith(chart3: const Color(0xFF112233), sidebarRing: const Color(0xFF445566));
    expect(b, isNot(a));
    expect(b.chart3, const Color(0xFF112233));
    expect(b.sidebarRing, const Color(0xFF445566));
    // lerp interpolates the new fields too (halfway between black and white).
    final mid = FwColors.lerp(a, a.copyWith(chart1: const Color(0xFFFFFFFF)), 0.5);
    expect(mid.chart1, Color.lerp(const Color(0xFF000000), const Color(0xFFFFFFFF), 0.5));
  });

  test('lerp interpolates primary halfway', () {
    final b = a.copyWith(primary: const Color(0xFFFFFFFF));
    final r = FwColors.lerp(a, b, 0.5);
    expect(r.primary, Color.lerp(const Color(0xFF000000), const Color(0xFFFFFFFF), 0.5));
  });

  test('lerp at t=0 returns a and t=1 returns b', () {
    final b = a.copyWith(primary: const Color(0xFFFFFFFF));
    expect(FwColors.lerp(a, b, 0), a);
    expect(FwColors.lerp(a, b, 1), b);
  });

  test('copyWith() with no args equals original; == is reflexive', () {
    expect(a.copyWith(), a);
    expect(a, a);
    expect(a.copyWith(primary: const Color(0xFFFFFFFF)), isNot(a));
  });
}

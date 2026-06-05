import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

/// Builds an FwShadows whose every step is [s] — handy for exercising lerp.
FwShadows _single(List<BoxShadow> s) =>
    FwShadows(xs2: s, xs: s, sm: s, md: s, lg: s, xl: s, xl2: s);

void main() {
  test('sm matches the Tailwind v4 two-layer shadow', () {
    final sm = FwShadows.defaults.sm;
    expect(sm, hasLength(2));
    expect(sm.first.offset, const Offset(0, 1));
    expect(sm.first.blurRadius, 3);
  });

  test('lerp blends layer-wise', () {
    final r = FwShadows.lerp(FwShadows.none, FwShadows.defaults, 0.5);
    expect(r.sm.first.color.a, closeTo(FwShadows.defaults.sm.first.color.a * 0.5, 0.001));
  });

  test('equality: defaults == defaults, defaults != none', () {
    expect(FwShadows.defaults, FwShadows.defaults);
    expect(FwShadows.defaults, isNot(FwShadows.none));
  });

  test('lerp interpolates geometry (offset + blur), not just alpha', () {
    final a = _single(const [BoxShadow(color: Color(0xFF000000))]);
    final b = _single(const [
      BoxShadow(color: Color(0xFF000000), offset: Offset(0, 10), blurRadius: 20),
    ]);
    final r = FwShadows.lerp(a, b, 0.5).sm.first;
    expect(r.offset, const Offset(0, 5));
    expect(r.blurRadius, 10);
  });

  test('lerp pads a shorter layer list when both sides are non-empty', () {
    final a = _single(const [BoxShadow(color: Color(0xFF000000), blurRadius: 4)]);
    final b = _single(const [
      BoxShadow(color: Color(0xFF000000), blurRadius: 4),
      BoxShadow(color: Color(0xFF000000), offset: Offset(0, 2), blurRadius: 8),
    ]);
    final r = FwShadows.lerp(a, b, 1).sm;
    expect(r, hasLength(2));
    expect(r[1].blurRadius, 8);
    expect(r[1].offset, const Offset(0, 2));
  });

  test('equality is field-sensitive (one differing layer)', () {
    final a = _single(const [BoxShadow(color: Color(0xFF000000), blurRadius: 4)]);
    final b = _single(const [BoxShadow(color: Color(0xFF000000), blurRadius: 8)]);
    expect(a, isNot(b));
  });
}

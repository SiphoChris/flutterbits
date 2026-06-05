import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

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
}

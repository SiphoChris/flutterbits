import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

void main() {
  test('fromBase derives the shadcn-style set', () {
    final r = FwRadii.fromBase(10);
    expect(r.sm, 6); // ×0.6
    expect(r.md, 8); // ×0.8
    expect(r.lg, 10); // ×1.0
    expect(r.xl, 14); // ×1.4
    expect(r.none, 0);
    expect(r.full, 9999);
  });

  test('lerp interpolates the base', () {
    final r = FwRadii.lerp(FwRadii.fromBase(0), FwRadii.fromBase(10), 0.5);
    expect(r.lg, 5);
  });

  test('FwRadiusScale exposes Tailwind named values', () {
    expect(FwRadiusScale.xs, 2);
    expect(FwRadiusScale.md, 6);
    expect(FwRadiusScale.xl2, 16);
    expect(FwRadiusScale.xl4, 32);
  });

  test('equality: fromBase(8) == fromBase(8), != fromBase(10)', () {
    expect(FwRadii.fromBase(8), FwRadii.fromBase(8));
    expect(FwRadii.fromBase(8), isNot(FwRadii.fromBase(10)));
  });
}

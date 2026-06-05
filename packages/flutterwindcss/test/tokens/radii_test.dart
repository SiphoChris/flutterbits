import 'package:flutterwindcss/flutterwindcss.dart';
import 'package:flutter_test/flutter_test.dart';

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
}

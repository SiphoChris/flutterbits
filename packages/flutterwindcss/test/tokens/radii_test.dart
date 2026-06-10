import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

void main() {
  group('non-negative guards (a negative radius crashes the framework painter)', () {
    test('FwRadii rejects a negative step', () {
      // Non-const so the assert fires at runtime (a const invocation would fail
      // const-evaluation at compile time instead).
      expect(() => FwRadii(base: 10, sm: -1, md: 8, lg: 10, xl: 14), throwsAssertionError);
      expect(() => FwRadii.fromBase(-1), throwsAssertionError);
      // A valid (clamped) set passes — the additive sm = base − 4 clamped at 0.
      expect(const FwRadii(base: 2, sm: 0, md: 0, lg: 2, xl: 6).sm, 0);
    });

    test('FwTokens rejects a negative radiusBase', () {
      expect(
        () => FwTokens(
          colors: FwTokens.light.colors,
          radii: const FwRadii.fromBase(10),
          shadows: FwTokens.light.shadows,
          typography: FwTokens.light.typography,
          radiusBase: -1,
        ),
        throwsAssertionError,
      );
    });
  });

  test('fromBase derives the shadcn-style set', () {
    const r = FwRadii.fromBase(10);
    expect(r.sm, 6); // ×0.6
    expect(r.md, 8); // ×0.8
    expect(r.lg, 10); // ×1.0
    expect(r.xl, 14); // ×1.4
    expect(r.none, 0);
    expect(r.full, 9999);
  });

  test('lerp interpolates the base', () {
    final r = FwRadii.lerp(const FwRadii.fromBase(0), const FwRadii.fromBase(10), 0.5);
    expect(r.lg, 5);
  });

  test('FwRadiusScale exposes Tailwind named values', () {
    expect(FwRadiusScale.xs, 2);
    expect(FwRadiusScale.md, 6);
    expect(FwRadiusScale.xl2, 16);
    expect(FwRadiusScale.xl4, 32);
  });

  test('equality: fromBase(8) == fromBase(8), != fromBase(10)', () {
    expect(const FwRadii.fromBase(8), const FwRadii.fromBase(8));
    expect(const FwRadii.fromBase(8), isNot(const FwRadii.fromBase(10)));
  });
}

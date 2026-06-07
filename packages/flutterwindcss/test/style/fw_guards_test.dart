import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/fw_style.dart';

// Guards (audit, pre-docs): the dev-facing setters that previously fell through
// to a terse framework assert now fail with a clear `flutterwindcss:` message —
// matching the engine's existing negative-width/radius/range guards. Negative
// margins are a real Tailwind feature that is NOT YET supported (margin renders
// via Padding, which requires non-negative insets), so it asserts with guidance
// rather than crashing cryptically.
void main() {
  test('aspect must be > 0', () {
    expect(() => const FwStyle().aspect(0), throwsA(isA<AssertionError>()));
    expect(() => const FwStyle().aspect(-1), throwsA(isA<AssertionError>()));
    expect(const FwStyle().aspect(1.5).aspectRatio, 1.5); // valid passes
  });

  test('wFraction / hFraction must be >= 0 (but may exceed 1, e.g. w-[150%])', () {
    expect(() => const FwStyle().wFraction(-0.5), throwsA(isA<AssertionError>()));
    expect(() => const FwStyle().hFraction(-0.1), throwsA(isA<AssertionError>()));
    expect(const FwStyle().wFraction(1.5).widthFactor, 1.5); // >1 is valid
  });

  test('padding units must be >= 0', () {
    expect(() => const FwStyle().p(-1), throwsA(isA<AssertionError>()));
    expect(() => const FwStyle().px(-2), throwsA(isA<AssertionError>()));
    expect(() => const FwStyle().pt(-3), throwsA(isA<AssertionError>()));
  });

  test('sizing units must be >= 0', () {
    expect(() => const FwStyle().w(-1), throwsA(isA<AssertionError>()));
    expect(() => const FwStyle().h(-1), throwsA(isA<AssertionError>()));
    expect(() => const FwStyle().size(-1), throwsA(isA<AssertionError>()));
    expect(() => const FwStyle().minW(-1), throwsA(isA<AssertionError>()));
    expect(() => const FwStyle().maxH(-1), throwsA(isA<AssertionError>()));
  });

  test('negative margins assert (not yet supported — Padding limitation)', () {
    expect(() => const FwStyle().m(-1), throwsA(isA<AssertionError>()));
    expect(() => const FwStyle().mx(-2), throwsA(isA<AssertionError>()));
    expect(() => const FwStyle().mt(-3), throwsA(isA<AssertionError>()));
    // Non-negative margins still work.
    expect(const FwStyle().m(2).margin!.top, 8);
  });
}

import 'package:flutter/widgets.dart';
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

  // Transform inputs feed a Matrix4; a non-finite scalar (NaN/±Infinity) would
  // silently corrupt the matrix AND hit-testing, with no framework error. These
  // guard every scalar that reaches the transform matrix (module 9/13/17).
  group('transform inputs must be finite', () {
    for (final v in <double>[double.nan, double.infinity, double.negativeInfinity]) {
      test('scale family rejects $v', () {
        expect(() => const FwStyle().scale(v), throwsAssertionError);
        expect(() => const FwStyle().scaleX(v), throwsAssertionError);
        expect(() => const FwStyle().scaleY(v), throwsAssertionError);
      });
      test('rotate family rejects $v', () {
        expect(() => const FwStyle().rotate(v), throwsAssertionError);
        expect(() => const FwStyle().rotateX(v), throwsAssertionError);
        expect(() => const FwStyle().rotateY(v), throwsAssertionError);
      });
      test('skew + translate reject $v', () {
        expect(() => const FwStyle().skewX(v), throwsAssertionError);
        expect(() => const FwStyle().skewY(v), throwsAssertionError);
        expect(() => const FwStyle().translate(v, 0), throwsAssertionError);
        expect(() => const FwStyle().translate(0, v), throwsAssertionError);
        expect(() => const FwStyle().translateX(v), throwsAssertionError);
        expect(() => const FwStyle().translateY(v), throwsAssertionError);
      });
    }

    test('finite transforms still pass (scale 0 and negative are valid)', () {
      expect(const FwStyle().scale(0).scaleFactor, 0);
      expect(const FwStyle().scale(-1).scaleFactor, -1);
      expect(const FwStyle().rotate(45).rotation, isNotNull);
    });
  });

  test('tracking must be finite (negative still allowed)', () {
    expect(() => const FwStyle().tracking(double.nan), throwsAssertionError);
    expect(() => const FwStyle().tracking(double.infinity), throwsAssertionError);
    expect(const FwStyle().tracking(-0.5).letterSpacing, -0.5); // tighter is valid
  });

  test('gradient stops length must match colors length', () {
    // 3 colors, 2 stops -> mismatch asserts at the call site (not at paint).
    expect(
      () => const FwStyle().bgLinear(
        colors: const <Color>[Color(0xFF000000), Color(0xFFFFFFFF), Color(0xFFFF0000)],
        stops: const <double>[0, 1],
      ),
      throwsAssertionError,
    );
    // Matching lengths pass; null stops pass.
    expect(
      const FwStyle()
          .bgLinear(
            colors: const <Color>[Color(0xFF000000), Color(0xFFFFFFFF)],
            stops: const <double>[0, 1],
          )
          .gradient,
      isNotNull,
    );
  });
}

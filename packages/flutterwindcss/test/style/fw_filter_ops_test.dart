import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/fw_style.dart';

void main() {
  group('color filters (module 12)', () {
    test('saturate(1) is the identity colour matrix', () {
      final m = const FwStyle().saturate(1).colorMatrix!;
      expect(m.length, 20);
      expect(m[0], moreOrLessEquals(1, epsilon: 1e-9)); // R diagonal
      expect(m[6], moreOrLessEquals(1, epsilon: 1e-9)); // G diagonal
      expect(m[12], moreOrLessEquals(1, epsilon: 1e-9)); // B diagonal
      expect(m[18], moreOrLessEquals(1, epsilon: 1e-9)); // A diagonal
      expect(m[1], moreOrLessEquals(0, epsilon: 1e-9)); // off-diagonal
    });

    test('grayscale(1) collapses every RGB row to the luma weights', () {
      final m = const FwStyle().grayscale().colorMatrix!;
      for (final row in <int>[0, 5, 10]) {
        expect(m[row + 0], moreOrLessEquals(0.213, epsilon: 1e-6));
        expect(m[row + 1], moreOrLessEquals(0.715, epsilon: 1e-6));
        expect(m[row + 2], moreOrLessEquals(0.072, epsilon: 1e-6));
      }
    });

    test('brightness composes multiplicatively (2 then 2 = 4 on the diagonal)', () {
      final m = const FwStyle().brightness(2).brightness(2).colorMatrix!;
      expect(m[0], moreOrLessEquals(4, epsilon: 1e-9));
      expect(m[6], moreOrLessEquals(4, epsilon: 1e-9));
      expect(m[12], moreOrLessEquals(4, epsilon: 1e-9));
    });

    test('contrast sets slope + bias (out = c·in + 127.5·(1-c))', () {
      final m = const FwStyle().contrast(0.5).colorMatrix!;
      expect(m[0], moreOrLessEquals(0.5, epsilon: 1e-9)); // slope
      expect(m[4], moreOrLessEquals(63.75, epsilon: 1e-6)); // bias on R row
    });

    test('hueRotate(0) is the identity colour matrix', () {
      final m = const FwStyle().hueRotate(0).colorMatrix!;
      expect(m.length, 20);
      // A 0° hue rotation leaves luminance + chrominance untouched: diagonal 1,
      // off-diagonal 0, no bias.
      expect(m[0], moreOrLessEquals(1, epsilon: 1e-6)); // R diagonal
      expect(m[6], moreOrLessEquals(1, epsilon: 1e-6)); // G diagonal
      expect(m[12], moreOrLessEquals(1, epsilon: 1e-6)); // B diagonal
      expect(m[1], moreOrLessEquals(0, epsilon: 1e-6)); // off-diagonal
      expect(m[4], moreOrLessEquals(0, epsilon: 1e-6)); // no R bias
    });

    test('hueRotate(360) returns to the identity (full turn)', () {
      final m = const FwStyle().hueRotate(360).colorMatrix!;
      expect(m[0], moreOrLessEquals(1, epsilon: 1e-6));
      expect(m[1], moreOrLessEquals(0, epsilon: 1e-6));
    });

    test('hueRotate composes with another filter (matrix is non-identity)', () {
      final m = const FwStyle().hueRotate(90).colorMatrix!;
      // 90° genuinely mixes channels — at least one off-diagonal is non-zero.
      expect(m[1].abs() + m[2].abs(), greaterThan(0.1));
    });

    test('invert(1) negates the diagonal and biases by 255 (full inversion)', () {
      final m = const FwStyle().invert(1).colorMatrix!;
      expect(m[0], moreOrLessEquals(-1, epsilon: 1e-9)); // R diagonal: 1 - 2·1
      expect(m[6], moreOrLessEquals(-1, epsilon: 1e-9)); // G diagonal
      expect(m[12], moreOrLessEquals(-1, epsilon: 1e-9)); // B diagonal
      expect(m[4], moreOrLessEquals(255, epsilon: 1e-6)); // R bias: 255·1
      expect(m[9], moreOrLessEquals(255, epsilon: 1e-6)); // G bias
      expect(m[14], moreOrLessEquals(255, epsilon: 1e-6)); // B bias
    });

    test('invert(0) is the identity (no inversion)', () {
      final m = const FwStyle().invert(0).colorMatrix!;
      expect(m[0], moreOrLessEquals(1, epsilon: 1e-9));
      expect(m[4], moreOrLessEquals(0, epsilon: 1e-9)); // no bias
    });

    test('sepia(1) applies the published sepia coefficients on the R row', () {
      final m = const FwStyle().sepia(1).colorMatrix!;
      expect(m[0], moreOrLessEquals(0.393, epsilon: 1e-6));
      expect(m[1], moreOrLessEquals(0.769, epsilon: 1e-6));
      expect(m[2], moreOrLessEquals(0.189, epsilon: 1e-6));
    });

    test('sepia(0) is the identity (R row is 1,0,0)', () {
      final m = const FwStyle().sepia(0).colorMatrix!;
      expect(m[0], moreOrLessEquals(1, epsilon: 1e-9));
      expect(m[1], moreOrLessEquals(0, epsilon: 1e-9));
      expect(m[2], moreOrLessEquals(0, epsilon: 1e-9));
    });

    test('guards: grayscale/invert/sepia are 0..1; brightness/contrast/saturate >= 0', () {
      expect(() => const FwStyle().grayscale(2), throwsAssertionError);
      expect(() => const FwStyle().invert(-0.1), throwsAssertionError);
      expect(() => const FwStyle().sepia(1.5), throwsAssertionError);
      expect(() => const FwStyle().brightness(-1), throwsAssertionError);
      expect(() => const FwStyle().contrast(-1), throwsAssertionError);
      expect(() => const FwStyle().saturate(-1), throwsAssertionError);
    });

    test('guard: hueRotate degrees must be finite (NaN/Infinity assert)', () {
      expect(() => const FwStyle().hueRotate(double.nan), throwsAssertionError);
      expect(() => const FwStyle().hueRotate(double.infinity), throwsAssertionError);
    });
  });

  group('object-fit (module 12)', () {
    test('fit writes boxFit (last-wins); setter is `fit`, field is `boxFit`', () {
      expect(const FwStyle().fit(BoxFit.cover).boxFit, BoxFit.cover);
      expect(const FwStyle().fit(BoxFit.cover).fit(BoxFit.contain).boxFit, BoxFit.contain);
    });
  });
}

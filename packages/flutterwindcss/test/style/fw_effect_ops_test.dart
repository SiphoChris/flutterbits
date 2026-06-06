import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/fw_style.dart';
import 'package:flutterwindcss/src/tokens/scales.dart';
import 'package:flutterwindcss/src/tokens/shadows.dart';

void main() {
  group('effect setters', () {
    test('shadow writes the boxShadow list (last-wins)', () {
      final md = FwShadows.defaults.md;
      expect(const FwStyle().shadow(md).boxShadow, md);
      final lg = FwShadows.defaults.lg;
      expect(const FwStyle().shadow(md).shadow(lg).boxShadow, lg);
    });

    test('opacity writes groupOpacity (accepts fwOpacity helper)', () {
      expect(const FwStyle().opacity(0.5).groupOpacity, 0.5);
      expect(const FwStyle().opacity(fwOpacity(40)).groupOpacity, 0.4);
    });

    test('blur writes contentBlur; backdropBlur writes backdropBlurSigma', () {
      expect(const FwStyle().blur(8).contentBlur, 8);
      expect(const FwStyle().backdropBlur(12).backdropBlurSigma, 12);
    });
  });

  group('guards', () {
    test('opacity out of 0..1 asserts', () {
      expect(() => const FwStyle().opacity(-0.1), throwsAssertionError);
      expect(() => const FwStyle().opacity(1.1), throwsAssertionError);
    });

    test('negative blur / backdropBlur asserts', () {
      expect(() => const FwStyle().blur(-1), throwsAssertionError);
      expect(() => const FwStyle().backdropBlur(-1), throwsAssertionError);
    });

    test('opacity 0 and 1 and zero blur are allowed', () {
      expect(const FwStyle().opacity(0).groupOpacity, 0);
      expect(const FwStyle().opacity(1).groupOpacity, 1);
      expect(const FwStyle().blur(0).contentBlur, 0);
    });
  });
}

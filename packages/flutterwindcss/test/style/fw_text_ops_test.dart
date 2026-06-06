import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/fw_style.dart';
import 'package:flutterwindcss/src/tokens/typography.dart';

const _c = Color(0xFF112233);

void main() {
  group('value setters', () {
    test('text writes foreground', () {
      expect(const FwStyle().text(_c).foreground, _c);
    });

    test('textSize writes fontSize in logical px (last-wins)', () {
      expect(const FwStyle().textSize(18).fontSize, 18);
      expect(const FwStyle().textSize(18).textSize(24).fontSize, 24);
      expect(const FwStyle().textSize(FwFontSize.lg.px).fontSize, 18);
    });

    test('weight maps the CSS int scale to FontWeight', () {
      expect(const FwStyle().weight(700).fontWeight, FontWeight.w700);
      expect(const FwStyle().weight(FwFontWeight.semibold).fontWeight, FontWeight.w600);
      expect(const FwStyle().weight(100).fontWeight, FontWeight.w100);
      expect(const FwStyle().weight(900).fontWeight, FontWeight.w900);
    });

    test('leading writes the line-height multiple', () {
      expect(const FwStyle().leading(1.5).lineHeight, 1.5);
      expect(const FwStyle().leading(FwLeading.tight).lineHeight, 1.25);
    });

    test('tracking writes letterSpacing and may be negative', () {
      expect(const FwStyle().tracking(0.5).letterSpacing, 0.5);
      expect(const FwStyle().tracking(-0.4).letterSpacing, -0.4);
    });

    test('align writes textAlign', () {
      expect(const FwStyle().align(TextAlign.center).textAlign, TextAlign.center);
    });
  });

  group('guards', () {
    test('non-positive font size asserts', () {
      expect(() => const FwStyle().textSize(0), throwsAssertionError);
      expect(() => const FwStyle().textSize(-1), throwsAssertionError);
    });

    test('non-positive leading asserts', () {
      expect(() => const FwStyle().leading(0), throwsAssertionError);
    });

    test('out-of-range / unstepped weight asserts', () {
      expect(() => const FwStyle().weight(50), throwsAssertionError);
      expect(() => const FwStyle().weight(1000), throwsAssertionError);
      expect(() => const FwStyle().weight(450), throwsAssertionError);
    });
  });
}

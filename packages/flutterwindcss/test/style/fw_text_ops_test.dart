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

    test('out-of-range / unstepped weight throws ArgumentError (release-safe, not assert)', () {
      // A throw (not an assert) so the guard survives release mode — the value
      // indexes a fixed-length list and a stripped assert would crash with an
      // opaque RangeError instead of this clear message.
      expect(() => const FwStyle().weight(50), throwsArgumentError);
      expect(() => const FwStyle().weight(1000), throwsArgumentError);
      expect(() => const FwStyle().weight(450), throwsArgumentError);
      expect(() => const FwStyle().weight(0), throwsArgumentError);
    });
  });

  group('decoration', () {
    test('underline / lineThrough set their decoration', () {
      expect(const FwStyle().underline.textDecoration, TextDecoration.underline);
      expect(const FwStyle().lineThrough.textDecoration, TextDecoration.lineThrough);
    });

    test('underline + lineThrough combine (both present, order-independent)', () {
      final a = const FwStyle().underline.lineThrough.textDecoration!;
      final b = const FwStyle().lineThrough.underline.textDecoration!;
      for (final d in <TextDecoration>[a, b]) {
        expect(d.contains(TextDecoration.underline), isTrue);
        expect(d.contains(TextDecoration.lineThrough), isTrue);
      }
    });

    test('repeating a decoration is idempotent', () {
      expect(const FwStyle().underline.underline.textDecoration, TextDecoration.underline);
    });
  });
}

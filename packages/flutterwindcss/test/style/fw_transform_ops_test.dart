import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/fw_style.dart';

void main() {
  group('transform setters (write the renamed FwStyle fields)', () {
    test('scale writes scaleFactor (last-wins)', () {
      expect(const FwStyle().scale(1.5).scaleFactor, 1.5);
      expect(const FwStyle().scale(1.5).scale(2).scaleFactor, 2);
    });

    test('rotate stores degrees as radians', () {
      expect(const FwStyle().rotate(180).rotation, closeTo(math.pi, 1e-9));
      expect(const FwStyle().rotate(90).rotation, closeTo(math.pi / 2, 1e-9));
    });

    test('translate writes translation as an Offset in logical px (utility units × 4)', () {
      expect(const FwStyle().translate(2, 3).translation, const Offset(8, 12));
    });

    test('translateX / translateY merge per-axis, keeping the other axis', () {
      // translate(2,3) then translateX(5): x→20, y stays 12.
      expect(const FwStyle().translate(2, 3).translateX(5).translation, const Offset(20, 12));
      // translateY on a fresh style keeps x at 0.
      expect(const FwStyle().translateY(4).translation, const Offset(0, 16));
    });
  });
}

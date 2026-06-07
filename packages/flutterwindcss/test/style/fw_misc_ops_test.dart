import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/fw_style.dart';

void main() {
  group('transform extras (module 13)', () {
    test('scaleX / scaleY write per-axis fields (independent of uniform scale)', () {
      expect(const FwStyle().scaleX(2).scaleXFactor, 2);
      expect(const FwStyle().scaleY(3).scaleYFactor, 3);
      expect(const FwStyle().scaleX(2).scaleX(4).scaleXFactor, 4); // last-wins
    });

    test('skewX / skewY store radians from degrees', () {
      expect(const FwStyle().skewX(45).skewXAngle, moreOrLessEquals(math.pi / 4, epsilon: 1e-9));
      expect(const FwStyle().skewY(90).skewYAngle, moreOrLessEquals(math.pi / 2, epsilon: 1e-9));
    });

    test('transformOrigin writes the alignment', () {
      expect(
        const FwStyle().transformOrigin(AlignmentDirectional.topStart).transformAlignment,
        AlignmentDirectional.topStart,
      );
    });
  });

  group('interactivity (module 13)', () {
    test('cursor writes the mouse cursor (setter `cursor`, field `mouseCursor`)', () {
      expect(
        const FwStyle().cursor(SystemMouseCursors.click).mouseCursor,
        SystemMouseCursors.click,
      );
    });

    test('pointerEventsNone sets ignorePointer', () {
      expect(const FwStyle().pointerEventsNone.ignorePointer, isTrue);
    });

    test('invisible / visible toggle visibility (keep layout space)', () {
      expect(const FwStyle().invisible.isVisible, isFalse);
      expect(const FwStyle().visible.isVisible, isTrue);
    });
  });

  group('typography italic + size sugar (module 13)', () {
    test('italic / notItalic set fontStyle', () {
      expect(const FwStyle().italic.fontStyle, FontStyle.italic);
      expect(const FwStyle().notItalic.fontStyle, FontStyle.normal);
    });

    test('size sets width and height together (utility units)', () {
      final s = const FwStyle().size(10);
      expect(s.width, 40); // 10 × 4 px
      expect(s.height, 40);
    });
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart' show fwSpace;
import 'package:flutterwindcss/src/style/fw_style.dart';

void main() {
  group('margin', () {
    test('m sets every edge; ms/me/mt/mb set one edge', () {
      expect(const FwStyle().m(3).margin, EdgeInsetsDirectional.all(fwSpace(3)));
      expect(const FwStyle().ms(1).margin!.start, fwSpace(1));
      expect(const FwStyle().me(1).margin!.end, fwSpace(1));
      expect(const FwStyle().mt(1).margin!.top, fwSpace(1));
      expect(const FwStyle().mb(1).margin!.bottom, fwSpace(1));
    });

    test('mx sets horizontal margin in logical px; last-wins on repeat', () {
      final s = const FwStyle().mx(4).mx(2);
      expect(s.margin!.start, fwSpace(2));
      expect(s.margin!.end, fwSpace(2));
      expect(s.margin!.top, 0);
    });

    test('mx then my keeps both axes (per-edge merge)', () {
      final s = const FwStyle().mx(4).my(2);
      expect(s.margin!.start, fwSpace(4));
      expect(s.margin!.end, fwSpace(4));
      expect(s.margin!.top, fwSpace(2));
      expect(s.margin!.bottom, fwSpace(2));
    });

    test('margin and padding are independent fields', () {
      final s = const FwStyle().p(2).m(4);
      expect(s.padding, EdgeInsetsDirectional.all(fwSpace(2)));
      expect(s.margin, EdgeInsetsDirectional.all(fwSpace(4)));
    });
  });

  group('fixed / min / max sizing', () {
    test('w/h write width/height in logical px', () {
      expect(const FwStyle().w(20).width, fwSpace(20));
      expect(const FwStyle().h(10).height, fwSpace(10));
    });

    test('minW/minH/maxW/maxH write the matching constraint field', () {
      expect(const FwStyle().minW(4).minWidth, fwSpace(4));
      expect(const FwStyle().minH(4).minHeight, fwSpace(4));
      expect(const FwStyle().maxW(8).maxWidth, fwSpace(8));
      expect(const FwStyle().maxH(8).maxHeight, fwSpace(8));
    });

    test('each sizing setter is last-wins on its own field', () {
      expect(const FwStyle().w(20).w(10).width, fwSpace(10));
      expect(const FwStyle().maxW(8).maxW(4).maxWidth, fwSpace(4));
    });

    test('width and height are independent fields', () {
      final s = const FwStyle().w(20).h(10);
      expect(s.width, fwSpace(20));
      expect(s.height, fwSpace(10));
    });
  });

  group('fractional / full sizing', () {
    test('wFull/hFull write a factor of 1.0', () {
      expect(const FwStyle().wFull.widthFactor, 1.0);
      expect(const FwStyle().hFull.heightFactor, 1.0);
    });

    test('wFraction/hFraction write the given factor', () {
      expect(const FwStyle().wFraction(0.5).widthFactor, 0.5);
      expect(const FwStyle().hFraction(0.25).heightFactor, 0.25);
    });

    test('fraction without align leaves factorAlignment unset', () {
      expect(const FwStyle().wFraction(0.5).factorAlignment, isNull);
    });

    test('fraction align sets factorAlignment', () {
      final s = const FwStyle().wFraction(0.5, align: AlignmentDirectional.topEnd);
      expect(s.widthFactor, 0.5);
      expect(s.factorAlignment, AlignmentDirectional.topEnd);
    });
  });

  group('aspect ratio', () {
    test('aspect writes aspectRatio', () {
      expect(const FwStyle().aspect(16 / 9).aspectRatio, 16 / 9);
    });

    test('square writes aspectRatio 1 and last-wins against aspect', () {
      expect(const FwStyle().square.aspectRatio, 1.0);
      // square is sugar for the same field, so it overwrites a prior aspect().
      expect(const FwStyle().aspect(16 / 9).square.aspectRatio, 1.0);
      // ...and aspect() overwrites a prior square (same field, last-wins).
      expect(const FwStyle().square.aspect(2).aspectRatio, 2.0);
    });
  });
}

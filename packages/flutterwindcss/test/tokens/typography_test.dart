import 'package:flutterwindcss/flutterwindcss.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('font sizes match Tailwind v4 (16px root)', () {
    expect(FwFontSize.base.px, 16); // 1rem
    expect(FwFontSize.sm.px, 14); // .875rem
    expect(FwFontSize.xl2.px, 24); // 1.5rem
  });

  test('base size carries its paired line-height ratio', () {
    expect(FwFontSize.base.lineHeight, closeTo(1.5, 0.0001));
  });

  test('weights and tracking expose Tailwind values', () {
    expect(FwFontWeight.semibold, 600);
    expect(FwTracking.tight, -0.025);
    expect(FwLeading.normal, 1.5);
  });
}

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Module 17 — visual completeness: background-image, 3D transforms
// (rotateX/rotateY + perspective), text-shadow, and mix-blend-mode.
const _img = AssetImage('x');

Widget _wrap(Widget c) => Directionality(textDirection: TextDirection.ltr, child: c);

BoxDecoration? _deco(WidgetTester t) {
  for (final d in t.widgetList<DecoratedBox>(find.byType(DecoratedBox))) {
    if (d.decoration is BoxDecoration) return d.decoration as BoxDecoration;
  }
  return null;
}

void main() {
  // ---- background-image ----
  test('bgImage stores a DecorationImage with fit/alignment/repeat', () {
    final s = const FwStyle().bgImage(_img, fit: BoxFit.cover, repeat: ImageRepeat.repeatX);
    expect(s.backgroundImage, isNotNull);
    expect(s.backgroundImage!.fit, BoxFit.cover);
    expect(s.backgroundImage!.repeat, ImageRepeat.repeatX);
  });

  testWidgets('bgImage renders as the decoration image', (t) async {
    await t.pumpWidget(
      _wrap(const SizedBox(width: 40, height: 40).tw.bgImage(_img, fit: BoxFit.cover)),
    );
    expect(_deco(t)!.image, isNotNull);
    expect(_deco(t)!.image!.fit, BoxFit.cover);
    t.takeException(); // the fake 'x' asset fails to load async — expected, clear it.
  });

  // ---- 3D transforms ----
  test('rotateX/rotateY store radians; perspective stored', () {
    final s = const FwStyle().rotateX(90).rotateY(45).perspective(800);
    expect(s.rotateXAngle, moreOrLessEquals(math.pi / 2, epsilon: 1e-9));
    expect(s.rotateYAngle, moreOrLessEquals(math.pi / 4, epsilon: 1e-9));
    expect(s.perspectiveDepth, 800);
  });

  testWidgets('perspective sets the projection entry (3,2) = -1/depth', (t) async {
    await t.pumpWidget(_wrap(const SizedBox(width: 40, height: 40).tw.perspective(500)));
    final xf = t.widget<Transform>(find.byType(Transform));
    expect(xf.transform.entry(3, 2), moreOrLessEquals(-1 / 500, epsilon: 1e-9));
  });

  testWidgets('rotateY rotates about the Y axis (m[0][0] = cos)', (t) async {
    await t.pumpWidget(_wrap(const SizedBox(width: 40, height: 40).tw.rotateY(45)));
    final xf = t.widget<Transform>(find.byType(Transform));
    expect(xf.transform.entry(0, 0), moreOrLessEquals(math.cos(math.pi / 4), epsilon: 1e-9));
  });

  test('perspective must be > 0', () {
    expect(() => const FwStyle().perspective(0), throwsA(isA<AssertionError>()));
  });

  // ---- text-shadow ----
  test('textShadow stores the shadow list', () {
    const shadows = <Shadow>[Shadow(color: Color(0xFF000000), blurRadius: 2)];
    expect(const FwStyle().textShadow(shadows).textShadows, shadows);
  });

  testWidgets('textShadow flows into DefaultTextStyle', (t) async {
    const shadows = <Shadow>[Shadow(color: Color(0xFF000000), blurRadius: 2, offset: Offset(1, 1))];
    await t.pumpWidget(_wrap(const Text('hi').tw.textShadow(shadows)));
    final dts = t.widget<DefaultTextStyle>(find.byType(DefaultTextStyle).first);
    expect(dts.style.shadows, shadows);
  });

  // ---- mix-blend-mode ----
  test('blendMode stores the mode', () {
    expect(const FwStyle().blendMode(BlendMode.multiply).mixBlendMode, BlendMode.multiply);
  });

  testWidgets('blendMode wraps the box in a blend layer', (t) async {
    await t.pumpWidget(
      _wrap(
        const SizedBox(
          width: 40,
          height: 40,
        ).tw.bg(const Color(0xFFFF0000)).blendMode(BlendMode.multiply),
      ),
    );
    expect(find.byType(FwBlendMode), findsOneWidget);
    expect(t.widget<FwBlendMode>(find.byType(FwBlendMode)).blendMode, BlendMode.multiply);
  });
}

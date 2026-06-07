import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';
import 'package:flutterwindcss/src/style/fw_ring.dart';

// Module 15 — `ring`: a Tailwind focus-ring as a zero-blur, spread box-shadow in
// the ring color (the dev passes the color, normally context.fw.colors.ring), so
// it is context-free. With an offset, a second shadow in the offset colour sits
// between the box and the ring. Ring composes WITH any drop `shadow` (both render).
const _ring = Color(0xFF3B82F6);
const _bg = Color(0xFF0A0A0A);

List<BoxShadow> _shadows(WidgetTester t) {
  for (final d in t.widgetList<DecoratedBox>(find.byType(DecoratedBox))) {
    final deco = d.decoration;
    if (deco is BoxDecoration && deco.boxShadow != null && deco.boxShadow!.isNotEmpty) {
      return deco.boxShadow!;
    }
  }
  return const <BoxShadow>[];
}

Widget _wrap(Widget c) => Directionality(textDirection: TextDirection.ltr, child: c);

void main() {
  test('ring stores a FwRing spec (width + color)', () {
    final s = const FwStyle().ring(2, color: _ring);
    expect(s.ringSpec, const FwRing(width: 2, color: _ring));
  });

  test('ring requires width >= 0', () {
    expect(() => const FwStyle().ring(-1, color: _ring), throwsA(isA<AssertionError>()));
  });

  testWidgets('ring renders a zero-blur spread shadow in the ring color', (t) async {
    await t.pumpWidget(
      _wrap(const SizedBox(width: 40, height: 40).tw.bg(_bg).ring(3, color: _ring)),
    );
    final shadows = _shadows(t);
    expect(shadows, isNotEmpty);
    final ring = shadows.firstWhere((s) => s.color == _ring);
    expect(ring.spreadRadius, 3);
    expect(ring.blurRadius, 0);
  });

  testWidgets('ring with offset adds an inner offset shadow then the ring', (t) async {
    const offsetColor = Color(0xFFFFFFFF);
    await t.pumpWidget(
      _wrap(
        const SizedBox(
          width: 40,
          height: 40,
        ).tw.bg(_bg).ring(2, color: _ring, offset: 2, offsetColor: offsetColor),
      ),
    );
    final shadows = _shadows(t);
    // Offset shadow (offsetColor, spread = offset) before the ring (spread = offset+width).
    expect(shadows.any((s) => s.color == offsetColor && s.spreadRadius == 2), isTrue);
    expect(shadows.any((s) => s.color == _ring && s.spreadRadius == 4), isTrue);
  });

  testWidgets('ring composes WITH a drop shadow (both render)', (tester) async {
    await tester.pumpWidget(
      _wrap(
        FwTheme(
          tokens: FwTokens.light,
          child: Builder(
            builder: (context) {
              final fw = context.fw;
              return const SizedBox(
                width: 40,
                height: 40,
              ).tw.bg(_bg).shadow(fw.shadows.md).ring(2, color: _ring);
            },
          ),
        ),
      ),
    );
    final shadows = _shadows(tester);
    expect(shadows.any((s) => s.color == _ring), isTrue, reason: 'ring present');
    expect(shadows.length, greaterThan(1), reason: 'drop shadow(s) also present');
  });
}

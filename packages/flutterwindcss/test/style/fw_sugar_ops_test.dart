import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/fw_style.dart';

// Module 15 — gradient direction sugar (context-free; the dev supplies colors,
// usually from context.fw.colors). Directions are RTL-aware: `toEnd`/`toStart`
// use AlignmentDirectional, so a "to-r" gradient flows toward the reading end and
// flips under RTL (better than Tailwind's physical `to-r`).
const _c1 = Color(0xFF111111);
const _c2 = Color(0xFF222222);

LinearGradient _grad(FwStyle s) => s.gradient! as LinearGradient;

void main() {
  test('bgGradientToEnd flows start -> end (RTL-aware)', () {
    final g = _grad(const FwStyle().bgGradientToEnd(<Color>[_c1, _c2]));
    expect(g.begin, AlignmentDirectional.centerStart);
    expect(g.end, AlignmentDirectional.centerEnd);
    expect(g.colors, <Color>[_c1, _c2]);
  });

  test('bgGradientToStart flows end -> start', () {
    final g = _grad(const FwStyle().bgGradientToStart(<Color>[_c1, _c2]));
    expect(g.begin, AlignmentDirectional.centerEnd);
    expect(g.end, AlignmentDirectional.centerStart);
  });

  test('bgGradientToBottom / toTop are vertical', () {
    expect(_grad(const FwStyle().bgGradientToBottom(<Color>[_c1, _c2])).begin, Alignment.topCenter);
    expect(
      _grad(const FwStyle().bgGradientToBottom(<Color>[_c1, _c2])).end,
      Alignment.bottomCenter,
    );
    expect(_grad(const FwStyle().bgGradientToTop(<Color>[_c1, _c2])).begin, Alignment.bottomCenter);
  });

  test('diagonal directions use directional corners', () {
    final g = _grad(const FwStyle().bgGradientToBottomEnd(<Color>[_c1, _c2]));
    expect(g.begin, AlignmentDirectional.topStart);
    expect(g.end, AlignmentDirectional.bottomEnd);
  });

  test('bgLinear passes begin/end/colors/stops through', () {
    final g = _grad(
      const FwStyle().bgLinear(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: <Color>[_c1, _c2],
        stops: <double>[0, 1],
      ),
    );
    expect(g.begin, AlignmentDirectional.topStart);
    expect(g.end, AlignmentDirectional.bottomEnd);
    expect(g.stops, <double>[0, 1]);
  });

  test('a direction with stops carries them', () {
    final g = _grad(const FwStyle().bgGradientToEnd(<Color>[_c1, _c2], stops: <double>[0.2, 0.8]));
    expect(g.stops, <double>[0.2, 0.8]);
  });

  test('gradient sugar requires >= 2 colors', () {
    expect(() => const FwStyle().bgGradientToEnd(<Color>[_c1]), throwsA(isA<AssertionError>()));
  });

  test('toEnd physically flips under RTL (the whole point of directional gradients)', () {
    // The structural begin/end above are AlignmentDirectional; this proves they
    // RESOLVE to opposite physical edges per reading direction — what makes
    // `toEnd` better than Tailwind's physical `to-r`.
    final g = _grad(const FwStyle().bgGradientToEnd(<Color>[_c1, _c2]));
    expect(g.begin.resolve(TextDirection.ltr).x, -1, reason: 'LTR start edge = left');
    expect(g.begin.resolve(TextDirection.rtl).x, 1, reason: 'RTL start edge = right');
    expect(g.end.resolve(TextDirection.ltr).x, 1);
    expect(g.end.resolve(TextDirection.rtl).x, -1);
  });
}

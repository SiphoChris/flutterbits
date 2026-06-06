import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/fw_border_spec.dart';
import 'package:flutterwindcss/src/style/fw_style.dart';

const _c = Color(0xFF112233);
const _d = Color(0xFF445566);

void main() {
  group('gradient', () {
    test('bgGradient writes the gradient field (last-wins)', () {
      const g1 = LinearGradient(colors: <Color>[_c, _d]);
      const g2 = LinearGradient(colors: <Color>[_d, _c]);
      expect(const FwStyle().bgGradient(g1).gradient, g1);
      expect(const FwStyle().bgGradient(g1).bgGradient(g2).gradient, g2);
    });
  });

  group('border', () {
    test('border(w) sets width on every edge; resolves to a uniform Border', () {
      final spec = const FwStyle().border(2).borderSpec!;
      expect(spec.start!.width, 2);
      expect(spec.end!.width, 2);
      expect(spec.top!.width, 2);
      expect(spec.bottom!.width, 2);
      expect(spec.resolve(), isA<Border>());
    });

    test('border(w, color:) sets width + color on every edge', () {
      final spec = const FwStyle().border(2, color: _c).borderSpec!;
      expect(spec.top!.color, _c);
      expect(spec.top!.width, 2);
    });

    test('borderColor + borderWidth are order-independent (independent axes)', () {
      final a = const FwStyle().borderColor(_c).borderWidth(3).borderSpec!;
      final b = const FwStyle().borderWidth(3).borderColor(_c).borderSpec!;
      expect(a.top!.color, _c);
      expect(a.top!.width, 3);
      expect(b.top!.color, _c);
      expect(b.top!.width, 3);
    });

    test('borderS/E/T/B set one edge and merge with the others (last-wins)', () {
      final spec = const FwStyle().border(1, color: _c).borderS(width: 4, color: _d).borderSpec!;
      expect(spec.start!.width, 4);
      expect(spec.start!.color, _d);
      expect(spec.end!.width, 1); // untouched
      expect(spec.resolve(), isA<BorderDirectional>());
    });

    test('per-edge color only keeps the existing width', () {
      final spec = const FwStyle().borderWidth(2).borderT(color: _d).borderSpec!;
      expect(spec.top!.color, _d);
      expect(spec.top!.width, 2);
    });
  });

  group('radius', () {
    test('rounded sets every corner; last-wins on repeat', () {
      final r = const FwStyle().rounded(8).rounded(4).borderRadius!;
      expect(r.topStart, const Radius.circular(4));
      expect(r.bottomEnd, const Radius.circular(4));
    });

    test('roundedAll is a synonym of rounded', () {
      expect(const FwStyle().roundedAll(6).borderRadius, const FwStyle().rounded(6).borderRadius);
    });

    test('roundedT/B set their corner pair and merge per-corner', () {
      final r = const FwStyle().roundedT(8).roundedB(4).borderRadius!;
      expect(r.topStart, const Radius.circular(8));
      expect(r.topEnd, const Radius.circular(8));
      expect(r.bottomStart, const Radius.circular(4));
      expect(r.bottomEnd, const Radius.circular(4));
    });

    test('roundedS/E are directional (start/end corners)', () {
      final r = const FwStyle().roundedS(8).borderRadius!;
      expect(r.topStart, const Radius.circular(8));
      expect(r.bottomStart, const Radius.circular(8));
      expect(r.topEnd, Radius.zero);
    });

    test('roundedNone zeroes; roundedFull pills', () {
      expect(const FwStyle().rounded(8).roundedNone.borderRadius, BorderRadiusDirectional.zero);
      expect(const FwStyle().roundedFull.borderRadius!.topStart, const Radius.circular(9999));
    });
  });

  group('clip', () {
    test('clip() defaults to antiAlias; clip(x) writes the behavior', () {
      expect(const FwStyle().clip().clipBehavior, Clip.antiAlias);
      expect(const FwStyle().clip(Clip.hardEdge).clipBehavior, Clip.hardEdge);
    });
  });
}

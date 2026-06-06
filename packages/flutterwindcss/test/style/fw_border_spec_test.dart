import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/fw_border_spec.dart';

void main() {
  test('empty / width-0 spec resolves to null (nothing paints)', () {
    expect(const FwBorderSpec().resolve(), isNull);
    expect(const FwBorderSpec(start: BorderSide(width: 0)).resolve(), isNull);
  });

  test('uniform spec resolves to a non-directional Border', () {
    const side = BorderSide(color: Color(0xFF112233), width: 2);
    final b = const FwBorderSpec(start: side, end: side, top: side, bottom: side).resolve();
    expect(b, isA<Border>());
    expect((b! as Border).top, side);
  });

  test('per-side spec resolves to a directional BorderDirectional', () {
    const thick = BorderSide(color: Color(0xFF112233), width: 4);
    const thin = BorderSide(color: Color(0xFF112233), width: 1);
    final b = const FwBorderSpec(start: thick, end: thin, top: thin, bottom: thin).resolve();
    expect(b, isA<BorderDirectional>());
    expect((b! as BorderDirectional).start, thick);
    expect((b as BorderDirectional).end, thin);
  });

  test('null edges resolve to BorderSide.none on the directional border', () {
    const top = BorderSide(width: 2);
    final b = const FwBorderSpec(top: top).resolve()! as BorderDirectional;
    expect(b.top, top);
    expect(b.start, BorderSide.none);
    expect(b.bottom, BorderSide.none);
  });

  test('merge replaces only the given edges (per-edge last-wins)', () {
    const a = BorderSide(width: 1);
    const c = BorderSide(width: 4);
    final merged = const FwBorderSpec(start: a, top: a).merge(start: c);
    expect(merged.start, c);
    expect(merged.top, a);
    expect(merged.end, isNull);
  });

  test('== / hashCode compare all four edges', () {
    const a = FwBorderSpec(start: BorderSide(width: 1));
    const b = FwBorderSpec(start: BorderSide(width: 1));
    const d = FwBorderSpec(start: BorderSide(width: 2));
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == d, isFalse);
  });
}

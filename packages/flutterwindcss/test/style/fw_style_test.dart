import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/fw_layer.dart';
import 'package:flutterwindcss/src/style/fw_style.dart';

void main() {
  test('const empty style has all-null fields and no layers', () {
    const s = FwStyle();
    expect(s.padding, isNull);
    expect(s.background, isNull);
    expect(s.layers, isEmpty);
  });

  test('copyWith replaces only the named field (last-wins primitive)', () {
    const s = FwStyle();
    final s2 = s.copyWith(background: const Color(0xFF112233));
    expect(s2.background, const Color(0xFF112233));
    expect(s2.padding, isNull);
    final s3 = s2.copyWith(background: const Color(0xFF445566));
    expect(s3.background, const Color(0xFF445566)); // overwrite, not merge
    expect(s3.padding, isNull);
  });

  test('addLayer appends, preserving declaration order', () {
    const inner = FwStyle(background: Color(0xFF000000));
    const s = FwStyle();
    final s2 = s.addLayer(const FwStateCondition(WidgetState.hovered), inner);
    expect(s2.layers, hasLength(1));
    expect(s2.layers.first.$1, isA<FwStateCondition>());
    expect(s2.layers.first.$2, same(inner));
    final s3 = s2.addLayer(const FwStateCondition(WidgetState.focused), inner);
    expect(s3.layers, hasLength(2));
    expect(s3.layers[1].$1, const FwStateCondition(WidgetState.focused));
  });

  test('equality is value-based over fields and layers', () {
    const a = FwStyle(background: Color(0xFF111111));
    const b = FwStyle(background: Color(0xFF111111));
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(const FwStyle(background: Color(0xFF222222))));
  });

  test('equality is sensitive to layer contents', () {
    final a = const FwStyle().addLayer(
      const FwStateCondition(WidgetState.hovered),
      const FwStyle(background: Color(0xFF111111)),
    );
    final b = const FwStyle().addLayer(
      const FwStateCondition(WidgetState.hovered),
      const FwStyle(background: Color(0xFF222222)),
    );
    expect(a, isNot(b));
  });
}

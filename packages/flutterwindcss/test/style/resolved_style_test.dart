import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/resolved_style.dart';

void main() {
  test('ResolvedStyle holds the optional fields it is given', () {
    const r = ResolvedStyle(
      padding: EdgeInsetsDirectional.all(8),
      background: Color(0xFF123456),
    );
    expect(r.padding, const EdgeInsetsDirectional.all(8));
    expect(r.background, const Color(0xFF123456));
    expect(r.margin, isNull);
    expect(r.boxShadow, isNull);
  });

  test('factorAlignment defaults to centerStart when not provided', () {
    const r = ResolvedStyle();
    expect(r.factorAlignment, AlignmentDirectional.centerStart);
  });
}

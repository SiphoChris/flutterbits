import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Module 16 — `divide` (Tailwind divide-x/divide-y): a border BETWEEN flex
// children (`& > :not(:last-child)`). FwRow draws a trailing (end) border on each
// non-last child; FwColumn draws a bottom border. Directional (RTL-aware).
const _line = Color(0xFF3B82F6);

Widget _wrap(Widget c) => Directionality(textDirection: TextDirection.ltr, child: c);

Iterable<BorderDirectional> _borders(WidgetTester t) =>
    t
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.border)
        .whereType<BorderDirectional>();

void main() {
  testWidgets('FwRow divide draws an END border on each non-last child', (t) async {
    await t.pumpWidget(
      _wrap(
        const FwRow(
          divideWidth: 2,
          divideColor: _line,
          children: <Widget>[SizedBox(width: 20), SizedBox(width: 20), SizedBox(width: 20)],
        ),
      ),
    );
    final borders = _borders(t).toList();
    // 3 children -> 2 dividers (non-last get an end border).
    expect(borders.length, 2);
    expect(borders.first.end.width, 2);
    expect(borders.first.end.color, _line);
    expect(borders.first.bottom, BorderSide.none);
  });

  testWidgets('FwColumn divide draws a BOTTOM border on each non-last child', (t) async {
    await t.pumpWidget(
      _wrap(
        const FwColumn(
          divideWidth: 1,
          divideColor: _line,
          children: <Widget>[SizedBox(height: 20), SizedBox(height: 20)],
        ),
      ),
    );
    final borders = _borders(t).toList();
    expect(borders.length, 1); // 2 children -> 1 divider
    expect(borders.first.bottom.width, 1);
    expect(borders.first.bottom.color, _line);
    expect(borders.first.end, BorderSide.none);
  });

  testWidgets('no divide -> no separator DecoratedBox', (t) async {
    await t.pumpWidget(
      _wrap(const FwRow(children: <Widget>[SizedBox(width: 20), SizedBox(width: 20)])),
    );
    expect(_borders(t), isEmpty);
  });

  test('divideWidth > 0 requires a divideColor', () {
    expect(
      () => FwRow(divideWidth: 1, children: const <Widget>[SizedBox(), SizedBox()]),
      throwsA(isA<AssertionError>()),
    );
  });

  test('divideWidth must be >= 0', () {
    expect(
      () => FwRow(divideWidth: -1, divideColor: _line, children: const <Widget>[SizedBox()]),
      throwsA(isA<AssertionError>()),
    );
  });
}

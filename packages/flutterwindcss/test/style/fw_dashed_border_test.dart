import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';
import 'package:flutterwindcss/src/style/fw_dashed_border.dart';

// Module 15 — dashed/dotted borders (Tailwind `border-dashed`/`border-dotted`),
// the staple of drag-and-drop "drop to upload" zones. Flutter's BorderSide has no
// dashed style, so a non-solid border is painted by FwDashedBorderPainter (a
// CustomPainter) instead of the decoration's stroke. Uniform borders only.
const _border = Color(0xFF3B82F6);
const _bg = Color(0xFF0A0A0A);

Widget _wrap(Widget c) => Directionality(textDirection: TextDirection.ltr, child: c);

BoxDecoration? _deco(WidgetTester t) {
  for (final d in t.widgetList<DecoratedBox>(find.byType(DecoratedBox))) {
    if (d.decoration is BoxDecoration) return d.decoration as BoxDecoration;
  }
  return null;
}

FwDashedBorderPainter? _painter(WidgetTester t) {
  for (final cp in t.widgetList<CustomPaint>(find.byType(CustomPaint))) {
    if (cp.foregroundPainter is FwDashedBorderPainter) {
      return cp.foregroundPainter! as FwDashedBorderPainter;
    }
  }
  return null;
}

void main() {
  test('borderDashed/borderDotted/borderSolid store the line style', () {
    expect(const FwStyle().borderDashed.borderStyle, FwBorderStyle.dashed);
    expect(const FwStyle().borderDotted.borderStyle, FwBorderStyle.dotted);
    expect(const FwStyle().borderSolid.borderStyle, FwBorderStyle.solid);
  });

  testWidgets('a dashed border paints via FwDashedBorderPainter, not the decoration stroke', (
    t,
  ) async {
    await t.pumpWidget(
      _wrap(
        const SizedBox(width: 80, height: 60).tw.bg(_bg).border(2, color: _border).borderDashed,
      ),
    );
    final painter = _painter(t);
    expect(painter, isNotNull, reason: 'dashed border is painted');
    expect(painter!.color, _border);
    expect(painter.width, 2);
    expect(painter.dotted, isFalse);
    // The decoration carries the fill but NOT a solid border (no double border).
    expect(_deco(t)!.color, _bg);
    expect(_deco(t)!.border, isNull);
  });

  testWidgets('dotted border sets the dotted flag', (t) async {
    await t.pumpWidget(
      _wrap(const SizedBox(width: 80, height: 60).tw.border(2, color: _border).borderDotted),
    );
    expect(_painter(t)!.dotted, isTrue);
  });

  testWidgets('a solid border (default) still renders via the decoration, no painter', (t) async {
    await t.pumpWidget(
      _wrap(const SizedBox(width: 80, height: 60).tw.bg(_bg).border(2, color: _border)),
    );
    expect(_painter(t), isNull);
    expect(_deco(t)!.border, isNotNull);
  });

  testWidgets('borderSolid resets a dashed style back to the decoration stroke', (t) async {
    await t.pumpWidget(
      _wrap(
        const SizedBox(width: 80, height: 60).tw.border(2, color: _border).borderDashed.borderSolid,
      ),
    );
    expect(_painter(t), isNull);
    expect(_deco(t)!.border, isNotNull);
  });

  testWidgets('a non-uniform (per-side) border with dashed asserts', (t) async {
    await t.pumpWidget(
      _wrap(
        const SizedBox(width: 80, height: 60).tw.borderS(width: 2, color: _border).borderDashed,
      ),
    );
    expect(t.takeException(), isAssertionError);
  });

  testWidgets('a dashed border follows the rounded shape (radius passed to painter)', (t) async {
    await t.pumpWidget(
      _wrap(
        const SizedBox(width: 80, height: 60).tw.border(2, color: _border).rounded(12).borderDashed,
      ),
    );
    expect(_painter(t)!.borderRadius, isNotNull);
  });
}

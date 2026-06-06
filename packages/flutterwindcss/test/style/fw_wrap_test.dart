import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

Widget _wrap(Widget child) => Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  testWidgets('FwWrap maps gap/runGap units to Wrap spacing/runSpacing', (t) async {
    await t.pumpWidget(_wrap(const FwWrap(gap: 2, runGap: 3, children: [SizedBox(), SizedBox()])));
    final w = t.widget<Wrap>(find.byType(Wrap));
    expect(w.spacing, 8.0); // gap 2 × 4
    expect(w.runSpacing, 12.0); // runGap 3 × 4
    expect(w.children.length, 2);
  });

  testWidgets('defaults: zero spacing, horizontal direction', (t) async {
    await t.pumpWidget(_wrap(const FwWrap(children: [SizedBox()])));
    final w = t.widget<Wrap>(find.byType(Wrap));
    expect(w.spacing, 0.0);
    expect(w.runSpacing, 0.0);
    expect(w.direction, Axis.horizontal);
  });

  testWidgets('passes through alignment', (t) async {
    await t.pumpWidget(
      _wrap(
        const FwWrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [SizedBox()],
        ),
      ),
    );
    final w = t.widget<Wrap>(find.byType(Wrap));
    expect(w.alignment, WrapAlignment.center);
    expect(w.runAlignment, WrapAlignment.spaceBetween);
    expect(w.crossAxisAlignment, WrapCrossAlignment.end);
  });

  test('negative gap / runGap assert', () {
    expect(() => FwWrap(gap: -1, children: const []), throwsAssertionError);
    expect(() => FwWrap(runGap: -1, children: const []), throwsAssertionError);
  });
}

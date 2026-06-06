import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

Widget _wrap(Widget child) => Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  group('FwRow', () {
    testWidgets('builds a horizontal Flex with native spacing from gap units', (t) async {
      await t.pumpWidget(_wrap(const FwRow(gap: 2, children: [SizedBox(), SizedBox()])));
      final flex = t.widget<Flex>(find.byType(Flex));
      expect(flex.direction, Axis.horizontal);
      expect(flex.spacing, 8.0); // gap 2 × 4px
      expect(flex.children.length, 2);
    });

    testWidgets('defaults: gap 0, mainAxisSize.max', (t) async {
      await t.pumpWidget(_wrap(const FwRow(children: [SizedBox()])));
      final flex = t.widget<Flex>(find.byType(Flex));
      expect(flex.spacing, 0.0);
      expect(flex.mainAxisSize, MainAxisSize.max);
    });

    testWidgets('passes through alignment + mainAxisSize', (t) async {
      await t.pumpWidget(
        _wrap(
          const FwRow(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [SizedBox()],
          ),
        ),
      );
      final flex = t.widget<Flex>(find.byType(Flex));
      expect(flex.mainAxisAlignment, MainAxisAlignment.spaceBetween);
      expect(flex.crossAxisAlignment, CrossAxisAlignment.end);
      expect(flex.mainAxisSize, MainAxisSize.min);
    });
  });

  group('FwColumn', () {
    testWidgets('builds a vertical Flex with native spacing', (t) async {
      await t.pumpWidget(_wrap(const FwColumn(gap: 3, children: [SizedBox()])));
      final flex = t.widget<Flex>(find.byType(Flex));
      expect(flex.direction, Axis.vertical);
      expect(flex.spacing, 12.0); // gap 3 × 4px
    });
  });

  testWidgets('a flex widget can itself be styled with .tw', (t) async {
    await t.pumpWidget(_wrap(const FwRow(children: [SizedBox()]).tw.p(2)));
    expect(find.byType(FwStyled), findsOneWidget);
    expect(find.byType(FwRow), findsOneWidget);
  });

  test('negative gap asserts', () {
    expect(() => FwRow(gap: -1, children: const []), throwsAssertionError);
  });
}

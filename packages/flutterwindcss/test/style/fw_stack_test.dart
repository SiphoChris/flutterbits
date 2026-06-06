import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

Widget _wrap(Widget child) => Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  testWidgets('FwStack materializes FwPositioned into PositionedDirectional', (t) async {
    await t.pumpWidget(
      _wrap(
        FwStack(
          children: [
            const SizedBox(),
            FwPositioned(start: 2, top: 3, child: Container(key: const Key('p'))),
          ],
        ),
      ),
    );
    expect(find.byType(Stack), findsOneWidget);
    final pos = t.widget<PositionedDirectional>(find.byType(PositionedDirectional));
    expect(pos.start, 8.0); // inset 2 × 4px
    expect(pos.top, 12.0); // inset 3 × 4px
    expect(pos.end, isNull);
    expect(pos.bottom, isNull);
    // The FwPositioned wrapper itself is never built into the tree.
    expect(find.byType(FwPositioned), findsNothing);
  });

  testWidgets('children are stably sorted by z, then declaration order', (t) async {
    // Declared a(z10), b(z0), c(z10): paint order must be b, a, c.
    await t.pumpWidget(
      _wrap(
        FwStack(
          children: [
            FwPositioned(z: 10, child: Container(key: const Key('a'))),
            FwPositioned(z: 0, child: Container(key: const Key('b'))),
            FwPositioned(z: 10, child: Container(key: const Key('c'))),
          ],
        ),
      ),
    );
    final stack = t.widget<Stack>(find.byType(Stack));
    Key keyOf(Widget positioned) => ((positioned as PositionedDirectional).child as Container).key!;
    expect(stack.children.map(keyOf).toList(), const [Key('b'), Key('a'), Key('c')]);
  });

  testWidgets('non-positioned children default to z 0 and keep their slot', (t) async {
    await t.pumpWidget(
      _wrap(
        FwStack(
          children: [
            FwPositioned(z: 20, child: Container(key: const Key('top'))),
            Container(key: const Key('base')),
          ],
        ),
      ),
    );
    final stack = t.widget<Stack>(find.byType(Stack));
    // base (z0) paints first, then top (z20).
    expect((stack.children.first as Container).key, const Key('base'));
    expect(
      ((stack.children.last as PositionedDirectional).child as Container).key,
      const Key('top'),
    );
  });

  testWidgets('a plain child between two z-0 positioned children keeps declaration order', (
    t,
  ) async {
    // All z 0 → the stable sort must preserve declaration order across the
    // mixed positioned/plain set (no reordering of equal-z items).
    await t.pumpWidget(
      _wrap(
        FwStack(
          children: [
            FwPositioned(z: 0, child: Container(key: const Key('p1'))),
            Container(key: const Key('plain')),
            FwPositioned(z: 0, child: Container(key: const Key('p2'))),
          ],
        ),
      ),
    );
    final stack = t.widget<Stack>(find.byType(Stack));
    Key keyOf(Widget w) =>
        w is PositionedDirectional ? (w.child as Container).key! : (w as Container).key!;
    expect(stack.children.map(keyOf).toList(), const [Key('p1'), Key('plain'), Key('p2')]);
  });

  testWidgets('a bare FwPositioned outside FwStack throws a clear error', (t) async {
    await t.pumpWidget(_wrap(const FwPositioned(child: SizedBox())));
    expect(t.takeException(), isA<FlutterError>());
  });

  test('negative inset asserts', () {
    expect(() => FwPositioned(start: -1, child: const SizedBox()), throwsAssertionError);
  });

  test('FwPositionedPatch asserts non-negative inset', () {
    expect(() => FwPositionedPatch(top: -1), throwsAssertionError);
  });

  group('responsive', () {
    Widget frameViewport(double width, Widget child) => MediaQuery(
      data: MediaQueryData(size: Size(width, 600)),
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    );

    testWidgets('FwPositioned inset is overridden at the breakpoint', (t) async {
      const stack = FwStack(
        children: [
          FwPositioned(
            start: 1,
            top: 1,
            viewport: {FwBreakpoint.md: FwPositionedPatch(start: 5, top: 6)},
            child: SizedBox(),
          ),
        ],
      );
      await t.pumpWidget(frameViewport(500, stack)); // below md
      var pos = t.widget<PositionedDirectional>(find.byType(PositionedDirectional));
      expect(pos.start, 4.0); // inset 1 × 4
      expect(pos.top, 4.0);
      await t.pumpWidget(frameViewport(800, stack)); // at md
      pos = t.widget<PositionedDirectional>(find.byType(PositionedDirectional));
      expect(pos.start, 20.0); // inset 5 × 4
      expect(pos.top, 24.0); // inset 6 × 4
    });

    testWidgets('FwStack alignment is overridden at the breakpoint', (t) async {
      const stack = FwStack(
        viewport: {FwBreakpoint.md: FwStackPatch(alignment: AlignmentDirectional.center)},
        children: [SizedBox()],
      );
      await t.pumpWidget(frameViewport(500, stack));
      expect(t.widget<Stack>(find.byType(Stack)).alignment, AlignmentDirectional.topStart);
      await t.pumpWidget(frameViewport(800, stack));
      expect(t.widget<Stack>(find.byType(Stack)).alignment, AlignmentDirectional.center);
    });

    testWidgets('a fully static stack inserts no LayoutBuilder', (t) async {
      await t.pumpWidget(frameViewport(800, const FwStack(children: [SizedBox()])));
      expect(find.byType(LayoutBuilder), findsNothing);
    });

    testWidgets('container patch keys off the enclosing constraint (LayoutBuilder)', (t) async {
      const stack = FwStack(
        container: {FwBreakpoint.sm: FwStackPatch(alignment: AlignmentDirectional.center)},
        children: [SizedBox()],
      );
      await t.pumpWidget(
        frameViewport(2000, const Center(child: SizedBox(width: 300, child: stack))),
      );
      expect(find.byType(LayoutBuilder), findsOneWidget);
      expect(t.widget<Stack>(find.byType(Stack)).alignment, AlignmentDirectional.topStart);
      await t.pumpWidget(
        frameViewport(2000, const Center(child: SizedBox(width: 700, child: stack))),
      );
      expect(t.widget<Stack>(find.byType(Stack)).alignment, AlignmentDirectional.center);
    });
  });
}

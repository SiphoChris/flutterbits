import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Module 15 — FwScroll: a Material-free scroll container (Tailwind
// overflow-auto/scroll). SingleChildScrollView + RawScrollbar (both widgets-layer
// — no Material Scrollbar). overflow-hidden stays `.tw.clip()`; this is the
// scrollable primitive.
Widget _wrap(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(size: Size(200, 200)),
    child: Center(child: SizedBox(width: 100, height: 100, child: child)),
  ),
);

void main() {
  testWidgets('vertical FwScroll wraps a SingleChildScrollView + RawScrollbar', (t) async {
    await t.pumpWidget(
      _wrap(
        FwScroll(
          child: Column(
            children: List<Widget>.generate(40, (i) => SizedBox(height: 20, child: Text('row $i'))),
          ),
        ),
      ),
    );
    final sv = t.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
    expect(sv.scrollDirection, Axis.vertical);
    expect(find.byType(RawScrollbar), findsOneWidget);
  });

  testWidgets('FwScroll actually scrolls its overflowing content', (t) async {
    await t.pumpWidget(
      _wrap(
        FwScroll(
          child: Column(
            children: List<Widget>.generate(40, (i) => SizedBox(height: 20, child: Text('row $i'))),
          ),
        ),
      ),
    );
    final before =
        t.widget<SingleChildScrollView>(find.byType(SingleChildScrollView)).controller!.offset;
    await t.drag(find.byType(FwScroll), const Offset(0, -200));
    await t.pumpAndSettle();
    final after =
        t.widget<SingleChildScrollView>(find.byType(SingleChildScrollView)).controller!.offset;
    expect(after, greaterThan(before));
  });

  testWidgets('horizontal axis scrolls sideways', (t) async {
    await t.pumpWidget(
      _wrap(
        FwScroll(
          axis: Axis.horizontal,
          child: Row(
            children: List<Widget>.generate(40, (i) => SizedBox(width: 20, child: Text('$i'))),
          ),
        ),
      ),
    );
    expect(
      t.widget<SingleChildScrollView>(find.byType(SingleChildScrollView)).scrollDirection,
      Axis.horizontal,
    );
  });

  testWidgets('showScrollbar:false omits the scrollbar', (t) async {
    await t.pumpWidget(
      _wrap(
        FwScroll(
          showScrollbar: false,
          child: Column(
            children: List<Widget>.generate(40, (i) => SizedBox(height: 20, child: Text('$i'))),
          ),
        ),
      ),
    );
    expect(find.byType(RawScrollbar), findsNothing);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('snapExtent snaps the scroll offset to item boundaries (start align)', (t) async {
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(200, 200)),
          child: Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: FwScroll(
                snapExtent: 50,
                child: Column(
                  children: List<Widget>.generate(40, (i) => const SizedBox(height: 50)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.drag(find.byType(FwScroll), const Offset(0, -130));
    await t.pumpAndSettle();
    final offset =
        t.widget<SingleChildScrollView>(find.byType(SingleChildScrollView)).controller!.offset;
    expect(offset % 50, moreOrLessEquals(0, epsilon: 0.5), reason: 'snapped to a 50px boundary');
  });

  testWidgets('snapExtent must be > 0', (t) async {
    expect(() => FwScroll(snapExtent: 0, child: const SizedBox()), throwsA(isA<AssertionError>()));
  });

  testWidgets('a provided controller is used (not overwritten)', (t) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await t.pumpWidget(
      _wrap(
        FwScroll(
          controller: controller,
          child: Column(
            children: List<Widget>.generate(40, (i) => SizedBox(height: 20, child: Text('$i'))),
          ),
        ),
      ),
    );
    expect(
      t.widget<SingleChildScrollView>(find.byType(SingleChildScrollView)).controller,
      same(controller),
    );
  });
}

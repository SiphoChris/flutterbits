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

  testWidgets('thumbColor + trackColor flow to RawScrollbar (track shown)', (t) async {
    await t.pumpWidget(
      _wrap(
        FwScroll(
          thumbColor: const Color(0xFF112233),
          trackColor: const Color(0xFF445566),
          child: Column(
            children: List<Widget>.generate(40, (i) => SizedBox(height: 20, child: Text('$i'))),
          ),
        ),
      ),
    );
    final bar = t.widget<RawScrollbar>(find.byType(RawScrollbar));
    expect(bar.thumbColor, const Color(0xFF112233));
    expect(bar.trackColor, const Color(0xFF445566));
    expect(bar.trackVisibility, isTrue);
    // A visible track implies a visible thumb.
    expect(bar.thumbVisibility, isTrue);
  });

  testWidgets('no trackColor leaves the track hidden (auto)', (t) async {
    await t.pumpWidget(
      _wrap(
        FwScroll(
          child: Column(
            children: List<Widget>.generate(40, (i) => SizedBox(height: 20, child: Text('$i'))),
          ),
        ),
      ),
    );
    final bar = t.widget<RawScrollbar>(find.byType(RawScrollbar));
    expect(bar.trackColor, isNull);
    expect(bar.trackVisibility, isNull);
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

  testWidgets('snapExtent accounts for leading padding (padded carousel aligns)', (t) async {
    // With a 20px leading inset, item k's edge sits at 20 + k·50 — so the rest
    // offset must satisfy (offset − 20) % 50 == 0, NOT offset % 50. Without the
    // padding-aware math every item would rest 20px off.
    const lead = 20.0;
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
                padding: const EdgeInsets.only(top: lead),
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
    expect(
      (offset - lead) % 50,
      moreOrLessEquals(0, epsilon: 0.5),
      reason: 'snapped to a 50px boundary measured from the leading padding',
    );
  });

  testWidgets('snapExtent must be > 0', (t) async {
    expect(() => FwScroll(snapExtent: 0, child: const SizedBox()), throwsA(isA<AssertionError>()));
  });

  testWidgets('snapExtent larger than the viewport degrades to snap-to-start (no '
      'off-screen negative offset)', (t) async {
    // itemExtent 150 > viewport 100 → slack is negative; an end/center align
    // would push the snap target off-screen pre-clamp. The clamp degrades it to
    // snap-to-start, keeping the offset in-bounds and on a clean boundary.
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
                snapExtent: 150,
                snapAlign: FwSnapAlign.end,
                child: Column(
                  children: List<Widget>.generate(10, (i) => const SizedBox(height: 150)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.drag(find.byType(FwScroll), const Offset(0, -260));
    await t.pumpAndSettle();
    final sv = t.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
    final offset = sv.controller!.offset;
    expect(offset, greaterThanOrEqualTo(0.0));
    expect(offset, lessThanOrEqualTo(sv.controller!.position.maxScrollExtent + 0.5));
    expect(offset % 150, moreOrLessEquals(0, epsilon: 0.5), reason: 'snapped to a 150px boundary');
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

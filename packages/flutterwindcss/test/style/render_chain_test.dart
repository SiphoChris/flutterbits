import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/resolved_style.dart';
import 'package:flutterwindcss/src/style/resolved_style_build.dart';

Future<void> _pump(WidgetTester t, ResolvedStyle r) => t.pumpWidget(
  Directionality(
    textDirection: TextDirection.ltr,
    child: r.build(const SizedBox(key: Key('child'))),
  ),
);

void main() {
  testWidgets('static empty style renders the child with no extra wrappers', (t) async {
    await _pump(t, const ResolvedStyle());
    expect(find.byKey(const Key('child')), findsOneWidget);
    expect(find.byType(Opacity), findsNothing);
    expect(find.byType(DecoratedBox), findsNothing);
    expect(find.byType(Padding), findsNothing);
  });

  testWidgets('padding wrapper present iff padding set', (t) async {
    await _pump(t, const ResolvedStyle());
    expect(find.byType(Padding), findsNothing);
    await _pump(t, const ResolvedStyle(padding: EdgeInsetsDirectional.all(8)));
    expect(find.byType(Padding), findsWidgets);
  });

  testWidgets('background emits exactly one DecoratedBox', (t) async {
    await _pump(t, const ResolvedStyle(background: Color(0xFF112233)));
    expect(find.byType(DecoratedBox), findsOneWidget);
  });

  testWidgets('shadow emits an outer DecoratedBox even with a backdrop clip', (t) async {
    await _pump(
      t,
      const ResolvedStyle(
        background: Color(0xFF112233),
        backdropBlur: 4,
        boxShadow: <BoxShadow>[BoxShadow(blurRadius: 3)],
        borderRadius: BorderRadiusDirectional.all(Radius.circular(6)),
      ),
    );
    // The shadow box must sit OUTSIDE the backdrop ClipRRect.
    final shadowBox = find.byType(DecoratedBox).first;
    expect(find.descendant(of: shadowBox, matching: find.byType(BackdropFilter)), findsOneWidget);
  });

  testWidgets('margin is outermost, decoration nested within it', (t) async {
    await _pump(
      t,
      const ResolvedStyle(
        margin: EdgeInsetsDirectional.all(4),
        padding: EdgeInsetsDirectional.all(8),
        background: Color(0xFF112233),
      ),
    );
    final marginPadding = find.byType(Padding).first;
    expect(find.descendant(of: marginPadding, matching: find.byType(DecoratedBox)), findsOneWidget);
  });

  testWidgets('opacity wrapper present iff opacity set', (t) async {
    await _pump(t, const ResolvedStyle());
    expect(find.byType(Opacity), findsNothing);
    await _pump(t, const ResolvedStyle(opacity: 0.5, background: Color(0xFF111111)));
    expect(find.byType(Opacity), findsOneWidget);
  });

  testWidgets('transform is outside the shadow (transforms rendered result)', (t) async {
    await _pump(
      t,
      const ResolvedStyle(scale: 1.5, boxShadow: <BoxShadow>[BoxShadow(blurRadius: 3)]),
    );
    final transform = find.byType(Transform).first;
    expect(find.descendant(of: transform, matching: find.byType(DecoratedBox)), findsOneWidget);
  });

  testWidgets('fixed width produces a tight ConstrainedBox on that axis', (t) async {
    await _pump(t, const ResolvedStyle(width: 50));
    final cb = t.widget<ConstrainedBox>(find.byType(ConstrainedBox));
    expect(cb.constraints.minWidth, 50);
    expect(cb.constraints.maxWidth, 50);
  });

  test('fixed dim + min/max on same axis asserts in debug', () {
    expect(
      () => const ResolvedStyle(width: 50, maxWidth: 100).build(const SizedBox()),
      throwsAssertionError,
    );
    expect(
      () => const ResolvedStyle(height: 50, minHeight: 10).build(const SizedBox()),
      throwsAssertionError,
    );
  });

  testWidgets('content clip radius is deflated by the border width (Finding #3)', (t) async {
    const r = 10.0;
    const w = 3.0;
    await _pump(
      t,
      ResolvedStyle(
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadiusDirectional.all(Radius.circular(r)),
        border: Border.all(width: w),
        background: const Color(0xFF112233),
      ),
    );
    // The content ClipRRect (inside the surface DecoratedBox) uses radius r - w.
    final clip = t.widget<ClipRRect>(find.byType(ClipRRect));
    final radius = clip.borderRadius as BorderRadiusDirectional;
    expect(radius.topStart, const Radius.circular(r - w));
  });

  test('per-side (directional) border + radius asserts in debug (Flutter cannot paint it)', () {
    // Flutter paints a rounded border only when every edge is uniform; a
    // BorderDirectional with differing edges + borderRadius crashes in its
    // painter. The engine turns that into a clear, early assert.
    expect(
      () => const ResolvedStyle(
        border: BorderDirectional(start: BorderSide(width: 4), end: BorderSide(width: 1)),
        borderRadius: BorderRadiusDirectional.all(Radius.circular(8)),
      ).build(const SizedBox()),
      throwsAssertionError,
    );
  });

  testWidgets('uniform border + radius paints fine (no assert)', (t) async {
    await _pump(
      t,
      ResolvedStyle(
        border: Border.all(width: 2),
        borderRadius: const BorderRadiusDirectional.all(Radius.circular(8)),
        background: const Color(0xFF112233),
      ),
    );
    expect(find.byType(DecoratedBox), findsOneWidget);
  });

  testWidgets('clip without a radius still clips (rectangular ClipRRect)', (t) async {
    await _pump(t, const ResolvedStyle(clipBehavior: Clip.antiAlias));
    final clip = t.widget<ClipRRect>(find.byType(ClipRRect));
    expect(clip.borderRadius, BorderRadiusDirectional.zero);
  });

  testWidgets('no clip emitted when clipBehavior is unset', (t) async {
    await _pump(
      t,
      const ResolvedStyle(borderRadius: BorderRadiusDirectional.all(Radius.circular(8))),
    );
    expect(find.byType(ClipRRect), findsNothing);
  });

  testWidgets('content clip without a border uses the un-deflated radius', (t) async {
    await _pump(
      t,
      const ResolvedStyle(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadiusDirectional.all(Radius.circular(10)),
      ),
    );
    final clip = t.widget<ClipRRect>(find.byType(ClipRRect));
    final radius = clip.borderRadius as BorderRadiusDirectional;
    expect(radius.topStart, const Radius.circular(10));
  });

  testWidgets('deflated content-clip radius clamps at 0 when border ≥ radius', (t) async {
    await _pump(
      t,
      ResolvedStyle(
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadiusDirectional.all(Radius.circular(2)),
        border: Border.all(width: 5), // 5 > 2 → corner would go negative
        background: const Color(0xFF112233),
      ),
    );
    final clip = t.widget<ClipRRect>(find.byType(ClipRRect));
    final radius = clip.borderRadius as BorderRadiusDirectional;
    expect(radius.topStart, Radius.zero); // clamped, not negative
  });

  // --- Render-chain ORDER pins (the build() doc-comment pins outer→inner and
  // says "do not reorder without updating render_chain_test.dart"; these pin the
  // pairs that were previously unverified). ---

  testWidgets('content blur is OUTSIDE group opacity', (t) async {
    await _pump(t, const ResolvedStyle(opacity: 0.5, blur: 4, background: Color(0xFF111111)));
    final blur = find.byType(ImageFiltered).first;
    expect(find.descendant(of: blur, matching: find.byType(Opacity)), findsOneWidget);
  });

  testWidgets('transform is OUTSIDE content blur', (t) async {
    await _pump(t, const ResolvedStyle(scale: 1.5, blur: 4));
    final transform = find.byType(Transform).first;
    expect(find.descendant(of: transform, matching: find.byType(ImageFiltered)), findsOneWidget);
  });

  testWidgets('content clip is OUTSIDE inner padding', (t) async {
    await _pump(
      t,
      const ResolvedStyle(clipBehavior: Clip.antiAlias, padding: EdgeInsetsDirectional.all(8)),
    );
    final clip = find.byType(ClipRRect).first;
    expect(find.descendant(of: clip, matching: find.byType(Padding)), findsOneWidget);
  });
}

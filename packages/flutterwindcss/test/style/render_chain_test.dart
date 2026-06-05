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
  testWidgets('static empty style renders the child with no extra wrappers',
      (t) async {
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

  testWidgets('shadow emits an outer DecoratedBox even with a backdrop clip',
      (t) async {
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
    expect(
      find.descendant(of: shadowBox, matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );
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
    expect(
      find.descendant(of: marginPadding, matching: find.byType(DecoratedBox)),
      findsOneWidget,
    );
  });

  testWidgets('opacity wrapper present iff opacity set', (t) async {
    await _pump(t, const ResolvedStyle());
    expect(find.byType(Opacity), findsNothing);
    await _pump(
      t,
      const ResolvedStyle(opacity: 0.5, background: Color(0xFF111111)),
    );
    expect(find.byType(Opacity), findsOneWidget);
  });

  testWidgets('transform is outside the shadow (transforms rendered result)',
      (t) async {
    await _pump(
      t,
      const ResolvedStyle(
        scale: 1.5,
        boxShadow: <BoxShadow>[BoxShadow(blurRadius: 3)],
      ),
    );
    final transform = find.byType(Transform).first;
    expect(
      find.descendant(of: transform, matching: find.byType(DecoratedBox)),
      findsOneWidget,
    );
  });

  testWidgets('fixed width produces a tight ConstrainedBox on that axis',
      (t) async {
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
}

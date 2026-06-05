import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

const _a = Color(0xFFAAAAAA);
const _b = Color(0xFFBBBBBB);

Color? _boxColor(WidgetTester t) {
  final d = t.widget<DecoratedBox>(find.byType(DecoratedBox));
  return (d.decoration as BoxDecoration).color;
}

/// Finds the visual-only Focus that `FwStyled` inserts (the framework always
/// adds a root FocusTraversalGroup Focus, so target ours by its debugLabel).
final _ourFocus = find.byWidgetPredicate(
  (w) => w is Focus && w.focusNode?.debugLabel == 'FwStyled(visual-only)',
);

void main() {
  testWidgets('.tw renders the child and applies static base styling', (t) async {
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: const SizedBox(key: Key('c')).tw.p(2).bg(_a),
      ),
    );
    expect(find.byKey(const Key('c')), findsOneWidget);
    expect(find.byType(DecoratedBox), findsOneWidget);
    expect(_boxColor(t), _a);
  });

  testWidgets('static style inserts no interaction wrappers or LayoutBuilder', (t) async {
    await t.pumpWidget(
      Directionality(textDirection: TextDirection.ltr, child: const SizedBox().tw.p(2).bg(_a)),
    );
    expect(_ourFocus, findsNothing);
    expect(find.byType(LayoutBuilder), findsNothing);
  });

  testWidgets('a hover layer is visual-only: a Focus that is never a tab stop', (t) async {
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: const SizedBox().tw.bg(_a).hover((h) => h.bg(_b)),
      ),
    );
    final focus = t.widget<Focus>(_ourFocus);
    expect(focus.canRequestFocus, isFalse);
    expect(focus.skipTraversal, isTrue);
  });

  testWidgets('hovering changes the resolved background (live state)', (t) async {
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: const SizedBox(width: 50, height: 50).tw.bg(_a).hover((h) => h.bg(_b)),
      ),
    );
    expect(_boxColor(t), _a);

    final gesture = await t.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(t.getCenter(find.byType(DecoratedBox)));
    await t.pumpAndSettle();

    expect(_boxColor(t), _b);
  });

  testWidgets('a container layer inserts a LayoutBuilder', (t) async {
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: const SizedBox().tw.bg(_a).containerMd((m) => m.bg(_b)),
      ),
    );
    expect(find.byType(LayoutBuilder), findsOneWidget);
  });

  testWidgets('injected states resolve without any detector requirement', (t) async {
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FwStyled(
          style: const FwStyle().bg(_a).whenState(WidgetState.selected, (s) => s.bg(_b)),
          states: const <WidgetState>{WidgetState.selected},
          child: const SizedBox(),
        ),
      ),
    );
    expect(_boxColor(t), _b);
  });

  testWidgets('a Semantics(button) child survives the .tw chain', (t) async {
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(button: true, label: 'Go', child: const SizedBox()).tw.p(2).bg(_a),
      ),
    );
    expect(find.bySemanticsLabel('Go'), findsOneWidget);
  });
}

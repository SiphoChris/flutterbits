import 'dart:ui' show Tristate;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';
import 'package:flutterbits_gallery/components/ui/button.dart';

Widget _host(Widget child) => FwTheme(
  tokens: FwTokens.light,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(data: const MediaQueryData(), child: Center(child: child)),
  ),
);

void main() {
  testWidgets('renders its label and reports button semantics', (t) async {
    await t.pumpWidget(_host(Button(onPressed: () {}, child: const Text('Save'))));
    expect(find.text('Save'), findsOneWidget);

    final semanticsNode = t.getSemantics(find.text('Save'));
    final flags = semanticsNode.getSemanticsData().flagsCollection;
    expect(flags.isButton, isTrue);
    expect(flags.isEnabled, Tristate.isTrue);
  });

  testWidgets('fires onPressed when tapped', (t) async {
    var taps = 0;
    await t.pumpWidget(_host(Button(onPressed: () => taps++, child: const Text('Go'))));
    await t.tap(find.text('Go'));
    expect(taps, 1);
  });

  testWidgets('disabled (onPressed null) does not fire and reports disabled', (t) async {
    await t.pumpWidget(_host(const Button(onPressed: null, child: Text('Nope'))));
    await t.tap(find.text('Nope'), warnIfMissed: false);
    final flags = t.getSemantics(find.text('Nope')).getSemanticsData().flagsCollection;
    expect(flags.isEnabled, Tristate.isFalse);
  });

  // The Button must handle ActivateIntent (mapped to Enter + Space) when it
  // owns focus.  We give the Button its own FocusNode, request focus directly,
  // then send Enter — this is the most reliable harness sequence because widget
  // tests don't always simulate a full tab-traversal chain consistently.
  testWidgets('activates via keyboard (Enter) when focused', (t) async {
    var taps = 0;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await t.pumpWidget(
      _host(Button(focusNode: focus, onPressed: () => taps++, child: const Text('K'))),
    );
    focus.requestFocus();
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump();
    expect(taps, 1, reason: 'Enter while focused should fire onPressed exactly once');
  });

  testWidgets('activates via keyboard (Space) when focused', (t) async {
    var taps = 0;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await t.pumpWidget(
      _host(Button(focusNode: focus, onPressed: () => taps++, child: const Text('K2'))),
    );
    focus.requestFocus();
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await t.pump();
    expect(taps, 1, reason: 'Space while focused should fire onPressed exactly once');
  });
}

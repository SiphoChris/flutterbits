import 'dart:ui' show Tristate;

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
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Golden slice for the module 14 group/peer state propagation. Two group cards
// sit side by side: the left group is idle, the right group has `hovered`
// INJECTED (FwGroup.states) so the `group-hover` reactor visual is captured
// deterministically — no live pointer needed. Each card holds a reactor box that
// is `muted` at rest and `primary` while its group is hovered. The light/dark
// pair covers both themes. Local generation is non-authoritative; CI (Linux) is
// the source of truth (spec §10).
Widget _frame(FwTokens tokens, Widget child) => FwTheme(
  tokens: tokens,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(size: Size(220, 140)),
      child: ColoredBox(color: tokens.colors.background, child: Center(child: child)),
    ),
  ),
);

Widget _card(BuildContext context, {required bool hovered}) {
  final c = context.fw.colors;
  final r = context.fw.radii;
  // The group container (card) + a reactor that flips on group-hover.
  return FwGroup(
    states: <WidgetState>{if (hovered) WidgetState.hovered},
    child: const SizedBox(
      width: 80,
      height: 80,
    ).tw.m(2).rounded(r.lg).bg(c.muted).groupHover((s) => s.bg(c.primary)),
  ).tw.p(2);
}

Widget _row(BuildContext context) => Row(
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[_card(context, hovered: false), _card(context, hovered: true)],
);

void main() {
  testWidgets('group slice — light (idle vs group-hovered)', (t) async {
    await t.pumpWidget(_frame(FwTokens.light, const Builder(builder: _row)));
    await expectLater(find.byType(Row), matchesGoldenFile('goldens/group_light.png'));
  });

  testWidgets('group slice — dark (idle vs group-hovered)', (t) async {
    await t.pumpWidget(_frame(FwTokens.dark, const Builder(builder: _row)));
    await expectLater(find.byType(Row), matchesGoldenFile('goldens/group_dark.png'));
  });
}

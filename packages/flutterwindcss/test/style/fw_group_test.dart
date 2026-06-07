import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

const _base = Color(0xFFAAAAAA);
const _react = Color(0xFFBBBBBB);

/// True if any rendered DecoratedBox carries [color] (the reactor's resolved bg).
bool _hasBoxColor(WidgetTester t, Color color) => t
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .any((d) => d.decoration is BoxDecoration && (d.decoration as BoxDecoration).color == color);

Future<TestGesture> _hoverCenterOf(WidgetTester t, Finder finder) async {
  final gesture = await t.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await gesture.moveTo(t.getCenter(finder));
  await t.pumpAndSettle();
  return gesture;
}

Widget _wrap(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    Directionality(textDirection: direction, child: child);

void main() {
  testWidgets('group-hover: hovering an FwGroup flips a descendant reactor', (t) async {
    await t.pumpWidget(
      _wrap(
        FwGroup(
          child: const SizedBox(width: 80, height: 80).tw.bg(_base).groupHover((s) => s.bg(_react)),
        ),
      ),
    );
    expect(_hasBoxColor(t, _base), isTrue);
    expect(_hasBoxColor(t, _react), isFalse);

    await _hoverCenterOf(t, find.byType(FwGroup));
    expect(_hasBoxColor(t, _react), isTrue);
  });

  testWidgets('peer-hover: hovering an FwPeer flips a SIBLING reactor', (t) async {
    await t.pumpWidget(
      _wrap(
        FwGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const FwPeer(child: SizedBox(width: 80, height: 40, key: Key('peer'))),
              const SizedBox(width: 80, height: 40).tw.bg(_base).peerHover((s) => s.bg(_react)),
            ],
          ),
        ),
      ),
    );
    expect(_hasBoxColor(t, _react), isFalse);

    await _hoverCenterOf(t, find.byKey(const Key('peer')));
    expect(_hasBoxColor(t, _react), isTrue);
  });

  testWidgets('named group: a reactor targets the OUTER group when nested', (t) async {
    await t.pumpWidget(
      _wrap(
        FwGroup(
          name: 'outer',
          child: Padding(
            // padding gives the outer group hover area beyond the inner group
            padding: const EdgeInsets.all(40),
            child: FwGroup(
              child: const SizedBox(
                width: 40,
                height: 40,
              ).tw.bg(_base).groupHover((s) => s.bg(_react), name: 'outer'),
            ),
          ),
        ),
      ),
    );
    expect(_hasBoxColor(t, _react), isFalse);

    // Hover the outer group's padding area (outside the inner group + reactor).
    final gesture = await t.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(t.getTopLeft(find.byType(FwGroup).first) + const Offset(5, 5));
    await t.pumpAndSettle();

    expect(_hasBoxColor(t, _react), isTrue);
  });

  testWidgets('injected group state drives group-disabled without a pointer', (t) async {
    const disabled = Color(0xFFCCCCCC);
    await t.pumpWidget(
      _wrap(
        FwGroup(
          states: const <WidgetState>{WidgetState.disabled},
          child: const SizedBox(
            width: 40,
            height: 40,
          ).tw.bg(_base).groupDisabled((s) => s.bg(disabled)),
        ),
      ),
    );
    expect(_hasBoxColor(t, disabled), isTrue);
  });

  testWidgets('FwPeer outside an FwGroup scope asserts', (t) async {
    await t.pumpWidget(_wrap(const FwPeer(child: SizedBox())));
    expect(t.takeException(), isAssertionError);
  });

  testWidgets('group-hover drives a directional reactor under RTL', (t) async {
    // Group/peer state propagation is direction-agnostic; this confirms a
    // reactor inside a group resolves + flips correctly under RTL too (the
    // directional render chain is exercised elsewhere).
    await t.pumpWidget(
      _wrap(
        direction: TextDirection.rtl,
        FwGroup(
          child: const SizedBox(
            width: 80,
            height: 80,
          ).tw.bg(_base).groupHover((s) => s.bg(_react).ps(2)),
        ),
      ),
    );
    expect(_hasBoxColor(t, _react), isFalse);
    await _hoverCenterOf(t, find.byType(FwGroup));
    expect(_hasBoxColor(t, _react), isTrue);
  });

  testWidgets('peer reparented across groups (GlobalKey) deregisters from the old scope', (
    t,
  ) async {
    const colorA = Color(0xFF111111);
    const colorB = Color(0xFF222222);
    final peerKey = GlobalKey();

    // A peer with injected `hovered` (deterministic — no pointer). When it lives
    // under group A, reactor A reacts; after a GlobalKey move to group B, reactor
    // B must react and reactor A must revert (the old scope must drop the peer).
    Widget tree({required bool inB}) => _wrap(
      Column(
        children: <Widget>[
          FwGroup(
            child: Column(
              children: <Widget>[
                if (!inB)
                  FwPeer(
                    key: peerKey,
                    states: const <WidgetState>{WidgetState.hovered},
                    child: const SizedBox(width: 20, height: 20),
                  ),
                const SizedBox(width: 30, height: 30).tw.bg(_base).peerHover((s) => s.bg(colorA)),
              ],
            ),
          ),
          FwGroup(
            child: Column(
              children: <Widget>[
                if (inB)
                  FwPeer(
                    key: peerKey,
                    states: const <WidgetState>{WidgetState.hovered},
                    child: const SizedBox(width: 20, height: 20),
                  ),
                const SizedBox(width: 30, height: 30).tw.bg(_base).peerHover((s) => s.bg(colorB)),
              ],
            ),
          ),
        ],
      ),
    );

    await t.pumpWidget(tree(inB: false));
    await t.pumpAndSettle();
    expect(_hasBoxColor(t, colorA), isTrue, reason: 'peer in A drives reactor A');
    expect(_hasBoxColor(t, colorB), isFalse);

    await t.pumpWidget(tree(inB: true)); // GlobalKey move A -> B
    await t.pumpAndSettle();
    expect(_hasBoxColor(t, colorB), isTrue, reason: 'peer moved to B drives reactor B');
    expect(_hasBoxColor(t, colorA), isFalse, reason: 'old scope A must have dropped the peer');
  });

  testWidgets('two unnamed peers under one scope union their states', (t) async {
    const cHover = Color(0xFF777777);
    const cFocus = Color(0xFF888888);
    await t.pumpWidget(
      _wrap(
        FwGroup(
          child: Column(
            children: <Widget>[
              const FwPeer(
                states: <WidgetState>{WidgetState.hovered},
                child: SizedBox(width: 10, height: 10),
              ),
              const FwPeer(
                states: <WidgetState>{WidgetState.focused},
                child: SizedBox(width: 10, height: 10),
              ),
              // Two separate reactors prove BOTH peers' states reached the channel
              // simultaneously (the union), rather than one clobbering the other.
              const SizedBox(width: 30, height: 30).tw.bg(_base).peerHover((s) => s.bg(cHover)),
              const SizedBox(width: 30, height: 30).tw.bg(_base).peerFocus((s) => s.bg(cFocus)),
            ],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(_hasBoxColor(t, cHover), isTrue); // hovered from peer 1
    expect(_hasBoxColor(t, cFocus), isTrue); // focused from peer 2 — union holds both
  });

  testWidgets('removing a peer reverts its sibling reactor', (t) async {
    Widget tree({required bool withPeer}) => _wrap(
      FwGroup(
        child: Column(
          children: <Widget>[
            if (withPeer)
              const FwPeer(
                states: <WidgetState>{WidgetState.hovered},
                child: SizedBox(width: 10, height: 10),
              ),
            const SizedBox(width: 30, height: 30).tw.bg(_base).peerHover((s) => s.bg(_react)),
          ],
        ),
      ),
    );
    await t.pumpWidget(tree(withPeer: true));
    await t.pumpAndSettle();
    expect(_hasBoxColor(t, _react), isTrue);

    await t.pumpWidget(tree(withPeer: false)); // peer disposed
    await t.pumpAndSettle();
    expect(_hasBoxColor(t, _react), isFalse, reason: 'peer gone -> reactor reverts');
  });

  testWidgets('peer-disabled suppresses peer-hover within the peer channel', (t) async {
    const disabledColor = Color(0xFF444444);
    await t.pumpWidget(
      _wrap(
        FwGroup(
          child: Column(
            children: <Widget>[
              const FwPeer(
                states: <WidgetState>{WidgetState.disabled, WidgetState.hovered},
                child: SizedBox(width: 10, height: 10),
              ),
              const SizedBox(width: 30, height: 30).tw
                  .bg(_base)
                  .peerHover((s) => s.bg(_react))
                  .peerDisabled((s) => s.bg(disabledColor)),
            ],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(_hasBoxColor(t, disabledColor), isTrue); // disabled wins
    expect(_hasBoxColor(t, _react), isFalse); // peer-hover suppressed
  });

  testWidgets('group-hover combines with the box own hover independently', (t) async {
    const own = Color(0xFFDDDDDD);
    await t.pumpWidget(
      _wrap(
        FwGroup(
          child: const SizedBox(
            width: 80,
            height: 80,
          ).tw.bg(_base).hover((s) => s.bg(own)).groupHover((s) => s.bg(_react)),
        ),
      ),
    );
    // Hovering the box hovers both the box and (since the box is inside) the
    // group; group-hover is declared last so it wins the tie — but the point is
    // both paths resolve without error.
    await _hoverCenterOf(t, find.byType(DecoratedBox).first);
    expect(_hasBoxColor(t, _react), isTrue);
  });
}

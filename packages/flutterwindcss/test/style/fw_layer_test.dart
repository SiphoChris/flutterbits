import 'package:flutter/widgets.dart' show WidgetState;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart' show FwBreakpoint;
import 'package:flutterwindcss/src/style/fw_layer.dart';

void main() {
  const noStates = <WidgetState>{};

  test('state condition matches on its WidgetState, ignoring both widths', () {
    const c = FwStateCondition(WidgetState.hovered);
    expect(c.matches(<WidgetState>{WidgetState.hovered}, null, null), isTrue);
    expect(c.matches(<WidgetState>{WidgetState.focused}, 9999, 9999), isFalse);
  });

  test('viewport condition keys off the viewport width only', () {
    const c = FwViewportCondition(FwBreakpoint.md); // 768
    expect(c.matches(noStates, 800, null), isTrue);
    expect(c.matches(noStates, 768, null), isTrue);
    expect(c.matches(noStates, 700, null), isFalse);
    expect(c.matches(noStates, null, null), isFalse);
    // A wide *container* width must NOT satisfy a viewport condition.
    expect(c.matches(noStates, 100, 9999), isFalse);
  });

  test('container condition keys off the container width only', () {
    const c = FwContainerCondition(FwBreakpoint.md); // 768
    expect(c.matches(noStates, null, 800), isTrue);
    expect(c.matches(noStates, null, 768), isTrue);
    expect(c.matches(noStates, null, 700), isFalse);
    expect(c.matches(noStates, null, null), isFalse);
    // A wide *viewport* width must NOT satisfy a container condition.
    expect(c.matches(noStates, 9999, 100), isFalse);
  });

  test('conditions report their kind for the flattened-set ancestor scan', () {
    expect(const FwStateCondition(WidgetState.pressed).isState, isTrue);
    expect(const FwViewportCondition(FwBreakpoint.sm).isViewport, isTrue);
    expect(const FwViewportCondition(FwBreakpoint.sm).isContainer, isFalse);
    expect(const FwContainerCondition(FwBreakpoint.sm).isContainer, isTrue);
    expect(const FwContainerCondition(FwBreakpoint.sm).isState, isFalse);
  });

  group('FwGroupCondition', () {
    test('group relation matches against the group channel only', () {
      const c = FwGroupCondition(FwRelation.group, WidgetState.hovered);
      expect(
        c.matches(
          noStates,
          null,
          null,
          groupStates: <String?, Set<WidgetState>>{
            null: <WidgetState>{WidgetState.hovered},
          },
        ),
        isTrue,
      );
      // Same state on the *peer* channel must not satisfy a group condition.
      expect(
        c.matches(
          noStates,
          null,
          null,
          peerStates: <String?, Set<WidgetState>>{
            null: <WidgetState>{WidgetState.hovered},
          },
        ),
        isFalse,
      );
      // No maps at all → no match (and no throw).
      expect(c.matches(noStates, null, null), isFalse);
    });

    test('peer relation matches against the peer channel only', () {
      const c = FwGroupCondition(FwRelation.peer, WidgetState.focused);
      expect(
        c.matches(
          noStates,
          null,
          null,
          peerStates: <String?, Set<WidgetState>>{
            null: <WidgetState>{WidgetState.focused},
          },
        ),
        isTrue,
      );
      expect(
        c.matches(
          noStates,
          null,
          null,
          groupStates: <String?, Set<WidgetState>>{
            null: <WidgetState>{WidgetState.focused},
          },
        ),
        isFalse,
      );
    });

    test('named condition reads its own channel key, not the default', () {
      const named = FwGroupCondition(FwRelation.group, WidgetState.hovered, name: 'sidebar');
      final states = <String?, Set<WidgetState>>{
        null: <WidgetState>{WidgetState.hovered},
        'sidebar': <WidgetState>{},
      };
      // 'sidebar' is hovered? no — only the default channel is.
      expect(named.matches(noStates, null, null, groupStates: states), isFalse);
      states['sidebar'] = <WidgetState>{WidgetState.hovered};
      expect(named.matches(noStates, null, null, groupStates: states), isTrue);
    });

    test('is not a state/viewport/container condition for the ancestor scan', () {
      const c = FwGroupCondition(FwRelation.group, WidgetState.hovered);
      expect(c.isState, isFalse);
      expect(c.isViewport, isFalse);
      expect(c.isContainer, isFalse);
    });

    test('== and hashCode key on (relation, state, name)', () {
      const a = FwGroupCondition(FwRelation.group, WidgetState.hovered, name: 'x');
      const b = FwGroupCondition(FwRelation.group, WidgetState.hovered, name: 'x');
      const diffName = FwGroupCondition(FwRelation.group, WidgetState.hovered, name: 'y');
      const diffRel = FwGroupCondition(FwRelation.peer, WidgetState.hovered, name: 'x');
      const diffState = FwGroupCondition(FwRelation.group, WidgetState.focused, name: 'x');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(diffName)));
      expect(a, isNot(equals(diffRel)));
      expect(a, isNot(equals(diffState)));
    });
  });
}

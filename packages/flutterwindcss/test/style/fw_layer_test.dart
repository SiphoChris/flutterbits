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
}

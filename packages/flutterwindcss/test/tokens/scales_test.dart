import 'package:flutter/widgets.dart' show WidgetState;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

void main() {
  test('fwSpace maps 1 unit to 4 logical pixels', () {
    expect(fwSpace(0), 0);
    expect(fwSpace(0.5), 2);
    expect(fwSpace(4), 16);
  });

  test('FwBreakpoint carries Tailwind v4 min-widths', () {
    expect(FwBreakpoint.sm.minWidth, 640);
    expect(FwBreakpoint.md.minWidth, 768);
    expect(FwBreakpoint.lg.minWidth, 1024);
    expect(FwBreakpoint.xl.minWidth, 1280);
    expect(FwBreakpoint.xl2.minWidth, 1536);
  });

  test('FwState enumerates the four engine-sourced interaction states', () {
    expect(FwState.values, hasLength(4));
    expect(
      FwState.values,
      containsAll(<FwState>[FwState.hovered, FwState.focused, FwState.pressed, FwState.disabled]),
    );
  });

  test('fwOpacity converts 0..100 step to 0.0..1.0 and clamps out-of-range', () {
    expect(fwOpacity(0), 0.0);
    expect(fwOpacity(50), 0.5);
    expect(fwOpacity(100), 1.0);
    expect(fwOpacity(150), 1.0);
    expect(fwOpacity(-10), 0.0);
  });

  test('FwBlur sigma values match Tailwind v4 blur scale', () {
    expect(FwBlur.sm.sigma, 8);
    expect(FwBlur.xl3.sigma, 64);
  });

  test('fwBorderWidths is the Tailwind v4 border-width scale', () {
    expect(fwBorderWidths, <double>[0, 1, 2, 4, 8]);
  });

  test('fwZIndices is the Tailwind v4 z-index scale', () {
    expect(fwZIndices, <int>[0, 10, 20, 30, 40, 50]);
  });

  test('FwState.widgetState maps to the correct WidgetState', () {
    expect(FwState.hovered.widgetState, WidgetState.hovered);
    expect(FwState.disabled.widgetState, WidgetState.disabled);
  });
}

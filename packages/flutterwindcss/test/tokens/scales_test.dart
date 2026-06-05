import 'package:flutterwindcss/flutterwindcss.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(FwState.values, containsAll(<FwState>[
      FwState.hovered, FwState.focused, FwState.pressed, FwState.disabled,
    ]));
  });
}

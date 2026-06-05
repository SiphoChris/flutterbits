import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart' show FwBreakpoint, fwSpace;
import 'package:flutterwindcss/src/style/fw_layer.dart';
import 'package:flutterwindcss/src/style/fw_style.dart';

void main() {
  test('px sets horizontal padding in logical px; last-wins on repeat', () {
    final s = const FwStyle().px(4).px(2);
    expect(s.padding!.start, fwSpace(2));
    expect(s.padding!.end, fwSpace(2));
    expect(s.padding!.top, 0);
    expect(s.padding!.bottom, 0);
  });

  test('px then py keeps both axes (per-edge merge)', () {
    final s = const FwStyle().px(4).py(2);
    expect(s.padding!.start, fwSpace(4));
    expect(s.padding!.end, fwSpace(4));
    expect(s.padding!.top, fwSpace(2));
    expect(s.padding!.bottom, fwSpace(2));
  });

  test('p sets all edges; ps/pe/pt/pb set one edge', () {
    expect(const FwStyle().p(3).padding, EdgeInsetsDirectional.all(fwSpace(3)));
    expect(const FwStyle().ps(1).padding!.start, fwSpace(1));
    expect(const FwStyle().pe(1).padding!.end, fwSpace(1));
    expect(const FwStyle().pt(1).padding!.top, fwSpace(1));
    expect(const FwStyle().pb(1).padding!.bottom, fwSpace(1));
  });

  test('bg replaces the background (last-wins)', () {
    final s = const FwStyle().bg(const Color(0xFF111111)).bg(const Color(0xFF222222));
    expect(s.background, const Color(0xFF222222));
  });

  test('hover appends a state layer carrying the built nested style', () {
    final s = const FwStyle().hover((h) => h.bg(const Color(0xFF000000)));
    expect(s.layers, hasLength(1));
    final (cond, nested) = s.layers.first;
    expect(cond, const FwStateCondition(WidgetState.hovered));
    expect(nested.background, const Color(0xFF000000));
  });

  test('focus/pressed/disabled map to their WidgetStates', () {
    expect(
      const FwStyle().focus((s) => s).layers.first.$1,
      const FwStateCondition(WidgetState.focused),
    );
    expect(
      const FwStyle().pressed((s) => s).layers.first.$1,
      const FwStateCondition(WidgetState.pressed),
    );
    expect(
      const FwStyle().disabled((s) => s).layers.first.$1,
      const FwStateCondition(WidgetState.disabled),
    );
  });

  test('md/container append viewport/container layers; nest jointly', () {
    final s = const FwStyle().md((m) => m.hover((h) => h.bg(const Color(0xFF010101))));
    final (cond, nested) = s.layers.first;
    expect(cond, const FwViewportCondition(FwBreakpoint.md));
    expect(nested.layers.first.$1, const FwStateCondition(WidgetState.hovered));
  });

  test('all five viewport breakpoints map correctly', () {
    expect(
      const FwStyle().sm((s) => s).layers.first.$1,
      const FwViewportCondition(FwBreakpoint.sm),
    );
    expect(
      const FwStyle().lg((s) => s).layers.first.$1,
      const FwViewportCondition(FwBreakpoint.lg),
    );
    expect(
      const FwStyle().xl((s) => s).layers.first.$1,
      const FwViewportCondition(FwBreakpoint.xl),
    );
    expect(
      const FwStyle().xl2((s) => s).layers.first.$1,
      const FwViewportCondition(FwBreakpoint.xl2),
    );
  });

  test('container family maps to container conditions', () {
    expect(
      const FwStyle().containerSm((s) => s).layers.first.$1,
      const FwContainerCondition(FwBreakpoint.sm),
    );
    expect(
      const FwStyle().container2xl((s) => s).layers.first.$1,
      const FwContainerCondition(FwBreakpoint.xl2),
    );
  });

  test('whenState accepts arbitrary WidgetState', () {
    final s = const FwStyle().whenState(WidgetState.selected, (x) => x.bg(const Color(0xFF030303)));
    expect(s.layers.first.$1, const FwStateCondition(WidgetState.selected));
  });
}

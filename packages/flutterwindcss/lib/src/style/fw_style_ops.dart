import 'package:flutter/widgets.dart';

import '../tokens/scales.dart';
import 'fw_layer.dart';
import 'fw_style.dart';

/// The chainable builder utilities, defined once and shared by both [FwStyle]
/// (`T = FwStyle`, for nested-layer callbacks) and `FwStyled` (`T = FwStyled`,
/// the `.tw` widget). Implementers expose their current [fwStyle] and a
/// [fwRebuild] that wraps a new style back into `T`.
///
/// Module 3 ships only the **padding + bg** base setters (the engine's test
/// vehicle, module design §1) plus the **complete** variant/responsive/container
/// surface. Modules 4–9 extend this mixin with the remaining base setters.
mixin FwStyleOps<T> {
  /// The current accumulated style.
  FwStyle get fwStyle;

  /// Wraps [style] into the implementer's type (new `FwStyle` or new `FwStyled`).
  T fwRebuild(FwStyle style);

  // ---- Padding (per-edge merge; last-wins per edge) ----

  EdgeInsetsDirectional _mergePad({double? start, double? end, double? top, double? bottom}) {
    final p = fwStyle.padding ?? EdgeInsetsDirectional.zero;
    return EdgeInsetsDirectional.only(
      start: start ?? p.start,
      end: end ?? p.end,
      top: top ?? p.top,
      bottom: bottom ?? p.bottom,
    );
  }

  /// Padding on all sides, [units] × 4 logical px.
  T p(double units) =>
      fwRebuild(fwStyle.copyWith(padding: EdgeInsetsDirectional.all(fwSpace(units))));

  /// Horizontal padding (start + end).
  T px(double units) =>
      fwRebuild(fwStyle.copyWith(padding: _mergePad(start: fwSpace(units), end: fwSpace(units))));

  /// Vertical padding (top + bottom).
  T py(double units) =>
      fwRebuild(fwStyle.copyWith(padding: _mergePad(top: fwSpace(units), bottom: fwSpace(units))));

  /// Padding at the start edge (RTL-aware).
  T ps(double units) => fwRebuild(fwStyle.copyWith(padding: _mergePad(start: fwSpace(units))));

  /// Padding at the end edge (RTL-aware).
  T pe(double units) => fwRebuild(fwStyle.copyWith(padding: _mergePad(end: fwSpace(units))));

  /// Padding at the top edge.
  T pt(double units) => fwRebuild(fwStyle.copyWith(padding: _mergePad(top: fwSpace(units))));

  /// Padding at the bottom edge.
  T pb(double units) => fwRebuild(fwStyle.copyWith(padding: _mergePad(bottom: fwSpace(units))));

  // ---- Background ----

  /// Solid background fill (last-wins).
  T bg(Color color) => fwRebuild(fwStyle.copyWith(background: color));

  // ---- Variant layering ----

  T _layer(FwCondition condition, FwStyle Function(FwStyle) build) =>
      fwRebuild(fwStyle.addLayer(condition, build(const FwStyle())));

  /// Applies the built style while hovered.
  T hover(FwStyle Function(FwStyle) build) =>
      _layer(const FwStateCondition(WidgetState.hovered), build);

  /// Applies the built style while focused.
  T focus(FwStyle Function(FwStyle) build) =>
      _layer(const FwStateCondition(WidgetState.focused), build);

  /// Applies the built style while pressed.
  T pressed(FwStyle Function(FwStyle) build) =>
      _layer(const FwStateCondition(WidgetState.pressed), build);

  /// Applies the built style while disabled (suppresses hover/focus/pressed).
  T disabled(FwStyle Function(FwStyle) build) =>
      _layer(const FwStateCondition(WidgetState.disabled), build);

  /// Applies the built style while the given [state] is active. Escape hatch for
  /// component-managed states (e.g. selected); inert unless injected (§6.5).
  T whenState(WidgetState state, FwStyle Function(FwStyle) build) =>
      _layer(FwStateCondition(state), build);

  /// Applies the built style at viewport width ≥ `sm` (640).
  T sm(FwStyle Function(FwStyle) build) =>
      _layer(const FwViewportCondition(FwBreakpoint.sm), build);

  /// Applies the built style at viewport width ≥ `md` (768).
  T md(FwStyle Function(FwStyle) build) =>
      _layer(const FwViewportCondition(FwBreakpoint.md), build);

  /// Applies the built style at viewport width ≥ `lg` (1024).
  T lg(FwStyle Function(FwStyle) build) =>
      _layer(const FwViewportCondition(FwBreakpoint.lg), build);

  /// Applies the built style at viewport width ≥ `xl` (1280).
  T xl(FwStyle Function(FwStyle) build) =>
      _layer(const FwViewportCondition(FwBreakpoint.xl), build);

  /// Applies the built style at viewport width ≥ `2xl` (1536).
  T xl2(FwStyle Function(FwStyle) build) =>
      _layer(const FwViewportCondition(FwBreakpoint.xl2), build);

  /// Applies the built style at container width ≥ `sm` (640). See spec R6 caveat.
  T containerSm(FwStyle Function(FwStyle) build) =>
      _layer(const FwContainerCondition(FwBreakpoint.sm), build);

  /// Applies the built style at container width ≥ `md` (768).
  T containerMd(FwStyle Function(FwStyle) build) =>
      _layer(const FwContainerCondition(FwBreakpoint.md), build);

  /// Applies the built style at container width ≥ `lg` (1024).
  T containerLg(FwStyle Function(FwStyle) build) =>
      _layer(const FwContainerCondition(FwBreakpoint.lg), build);

  /// Applies the built style at container width ≥ `xl` (1280).
  T containerXl(FwStyle Function(FwStyle) build) =>
      _layer(const FwContainerCondition(FwBreakpoint.xl), build);

  /// Applies the built style at container width ≥ `2xl` (1536).
  T container2xl(FwStyle Function(FwStyle) build) =>
      _layer(const FwContainerCondition(FwBreakpoint.xl2), build);
}

import 'package:flutter/widgets.dart';

import '../tokens/scales.dart';
import 'fw_border_spec.dart';
import 'fw_layer.dart';
import 'fw_style.dart';

/// The chainable builder utilities, defined once and shared by both [FwStyle]
/// (`T = FwStyle`, for nested-layer callbacks) and `FwStyled` (`T = FwStyled`,
/// the `.tw` widget). Implementers expose their current [fwStyle] and a
/// [fwRebuild] that wraps a new style back into `T`.
///
/// Module 3 shipped the **padding + bg** base setters (the engine's test
/// vehicle, module design §1) plus the **complete** variant/responsive/container
/// surface. Module 4 added the **spacing + sizing** setters (margin, fixed/min/max
/// sizing, fractional sizing + alignment, aspect/square). Module 5 added the
/// **color/border/radius** setters (gradient, per-edge directional border,
/// per-corner directional radius, clip). Modules 6–9 extend this mixin with the
/// remaining base setters (typography, effects, transforms).
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

  // ---- Margin (per-edge merge; last-wins per edge — mirrors padding) ----

  EdgeInsetsDirectional _mergeMargin({double? start, double? end, double? top, double? bottom}) {
    final m = fwStyle.margin ?? EdgeInsetsDirectional.zero;
    return EdgeInsetsDirectional.only(
      start: start ?? m.start,
      end: end ?? m.end,
      top: top ?? m.top,
      bottom: bottom ?? m.bottom,
    );
  }

  /// Margin on all sides, [units] × 4 logical px.
  T m(double units) =>
      fwRebuild(fwStyle.copyWith(margin: EdgeInsetsDirectional.all(fwSpace(units))));

  /// Horizontal margin (start + end).
  T mx(double units) =>
      fwRebuild(fwStyle.copyWith(margin: _mergeMargin(start: fwSpace(units), end: fwSpace(units))));

  /// Vertical margin (top + bottom).
  T my(double units) => fwRebuild(
    fwStyle.copyWith(margin: _mergeMargin(top: fwSpace(units), bottom: fwSpace(units))),
  );

  /// Margin at the start edge (RTL-aware).
  T ms(double units) => fwRebuild(fwStyle.copyWith(margin: _mergeMargin(start: fwSpace(units))));

  /// Margin at the end edge (RTL-aware).
  T me(double units) => fwRebuild(fwStyle.copyWith(margin: _mergeMargin(end: fwSpace(units))));

  /// Margin at the top edge.
  T mt(double units) => fwRebuild(fwStyle.copyWith(margin: _mergeMargin(top: fwSpace(units))));

  /// Margin at the bottom edge.
  T mb(double units) => fwRebuild(fwStyle.copyWith(margin: _mergeMargin(bottom: fwSpace(units))));

  // ---- Sizing (fixed / min / max; utility units → logical px) ----
  //
  // Tailwind's width/height scale is its spacing scale (`w-4` = 1rem = 16px), so
  // these reuse [fwSpace]. A fixed dim produces a tight constraint and wins its
  // axis; `min*`/`max*` apply only to axes without a fixed value — the render
  // chain's sizing reconciliation (spec §6.4 Finding #6) governs how they
  // combine (and asserts against a fixed dim + min/max on the same axis).

  /// Fixed width, [units] × 4 logical px (tight constraint, wins its axis).
  T w(double units) => fwRebuild(fwStyle.copyWith(width: fwSpace(units)));

  /// Fixed height, [units] × 4 logical px (tight constraint, wins its axis).
  T h(double units) => fwRebuild(fwStyle.copyWith(height: fwSpace(units)));

  /// Minimum width, [units] × 4 logical px.
  T minW(double units) => fwRebuild(fwStyle.copyWith(minWidth: fwSpace(units)));

  /// Minimum height, [units] × 4 logical px.
  T minH(double units) => fwRebuild(fwStyle.copyWith(minHeight: fwSpace(units)));

  /// Maximum width, [units] × 4 logical px.
  T maxW(double units) => fwRebuild(fwStyle.copyWith(maxWidth: fwSpace(units)));

  /// Maximum height, [units] × 4 logical px.
  T maxH(double units) => fwRebuild(fwStyle.copyWith(maxHeight: fwSpace(units)));

  // ---- Fractional sizing (FractionallySizedBox factors) ----

  /// Fractional width, [factor] of the parent (e.g. `0.5` = half). [align]
  /// (default `centerStart` at resolve time) is the only control over fractional
  /// alignment (spec §6.5); it is shared with [hFraction] (last-wins).
  T wFraction(double factor, {AlignmentDirectional? align}) =>
      fwRebuild(fwStyle.copyWith(widthFactor: factor, factorAlignment: align));

  /// Fractional height, [factor] of the parent. See [wFraction] re [align].
  T hFraction(double factor, {AlignmentDirectional? align}) =>
      fwRebuild(fwStyle.copyWith(heightFactor: factor, factorAlignment: align));

  /// Fills the parent's width (Tailwind `w-full`); sugar for `wFraction(1)`.
  T get wFull => wFraction(1);

  /// Fills the parent's height (Tailwind `h-full`); sugar for `hFraction(1)`.
  T get hFull => hFraction(1);

  // ---- Aspect ratio ----

  /// Constrains the box to [ratio] (width / height).
  T aspect(double ratio) => fwRebuild(fwStyle.copyWith(aspectRatio: ratio));

  /// Square aspect ratio; sugar for `aspect(1)`. Writes the `aspectRatio` field
  /// (so it last-wins against [aspect]); it does **not** set `width == height`.
  T get square => aspect(1);

  // ---- Background ----

  /// Solid background fill (last-wins).
  T bg(Color color) => fwRebuild(fwStyle.copyWith(background: color));

  // ---- Gradient ----

  /// Gradient background fill (replaces a solid [bg] when both are set; the
  /// render chain prefers the gradient). Last-wins.
  T bgGradient(Gradient gradient) => fwRebuild(fwStyle.copyWith(gradient: gradient));

  // ---- Border (per-edge merge; color & width are independent axes) ----
  //
  // Widths are in **logical px** (Tailwind's 0/1/2/4/8 `fwBorderWidths` scale),
  // NOT utility units — borders ride the border-width scale, not spacing. An edge
  // paints only when width > 0; color defaults to BorderSide's opaque black until
  // set (components pass `context.fw.colors.border`).

  FwBorderSpec get _borderSpec => fwStyle.borderSpec ?? const FwBorderSpec();

  // A negative stroke width is meaningless; guard it with a clear flutterwindcss
  // message rather than leaving it to BorderSide's terser internal assert.
  static double _checkWidth(double width) {
    assert(width >= 0, 'flutterwindcss: border width must be >= 0 (got $width).');
    return width;
  }

  BorderSide _withWidth(BorderSide? s, double width) =>
      (s ?? const BorderSide()).copyWith(width: _checkWidth(width), style: BorderStyle.solid);

  BorderSide _withColor(BorderSide? s, Color color) =>
      (s ?? const BorderSide(width: 0)).copyWith(color: color, style: BorderStyle.solid);

  FwBorderSpec _borderEach(BorderSide Function(BorderSide?) f) {
    final b = _borderSpec;
    return FwBorderSpec(start: f(b.start), end: f(b.end), top: f(b.top), bottom: f(b.bottom));
  }

  BorderSide _edge(BorderSide? existing, double? width, Color? color) {
    var s = (existing ?? const BorderSide(width: 0)).copyWith(style: BorderStyle.solid);
    if (width != null) s = s.copyWith(width: _checkWidth(width));
    if (color != null) s = s.copyWith(color: color);
    return s;
  }

  /// Uniform border of [width] logical px on every edge (plus [color] if given).
  /// Tailwind's bare `border` is `border(1)`. With no [color] the edge defaults to
  /// opaque black — pass a semantic token (`context.fw.colors.border`) in
  /// components. A per-side (non-uniform) border **cannot** be rounded; combining
  /// it with `rounded*` asserts at build time (Flutter limitation; see the render
  /// chain). [width] must be `>= 0`.
  T border(double width, {Color? color}) => fwRebuild(
    fwStyle.copyWith(
      borderSpec: _borderEach((s) {
        var side = _withWidth(s, width);
        if (color != null) side = side.copyWith(color: color);
        return side;
      }),
    ),
  );

  /// Sets the border [width] (logical px) on every edge, keeping each edge color.
  T borderWidth(double width) =>
      fwRebuild(fwStyle.copyWith(borderSpec: _borderEach((s) => _withWidth(s, width))));

  /// Sets the border [color] on every edge, keeping each edge width.
  T borderColor(Color color) =>
      fwRebuild(fwStyle.copyWith(borderSpec: _borderEach((s) => _withColor(s, color))));

  /// Border on the start edge (RTL-aware); merges with the other edges.
  T borderS({double? width, Color? color}) => fwRebuild(
    fwStyle.copyWith(borderSpec: _borderSpec.merge(start: _edge(_borderSpec.start, width, color))),
  );

  /// Border on the end edge (RTL-aware); merges with the other edges.
  T borderE({double? width, Color? color}) => fwRebuild(
    fwStyle.copyWith(borderSpec: _borderSpec.merge(end: _edge(_borderSpec.end, width, color))),
  );

  /// Border on the top edge; merges with the other edges.
  T borderT({double? width, Color? color}) => fwRebuild(
    fwStyle.copyWith(borderSpec: _borderSpec.merge(top: _edge(_borderSpec.top, width, color))),
  );

  /// Border on the bottom edge; merges with the other edges.
  T borderB({double? width, Color? color}) => fwRebuild(
    fwStyle.copyWith(
      borderSpec: _borderSpec.merge(bottom: _edge(_borderSpec.bottom, width, color)),
    ),
  );

  // ---- Radius (per-corner merge; directional) ----
  //
  // Radius args are in **logical px** (token values like `t.radii.md`,
  // `FwRadiusScale.*`), NOT utility units.

  BorderRadiusDirectional _mergeRadius({
    Radius? topStart,
    Radius? topEnd,
    Radius? bottomStart,
    Radius? bottomEnd,
  }) {
    final r = fwStyle.borderRadius ?? BorderRadiusDirectional.zero;
    return BorderRadiusDirectional.only(
      topStart: topStart ?? r.topStart,
      topEnd: topEnd ?? r.topEnd,
      bottomStart: bottomStart ?? r.bottomStart,
      bottomEnd: bottomEnd ?? r.bottomEnd,
    );
  }

  // A negative corner radius is meaningless and (unlike a width) Radius.circular
  // does NOT guard it, so assert here with a clear flutterwindcss message.
  static Radius _circular(double radius) {
    assert(radius >= 0, 'flutterwindcss: border radius must be >= 0 (got $radius).');
    return Radius.circular(radius);
  }

  /// Rounds every corner to [radius] logical px (overwrites all corners, last-wins).
  T rounded(double radius) =>
      fwRebuild(fwStyle.copyWith(borderRadius: BorderRadiusDirectional.all(_circular(radius))));

  /// Explicit synonym of [rounded] (the spec's named `roundedAll` surface).
  T roundedAll(double radius) => rounded(radius);

  /// Rounds the top corners (topStart + topEnd); merges per-corner.
  T roundedT(double radius) => fwRebuild(
    fwStyle.copyWith(
      borderRadius: _mergeRadius(topStart: _circular(radius), topEnd: _circular(radius)),
    ),
  );

  /// Rounds the bottom corners (bottomStart + bottomEnd); merges per-corner.
  T roundedB(double radius) => fwRebuild(
    fwStyle.copyWith(
      borderRadius: _mergeRadius(bottomStart: _circular(radius), bottomEnd: _circular(radius)),
    ),
  );

  /// Rounds the start corners (topStart + bottomStart, RTL-aware); merges per-corner.
  T roundedS(double radius) => fwRebuild(
    fwStyle.copyWith(
      borderRadius: _mergeRadius(topStart: _circular(radius), bottomStart: _circular(radius)),
    ),
  );

  /// Rounds the end corners (topEnd + bottomEnd, RTL-aware); merges per-corner.
  T roundedE(double radius) => fwRebuild(
    fwStyle.copyWith(
      borderRadius: _mergeRadius(topEnd: _circular(radius), bottomEnd: _circular(radius)),
    ),
  );

  /// Removes all rounding (overwrites all corners).
  T get roundedNone => fwRebuild(fwStyle.copyWith(borderRadius: BorderRadiusDirectional.zero));

  /// Pill / fully-rounded corners (radius 9999).
  T get roundedFull => rounded(9999);

  // ---- Clip ----

  /// Clips overflowing content to the box shape. With a corner radius the clip
  /// reuses it **deflated by the border width** (spec §6.4 Finding #3); with no
  /// radius it clips to the rectangle (it never silently no-ops).
  T clip([Clip behavior = Clip.antiAlias]) => fwRebuild(fwStyle.copyWith(clipBehavior: behavior));

  // ---- Typography ----
  //
  // Setters take clean, collision-free names (the FwStyle fields already own
  // `fontSize`/`fontWeight`/`textAlign`, and FwStyle mixes in these ops). Sizes
  // are logical px; `leading` is a line-height multiple; `tracking` is absolute
  // logical px (Flutter's model), NOT em — to use the em-based FwTracking scale,
  // multiply by the font size, e.g. `tracking(FwTracking.wide * FwFontSize.base.px)`.

  /// Default text/icon color for descendants (Tailwind `text-{color}`).
  T text(Color color) => fwRebuild(fwStyle.copyWith(foreground: color));

  /// Default font size in logical px (Tailwind `text-{size}`); also sets icon
  /// size. Pass a token value like `FwFontSize.lg.px`. Must be `> 0`.
  T textSize(double px) {
    assert(px > 0, 'flutterwindcss: font size must be > 0 (got $px).');
    return fwRebuild(fwStyle.copyWith(fontSize: px));
  }

  /// Default font weight on the CSS scale `100..900` (Tailwind `font-{weight}`);
  /// pass a token like `FwFontWeight.semibold`. Maps to a Flutter [FontWeight].
  T weight(int weight) {
    assert(
      weight >= 100 && weight <= 900 && weight % 100 == 0,
      'flutterwindcss: font weight must be 100..900 in steps of 100 (got $weight).',
    );
    return fwRebuild(fwStyle.copyWith(fontWeight: FontWeight.values[(weight ~/ 100) - 1]));
  }

  /// Default line-height as a multiple of the font size (Tailwind `leading-*`);
  /// pass a token like `FwLeading.normal`. Must be `> 0`.
  T leading(double multiple) {
    assert(
      multiple > 0,
      'flutterwindcss: leading (line-height multiple) must be > 0 (got $multiple).',
    );
    return fwRebuild(fwStyle.copyWith(lineHeight: multiple));
  }

  /// Default letter-spacing in **absolute logical px** (Flutter's model;
  /// Tailwind/`FwTracking` are em — multiply by the font size to convert). May be
  /// negative (tighter tracking).
  T tracking(double logicalPx) => fwRebuild(fwStyle.copyWith(letterSpacing: logicalPx));

  /// Default text alignment (Tailwind `text-{align}`); `start`/`end` are RTL-aware.
  T align(TextAlign align) => fwRebuild(fwStyle.copyWith(textAlign: align));

  T _addDecoration(TextDecoration d) {
    final existing = fwStyle.textDecoration;
    final combined = existing == null || existing == TextDecoration.none
        ? d
        : TextDecoration.combine(<TextDecoration>[existing, d]);
    return fwRebuild(fwStyle.copyWith(textDecoration: combined));
  }

  /// Underlines descendant text; combines with any existing decoration (Tailwind
  /// `underline`).
  T get underline => _addDecoration(TextDecoration.underline);

  /// Strikes through descendant text; combines with any existing decoration
  /// (Tailwind `line-through`).
  T get lineThrough => _addDecoration(TextDecoration.lineThrough);

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

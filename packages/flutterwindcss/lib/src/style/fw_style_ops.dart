import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../tokens/scales.dart';
import '../tokens/typography.dart';
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
/// per-corner directional radius, clip). Module 6 added the **typography**
/// setters (text color, size, weight, leading, tracking, align, underline/
/// line-through). Module 7 added the **effects** setters (shadow, opacity, blur,
/// backdrop-blur). Module 8 shipped the **layout widgets** (`FwRow`/`FwColumn`/
/// `FwWrap`/`FwStack`/`FwPositioned`/`FwGrid`) — dedicated multi-child widgets,
/// *not* `.tw` setters (spec §6.0/§6.6), with first-class responsive
/// layout-property layering via per-widget `viewport`/`container` patch maps —
/// and confirmed the container-query family (`containerSm…`) already shipped here
/// in module 3. Module 9 added the **transform** setters (`scale`/`rotate`/
/// `translate`/`translateX`/`translateY`, paint-only). Module 10 (animated
/// theming) is a dedicated widget, not a `.tw` setter. Module 11 added **text
/// completeness** (`font`/`fontSans`/`fontSerif`/`fontMono`, `maxLines`,
/// `lineClamp`, `truncate`, `overflow`, `nowrap`/`wrap`). Module 12 added
/// **filters + object-fit** (`grayscale`/`brightness`/`contrast`/`saturate`/
/// `invert`/`sepia`/`hueRotate` — composed CSS color filters — and `fit`).
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
  ///
  /// [align] only **sets** the alignment; omitting it keeps any previously-set
  /// value (it cannot clear back to the default — `copyWith` treats `null` as
  /// "keep"). To change it, pass an explicit [align].
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
  ///
  /// Validated with a **runtime throw** (not an `assert`): the value indexes a
  /// fixed-length list, so an assert — stripped in release — would surface an
  /// invalid weight as an opaque `RangeError`. Throwing keeps the error clear and
  /// the behavior defined in both debug and release.
  T weight(int weight) {
    if (weight < 100 || weight > 900 || weight % 100 != 0) {
      throw ArgumentError.value(
        weight,
        'weight',
        'flutterwindcss: font weight must be 100..900 in steps of 100',
      );
    }
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
    final combined =
        existing == null || existing == TextDecoration.none
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

  // ---- Text completeness (module 11): family, line-clamp/truncate, wrapping ----
  //
  // All ride the existing `DefaultTextStyle.merge` (which carries `fontFamily`,
  // `maxLines`, `overflow`, `softWrap`), so they inherit into descendant text
  // exactly like the other typography setters.

  /// Default font family for descendant text (Tailwind `font-[family]`); pass a
  /// token such as `FwFontFamily.sans`. Last-wins.
  T font(String family) => fwRebuild(fwStyle.copyWith(fontFamily: family));

  /// Sans-serif family (Tailwind `font-sans`).
  T get fontSans => font(FwFontFamily.sans);

  /// Serif family (Tailwind `font-serif`).
  T get fontSerif => font(FwFontFamily.serif);

  /// Monospace family (Tailwind `font-mono`).
  T get fontMono => font(FwFontFamily.mono);

  /// Caps descendant text at [lines] lines, *without* forcing an overflow style.
  /// Must be `> 0`. For Tailwind `line-clamp-*` (which ellipsizes) use [lineClamp].
  T maxLines(int lines) {
    assert(lines > 0, 'flutterwindcss: maxLines must be > 0 (got $lines).');
    return fwRebuild(fwStyle.copyWith(maxLineCount: lines));
  }

  /// Tailwind `line-clamp-N`: cap at [lines] lines and ellipsize the overflow.
  /// Must be `> 0`.
  T lineClamp(int lines) {
    assert(lines > 0, 'flutterwindcss: lineClamp must be > 0 (got $lines).');
    return fwRebuild(fwStyle.copyWith(maxLineCount: lines, textOverflow: TextOverflow.ellipsis));
  }

  /// Tailwind `truncate`: a single, non-wrapping line ending in an ellipsis.
  T get truncate => fwRebuild(
    fwStyle.copyWith(maxLineCount: 1, textOverflow: TextOverflow.ellipsis, softWrap: false),
  );

  /// How descendant text overflows once it hits its line cap (Tailwind
  /// `text-ellipsis` / `text-clip`; also `fade` / `visible`).
  T overflow(TextOverflow behavior) => fwRebuild(fwStyle.copyWith(textOverflow: behavior));

  /// Prevents soft-wrapping — forces one line (Tailwind `whitespace-nowrap`).
  T get nowrap => fwRebuild(fwStyle.copyWith(softWrap: false));

  /// (Re-)enables soft-wrapping (Tailwind `whitespace-normal`) — handy to undo a
  /// `nowrap`/`truncate` inside a responsive or state layer.
  T get wrap => fwRebuild(fwStyle.copyWith(softWrap: true));

  // ---- Effects ----
  //
  // The FwStyle fields are named groupOpacity/contentBlur/backdropBlurSigma so
  // these Tailwind-natural setters don't collide (the field names also match the
  // render-chain's "group opacity" / "content blur" terminology). Blur args are
  // Gaussian sigmas in logical px.

  /// Drop shadow from the theme scale; pass a resolved list like
  /// `context.fw.shadows.md` (an empty list = no shadow). Last-wins.
  T shadow(List<BoxShadow> shadows) => fwRebuild(fwStyle.copyWith(boxShadow: shadows));

  /// Group opacity `0.0..1.0` (Tailwind `opacity-*`); `fwOpacity(50)` maps the
  /// `0..100` scale. Applies to the whole box as one layer.
  T opacity(double value) {
    assert(value >= 0.0 && value <= 1.0, 'flutterwindcss: opacity must be 0.0..1.0 (got $value).');
    return fwRebuild(fwStyle.copyWith(groupOpacity: value));
  }

  /// Content blur — Gaussian sigma in logical px, blurs the whole element
  /// (Tailwind `blur-*`; `FwBlur.md.sigma` for the named scale). Must be `>= 0`.
  T blur(double sigma) {
    assert(sigma >= 0, 'flutterwindcss: blur sigma must be >= 0 (got $sigma).');
    return fwRebuild(fwStyle.copyWith(contentBlur: sigma));
  }

  /// Backdrop blur — frosts content painted *behind* the box (Tailwind
  /// `backdrop-blur-*`). Gaussian sigma in logical px; must be `>= 0`.
  T backdropBlur(double sigma) {
    assert(sigma >= 0, 'flutterwindcss: backdrop blur sigma must be >= 0 (got $sigma).');
    return fwRebuild(fwStyle.copyWith(backdropBlurSigma: sigma));
  }

  // ---- Filters (CSS filter color functions) + object-fit (module 12) ----
  //
  // Color filters resolve to one `ColorFilter.matrix`. They **compose** within a
  // chain (CSS `filter: a() b()` applies a then b) by matrix multiply, so
  // `.grayscale().brightness(1.2)` is grayscale *then* brighten. (Content `blur`
  // is the one CSS filter kept separate — it's a spatial `ImageFilter`, not a
  // color matrix.)

  /// Composes [matrix] after any existing color filter (new applies last).
  T _applyColorFilter(List<double> matrix) {
    final existing = fwStyle.colorMatrix;
    return fwRebuild(
      fwStyle.copyWith(
        colorMatrix: existing == null ? matrix : _composeColorMatrix(matrix, existing),
      ),
    );
  }

  /// Saturation (Tailwind `saturate-*`): `1` = unchanged, `0` = grayscale, `>1`
  /// more saturated. Must be `>= 0`.
  T saturate(double amount) {
    assert(amount >= 0, 'flutterwindcss: saturate must be >= 0 (got $amount).');
    return _applyColorFilter(_saturateMatrix(amount));
  }

  /// Grayscale (Tailwind `grayscale`): [amount] `0..1` (`1` = fully gray).
  T grayscale([double amount = 1]) {
    assert(amount >= 0 && amount <= 1, 'flutterwindcss: grayscale must be 0..1 (got $amount).');
    return _applyColorFilter(_saturateMatrix(1 - amount));
  }

  /// Brightness (Tailwind `brightness-*`): `1` = unchanged, scales RGB. `>= 0`.
  T brightness(double amount) {
    assert(amount >= 0, 'flutterwindcss: brightness must be >= 0 (got $amount).');
    return _applyColorFilter(_scaleColorMatrix(amount));
  }

  /// Contrast (Tailwind `contrast-*`): `1` = unchanged. `>= 0`.
  T contrast(double amount) {
    assert(amount >= 0, 'flutterwindcss: contrast must be >= 0 (got $amount).');
    return _applyColorFilter(_contrastMatrix(amount));
  }

  /// Invert (Tailwind `invert`): [amount] `0..1` (`1` = fully inverted).
  T invert([double amount = 1]) {
    assert(amount >= 0 && amount <= 1, 'flutterwindcss: invert must be 0..1 (got $amount).');
    return _applyColorFilter(_invertMatrix(amount));
  }

  /// Sepia (Tailwind `sepia`): [amount] `0..1`.
  T sepia([double amount = 1]) {
    assert(amount >= 0 && amount <= 1, 'flutterwindcss: sepia must be 0..1 (got $amount).');
    return _applyColorFilter(_sepiaMatrix(amount));
  }

  /// Hue rotation in **degrees** (Tailwind `hue-rotate-*`).
  T hueRotate(double degrees) => _applyColorFilter(_hueRotateMatrix(degrees));

  /// Object-fit for the child content (Tailwind `object-*`): wraps it in a
  /// `FittedBox`. Mainly for images/replaced content. Needs a **bounded** box to
  /// fit into (set a size, or place it where the parent constrains it); under an
  /// unbounded constraint on the fitted axis it safely degrades to no scaling
  /// (the child renders at its natural size) rather than throwing.
  T fit(BoxFit fit) => fwRebuild(fwStyle.copyWith(boxFit: fit));

  // ---- Transform (paint-only; does NOT change the box's layout footprint) ----
  //
  // Like CSS `transform`, these change painting + hit-testing but not layout — a
  // `.scale(1.5)` box still occupies its unscaled size and can visually overlap
  // siblings (spec §6.4). `rotate` is in **degrees** (Tailwind `rotate-*`);
  // `translate*` are in **utility units** (× 4 px, Tailwind `translate-*`);
  // `scale` is **uniform** (Tailwind `scale-*`). Composition order is fixed by the
  // render chain (T·R·S — scale, then rotate, then translate).

  /// Uniform scale factor (Tailwind `scale-*`; `1.0` = identity, `<1` shrinks,
  /// negatives flip). Paint-only — does not reflow siblings. Per-axis `scale-x`/
  /// `scale-y` are not in v1 (the engine's scale field is uniform).
  T scale(double factor) => fwRebuild(fwStyle.copyWith(scaleFactor: factor));

  /// Rotation in **degrees**, clockwise (Tailwind `rotate-*`; stored internally
  /// as radians). Paint-only.
  T rotate(double degrees) => fwRebuild(fwStyle.copyWith(rotation: degrees * math.pi / 180.0));

  Offset get _translation => fwStyle.translation ?? Offset.zero;

  /// Translation by ([x], [y]) **utility units** (Tailwind `translate-*`).
  /// Physical axes (not directional — matches CSS `translate`). Paint-only.
  T translate(double x, double y) =>
      fwRebuild(fwStyle.copyWith(translation: Offset(fwSpace(x), fwSpace(y))));

  /// Horizontal translation (utility units), keeping any vertical translate.
  T translateX(double x) =>
      fwRebuild(fwStyle.copyWith(translation: Offset(fwSpace(x), _translation.dy)));

  /// Vertical translation (utility units), keeping any horizontal translate.
  T translateY(double y) =>
      fwRebuild(fwStyle.copyWith(translation: Offset(_translation.dx, fwSpace(y))));

  // ---- Variant layering ----
  //
  // A variant callback receives a FRESH `FwStyle` (not the base), and at resolve
  // time a matching layer overlays the base **whole-field, last-wins** — it does
  // NOT merge per-edge with the base. Per-edge merge (`.px(4).py(2)`) only
  // happens *within one chain*. So `.p(4).hover((s) => s.pt(8))` resolves, while
  // hovered, to padding `top: 32` and **0 on the other edges** — not `16` with a
  // `32` top. To keep the other edges, restate them in the layer
  // (`.hover((s) => s.p(4).pt(8))`). Precedence across matching layers is the
  // cascade documented on `FwStyle.resolve` (breakpoints by min-width, then
  // states; declaration order breaks ties) — not raw chain order.

  T _layer(FwCondition condition, FwStyle Function(FwStyle) build) =>
      fwRebuild(fwStyle.addLayer(condition, build(const FwStyle())));

  /// Applies the built style while hovered.
  T hover(FwStyle Function(FwStyle) build) =>
      _layer(const FwStateCondition(WidgetState.hovered), build);

  /// Applies the built style while focused.
  ///
  /// Note: the engine's visual-only state sourcing uses a **non-traversable**
  /// `Focus` (§6.2), so a bare `.tw` box is never itself focusable — a `focus:`
  /// layer on a non-interactive box therefore won't trigger on its own. Focus +
  /// a visible ring belong to an **interactive component** (which owns the action
  /// and a real focusable detector); use `focus:` there, or feed `focused` via
  /// `FwStyled.states`.
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

// ---------------------------------------------------------------------------
// CSS color-filter matrices (4×5, 20 values, row-major [R G B A bias] per output
// channel; bias is in the 0..255 channel scale, matching `ColorFilter.matrix`).
// The luma weights (0.213/0.715/0.072) are the same set CSS/SVG use.
// ---------------------------------------------------------------------------

/// SVG/CSS `saturate(s)` matrix (`s == 1` ⇒ identity, `0` ⇒ grayscale).
List<double> _saturateMatrix(double s) => <double>[
  0.213 + 0.787 * s,
  0.715 - 0.715 * s,
  0.072 - 0.072 * s,
  0,
  0,
  0.213 - 0.213 * s,
  0.715 + 0.285 * s,
  0.072 - 0.072 * s,
  0,
  0,
  0.213 - 0.213 * s,
  0.715 - 0.715 * s,
  0.072 + 0.928 * s,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

/// `brightness(b)` — scales RGB by [b].
List<double> _scaleColorMatrix(double b) => <double>[
  b,
  0,
  0,
  0,
  0,
  0,
  b,
  0,
  0,
  0,
  0,
  0,
  b,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

/// `contrast(c)` — `out = c·in + 127.5·(1 − c)`.
List<double> _contrastMatrix(double c) {
  final t = 127.5 * (1 - c);
  return <double>[c, 0, 0, 0, t, 0, c, 0, 0, t, 0, 0, c, 0, t, 0, 0, 0, 1, 0];
}

/// `invert(a)` — `out = (1 − 2a)·in + 255a`.
List<double> _invertMatrix(double a) {
  final d = 1 - 2 * a;
  final t = 255 * a;
  return <double>[d, 0, 0, 0, t, 0, d, 0, 0, t, 0, 0, d, 0, t, 0, 0, 0, 1, 0];
}

/// `sepia(a)` — linear blend of identity and full sepia by [a].
List<double> _sepiaMatrix(double a) {
  const full = <double>[
    0.393,
    0.769,
    0.189,
    0,
    0,
    0.349,
    0.686,
    0.168,
    0,
    0,
    0.272,
    0.534,
    0.131,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
  const identity = <double>[1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];
  return <double>[for (var i = 0; i < 20; i++) identity[i] * (1 - a) + full[i] * a];
}

/// SVG/CSS `hue-rotate(deg)` matrix.
List<double> _hueRotateMatrix(double degrees) {
  final r = degrees * math.pi / 180.0;
  final c = math.cos(r);
  final s = math.sin(r);
  return <double>[
    0.213 + c * 0.787 - s * 0.213,
    0.715 - c * 0.715 - s * 0.715,
    0.072 - c * 0.072 + s * 0.928,
    0,
    0,
    0.213 - c * 0.213 + s * 0.143,
    0.715 + c * 0.285 + s * 0.140,
    0.072 - c * 0.072 - s * 0.283,
    0,
    0,
    0.213 - c * 0.213 - s * 0.787,
    0.715 - c * 0.715 + s * 0.715,
    0.072 + c * 0.928 + s * 0.072,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
}

/// Composes two 4×5 color matrices: applies [inner] first, then [outer]
/// (`outer ∘ inner`). Each is extended to 5×5 with a `[0,0,0,0,1]` row.
List<double> _composeColorMatrix(List<double> outer, List<double> inner) {
  double at(List<double> m, int row, int col) =>
      row < 4 ? m[row * 5 + col] : (col == 4 ? 1.0 : 0.0);
  final out = List<double>.filled(20, 0);
  for (var i = 0; i < 4; i++) {
    for (var j = 0; j < 5; j++) {
      var sum = 0.0;
      for (var k = 0; k < 5; k++) {
        sum += at(outer, i, k) * at(inner, k, j);
      }
      out[i * 5 + j] = sum;
    }
  }
  return out;
}

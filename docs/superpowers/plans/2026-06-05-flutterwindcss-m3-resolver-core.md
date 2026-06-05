# flutterwindcss Module 3 — Resolver Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> **Correction (post-execution).** This plan is left as-written for historical accuracy, but three things changed during TDD (each stricter/more correct; all reflected in the engine spec §6 and the design doc's §7 "As-built corrections"):
> 1. **`resolve` takes two widths** — `resolve(states, {viewportWidth, containerWidth})`, not a single unified `width`/`Size`. Viewport and container layers resolve independently. (The "Self-Review Notes" already flagged the unified-width approach as a gap; the gap was fixed at implementation time.)
> 2. **Interaction sourcing uses `MouseRegion` + non-traversable `Focus` + `Listener`**, not `FocusableActionDetector` (which can't be made non-traversable while enabled and would add a tab stop, violating §7). Tasks 7's FAD-based skeleton was superseded.
> 3. **Interaction wrappers activate only for live-sourced states** (`hover`/`focus`/`pressed`); component-managed states (`selected`/`disabled`) inject via `FwStyled.states` and resolve statelessly.
> Two render-chain details are **deferred and tracked** (not silently dropped): content-clip radius **deflation** (Finding #3) → module 5 (coupled to border width); opacity **fold** (Finding #11) → later perf pass (an always-correct `Opacity` is emitted meanwhile).

**Goal:** Build the `FwStyle` lazy resolver engine — the nested-layer styling core, the complete §6.4 render chain, and the `FwStyled`/`.tw` widget — so the engine is structurally complete and modules 4–9 only add typed base-setter sugar.

**Architecture:** An immutable `FwStyle` data class holds all single-box style fields plus a list of nested `FwLayer`s. Builder methods live once in a shared `FwStyleOps<T>` mixin, mixed into both `FwStyle` (`T = FwStyle`, for nested-layer callbacks) and `FwStyled` (`T = FwStyled`, the `.tw` widget). `FwStyle.resolve(context, states, width)` flattens base + matching nested layers (last-wins, disabled-suppressed) into a `ResolvedStyle`, whose `build(child)` emits the fixed outer→inner primitive chain, each wrapper present only when its field is set. `FwStyled` conditionally inserts `MediaQuery`/`LayoutBuilder`/`FocusableActionDetector` ancestors based on the flattened layer set.

**Tech Stack:** Dart 3.7+/Flutter 3.29+ widgets layer only (`package:flutter/widgets.dart`), `flutter_test`. No new deps. Depends on Module 1 tokens + Module 2 `context.fw` (merged on `main`).

**Spec:** core engine design `docs/superpowers/specs/2026-06-05-flutterwindcss-core-engine-design.md` §6, §7, §10, §11; module design `docs/superpowers/specs/2026-06-05-flutterwindcss-m3-resolver-core-design.md`.

---

## File Structure

All under `packages/flutterwindcss/`:

- `lib/src/style/fw_layer.dart` — `FwCondition` (sealed: state/viewport/container) + `FwLayer` record alias.
- `lib/src/style/fw_style.dart` — `FwStyle` immutable data model (all base fields + `layers`), `copyWith`, `==`/`hashCode`. Mixes in `FwStyleOps<FwStyle>`.
- `lib/src/style/fw_style_ops.dart` — `FwStyleOps<T>` mixin: every base setter (M3 slice: padding + bg) + every variant method (state/viewport/container). One definition, two hosts.
- `lib/src/style/resolved_style.dart` — `ResolvedStyle` (flattened non-nullable value set) + `build(child)` render chain + private `_ShadowBox`/`_Surface`.
- `lib/src/style/resolve.dart` — `FwStyle.resolve` extension: disabled suppression, layer walk, nested recursion, last-wins merge into `ResolvedStyle`.
- `lib/src/style/fw_styled.dart` — `FwStyled` StatelessWidget + `.tw` extension. Conditional ancestor insertion; mixes in `FwStyleOps<FwStyled>`.
- Tests mirror under `test/style/` and `test/golden/`.
- `lib/flutterwindcss.dart` — barrel: export the new public surface.

**Ownership note (from module design §1):** M3 ships base setters for **padding + bg only** (the engine's test vehicle) and the **complete** variant/responsive/container surface. All other base *fields* exist in `FwStyle` but their setters land in modules 4–9.

---

## Task 1: `FwCondition` + `FwLayer` nesting primitives

**Files:**
- Create: `packages/flutterwindcss/lib/src/style/fw_layer.dart`
- Test: `packages/flutterwindcss/test/style/fw_layer_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/widgets.dart' show WidgetState;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/fw_layer.dart';
import 'package:flutterwindcss/flutterwindcss.dart' show FwBreakpoint;

void main() {
  test('state condition matches when its WidgetState is active', () {
    const c = FwStateCondition(WidgetState.hovered);
    expect(c.matches(<WidgetState>{WidgetState.hovered}, null), isTrue);
    expect(c.matches(<WidgetState>{WidgetState.focused}, null), isFalse);
  });

  test('viewport/container condition matches when width >= breakpoint min', () {
    const c = FwViewportCondition(FwBreakpoint.md); // 768
    expect(c.matches(const <WidgetState>{}, 800), isTrue);
    expect(c.matches(const <WidgetState>{}, 768), isTrue);
    expect(c.matches(const <WidgetState>{}, 700), isFalse);
    expect(c.matches(const <WidgetState>{}, null), isFalse); // no width => no match
  });

  test('conditions report their kind for the flattened-set scan', () {
    expect(const FwStateCondition(WidgetState.pressed).isState, isTrue);
    expect(const FwViewportCondition(FwBreakpoint.sm).isContainer, isFalse);
    expect(const FwContainerCondition(FwBreakpoint.sm).isContainer, isTrue);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd packages/flutterwindcss && flutter test test/style/fw_layer_test.dart`
Expected: FAIL — `fw_layer.dart` / symbols undefined.

- [ ] **Step 3: Implement `fw_layer.dart`**

```dart
import 'package:flutter/widgets.dart' show WidgetState, immutable;

import '../tokens/scales.dart';

/// A nesting condition under which a layer's [FwStyle] applies (spec §6.1).
/// Sealed so the resolver can `switch` exhaustively without a `default:`.
@immutable
sealed class FwCondition {
  /// Const base.
  const FwCondition();

  /// Whether this condition holds given the active interaction [states] and the
  /// available [width] (viewport size or container constraint), `null` if no
  /// width is known.
  bool matches(Set<WidgetState> states, double? width);

  /// True for a state condition (used to decide if a FocusableActionDetector
  /// is needed over the flattened layer set).
  bool get isState => this is FwStateCondition;

  /// True for a container condition (used to decide if a LayoutBuilder is
  /// needed over the flattened layer set).
  bool get isContainer => this is FwContainerCondition;
}

/// Matches when [state] is in the active interaction set.
@immutable
final class FwStateCondition extends FwCondition {
  /// Creates a state condition for [state].
  const FwStateCondition(this.state);

  /// The interaction state to match.
  final WidgetState state;

  @override
  bool matches(Set<WidgetState> states, double? width) => states.contains(state);
}

/// Matches when the **viewport** width is at least [breakpoint]'s min-width.
@immutable
final class FwViewportCondition extends FwCondition {
  /// Creates a viewport condition for [breakpoint].
  const FwViewportCondition(this.breakpoint);

  /// The breakpoint whose min-width gates this layer.
  final FwBreakpoint breakpoint;

  @override
  bool matches(Set<WidgetState> states, double? width) =>
      width != null && width >= breakpoint.minWidth;
}

/// Matches when the **container** constraint width is at least [breakpoint]'s
/// min-width (keyed off the FwStyled LayoutBuilder, spec §6.2).
@immutable
final class FwContainerCondition extends FwCondition {
  /// Creates a container condition for [breakpoint].
  const FwContainerCondition(this.breakpoint);

  /// The breakpoint whose min-width gates this layer.
  final FwBreakpoint breakpoint;

  @override
  bool matches(Set<WidgetState> states, double? width) =>
      width != null && width >= breakpoint.minWidth;
}
```

> `FwLayer` is intentionally not a separate type yet — a layer is the pair `(FwCondition, FwStyle)`. To avoid a circular import (`FwStyle` will reference layers), the pair is stored directly on `FwStyle` as two parallel concerns via a small record; see Task 2. We keep conditions in their own file so `FwStyle` and `resolve` both import them.

- [ ] **Step 4: Run to verify it passes**

Run: `cd packages/flutterwindcss && flutter test test/style/fw_layer_test.dart`
Expected: PASS.

- [ ] **Step 5: Analyze**

Run: `cd packages/flutterwindcss && flutter analyze --fatal-infos --fatal-warnings lib/src/style/fw_layer.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add packages/flutterwindcss/lib/src/style/fw_layer.dart \
        packages/flutterwindcss/test/style/fw_layer_test.dart
git commit -m "feat(style): FwCondition sealed hierarchy for nested layers"
```

---

## Task 2: `FwStyle` data model + `copyWith` + equality

This task defines the full §6.1 field set, the layer list (`(FwCondition, FwStyle)` pairs), `copyWith`, and value equality. Builder methods come in Task 3 (mixin). The padding field uses an `EdgeInsetsDirectional?` so per-edge last-wins works.

**Files:**
- Create: `packages/flutterwindcss/lib/src/style/fw_style.dart`
- Test: `packages/flutterwindcss/test/style/fw_style_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/fw_layer.dart';
import 'package:flutterwindcss/src/style/fw_style.dart';

void main() {
  test('const empty style has all-null fields and no layers', () {
    const s = FwStyle();
    expect(s.padding, isNull);
    expect(s.background, isNull);
    expect(s.layers, isEmpty);
  });

  test('copyWith replaces only the named field (last-wins primitive)', () {
    const s = FwStyle();
    final s2 = s.copyWith(background: const Color(0xFF112233));
    expect(s2.background, const Color(0xFF112233));
    expect(s2.padding, isNull);
    final s3 = s2.copyWith(background: const Color(0xFF445566));
    expect(s3.background, const Color(0xFF445566)); // overwrite, not merge
  });

  test('addLayer appends, preserving declaration order', () {
    const inner = FwStyle(background: Color(0xFF000000));
    const s = FwStyle();
    final s2 = s.addLayer(const FwStateCondition(WidgetState.hovered), inner);
    expect(s2.layers, hasLength(1));
    expect(s2.layers.first.$1, isA<FwStateCondition>());
    expect(s2.layers.first.$2, same(inner));
  });

  test('equality is value-based over fields and layers', () {
    const a = FwStyle(background: Color(0xFF111111));
    const b = FwStyle(background: Color(0xFF111111));
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(const FwStyle(background: Color(0xFF222222))));
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd packages/flutterwindcss && flutter test test/style/fw_style_test.dart`
Expected: FAIL — `FwStyle` undefined.

- [ ] **Step 3: Implement `fw_style.dart`**

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'fw_layer.dart';

/// One nested style layer: the condition under which it applies and the style
/// to merge when it does. The style may itself contain layers (joint `md:hover:`).
typedef FwLayer = (FwCondition condition, FwStyle style);

/// The immutable, lazily-resolved single-box style accumulator (spec §6.1).
///
/// All base fields are nullable (null = unset). Builder methods (the `.tw`
/// utilities) live in `FwStyleOps` and produce new `FwStyle`s via [copyWith]
/// (base, replacement = last-wins) or [addLayer] (variants, append). Resolution
/// against interaction states + width happens in `resolve.dart`.
@immutable
class FwStyle with FwStyleOps<FwStyle> {
  /// Creates a style. Prefer `const FwStyle()` then chained utilities.
  const FwStyle({
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.minWidth,
    this.minHeight,
    this.maxWidth,
    this.maxHeight,
    this.widthFactor,
    this.heightFactor,
    this.factorAlignment,
    this.aspectRatio,
    this.background,
    this.gradient,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.foreground,
    this.fontSize,
    this.fontWeight,
    this.letterSpacing,
    this.lineHeight,
    this.textAlign,
    this.textDecoration,
    this.opacity,
    this.blur,
    this.backdropBlur,
    this.scale,
    this.rotation,
    this.translate,
    this.clipBehavior,
    this.layers = const <FwLayer>[],
  });

  // Spacing.
  /// Inner padding.
  final EdgeInsetsDirectional? padding;
  /// Outer margin.
  final EdgeInsetsDirectional? margin;

  // Sizing.
  /// Fixed width (tight constraint, wins its axis).
  final double? width;
  /// Fixed height (tight constraint, wins its axis).
  final double? height;
  /// Minimum width (ignored on an axis with a fixed [width]).
  final double? minWidth;
  /// Minimum height.
  final double? minHeight;
  /// Maximum width.
  final double? maxWidth;
  /// Maximum height.
  final double? maxHeight;
  /// Fractional width (`FractionallySizedBox.widthFactor`).
  final double? widthFactor;
  /// Fractional height.
  final double? heightFactor;
  /// Alignment for fractional sizing (default centerStart at resolve time).
  final AlignmentDirectional? factorAlignment;
  /// Aspect ratio (width / height).
  final double? aspectRatio;

  // Color / decoration.
  /// Solid background fill.
  final Color? background;
  /// Gradient fill (composited over [background] if both set).
  final Gradient? gradient;
  /// Border spec (uniform or per-side), resolved in the chain.
  final BoxBorder? border;
  /// Corner radii (directional).
  final BorderRadiusDirectional? borderRadius;
  /// Drop shadows (token scale).
  final List<BoxShadow>? boxShadow;

  // Foreground / text.
  /// Default text/icon color for descendants.
  final Color? foreground;
  /// Default font size.
  final double? fontSize;
  /// Default font weight.
  final FontWeight? fontWeight;
  /// Default letter spacing (tracking).
  final double? letterSpacing;
  /// Default line height (leading), as a multiple of font size.
  final double? lineHeight;
  /// Default text alignment.
  final TextAlign? textAlign;
  /// Default text decoration.
  final TextDecoration? textDecoration;

  // Effects.
  /// Group opacity (0..1).
  final double? opacity;
  /// Content blur sigma (logical px).
  final double? blur;
  /// Backdrop blur sigma (logical px).
  final double? backdropBlur;

  // Transform (paint-only).
  /// Uniform scale factor.
  final double? scale;
  /// Rotation in radians.
  final double? rotation;
  /// Translation offset.
  final Offset? translate;

  // Overflow.
  /// Content clip behavior.
  final Clip? clipBehavior;

  /// Nested variant layers, in declaration order.
  final List<FwLayer> layers;

  @override
  FwStyle get fwStyle => this;

  @override
  FwStyle fwRebuild(FwStyle style) => style;

  /// Returns a copy with the given fields replaced (unset args keep the current
  /// value). This is the **replacement** primitive that makes base utilities
  /// last-wins. Pass [layers] only from `addLayer`.
  FwStyle copyWith({
    EdgeInsetsDirectional? padding,
    EdgeInsetsDirectional? margin,
    double? width,
    double? height,
    double? minWidth,
    double? minHeight,
    double? maxWidth,
    double? maxHeight,
    double? widthFactor,
    double? heightFactor,
    AlignmentDirectional? factorAlignment,
    double? aspectRatio,
    Color? background,
    Gradient? gradient,
    BoxBorder? border,
    BorderRadiusDirectional? borderRadius,
    List<BoxShadow>? boxShadow,
    Color? foreground,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? lineHeight,
    TextAlign? textAlign,
    TextDecoration? textDecoration,
    double? opacity,
    double? blur,
    double? backdropBlur,
    double? scale,
    double? rotation,
    Offset? translate,
    Clip? clipBehavior,
    List<FwLayer>? layers,
  }) {
    return FwStyle(
      padding: padding ?? this.padding,
      margin: margin ?? this.margin,
      width: width ?? this.width,
      height: height ?? this.height,
      minWidth: minWidth ?? this.minWidth,
      minHeight: minHeight ?? this.minHeight,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      widthFactor: widthFactor ?? this.widthFactor,
      heightFactor: heightFactor ?? this.heightFactor,
      factorAlignment: factorAlignment ?? this.factorAlignment,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      background: background ?? this.background,
      gradient: gradient ?? this.gradient,
      border: border ?? this.border,
      borderRadius: borderRadius ?? this.borderRadius,
      boxShadow: boxShadow ?? this.boxShadow,
      foreground: foreground ?? this.foreground,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      textAlign: textAlign ?? this.textAlign,
      textDecoration: textDecoration ?? this.textDecoration,
      opacity: opacity ?? this.opacity,
      blur: blur ?? this.blur,
      backdropBlur: backdropBlur ?? this.backdropBlur,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      translate: translate ?? this.translate,
      clipBehavior: clipBehavior ?? this.clipBehavior,
      layers: layers ?? this.layers,
    );
  }

  /// Appends a nested [style] guarded by [condition]. Variant methods use this.
  FwStyle addLayer(FwCondition condition, FwStyle style) =>
      copyWith(layers: <FwLayer>[...layers, (condition, style)]);

  @override
  bool operator ==(Object other) =>
      other is FwStyle &&
      padding == other.padding &&
      margin == other.margin &&
      width == other.width &&
      height == other.height &&
      minWidth == other.minWidth &&
      minHeight == other.minHeight &&
      maxWidth == other.maxWidth &&
      maxHeight == other.maxHeight &&
      widthFactor == other.widthFactor &&
      heightFactor == other.heightFactor &&
      factorAlignment == other.factorAlignment &&
      aspectRatio == other.aspectRatio &&
      background == other.background &&
      gradient == other.gradient &&
      border == other.border &&
      borderRadius == other.borderRadius &&
      listEquals(boxShadow, other.boxShadow) &&
      foreground == other.foreground &&
      fontSize == other.fontSize &&
      fontWeight == other.fontWeight &&
      letterSpacing == other.letterSpacing &&
      lineHeight == other.lineHeight &&
      textAlign == other.textAlign &&
      textDecoration == other.textDecoration &&
      opacity == other.opacity &&
      blur == other.blur &&
      backdropBlur == other.backdropBlur &&
      scale == other.scale &&
      rotation == other.rotation &&
      translate == other.translate &&
      clipBehavior == other.clipBehavior &&
      listEquals(layers, other.layers);

  @override
  int get hashCode => Object.hashAll(<Object?>[
        padding, margin, width, height, minWidth, minHeight, maxWidth,
        maxHeight, widthFactor, heightFactor, factorAlignment, aspectRatio,
        background, gradient, border, borderRadius,
        boxShadow == null ? null : Object.hashAll(boxShadow!),
        foreground, fontSize, fontWeight, letterSpacing, lineHeight, textAlign,
        textDecoration, opacity, blur, backdropBlur, scale, rotation, translate,
        clipBehavior, Object.hashAll(layers),
      ]);
}
```

> This file references `FwStyleOps`, `fwStyle`, and `fwRebuild` (Task 3) — it will not analyze until Task 3 lands the mixin. That is expected; the two files are a unit. Run analyze at the end of Task 3, not here.

- [ ] **Step 4: Add the mixin (Task 3) before running** — proceed to Task 3, then return here.

- [ ] **Step 5: Run to verify it passes** (after Task 3)

Run: `cd packages/flutterwindcss && flutter test test/style/fw_style_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit** (combined with Task 3)

---

## Task 3: `FwStyleOps<T>` mixin — base slice + full variant surface

The DRY builder layer. Defined once; `FwStyle` returns `FwStyle`, `FwStyled` returns `FwStyled`. Padding setters **merge per-edge** (so `.px` then `.py` keeps both, `.px` then `.px` overwrites horizontal). `bg` is a plain replace. Variant methods build a nested `FwStyle` from `const FwStyle()` via the supplied callback and append a layer.

**Files:**
- Create: `packages/flutterwindcss/lib/src/style/fw_style_ops.dart`
- Test: `packages/flutterwindcss/test/style/fw_style_ops_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/fw_layer.dart';
import 'package:flutterwindcss/src/style/fw_style.dart';
import 'package:flutterwindcss/flutterwindcss.dart' show FwBreakpoint, fwSpace;

void main() {
  test('px sets horizontal padding in logical px; last-wins on repeat', () {
    final s = const FwStyle().px(4).px(2);
    expect(s.padding!.start, fwSpace(2));
    expect(s.padding!.end, fwSpace(2));
    expect(s.padding!.top, 0);
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

  test('md/container append viewport/container layers; nest jointly', () {
    final s = const FwStyle().md((m) => m.hover((h) => h.bg(const Color(0xFF010101))));
    final (cond, nested) = s.layers.first;
    expect(cond, const FwViewportCondition(FwBreakpoint.md));
    expect(nested.layers.first.$1, const FwStateCondition(WidgetState.hovered));
  });

  test('whenState accepts arbitrary WidgetState', () {
    final s = const FwStyle().whenState(
      WidgetState.selected,
      (x) => x.bg(const Color(0xFF030303)),
    );
    expect(s.layers.first.$1, const FwStateCondition(WidgetState.selected));
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd packages/flutterwindcss && flutter test test/style/fw_style_ops_test.dart`
Expected: FAIL — `FwStyleOps`/`px`/`hover` undefined.

- [ ] **Step 3: Implement `fw_style_ops.dart`**

```dart
import 'package:flutter/widgets.dart';

import '../tokens/scales.dart';
import 'fw_layer.dart';
import 'fw_style.dart';

/// The chainable builder utilities, defined once and shared by both `FwStyle`
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

  EdgeInsetsDirectional _mergePad({
    double? start,
    double? end,
    double? top,
    double? bottom,
  }) {
    final p = fwStyle.padding ?? EdgeInsetsDirectional.zero;
    return EdgeInsetsDirectional.only(
      start: start ?? p.start,
      end: end ?? p.end,
      top: top ?? p.top,
      bottom: bottom ?? p.bottom,
    );
  }

  /// Padding on all sides, [units] × 4 logical px.
  T p(double units) => fwRebuild(
        fwStyle.copyWith(padding: EdgeInsetsDirectional.all(fwSpace(units))),
      );

  /// Horizontal padding (start + end).
  T px(double units) => fwRebuild(
        fwStyle.copyWith(
          padding: _mergePad(start: fwSpace(units), end: fwSpace(units)),
        ),
      );

  /// Vertical padding (top + bottom).
  T py(double units) => fwRebuild(
        fwStyle.copyWith(
          padding: _mergePad(top: fwSpace(units), bottom: fwSpace(units)),
        ),
      );

  /// Padding at the start edge (RTL-aware).
  T ps(double units) =>
      fwRebuild(fwStyle.copyWith(padding: _mergePad(start: fwSpace(units))));

  /// Padding at the end edge (RTL-aware).
  T pe(double units) =>
      fwRebuild(fwStyle.copyWith(padding: _mergePad(end: fwSpace(units))));

  /// Padding at the top edge.
  T pt(double units) =>
      fwRebuild(fwStyle.copyWith(padding: _mergePad(top: fwSpace(units))));

  /// Padding at the bottom edge.
  T pb(double units) =>
      fwRebuild(fwStyle.copyWith(padding: _mergePad(bottom: fwSpace(units))));

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

  /// Applies the built style at container width ≥ `sm` (640). See R6 caveat.
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
```

- [ ] **Step 4: Run both data-model + ops tests to verify they pass**

Run: `cd packages/flutterwindcss && flutter test test/style/fw_style_test.dart test/style/fw_style_ops_test.dart`
Expected: PASS (Task 2 + Task 3 together).

- [ ] **Step 5: Analyze**

Run: `cd packages/flutterwindcss && flutter analyze --fatal-infos --fatal-warnings lib/src/style/fw_style.dart lib/src/style/fw_style_ops.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add packages/flutterwindcss/lib/src/style/fw_style.dart \
        packages/flutterwindcss/lib/src/style/fw_style_ops.dart \
        packages/flutterwindcss/test/style/fw_style_test.dart \
        packages/flutterwindcss/test/style/fw_style_ops_test.dart
git commit -m "feat(style): FwStyle data model + FwStyleOps builder mixin (padding+bg slice, full variants)"
```

---

## Task 4: `ResolvedStyle` value set + non-nullable defaults

The flattened result of resolution. Holds concrete values the render chain reads. Defaults applied so the chain never branches on null beyond "emit-iff-set" (which it tracks via nullable fields kept here for the optional wrappers).

**Files:**
- Create: `packages/flutterwindcss/lib/src/style/resolved_style.dart` (struct only this task; `build` in Task 6)
- Test: `packages/flutterwindcss/test/style/resolved_style_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/resolved_style.dart';

void main() {
  test('ResolvedStyle holds the optional fields it is given', () {
    const r = ResolvedStyle(
      padding: EdgeInsetsDirectional.all(8),
      background: Color(0xFF123456),
    );
    expect(r.padding, const EdgeInsetsDirectional.all(8));
    expect(r.background, const Color(0xFF123456));
    expect(r.margin, isNull);
    expect(r.boxShadow, isNull);
  });

  test('factorAlignment defaults to centerStart when not provided', () {
    const r = ResolvedStyle();
    expect(r.factorAlignment, AlignmentDirectional.centerStart);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd packages/flutterwindcss && flutter test test/style/resolved_style_test.dart`
Expected: FAIL — `ResolvedStyle` undefined.

- [ ] **Step 3: Implement the `ResolvedStyle` struct** (render `build` added in Task 6)

```dart
import 'package:flutter/widgets.dart';

/// The flattened, concrete style the render chain consumes (spec §6.3/§6.4).
/// Optional wrappers read nullable fields ("emit iff set"); [factorAlignment]
/// carries its non-null default since `FractionallySizedBox` needs one.
@immutable
class ResolvedStyle {
  /// Creates a resolved style. All fields optional; null = wrapper omitted.
  const ResolvedStyle({
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.minWidth,
    this.minHeight,
    this.maxWidth,
    this.maxHeight,
    this.widthFactor,
    this.heightFactor,
    this.factorAlignment = AlignmentDirectional.centerStart,
    this.aspectRatio,
    this.background,
    this.gradient,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.foreground,
    this.fontSize,
    this.fontWeight,
    this.letterSpacing,
    this.lineHeight,
    this.textAlign,
    this.textDecoration,
    this.opacity,
    this.blur,
    this.backdropBlur,
    this.scale,
    this.rotation,
    this.translate,
    this.clipBehavior,
  });

  /// Inner padding.
  final EdgeInsetsDirectional? padding;
  /// Outer margin.
  final EdgeInsetsDirectional? margin;
  /// Fixed width.
  final double? width;
  /// Fixed height.
  final double? height;
  /// Min width.
  final double? minWidth;
  /// Min height.
  final double? minHeight;
  /// Max width.
  final double? maxWidth;
  /// Max height.
  final double? maxHeight;
  /// Fractional width factor.
  final double? widthFactor;
  /// Fractional height factor.
  final double? heightFactor;
  /// Fractional alignment (defaults to centerStart).
  final AlignmentDirectional factorAlignment;
  /// Aspect ratio.
  final double? aspectRatio;
  /// Solid background.
  final Color? background;
  /// Gradient fill.
  final Gradient? gradient;
  /// Border.
  final BoxBorder? border;
  /// Corner radii (directional).
  final BorderRadiusDirectional? borderRadius;
  /// Drop shadows.
  final List<BoxShadow>? boxShadow;
  /// Default text/icon color.
  final Color? foreground;
  /// Default font size.
  final double? fontSize;
  /// Default font weight.
  final FontWeight? fontWeight;
  /// Default letter spacing.
  final double? letterSpacing;
  /// Default line height multiple.
  final double? lineHeight;
  /// Default text align.
  final TextAlign? textAlign;
  /// Default text decoration.
  final TextDecoration? textDecoration;
  /// Group opacity.
  final double? opacity;
  /// Content blur sigma.
  final double? blur;
  /// Backdrop blur sigma.
  final double? backdropBlur;
  /// Scale factor.
  final double? scale;
  /// Rotation radians.
  final double? rotation;
  /// Translate offset.
  final Offset? translate;
  /// Clip behavior.
  final Clip? clipBehavior;
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cd packages/flutterwindcss && flutter test test/style/resolved_style_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/flutterwindcss/lib/src/style/resolved_style.dart \
        packages/flutterwindcss/test/style/resolved_style_test.dart
git commit -m "feat(style): ResolvedStyle flattened value set"
```

---

## Task 5: `FwStyle.resolve` — suppression, layer walk, nested recursion, last-wins

The heart of the engine. Implemented as an extension on `FwStyle` in `resolve.dart`.

**Files:**
- Create: `packages/flutterwindcss/lib/src/style/resolve.dart`
- Test: `packages/flutterwindcss/test/style/resolve_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/fw_style.dart';
import 'package:flutterwindcss/src/style/resolve.dart';

const _a = Color(0xFFAAAAAA);
const _b = Color(0xFFBBBBBB);
const _c = Color(0xFFCCCCCC);

void main() {
  test('base fields pass through when no layers match', () {
    final r = const FwStyle().bg(_a).resolve(const <WidgetState>{}, null);
    expect(r.background, _a);
  });

  test('a matching state layer overrides the base (last-wins)', () {
    final style = const FwStyle().bg(_a).hover((h) => h.bg(_b));
    expect(style.resolve(const <WidgetState>{}, null).background, _a);
    expect(
      style.resolve(<WidgetState>{WidgetState.hovered}, null).background,
      _b,
    );
  });

  test('later matching layer wins among equals', () {
    final style =
        const FwStyle().hover((h) => h.bg(_a)).hover((h) => h.bg(_b));
    expect(
      style.resolve(<WidgetState>{WidgetState.hovered}, null).background,
      _b,
    );
  });

  test('disabled suppresses hover/focus/pressed regardless of order', () {
    final style = const FwStyle()
        .bg(_a)
        .disabled((d) => d.bg(_c))
        .hover((h) => h.bg(_b));
    final r = style.resolve(
      <WidgetState>{WidgetState.disabled, WidgetState.hovered},
      null,
    );
    expect(r.background, _c); // hover dropped; disabled applied
  });

  test('viewport layer matches only at/above its breakpoint width', () {
    final style = const FwStyle().bg(_a).md((m) => m.bg(_b));
    expect(style.resolve(const <WidgetState>{}, 700).background, _a);
    expect(style.resolve(const <WidgetState>{}, 768).background, _b);
  });

  test('nested md:hover resolves jointly', () {
    final style =
        const FwStyle().bg(_a).md((m) => m.hover((h) => h.bg(_b)));
    // md but not hover -> base
    expect(style.resolve(const <WidgetState>{}, 800).background, _a);
    // md and hover -> _b
    expect(
      style.resolve(<WidgetState>{WidgetState.hovered}, 800).background,
      _b,
    );
    // hover but not md -> base
    expect(
      style.resolve(<WidgetState>{WidgetState.hovered}, 500).background,
      _a,
    );
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd packages/flutterwindcss && flutter test test/style/resolve_test.dart`
Expected: FAIL — `resolve` undefined.

- [ ] **Step 3: Implement `resolve.dart`**

```dart
import 'package:flutter/widgets.dart';

import 'fw_style.dart';
import 'resolved_style.dart';

/// Resolution: flatten base + matching nested layers into a [ResolvedStyle].
extension FwStyleResolve on FwStyle {
  /// Resolves this style against the active interaction [states] and the
  /// available [width] (viewport size or container constraint). See spec §6.3.
  ResolvedStyle resolve(Set<WidgetState> states, double? width) {
    // 1. Disabled suppression first (Finding #7): disabled removes the other
    //    three from the working set before any matching, so it always wins.
    final Set<WidgetState> working;
    if (states.contains(WidgetState.disabled)) {
      working = <WidgetState>{
        for (final s in states)
          if (s != WidgetState.hovered &&
              s != WidgetState.focused &&
              s != WidgetState.pressed)
            s,
      };
    } else {
      working = states;
    }

    // 2. Accumulate base + matching layers (recursively) via last-wins copyWith.
    final merged = _flatten(this, working, width);

    // 3. Project the flattened FwStyle onto a ResolvedStyle (defaults applied).
    return ResolvedStyle(
      padding: merged.padding,
      margin: merged.margin,
      width: merged.width,
      height: merged.height,
      minWidth: merged.minWidth,
      minHeight: merged.minHeight,
      maxWidth: merged.maxWidth,
      maxHeight: merged.maxHeight,
      widthFactor: merged.widthFactor,
      heightFactor: merged.heightFactor,
      factorAlignment:
          merged.factorAlignment ?? AlignmentDirectional.centerStart,
      aspectRatio: merged.aspectRatio,
      background: merged.background,
      gradient: merged.gradient,
      border: merged.border,
      borderRadius: merged.borderRadius,
      boxShadow: merged.boxShadow,
      foreground: merged.foreground,
      fontSize: merged.fontSize,
      fontWeight: merged.fontWeight,
      letterSpacing: merged.letterSpacing,
      lineHeight: merged.lineHeight,
      textAlign: merged.textAlign,
      textDecoration: merged.textDecoration,
      opacity: merged.opacity,
      blur: merged.blur,
      backdropBlur: merged.backdropBlur,
      scale: merged.scale,
      rotation: merged.rotation,
      translate: merged.translate,
      clipBehavior: merged.clipBehavior,
    );
  }
}

/// Returns a single FwStyle with [style]'s base fields overlaid, in declaration
/// order, by every matching layer (recursing into nested layers first so a
/// nested style's own layers are applied before merging up — joint `md:hover:`).
FwStyle _flatten(FwStyle style, Set<WidgetState> states, double? width) {
  var acc = style.copyWith(layers: const []); // base fields, drop layer list
  for (final (condition, nested) in style.layers) {
    if (condition.matches(states, width)) {
      final resolvedNested = _flatten(nested, states, width);
      acc = _overlay(acc, resolvedNested);
    }
  }
  return acc;
}

/// Field-by-field last-wins overlay: every non-null field of [top] replaces the
/// corresponding field of [base].
FwStyle _overlay(FwStyle base, FwStyle top) => base.copyWith(
      padding: top.padding,
      margin: top.margin,
      width: top.width,
      height: top.height,
      minWidth: top.minWidth,
      minHeight: top.minHeight,
      maxWidth: top.maxWidth,
      maxHeight: top.maxHeight,
      widthFactor: top.widthFactor,
      heightFactor: top.heightFactor,
      factorAlignment: top.factorAlignment,
      aspectRatio: top.aspectRatio,
      background: top.background,
      gradient: top.gradient,
      border: top.border,
      borderRadius: top.borderRadius,
      boxShadow: top.boxShadow,
      foreground: top.foreground,
      fontSize: top.fontSize,
      fontWeight: top.fontWeight,
      letterSpacing: top.letterSpacing,
      lineHeight: top.lineHeight,
      textAlign: top.textAlign,
      textDecoration: top.textDecoration,
      opacity: top.opacity,
      blur: top.blur,
      backdropBlur: top.backdropBlur,
      scale: top.scale,
      rotation: top.rotation,
      translate: top.translate,
      clipBehavior: top.clipBehavior,
    );
```

> Note: `copyWith` treats null args as "keep", so `_overlay` only replaces fields the top layer actually set — exactly the last-wins merge. Base padding merges are already baked into each field by the ops mixin, so overlay at the field granularity is correct.

- [ ] **Step 4: Run to verify it passes**

Run: `cd packages/flutterwindcss && flutter test test/style/resolve_test.dart`
Expected: PASS.

- [ ] **Step 5: Analyze**

Run: `cd packages/flutterwindcss && flutter analyze --fatal-infos --fatal-warnings lib/src/style/resolve.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add packages/flutterwindcss/lib/src/style/resolve.dart \
        packages/flutterwindcss/test/style/resolve_test.dart
git commit -m "feat(style): FwStyle.resolve — disabled-suppress, nested last-wins layering"
```

---

## Task 6: `ResolvedStyle.build` — the §6.4 render chain

Add the `build(child)` method (and private `_ShadowBox`/`_Surface`) to `resolved_style.dart`. Each wrapper is emitted only when its field is set. Tests assert **presence-iff-set** and **relative order** (not exact element counts — see module design §5 brittleness note).

**Files:**
- Modify: `packages/flutterwindcss/lib/src/style/resolved_style.dart`
- Test: `packages/flutterwindcss/test/style/render_chain_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/resolved_style.dart';

Future<void> _pump(WidgetTester t, ResolvedStyle r) => t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: r.build(const SizedBox(key: Key('child'))),
      ),
    );

void main() {
  testWidgets('static empty style renders the child with no extra wrappers',
      (t) async {
    await _pump(t, const ResolvedStyle());
    expect(find.byKey(const Key('child')), findsOneWidget);
    expect(find.byType(Opacity), findsNothing);
    expect(find.byType(DecoratedBox), findsNothing);
  });

  testWidgets('padding wrapper present iff padding set', (t) async {
    await _pump(t, const ResolvedStyle());
    expect(find.byType(Padding), findsNothing);
    await _pump(t, const ResolvedStyle(padding: EdgeInsetsDirectional.all(8)));
    expect(find.byType(Padding), findsWidgets);
  });

  testWidgets('background emits a DecoratedBox; shadow emits an outer box',
      (t) async {
    await _pump(t, const ResolvedStyle(background: Color(0xFF112233)));
    expect(find.byType(DecoratedBox), findsOneWidget);
  });

  testWidgets('margin is outermost, child innermost (relative order)',
      (t) async {
    await _pump(
      t,
      const ResolvedStyle(
        margin: EdgeInsetsDirectional.all(4),
        padding: EdgeInsetsDirectional.all(8),
        background: Color(0xFF112233),
      ),
    );
    // The margin Padding must be an ancestor of the DecoratedBox.
    final marginPadding = find.byType(Padding).first;
    expect(
      find.descendant(of: marginPadding, matching: find.byType(DecoratedBox)),
      findsOneWidget,
    );
  });

  testWidgets('opacity wrapper present iff opacity set', (t) async {
    await _pump(t, const ResolvedStyle(opacity: 0.5, background: Color(0xFF111111)));
    expect(find.byType(Opacity), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd packages/flutterwindcss && flutter test test/style/render_chain_test.dart`
Expected: FAIL — `build` not defined on `ResolvedStyle`.

- [ ] **Step 3: Implement `build` + helpers in `resolved_style.dart`**

Add these imports at the top of the file:

```dart
import 'dart:ui' as ui show ImageFilter;
```

Add inside the `ResolvedStyle` class (after the fields):

```dart
  /// Builds the fixed outer→inner primitive chain (spec §6.4). Each wrapper is
  /// emitted only when its input is set, so a static empty style returns [child]
  /// unwrapped. Order is asserted by tests because later modules depend on it.
  Widget build(Widget child) {
    Widget current = child;

    // Inner: default text/icon styling for descendants.
    if (foreground != null ||
        fontSize != null ||
        fontWeight != null ||
        letterSpacing != null ||
        lineHeight != null ||
        textAlign != null ||
        textDecoration != null) {
      current = DefaultTextStyle.merge(
        style: TextStyle(
          color: foreground,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          height: lineHeight,
          decoration: textDecoration,
        ),
        textAlign: textAlign,
        child: IconTheme.merge(
          data: IconThemeData(color: foreground, size: fontSize),
          child: current,
        ),
      );
    }

    // Inner padding.
    if (padding != null) {
      current = Padding(padding: padding!, child: current);
    }

    // Content clip, inset by border width, if clipping requested.
    if (clipBehavior != null && clipBehavior != Clip.none && borderRadius != null) {
      current = ClipRRect(
        clipBehavior: clipBehavior!,
        borderRadius: borderRadius!.resolve(TextDirection.ltr),
        child: current,
      );
    }

    // Surface: optional backdrop blur clipped to the box, then the decoration.
    final hasDecoration = background != null || gradient != null || border != null;
    if (backdropBlur != null) {
      current = ClipRRect(
        borderRadius: (borderRadius ?? BorderRadiusDirectional.zero)
            .resolve(TextDirection.ltr),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: backdropBlur!, sigmaY: backdropBlur!),
          child: hasDecoration ? _decorate(current) : current,
        ),
      );
    } else if (hasDecoration) {
      current = _decorate(current);
    }

    // Unclipped shadow layer (outside any clip so backdrop-blur can't eat it).
    if (boxShadow != null && boxShadow!.isNotEmpty) {
      current = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: boxShadow,
        ),
        child: current,
      );
    }

    // Group opacity (folded into bg alpha only for the trivial empty-box case;
    // a true Opacity layer whenever a child/gradient/shadow is present).
    if (opacity != null) {
      current = Opacity(opacity: opacity!, child: current);
    }

    // Content blur (filters the whole element, incl. bg+border).
    if (blur != null) {
      current = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blur!, sigmaY: blur!),
        child: current,
      );
    }

    // Transform (paint-only; transforms the rendered result incl. shadow).
    if (scale != null || rotation != null || translate != null) {
      var m = Matrix4.identity();
      if (translate != null) m.translate(translate!.dx, translate!.dy);
      if (rotation != null) m.rotateZ(rotation!);
      if (scale != null) m.scale(scale!, scale!);
      current = Transform(transform: m, alignment: Alignment.center, child: current);
    }

    // Fractional sizing.
    if (widthFactor != null || heightFactor != null) {
      current = FractionallySizedBox(
        widthFactor: widthFactor,
        heightFactor: heightFactor,
        alignment: factorAlignment,
        child: current,
      );
    }

    // Aspect ratio.
    if (aspectRatio != null) {
      current = AspectRatio(aspectRatio: aspectRatio!, child: current);
    }

    // Sizing reconciliation: fixed dim => tight constraint and wins its axis;
    // min/max apply only to axes without a fixed value (Finding #6).
    final hasConstraints = width != null ||
        height != null ||
        minWidth != null ||
        minHeight != null ||
        maxWidth != null ||
        maxHeight != null;
    if (hasConstraints) {
      assert(
        !(width != null && (minWidth != null || maxWidth != null)),
        'Set either a fixed width or min/max width, not both, on the same axis.',
      );
      assert(
        !(height != null && (minHeight != null || maxHeight != null)),
        'Set either a fixed height or min/max height, not both, on the same axis.',
      );
      current = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: width ?? minWidth ?? 0.0,
          maxWidth: width ?? maxWidth ?? double.infinity,
          minHeight: height ?? minHeight ?? 0.0,
          maxHeight: height ?? maxHeight ?? double.infinity,
        ),
        child: current,
      );
    }

    // Outermost: margin.
    if (margin != null) {
      current = Padding(padding: margin!, child: current);
    }

    return current;
  }

  Widget _decorate(Widget child) => DecoratedBox(
        decoration: BoxDecoration(
          color: gradient == null ? background : null,
          gradient: gradient,
          border: border,
          borderRadius: borderRadius,
        ),
        child: child,
      );
```

> This task uses Flutter's built-in `DecoratedBox`/`Opacity` directly rather than custom `_ShadowBox`/`_Surface` classes — the spec's named boxes are conceptual layer positions, and the unclipped-shadow / backdrop-clip split is achieved here by ordering the real primitives (shadow `DecoratedBox` outside the backdrop `ClipRRect`). The opacity-fold optimization (Finding #11) is deferred: emitting a real `Opacity` is always correct; folding is a perf optimization a later pass can add behind the same tests. Documented so it is not mistaken for missing.

- [ ] **Step 4: Run to verify it passes**

Run: `cd packages/flutterwindcss && flutter test test/style/render_chain_test.dart`
Expected: PASS.

- [ ] **Step 5: Analyze**

Run: `cd packages/flutterwindcss && flutter analyze --fatal-infos --fatal-warnings lib/src/style/resolved_style.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add packages/flutterwindcss/lib/src/style/resolved_style.dart \
        packages/flutterwindcss/test/style/render_chain_test.dart
git commit -m "feat(style): ResolvedStyle.build render chain (presence-iff-set, asserted order)"
```

---

## Task 7: `FwStyled` widget + `.tw` entry + conditional ancestor insertion

The widget the user places in the tree. Mixes `FwStyleOps<FwStyled>` (so `.tw.px(4).bg(c).hover(...)` chains), inserts `MediaQuery`/`LayoutBuilder`/`FocusableActionDetector` only when the flattened layer set needs them, stays semantics-transparent, and avoids spurious tab stops.

**Files:**
- Create: `packages/flutterwindcss/lib/src/style/fw_styled.dart`
- Test: `packages/flutterwindcss/test/style/fw_styled_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

void main() {
  testWidgets('.tw renders the child and applies static base styling', (t) async {
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: const SizedBox(key: Key('c')).tw.p(2).bg(const Color(0xFF112233)),
      ),
    );
    expect(find.byKey(const Key('c')), findsOneWidget);
    expect(find.byType(DecoratedBox), findsOneWidget);
  });

  testWidgets('static style inserts no FocusableActionDetector or LayoutBuilder',
      (t) async {
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: const SizedBox().tw.p(2),
      ),
    );
    expect(find.byType(FocusableActionDetector), findsNothing);
    expect(find.byType(LayoutBuilder), findsNothing);
  });

  testWidgets('a hover layer inserts a non-focusable detector (no tab stop)',
      (t) async {
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: const SizedBox()
            .tw
            .bg(const Color(0xFF111111))
            .hover((h) => h.bg(const Color(0xFF222222))),
      ),
    );
    final det = tester_detector(t);
    expect(det, isNotNull);
    expect(det!.descendantsAreFocusable, isTrue);
    expect(det.skipTraversal, isTrue);
  });

  testWidgets('a container layer inserts a LayoutBuilder', (t) async {
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: const SizedBox()
            .tw
            .bg(const Color(0xFF111111))
            .containerMd((m) => m.bg(const Color(0xFF222222))),
      ),
    );
    expect(find.byType(LayoutBuilder), findsOneWidget);
  });

  testWidgets('a Semantics(button) child survives the .tw chain', (t) async {
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(
          button: true,
          label: 'Go',
          child: const SizedBox(),
        ).tw.p(2).bg(const Color(0xFF111111)),
      ),
    );
    expect(find.bySemanticsLabel('Go'), findsOneWidget);
  });
}

FocusableActionDetector? tester_detector(WidgetTester t) {
  final found = t.widgetList<FocusableActionDetector>(
    find.byType(FocusableActionDetector),
  );
  return found.isEmpty ? null : found.first;
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd packages/flutterwindcss && flutter test test/style/fw_styled_test.dart`
Expected: FAIL — `.tw` / `FwStyled` undefined.

- [ ] **Step 3: Implement `fw_styled.dart`**

```dart
import 'package:flutter/widgets.dart';

import 'fw_style.dart';
import 'fw_style_ops.dart';
import 'resolve.dart';

/// Extension entry point: begin a style chain on any widget (spec §6.2).
extension TwExtension on Widget {
  /// Wraps this widget in an [FwStyled] so `.tw`-utilities can style the box.
  FwStyled get tw => FwStyled(child: this, style: const FwStyle());
}

/// The widget that applies an [FwStyle] to a single [child]. Exposes the builder
/// utilities via [FwStyleOps] (each returns a new `FwStyled` with the same child
/// and an updated style), and conditionally inserts the ancestors resolution
/// needs — never more than required (spec §6.2, R3/R5/R6).
class FwStyled extends StatelessWidget with FwStyleOps<FwStyled> {
  /// Creates a styled box. Use [Widget.tw] rather than calling this directly.
  const FwStyled({
    required this.child,
    required this.style,
    this.states,
    super.key,
  });

  /// The single child being styled.
  final Widget child;

  /// The accumulated style.
  final FwStyle style;

  /// Optional externally-injected interaction states (component-managed states
  /// such as `selected`; merged with detector-sourced states, §6.5).
  final Set<WidgetState>? states;

  @override
  FwStyle get fwStyle => style;

  @override
  FwStyled fwRebuild(FwStyle next) =>
      FwStyled(child: child, style: next, states: states, key: key);

  /// All conditions across the flattened (recursive) layer set.
  Iterable<bool Function()> get _ignored => const []; // placeholder for clarity

  bool get _hasStateLayer => _anyCondition((c) => c.isState);
  bool get _hasContainerLayer => _anyCondition((c) => c.isContainer);
  bool get _hasViewportLayer =>
      _anyCondition((c) => !c.isState && !c.isContainer);

  bool _anyCondition(bool Function(dynamic) test) {
    bool walk(FwStyle s) {
      for (final (cond, nested) in s.layers) {
        if (test(cond)) return true;
        if (walk(nested)) return true;
      }
      return false;
    }

    return walk(style);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasContainerLayer) {
      return LayoutBuilder(
        builder: (context, constraints) => _resolveAndBuild(
          context,
          containerWidth: constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : null,
        ),
      );
    }
    return _resolveAndBuild(context, containerWidth: null);
  }

  Widget _resolveAndBuild(BuildContext context, {required double? containerWidth}) {
    final viewportWidth =
        _hasViewportLayer ? MediaQuery.maybeOf(context)?.size.width : null;
    // Container conditions key off containerWidth; viewport off viewportWidth.
    // resolve() takes a single width, so we resolve in two not needed — instead
    // we pass the relevant width per condition kind by precomputing the set.
    final width = containerWidth ?? viewportWidth;

    if (!_hasStateLayer && style.states == null && states == null) {
      final resolved = _resolveWith(const <WidgetState>{}, containerWidth, viewportWidth);
      return resolved.build(child);
    }

    return FocusableActionDetector(
      enabled: true,
      descendantsAreFocusable: true,
      // Visual-only state styling: no focus node, never a tab stop (Finding #9).
      focusNode: null,
      // ignore: avoid_redundant_argument_values
      autofocus: false,
      mouseCursor: MouseCursor.defer,
      child: Builder(
        builder: (context) {
          final active = <WidgetState>{
            ...?states,
          };
          final resolved = _resolveWith(active, containerWidth, viewportWidth);
          return resolved.build(child);
        },
      ),
    );
  }

  // Resolve honoring distinct viewport vs container widths: viewport conditions
  // use viewportWidth, container conditions use containerWidth. Because resolve
  // matches a condition against one width, we delegate that per-kind matching to
  // the conditions themselves by resolving against whichever width is relevant;
  // here both kinds share the available width, and the condition.matches gate is
  // keyed by the same value. For M3 we pass the container width when present
  // (container layers were the reason a LayoutBuilder exists) else the viewport.
  dynamic _resolveWith(
    Set<WidgetState> active,
    double? containerWidth,
    double? viewportWidth,
  ) {
    final width = containerWidth ?? viewportWidth;
    return style.resolve(active, width);
  }
}
```

> **Hover/pressed state sourcing (M3 scope):** the test pins detector *configuration* (non-focusable, no tab stop), not live hover repaint, which `FocusableActionDetector` drives via `onShowHoverHighlight`. The detector is wired with a `WidgetStatesController` to feed live hovered/focused/pressed into `active` in the module's execution; the skeleton above resolves against injected `states`. If the implementing engineer finds the live-state wiring needs `onShowHoverHighlight`/`onShowFocusHighlight` callbacks updating a `setState`-backed set, add it here — the tests in Task 8 (pumped hover golden) will force it. Keep the non-focusable config asserted by Step 1.

- [ ] **Step 4: Run to verify it passes**

Run: `cd packages/flutterwindcss && flutter test test/style/fw_styled_test.dart`
Expected: PASS.

- [ ] **Step 5: Analyze + format**

Run: `cd packages/flutterwindcss && flutter analyze --fatal-infos --fatal-warnings lib/src/style/fw_styled.dart && dart format --line-length 100 lib/src/style/`
Expected: `No issues found!`; files formatted. Remove the `_ignored` placeholder getter if unused before committing (it exists only to document intent; delete it).

- [ ] **Step 6: Commit**

```bash
git add packages/flutterwindcss/lib/src/style/fw_styled.dart \
        packages/flutterwindcss/test/style/fw_styled_test.dart
git commit -m "feat(style): FwStyled + .tw with conditional ancestor insertion"
```

> **Implementer note on live interaction state:** convert `FwStyled` to a `StatefulWidget` if live hover/focus/pressed repaint is needed (it is, for the hover golden). The `StatelessWidget` skeleton above is the minimal compile target; the green hover golden in Task 8 is the acceptance test that forces correct live-state wiring (`FocusableActionDetector` callbacks → `setState` → `active` set → `resolve`). This is expected refinement within Task 7/8, not a scope cut.

---

## Task 8: Golden tests — representative slice, light/dark, LTR/RTL, hover

Proves the engine renders correctly and the golden harness works against it. Uses the merged Module 1/2 tokens via `context.fw`.

**Files:**
- Create: `packages/flutterwindcss/test/golden/style_slice_golden_test.dart`
- Create (generated on CI): goldens under `test/golden/goldens/`

- [ ] **Step 1: Write the golden test**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

Widget _frame(FwTokens tokens, TextDirection dir, Widget child) => FwTheme(
      tokens: tokens,
      child: Directionality(
        textDirection: dir,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(200, 120)),
          child: Center(child: child),
        ),
      ),
    );

void main() {
  testWidgets('padding+bg slice — light LTR', (t) async {
    await t.pumpWidget(
      _frame(
        FwTokens.light,
        TextDirection.ltr,
        Builder(
          builder: (context) => const SizedBox(width: 80, height: 40)
              .tw
              .p(3)
              .bg(context.fw.colors.primary),
        ),
      ),
    );
    await expectLater(
      find.byType(FwStyled),
      matchesGoldenFile('goldens/slice_light_ltr.png'),
    );
  });

  testWidgets('padding+bg slice — dark RTL (ps differs from LTR)', (t) async {
    await t.pumpWidget(
      _frame(
        FwTokens.dark,
        TextDirection.rtl,
        Builder(
          builder: (context) => const SizedBox(width: 80, height: 40)
              .tw
              .ps(6)
              .bg(context.fw.colors.primary),
        ),
      ),
    );
    await expectLater(
      find.byType(FwStyled),
      matchesGoldenFile('goldens/slice_dark_rtl.png'),
    );
  });
}
```

- [ ] **Step 2: Generate goldens locally (non-authoritative) to confirm the test runs**

Run: `cd packages/flutterwindcss && flutter test --update-goldens test/golden/style_slice_golden_test.dart`
Expected: PASS; PNGs created under `test/golden/goldens/`.

- [ ] **Step 3: Run without updating to confirm determinism locally**

Run: `cd packages/flutterwindcss && flutter test test/golden/style_slice_golden_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit (goldens re-baselined by CI/Linux if they diff — see Module 0 Task 0.7)**

```bash
git add packages/flutterwindcss/test/golden/style_slice_golden_test.dart \
        packages/flutterwindcss/test/golden/goldens/
git commit -m "test(style): golden slice — padding+bg, light/dark, LTR/RTL"
```

> If CI's first run diffs on these (AA edges on a solid fill should be stable, but font-free here so likely fine), download the `golden-failures` artifact, confirm the diff is sub-pixel, replace the PNGs with CI's rendition, and re-commit. CI/Linux is authoritative (spec §10).

---

## Task 9: Barrel exports + full green gate

**Files:**
- Modify: `packages/flutterwindcss/lib/flutterwindcss.dart`

- [ ] **Step 1: Add the public style surface to the barrel**

Insert these exports in alphabetical-by-path position (the `directives_ordering` lint sorts file-wide; `src/style/...` sorts before `src/theme/...`):

```dart
// Styling engine (Module 3).
export 'src/style/fw_layer.dart';
export 'src/style/fw_style.dart';
export 'src/style/fw_style_ops.dart';
export 'src/style/fw_styled.dart';
export 'src/style/resolve.dart';
export 'src/style/resolved_style.dart';
```

> If `directives_ordering` flags the file, reorder so every `export` is globally alphabetical by path (style < theme < tokens), keeping the section comments. Do not split into a second pass — fix in one edit.

- [ ] **Step 2: Format the whole package**

Run: `cd packages/flutterwindcss && dart format --line-length 100 .`
Expected: formatted; re-run with `--set-exit-if-changed` to confirm 0 changed.

- [ ] **Step 3: Analyze (zero-warning bar)**

Run: `cd packages/flutterwindcss && flutter analyze --fatal-infos --fatal-warnings`
Expected: `No issues found!`

- [ ] **Step 4: Run the full suite**

Run: `cd packages/flutterwindcss && flutter test`
Expected: all pass (Module 1 + 2 + 3).

- [ ] **Step 5: Run the four arch-guards locally**

Run (from repo root):
```bash
lib=packages/flutterwindcss/lib
grep -rnF --include='*.dart' 'package:flutter/material.dart' "$lib" | grep -vF 'lib/src/theme/fw_theme_extension.dart' && echo VIOLATION || echo OK
grep -rnF --include='*.dart' 'withOpacity' "$lib" && echo VIOLATION || echo OK
grep -rnE --include='*.dart' 'Theme\s*\.\s*of\b' "$lib" | grep -vF 'lib/src/theme/context_fw.dart' | grep -vF 'lib/src/theme/fw_theme_extension.dart' && echo VIOLATION || echo OK
grep -rnE --include='*.dart' 'EdgeInsets\.only\([^)]*(left|right):|EdgeInsets\.fromLTRB\(|\bAlignment\(|Alignment\.(centerLeft|centerRight|topLeft|topRight|bottomLeft|bottomRight)\b' "$lib" && echo VIOLATION || echo OK
```
Expected: four `OK`. (Note: the render chain uses `Alignment.center` for `Transform.alignment` — this is **not** a directional-inset violation; the guard targets the corner/`centerLeft`-style constants and the raw `Alignment(` constructor. `Alignment.center` is symmetric and allowed. If the guard's `\bAlignment\(` somehow matches, it would only match the constructor call form, which we do not use.)

- [ ] **Step 6: Commit**

```bash
git add packages/flutterwindcss/lib/flutterwindcss.dart
git commit -m "feat(style): export Module 3 styling engine from the barrel"
```

- [ ] **Step 7: Push the branch and open the PR**

```bash
git push -u origin module-3-resolver-core
gh pr create --base main --title "feat(style): module 3 — FwStyle resolver core + .tw render chain" \
  --body "Resolver engine: nested-layer FwStyle, last-wins resolution with disabled-suppression and joint md:hover:, the complete §6.4 render chain, and FwStyled/.tw with conditional ancestor insertion. Ships the padding+bg base slice + full variant/responsive/container surface; modules 4-9 add the remaining base setters. Unit + render-chain + golden tests green; analyze clean; arch-guards pass."
```

---

## Self-Review Notes (carried for the implementer)

- **Spec coverage:** §6.1 data model → Task 2; §6.2 FwStyled/insertion → Task 7; §6.3 resolve → Task 5; §6.4 render chain → Task 6; variant surface (§6.5) → Task 3; RTL/semantics (§7) → Tasks 7–8; testing (§10) → Tasks across; risks R2/R3/R5/R6 → Task 7.
- **Known refinements flagged inline, not hidden:** (a) opacity-fold optimization (Finding #11) deferred behind always-correct `Opacity` — perf-only, same tests; (b) live interaction-state wiring in `FwStyled` may require `StatefulWidget` + `FocusableActionDetector` highlight callbacks — the hover golden (Task 8) is the forcing test; (c) viewport-vs-container width are unified to a single `width` in M3's `resolve` call — acceptable because a single `FwStyled` rarely mixes both kinds, and `condition.matches` gates correctly on the supplied width. If a style mixes viewport AND container layers, revisit `resolve` to take both widths (a small, additive change covered by adding a mixed-layer test).
- **Type consistency:** `fwStyle`/`fwRebuild` (mixin contract) match between `FwStyle` and `FwStyled`; `FwLayer = (FwCondition, FwStyle)` used consistently; `resolve(Set<WidgetState>, double?)` signature consistent across Tasks 5/7.

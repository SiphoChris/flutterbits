import 'package:flutter/widgets.dart';

import 'fw_layer.dart';
import 'fw_style.dart';
import 'resolved_style.dart';

/// Resolution: flatten base + matching nested layers into a [ResolvedStyle].
extension FwStyleResolve on FwStyle {
  /// Resolves this style against the active interaction [states], the
  /// [viewportWidth] (screen size, for `sm…2xl` layers), and the
  /// [containerWidth] (enclosing constraint, for `containerSm…container2xl`
  /// layers). The two widths are kept separate so a viewport layer never
  /// matches on container size or vice-versa (spec §6.3).
  ResolvedStyle resolve(Set<WidgetState> states, {double? viewportWidth, double? containerWidth}) {
    // 1. Disabled suppression first (Finding #7): disabled removes the other
    //    three from the working set before any matching, so it always wins.
    final Set<WidgetState> working;
    if (states.contains(WidgetState.disabled)) {
      working = <WidgetState>{
        for (final s in states)
          if (s != WidgetState.hovered && s != WidgetState.focused && s != WidgetState.pressed) s,
      };
    } else {
      working = states;
    }

    // 2. Accumulate base + matching layers (recursively) via last-wins copyWith.
    final merged = _flatten(this, working, viewportWidth, containerWidth);

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
      factorAlignment: merged.factorAlignment ?? AlignmentDirectional.centerStart,
      aspectRatio: merged.aspectRatio,
      background: merged.background,
      gradient: merged.gradient,
      border: merged.borderSpec?.resolve(),
      borderRadius: merged.borderRadius,
      boxShadow: merged.boxShadow,
      foreground: merged.foreground,
      fontSize: merged.fontSize,
      fontWeight: merged.fontWeight,
      letterSpacing: merged.letterSpacing,
      lineHeight: merged.lineHeight,
      textAlign: merged.textAlign,
      textDecoration: merged.textDecoration,
      fontFamily: merged.fontFamily,
      // FwStyle's descriptive `maxLineCount` projects to the terse `maxLines`.
      maxLines: merged.maxLineCount,
      textOverflow: merged.textOverflow,
      softWrap: merged.softWrap,
      // FwStyle uses descriptive names (groupOpacity/contentBlur/
      // backdropBlurSigma) to free the .tw setter names; ResolvedStyle keeps the
      // terse render-chain names. This is the one place the two vocabularies meet.
      opacity: merged.groupOpacity,
      blur: merged.contentBlur,
      backdropBlur: merged.backdropBlurSigma,
      scale: merged.scaleFactor,
      rotation: merged.rotation,
      translate: merged.translation,
      clipBehavior: merged.clipBehavior,
    );
  }
}

/// Returns a single [FwStyle] with [style]'s base fields overlaid by every
/// matching layer, applied in **cascade order** (not raw declaration order):
///
/// 1. **Responsive breakpoint layers** first, ordered by breakpoint min-width
///    ascending — so a larger breakpoint always wins at larger sizes regardless
///    of the order they were chained (`.md(...).sm(...)` ≡ `.sm(...).md(...)`),
///    mirroring Tailwind's mobile-first min-width cascade and the layout
///    widgets' `fwActivePatches`. A **container** layer beats a **viewport**
///    layer at the same breakpoint (the more specific context).
/// 2. **Interaction-state layers** next — they outrank breakpoints, the way a CSS
///    pseudo-class adds specificity (so `hover:` beats `sm:` at ≥ sm).
/// 3. **Declaration order** breaks ties within a tier (last-declared wins among
///    equals, e.g. two `hover:` layers or two same-breakpoint container layers).
///
/// Each layer's nested style is resolved first, so joint `md:hover:` still
/// requires both. Corrected — audit (module 3): the resolver previously applied
/// matching layers in raw declaration order, which let `.md(...).sm(...)` invert
/// the cascade (the smaller, later-declared `sm` overriding `md` at large widths)
/// and diverged from the layout widgets. The cascade above raises the bar to an
/// order-independent, Tailwind-faithful precedence.
FwStyle _flatten(
  FwStyle style,
  Set<WidgetState> states,
  double? viewportWidth,
  double? containerWidth,
) {
  var acc = style.copyWith(layers: const <FwLayer>[]); // base fields only

  // Collect matching layers tagged with their cascade rank + declaration index,
  // then overlay in ascending rank so the highest-precedence layer is applied
  // last (wins). The explicit index makes the ordering a total order, so the
  // non-stable `List.sort` still preserves declaration order within a tier.
  final matched = <({int tier, double width, int axis, int index, FwStyle nested})>[];
  var index = 0;
  for (final (condition, nested) in style.layers) {
    if (condition.matches(states, viewportWidth, containerWidth)) {
      final (tier, width, axis) = _precedence(condition);
      final entry = (
        tier: tier,
        width: width,
        axis: axis,
        index: index,
        nested: _flatten(nested, states, viewportWidth, containerWidth),
      );
      matched.add(entry);
    }
    index++;
  }
  matched.sort((p, q) {
    if (p.tier != q.tier) return p.tier.compareTo(q.tier);
    if (p.width != q.width) return p.width.compareTo(q.width);
    if (p.axis != q.axis) return p.axis.compareTo(q.axis);
    return p.index.compareTo(q.index);
  });
  for (final m in matched) {
    acc = _overlay(acc, m.nested);
  }
  return acc;
}

/// Cascade rank of a matching layer as `(tier, width, axis)`, sorted ascending so
/// the last-overlaid (highest) wins. Breakpoint layers are **tier 0** (ordered by
/// min-[width]; container [axis] `1` beats viewport [axis] `0` at the same width);
/// state layers are **tier 1** — above every breakpoint, like a CSS pseudo-class.
(int, double, int) _precedence(FwCondition condition) => switch (condition) {
  FwViewportCondition(:final breakpoint) => (0, breakpoint.minWidth, 0),
  FwContainerCondition(:final breakpoint) => (0, breakpoint.minWidth, 1),
  FwStateCondition() => (1, 0, 0),
};

/// Field-by-field last-wins overlay: every non-null field of [top] replaces the
/// corresponding field of [base] (relies on `copyWith` treating null as "keep").
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
  borderSpec: top.borderSpec,
  borderRadius: top.borderRadius,
  boxShadow: top.boxShadow,
  foreground: top.foreground,
  fontSize: top.fontSize,
  fontWeight: top.fontWeight,
  letterSpacing: top.letterSpacing,
  lineHeight: top.lineHeight,
  textAlign: top.textAlign,
  textDecoration: top.textDecoration,
  fontFamily: top.fontFamily,
  maxLineCount: top.maxLineCount,
  textOverflow: top.textOverflow,
  softWrap: top.softWrap,
  groupOpacity: top.groupOpacity,
  contentBlur: top.contentBlur,
  backdropBlurSigma: top.backdropBlurSigma,
  scaleFactor: top.scaleFactor,
  rotation: top.rotation,
  translation: top.translation,
  clipBehavior: top.clipBehavior,
);

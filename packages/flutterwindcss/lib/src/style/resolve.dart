import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';
import 'fw_layer.dart';
import 'fw_style.dart';
import 'resolved_style.dart';

/// Theme-token pre-resolution for the named-scale sugar (module 15).
///
/// `roundedMd`/`shadowSm`/… store a *step* enum; this pass — run by `FwStyled`
/// at build, where a [FwTokens] is in scope — converts each step into the
/// concrete `borderRadius`/`boxShadow` against the active theme, recursing into
/// nested layers so `hover:shadow-lg` works. It runs **before** [resolve] so
/// `resolve` itself stays context-free (spec §6.3). A node that sets both a step
/// and the corresponding raw value asserts: the accumulator can't last-wins
/// across two fields, so the author must pick one.
extension FwStyleTokenResolve on FwStyle {
  /// Returns a copy with every radius/shadow step (here and in nested layers)
  /// resolved against [tokens]; styles with no steps are returned unchanged.
  FwStyle resolveTokenSteps(FwTokens tokens) {
    final newLayers = <FwLayer>[
      for (final (condition, nested) in layers) (condition, nested.resolveTokenSteps(tokens)),
    ];
    var out = copyWith(layers: newLayers);
    if (radiusStep != null) {
      assert(
        borderRadius == null,
        'flutterwindcss: do not mix a radius step (roundedSm/Md/Lg/Xl) with a raw '
        'rounded*(value) in the same chain — last-wins cannot order two fields. '
        'Pick one (use rounded(context.fw.radii.md) for per-corner control).',
      );
      out = out.copyWith(
        borderRadius: BorderRadiusDirectional.all(Radius.circular(radiusStep!.resolve(tokens))),
      );
    }
    if (shadowStep != null) {
      assert(
        boxShadow == null,
        'flutterwindcss: do not mix a shadow step (shadowSm/Md/…) with a raw '
        'shadow(list) in the same chain — last-wins cannot order two fields.',
      );
      out = out.copyWith(boxShadow: shadowStep!.resolve(tokens));
    }
    return out;
  }
}

/// Whether [style] (or any nested layer) still carries an *unresolved* radius or
/// shadow token step — used by [FwStyleResolve.resolve]'s debug guard to catch a
/// caller that skipped [FwStyleTokenResolve.resolveTokenSteps].
///
/// [FwStyleTokenResolve.resolveTokenSteps] populates `borderRadius`/`boxShadow`
/// from the step but cannot null the step field (copyWith treats null as "keep"),
/// so a *resolved* style legitimately still holds the step alongside its concrete
/// value. The unresolved state is therefore "step set **without** its concrete
/// field" — the pre-resolution invariant the mixing assert guarantees.
bool _hasUnresolvedTokenSteps(FwStyle style) {
  if (style.radiusStep != null && style.borderRadius == null) return true;
  if (style.shadowStep != null && style.boxShadow == null) return true;
  for (final (_, nested) in style.layers) {
    if (_hasUnresolvedTokenSteps(nested)) return true;
  }
  return false;
}

/// Drops hover/focus/pressed from [states] when `disabled` is present (spec §6.3
/// Finding #7); otherwise returns [states] unchanged.
Set<WidgetState> _suppressDisabled(Set<WidgetState> states) {
  if (!states.contains(WidgetState.disabled)) return states;
  return <WidgetState>{
    for (final s in states)
      if (s != WidgetState.hovered && s != WidgetState.focused && s != WidgetState.pressed) s,
  };
}

/// Applies [_suppressDisabled] to every channel of a group/peer state map
/// (module 14). Returns `null` for a `null` input (the no-scope fast path).
Map<String?, Set<WidgetState>>? _suppressChannels(Map<String?, Set<WidgetState>>? channels) {
  if (channels == null) return null;
  return <String?, Set<WidgetState>>{
    for (final MapEntry(:key, :value) in channels.entries) key: _suppressDisabled(value),
  };
}

/// Resolution: flatten base + matching nested layers into a [ResolvedStyle].
extension FwStyleResolve on FwStyle {
  /// Resolves this style against the active interaction [states], the
  /// [viewportWidth] (screen size, for `sm…2xl` layers), and the
  /// [containerWidth] (enclosing constraint, for `containerSm…container2xl`
  /// layers). The two widths are kept separate so a viewport layer never
  /// matches on container size or vice-versa (spec §6.3).
  ResolvedStyle resolve(
    Set<WidgetState> states, {
    double? viewportWidth,
    double? containerWidth,
    Map<String?, Set<WidgetState>>? groupStates,
    Map<String?, Set<WidgetState>>? peerStates,
  }) {
    // Guard the resolution contract: named-scale sugar (`roundedMd`/`shadowSm`)
    // is stored as a token *step* that must be resolved against the theme by
    // resolveTokenSteps() BEFORE resolve() runs. ResolvedStyle carries no step,
    // and the layer overlay drops steps, so calling resolve() on a style that
    // still holds steps would silently lose them. FwStyled does this for you;
    // any direct caller must too (§12 "guard what the dev shouldn't do").
    assert(
      !_hasUnresolvedTokenSteps(this),
      'flutterwindcss: resolve() was called on a style that still has unresolved '
      'radiusStep/shadowStep (roundedMd/shadowSm sugar). Call '
      'style.resolveTokenSteps(tokens) first — FwStyled does this automatically.',
    );

    // 1. Disabled suppression first (Finding #7): disabled removes the other
    //    three from the working set before any matching, so it always wins. The
    //    same rule is applied per-channel to the group/peer maps (module 14): a
    //    disabled group/peer must not also fire hover/focus/pressed.
    final working = _suppressDisabled(states);
    final groups = _suppressChannels(groupStates);
    final peers = _suppressChannels(peerStates);

    // 2. Accumulate base + matching layers (recursively) via last-wins copyWith.
    final merged = _flatten(this, working, viewportWidth, containerWidth, groups, peers);

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
      backgroundImage: merged.backgroundImage,
      border: merged.borderSpec?.resolve(),
      borderStyle: merged.borderStyle,
      borderRadius: merged.borderRadius,
      boxShadow: merged.boxShadow,
      ringSpec: merged.ringSpec,
      foreground: merged.foreground,
      fontSize: merged.fontSize,
      fontWeight: merged.fontWeight,
      letterSpacing: merged.letterSpacing,
      lineHeight: merged.lineHeight,
      textAlign: merged.textAlign,
      textDecoration: merged.textDecoration,
      textShadows: merged.textShadows,
      fontFamily: merged.fontFamily,
      fontStyle: merged.fontStyle,
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
      scaleX: merged.scaleXFactor,
      scaleY: merged.scaleYFactor,
      skewX: merged.skewXAngle,
      skewY: merged.skewYAngle,
      transformAlignment: merged.transformAlignment,
      rotation: merged.rotation,
      rotateX: merged.rotateXAngle,
      rotateY: merged.rotateYAngle,
      perspective: merged.perspectiveDepth,
      translate: merged.translation,
      colorMatrix: merged.colorMatrix,
      blendMode: merged.mixBlendMode,
      fit: merged.boxFit,
      mouseCursor: merged.mouseCursor,
      ignorePointer: merged.ignorePointer,
      isVisible: merged.isVisible,
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
  Map<String?, Set<WidgetState>>? groupStates,
  Map<String?, Set<WidgetState>>? peerStates,
) {
  var acc = style.copyWith(layers: const <FwLayer>[]); // base fields only

  // Collect matching layers tagged with their cascade rank + declaration index,
  // then overlay in ascending rank so the highest-precedence layer is applied
  // last (wins). The explicit index makes the ordering a total order, so the
  // non-stable `List.sort` still preserves declaration order within a tier.
  final matched = <({int tier, double width, int axis, int index, FwStyle nested})>[];
  var index = 0;
  for (final (condition, nested) in style.layers) {
    if (condition.matches(
      states,
      viewportWidth,
      containerWidth,
      groupStates: groupStates,
      peerStates: peerStates,
    )) {
      final (tier, width, axis) = _precedence(condition);
      final entry = (
        tier: tier,
        width: width,
        axis: axis,
        index: index,
        nested: _flatten(nested, states, viewportWidth, containerWidth, groupStates, peerStates),
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
/// Group/peer layers ([FwGroupCondition]) also rank **tier 1**: they are
/// pseudo-class-like variants above all breakpoints, with declaration order
/// breaking ties against own-state layers (module 14).
(int, double, int) _precedence(FwCondition condition) => switch (condition) {
  FwViewportCondition(:final breakpoint) => (0, breakpoint.minWidth, 0),
  FwContainerCondition(:final breakpoint) => (0, breakpoint.minWidth, 1),
  FwStateCondition() => (1, 0, 0),
  FwGroupCondition() => (1, 0, 0),
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
  backgroundImage: top.backgroundImage,
  borderSpec: top.borderSpec,
  borderStyle: top.borderStyle,
  borderRadius: top.borderRadius,
  boxShadow: top.boxShadow,
  ringSpec: top.ringSpec,
  foreground: top.foreground,
  fontSize: top.fontSize,
  fontWeight: top.fontWeight,
  letterSpacing: top.letterSpacing,
  lineHeight: top.lineHeight,
  textAlign: top.textAlign,
  textDecoration: top.textDecoration,
  textShadows: top.textShadows,
  fontFamily: top.fontFamily,
  fontStyle: top.fontStyle,
  maxLineCount: top.maxLineCount,
  textOverflow: top.textOverflow,
  softWrap: top.softWrap,
  groupOpacity: top.groupOpacity,
  contentBlur: top.contentBlur,
  backdropBlurSigma: top.backdropBlurSigma,
  scaleFactor: top.scaleFactor,
  scaleXFactor: top.scaleXFactor,
  scaleYFactor: top.scaleYFactor,
  skewXAngle: top.skewXAngle,
  skewYAngle: top.skewYAngle,
  transformAlignment: top.transformAlignment,
  rotation: top.rotation,
  rotateXAngle: top.rotateXAngle,
  rotateYAngle: top.rotateYAngle,
  perspectiveDepth: top.perspectiveDepth,
  translation: top.translation,
  colorMatrix: top.colorMatrix,
  mixBlendMode: top.mixBlendMode,
  boxFit: top.boxFit,
  mouseCursor: top.mouseCursor,
  ignorePointer: top.ignorePointer,
  isVisible: top.isVisible,
  clipBehavior: top.clipBehavior,
);

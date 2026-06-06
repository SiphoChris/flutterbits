import 'package:flutter/widgets.dart';

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

/// Returns a single [FwStyle] with [style]'s base fields overlaid, in declaration
/// order, by every matching layer (recursing into each nested layer first so a
/// nested style's own layers are applied before merging up — joint `md:hover:`).
FwStyle _flatten(
  FwStyle style,
  Set<WidgetState> states,
  double? viewportWidth,
  double? containerWidth,
) {
  var acc = style.copyWith(layers: const <FwLayer>[]); // base fields only
  for (final (condition, nested) in style.layers) {
    if (condition.matches(states, viewportWidth, containerWidth)) {
      final resolvedNested = _flatten(nested, states, viewportWidth, containerWidth);
      acc = _overlay(acc, resolvedNested);
    }
  }
  return acc;
}

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
  opacity: top.opacity,
  blur: top.blur,
  backdropBlur: top.backdropBlur,
  scale: top.scale,
  rotation: top.rotation,
  translate: top.translate,
  clipBehavior: top.clipBehavior,
);

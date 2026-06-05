import 'dart:ui' as ui show ImageFilter;

import 'package:flutter/widgets.dart';

import 'resolved_style.dart';

/// Builds the fixed outer→inner primitive chain for a [ResolvedStyle] (spec
/// §6.4). Kept as an extension so [ResolvedStyle] stays a pure value type.
extension ResolvedStyleBuild on ResolvedStyle {
  /// Wraps [child] in the documented primitive chain. Each wrapper is emitted
  /// only when its input is set, so a static empty style returns [child]
  /// unwrapped. The order is asserted by tests because later modules depend on
  /// it; do not reorder without updating `render_chain_test.dart`.
  ///
  /// Outer→inner: `margin → constraints → aspect → fractional → transform →
  /// content-blur → opacity → shadow(unclipped) → surface(backdrop?+decoration)
  /// → content-clip → padding → text/icon defaults → child`.
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
    if (clipBehavior != null &&
        clipBehavior != Clip.none &&
        borderRadius != null) {
      current = ClipRRect(
        clipBehavior: clipBehavior!,
        borderRadius: borderRadius!,
        child: current,
      );
    }

    // Surface: optional backdrop blur clipped to the box, then the decoration
    // composited on top so a semi-transparent fill frosts the backdrop.
    final hasDecoration =
        background != null || gradient != null || border != null;
    if (backdropBlur != null) {
      current = ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: backdropBlur!,
            sigmaY: backdropBlur!,
          ),
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

    // Group opacity. Emitting a real Opacity is always correct; the
    // fold-into-bg-alpha optimization (Finding #11) is a later perf pass behind
    // these same tests, not part of M3.
    if (opacity != null) {
      current = Opacity(opacity: opacity!, child: current);
    }

    // Content blur (filters the whole element, incl. bg + border + content).
    if (blur != null) {
      current = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blur!, sigmaY: blur!),
        child: current,
      );
    }

    // Transform (paint-only; transforms the already-rendered result incl. the
    // shadow, matching CSS `transform`).
    if (scale != null || rotation != null || translate != null) {
      // Composed via stable constructors (not the deprecated instance
      // `scale`/`translate`, which also keeps us compatible with the pinned
      // floor toolchain). Right-multiplying T·R·S applies scale first, then
      // rotation, then translation — matching CSS `transform` semantics.
      var m = Matrix4.identity();
      if (translate != null) {
        m = m.multiplied(Matrix4.translationValues(translate!.dx, translate!.dy, 0));
      }
      if (rotation != null) {
        m = m.multiplied(Matrix4.rotationZ(rotation!));
      }
      if (scale != null) {
        m = m.multiplied(Matrix4.diagonal3Values(scale!, scale!, 1));
      }
      current = Transform(
        transform: m,
        alignment: Alignment.center,
        child: current,
      );
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

    // Sizing reconciliation: a fixed dim => tight constraint and wins its axis;
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
}

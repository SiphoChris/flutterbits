import 'package:flutter/widgets.dart';

import 'fw_border_spec.dart';
import 'fw_ring.dart';

/// The flattened, concrete style the render chain consumes (spec §6.3/§6.4).
///
/// Optional wrappers read nullable fields ("emit iff set"); [factorAlignment]
/// carries its non-null default since `FractionallySizedBox` needs one. The
/// render chain ([build]) is in `resolved_style.build.dart` as an extension so
/// this struct stays a pure value type.
///
/// **Intentionally identity-equality** (no `==`/`hashCode`): a `ResolvedStyle` is
/// produced transiently inside `FwStyled.build` and consumed immediately by the
/// render chain — it is never a widget field nor memoized, so value equality
/// would be dead weight. (Persisted/diffed value types in the engine — `FwStyle`,
/// `FwColors`, `FwBorderSpec`, … — do implement equality.) If a future caller
/// memoizes on a `ResolvedStyle`, add equality then.
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
    this.borderStyle,
    this.borderRadius,
    this.boxShadow,
    this.ringSpec,
    this.foreground,
    this.fontSize,
    this.fontWeight,
    this.letterSpacing,
    this.lineHeight,
    this.textAlign,
    this.textDecoration,
    this.fontFamily,
    this.fontStyle,
    this.maxLines,
    this.textOverflow,
    this.softWrap,
    this.opacity,
    this.blur,
    this.backdropBlur,
    this.scale,
    this.scaleX,
    this.scaleY,
    this.skewX,
    this.skewY,
    this.transformAlignment,
    this.rotation,
    this.translate,
    this.colorMatrix,
    this.fit,
    this.mouseCursor,
    this.ignorePointer,
    this.isVisible,
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

  /// Border line style; non-solid ⇒ painted by `FwDashedBorderPainter` (M15).
  final FwBorderStyle? borderStyle;

  /// Corner radii (directional).
  final BorderRadiusDirectional? borderRadius;

  /// Drop shadows.
  final List<BoxShadow>? boxShadow;

  /// Focus-ring spec, rendered as composed box-shadows with [boxShadow] (M15).
  final FwRing? ringSpec;

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

  /// Default font family.
  final String? fontFamily;

  /// Default font style (italic/normal).
  final FontStyle? fontStyle;

  /// Max lines before truncation.
  final int? maxLines;

  /// Text overflow behavior at [maxLines].
  final TextOverflow? textOverflow;

  /// Whether text soft-wraps.
  final bool? softWrap;

  /// Group opacity.
  final double? opacity;

  /// Content blur sigma.
  final double? blur;

  /// Backdrop blur sigma.
  final double? backdropBlur;

  /// Uniform scale factor.
  final double? scale;

  /// Per-axis horizontal scale (composes with [scale]).
  final double? scaleX;

  /// Per-axis vertical scale (composes with [scale]).
  final double? scaleY;

  /// Horizontal skew angle (radians).
  final double? skewX;

  /// Vertical skew angle (radians).
  final double? skewY;

  /// Transform origin / anchor (defaults to center).
  final AlignmentGeometry? transformAlignment;

  /// Rotation radians.
  final double? rotation;

  /// Translate offset.
  final Offset? translate;

  /// Composed CSS-filter colour matrix (4×5, 20 values) → `ColorFilter.matrix`.
  final List<double>? colorMatrix;

  /// Object-fit for the content (→ `FittedBox`).
  final BoxFit? fit;

  /// Mouse cursor over the box (→ `MouseRegion`).
  final MouseCursor? mouseCursor;

  /// Whether the box ignores pointer events (→ `IgnorePointer`).
  final bool? ignorePointer;

  /// Visibility — `false` hides but keeps layout space (→ `Visibility`).
  final bool? isVisible;

  /// Clip behavior.
  final Clip? clipBehavior;
}

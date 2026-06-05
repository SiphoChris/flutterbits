import 'package:flutter/widgets.dart';

/// The flattened, concrete style the render chain consumes (spec §6.3/§6.4).
///
/// Optional wrappers read nullable fields ("emit iff set"); [factorAlignment]
/// carries its non-null default since `FractionallySizedBox` needs one. The
/// render chain ([build]) is in `resolved_style.build.dart` as an extension so
/// this struct stays a pure value type.
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

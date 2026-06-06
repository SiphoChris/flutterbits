import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'fw_border_spec.dart';
import 'fw_layer.dart';
import 'fw_style_ops.dart';

/// One nested style layer: the condition under which it applies and the style to
/// merge when it does. The style may itself contain layers (joint `md:hover:`).
typedef FwLayer = (FwCondition condition, FwStyle style);

/// The immutable, lazily-resolved single-box style accumulator (spec §6.1).
///
/// All base fields are nullable (null = unset). Builder methods (the `.tw`
/// utilities) live in [FwStyleOps] and produce new styles via [copyWith] (base,
/// replacement = last-wins) or [addLayer] (variants, append). Resolution against
/// interaction states + widths happens in `resolve.dart`.
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
    this.borderSpec,
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

  /// Alignment for fractional sizing (defaults to centerStart at resolve time).
  final AlignmentDirectional? factorAlignment;

  /// Aspect ratio (width / height).
  final double? aspectRatio;

  // Color / decoration.
  /// Solid background fill.
  final Color? background;

  /// Gradient fill (replaces [background] when both set).
  final Gradient? gradient;

  /// Accumulating border description (uniform or per-side directional); resolves
  /// to a concrete `BoxBorder` at resolve time. Renamed from M3's `border`
  /// placeholder (spec §6.1; the field now holds an [FwBorderSpec], not a
  /// `BoxBorder`).
  final FwBorderSpec? borderSpec;

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
  /// last-wins. Pass [layers] only from [addLayer].
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
    FwBorderSpec? borderSpec,
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
      borderSpec: borderSpec ?? this.borderSpec,
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
      borderSpec == other.borderSpec &&
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
    padding,
    margin,
    width,
    height,
    minWidth,
    minHeight,
    maxWidth,
    maxHeight,
    widthFactor,
    heightFactor,
    factorAlignment,
    aspectRatio,
    background,
    gradient,
    borderSpec,
    borderRadius,
    boxShadow == null ? null : Object.hashAll(boxShadow!),
    foreground,
    fontSize,
    fontWeight,
    letterSpacing,
    lineHeight,
    textAlign,
    textDecoration,
    opacity,
    blur,
    backdropBlur,
    scale,
    rotation,
    translate,
    clipBehavior,
    Object.hashAll(layers),
  ]);
}

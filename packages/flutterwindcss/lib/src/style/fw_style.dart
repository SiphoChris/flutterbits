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
    this.fontFamily,
    this.maxLineCount,
    this.textOverflow,
    this.softWrap,
    this.groupOpacity,
    this.contentBlur,
    this.backdropBlurSigma,
    this.scaleFactor,
    this.rotation,
    this.translation,
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

  /// Default font family (set by `font`/`fontSans`/`fontSerif`/`fontMono`).
  final String? fontFamily;

  /// Maximum lines before truncation (set by `maxLines`/`lineClamp`/`truncate`).
  /// Named `maxLineCount`, not `maxLines`, so the Tailwind-natural `maxLines`
  /// setter in [FwStyleOps] doesn't collide with this field (same rationale as
  /// `groupOpacity` vs the `opacity` setter).
  final int? maxLineCount;

  /// How text overflows once it hits [maxLineCount] (set by `overflow`/
  /// `lineClamp`/`truncate`).
  final TextOverflow? textOverflow;

  /// Whether text soft-wraps (set by `nowrap`/`wrap`/`truncate`). `false` ⇒
  /// single unwrapped line (Tailwind `whitespace-nowrap`).
  final bool? softWrap;

  // Effects. Named descriptively so the Tailwind-natural `.tw` setters
  // (`opacity`/`blur`/`backdropBlur`) don't collide with these fields (the mixin
  // can't redeclare a field name). `ResolvedStyle` keeps the terse render-chain
  // names; the mapping lives in the resolve projection.
  /// Group opacity (0..1); written by the `opacity` setter.
  final double? groupOpacity;

  /// Content blur sigma (logical px); written by the `blur` setter.
  final double? contentBlur;

  /// Backdrop blur sigma (logical px); written by the `backdropBlur` setter.
  final double? backdropBlurSigma;

  // Transform (paint-only). Field names differ from the Tailwind-natural `.tw`
  // setters (`scale`/`translate`) so the mixin can own those names (as with the
  // M7 effect fields); `ResolvedStyle` keeps the terse render-chain names.
  /// Uniform scale factor (set by the `scale` setter).
  final double? scaleFactor;

  /// Rotation in radians (set by the `rotate` setter, which takes degrees).
  final double? rotation;

  /// Translation offset in logical px (set by `translate`/`translateX/Y`).
  final Offset? translation;

  // Overflow.
  /// Content clip behavior.
  final Clip? clipBehavior;

  /// Nested variant layers, in declaration order.
  ///
  /// **Layers are additive / override-only** (Tailwind-faithful): a matching
  /// layer can *set* a field but cannot *unset* a base field back to its default
  /// — resolution overlays via `copyWith`, where a `null` field means "keep". So
  /// `bg(c).hover((h) => …)` can change the background on hover but no variant can
  /// remove a base utility. This is a deliberate limitation of the accumulator
  /// model, not a bug.
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
    String? fontFamily,
    int? maxLineCount,
    TextOverflow? textOverflow,
    bool? softWrap,
    double? groupOpacity,
    double? contentBlur,
    double? backdropBlurSigma,
    double? scaleFactor,
    double? rotation,
    Offset? translation,
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
      fontFamily: fontFamily ?? this.fontFamily,
      maxLineCount: maxLineCount ?? this.maxLineCount,
      textOverflow: textOverflow ?? this.textOverflow,
      softWrap: softWrap ?? this.softWrap,
      groupOpacity: groupOpacity ?? this.groupOpacity,
      contentBlur: contentBlur ?? this.contentBlur,
      backdropBlurSigma: backdropBlurSigma ?? this.backdropBlurSigma,
      scaleFactor: scaleFactor ?? this.scaleFactor,
      rotation: rotation ?? this.rotation,
      translation: translation ?? this.translation,
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
      fontFamily == other.fontFamily &&
      maxLineCount == other.maxLineCount &&
      textOverflow == other.textOverflow &&
      softWrap == other.softWrap &&
      groupOpacity == other.groupOpacity &&
      contentBlur == other.contentBlur &&
      backdropBlurSigma == other.backdropBlurSigma &&
      scaleFactor == other.scaleFactor &&
      rotation == other.rotation &&
      translation == other.translation &&
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
    fontFamily,
    maxLineCount,
    textOverflow,
    softWrap,
    groupOpacity,
    contentBlur,
    backdropBlurSigma,
    scaleFactor,
    rotation,
    translation,
    clipBehavior,
    Object.hashAll(layers),
  ]);
}

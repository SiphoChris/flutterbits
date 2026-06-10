import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show MouseCursor;

import 'fw_border_spec.dart';
import 'fw_layer.dart';
import 'fw_ring.dart';
import 'fw_style_ops.dart';
import 'fw_token_steps.dart';

/// One nested style layer: the condition under which it applies and the style to
/// merge when it does. The style may itself contain layers (joint `md:hover:`).
typedef FwLayer = (FwCondition condition, FwStyle style);

/// The immutable, lazily-resolved single-box style accumulator (spec §6.1).
///
/// All base fields are nullable (null = unset). Builder methods (the `.tw`
/// utilities) live in [FwStyleOps] and produce new styles via [copyWith] (base,
/// replacement = last-wins) or [addLayer] (variants, append). Resolution against
/// interaction states + widths happens in `resolve.dart`.
///
/// **Variant layers are override-only.** Resolution overlays a layer's *non-null*
/// fields onto the base (null = "keep"), so a `hover:`/`sm:`/`group-*` layer can
/// only *set or change* a field — it cannot reset one back to "unset". Fields with
/// an explicit inverse setter can be re-set in a layer (`notItalic`, `visible`,
/// `wrap`, `borderSolid`, `shadowNone`, `roundedNone`); fields without one
/// (`maxLines`/`lineClamp`, `aspectRatio`, `fit`/`fitAlignment`, `blendMode`, the
/// color filters, `mouseCursor`, the transform fields, fractional `align`) can be
/// *overridden* in a layer but not *cleared*. Set the desired base value instead.
/// (This is why Tailwind's `line-clamp-none` has no layer-level equivalent — it is
/// one instance of this general rule, not a special case.)
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
    this.backgroundImage,
    this.borderSpec,
    this.borderStyle,
    this.borderRadius,
    this.radiusStep,
    this.boxShadow,
    this.shadowStep,
    this.ringSpec,
    this.foreground,
    this.fontSize,
    this.fontWeight,
    this.letterSpacing,
    this.lineHeight,
    this.textAlign,
    this.textDecoration,
    this.textShadows,
    this.fontFamily,
    this.fontFamilyStep,
    this.fontStyle,
    this.maxLineCount,
    this.textOverflow,
    this.softWrap,
    this.groupOpacity,
    this.contentBlur,
    this.backdropBlurSigma,
    this.scaleFactor,
    this.scaleXFactor,
    this.scaleYFactor,
    this.skewXAngle,
    this.skewYAngle,
    this.transformAlignment,
    this.rotation,
    this.rotateXAngle,
    this.rotateYAngle,
    this.perspectiveDepth,
    this.translation,
    this.colorMatrix,
    this.mixBlendMode,
    this.boxFit,
    this.fitAlignment,
    this.mouseCursor,
    this.ignorePointer,
    this.isVisible,
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

  /// Background image (Tailwind `bg-[url(...)]`); set by `bgImage`. Rendered as
  /// the decoration's `DecorationImage` (module 17).
  final DecorationImage? backgroundImage;

  /// Accumulating border description (uniform or per-side directional); resolves
  /// to a concrete `BoxBorder` at resolve time. Renamed from M3's `border`
  /// placeholder (spec §6.1; the field now holds an [FwBorderSpec], not a
  /// `BoxBorder`).
  final FwBorderSpec? borderSpec;

  /// Border line style (set by `borderDashed`/`borderDotted`/`borderSolid`); a
  /// non-solid style paints the border via `FwDashedBorderPainter` (module 15).
  final FwBorderStyle? borderStyle;

  /// Corner radii (directional).
  final BorderRadiusDirectional? borderRadius;

  /// Named radius step (set by `roundedSm`/`Md`/`Lg`/`Xl`); resolved against the
  /// theme into [borderRadius] by `FwStyled` at build (module 15). Mutually
  /// exclusive with a raw [borderRadius] in the same node (asserts).
  final FwRadiusStep? radiusStep;

  /// Drop shadows (token scale).
  final List<BoxShadow>? boxShadow;

  /// Named shadow step (set by `shadowSm`/`Md`/…/`shadowNone`); resolved against
  /// the theme into [boxShadow] by `FwStyled` at build (module 15). Mutually
  /// exclusive with a raw [boxShadow] in the same node (asserts).
  final FwShadowStep? shadowStep;

  /// Focus-ring spec (set by `ring`); rendered as composed box-shadows alongside
  /// [boxShadow] so a ring and a drop shadow coexist. Module 15.
  final FwRing? ringSpec;

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

  /// Text shadows for descendant text (Tailwind `text-shadow-*`); set by
  /// `textShadow` (module 17).
  final List<Shadow>? textShadows;

  /// Default font family as a literal name (set by `font(String)`).
  final String? fontFamily;

  /// Named font role (set by `fontSans`/`fontSerif`/`fontMono`); resolved against
  /// the theme's [FwTypographyTheme] into [fontFamily] by `FwStyled` at build, so
  /// the utilities track the active theme's families. Mutually exclusive with a
  /// literal [fontFamily] in the same node (asserts).
  final FwFontStep? fontFamilyStep;

  /// Default font style (italic/normal; set by `italic`/`notItalic`).
  final FontStyle? fontStyle;

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

  /// Per-axis horizontal scale (set by `scaleX`); composes with [scaleFactor].
  final double? scaleXFactor;

  /// Per-axis vertical scale (set by `scaleY`); composes with [scaleFactor].
  final double? scaleYFactor;

  /// Horizontal skew angle in radians (set by `skewX`, which takes degrees).
  final double? skewXAngle;

  /// Vertical skew angle in radians (set by `skewY`, which takes degrees).
  final double? skewYAngle;

  /// Transform origin / anchor (set by `transformOrigin`; defaults to center).
  final AlignmentGeometry? transformAlignment;

  /// Rotation in radians (set by the `rotate` setter, which takes degrees).
  final double? rotation;

  /// 3D rotation about the X axis in radians (set by `rotateX`, degrees); module 17.
  final double? rotateXAngle;

  /// 3D rotation about the Y axis in radians (set by `rotateY`, degrees); module 17.
  final double? rotateYAngle;

  /// Perspective depth in logical px for 3D transforms (set by `perspective`;
  /// smaller = stronger). Module 17.
  final double? perspectiveDepth;

  /// Translation offset in logical px (set by `translate`/`translateX/Y`).
  final Offset? translation;

  /// Composed CSS-filter colour matrix (4×5, 20 values), set by the filter
  /// setters (`grayscale`/`brightness`/`contrast`/`saturate`/`invert`/`sepia`/
  /// `hueRotate`). Filters **compose** within a chain (matrices multiply); across
  /// layers it last-wins like every other field.
  final List<double>? colorMatrix;

  /// Mix-blend-mode: composites the box against the backdrop (set by the
  /// `blendMode` setter; Tailwind `mix-blend-*`). Named `mixBlendMode` so the
  /// Tailwind-natural `blendMode` setter doesn't collide with the field (like
  /// `groupOpacity` vs `opacity`). Module 17.
  final BlendMode? mixBlendMode;

  /// Object-fit for the child content (set by the `fit` setter; named `boxFit`
  /// so the Tailwind-natural `fit` setter doesn't collide with the field).
  final BoxFit? boxFit;

  /// Alignment of the fitted child within its box (Tailwind `object-{position}`;
  /// set by the optional `alignment` of the `fit` setter). Defaults to center at
  /// resolve time. Directional (RTL-aware) when an `AlignmentDirectional`.
  final AlignmentGeometry? fitAlignment;

  /// Mouse cursor over the box (set by `cursor`; Tailwind `cursor-*`). Named
  /// `mouseCursor` so the `cursor` setter doesn't collide with the field.
  final MouseCursor? mouseCursor;

  /// Whether the box ignores pointer events (set by `pointerEventsNone`;
  /// Tailwind `pointer-events-none`).
  final bool? ignorePointer;

  /// Visibility (set by `invisible`/`visible`; Tailwind `invisible`/`visible`).
  /// `false` hides the box but keeps its layout space. Named `isVisible` so the
  /// `visible` setter doesn't collide with the field.
  final bool? isVisible;

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
    DecorationImage? backgroundImage,
    FwBorderSpec? borderSpec,
    FwBorderStyle? borderStyle,
    BorderRadiusDirectional? borderRadius,
    FwRadiusStep? radiusStep,
    List<BoxShadow>? boxShadow,
    FwShadowStep? shadowStep,
    FwRing? ringSpec,
    Color? foreground,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? lineHeight,
    TextAlign? textAlign,
    TextDecoration? textDecoration,
    List<Shadow>? textShadows,
    String? fontFamily,
    FwFontStep? fontFamilyStep,
    FontStyle? fontStyle,
    int? maxLineCount,
    TextOverflow? textOverflow,
    bool? softWrap,
    double? groupOpacity,
    double? contentBlur,
    double? backdropBlurSigma,
    double? scaleFactor,
    double? scaleXFactor,
    double? scaleYFactor,
    double? skewXAngle,
    double? skewYAngle,
    AlignmentGeometry? transformAlignment,
    double? rotation,
    double? rotateXAngle,
    double? rotateYAngle,
    double? perspectiveDepth,
    Offset? translation,
    List<double>? colorMatrix,
    BlendMode? mixBlendMode,
    BoxFit? boxFit,
    AlignmentGeometry? fitAlignment,
    MouseCursor? mouseCursor,
    bool? ignorePointer,
    bool? isVisible,
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
      backgroundImage: backgroundImage ?? this.backgroundImage,
      borderSpec: borderSpec ?? this.borderSpec,
      borderStyle: borderStyle ?? this.borderStyle,
      borderRadius: borderRadius ?? this.borderRadius,
      radiusStep: radiusStep ?? this.radiusStep,
      boxShadow: boxShadow ?? this.boxShadow,
      shadowStep: shadowStep ?? this.shadowStep,
      ringSpec: ringSpec ?? this.ringSpec,
      foreground: foreground ?? this.foreground,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      textAlign: textAlign ?? this.textAlign,
      textDecoration: textDecoration ?? this.textDecoration,
      textShadows: textShadows ?? this.textShadows,
      fontFamily: fontFamily ?? this.fontFamily,
      fontFamilyStep: fontFamilyStep ?? this.fontFamilyStep,
      fontStyle: fontStyle ?? this.fontStyle,
      maxLineCount: maxLineCount ?? this.maxLineCount,
      textOverflow: textOverflow ?? this.textOverflow,
      softWrap: softWrap ?? this.softWrap,
      groupOpacity: groupOpacity ?? this.groupOpacity,
      contentBlur: contentBlur ?? this.contentBlur,
      backdropBlurSigma: backdropBlurSigma ?? this.backdropBlurSigma,
      scaleFactor: scaleFactor ?? this.scaleFactor,
      scaleXFactor: scaleXFactor ?? this.scaleXFactor,
      scaleYFactor: scaleYFactor ?? this.scaleYFactor,
      skewXAngle: skewXAngle ?? this.skewXAngle,
      skewYAngle: skewYAngle ?? this.skewYAngle,
      transformAlignment: transformAlignment ?? this.transformAlignment,
      rotation: rotation ?? this.rotation,
      rotateXAngle: rotateXAngle ?? this.rotateXAngle,
      rotateYAngle: rotateYAngle ?? this.rotateYAngle,
      perspectiveDepth: perspectiveDepth ?? this.perspectiveDepth,
      translation: translation ?? this.translation,
      colorMatrix: colorMatrix ?? this.colorMatrix,
      mixBlendMode: mixBlendMode ?? this.mixBlendMode,
      boxFit: boxFit ?? this.boxFit,
      fitAlignment: fitAlignment ?? this.fitAlignment,
      mouseCursor: mouseCursor ?? this.mouseCursor,
      ignorePointer: ignorePointer ?? this.ignorePointer,
      isVisible: isVisible ?? this.isVisible,
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
      backgroundImage == other.backgroundImage &&
      borderSpec == other.borderSpec &&
      borderStyle == other.borderStyle &&
      borderRadius == other.borderRadius &&
      radiusStep == other.radiusStep &&
      listEquals(boxShadow, other.boxShadow) &&
      shadowStep == other.shadowStep &&
      ringSpec == other.ringSpec &&
      foreground == other.foreground &&
      fontSize == other.fontSize &&
      fontWeight == other.fontWeight &&
      letterSpacing == other.letterSpacing &&
      lineHeight == other.lineHeight &&
      textAlign == other.textAlign &&
      textDecoration == other.textDecoration &&
      listEquals(textShadows, other.textShadows) &&
      fontFamily == other.fontFamily &&
      fontFamilyStep == other.fontFamilyStep &&
      fontStyle == other.fontStyle &&
      maxLineCount == other.maxLineCount &&
      textOverflow == other.textOverflow &&
      softWrap == other.softWrap &&
      groupOpacity == other.groupOpacity &&
      contentBlur == other.contentBlur &&
      backdropBlurSigma == other.backdropBlurSigma &&
      scaleFactor == other.scaleFactor &&
      scaleXFactor == other.scaleXFactor &&
      scaleYFactor == other.scaleYFactor &&
      skewXAngle == other.skewXAngle &&
      skewYAngle == other.skewYAngle &&
      transformAlignment == other.transformAlignment &&
      rotation == other.rotation &&
      rotateXAngle == other.rotateXAngle &&
      rotateYAngle == other.rotateYAngle &&
      perspectiveDepth == other.perspectiveDepth &&
      translation == other.translation &&
      listEquals(colorMatrix, other.colorMatrix) &&
      mixBlendMode == other.mixBlendMode &&
      boxFit == other.boxFit &&
      fitAlignment == other.fitAlignment &&
      mouseCursor == other.mouseCursor &&
      ignorePointer == other.ignorePointer &&
      isVisible == other.isVisible &&
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
    backgroundImage,
    borderSpec,
    borderStyle,
    borderRadius,
    radiusStep,
    boxShadow == null ? null : Object.hashAll(boxShadow!),
    shadowStep,
    ringSpec,
    foreground,
    fontSize,
    fontWeight,
    letterSpacing,
    lineHeight,
    textAlign,
    textDecoration,
    textShadows == null ? null : Object.hashAll(textShadows!),
    fontFamily,
    fontFamilyStep,
    fontStyle,
    maxLineCount,
    textOverflow,
    softWrap,
    groupOpacity,
    contentBlur,
    backdropBlurSigma,
    scaleFactor,
    scaleXFactor,
    scaleYFactor,
    skewXAngle,
    skewYAngle,
    transformAlignment,
    rotation,
    rotateXAngle,
    rotateYAngle,
    perspectiveDepth,
    translation,
    colorMatrix == null ? null : Object.hashAll(colorMatrix!),
    mixBlendMode,
    boxFit,
    fitAlignment,
    mouseCursor,
    ignorePointer,
    isVisible,
    clipBehavior,
    Object.hashAll(layers),
  ]);
}

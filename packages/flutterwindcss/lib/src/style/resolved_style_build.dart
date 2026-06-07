import 'dart:ui' as ui show ImageFilter;

import 'package:flutter/widgets.dart';

import 'fw_border_spec.dart';
import 'fw_dashed_border.dart';
import 'resolved_style.dart';

/// Builds the fixed outer→inner primitive chain for a [ResolvedStyle] (spec
/// §6.4). Kept as an extension so [ResolvedStyle] stays a pure value type.
extension ResolvedStyleBuild on ResolvedStyle {
  /// Wraps [child] in the documented primitive chain. Each wrapper is emitted
  /// only when its input is set, so a static empty style returns [child]
  /// unwrapped. The order is asserted by tests because later modules depend on
  /// it; do not reorder without updating `render_chain_test.dart`.
  ///
  /// Outer→inner: `margin → cursor → ignore-pointer → visibility → constraints →
  /// aspect → fractional → transform → color-filter → content-blur → opacity →
  /// shadow(unclipped) → surface(backdrop?+decoration) → content-clip → padding →
  /// object-fit → text/icon defaults → child`.
  Widget build(Widget child) {
    // Flutter paints a rounded border only when every edge shares one color and
    // width (a uniform `Border`); a per-side `BorderDirectional` + `borderRadius`
    // crashes deep in the painter. Surface that as a clear, early assert instead
    // (spec §6.4 Finding #5). The content clip below may still round freely — the
    // limitation is only the decoration's stroke, not the clip.
    assert(
      !(border is BorderDirectional && borderRadius != null),
      'flutterwindcss: a border radius cannot be combined with a per-side '
      '(directional) border — Flutter rounds a border only when every edge shares '
      'one color and width. Use a uniform border when rounding, or drop the radius.',
    );

    // A non-solid border style with no width would silently paint nothing — guard
    // it (module 15). `border == null` here means no edge has width > 0.
    assert(
      !(borderStyle != null && borderStyle != FwBorderStyle.solid && border == null),
      'flutterwindcss: borderDashed/borderDotted needs a border width — set it with '
      'border(w, {color}). A non-solid style with no width paints nothing.',
    );

    Widget current = child;

    // Inner: default text/icon styling for descendants.
    if (foreground != null ||
        fontSize != null ||
        fontWeight != null ||
        letterSpacing != null ||
        lineHeight != null ||
        textAlign != null ||
        textDecoration != null ||
        fontFamily != null ||
        fontStyle != null ||
        maxLines != null ||
        textOverflow != null ||
        softWrap != null) {
      current = DefaultTextStyle.merge(
        style: TextStyle(
          color: foreground,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          height: lineHeight,
          decoration: textDecoration,
          fontFamily: fontFamily,
          fontStyle: fontStyle,
        ),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: textOverflow,
        softWrap: softWrap,
        child: IconTheme.merge(
          data: IconThemeData(color: foreground, size: fontSize),
          child: current,
        ),
      );
    }

    // Object-fit: scale the content to fit its content box (inside padding).
    if (fit != null) {
      current = FittedBox(fit: fit!, child: current);
    }

    // Inner padding.
    if (padding != null) {
      current = Padding(padding: padding!, child: current);
    }

    // Content clip: clip to the box shape. With a corner radius, reuse it
    // deflated by the border width so clipped content never bleeds across the
    // stroke (spec §6.4 Finding #3); with no radius, clip to the rectangle
    // (`BorderRadiusDirectional.zero`) — `.clip()` alone must still clip, not
    // silently no-op.
    if (clipBehavior != null && clipBehavior != Clip.none) {
      final clipRadius =
          borderRadius == null
              ? BorderRadiusDirectional.zero
              : (border == null ? borderRadius! : _deflateRadius(borderRadius!, border!));
      current = ClipRRect(clipBehavior: clipBehavior!, borderRadius: clipRadius, child: current);
    }

    // A dashed/dotted border is NOT a decoration stroke (Flutter's BorderSide has
    // no dashed style); it is painted on top by FwDashedBorderPainter (module 15).
    // So the decoration omits the border in that case, and the painter draws it.
    final dashed = borderStyle != null && borderStyle != FwBorderStyle.solid && border != null;
    final BoxBorder? decoBorder = dashed ? null : border;

    // Surface: optional backdrop blur clipped to the box, then the decoration
    // composited on top so a semi-transparent fill frosts the backdrop.
    final hasDecoration = background != null || gradient != null || decoBorder != null;
    if (backdropBlur != null) {
      current = ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: backdropBlur!, sigmaY: backdropBlur!),
          child: hasDecoration ? _decorate(current, decoBorder) : current,
        ),
      );
    } else if (hasDecoration) {
      current = _decorate(current, decoBorder);
    }

    // Paint the dashed/dotted border over the surface. The directional radius
    // needs a text direction, which the render chain lacks — a Builder supplies
    // the ambient Directionality so the resolved radius is correct under RTL.
    if (dashed) {
      assert(
        border!.isUniform,
        'flutterwindcss: dashed/dotted borders must be uniform — set the width and '
        'colour with border(w, {color}), not a per-side borderS/E/T/B.',
      );
      final side = switch (border!) {
        Border(:final top) => top,
        BorderDirectional(:final top) => top,
        _ => const BorderSide(width: 0),
      };
      final inner = current;
      current = Builder(
        builder:
            (context) => CustomPaint(
              foregroundPainter: FwDashedBorderPainter(
                width: side.width,
                color: side.color,
                dotted: borderStyle == FwBorderStyle.dotted,
                borderRadius: borderRadius?.resolve(Directionality.of(context)),
              ),
              child: inner,
            ),
      );
    }

    // Unclipped shadow layer (outside any clip so backdrop-blur can't eat it).
    // The focus `ring` (module 15) expands to zero-blur spread shadows that
    // compose WITH any drop `shadow` — ring layers paint outermost (after the
    // drop shadows), following the same `borderRadius` as the box.
    final ringShadows = ringSpec?.toBoxShadows() ?? const <BoxShadow>[];
    final shadows = <BoxShadow>[...?boxShadow, ...ringShadows];
    if (shadows.isNotEmpty) {
      current = DecoratedBox(
        decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
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

    // Colour filter (CSS filter color functions: brightness/contrast/grayscale/
    // saturate/invert/sepia/hue-rotate), composed into one matrix. Outside the
    // content blur, like CSS `filter` applied to the rendered element.
    if (colorMatrix != null) {
      current = ColorFiltered(colorFilter: ColorFilter.matrix(colorMatrix!), child: current);
    }

    // Transform (paint-only; transforms the already-rendered result incl. the
    // shadow, matching CSS `transform`). Uniform `scale` composes (multiplies)
    // with per-axis `scaleX`/`scaleY`, like CSS `scale()` + `scaleX()`.
    final sx = (scale ?? 1) * (scaleX ?? 1);
    final sy = (scale ?? 1) * (scaleY ?? 1);
    final hasScale = scale != null || scaleX != null || scaleY != null;
    final hasSkew = skewX != null || skewY != null;
    if (translate != null || rotation != null || hasScale || hasSkew) {
      // Composed via stable constructors. Right-multiplying T·R·Skew·S applies
      // scale first, then skew, then rotation, then translation — matching CSS
      // `transform` semantics. `transformAlignment` is the origin (default
      // center).
      var m = Matrix4.identity();
      if (translate != null) {
        m = m.multiplied(Matrix4.translationValues(translate!.dx, translate!.dy, 0));
      }
      if (rotation != null) {
        m = m.multiplied(Matrix4.rotationZ(rotation!));
      }
      if (hasSkew) {
        m = m.multiplied(Matrix4.skew(skewX ?? 0, skewY ?? 0));
      }
      if (hasScale) {
        m = m.multiplied(Matrix4.diagonal3Values(sx, sy, 1));
      }
      current = Transform(
        transform: m,
        alignment: transformAlignment ?? Alignment.center,
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
    final hasConstraints =
        width != null ||
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

    // Visibility: hide but keep the layout footprint (CSS `visibility: hidden`).
    if (isVisible == false) {
      current = Visibility(
        visible: false,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: current,
      );
    }

    // Pointer-events: drop hit-testing for the whole box (CSS `pointer-events:none`).
    if (ignorePointer == true) {
      current = IgnorePointer(child: current);
    }

    // Cursor: the mouse cursor shown over the box (CSS `cursor`).
    if (mouseCursor != null) {
      current = MouseRegion(cursor: mouseCursor!, child: current);
    }

    // Outermost: margin.
    if (margin != null) {
      current = Padding(padding: margin!, child: current);
    }

    return current;
  }

  /// Deflates each corner of [r] by its two adjacent edge widths (CSS inner
  /// border-radius), clamped at 0 — so the content clip hugs the inside of the
  /// stroke (spec §6.4 Finding #3).
  BorderRadiusDirectional _deflateRadius(BorderRadiusDirectional r, BoxBorder border) {
    final w = _edgeWidths(border);
    Radius inset(Radius c, double dx, double dy) {
      final x = c.x - dx, y = c.y - dy;
      return Radius.elliptical(x < 0 ? 0 : x, y < 0 ? 0 : y);
    }

    return BorderRadiusDirectional.only(
      topStart: inset(r.topStart, w.start, w.top),
      topEnd: inset(r.topEnd, w.end, w.top),
      bottomStart: inset(r.bottomStart, w.start, w.bottom),
      bottomEnd: inset(r.bottomEnd, w.end, w.bottom),
    );
  }

  /// Reads the per-edge stroke widths off a resolved [BoxBorder], directionally.
  /// A uniform `Border` is symmetric, so mapping start←left / end←right is exact.
  EdgeInsetsDirectional _edgeWidths(BoxBorder border) {
    if (border is BorderDirectional) {
      return EdgeInsetsDirectional.only(
        start: border.start.width,
        end: border.end.width,
        top: border.top.width,
        bottom: border.bottom.width,
      );
    }
    if (border is Border) {
      return EdgeInsetsDirectional.only(
        start: border.left.width,
        end: border.right.width,
        top: border.top.width,
        bottom: border.bottom.width,
      );
    }
    return EdgeInsetsDirectional.zero;
  }

  Widget _decorate(Widget child, BoxBorder? decoBorder) => DecoratedBox(
    decoration: BoxDecoration(
      color: gradient == null ? background : null,
      gradient: gradient,
      border: decoBorder,
      borderRadius: borderRadius,
    ),
    child: child,
  );
}

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Paints a uniform **dashed** or **dotted** box border (module 15) — Flutter's
/// `BorderSide` has no dashed style, so a non-solid border (Tailwind
/// `border-dashed`/`border-dotted`) is drawn here instead of by the decoration's
/// stroke. The staple of "drop to upload" zones.
///
/// Strokes the (optionally rounded) outline, inset by half the [width] so the
/// stroke sits inside the box like a CSS border, then dashes the path via
/// `PathMetric`. [borderRadius] is pre-resolved against the text direction by the
/// render chain (the painter has no `BuildContext`).
class FwDashedBorderPainter extends CustomPainter {
  /// Creates a dashed/dotted border painter.
  const FwDashedBorderPainter({
    required this.width,
    required this.color,
    required this.dotted,
    this.borderRadius,
  });

  /// Stroke width in logical px.
  final double width;

  /// Stroke colour.
  final Color color;

  /// `true` = dotted (round caps, ~square spacing); `false` = dashed.
  final bool dotted;

  /// Resolved corner radii (null = a rectangle).
  final BorderRadius? borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (width <= 0) return;
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = dotted ? StrokeCap.round : StrokeCap.butt;

    final inset = width / 2;
    final rect = Rect.fromLTRB(inset, inset, size.width - inset, size.height - inset);
    if (rect.width <= 0 || rect.height <= 0) return;

    final Path outline;
    if (borderRadius != null) {
      Radius deflate(Radius r) =>
          Radius.elliptical(math.max(0, r.x - inset), math.max(0, r.y - inset));
      outline =
          Path()..addRRect(
            RRect.fromRectAndCorners(
              rect,
              topLeft: deflate(borderRadius!.topLeft),
              topRight: deflate(borderRadius!.topRight),
              bottomLeft: deflate(borderRadius!.bottomLeft),
              bottomRight: deflate(borderRadius!.bottomRight),
            ),
          );
    } else {
      outline = Path()..addRect(rect);
    }

    // Dash/dot pattern derived from the width so it scales sensibly.
    final on = dotted ? width : width * 3;
    final off = dotted ? width * 1.5 : width * 2;
    canvas.drawPath(_dash(outline, on, off), paint);
  }

  /// Returns a copy of [source] reduced to `on`-length segments separated by
  /// `off`-length gaps, walked along each contour via its [PathMetric].
  static Path _dash(Path source, double on, double off) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + on, metric.length);
        result.addPath(metric.extractPath(distance, end), Offset.zero);
        distance += on + off;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(FwDashedBorderPainter old) =>
      old.width != width ||
      old.color != color ||
      old.dotted != dotted ||
      old.borderRadius != borderRadius;
}

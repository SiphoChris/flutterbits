import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';

/// The line style of a box border (Tailwind `border-solid/dashed/dotted`,
/// module 15). [solid] is the default and renders via the decoration's stroke;
/// [dashed]/[dotted] are painted by `FwDashedBorderPainter` (Flutter's
/// `BorderSide` has no dashed style) and require a **uniform** border.
enum FwBorderStyle {
  /// Continuous stroke (the default).
  solid,

  /// Evenly-spaced dashes.
  dashed,

  /// Evenly-spaced round dots.
  dotted,
}

/// An accumulating, directional border description (spec §6.1). Each edge is an
/// optional [BorderSide]; `null` means "no border declared on that edge". The
/// `.tw` border setters merge per-edge (last-wins per edge), mirroring how
/// padding accumulates, and [resolve] converts to a concrete [BoxBorder] for the
/// render chain.
///
/// Corrects the engine spec §6.1 working name `BorderSideSpec` — this type
/// describes the whole four-edge border, not a single side. An edge paints only
/// when its width is > 0, so a color-only chain stays invisible (matching
/// Tailwind, where `border-{color}` alone shows nothing without a width).
@immutable
class FwBorderSpec {
  /// Creates a border spec. Any omitted edge is unset (`null`).
  const FwBorderSpec({this.start, this.end, this.top, this.bottom});

  /// Start edge (RTL-aware).
  final BorderSide? start;

  /// End edge (RTL-aware).
  final BorderSide? end;

  /// Top edge.
  final BorderSide? top;

  /// Bottom edge.
  final BorderSide? bottom;

  /// Returns a copy with the given edges replaced (unset args keep the current
  /// edge) — the per-edge merge the setters use for last-wins-per-edge.
  FwBorderSpec merge({BorderSide? start, BorderSide? end, BorderSide? top, BorderSide? bottom}) =>
      FwBorderSpec(
        start: start ?? this.start,
        end: end ?? this.end,
        top: top ?? this.top,
        bottom: bottom ?? this.bottom,
      );

  bool get _paints =>
      (start?.width ?? 0) > 0 ||
      (end?.width ?? 0) > 0 ||
      (top?.width ?? 0) > 0 ||
      (bottom?.width ?? 0) > 0;

  /// Converts to a concrete [BoxBorder], or `null` when no edge paints. A uniform
  /// border (all four edges equal) becomes a direction-agnostic [Border]; any
  /// per-edge difference becomes a [BorderDirectional] so `start`/`end` mirror
  /// under RTL (spec §6.4 Finding #5).
  BoxBorder? resolve() {
    if (!_paints) return null;
    final s = start ?? BorderSide.none;
    final e = end ?? BorderSide.none;
    final t = top ?? BorderSide.none;
    final b = bottom ?? BorderSide.none;
    if (s == e && e == t && t == b) return Border.fromBorderSide(s);
    return BorderDirectional(start: s, end: e, top: t, bottom: b);
  }

  @override
  bool operator ==(Object other) =>
      other is FwBorderSpec &&
      start == other.start &&
      end == other.end &&
      top == other.top &&
      bottom == other.bottom;

  @override
  int get hashCode => Object.hash(start, end, top, bottom);
}

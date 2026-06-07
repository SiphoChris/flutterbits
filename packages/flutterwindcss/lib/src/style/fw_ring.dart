import 'package:flutter/painting.dart';

/// A Tailwind focus-`ring`: a zero-blur, spread box-shadow drawn in [color]
/// (module 15). With [offset] > 0, a second shadow in [offsetColor] sits between
/// the box and the ring (Tailwind `ring-offset-*`), so the ring appears detached.
///
/// Engine-internal value type (set via the `ring()` `.tw` setter, not constructed
/// by consumers); carried on `FwStyle`/`ResolvedStyle` and expanded to
/// [BoxShadow]s at render time, composed with any drop `shadow` so both show.
class FwRing {
  /// Creates a ring spec. Prefer the `ring()` `.tw` setter.
  const FwRing({
    required this.width,
    required this.color,
    this.offset = 0,
    this.offsetColor = const Color(0xFFFFFFFF),
  });

  /// Ring thickness in logical px (the shadow's spread).
  final double width;

  /// Ring colour (pass a semantic token, e.g. `context.fw.colors.ring`).
  final Color color;

  /// Gap between the box and the ring, in logical px (Tailwind `ring-offset-*`).
  final double offset;

  /// Colour of the offset gap (Tailwind's `--tw-ring-offset-color`, default white
  /// — set it to the surface colour behind the element).
  final Color offsetColor;

  /// Expands to the box-shadow layers, outer-last. The offset gap (if any) is the
  /// inner shadow; the ring is the outer one (its spread includes the offset). A
  /// zero (or negative) [width] is a true no-op — no shadows, no dead wrapper, and
  /// no lone offset band (an offset with no ring is meaningless).
  List<BoxShadow> toBoxShadows() {
    if (width <= 0) return const <BoxShadow>[];
    return <BoxShadow>[
      if (offset > 0) BoxShadow(color: offsetColor, spreadRadius: offset),
      BoxShadow(color: color, spreadRadius: offset + width),
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is FwRing &&
      other.width == width &&
      other.color == color &&
      other.offset == offset &&
      other.offsetColor == offsetColor;

  @override
  int get hashCode => Object.hash(width, color, offset, offsetColor);
}

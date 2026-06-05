import 'dart:ui' show Color, Offset;

import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:flutter/painting.dart' show BoxShadow;

/// The Tailwind v4 box-shadow scale as Flutter [BoxShadow] lists (spec §4.4).
@immutable
class FwShadows {
  /// Creates a shadow scale.
  const FwShadows({
    required this.xs2,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xl2,
  });

  /// `shadow-2xs`.
  final List<BoxShadow> xs2;

  /// `shadow-xs`.
  final List<BoxShadow> xs;

  /// `shadow-sm`.
  final List<BoxShadow> sm;

  /// `shadow-md`.
  final List<BoxShadow> md;

  /// `shadow-lg`.
  final List<BoxShadow> lg;

  /// `shadow-xl`.
  final List<BoxShadow> xl;

  /// `shadow-2xl`.
  final List<BoxShadow> xl2;

  static const Color _k = Color(0x00000000);

  /// Tailwind v4 default shadow values (black at documented alphas).
  static const FwShadows defaults = FwShadows(
    xs2: <BoxShadow>[BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1))],
    xs: <BoxShadow>[
      BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2),
    ],
    sm: <BoxShadow>[
      BoxShadow(color: Color(0x1A000000), offset: Offset(0, 1), blurRadius: 3),
      BoxShadow(
        color: Color(0x1A000000),
        offset: Offset(0, 1),
        blurRadius: 2,
        spreadRadius: -1,
      ),
    ],
    md: <BoxShadow>[
      BoxShadow(
        color: Color(0x1A000000),
        offset: Offset(0, 4),
        blurRadius: 6,
        spreadRadius: -1,
      ),
      BoxShadow(
        color: Color(0x1A000000),
        offset: Offset(0, 2),
        blurRadius: 4,
        spreadRadius: -2,
      ),
    ],
    lg: <BoxShadow>[
      BoxShadow(
        color: Color(0x1A000000),
        offset: Offset(0, 10),
        blurRadius: 15,
        spreadRadius: -3,
      ),
      BoxShadow(
        color: Color(0x1A000000),
        offset: Offset(0, 4),
        blurRadius: 6,
        spreadRadius: -4,
      ),
    ],
    xl: <BoxShadow>[
      BoxShadow(
        color: Color(0x1A000000),
        offset: Offset(0, 20),
        blurRadius: 25,
        spreadRadius: -5,
      ),
      BoxShadow(
        color: Color(0x1A000000),
        offset: Offset(0, 8),
        blurRadius: 10,
        spreadRadius: -6,
      ),
    ],
    xl2: <BoxShadow>[
      BoxShadow(
        color: Color(0x40000000),
        offset: Offset(0, 25),
        blurRadius: 50,
        spreadRadius: -12,
      ),
    ],
  );

  /// An all-empty scale (used as a lerp origin / `shadow-none`).
  static const FwShadows none = FwShadows(
    xs2: <BoxShadow>[],
    xs: <BoxShadow>[],
    sm: <BoxShadow>[],
    md: <BoxShadow>[],
    lg: <BoxShadow>[],
    xl: <BoxShadow>[],
    xl2: <BoxShadow>[],
  );

  static List<BoxShadow> _lerpList(List<BoxShadow> a, List<BoxShadow> b, double t) {
    final n = a.length > b.length ? a.length : b.length;
    return List<BoxShadow>.generate(n, (i) {
      final x = i < a.length ? a[i] : b[i].copyWith(color: _k);
      final y = i < b.length ? b[i] : a[i].copyWith(color: _k);
      return BoxShadow.lerp(x, y, t)!;
    });
  }

  /// Layer-wise interpolation of every step.
  static FwShadows lerp(FwShadows a, FwShadows b, double t) => FwShadows(
        xs2: _lerpList(a.xs2, b.xs2, t),
        xs: _lerpList(a.xs, b.xs, t),
        sm: _lerpList(a.sm, b.sm, t),
        md: _lerpList(a.md, b.md, t),
        lg: _lerpList(a.lg, b.lg, t),
        xl: _lerpList(a.xl, b.xl, t),
        xl2: _lerpList(a.xl2, b.xl2, t),
      );

  @override
  bool operator ==(Object other) =>
      other is FwShadows &&
      listEquals(other.xs2, xs2) &&
      listEquals(other.xs, xs) &&
      listEquals(other.sm, sm) &&
      listEquals(other.md, md) &&
      listEquals(other.lg, lg) &&
      listEquals(other.xl, xl) &&
      listEquals(other.xl2, xl2);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(xs2),
        Object.hashAll(xs),
        Object.hashAll(sm),
        Object.hashAll(md),
        Object.hashAll(lg),
        Object.hashAll(xl),
        Object.hashAll(xl2),
      );
}

import 'package:flutter/foundation.dart' show immutable;

/// Border-radius tokens. The `sm/md/lg/xl` set is derived from one shadcn
/// `--radius` base (spec §4.3): `sm ×0.6, md ×0.8, lg ×1.0, xl ×1.4`. The
/// Tailwind v4 named scale is also exposed for utility use.
@immutable
class FwRadii {
  /// Creates a radius set from explicit values. Prefer [FwRadii.fromBase].
  const FwRadii({
    required this.base,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  /// Derives the shadcn-style set from a single [base] radius (logical px).
  factory FwRadii.fromBase(double base) =>
      FwRadii(base: base, sm: base * 0.6, md: base * 0.8, lg: base * 1.0, xl: base * 1.4);

  /// The shadcn `--radius` this set was derived from.
  final double base;

  /// `base ×0.6`.
  final double sm;

  /// `base ×0.8`.
  final double md;

  /// `base ×1.0`.
  final double lg;

  /// `base ×1.4`.
  final double xl;

  /// No rounding.
  double get none => 0;

  /// Pill/fully-rounded sentinel (`9999`).
  double get full => 9999;

  /// Linearly interpolates the derived set via the [base].
  static FwRadii lerp(FwRadii a, FwRadii b, double t) =>
      FwRadii.fromBase(a.base + (b.base - a.base) * t);

  @override
  bool operator ==(Object other) =>
      other is FwRadii &&
      other.base == base &&
      other.sm == sm &&
      other.md == md &&
      other.lg == lg &&
      other.xl == xl;

  @override
  int get hashCode => Object.hash(base, sm, md, lg, xl);
}

/// The Tailwind v4 named border-radius scale (logical px), independent of theme.
abstract final class FwRadiusScale {
  /// `0.125rem` → 2px.
  static const double xs = 2;

  /// `0.25rem` → 4px.
  static const double sm = 4;

  /// `0.375rem` → 6px.
  static const double md = 6;

  /// `0.5rem` → 8px.
  static const double lg = 8;

  /// `0.75rem` → 12px.
  static const double xl = 12;

  /// `1rem` → 16px.
  static const double xl2 = 16;

  /// `1.5rem` → 24px.
  static const double xl3 = 24;

  /// `2rem` → 32px.
  static const double xl4 = 32;
}

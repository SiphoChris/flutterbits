import 'package:flutter/foundation.dart' show immutable;

/// Border-radius tokens. The `sm/md/lg/xl` set is derived from one shadcn
/// `--radius` base (spec §4.3): `sm ×0.6, md ×0.8, lg ×1.0, xl ×1.4`. The
/// Tailwind v4 named scale is also exposed for utility use.
@immutable
class FwRadii {
  /// Creates a radius set from explicit per-step values.
  ///
  /// Use this when the steps are **not** the stock ×-factor ratios — e.g. a
  /// generated theme using shadcn's *additive* derivation (`sm = base−4`,
  /// `md = base−2`, `lg = base`, `xl = base+4`), which coincides with
  /// [FwRadii.fromBase] only at the 10px default and diverges otherwise. For
  /// stock ×-factor themes, prefer [FwRadii.fromBase].
  const FwRadii({
    required this.base,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  /// Derives the shadcn-style set from a single [base] radius (logical px).
  ///
  /// `const` so themes can compose it directly (e.g. `FwRadii.fromBase(10)`),
  /// keeping the derived values in lockstep with [base] instead of restating
  /// them as literals that could drift.
  const FwRadii.fromBase(this.base)
    : sm = base * 0.6,
      md = base * 0.8,
      lg = base * 1.0,
      xl = base * 1.4;

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

  /// Linearly interpolates **every field** independently (corrected — audit: the
  /// old `fromBase(lerp(base))` re-derived `sm…xl` and so was inconsistent with
  /// `==`/`hashCode` for a directly-constructed set whose steps don't follow the
  /// base ratios). For stock `fromBase` themes the result is identical, since each
  /// step is a linear function of `base`.
  static FwRadii lerp(FwRadii a, FwRadii b, double t) => FwRadii(
    base: a.base + (b.base - a.base) * t,
    sm: a.sm + (b.sm - a.sm) * t,
    md: a.md + (b.md - a.md) * t,
    lg: a.lg + (b.lg - a.lg) * t,
    xl: a.xl + (b.xl - a.xl) * t,
  );

  // Direct-constructor instances may set sm/md/lg/xl independently of base,
  // so compare all five fields rather than base alone.
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

/// Typography tokens mirroring the Tailwind v4 scales (spec §4.5). At a 16px
/// root, `1rem = 16` logical px. Line-heights are the paired `--text-*-
/// -line-height` ratios.
library;

/// Tailwind v4 font-size steps with paired line-height ratios.
enum FwFontSize {
  /// `0.75rem` (12 px).
  xs(12, 1 / 0.75),

  /// `0.875rem` (14 px).
  sm(14, 1.25 / 0.875),

  /// `1rem` (16 px).
  base(16, 1.5 / 1),

  /// `1.125rem` (18 px).
  lg(18, 1.75 / 1.125),

  /// `1.25rem` (20 px).
  xl(20, 1.75 / 1.25),

  /// `1.5rem` (24 px).
  xl2(24, 2 / 1.5),

  /// `1.875rem` (30 px).
  xl3(30, 2.25 / 1.875),

  /// `2.25rem` (36 px).
  xl4(36, 2.5 / 2.25),

  /// `3rem` (48 px).
  xl5(48, 1),

  /// `3.75rem` (60 px).
  xl6(60, 1),

  /// `4.5rem` (72 px).
  xl7(72, 1),

  /// `6rem` (96 px).
  xl8(96, 1),

  /// `8rem` (128 px).
  xl9(128, 1);

  const FwFontSize(this.px, this.lineHeight);

  /// Font size in logical pixels.
  final double px;

  /// Paired line-height as a multiple of [px].
  final double lineHeight;
}

/// Tailwind v4 font weights.
abstract final class FwFontWeight {
  /// 100.
  static const int thin = 100;

  /// 200.
  static const int extralight = 200;

  /// 300.
  static const int light = 300;

  /// 400.
  static const int normal = 400;

  /// 500.
  static const int medium = 500;

  /// 600.
  static const int semibold = 600;

  /// 700.
  static const int bold = 700;

  /// 800.
  static const int extrabold = 800;

  /// 900.
  static const int black = 900;
}

/// Tailwind v4 letter-spacing (`em`).
abstract final class FwTracking {
  /// -0.05em.
  static const double tighter = -0.05;

  /// -0.025em.
  static const double tight = -0.025;

  /// 0.
  static const double normal = 0;

  /// 0.025em.
  static const double wide = 0.025;

  /// 0.05em.
  static const double wider = 0.05;

  /// 0.1em.
  static const double widest = 0.1;
}

/// Tailwind v4 line-height multipliers.
abstract final class FwLeading {
  /// 1.25.
  static const double tight = 1.25;

  /// 1.375.
  static const double snug = 1.375;

  /// 1.5.
  static const double normal = 1.5;

  /// 1.625.
  static const double relaxed = 1.625;

  /// 2.0.
  static const double loose = 2.0;
}

/// Font-family *names* only — the engine never bundles fonts (spec §4.5).
abstract final class FwFontFamily {
  /// Default UI sans family name. Flutter resolves this generic name to the
  /// platform UI font; the host overrides it in FwTheme for a custom face.
  static const String sans = 'sans-serif';

  /// Serif family name.
  static const String serif = 'serif';

  /// Monospace family name.
  static const String mono = 'monospace';
}

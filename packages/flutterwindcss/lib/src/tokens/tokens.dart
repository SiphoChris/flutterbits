import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show immutable;

import 'colors.dart';
import 'palette.dart';
import 'radii.dart';
import 'shadows.dart';
import 'typography.dart';

/// The per-theme resolved token bundle a component reads via `context.fw`
/// (spec §4.7). Theme-independent scales (palette, named radii, type, blur,
/// z, border-width) are exposed by their own classes, not here.
@immutable
class FwTokens {
  /// Creates a token bundle.
  const FwTokens({
    required this.colors,
    required this.radii,
    required this.shadows,
    required this.typography,
    required this.radiusBase,
  });

  /// Semantic colors for this theme.
  final FwColors colors;

  /// Radius set derived from [radiusBase].
  final FwRadii radii;

  /// Box-shadow scale.
  final FwShadows shadows;

  /// Per-theme typography: the `sans`/`serif`/`mono` family names and `tracking`
  /// (em base letter-spacing). The static type *scales* live on their own types.
  final FwTypographyTheme typography;

  /// The shadcn `--radius` this theme was built from (logical px).
  final double radiusBase;

  /// The stock shadcn-neutral **light** theme. Composed from baked `const`
  /// palette literals — no runtime color computation (spec §4.7 / R4).
  static const FwTokens light = FwTokens(
    // shadcn default --radius is 0.625rem = 10 logical px (derived set:
    // sm 6 / md 8 / lg 10 / xl 14).
    radiusBase: 10,
    radii: FwRadii.fromBase(10),
    shadows: FwShadows.defaults,
    typography: FwTypographyTheme.standard,
    colors: FwColors(
      background: FwPalette.white,
      foreground: Color(0xFF0A0A0A), // neutral-950
      card: FwPalette.white,
      cardForeground: Color(0xFF0A0A0A), // neutral-950
      popover: FwPalette.white,
      popoverForeground: Color(0xFF0A0A0A), // neutral-950
      primary: Color(0xFF171717), // neutral-900
      primaryForeground: Color(0xFFFAFAFA), // neutral-50
      secondary: Color(0xFFF5F5F5), // neutral-100
      secondaryForeground: Color(0xFF171717), // neutral-900
      muted: Color(0xFFF5F5F5), // neutral-100
      mutedForeground: Color(0xFF737373), // neutral-500
      accent: Color(0xFFF5F5F5), // neutral-100
      accentForeground: Color(0xFF171717), // neutral-900
      destructive: Color(0xFFE7000B), // red-600
      destructiveForeground: FwPalette.white,
      border: Color(0xFFE5E5E5), // neutral-200
      input: Color(0xFFE5E5E5), // neutral-200
      ring: Color(0xFFA1A1A1), // neutral-400
      // chart-* and sidebar-* are the stock shadcn defaults, converted from
      // their OKLCH source via the project's clip pipeline (the grayscale
      // sidebar values reproduce the neutral palette exactly).
      chart1: Color(0xFFF54900),
      chart2: Color(0xFF009689),
      chart3: Color(0xFF104E64),
      chart4: Color(0xFFFFB900),
      chart5: Color(0xFFFE9A00),
      sidebar: FwPalette.white,
      sidebarForeground: Color(0xFF0A0A0A), // neutral-950
      sidebarPrimary: Color(0xFF171717), // neutral-900
      sidebarPrimaryForeground: Color(0xFFFAFAFA), // neutral-50
      sidebarAccent: Color(0xFFF5F5F5), // neutral-100
      sidebarAccentForeground: Color(0xFF171717), // neutral-900
      sidebarBorder: Color(0xFFE5E5E5), // neutral-200
      sidebarRing: Color(0xFFA1A1A1), // neutral-400
    ),
  );

  /// The stock shadcn-neutral **dark** theme.
  static const FwTokens dark = FwTokens(
    // shadcn default --radius is 0.625rem = 10 logical px (same as light).
    radiusBase: 10,
    radii: FwRadii.fromBase(10),
    shadows: FwShadows.defaults,
    typography: FwTypographyTheme.standard,
    colors: FwColors(
      background: Color(0xFF0A0A0A), // neutral-950
      foreground: Color(0xFFFAFAFA), // neutral-50
      card: Color(0xFF171717), // neutral-900
      cardForeground: Color(0xFFFAFAFA), // neutral-50
      popover: Color(0xFF171717), // neutral-900
      popoverForeground: Color(0xFFFAFAFA), // neutral-50
      primary: Color(0xFFFAFAFA), // neutral-50
      primaryForeground: Color(0xFF171717), // neutral-900
      secondary: Color(0xFF262626), // neutral-800
      secondaryForeground: Color(0xFFFAFAFA), // neutral-50
      muted: Color(0xFF262626), // neutral-800
      mutedForeground: Color(0xFFA1A1A1), // neutral-400
      accent: Color(0xFF262626), // neutral-800
      accentForeground: Color(0xFFFAFAFA), // neutral-50
      destructive: Color(0xFFFF6467), // red-400
      destructiveForeground: Color(0xFF0A0A0A), // neutral-950
      border: Color(0x1AFFFFFF), // white/10%
      input: Color(0x26FFFFFF), // white/15%
      ring: Color(0xFF737373), // neutral-500
      // Stock shadcn dark chart/sidebar defaults (OKLCH → clip).
      chart1: Color(0xFF1447E6),
      chart2: Color(0xFF00BC7D),
      chart3: Color(0xFFFE9A00),
      chart4: Color(0xFFAD46FF),
      chart5: Color(0xFFFF2056),
      sidebar: Color(0xFF171717), // neutral-900
      sidebarForeground: Color(0xFFFAFAFA), // neutral-50
      sidebarPrimary: Color(0xFF1447E6), // matches chart-1 (dark)
      sidebarPrimaryForeground: Color(0xFFFAFAFA), // neutral-50
      sidebarAccent: Color(0xFF262626), // neutral-800
      sidebarAccentForeground: Color(0xFFFAFAFA), // neutral-50
      sidebarBorder: Color(0x1AFFFFFF), // white/10%
      sidebarRing: Color(0xFF737373), // neutral-500
    ),
  );

  /// Interpolates two themes (drives FwAnimatedTheme later).
  static FwTokens lerp(FwTokens a, FwTokens b, double t) => FwTokens(
    colors: FwColors.lerp(a.colors, b.colors, t),
    radii: FwRadii.lerp(a.radii, b.radii, t),
    shadows: FwShadows.lerp(a.shadows, b.shadows, t),
    // Family names hard-crossover at t=0.5 while tracking interpolates — see
    // FwTypographyTheme.lerp. (Was a whole-object crossover before tracking.)
    typography: FwTypographyTheme.lerp(a.typography, b.typography, t),
    radiusBase: a.radiusBase + (b.radiusBase - a.radiusBase) * t,
  );

  @override
  bool operator ==(Object other) =>
      other is FwTokens &&
      other.colors == colors &&
      other.radii == radii &&
      other.shadows == shadows &&
      other.typography == typography &&
      other.radiusBase == radiusBase;

  @override
  int get hashCode => Object.hash(colors, radii, shadows, typography, radiusBase);
}

/// Per-theme typography families — the [sans], [serif], and [mono] family
/// *names* a shadcn theme carries (`--font-sans`/`--font-serif`/`--font-mono`).
/// Type *scales* are static (`FwFontSize` etc.); this carries only the families.
///
/// **flutterwindcss bundles no fonts.** These are family-name strings handed to
/// `TextStyle.fontFamily`; if the named family isn't a platform/system font and
/// isn't wired by the host app, Flutter falls back silently to the default. The
/// theme generator therefore emits the name **and** a clearly-commented wiring
/// stub (`// TODO: wire this font — add google_fonts / bundle it`) per spec §7,
/// rather than pretending the font is present. [family] is kept as a
/// deprecated-free alias of [sans] for the common "just the body font" read.
///
/// Note: family names hard-crossover at `t = 0.5` (strings cannot interpolate)
/// while [tracking] interpolates linearly — see [FwTypographyTheme.lerp].
@immutable
class FwTypographyTheme {
  /// Creates a typography theme from its family names and base letter-spacing.
  const FwTypographyTheme({
    this.sans = FwFontFamily.sans,
    this.serif = FwFontFamily.serif,
    this.mono = FwFontFamily.mono,
    this.tracking = 0,
  });

  /// The default UI/body (sans) family name.
  final String sans;

  /// The serif family name.
  final String serif;

  /// The monospace family name.
  final String mono;

  /// Theme base letter-spacing in **em** (shadcn `--tracking-normal`), stored as an
  /// em multiple (e.g. `-0.025` for `-0.025em`). Consumers convert to Flutter's
  /// logical-px `TextStyle.letterSpacing` as `tracking × fontSize` at the text-apply
  /// site — the token only carries the value. `0` (the default) means no extra
  /// tracking, preserving prior behavior and all existing goldens.
  final double tracking;

  /// Convenience alias for [sans] — the default body family.
  String get family => sans;

  /// The standard theme using the platform sans/serif/mono families and zero tracking.
  static const FwTypographyTheme standard = FwTypographyTheme();

  /// Interpolates two typography themes. Family **names** are [String]s and cannot
  /// numerically interpolate, so they hard-crossover at `t = 0.5` (the approach
  /// Flutter uses for non-lerpable fields); [tracking] is numeric and interpolates
  /// linearly, so it stays continuous through the crossover.
  static FwTypographyTheme lerp(FwTypographyTheme a, FwTypographyTheme b, double t) {
    final FwTypographyTheme families = t < 0.5 ? a : b;
    return FwTypographyTheme(
      sans: families.sans,
      serif: families.serif,
      mono: families.mono,
      tracking: a.tracking + (b.tracking - a.tracking) * t,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FwTypographyTheme &&
      other.sans == sans &&
      other.serif == serif &&
      other.mono == mono &&
      other.tracking == tracking;

  @override
  int get hashCode => Object.hash(sans, serif, mono, tracking);
}

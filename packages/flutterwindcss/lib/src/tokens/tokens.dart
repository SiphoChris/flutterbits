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

  /// Typography marker (scales are static; present for future per-theme type).
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
    ),
  );

  /// Interpolates two themes (drives FwAnimatedTheme later).
  static FwTokens lerp(FwTokens a, FwTokens b, double t) => FwTokens(
    colors: FwColors.lerp(a.colors, b.colors, t),
    radii: FwRadii.lerp(a.radii, b.radii, t),
    shadows: FwShadows.lerp(a.shadows, b.shadows, t),
    // String family names cannot numerically interpolate; use a hard
    // crossover at t=0.5 (same approach Flutter takes for non-lerpable fields).
    typography: t < 0.5 ? a.typography : b.typography,
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

/// Placeholder per-theme typography marker. Type scales are static
/// (`FwFontSize` etc.); this exists so a theme can carry a default family in a
/// later module without changing the `FwTokens` shape.
///
/// Note: `FwTokens.lerp` uses a hard crossover (t < 0.5 -> a, t >= 0.5 -> b)
/// for this field, because [String] family names cannot numerically interpolate.
@immutable
class FwTypographyTheme {
  /// Creates a typography theme with a default sans [family].
  const FwTypographyTheme({required this.family});

  /// The default font family name.
  final String family;

  /// The standard theme using the platform sans family.
  static const FwTypographyTheme standard = FwTypographyTheme(family: FwFontFamily.sans);

  @override
  bool operator ==(Object other) => other is FwTypographyTheme && other.family == family;

  @override
  int get hashCode => family.hashCode;
}

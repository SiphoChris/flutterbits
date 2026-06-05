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
    radiusBase: 8,
    radii: FwRadii(base: 8, sm: 4.8, md: 6.4, lg: 8, xl: 11.2),
    shadows: FwShadows.defaults,
    typography: FwTypographyTheme.standard,
    colors: FwColors(
      background: FwPalette.white,
      foreground: Color(0xFF0A0A0A), // neutral-950
      card: FwPalette.white,
      cardForeground: Color(0xFF0A0A0A),
      popover: FwPalette.white,
      popoverForeground: Color(0xFF0A0A0A),
      primary: Color(0xFF171717), // neutral-900
      primaryForeground: Color(0xFFFAFAFA), // neutral-50
      secondary: Color(0xFFF5F5F5), // neutral-100
      secondaryForeground: Color(0xFF171717),
      muted: Color(0xFFF5F5F5),
      mutedForeground: Color(0xFF737373), // neutral-500
      accent: Color(0xFFF5F5F5),
      accentForeground: Color(0xFF171717),
      destructive: Color(0xFFE7000B), // red-600-ish per shadcn
      destructiveForeground: FwPalette.white,
      border: Color(0xFFE5E5E5), // neutral-200
      input: Color(0xFFE5E5E5),
      ring: Color(0xFFA1A1A1), // neutral-400
    ),
  );

  /// The stock shadcn-neutral **dark** theme.
  static const FwTokens dark = FwTokens(
    radiusBase: 8,
    radii: FwRadii(base: 8, sm: 4.8, md: 6.4, lg: 8, xl: 11.2),
    shadows: FwShadows.defaults,
    typography: FwTypographyTheme.standard,
    colors: FwColors(
      background: Color(0xFF0A0A0A), // neutral-950
      foreground: Color(0xFFFAFAFA),
      card: Color(0xFF171717),
      cardForeground: Color(0xFFFAFAFA),
      popover: Color(0xFF171717),
      popoverForeground: Color(0xFFFAFAFA),
      primary: Color(0xFFFAFAFA),
      primaryForeground: Color(0xFF171717),
      secondary: Color(0xFF262626), // neutral-800
      secondaryForeground: Color(0xFFFAFAFA),
      muted: Color(0xFF262626),
      mutedForeground: Color(0xFFA1A1A1),
      accent: Color(0xFF262626),
      accentForeground: Color(0xFFFAFAFA),
      destructive: Color(0xFFFF6467), // red-400-ish per shadcn dark
      destructiveForeground: Color(0xFF0A0A0A),
      border: Color(0x1AFFFFFF), // white/10
      input: Color(0x26FFFFFF), // white/15
      ring: Color(0xFF737373),
    ),
  );

  /// Interpolates two themes (drives FwAnimatedTheme later).
  static FwTokens lerp(FwTokens a, FwTokens b, double t) => FwTokens(
        colors: FwColors.lerp(a.colors, b.colors, t),
        radii: FwRadii.lerp(a.radii, b.radii, t),
        shadows: FwShadows.lerp(a.shadows, b.shadows, t),
        typography: FwTypographyTheme.standard,
        radiusBase: a.radiusBase + (b.radiusBase - a.radiusBase) * t,
      );

  @override
  bool operator ==(Object other) =>
      other is FwTokens &&
      other.colors == colors &&
      other.radii == radii &&
      other.shadows == shadows &&
      other.radiusBase == radiusBase;

  @override
  int get hashCode => Object.hash(colors, radii, shadows, radiusBase);
}

/// Placeholder per-theme typography marker. Type scales are static
/// (`FwFontSize` etc.); this exists so a theme can carry a default family in a
/// later module without changing the `FwTokens` shape.
@immutable
class FwTypographyTheme {
  /// Creates a typography theme with a default sans [family].
  const FwTypographyTheme({required this.family});

  /// The default font family name.
  final String family;

  /// The standard theme using the platform sans family.
  static const FwTypographyTheme standard = FwTypographyTheme(family: FwFontFamily.sans);

  @override
  bool operator ==(Object other) =>
      other is FwTypographyTheme && other.family == family;

  @override
  int get hashCode => family.hashCode;
}

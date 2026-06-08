// Demo themes for the showcase theme-switcher. Each [DemoTheme] is a light+dark
// `FwTokens` pair. These are hand-authored stand-ins for what the tweakcn ->
// theme.dart generator will emit — the switcher swaps between them at runtime to
// prove the headline capability: semantic tokens reskin the ENTIRE app (colours,
// radius, shadows, and font names all change) without touching a single widget.
//
// "Default" is the built-in stock shadcn-neutral theme. "Claude" is a real pasted
// tweakcn/shadcn theme (warm/clay palette, 1rem radius, Outfit type) transcribed
// faithfully: hex colours verbatim, radius via shadcn's additive calc(--radius ±
// px) derivation (NOT a multiplicative factor), and its black-alpha shadow scale.
import 'package:flutter/painting.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

/// A named theme = a light + dark [FwTokens] pair the switcher can select.
class DemoTheme {
  /// Creates a named theme from its [light] and [dark] token bundles.
  const DemoTheme(this.name, this.light, this.dark);

  /// Display name shown on the switcher.
  final String name;

  /// Tokens used when the app is in light mode.
  final FwTokens light;

  /// Tokens used when the app is in dark mode.
  final FwTokens dark;

  /// The bundle for the current [isDark] brightness.
  FwTokens resolve({required bool isDark}) => isDark ? dark : light;
}

/// The themes offered by the showcase switcher.
const List<DemoTheme> kDemoThemes = <DemoTheme>[
  DemoTheme('Default', FwTokens.light, FwTokens.dark),
  DemoTheme('Claude', _claudeLight, _claudeDark),
];

// --- Claude theme (pasted tweakcn theme; generator preview) -----------------

// shadcn additive radius derivation from --radius: 1rem (16px):
// sm = r-4 = 12, md = r-2 = 14, lg = r = 16, xl = r+4 = 20. (The generator emits
// these explicit values rather than the engine's default ×factor — see the
// coverage spec; FwRadii holds explicit per-step values for exactly this.)
const FwRadii _claudeRadii = FwRadii(base: 16, sm: 12, md: 14, lg: 16, xl: 20);

// Outfit (sans) is not bundled — flutterwindcss ships no fonts — so it falls back
// to the platform sans until the host wires google_fonts (the stub the generator
// emits). The NAME still round-trips through the theme.
const FwTypographyTheme _claudeType = FwTypographyTheme(
  sans: 'Outfit',
  serif: 'Georgia',
  mono: 'Geist Mono',
);

// The Claude theme's black-alpha shadow scale (hsl(0 0% 0% / a) = black at alpha):
// 0.05 -> 0x0D, 0.10 -> 0x1A, 0.25 -> 0x40. Light and dark share these.
const FwShadows _claudeShadows = FwShadows(
  xs2: <BoxShadow>[BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 3)],
  xs: <BoxShadow>[BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 3)],
  sm: <BoxShadow>[
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 1), blurRadius: 3),
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 1), blurRadius: 2, spreadRadius: -1),
  ],
  md: <BoxShadow>[
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 1), blurRadius: 3),
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 2), blurRadius: 4, spreadRadius: -1),
  ],
  lg: <BoxShadow>[
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 1), blurRadius: 3),
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 6, spreadRadius: -1),
  ],
  xl: <BoxShadow>[
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 1), blurRadius: 3),
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 8), blurRadius: 10, spreadRadius: -1),
  ],
  xl2: <BoxShadow>[BoxShadow(color: Color(0x40000000), offset: Offset(0, 1), blurRadius: 3)],
);

const FwTokens _claudeLight = FwTokens(
  radiusBase: 16,
  radii: _claudeRadii,
  shadows: _claudeShadows,
  typography: _claudeType,
  colors: FwColors(
    background: Color(0xFFFAF9F5),
    foreground: Color(0xFF3D3929),
    card: Color(0xFFF5F4EF),
    cardForeground: Color(0xFF141413),
    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF28261B),
    primary: Color(0xFFC96442),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFFE9E6DC),
    secondaryForeground: Color(0xFF535146),
    muted: Color(0xFFEDE9DE),
    mutedForeground: Color(0xFF6E6D68),
    accent: Color(0xFFE9E6DC),
    accentForeground: Color(0xFF28261B),
    destructive: Color(0xFF141413),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0xFFDAD9D4),
    input: Color(0xFFB4B2A7),
    ring: Color(0xFFC96442),
    chart1: Color(0xFFB05730),
    chart2: Color(0xFF9C87F5),
    chart3: Color(0xFFDED8C4),
    chart4: Color(0xFFDBD3F0),
    chart5: Color(0xFFB4552D),
    sidebar: Color(0xFFF5F4EE),
    sidebarForeground: Color(0xFF3D3D3A),
    sidebarPrimary: Color(0xFFC96442),
    sidebarPrimaryForeground: Color(0xFFFBFBFB),
    sidebarAccent: Color(0xFFE9E6DC),
    sidebarAccentForeground: Color(0xFF343434),
    sidebarBorder: Color(0xFFEBEBEB),
    sidebarRing: Color(0xFFB5B5B5),
  ),
);

const FwTokens _claudeDark = FwTokens(
  radiusBase: 16,
  radii: _claudeRadii,
  shadows: _claudeShadows,
  typography: _claudeType,
  colors: FwColors(
    background: Color(0xFF262624),
    foreground: Color(0xFFF1F1EF),
    card: Color(0xFF2C2C2B),
    cardForeground: Color(0xFFFAF9F5),
    popover: Color(0xFF30302E),
    popoverForeground: Color(0xFFE5E5E2),
    primary: Color(0xFFD97757),
    primaryForeground: Color(0xFF141413),
    secondary: Color(0xFFFAF9F5),
    secondaryForeground: Color(0xFF30302E),
    muted: Color(0xFF1B1B19),
    mutedForeground: Color(0xFFB7B5A9),
    accent: Color(0xFF1A1915),
    accentForeground: Color(0xFFF5F4EE),
    destructive: Color(0xFFEF4444),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0xFF3E3E38),
    input: Color(0xFF52514A),
    ring: Color(0xFFD97757),
    chart1: Color(0xFFB05730),
    chart2: Color(0xFF9C87F5),
    chart3: Color(0xFF1A1915),
    chart4: Color(0xFF2F2B48),
    chart5: Color(0xFFB4552D),
    sidebar: Color(0xFF1F1E1D),
    sidebarForeground: Color(0xFFC3C0B6),
    sidebarPrimary: Color(0xFF343434),
    sidebarPrimaryForeground: Color(0xFFFBFBFB),
    sidebarAccent: Color(0xFF0F0F0E),
    sidebarAccentForeground: Color(0xFFC3C0B6),
    sidebarBorder: Color(0xFFEBEBEB),
    sidebarRing: Color(0xFFB5B5B5),
  ),
);

/// Expected resolved values for the Claude theme — the end-to-end golden oracle
/// (spec §8). This **mirrors** `apps/example/lib/showcase/themes.dart`
/// (`_claudeLight`/`_claudeDark`/`_claudeRadii`/`_claudeShadows`/`_claudeType`),
/// the human-checked source of those values. Colors are `AARRGGBB` hex; shadow
/// colors are `AARRGGBB` (tweakcn hard-codes `hsl(... / a)` for shadows in every
/// export format, so they are byte-exact across all four fixtures).
///
/// If a future change to `themes.dart` makes the golden fail, fix THIS oracle to
/// match the transform's output in the same PR, with a `// corrected` note (§12).

import type { ResolvedRadii, ResolvedTypography, ShadowSlot, ThemeJsonShadow } from '../types';

export const claudeExpectedLight: Readonly<Record<string, string>> = {
  background: 'FFFAF9F5',
  foreground: 'FF3D3929',
  card: 'FFF5F4EF',
  cardForeground: 'FF141413',
  popover: 'FFFFFFFF',
  popoverForeground: 'FF28261B',
  primary: 'FFC96442',
  primaryForeground: 'FFFFFFFF',
  secondary: 'FFE9E6DC',
  secondaryForeground: 'FF535146',
  muted: 'FFEDE9DE',
  mutedForeground: 'FF6E6D68',
  accent: 'FFE9E6DC',
  accentForeground: 'FF28261B',
  destructive: 'FF141413',
  destructiveForeground: 'FFFFFFFF',
  border: 'FFDAD9D4',
  input: 'FFB4B2A7',
  ring: 'FFC96442',
  chart1: 'FFB05730',
  chart2: 'FF9C87F5',
  chart3: 'FFDED8C4',
  chart4: 'FFDBD3F0',
  chart5: 'FFB4552D',
  sidebar: 'FFF5F4EE',
  sidebarForeground: 'FF3D3D3A',
  sidebarPrimary: 'FFC96442',
  sidebarPrimaryForeground: 'FFFBFBFB',
  sidebarAccent: 'FFE9E6DC',
  sidebarAccentForeground: 'FF343434',
  sidebarBorder: 'FFEBEBEB',
  sidebarRing: 'FFB5B5B5',
};

export const claudeExpectedDark: Readonly<Record<string, string>> = {
  background: 'FF262624',
  foreground: 'FFF1F1EF',
  card: 'FF2C2C2B',
  cardForeground: 'FFFAF9F5',
  popover: 'FF30302E',
  popoverForeground: 'FFE5E5E2',
  primary: 'FFD97757',
  primaryForeground: 'FF141413',
  secondary: 'FFFAF9F5',
  secondaryForeground: 'FF30302E',
  muted: 'FF1B1B19',
  mutedForeground: 'FFB7B5A9',
  accent: 'FF1A1915',
  accentForeground: 'FFF5F4EE',
  destructive: 'FFEF4444',
  destructiveForeground: 'FFFFFFFF',
  border: 'FF3E3E38',
  input: 'FF52514A',
  ring: 'FFD97757',
  chart1: 'FFB05730',
  chart2: 'FF9C87F5',
  chart3: 'FF1A1915',
  chart4: 'FF2F2B48',
  chart5: 'FFB4552D',
  sidebar: 'FF1F1E1D',
  sidebarForeground: 'FFC3C0B6',
  sidebarPrimary: 'FF343434',
  sidebarPrimaryForeground: 'FFFBFBFB',
  sidebarAccent: 'FF0F0F0E',
  sidebarAccentForeground: 'FFC3C0B6',
  sidebarBorder: 'FFEBEBEB',
  sidebarRing: 'FFB5B5B5',
};

export const claudeExpectedRadii: ResolvedRadii = { base: 16, sm: 12, md: 14, lg: 16, xl: 20 };

// Black-alpha shadow scale: 0.05 → 0x0D, 0.10 → 0x1A, 0.25 → 0x40.
const sh = (a: string, x: number, y: number, blur: number, spread: number): ThemeJsonShadow => ({
  color: `${a}000000`,
  x,
  y,
  blur,
  spread,
});
export const claudeExpectedShadows: Record<ShadowSlot, ThemeJsonShadow[]> = {
  xs2: [sh('0D', 0, 1, 3, 0)],
  xs: [sh('0D', 0, 1, 3, 0)],
  sm: [sh('1A', 0, 1, 3, 0), sh('1A', 0, 1, 2, -1)],
  md: [sh('1A', 0, 1, 3, 0), sh('1A', 0, 2, 4, -1)],
  lg: [sh('1A', 0, 1, 3, 0), sh('1A', 0, 4, 6, -1)],
  xl: [sh('1A', 0, 1, 3, 0), sh('1A', 0, 8, 10, -1)],
  xl2: [sh('40', 0, 1, 3, 0)],
};

export const claudeExpectedTypography: ResolvedTypography = {
  sans: 'Outfit',
  serif: 'Georgia',
  mono: 'Geist Mono',
  tracking: 0,
};

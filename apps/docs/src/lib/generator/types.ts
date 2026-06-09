/// Generator-wide types and the CSS token-name contract.
///
/// This file is the shared vocabulary between the staged pipeline
/// (`parse → color → emit`, spec §2). G2 (`parse/`) produces a [RawTheme] of
/// verbatim CSS custom properties and uses [KNOWN_VAR_NAMES] to classify which
/// `--vars` are "unknown"; G3 (`emit/`) consumes the same name lists to map each
/// CSS property onto its `FwTokens` field and to gate the 32 colors.
///
/// Doc comments use `///` (not JSDoc) intentionally, to match the Dart layer's
/// house style across the repo (spec §2.1).

import type { ConversionMode, Rgba8 } from './color/types';

// === RawTheme — the G2 (parse) stage output ===

/// A single CSS rule block's custom properties, captured verbatim.
export interface RawBlock {
  /// Every `--name: value` declaration in the block. The key is the property
  /// name **without** the leading `--`; the value is the verbatim, trimmed
  /// declaration value (only `/* … */` comments are stripped — the value is
  /// otherwise unmodified, so the color/emit stages parse it).
  ///
  /// Nothing is dropped here (spec §2.2 "record, don't drop"): per-axis
  /// `--shadow-*` builder primitives, the unprefixed `--shadow` DEFAULT, and any
  /// unknown vars are all retained alongside the values we map. **Token absence
  /// is recorded by omission** — a contract token missing from a block simply has
  /// no key here, which is how G3/G4 detect a token to default-and-report.
  readonly vars: Readonly<Record<string, string>>;
}

/// The output of G2: the `:root` (light) and `.dark` blocks of a tweakcn
/// Tailwind-v4 export, each as a verbatim property map, plus the names of any
/// properties not in the known token contract.
export interface RawTheme {
  /// The `:root { … }` block — the light theme.
  readonly root: RawBlock;
  /// The `.dark { … }` block — the dark theme.
  readonly dark: RawBlock;
  /// CSS var names (sans `--`) found in `:root` or `.dark` that are **not** part
  /// of the known token contract ([KNOWN_VAR_NAMES]). Recorded here, never
  /// silently discarded (spec §2.2); de-duplicated across both blocks and sorted.
  /// G3 surfaces these as `meta.droppedVars` in `theme.json`.
  readonly unknownVars: readonly string[];
}

// === Token-name contract — the CSS custom-property names we understand ===

/// The 32 semantic color CSS custom-property names (sans `--`), in the canonical
/// order of the §5 token contract: 19 core + `chart-1…5` + 8 `sidebar*`. G3 maps
/// each to its `FwColors` field (e.g. `card-foreground` → `cardForeground`).
export const COLOR_VAR_NAMES = [
  'background',
  'foreground',
  'card',
  'card-foreground',
  'popover',
  'popover-foreground',
  'primary',
  'primary-foreground',
  'secondary',
  'secondary-foreground',
  'muted',
  'muted-foreground',
  'accent',
  'accent-foreground',
  'destructive',
  'destructive-foreground',
  'border',
  'input',
  'ring',
  'chart-1',
  'chart-2',
  'chart-3',
  'chart-4',
  'chart-5',
  'sidebar',
  'sidebar-foreground',
  'sidebar-primary',
  'sidebar-primary-foreground',
  'sidebar-accent',
  'sidebar-accent-foreground',
  'sidebar-border',
  'sidebar-ring',
] as const;

/// The seven **named** composed shadow slots (sans `--`), mapped by G3 to the
/// `FwShadows` 7-slot scale (`--shadow-2xs` → `xs2`, …, `--shadow-2xl` → `xl2`).
export const NAMED_SHADOW_VAR_NAMES = [
  'shadow-2xs',
  'shadow-xs',
  'shadow-sm',
  'shadow-md',
  'shadow-lg',
  'shadow-xl',
  'shadow-2xl',
] as const;

/// The unprefixed Tailwind DEFAULT shadow. It is **known but knowingly dropped**:
/// `FwShadows` has no DEFAULT slot, and tweakcn computes `--shadow` with the `sm`
/// second-layer formula so it is *not* `--shadow-md` (spec §4.2). Listed here so
/// it is classified "known" (not flagged as an unknown var) while still recorded
/// verbatim in [RawBlock.vars].
export const DEFAULT_SHADOW_VAR_NAME = 'shadow';

/// tweakcn's per-axis shadow **builder inputs**. They bake into the composed
/// `--shadow-*` strings and are NOT separate outputs — known, but deliberately
/// ignored by emit (spec §4.2). Listed so they are classified "known" while still
/// retained verbatim in [RawBlock.vars] (record-don't-drop).
export const IGNORED_SHADOW_VAR_NAMES = [
  'shadow-x',
  'shadow-y',
  'shadow-blur',
  'shadow-spread',
  'shadow-opacity',
  'shadow-color',
] as const;

/// Non-color, non-shadow scalar tokens read by emit: the radius base, the three
/// font stacks, the base letter-spacing, and the base spacing unit.
export const OTHER_VAR_NAMES = [
  'radius',
  'font-sans',
  'font-serif',
  'font-mono',
  'tracking-normal',
  'spacing',
] as const;

/// The full set of CSS var names the generator understands. Any `--var` in
/// `:root`/`.dark` outside this set is an "unknown var" ([RawTheme.unknownVars]).
export const KNOWN_VAR_NAMES: ReadonlySet<string> = new Set<string>([
  ...COLOR_VAR_NAMES,
  ...NAMED_SHADOW_VAR_NAMES,
  DEFAULT_SHADOW_VAR_NAME,
  ...IGNORED_SHADOW_VAR_NAMES,
  ...OTHER_VAR_NAMES,
]);

// === ResolvedTheme — the G3 (emit) intermediate, after color/unit resolution ===

/// `card-foreground` → `cardForeground`, `chart-1` → `chart1`. The dart `FwColors`
/// field name for a CSS color var: drop each hyphen and upper-case what follows.
export function kebabToCamel(name: string): string {
  return name.replace(/-([a-z0-9])/g, (_m, c: string) => c.toUpperCase());
}

/// The 32 `FwColors` field names (camelCase), in the [COLOR_VAR_NAMES] order.
export const COLOR_FIELD_NAMES = COLOR_VAR_NAMES.map(kebabToCamel);

/// The seven `FwShadows` slot names, in declaration order, paired with the CSS
/// `--shadow-*` they come from (spec §4.2). `--shadow-2xs` → `xs2`, … .
export const SHADOW_SLOTS = [
  { slot: 'xs2', css: 'shadow-2xs' },
  { slot: 'xs', css: 'shadow-xs' },
  { slot: 'sm', css: 'shadow-sm' },
  { slot: 'md', css: 'shadow-md' },
  { slot: 'lg', css: 'shadow-lg' },
  { slot: 'xl', css: 'shadow-xl' },
  { slot: 'xl2', css: 'shadow-2xl' },
] as const;

/// A `FwShadows` slot key.
export type ShadowSlot = (typeof SHADOW_SLOTS)[number]['slot'];

/// One CSS box-shadow layer, resolved: `<x> <y> <blur> <spread> <color>` (px).
export interface ResolvedShadow {
  readonly color: Rgba8;
  readonly x: number;
  readonly y: number;
  readonly blur: number;
  readonly spread: number;
}

/// The 7 shadow slots, each a list of [ResolvedShadow] layers (source order).
export type ResolvedShadows = Readonly<Record<ShadowSlot, readonly ResolvedShadow[]>>;

/// The additive radius set in logical px (spec §4.1): `sm = max(0, base−4)`,
/// `md = max(0, base−2)`, `lg = base`, `xl = base+4`.
export interface ResolvedRadii {
  readonly base: number;
  readonly sm: number;
  readonly md: number;
  readonly lg: number;
  readonly xl: number;
}

/// Family names (extracted from the CSS stacks) + base letter-spacing in em.
export interface ResolvedTypography {
  readonly sans: string;
  readonly serif: string;
  readonly mono: string;
  /// `--tracking-normal` normalized to em (spec §4.3); `0` when absent/`normal`.
  readonly tracking: number;
}

/// The 32 resolved semantic colors for one brightness, keyed by `FwColors` field
/// name (camelCase). Every key in [COLOR_FIELD_NAMES] is present (the hard gate).
export type ResolvedColors = Readonly<Record<string, Rgba8>>;

/// Generation metadata surfaced to the user and emitted as `theme.dart` comments.
export interface ResolvedMeta {
  /// The OKLCH out-of-gamut policy used (spec §2.1).
  readonly conversion: ConversionMode;
  /// Out-of-contract `--vars` recorded by the parser ([RawTheme.unknownVars]).
  readonly droppedVars: readonly string[];
  /// Human-readable notes on every token the generator **defaulted** or **dropped**
  /// (omitted font/shadow/radius → engine default; non-default `--spacing` dropped;
  /// absolute-unit tracking). Nothing is silent (spec §7.4 / §12).
  readonly notes: readonly string[];
}

/// The fully resolved theme — the G3 pivot between parse/color and JSON/Dart
/// emit. Radius/shadows/typography are theme-level (identical in `:root`/`.dark`
/// for every tweakcn export, read from `:root`); only colors differ per block.
export interface ResolvedTheme {
  readonly light: ResolvedColors;
  readonly dark: ResolvedColors;
  readonly radii: ResolvedRadii;
  readonly shadows: ResolvedShadows;
  readonly typography: ResolvedTypography;
  readonly meta: ResolvedMeta;
}

// === ThemeJson — the JSON source of truth (spec §4.4) ===

/// A shadow layer as serialized JSON: color is an `AARRGGBB` hex string.
export interface ThemeJsonShadow {
  readonly color: string;
  readonly x: number;
  readonly y: number;
  readonly blur: number;
  readonly spread: number;
}

/// The `theme.json` shape — mirrors `FwTokens`; the Dart file is a pure function
/// of this (spec §4.4). Colors are `AARRGGBB` hex strings keyed by `FwColors`
/// field name.
export interface ThemeJson {
  readonly radiusBase: number;
  readonly radii: ResolvedRadii;
  readonly colors: {
    readonly light: Readonly<Record<string, string>>;
    readonly dark: Readonly<Record<string, string>>;
  };
  readonly shadows: Readonly<Record<ShadowSlot, readonly ThemeJsonShadow[]>>;
  readonly typography: ResolvedTypography;
  readonly meta: ResolvedMeta;
}

/// The generator's end product: the JSON source of truth + the emitted Dart.
export interface GenerateResult {
  readonly themeJson: ThemeJson;
  readonly dartSource: string;
}

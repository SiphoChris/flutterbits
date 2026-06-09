import { generateTheme } from './emit';
import { COLOR_FIELD_NAMES, SHADOW_SLOTS } from './types';
import type { GenerateResult, ThemeJson, ThemeJsonShadow } from './types';

/// Presentation helpers for the G4 web UI (spec §7). Pure, framework-free, and
/// unit-tested so the React route (`theme-generator/page.tsx`) stays a thin,
/// declarative shell. Turns the [ThemeJson] (8-bit `AARRGGBB`) into CSS-ready
/// strings for the swatch / radius / shadow preview, and wraps `generateTheme`
/// into a discriminated result the UI can render without a try/catch.

/// `AARRGGBB` (the engine's ARGB byte order) → CSS `#rrggbbaa`. The browser wants
/// the alpha last; the generator stores it first (to match Flutter's `Color`).
export function argbToCss(argb: string): string {
  const aa = argb.slice(0, 2);
  const rgb = argb.slice(2, 8);
  return `#${rgb}${aa}`.toLowerCase();
}

/// A [ThemeJsonShadow] list → a CSS `box-shadow` value (layers comma-joined, in
/// source order). Each layer is `x y blur spread color` in px.
export function shadowToCss(layers: readonly ThemeJsonShadow[]): string {
  if (layers.length === 0) return 'none';
  return layers
    .map((l) => `${l.x}px ${l.y}px ${l.blur}px ${l.spread}px ${argbToCss(l.color)}`)
    .join(', ');
}

/// `cardForeground` → `Card foreground`, `chart1` → `Chart 1`. A readable swatch
/// label from a `FwColors` field name.
export function humanizeField(field: string): string {
  const spaced = field
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .replace(/([a-zA-Z])(\d)/g, '$1 $2')
    .toLowerCase();
  return spaced.charAt(0).toUpperCase() + spaced.slice(1);
}

/// One color swatch: the `FwColors` field, a human label, and a CSS color.
export interface Swatch {
  readonly field: string;
  readonly label: string;
  readonly css: string;
}

/// The 32 swatches for a brightness, in the canonical token order.
export function swatches(colors: Readonly<Record<string, string>>): Swatch[] {
  return COLOR_FIELD_NAMES.map((field) => ({
    field,
    label: humanizeField(field),
    css: argbToCss(colors[field]),
  }));
}

/// One radius sample: the step name and its logical-px value.
export interface RadiusSample {
  readonly name: string;
  readonly px: number;
}

/// The four radius samples (sm/md/lg/xl) for the preview.
export function radiusSamples(json: ThemeJson): RadiusSample[] {
  return [
    { name: 'sm', px: json.radii.sm },
    { name: 'md', px: json.radii.md },
    { name: 'lg', px: json.radii.lg },
    { name: 'xl', px: json.radii.xl },
  ];
}

/// One shadow sample: the slot name and its CSS `box-shadow` value.
export interface ShadowSample {
  readonly name: string;
  readonly css: string;
}

/// The seven shadow samples for the preview.
export function shadowSamples(json: ThemeJson): ShadowSample[] {
  return SHADOW_SLOTS.map(({ slot }) => ({ name: slot, css: shadowToCss(json.shadows[slot]) }));
}

/// The result of running the generator on pasted CSS — a discriminated union the
/// UI renders directly. `empty` is a paste-prompt state (not an error); `error`
/// carries a user-facing message (v3 reject, missing-color gate, malformed input).
export type GeneratorResult =
  | { readonly status: 'empty' }
  | { readonly status: 'ok'; readonly result: GenerateResult }
  | { readonly status: 'error'; readonly message: string };

/// Run the generator, mapping a blank textarea to `empty` and any thrown error to
/// a clean `error` message — so the route never needs its own try/catch (spec §7).
/// The web UI always uses the **faithful** conversion (it matches the Tailwind/
/// shadcn hex, which is what every real tweakcn export wants); the perceptual
/// gamut-map remains available on the `generateTheme`/`parseCssColor` library API
/// but is not surfaced as a UI toggle (UX decision 2026-06-09).
export function runGenerator(css: string): GeneratorResult {
  if (css.trim() === '') return { status: 'empty' };
  try {
    return { status: 'ok', result: generateTheme(css) };
  } catch (e) {
    return { status: 'error', message: e instanceof Error ? e.message : String(e) };
  }
}

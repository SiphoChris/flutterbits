import type { ConversionMode, Rgba8 } from '../color/types';
import { parseCssColor } from '../color';
import type {
  RawBlock,
  RawTheme,
  ResolvedColors,
  ResolvedRadii,
  ResolvedShadow,
  ResolvedShadows,
  ResolvedTheme,
  ResolvedTypography,
} from '../types';
import { COLOR_VAR_NAMES, COLOR_FIELD_NAMES, SHADOW_SLOTS } from '../types';

/// G3 resolve stage — `RawTheme` (verbatim CSS) → `ResolvedTheme` (8-bit colors +
/// px numbers + family names + tracking em + a graceful-default report). This is
/// where the §4 per-domain emit rules live; the color math is delegated to the
/// G1 `color/` core. Everything that is defaulted or dropped is recorded in
/// `meta.notes` — never silent (spec §7.4 / §12).

/// Platform fallback family names (`FwFontFamily` defaults) for omitted `--font-*`.
const DEFAULT_FONT = { sans: 'sans-serif', serif: 'serif', mono: 'monospace' } as const;

/// CSS generic font keywords — skipped when extracting a concrete family from a
/// stack (spec §4.3). Compared case-insensitively.
const GENERIC_FAMILIES = new Set<string>([
  'serif',
  'sans-serif',
  'monospace',
  'cursive',
  'fantasy',
  'system-ui',
  'math',
  'emoji',
  'fangsong',
  'ui-serif',
  'ui-sans-serif',
  'ui-monospace',
  'ui-rounded',
]);

/// `FwShadows.defaults` transcribed (spec §7.4): the engine's Tailwind-v4 scale
/// used when a theme omits some/all `--shadow-*`. Black at 5% / 10% / 25% alpha
/// (`0x0D` / `0x1A` / `0x40`).
const K05: Rgba8 = { r: 0, g: 0, b: 0, a: 0x0d };
const K10: Rgba8 = { r: 0, g: 0, b: 0, a: 0x1a };
const K25: Rgba8 = { r: 0, g: 0, b: 0, a: 0x40 };
const s = (color: Rgba8, x: number, y: number, blur: number, spread: number): ResolvedShadow => ({
  color,
  x,
  y,
  blur,
  spread,
});
const DEFAULT_SHADOWS: ResolvedShadows = {
  xs2: [s(K05, 0, 1, 0, 0)],
  xs: [s(K05, 0, 1, 2, 0)],
  sm: [s(K10, 0, 1, 3, 0), s(K10, 0, 1, 2, -1)],
  md: [s(K10, 0, 4, 6, -1), s(K10, 0, 2, 4, -2)],
  lg: [s(K10, 0, 10, 15, -3), s(K10, 0, 4, 6, -4)],
  xl: [s(K10, 0, 20, 25, -5), s(K10, 0, 8, 10, -6)],
  xl2: [s(K25, 0, 25, 50, -12)],
};

/// Convert a CSS length to logical px: `rem` × 16, `px` as-is, bare number as-is
/// (covers `0`). Throws on a non-numeric value (caller surfaces it).
function lengthToPx(value: string, label: string): number {
  const m = /^(-?[\d.]+)\s*(rem|px)?$/.exec(value.trim());
  if (m === null) throw new Error(`Invalid ${label} length: "${value}"`);
  const n = parseFloat(m[1]);
  return m[2] === 'rem' ? n * 16 : n;
}

/// Split on `sep` only at paren depth 0, so a `hsl(0 0% 0% / .1)` or
/// `rgba(29,161,242,.15)` color inside a shadow layer is never split apart.
function splitTopLevel(input: string, sep: string): string[] {
  const out: string[] = [];
  let depth = 0;
  let start = 0;
  for (let i = 0; i < input.length; i++) {
    const c = input[i];
    if (c === '(') depth++;
    else if (c === ')') depth = Math.max(0, depth - 1);
    else if (c === sep && depth === 0) {
      out.push(input.slice(start, i));
      start = i + 1;
    }
  }
  out.push(input.slice(start));
  return out.map((t) => t.trim()).filter((t) => t.length > 0);
}

/// Tokenize a shadow layer on whitespace at paren depth 0 (keeps `hsl( … )` whole).
function tokenizeTopLevel(input: string): string[] {
  const out: string[] = [];
  let depth = 0;
  let buf = '';
  for (const c of input.trim()) {
    if (c === '(') depth++;
    else if (c === ')') depth = Math.max(0, depth - 1);
    if (depth === 0 && /\s/.test(c)) {
      if (buf.length > 0) {
        out.push(buf);
        buf = '';
      }
    } else {
      buf += c;
    }
  }
  if (buf.length > 0) out.push(buf);
  return out;
}

/// Whether a shadow token is the color (a function color or a hex). tweakcn never
/// emits `inset` or a named color in shadows; everything else is a length.
function isColorToken(token: string): boolean {
  return token.startsWith('#') || /^(oklch|hsla?|rgba?)\(/i.test(token);
}

/// Parse a CSS box-shadow value (one or more comma-separated layers) into
/// resolved layers (spec §4.2). Each layer is `<x> <y> <blur>? <spread>? <color>`.
function parseShadow(value: string, mode: ConversionMode): ResolvedShadow[] {
  return splitTopLevel(value, ',').map((layer) => {
    const tokens = tokenizeTopLevel(layer);
    const colorIdx = tokens.findIndex(isColorToken);
    if (colorIdx === -1) throw new Error(`Shadow layer has no color: "${layer}"`);
    const color = parseCssColor(tokens[colorIdx], mode);
    const lengths = tokens.filter((_t, i) => i !== colorIdx).map((t) => parseFloat(t));
    if (lengths.length < 2 || lengths.some((n) => !Number.isFinite(n))) {
      throw new Error(`Shadow layer needs at least x & y offsets: "${layer}"`);
    }
    return { color, x: lengths[0], y: lengths[1], blur: lengths[2] ?? 0, spread: lengths[3] ?? 0 };
  });
}

/// Extract one concrete family name from a CSS font *stack* (spec §4.3): split on
/// top-level commas, strip all quotes, skip CSS generics, take the first concrete
/// family — falling back to the first entry if every entry is generic.
function extractFamily(stack: string): string {
  const entries = splitTopLevel(stack, ',').map((e) => e.replace(/['"]/g, '').trim());
  const concrete = entries.find((e) => !GENERIC_FAMILIES.has(e.toLowerCase()));
  return concrete ?? entries[0];
}

/// Normalize `--tracking-normal` to em (spec §4.3). `em`/`rem`/bare → numeric;
/// `normal` → 0; `px` → px/16 (absolute — flagged in `notes`).
function resolveTracking(value: string, notes: string[]): number {
  const trimmed = value.trim();
  if (trimmed.toLowerCase() === 'normal') return 0;
  const m = /^(-?[\d.]+)\s*(em|rem|px)?$/.exec(trimmed);
  if (m === null) throw new Error(`Invalid --tracking-normal: "${value}"`);
  const n = parseFloat(m[1]);
  if (m[2] === 'px') {
    notes.push(
      `--tracking-normal "${value}" is an absolute unit; converted to ${n / 16}em ` +
        `(it will not scale with font size).`,
    );
    return n / 16;
  }
  return n;
}

/// Resolve one brightness block's 32 colors, hard-gating their presence. Missing
/// `--sidebar-ring` defaults to `ring` (it is absent from tweakcn's Zod schema,
/// spec §3); any other missing color throws (FwColors has no defaults — a partial
/// `theme.dart` would not compile, and a web user has no compiler).
function resolveColors(
  block: RawBlock,
  mode: ConversionMode,
  brightness: string,
  notes: string[],
): ResolvedColors {
  const colors: Record<string, Rgba8> = {};
  const missing: string[] = [];
  COLOR_VAR_NAMES.forEach((cssName, i) => {
    const field = COLOR_FIELD_NAMES[i];
    const value = block.vars[cssName];
    if (value !== undefined) {
      colors[field] = parseCssColor(value, mode);
    } else if (cssName === 'sidebar-ring' && colors.ring !== undefined) {
      colors.sidebarRing = colors.ring;
      notes.push(`--sidebar-ring absent (${brightness}); defaulted to --ring.`);
    } else {
      missing.push(cssName);
    }
  });
  if (missing.length > 0) {
    throw new Error(
      `Missing required color${missing.length > 1 ? 's' : ''} in the ${brightness} theme: ` +
        `${missing.map((n) => `--${n}`).join(', ')}. All 32 shadcn colors are required ` +
        `(FwColors has no defaults).`,
    );
  }
  return colors;
}

/// Resolve the additive radius set from `--radius` (spec §4.1), clamped ≥ 0.
function resolveRadii(root: RawBlock, notes: string[]): ResolvedRadii {
  const value = root.vars.radius;
  let base: number;
  if (value === undefined) {
    base = 10;
    notes.push('--radius absent; defaulted to 0.625rem (10px), the shadcn default.');
  } else {
    base = lengthToPx(value, 'radius');
  }
  return {
    base,
    sm: Math.max(0, base - 4),
    md: Math.max(0, base - 2),
    lg: base,
    xl: base + 4,
  };
}

/// Resolve the 7 named shadow slots (spec §4.2). The unprefixed `--shadow`
/// DEFAULT and the per-axis `--shadow-*` primitives are ignored. Wholly-absent
/// shadows → the engine default scale; a partially-defined theme fills each
/// missing slot from the engine default. Either way the gap is reported.
function resolveShadows(
  root: RawBlock,
  mode: ConversionMode,
  notes: string[],
): ResolvedShadows {
  const anyPresent = SHADOW_SLOTS.some(({ css }) => root.vars[css] !== undefined);
  if (!anyPresent) {
    notes.push('No --shadow-* defined; defaulted to the engine Tailwind-v4 shadow scale.');
    return DEFAULT_SHADOWS;
  }
  const out = {} as Record<string, readonly ResolvedShadow[]>;
  for (const { slot, css } of SHADOW_SLOTS) {
    const value = root.vars[css];
    if (value !== undefined) {
      out[slot] = parseShadow(value, mode);
    } else {
      out[slot] = DEFAULT_SHADOWS[slot];
      notes.push(`--${css} absent; defaulted to the engine '${slot}' shadow.`);
    }
  }
  return out as ResolvedShadows;
}

/// Resolve typography: extract a concrete family per slot (defaulting + reporting
/// omitted ones) and normalize `--tracking-normal` to em (spec §4.3).
function resolveTypography(root: RawBlock, notes: string[]): ResolvedTypography {
  const family = (css: string, fallback: string): string => {
    const value = root.vars[css];
    if (value === undefined) {
      notes.push(`--${css} absent; defaulted to the platform '${fallback}' family.`);
      return fallback;
    }
    return extractFamily(value);
  };
  const tracking = root.vars['tracking-normal'];
  return {
    sans: family('font-sans', DEFAULT_FONT.sans),
    serif: family('font-serif', DEFAULT_FONT.serif),
    mono: family('font-mono', DEFAULT_FONT.mono),
    tracking: tracking === undefined ? 0 : resolveTracking(tracking, notes),
  };
}

/// Note a non-default `--spacing` (spec §4.3 "knowing drop"): flutterwindcss's
/// spacing scale is a fixed `1 unit = 4px`, so a non-4px `--spacing` is dropped —
/// but reported, never silently lost.
function noteSpacing(root: RawBlock, notes: string[]): void {
  const value = root.vars.spacing;
  if (value === undefined) return;
  const px = lengthToPx(value, 'spacing');
  if (px !== 4) {
    notes.push(
      `--spacing "${value}" (${px}px) ≠ the fixed 4px base unit; dropped ` +
        '(flutterwindcss spacing is context-free, 1 unit = 4px).',
    );
  }
}

/// Resolve a parsed [RawTheme] into a [ResolvedTheme] (spec §3, §4). Radius,
/// shadows, and typography are theme-level and read from `:root` (identical in
/// `.dark` for every tweakcn export). May throw on a missing required color
/// (the 32-color hard gate, spec §3) — the UI surfaces it.
export function resolveTheme(raw: RawTheme, mode: ConversionMode = 'faithful'): ResolvedTheme {
  const notes: string[] = [];
  const light = resolveColors(raw.root, mode, 'light', notes);
  const dark = resolveColors(raw.dark, mode, 'dark', notes);
  const radii = resolveRadii(raw.root, notes);
  const shadows = resolveShadows(raw.root, mode, notes);
  const typography = resolveTypography(raw.root, notes);
  noteSpacing(raw.root, notes);
  return {
    light,
    dark,
    radii,
    shadows,
    typography,
    meta: {
      conversion: mode,
      droppedVars: raw.unknownVars,
      notes: [...new Set(notes)],
    },
  };
}

// Re-exported for tests and any consumer that wants the engine's default scale.
export { DEFAULT_SHADOWS, extractFamily };

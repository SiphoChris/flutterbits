import type { Rgba8, ConversionMode } from './types';
import { alphaTo8, channelTo8, clamp01, requireFinite } from './srgb';
import { oklchToRgb01 } from './oklch';

/// Split the inside of a `fn(...)` color into its components, supporting both
/// CSS comma syntax (`a, b, c`) and modern space syntax with optional
/// slash-alpha (`a b c / d`). Returns the 3 main components and an optional
/// 4th alpha token.
function splitComponents(inside: string): { parts: string[]; alpha?: string } {
  let main = inside.trim();
  let alpha: string | undefined;
  const slash = main.indexOf('/');
  if (slash !== -1) {
    alpha = main.slice(slash + 1).trim();
    main = main.slice(0, slash).trim();
  }
  const parts = main.split(/[\s,]+/).filter((s) => s.length > 0);
  if (alpha === undefined && parts.length === 4) {
    alpha = parts.pop();
  }
  return { parts, alpha };
}

/// Parse a number that may be a percentage (`50%` → 0.5) or a plain number.
/// Throws (via [requireFinite]) on a non-numeric token like `foo` or `b%`.
function parseMaybePercent(token: string, source: string): number {
  const raw = token.endsWith('%') ? parseFloat(token) / 100 : parseFloat(token);
  return requireFinite(raw, `component "${token}"`, source);
}

/// Parse a CSS alpha token (`0.5` or `50%`) to [0,1]; undefined → 1 (opaque).
function parseAlpha(token: string | undefined, source: string): number {
  if (token === undefined) return 1;
  return parseMaybePercent(token, source);
}

/// Parse `#rgb`, `#rgba`, `#rrggbb`, or `#rrggbbaa`.
export function parseHex(value: string): Rgba8 {
  let hex = value.trim().replace(/^#/, '');
  if (hex.length === 3 || hex.length === 4) {
    hex = hex
      .split('')
      .map((c) => c + c)
      .join('');
  }
  if (hex.length !== 6 && hex.length !== 8) {
    throw new Error(`Invalid hex color: ${value}`);
  }
  // `parseInt` is lenient — `parseInt('1g', 16)` is `1` and `parseInt('xy', 16)`
  // is `NaN`, so a non-hex digit would silently truncate or poison a channel.
  // Reject anything that isn't a pure hex digit before parsing.
  if (!/^[0-9a-fA-F]+$/.test(hex)) {
    throw new Error(`Invalid hex color: ${value}`);
  }
  const r = parseInt(hex.slice(0, 2), 16);
  const g = parseInt(hex.slice(2, 4), 16);
  const b = parseInt(hex.slice(4, 6), 16);
  const a = hex.length === 8 ? parseInt(hex.slice(6, 8), 16) : 255;
  return { r, g, b, a };
}

/// Parse `rgb()`/`rgba()`. Channels may be 0–255 or percentages.
export function parseRgb(value: string): Rgba8 {
  const inside = value.trim().replace(/^rgba?\(/, '').replace(/\)$/, '');
  const { parts, alpha } = splitComponents(inside);
  if (parts.length !== 3) throw new Error(`Invalid rgb color: ${value}`);
  // Numeric channels are 0–255; route BOTH the percent and numeric paths through
  // clamp+round so an out-of-range channel like `rgb(300 -5 0)` is clamped to a
  // valid byte (otherwise `300` would emit the 3-char garbage hex `12C`) and a
  // non-numeric token throws via [requireFinite] rather than leaking `NaN`.
  const ch = (t: string) =>
    t.endsWith('%')
      ? channelTo8(requireFinite(parseFloat(t) / 100, `component "${t}"`, value))
      : Math.round(clamp01(requireFinite(parseFloat(t), `component "${t}"`, value) / 255) * 255);
  return {
    r: ch(parts[0]),
    g: ch(parts[1]),
    b: ch(parts[2]),
    a: alphaTo8(parseAlpha(alpha, value)),
  };
}

/// Convert HSL (h in degrees, s and l in [0,1]) to gamma-space sRGB in [0,1].
function hslToRgb01(h: number, s: number, l: number): { r: number; g: number; b: number } {
  const hn = (((h % 360) + 360) % 360) / 360;
  if (s === 0) return { r: l, g: l, b: l };
  const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
  const p = 2 * l - q;
  const hue2rgb = (t: number): number => {
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
    return p;
  };
  return { r: hue2rgb(hn + 1 / 3), g: hue2rgb(hn), b: hue2rgb(hn - 1 / 3) };
}

/// Parse `hsl()`/`hsla()`. Hue is degrees; saturation and lightness are %.
export function parseHsl(value: string): Rgba8 {
  const inside = value.trim().replace(/^hsla?\(/, '').replace(/\)$/, '');
  const { parts, alpha } = splitComponents(inside);
  if (parts.length !== 3) throw new Error(`Invalid hsl color: ${value}`);
  const h = requireFinite(parseFloat(parts[0]), `hue "${parts[0]}"`, value);
  const s = parseMaybePercent(parts[1], value);
  const l = parseMaybePercent(parts[2], value);
  const { r, g, b } = hslToRgb01(h, s, l);
  return {
    r: channelTo8(r),
    g: channelTo8(g),
    b: channelTo8(b),
    a: alphaTo8(parseAlpha(alpha, value)),
  };
}

/// Parse `oklch(L C h)` / `oklch(L C h / a)`. L may be unit ([0,1]) or percent;
/// C is a number; h is degrees. `mode` selects faithful-clip vs perceptual.
export function parseOklch(value: string, mode: ConversionMode): Rgba8 {
  const inside = value.trim().replace(/^oklch\(/, '').replace(/\)$/, '');
  const { parts, alpha } = splitComponents(inside);
  if (parts.length !== 3) throw new Error(`Invalid oklch color: ${value}`);
  const L = parts[0] === 'none' ? 0 : parseMaybePercent(parts[0], value);
  const C =
    parts[1] === 'none' ? 0 : requireFinite(parseFloat(parts[1]), `chroma "${parts[1]}"`, value);
  const h =
    parts[2] === 'none' ? 0 : requireFinite(parseFloat(parts[2]), `hue "${parts[2]}"`, value);
  const { r, g, b } = oklchToRgb01(L, C, h, mode);
  return {
    r: channelTo8(r),
    g: channelTo8(g),
    b: channelTo8(b),
    a: alphaTo8(parseAlpha(alpha, value)),
  };
}

/// Parse any supported CSS color string — `#hex`, `rgb()/rgba()`, `hsl()/hsla()`,
/// or `oklch()` — into an [Rgba8]. `mode` selects the OKLCH out-of-gamut policy
/// (only affects `oklch()` inputs). Throws on an unrecognized format (e.g. a
/// bare Tailwind-v3 `H S% L%` triple or a named color), which the caller (G2)
/// surfaces as a clear error.
export function parseCssColor(value: string, mode: ConversionMode = 'faithful'): Rgba8 {
  const v = value.trim();
  if (v.startsWith('#')) return parseHex(v);
  const lower = v.toLowerCase();
  if (lower.startsWith('oklch(')) return parseOklch(v, mode);
  if (lower.startsWith('hsl(') || lower.startsWith('hsla(')) return parseHsl(v);
  if (lower.startsWith('rgb(') || lower.startsWith('rgba(')) return parseRgb(v);
  throw new Error(`Unrecognized color format: "${value}". Expected hex, rgb(), hsl(), or oklch().`);
}

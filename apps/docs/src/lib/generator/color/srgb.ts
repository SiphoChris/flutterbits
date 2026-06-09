import type { Rgba8 } from './types';

/// Clamp a number to the [0,1] range.
export function clamp01(x: number): number {
  if (x < 0) return 0;
  if (x > 1) return 1;
  return x;
}

/// Gamma-encode a linear-sRGB channel ([0,1] → [0,1]) per the sRGB transfer
/// function (IEC 61966-2-1): linear ≤ 0.0031308 → ×12.92, else the power curve.
export function linearToSrgb(x: number): number {
  return x <= 0.0031308 ? 12.92 * x : 1.055 * Math.pow(x, 1 / 2.4) - 0.055;
}

/// Quantize a gamma-space sRGB channel ([0,1], possibly out of range) to an
/// 8-bit value: clamp to [0,1] (the faithful gamut-clip) then round to nearest.
export function channelTo8(x01: number): number {
  return Math.round(clamp01(x01) * 255);
}

/// Quantize an alpha ([0,1]) to an 8-bit value, round to nearest.
export function alphaTo8(a01: number): number {
  return Math.round(clamp01(a01) * 255);
}

/// Format an [Rgba8] as an 8-digit uppercase `AARRGGBB` hex string.
export function rgba8ToArgbHex(c: Rgba8): string {
  const h = (n: number) => n.toString(16).toUpperCase().padStart(2, '0');
  return `${h(c.a)}${h(c.r)}${h(c.g)}${h(c.b)}`;
}

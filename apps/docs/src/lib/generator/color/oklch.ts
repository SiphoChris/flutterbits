import type { ConversionMode } from './types';
import { clamp01, linearToSrgb } from './srgb';

/// OKLCH → linear sRGB. L is [0,1] lightness, C chroma, h hue in degrees.
/// Returns linear-sRGB channels that may fall OUTSIDE [0,1] (out of gamut).
function oklchToLinearSrgb(L: number, C: number, h: number): { r: number; g: number; b: number } {
  const hr = (h * Math.PI) / 180;
  const a = C * Math.cos(hr);
  const b = C * Math.sin(hr);

  // OKLab → l'm's' (inverse M2)
  const l_ = L + 0.3963377774 * a + 0.2158037573 * b;
  const m_ = L - 0.1055613458 * a - 0.0638541728 * b;
  const s_ = L - 0.0894841775 * a - 1.291485548 * b;

  // cube
  const l = l_ * l_ * l_;
  const m = m_ * m_ * m_;
  const s = s_ * s_ * s_;

  // LMS → linear sRGB (inverse M1)
  return {
    r: 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    g: -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    b: -0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s,
  };
}

/// True if all three linear-sRGB channels are within [0,1] (within a tiny
/// epsilon for floating-point slack).
function inGamut(lin: { r: number; g: number; b: number }): boolean {
  const eps = 1e-6;
  return (
    lin.r >= -eps && lin.r <= 1 + eps &&
    lin.g >= -eps && lin.g <= 1 + eps &&
    lin.b >= -eps && lin.b <= 1 + eps
  );
}

/// Largest chroma ≤ the input chroma whose color is in sRGB gamut, found by
/// bisection (hue + lightness preserved). Used by the perceptual mode.
export function maxInGamutChroma(L: number, C: number, h: number): number {
  if (inGamut(oklchToLinearSrgb(L, C, h))) return C;
  let lo = 0;
  let hi = C;
  for (let i = 0; i < 24; i++) {
    const mid = (lo + hi) / 2;
    if (inGamut(oklchToLinearSrgb(L, mid, h))) lo = mid;
    else hi = mid;
  }
  return lo;
}

/// OKLCH → gamma-space sRGB in [0,1].
/// - `faithful` (default): convert then gamut-CLIP (clamp each channel to
///   [0,1]) so the result matches Tailwind's published hex by construction.
/// - `perceptual`: reduce chroma (hue-preserving) until in gamut, then convert.
export function oklchToRgb01(
  L: number,
  C: number,
  h: number,
  mode: ConversionMode,
): { r: number; g: number; b: number } {
  const chroma = mode === 'perceptual' ? maxInGamutChroma(L, C, h) : C;
  const lin = oklchToLinearSrgb(L, chroma, h);
  return {
    r: clamp01(linearToSrgb(lin.r)),
    g: clamp01(linearToSrgb(lin.g)),
    b: clamp01(linearToSrgb(lin.b)),
  };
}

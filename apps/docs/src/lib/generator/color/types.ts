/// An 8-bit sRGB color. Each channel is an integer 0–255; `a` defaults to 255
/// (opaque). This is the generator's normalized color value — the emit stage
/// (G3) renders it as a Flutter `Color(0xAARRGGBB)`.
export interface Rgba8 {
  r: number;
  g: number;
  b: number;
  a: number;
}

/// OKLCH → sRGB out-of-gamut policy.
/// - `faithful` (default): gamut-CLIP the channels to [0,1] so output matches
///   Tailwind's published hex by construction (spec §2.1).
/// - `perceptual`: hue-preserving chroma reduction for out-of-gamut colors.
export type ConversionMode = 'faithful' | 'perceptual';

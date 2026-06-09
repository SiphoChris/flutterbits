# Generator G1 — Color Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the pure-TS color core of the tweakcn→`theme.dart` generator: parse any of the four CSS color formats (`hex`, `rgb()`, `hsl()`, `oklch()`) — with alpha slash-syntax — into an 8-bit sRGB color, using a hand-rolled OKLCH→sRGB pipeline with a faithful-clip default and an opt-in perceptual gamut-map.

**Architecture:** A self-contained module at `apps/docs/src/lib/generator/color/`, pure functions, no runtime deps. The OKLCH path is `oklch → OKLab → l'm's' → cube → linear sRGB → gamma-encode → sRGB`, then either clip (default) or chroma-reduce (perceptual). Hex/rgb/hsl parse directly to gamma-space sRGB. The public entry is `parseCssColor(value, mode)` → `Rgba8`. Validated by per-format vectors, the **four-format convergence** oracle (the same Claude-theme colors in all four formats must converge), and out-of-gamut clip-vs-map behavior. This is spec §2.1 + §8 (G1).

**Tech Stack:** TypeScript 6 (strict, ESM, `moduleResolution: bundler`), Vitest (added here — first test runner in `apps/docs`), pnpm 11, Node 24.

**Spec:** `docs/superpowers/specs/2026-06-08-tweakcn-theme-generator-design.md` §2.1, §8. **Branch:** `feat/generator-g1-color` off `main` (already created). All tasks commit here; PR after the final task.

---

## File Structure

```
apps/docs/
  vitest.config.ts                              # Task 1 — test runner config
  package.json                                  # Task 1 — add vitest devDep + "test" script
  src/lib/generator/color/
    types.ts                                    # Task 2 — Rgba8, ConversionMode
    srgb.ts                                      # Task 2 — gamma encode, clamp, 8-bit quantize, ARGB hex
    srgb.test.ts                                 # Task 2
    parse.ts                                     # Tasks 3,4,6 — format detect + hex/rgb/hsl/oklch parsers + parseCssColor
    parse.test.ts                                # Tasks 3,4,6 — per-format + error vectors
    oklch.ts                                     # Tasks 4,5 — oklch→sRGB (faithful) + gamut-map (perceptual)
    oklch.test.ts                                # Tasks 4,5
    convergence.test.ts                          # Task 5 — four-format convergence + out-of-gamut clip-vs-map
    index.ts                                     # Task 6 — barrel
```

**Color representation:** `Rgba8 = { r, g, b, a }`, each an integer **0–255** (a defaults to 255 = opaque). The emit stage (G3) formats this as `Color(0xAARRGGBB)`; G1 stops at `Rgba8` plus a `rgba8ToArgbHex` helper for assertions.

**Units of alpha→byte:** **round-to-nearest** via `Math.round` (verified: `0.05·255=12.75→13`, `0.10·255=25.5→26`, `0.25·255=63.75→64`, `0.15·255=38.25→38`).

---

## Task 1: Stand up Vitest

`apps/docs` has no test runner. Add Vitest (TS-native, ESM, zero-config — justified: G1 is the first generator code and needs unit tests; dev-only dependency).

**Files:**
- Modify: `apps/docs/package.json`
- Create: `apps/docs/vitest.config.ts`
- Create: `apps/docs/src/lib/generator/color/smoke.test.ts` (temporary, deleted at end of task)

- [ ] **Step 1: Install Vitest**

Run: `cd apps/docs && pnpm add -D vitest`
Expected: `vitest` appears in `devDependencies`; pnpm lockfile updates; no error.

- [ ] **Step 2: Add the test script**

In `apps/docs/package.json`, add to `"scripts"` (keep existing scripts):

```json
    "test": "vitest run",
    "test:watch": "vitest"
```

- [ ] **Step 3: Create the Vitest config**

Create `apps/docs/vitest.config.ts`:

```ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: ['src/**/*.test.ts'],
    environment: 'node',
  },
});
```

- [ ] **Step 4: Add a temporary smoke test and verify the runner works**

Create `apps/docs/src/lib/generator/color/smoke.test.ts`:

```ts
import { describe, it, expect } from 'vitest';

describe('vitest', () => {
  it('runs', () => {
    expect(1 + 1).toBe(2);
  });
});
```

Run: `cd apps/docs && pnpm test`
Expected: PASS — 1 test passed.

- [ ] **Step 5: Delete the smoke test**

Run: `rm apps/docs/src/lib/generator/color/smoke.test.ts`

- [ ] **Step 6: Commit**

```bash
git add apps/docs/package.json apps/docs/pnpm-lock.yaml apps/docs/vitest.config.ts
git commit -m "chore(docs): add vitest test runner for the generator"
```

---

## Task 2: Types + sRGB helpers

**Files:**
- Create: `apps/docs/src/lib/generator/color/types.ts`
- Create: `apps/docs/src/lib/generator/color/srgb.ts`
- Create: `apps/docs/src/lib/generator/color/srgb.test.ts`

- [ ] **Step 1: Write the failing test**

Create `apps/docs/src/lib/generator/color/srgb.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { clamp01, linearToSrgb, channelTo8, alphaTo8, rgba8ToArgbHex } from './srgb';

describe('srgb helpers', () => {
  it('clamp01 clamps to [0,1]', () => {
    expect(clamp01(-0.2)).toBe(0);
    expect(clamp01(0.5)).toBe(0.5);
    expect(clamp01(1.4)).toBe(1);
  });

  it('linearToSrgb matches the piecewise gamma curve at known points', () => {
    expect(linearToSrgb(0)).toBeCloseTo(0, 12);
    expect(linearToSrgb(1)).toBeCloseTo(1, 12);
    // linear 0.0031308 is the breakpoint; below it the curve is 12.92*x
    expect(linearToSrgb(0.001)).toBeCloseTo(0.01292, 9);
    // a mid value through the power segment
    expect(linearToSrgb(0.5)).toBeCloseTo(0.735356, 5);
  });

  it('channelTo8 clamps then rounds to nearest', () => {
    expect(channelTo8(0)).toBe(0);
    expect(channelTo8(1)).toBe(255);
    expect(channelTo8(1.5)).toBe(255); // clamp
    expect(channelTo8(-0.1)).toBe(0); // clamp
    expect(channelTo8(201 / 255)).toBe(201);
  });

  it('alphaTo8 rounds to nearest (verified shadow alphas)', () => {
    expect(alphaTo8(0.05)).toBe(13); // 12.75 -> 13
    expect(alphaTo8(0.1)).toBe(26); // 25.5 -> 26
    expect(alphaTo8(0.25)).toBe(64); // 63.75 -> 64
    expect(alphaTo8(0.15)).toBe(38); // 38.25 -> 38
    expect(alphaTo8(1)).toBe(255);
  });

  it('rgba8ToArgbHex formats AARRGGBB uppercase', () => {
    expect(rgba8ToArgbHex({ r: 201, g: 100, b: 66, a: 255 })).toBe('FFC96442');
    expect(rgba8ToArgbHex({ r: 0, g: 0, b: 0, a: 13 })).toBe('0D000000');
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd apps/docs && pnpm test src/lib/generator/color/srgb.test.ts`
Expected: FAIL — cannot resolve `./srgb`.

- [ ] **Step 3: Create the types**

Create `apps/docs/src/lib/generator/color/types.ts`:

```ts
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
```

- [ ] **Step 4: Create the sRGB helpers**

Create `apps/docs/src/lib/generator/color/srgb.ts`:

```ts
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
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd apps/docs && pnpm test src/lib/generator/color/srgb.test.ts`
Expected: PASS (5 tests).

- [ ] **Step 6: Commit**

```bash
git add apps/docs/src/lib/generator/color/types.ts apps/docs/src/lib/generator/color/srgb.ts apps/docs/src/lib/generator/color/srgb.test.ts
git commit -m "feat(generator): color types + sRGB quantize/gamma helpers"
```

---

## Task 3: hex / rgb / hsl parsers

**Files:**
- Create: `apps/docs/src/lib/generator/color/parse.ts`
- Create: `apps/docs/src/lib/generator/color/parse.test.ts`

- [ ] **Step 1: Write the failing test**

Create `apps/docs/src/lib/generator/color/parse.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { parseHex, parseRgb, parseHsl } from './parse';

describe('parseHex', () => {
  it('parses 6-digit', () => {
    expect(parseHex('#c96442')).toEqual({ r: 201, g: 100, b: 66, a: 255 });
  });
  it('parses 3-digit (shorthand)', () => {
    expect(parseHex('#fff')).toEqual({ r: 255, g: 255, b: 255, a: 255 });
  });
  it('parses 8-digit with alpha', () => {
    expect(parseHex('#00000080')).toEqual({ r: 0, g: 0, b: 0, a: 128 });
  });
  it('parses 4-digit shorthand with alpha', () => {
    expect(parseHex('#0000')).toEqual({ r: 0, g: 0, b: 0, a: 0 });
  });
});

describe('parseRgb', () => {
  it('parses comma syntax', () => {
    expect(parseRgb('rgb(201, 100, 66)')).toEqual({ r: 201, g: 100, b: 66, a: 255 });
  });
  it('parses space syntax', () => {
    expect(parseRgb('rgb(201 100 66)')).toEqual({ r: 201, g: 100, b: 66, a: 255 });
  });
  it('parses alpha slash-syntax (round-to-nearest)', () => {
    expect(parseRgb('rgb(0 0 0 / 0.5)')).toEqual({ r: 0, g: 0, b: 0, a: 128 });
  });
  it('parses rgba() with comma alpha', () => {
    expect(parseRgb('rgba(29,161,242,0.15)')).toEqual({ r: 29, g: 161, b: 242, a: 38 });
  });
});

describe('parseHsl', () => {
  it('parses white', () => {
    expect(parseHsl('hsl(0 0% 100%)')).toEqual({ r: 255, g: 255, b: 255, a: 255 });
  });
  it('parses black with alpha', () => {
    expect(parseHsl('hsl(0 0% 0% / 0.05)')).toEqual({ r: 0, g: 0, b: 0, a: 13 });
  });
  it('converts the Claude primary HSL to its sRGB bytes', () => {
    // tweakcn hsl for #c96442; must round-trip to 201,100,66
    expect(parseHsl('hsl(15.1111 55.5556% 52.3529%)')).toEqual({ r: 201, g: 100, b: 66, a: 255 });
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd apps/docs && pnpm test src/lib/generator/color/parse.test.ts`
Expected: FAIL — cannot resolve `./parse`.

- [ ] **Step 3: Implement the hex/rgb/hsl parsers**

Create `apps/docs/src/lib/generator/color/parse.ts`:

```ts
import type { Rgba8 } from './types';
import { alphaTo8, channelTo8 } from './srgb';

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
  // comma-syntax rgba()/hsla() carries alpha as the 4th part (no slash).
  if (alpha === undefined && parts.length === 4) {
    alpha = parts.pop();
  }
  return { parts, alpha };
}

/// Parse a number that may be a percentage (`50%` → 0.5) or a plain number.
function parseMaybePercent(token: string): number {
  return token.endsWith('%') ? parseFloat(token) / 100 : parseFloat(token);
}

/// Parse a CSS alpha token (`0.5` or `50%`) to [0,1]; undefined → 1 (opaque).
function parseAlpha(token: string | undefined): number {
  if (token === undefined) return 1;
  return parseMaybePercent(token);
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
  const ch = (t: string) => (t.endsWith('%') ? channelTo8(parseFloat(t) / 100) : Math.round(parseFloat(t)));
  return { r: ch(parts[0]), g: ch(parts[1]), b: ch(parts[2]), a: alphaTo8(parseAlpha(alpha)) };
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
  const h = parseFloat(parts[0]);
  const s = parseMaybePercent(parts[1]);
  const l = parseMaybePercent(parts[2]);
  const { r, g, b } = hslToRgb01(h, s, l);
  return { r: channelTo8(r), g: channelTo8(g), b: channelTo8(b), a: alphaTo8(parseAlpha(alpha)) };
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd apps/docs && pnpm test src/lib/generator/color/parse.test.ts`
Expected: PASS (11 tests). If the Claude-primary HSL case is off by 1 on a single channel, that is a tweakcn HSL-rounding artifact — record it and relax that one channel to `toBeCloseTo(value, -0.5)`-style ±1; do **not** change the conversion (hex is ground truth). The expectation is exact.

- [ ] **Step 5: Commit**

```bash
git add apps/docs/src/lib/generator/color/parse.ts apps/docs/src/lib/generator/color/parse.test.ts
git commit -m "feat(generator): hex/rgb/hsl color parsers with alpha slash-syntax"
```

---

## Task 4: OKLCH → sRGB (faithful-clip)

**Files:**
- Create: `apps/docs/src/lib/generator/color/oklch.ts`
- Create: `apps/docs/src/lib/generator/color/oklch.test.ts`

- [ ] **Step 1: Write the failing test**

Create `apps/docs/src/lib/generator/color/oklch.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { oklchToRgb01 } from './oklch';
import { channelTo8 } from './srgb';

function to8(L: number, C: number, h: number) {
  const { r, g, b } = oklchToRgb01(L, C, h, 'faithful');
  return { r: channelTo8(r), g: channelTo8(g), b: channelTo8(b) };
}

describe('oklchToRgb01 (faithful)', () => {
  it('white: oklch(1 0 0) -> 255,255,255', () => {
    expect(to8(1, 0, 0)).toEqual({ r: 255, g: 255, b: 255 });
  });
  it('black: oklch(0 0 0) -> 0,0,0', () => {
    expect(to8(0, 0, 0)).toEqual({ r: 0, g: 0, b: 0 });
  });
  it('Claude primary oklch within ±1 of #c96442 (201,100,66)', () => {
    const { r, g, b } = to8(0.6171, 0.1375, 39.0427);
    expect(Math.abs(r - 201)).toBeLessThanOrEqual(1);
    expect(Math.abs(g - 100)).toBeLessThanOrEqual(1);
    expect(Math.abs(b - 66)).toBeLessThanOrEqual(1);
  });
  it('Claude dark destructive oklch within ±1 of #ef4444 (239,68,68)', () => {
    const { r, g, b } = to8(0.6368, 0.2078, 25.3313);
    expect(Math.abs(r - 239)).toBeLessThanOrEqual(1);
    expect(Math.abs(g - 68)).toBeLessThanOrEqual(1);
    expect(Math.abs(b - 68)).toBeLessThanOrEqual(1);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd apps/docs && pnpm test src/lib/generator/color/oklch.test.ts`
Expected: FAIL — cannot resolve `./oklch`.

- [ ] **Step 3: Implement the OKLCH→linear→sRGB pipeline (faithful)**

Create `apps/docs/src/lib/generator/color/oklch.ts`. The matrix coefficients are Björn Ottosson's published OKLab values (verified against bottosson.github.io/posts/oklab):

```ts
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
function maxInGamutChroma(L: number, C: number, h: number): number {
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
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd apps/docs && pnpm test src/lib/generator/color/oklch.test.ts`
Expected: PASS (4 tests). The ±1 tolerance absorbs float-vs-culori rounding; white/black are exact.

- [ ] **Step 5: Wire OKLCH into the format dispatch**

Append to `apps/docs/src/lib/generator/color/parse.ts` (add the import at the top, then the function):

```ts
import { oklchToRgb01 } from './oklch';
import type { ConversionMode } from './types';
```

```ts
/// Parse `oklch(L C h)` / `oklch(L C h / a)`. L may be unit ([0,1]) or percent;
/// C is a number; h is degrees. `mode` selects faithful-clip vs perceptual.
export function parseOklch(value: string, mode: ConversionMode): Rgba8 {
  const inside = value.trim().replace(/^oklch\(/, '').replace(/\)$/, '');
  const { parts, alpha } = splitComponents(inside);
  if (parts.length !== 3) throw new Error(`Invalid oklch color: ${value}`);
  // Lightness: percent → [0,1]; "none" → 0.
  const L = parts[0] === 'none' ? 0 : parseMaybePercent(parts[0]);
  const C = parts[1] === 'none' ? 0 : parseFloat(parts[1]);
  const h = parts[2] === 'none' ? 0 : parseFloat(parts[2]);
  const { r, g, b } = oklchToRgb01(L, C, h, mode);
  return { r: channelTo8(r), g: channelTo8(g), b: channelTo8(b), a: alphaTo8(parseAlpha(alpha)) };
}
```

- [ ] **Step 6: Add an OKLCH parser test (percent L + alpha) and verify**

Append to `apps/docs/src/lib/generator/color/parse.test.ts` (add `parseOklch` to the existing import from `./parse`):

```ts
import { parseOklch } from './parse';

describe('parseOklch', () => {
  it('parses unit lightness', () => {
    expect(parseOklch('oklch(1 0 0)', 'faithful')).toEqual({ r: 255, g: 255, b: 255, a: 255 });
  });
  it('treats percent lightness the same as unit', () => {
    const unit = parseOklch('oklch(0.6171 0.1375 39.0427)', 'faithful');
    const pct = parseOklch('oklch(61.71% 0.1375 39.0427)', 'faithful');
    expect(pct).toEqual(unit);
  });
  it('parses alpha slash-syntax (round-to-nearest)', () => {
    expect(parseOklch('oklch(0 0 0 / 0.1)', 'faithful')).toEqual({ r: 0, g: 0, b: 0, a: 26 });
  });
});
```

Run: `cd apps/docs && pnpm test src/lib/generator/color/parse.test.ts`
Expected: PASS (14 tests).

- [ ] **Step 7: Commit**

```bash
git add apps/docs/src/lib/generator/color/oklch.ts apps/docs/src/lib/generator/color/oklch.test.ts apps/docs/src/lib/generator/color/parse.ts apps/docs/src/lib/generator/color/parse.test.ts
git commit -m "feat(generator): hand-rolled OKLCH->sRGB (faithful-clip) + oklch parser"
```

---

## Task 5: Perceptual gamut-map + four-format convergence + out-of-gamut

**Files:**
- Modify: `apps/docs/src/lib/generator/color/oklch.test.ts`
- Create: `apps/docs/src/lib/generator/color/convergence.test.ts`

- [ ] **Step 1: Write the failing tests**

Append to `apps/docs/src/lib/generator/color/oklch.test.ts`:

```ts
describe('oklchToRgb01 gamut handling', () => {
  // An obviously out-of-gamut request: very high chroma at mid lightness.
  const OOG = { L: 0.7, C: 0.3, h: 25 };

  it('faithful and perceptual agree for an in-gamut color', () => {
    const f = oklchToRgb01(0.6171, 0.1375, 39.0427, 'faithful');
    const p = oklchToRgb01(0.6171, 0.1375, 39.0427, 'perceptual');
    expect(p).toEqual(f);
  });

  it('faithful clips an out-of-gamut color (some channel pinned to 0 or 1)', () => {
    const f = oklchToRgb01(OOG.L, OOG.C, OOG.h, 'faithful');
    const pinned = [f.r, f.g, f.b].some((c) => c === 0 || c === 1);
    expect(pinned).toBe(true);
  });

  it('perceptual differs from faithful for an out-of-gamut color', () => {
    const f = oklchToRgb01(OOG.L, OOG.C, OOG.h, 'faithful');
    const p = oklchToRgb01(OOG.L, OOG.C, OOG.h, 'perceptual');
    expect(p).not.toEqual(f);
  });
});
```

Create `apps/docs/src/lib/generator/color/convergence.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { parseCssColor } from './index';
import { rgba8ToArgbHex } from './srgb';
import type { Rgba8 } from './types';

// The same Claude-theme colors, expressed in all four export formats.
// `argb` is the ground-truth value (from the hex export → themes.dart).
const QUADS: { name: string; argb: string; hex: string; rgb: string; hsl: string; oklch: string }[] = [
  {
    name: 'background (light)',
    argb: 'FFFAF9F5',
    hex: '#faf9f5',
    rgb: 'rgb(250, 249, 245)',
    hsl: 'hsl(48 33.3333% 97.0588%)',
    oklch: 'oklch(0.9818 0.0054 95.0986)',
  },
  {
    name: 'primary (light)',
    argb: 'FFC96442',
    hex: '#c96442',
    rgb: 'rgb(201, 100, 66)',
    hsl: 'hsl(15.1111 55.5556% 52.3529%)',
    oklch: 'oklch(0.6171 0.1375 39.0427)',
  },
  {
    name: 'destructive (dark)',
    argb: 'FFEF4444',
    hex: '#ef4444',
    rgb: 'rgb(239, 68, 68)',
    hsl: 'hsl(0 84.2365% 60.1961%)',
    oklch: 'oklch(0.6368 0.2078 25.3313)',
  },
];

function within1(a: Rgba8, hex: string): void {
  const exp = parseCssColor(hex, 'faithful');
  expect(Math.abs(a.r - exp.r)).toBeLessThanOrEqual(1);
  expect(Math.abs(a.g - exp.g)).toBeLessThanOrEqual(1);
  expect(Math.abs(a.b - exp.b)).toBeLessThanOrEqual(1);
  expect(a.a).toBe(exp.a);
}

describe('four-format convergence (B1 keystone)', () => {
  for (const q of QUADS) {
    it(`${q.name}: hex & rgb are byte-exact ground truth`, () => {
      expect(rgba8ToArgbHex(parseCssColor(q.hex, 'faithful'))).toBe(q.argb);
      expect(rgba8ToArgbHex(parseCssColor(q.rgb, 'faithful'))).toBe(q.argb);
    });
    it(`${q.name}: hsl & oklch converge within ±1`, () => {
      // hsl is expected exact in practice; oklch ±1 absorbs float-vs-culori
      // rounding. hex is ground truth.
      within1(parseCssColor(q.hsl, 'faithful'), q.hex);
      within1(parseCssColor(q.oklch, 'faithful'), q.hex);
    });
  }
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd apps/docs && pnpm test src/lib/generator/color/oklch.test.ts src/lib/generator/color/convergence.test.ts`
Expected: FAIL — `oklch.test.ts` already has `oklchToRgb01` (perceptual path exists from Task 4, so the gamut tests may already pass) but `convergence.test.ts` fails because `./index` does not exist yet. (The perceptual `maxInGamutChroma` was implemented in Task 4; these tests pin its behavior.)

- [ ] **Step 3: Create the barrel so `parseCssColor` resolves**

Create `apps/docs/src/lib/generator/color/index.ts`:

```ts
export type { Rgba8, ConversionMode } from './types';
export { rgba8ToArgbHex } from './srgb';
export { parseCssColor } from './parse';
```

- [ ] **Step 4: Add `parseCssColor` (format dispatch) to `parse.ts`**

Append to `apps/docs/src/lib/generator/color/parse.ts`:

```ts
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
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `cd apps/docs && pnpm test src/lib/generator/color/oklch.test.ts src/lib/generator/color/convergence.test.ts`
Expected: PASS. If a `within1` `hsl` channel is off by more than 1, that means the HSL fixture lost precision — investigate before relaxing; hex/rgb must stay byte-exact.

- [ ] **Step 6: Commit**

```bash
git add apps/docs/src/lib/generator/color/oklch.test.ts apps/docs/src/lib/generator/color/convergence.test.ts apps/docs/src/lib/generator/color/index.ts apps/docs/src/lib/generator/color/parse.ts
git commit -m "feat(generator): perceptual gamut-map + parseCssColor + four-format convergence tests"
```

---

## Task 6: Error handling, type-check, and final gate

**Files:**
- Modify: `apps/docs/src/lib/generator/color/parse.test.ts`

- [ ] **Step 1: Write the failing test (unrecognized-format rejection)**

Append to `apps/docs/src/lib/generator/color/parse.test.ts` (add `parseCssColor` to the import from `./parse`):

```ts
import { parseCssColor } from './parse';

describe('parseCssColor error handling', () => {
  it('throws on a bare Tailwind-v3 HSL triple (no wrapper)', () => {
    expect(() => parseCssColor('220 14% 95%')).toThrow(/Unrecognized color format/);
  });
  it('throws on a named color (unsupported)', () => {
    expect(() => parseCssColor('rebeccapurple')).toThrow(/Unrecognized color format/);
  });
  it('defaults to faithful mode', () => {
    expect(parseCssColor('#c96442')).toEqual({ r: 201, g: 100, b: 66, a: 255 });
  });
});
```

- [ ] **Step 2: Run the test to verify it passes**

Run: `cd apps/docs && pnpm test src/lib/generator/color/parse.test.ts`
Expected: PASS (the dispatch + error path from Task 5 already implements this; this task pins the behavior). All `parse.test.ts` cases green.

- [ ] **Step 3: Run the full generator test suite**

Run: `cd apps/docs && pnpm test`
Expected: PASS — all color tests across `srgb.test.ts`, `parse.test.ts`, `oklch.test.ts`, `convergence.test.ts`.

- [ ] **Step 4: Type-check (strict TS) and lint**

Run: `cd apps/docs && pnpm exec tsc --noEmit && pnpm run lint`
Expected: `tsc` reports no errors; `eslint` reports no errors for the new files. Fix any reported type/lint issue in the color module (e.g. add `import type` for type-only imports — the project sets `isolatedModules`). Do **not** introduce `any`.

- [ ] **Step 5: Commit**

```bash
git add apps/docs/src/lib/generator/color/parse.test.ts
git commit -m "test(generator): pin parseCssColor format-rejection + faithful default"
```

---

## Self-Review notes (already reconciled)

- **Spec §2.1 coverage:** four formats (hex/rgb/hsl/oklch) — Tasks 3,4; alpha slash-syntax — Tasks 3,4 (`splitComponents`); both OKLCH lightness forms — Task 4 Step 6 (`parseMaybePercent`); OKLCH→OKLab→LMS→linear→gamma→sRGB pipeline with verified coefficients — Task 4; faithful-clip default + opt-in perceptual chroma-reduction — Tasks 4,5; round-to-nearest alpha — Task 2.
- **Spec §8 coverage:** four-format convergence keystone (hex/rgb byte-exact, hsl/oklch ±1) — Task 5 `convergence.test.ts`; out-of-gamut clip-vs-map behavior — Task 5 `oklch.test.ts`; alpha-syntax + percent-vs-unit-L cases — Tasks 3,4. The exhaustive *whole-CSS-file* convergence (reading the `.css` fixtures) is **G2/G3** (needs the CSS parser); G1 proves the color core with representative real quadruples — noted, not silently dropped.
- **Type consistency:** `Rgba8 {r,g,b,a}` and `ConversionMode 'faithful'|'perceptual'` used identically across all files; `parseCssColor(value, mode='faithful')`, `oklchToRgb01(L,C,h,mode)`, `parseHex/parseRgb/parseHsl/parseOklch` names consistent between `parse.ts` and its tests.
- **No placeholders:** every step has complete code and an exact command.
- **Tolerance honesty:** hex/rgb asserted byte-exact (ground truth); hsl/oklch ±1 with rationale (float/rounding) — a recorded, justified tolerance (§12), re-checked at the emitter golden (G3) against `themes.dart`.
- **Scope:** G1 is the color core only — the CSS tokenizer, token mapping, radius/shadow/font handling, and the `theme.dart` emit are later modules (G2/G3).

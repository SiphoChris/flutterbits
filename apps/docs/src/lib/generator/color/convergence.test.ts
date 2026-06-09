import { describe, it, expect } from 'vitest';
import { parseCssColor } from './index';
import { rgba8ToArgbHex } from './srgb';
import type { Rgba8 } from './types';

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
    it(`${q.name}: hex, rgb & hsl are byte-exact ground truth`, () => {
      // hex/rgb/hsl are deterministic (no transcendental math), so they must
      // reproduce the ground-truth ARGB exactly — not merely within ±1.
      expect(rgba8ToArgbHex(parseCssColor(q.hex, 'faithful'))).toBe(q.argb);
      expect(rgba8ToArgbHex(parseCssColor(q.rgb, 'faithful'))).toBe(q.argb);
      expect(rgba8ToArgbHex(parseCssColor(q.hsl, 'faithful'))).toBe(q.argb);
    });
    it(`${q.name}: oklch converges within ±1`, () => {
      // oklch goes through libm pow/cos/sin, which can differ ~1 ULP across
      // platforms and flip a rounding boundary — hence ±1, not byte-exact.
      within1(parseCssColor(q.oklch, 'faithful'), q.hex);
    });
  }
});

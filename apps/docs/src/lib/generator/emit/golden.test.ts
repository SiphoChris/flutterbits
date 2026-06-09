import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { generateTheme, resolveTheme, toThemeJson } from './index';
import { parseTheme } from '../parse';
import type { ThemeJson } from '../types';
import {
  claudeExpectedLight,
  claudeExpectedDark,
  claudeExpectedRadii,
  claudeExpectedShadows,
  claudeExpectedTypography,
} from '../__fixtures__/claude-expected';

function fixture(format: 'hex' | 'rgb' | 'hsl' | 'oklch'): string {
  return readFileSync(new URL(`../__fixtures__/claude.${format}.css`, import.meta.url), 'utf8');
}

const FORMATS = ['hex', 'rgb', 'hsl', 'oklch'] as const;

/// `AARRGGBB` hex → integer channels.
function channels(hex: string): { a: number; r: number; g: number; b: number } {
  return {
    a: parseInt(hex.slice(0, 2), 16),
    r: parseInt(hex.slice(2, 4), 16),
    g: parseInt(hex.slice(4, 6), 16),
    b: parseInt(hex.slice(6, 8), 16),
  };
}

/// Assert two color maps converge: alpha + each channel within `tol`. `tol = 0`
/// is byte-exact (hex/rgb/hsl); `tol = 1` allows the documented oklch libm drift.
function expectColorsConverge(
  actual: Readonly<Record<string, string>>,
  expected: Readonly<Record<string, string>>,
  tol: number,
): void {
  for (const [field, exp] of Object.entries(expected)) {
    const a = channels(actual[field]);
    const e = channels(exp);
    expect(a.a, `${field} alpha`).toBe(e.a);
    for (const ch of ['r', 'g', 'b'] as const) {
      expect(Math.abs(a[ch] - e[ch]), `${field}.${ch}`).toBeLessThanOrEqual(tol);
    }
  }
}

describe('end-to-end golden — Claude theme, all four formats (§8)', () => {
  for (const fmt of FORMATS) {
    const json = toThemeJson(resolveTheme(parseTheme(fixture(fmt))));
    // hex/rgb/hsl are deterministic → byte-exact; oklch goes through libm → ±1.
    const tol = fmt === 'oklch' ? 1 : 0;

    describe(`claude.${fmt}.css`, () => {
      it(`32 light colors converge (tol ${tol})`, () => {
        expectColorsConverge(json.colors.light, claudeExpectedLight, tol);
      });
      it(`32 dark colors converge (tol ${tol})`, () => {
        expectColorsConverge(json.colors.dark, claudeExpectedDark, tol);
      });
      it('radii match (16 → 12/14/16/20)', () => {
        expect(json.radii).toEqual(claudeExpectedRadii);
        expect(json.radiusBase).toBe(16);
      });
      it('shadows match byte-exact (hsl in every export format)', () => {
        expect(json.shadows).toEqual(claudeExpectedShadows);
      });
      it('typography matches (Outfit / Georgia / Geist Mono, tracking 0)', () => {
        expect(json.typography).toEqual(claudeExpectedTypography);
      });
      it('a complete theme defaults/drops nothing (meta clean)', () => {
        expect(json.meta.conversion).toBe('faithful');
        expect(json.meta.droppedVars).toEqual([]);
        expect(json.meta.notes).toEqual([]);
      });
    });
  }
});

describe('end-to-end golden — ThemeJson schema (hex fixture)', () => {
  const json: ThemeJson = toThemeJson(resolveTheme(parseTheme(fixture('hex'))));

  it('has exactly the §4.4 top-level shape', () => {
    expect(Object.keys(json).sort()).toEqual(
      ['colors', 'meta', 'radii', 'radiusBase', 'shadows', 'typography'].sort(),
    );
  });
  it('carries all 32 colors per block', () => {
    expect(Object.keys(json.colors.light)).toHaveLength(32);
    expect(Object.keys(json.colors.dark)).toHaveLength(32);
  });
  it('matches the full transcribed bundle', () => {
    expect(json.colors.light).toEqual(claudeExpectedLight);
    expect(json.colors.dark).toEqual(claudeExpectedDark);
  });
});

describe('end-to-end — generateTheme produces both artifacts', () => {
  it('returns a ThemeJson and a non-empty Dart source for every format', () => {
    for (const fmt of FORMATS) {
      const { themeJson, dartSource } = generateTheme(fixture(fmt));
      expect(themeJson.radiusBase).toBe(16);
      expect(dartSource).toContain('const FwTokens lightTheme');
      expect(dartSource).toContain('const FwTokens darkTheme');
    }
  });
});

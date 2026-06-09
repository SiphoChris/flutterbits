import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { parseTheme } from './theme';
import { COLOR_VAR_NAMES } from '../types';

/// Load one of the committed four-format Claude fixtures (the real tweakcn export
/// of theme `cmdght103000n04lh3e2ae93r`, spec §8).
function fixture(format: 'hex' | 'rgb' | 'hsl' | 'oklch'): string {
  return readFileSync(new URL(`../__fixtures__/claude.${format}.css`, import.meta.url), 'utf8');
}

const FORMATS = ['hex', 'rgb', 'hsl', 'oklch'] as const;

describe('parseTheme — real four-format fixtures', () => {
  for (const fmt of FORMATS) {
    describe(`claude.${fmt}.css`, () => {
      const theme = parseTheme(fixture(fmt));

      it('extracts both :root and .dark blocks', () => {
        expect(Object.keys(theme.root.vars).length).toBeGreaterThan(0);
        expect(Object.keys(theme.dark.vars).length).toBeGreaterThan(0);
      });

      it('captures all 32 semantic colors in both blocks', () => {
        for (const name of COLOR_VAR_NAMES) {
          expect(theme.root.vars[name], `root missing ${name}`).toBeDefined();
          expect(theme.dark.vars[name], `dark missing ${name}`).toBeDefined();
        }
      });

      it('captures the seven named shadow slots verbatim (with commas intact)', () => {
        expect(theme.root.vars['shadow-2xs']).toBe('0 1px 3px 0px hsl(0 0% 0% / 0.05)');
        expect(theme.root.vars['shadow-sm']).toBe(
          '0 1px 3px 0px hsl(0 0% 0% / 0.10), 0 1px 2px -1px hsl(0 0% 0% / 0.10)',
        );
        expect(theme.root.vars['shadow-md']).toBe(
          '0 1px 3px 0px hsl(0 0% 0% / 0.10), 0 2px 4px -1px hsl(0 0% 0% / 0.10)',
        );
      });

      it('retains the per-axis shadow primitives and the unprefixed DEFAULT (record-don\'t-drop)', () => {
        // These are "known but ignored" by emit — but G2 must still record them.
        expect(theme.root.vars['shadow-x']).toBe('0');
        expect(theme.root.vars['shadow-blur']).toBe('3px');
        expect(theme.root.vars['shadow-opacity']).toBe('0.1');
        // The unprefixed DEFAULT shadow is present and distinct from --shadow-md.
        expect(theme.root.vars['shadow']).toBeDefined();
        expect(theme.root.vars['shadow']).not.toBe(theme.root.vars['shadow-md']);
      });

      it('captures non-color scalar tokens (radius, fonts, tracking, spacing)', () => {
        expect(theme.root.vars['radius']).toBe('1rem');
        expect(theme.root.vars['font-sans']).toBe('Outfit, sans-serif');
        expect(theme.root.vars['font-serif']).toBe(
          'ui-serif, Georgia, Cambria, "Times New Roman", Times, serif',
        );
        expect(theme.root.vars['tracking-normal']).toBe('0em');
        expect(theme.root.vars['spacing']).toBe('0.25rem');
      });

      it('ignores the @theme inline / @layer base / @import / @custom-variant at-rules', () => {
        // The @theme inline block re-declares --color-* / --radius-* as var()/calc()
        // indirection. None of those must leak into the read blocks.
        expect(theme.root.vars['color-background']).toBeUndefined();
        expect(theme.root.vars['radius-sm']).toBeUndefined();
        // .dark must be the rule block, NOT the value of any var.
        expect(theme.dark.vars['background']).toBeDefined();
      });

      it('reads .dark values, not :root values, into the dark block', () => {
        // Claude dark background differs from light; proves the right block was read
        // and the `@custom-variant dark (&:is(.dark *))` false match was avoided.
        expect(theme.dark.vars['background']).not.toBe(theme.root.vars['background']);
      });

      it('records no unknown vars for a clean tweakcn export', () => {
        expect(theme.unknownVars).toEqual([]);
      });
    });
  }
});

describe('parseTheme — preamble & false-match robustness', () => {
  it('does not treat `@custom-variant dark (&:is(.dark *))` as the .dark block', () => {
    const css = `
      @import "tailwindcss";
      @custom-variant dark (&:is(.dark *));
      :root { --background: oklch(1 0 0); }
      .dark { --background: oklch(0 0 0); }
    `;
    const theme = parseTheme(css);
    // If the false match had won, dark.background would be empty/garbage.
    expect(theme.dark.vars['background']).toBe('oklch(0 0 0)');
    expect(theme.root.vars['background']).toBe('oklch(1 0 0)');
  });

  it('absorbs the `@import` + `@custom-variant` preamble without misreading the selector', () => {
    const css = `@import "tailwindcss";\n@custom-variant dark (&:is(.dark *));\n:root{--radius:0.5rem;}\n.dark{--radius:0.5rem;}`;
    const theme = parseTheme(css);
    expect(theme.root.vars['radius']).toBe('0.5rem');
  });
});

describe('parseTheme — tolerant tokenizing', () => {
  it('tolerates messy whitespace and a missing trailing semicolon', () => {
    const css = `
      :root   {
            --background:    oklch(1 0 0)   ;
            --foreground: oklch(0 0 0)
      }
      .dark { --background: oklch(0 0 0); --foreground: oklch(1 0 0); }
    `;
    const theme = parseTheme(css);
    expect(theme.root.vars['background']).toBe('oklch(1 0 0)');
    expect(theme.root.vars['foreground']).toBe('oklch(0 0 0)');
  });

  it('strips block comments before tokenizing', () => {
    const css = `
      :root {
        /* brand */ --primary: oklch(0.62 0.13 39); /* trailing note */
      }
      .dark { --primary: oklch(0.67 0.13 39); }
    `;
    const theme = parseTheme(css);
    expect(theme.root.vars['primary']).toBe('oklch(0.62 0.13 39)');
  });

  it('preserves alpha slash-syntax in values verbatim (parsed later by color/)', () => {
    const css = `
      :root { --border: hsl(0 0% 0% / 0.05); }
      .dark { --border: oklch(1 0 0 / 10%); }
    `;
    const theme = parseTheme(css);
    expect(theme.root.vars['border']).toBe('hsl(0 0% 0% / 0.05)');
    expect(theme.dark.vars['border']).toBe('oklch(1 0 0 / 10%)');
  });
});

describe('parseTheme — recording (record-don\'t-drop)', () => {
  it('records vars outside the contract in unknownVars (sorted, de-duped across blocks)', () => {
    const css = `
      :root { --background: oklch(1 0 0); --brand-glow: #fff; --z-fizz: 3; }
      .dark { --background: oklch(0 0 0); --brand-glow: #000; }
    `;
    const theme = parseTheme(css);
    expect(theme.unknownVars).toEqual(['brand-glow', 'z-fizz']);
    // …but they are still retained verbatim, never silently discarded.
    expect(theme.root.vars['brand-glow']).toBe('#fff');
    expect(theme.dark.vars['brand-glow']).toBe('#000');
  });

  it('records token absence by omission (a missing token has no key)', () => {
    const css = `
      :root { --background: oklch(1 0 0); }
      .dark { --background: oklch(0 0 0); }
    `;
    const theme = parseTheme(css);
    // A colors-only-ish theme: fonts/shadows/tracking are simply absent, which is
    // how G3/G4 detect them to default-and-report.
    expect(theme.root.vars['font-sans']).toBeUndefined();
    expect(theme.root.vars['shadow-md']).toBeUndefined();
    expect(theme.root.vars['tracking-normal']).toBeUndefined();
  });
});

describe('parseTheme — Tailwind v3 rejection (descoped, must not misparse)', () => {
  it('rejects an @tailwind-directive (v3) input with a clear re-export message', () => {
    const css = `
      @tailwind base;
      @tailwind components;
      @tailwind utilities;
      @layer base {
        :root { --background: 0 0% 100%; }
        .dark { --background: 0 0% 0%; }
      }
    `;
    expect(() => parseTheme(css)).toThrow(/Tailwind v3/);
  });

  it('rejects bare `H S% L%` color triples (the v3 structural tell) even without @tailwind', () => {
    const css = `
      :root { --background: 0 0% 100%; --foreground: 0 0% 3.9%; }
      .dark { --background: 0 0% 3.9%; --foreground: 0 0% 98%; }
    `;
    expect(() => parseTheme(css)).toThrow(/Tailwind v3/);
  });
});

describe('parseTheme — malformed input errors loudly', () => {
  it('throws a clear error when no :root block is present', () => {
    expect(() => parseTheme('.dark { --background: oklch(0 0 0); }')).toThrow(/:root/);
  });

  it('throws a clear error when no .dark block is present', () => {
    expect(() => parseTheme(':root { --background: oklch(1 0 0); }')).toThrow(/\.dark/);
  });
});

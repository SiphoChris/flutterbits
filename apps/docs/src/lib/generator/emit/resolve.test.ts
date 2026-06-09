import { describe, it, expect } from 'vitest';
import { parseTheme } from '../parse';
import { resolveTheme } from './resolve';
import { rgba8ToArgbHex } from '../color';

/// Wrap CSS fragments into a minimal valid `:root`/`.dark` pair so `parseTheme`
/// accepts them. All 32 colors are injected unless the test overrides them.
const COLOR_BLOCK = `
  --background: oklch(1 0 0); --foreground: oklch(0 0 0);
  --card: oklch(1 0 0); --card-foreground: oklch(0 0 0);
  --popover: oklch(1 0 0); --popover-foreground: oklch(0 0 0);
  --primary: oklch(0.62 0.13 39); --primary-foreground: oklch(1 0 0);
  --secondary: oklch(0.9 0 0); --secondary-foreground: oklch(0.3 0 0);
  --muted: oklch(0.9 0 0); --muted-foreground: oklch(0.5 0 0);
  --accent: oklch(0.9 0 0); --accent-foreground: oklch(0.3 0 0);
  --destructive: oklch(0.6 0.2 25); --destructive-foreground: oklch(1 0 0);
  --border: oklch(0.8 0 0); --input: oklch(0.8 0 0); --ring: oklch(0.62 0.13 39);
  --chart-1: oklch(0.6 0.1 40); --chart-2: oklch(0.6 0.1 290);
  --chart-3: oklch(0.8 0.02 90); --chart-4: oklch(0.8 0.04 300); --chart-5: oklch(0.56 0.13 42);
  --sidebar: oklch(0.96 0 0); --sidebar-foreground: oklch(0.35 0 0);
  --sidebar-primary: oklch(0.62 0.13 39); --sidebar-primary-foreground: oklch(0.98 0 0);
  --sidebar-accent: oklch(0.92 0 0); --sidebar-accent-foreground: oklch(0.32 0 0);
  --sidebar-border: oklch(0.94 0 0); --sidebar-ring: oklch(0.77 0 0);
`;

function wrap(extraRoot = '', extraDark = ''): string {
  return `:root { ${COLOR_BLOCK} ${extraRoot} } .dark { ${COLOR_BLOCK} ${extraDark} }`;
}

function resolve(extraRoot = '', extraDark = '') {
  return resolveTheme(parseTheme(wrap(extraRoot, extraDark)));
}

describe('resolveTheme — radius (§4.1, additive, clamped ≥0)', () => {
  it('derives the additive set at a non-10 base (S4 — not fromBase)', () => {
    // 0.5rem = 8px → sm 4, md 6, lg 8, xl 12. fromBase(8) would give 4.8/6.4/11.2.
    expect(resolve('--radius: 0.5rem;').radii).toEqual({ base: 8, sm: 4, md: 6, lg: 8, xl: 12 });
  });
  it('derives the Claude 1rem base (16 → 12/14/16/20)', () => {
    expect(resolve('--radius: 1rem;').radii).toEqual({ base: 16, sm: 12, md: 14, lg: 16, xl: 20 });
  });
  it('clamps a zero radius (0px → 0/0/0/0/4, never negative)', () => {
    expect(resolve('--radius: 0px;').radii).toEqual({ base: 0, sm: 0, md: 0, lg: 0, xl: 4 });
  });
  it('handles a bare 0 radius', () => {
    expect(resolve('--radius: 0;').radii.base).toBe(0);
  });
  it('parses px units as-is', () => {
    expect(resolve('--radius: 12px;').radii).toEqual({ base: 12, sm: 8, md: 10, lg: 12, xl: 16 });
  });
  it('defaults an absent --radius to 10px and reports it', () => {
    const r = resolve();
    expect(r.radii).toEqual({ base: 10, sm: 6, md: 8, lg: 10, xl: 14 });
    expect(r.meta.notes.some((n) => /--radius absent/.test(n))).toBe(true);
  });
});

describe('resolveTheme — tracking units (§4.3)', () => {
  it('keeps em as-is', () => {
    expect(resolve('--tracking-normal: -0.025em;').typography.tracking).toBe(-0.025);
  });
  it('maps the `normal` keyword to 0', () => {
    expect(resolve('--tracking-normal: normal;').typography.tracking).toBe(0);
  });
  it('treats rem as em (1rem ≈ 1em)', () => {
    expect(resolve('--tracking-normal: 0rem;').typography.tracking).toBe(0);
  });
  it('converts px to em (px/16) and flags it as absolute', () => {
    const r = resolve('--tracking-normal: 0.5px;');
    expect(r.typography.tracking).toBe(0.03125);
    expect(r.meta.notes.some((n) => /absolute unit/.test(n))).toBe(true);
  });
  it('defaults absent tracking to 0 (no note)', () => {
    const r = resolve();
    expect(r.typography.tracking).toBe(0);
    expect(r.meta.notes.some((n) => /tracking/.test(n))).toBe(false);
  });
});

describe('resolveTheme — font-stack extraction (§4.3)', () => {
  const fam = (decl: string) => resolve(decl).typography;
  it('takes the first concrete family', () => {
    expect(fam('--font-sans: Outfit, sans-serif;').sans).toBe('Outfit');
  });
  it('skips a leading generic (ui-serif → Georgia)', () => {
    expect(fam('--font-serif: ui-serif, Georgia, Cambria, "Times New Roman", Times, serif;').serif).toBe(
      'Georgia',
    );
  });
  it('strips outer quotes ("Times New Roman")', () => {
    expect(fam('--font-mono: "Times New Roman", monospace;').mono).toBe('Times New Roman');
  });
  it('strips inner quotes (\'"Oxanium", sans-serif\')', () => {
    expect(fam(`--font-sans: '"Oxanium", sans-serif';`).sans).toBe('Oxanium');
  });
  it('looks up by name regardless of slot (a serif in the sans slot)', () => {
    expect(fam('--font-sans: Merriweather, serif;').sans).toBe('Merriweather');
  });
  it('defaults an omitted family to the platform family and reports it', () => {
    const r = resolve();
    expect(r.typography.sans).toBe('sans-serif');
    expect(r.meta.notes.some((n) => /--font-sans absent/.test(n))).toBe(true);
  });
});

describe('resolveTheme — shadows (§4.2)', () => {
  const shadowDecls = `
    --shadow-2xs: 0 1px 3px 0px hsl(0 0% 0% / 0.05);
    --shadow-xs: 0 1px 3px 0px hsl(0 0% 0% / 0.05);
    --shadow-sm: 0 1px 3px 0px hsl(0 0% 0% / 0.10), 0 1px 2px -1px hsl(0 0% 0% / 0.10);
    --shadow: 0 1px 3px 0px hsl(0 0% 0% / 0.10), 0 1px 2px -1px hsl(0 0% 0% / 0.10);
    --shadow-md: 0 1px 3px 0px hsl(0 0% 0% / 0.10), 0 2px 4px -1px hsl(0 0% 0% / 0.10);
    --shadow-lg: 0 1px 3px 0px hsl(0 0% 0% / 0.10), 0 4px 6px -1px hsl(0 0% 0% / 0.10);
    --shadow-xl: 0 1px 3px 0px hsl(0 0% 0% / 0.10), 0 8px 10px -1px hsl(0 0% 0% / 0.10);
    --shadow-2xl: 0 1px 3px 0px hsl(0 0% 0% / 0.25);
  `;
  it('parses a two-layer shadow with alpha into the right BoxShadow values', () => {
    const sm = resolve(shadowDecls).shadows.sm;
    expect(sm).toHaveLength(2);
    expect(rgba8ToArgbHex(sm[0].color)).toBe('1A000000');
    expect({ x: sm[1].x, y: sm[1].y, blur: sm[1].blur, spread: sm[1].spread }).toEqual({
      x: 0,
      y: 1,
      blur: 2,
      spread: -1,
    });
  });
  it('reads `md` from --shadow-md, NOT the unprefixed DEFAULT --shadow (§4.2)', () => {
    // DEFAULT --shadow second layer is `2px` blur; --shadow-md second layer is `4px`.
    const md = resolve(shadowDecls).shadows.md;
    expect(md[1].blur).toBe(4);
  });
  it('parses a colored shadow whose color is rgba() with internal commas', () => {
    const r = resolve('--shadow-md: 1px 2px 4px 0px rgba(29,161,242,0.15);');
    const md = r.shadows.md;
    expect(md).toHaveLength(1);
    expect(rgba8ToArgbHex(md[0].color)).toBe('26' + '1DA1F2'); // 0.15·255≈38=0x26
    expect({ x: md[0].x, y: md[0].y, blur: md[0].blur }).toEqual({ x: 1, y: 2, blur: 4 });
  });
  it('parses a colored hsl() shadow base (hard offsets, no spread)', () => {
    const r = resolve('--shadow-lg: 4px 4px 0px hsl(255 86% 66%);');
    const lg = r.shadows.lg;
    expect({ x: lg[0].x, y: lg[0].y, blur: lg[0].blur, spread: lg[0].spread }).toEqual({
      x: 4,
      y: 4,
      blur: 0,
      spread: 0,
    });
  });
  it('defaults to the engine scale when no --shadow-* is defined, and reports it', () => {
    const r = resolve();
    expect(r.shadows.md).toHaveLength(2);
    expect(r.meta.notes.some((n) => /shadow scale/.test(n))).toBe(true);
  });
});

describe('resolveTheme — colors & the 32-color hard gate (§3)', () => {
  it('defaults a missing --sidebar-ring to --ring and reports it', () => {
    const css = wrap().replace(/--sidebar-ring: oklch\([^)]*\);/g, '');
    const r = resolveTheme(parseTheme(css));
    expect(rgba8ToArgbHex(r.light.sidebarRing)).toBe(rgba8ToArgbHex(r.light.ring));
    expect(r.meta.notes.some((n) => /--sidebar-ring absent/.test(n))).toBe(true);
  });
  it('throws a clear error listing other missing required colors', () => {
    const css = wrap().replace(/--primary: oklch\([^)]*\);/g, '');
    expect(() => resolveTheme(parseTheme(css))).toThrow(/Missing required color.*--primary/s);
  });
});

describe('resolveTheme — spacing (§4.3 knowing drop)', () => {
  it('does not note the default 0.25rem (= 4px) spacing', () => {
    const r = resolve('--spacing: 0.25rem;');
    expect(r.meta.notes.some((n) => /--spacing/.test(n))).toBe(false);
  });
  it('notes a non-default --spacing as dropped', () => {
    const r = resolve('--spacing: 0.3rem;');
    expect(r.meta.notes.some((n) => /--spacing.*dropped/.test(n))).toBe(true);
  });
});

describe('resolveTheme — meta', () => {
  it('carries the conversion mode and dropped unknown vars', () => {
    const css = wrap('--brand-glow: #fff;');
    const r = resolveTheme(parseTheme(css), 'perceptual');
    expect(r.meta.conversion).toBe('perceptual');
    expect(r.meta.droppedVars).toEqual(['brand-glow']);
  });
});

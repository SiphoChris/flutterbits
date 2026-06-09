import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import {
  argbToCss,
  shadowToCss,
  humanizeField,
  swatches,
  radiusSamples,
  shadowSamples,
  runGenerator,
} from './preview';
import { generateTheme } from './emit';

function claudeCss(): string {
  return readFileSync(new URL('./__fixtures__/claude.hex.css', import.meta.url), 'utf8');
}

describe('argbToCss', () => {
  it('moves alpha from first (ARGB) to last (CSS) byte', () => {
    expect(argbToCss('FFFAF9F5')).toBe('#faf9f5ff');
    expect(argbToCss('1A000000')).toBe('#0000001a');
  });
});

describe('shadowToCss', () => {
  it('joins layers in source order with CSS colors', () => {
    expect(
      shadowToCss([
        { color: '1A000000', x: 0, y: 1, blur: 3, spread: 0 },
        { color: '1A000000', x: 0, y: 1, blur: 2, spread: -1 },
      ]),
    ).toBe('0px 1px 3px 0px #0000001a, 0px 1px 2px -1px #0000001a');
  });
  it('maps an empty layer list to `none`', () => {
    expect(shadowToCss([])).toBe('none');
  });
});

describe('humanizeField', () => {
  it('splits camelCase and trailing digits', () => {
    expect(humanizeField('cardForeground')).toBe('Card foreground');
    expect(humanizeField('sidebarPrimaryForeground')).toBe('Sidebar primary foreground');
    expect(humanizeField('chart1')).toBe('Chart 1');
    expect(humanizeField('ring')).toBe('Ring');
  });
});

describe('preview models (from the Claude theme)', () => {
  const json = generateTheme(claudeCss()).themeJson;

  it('produces 32 swatches with CSS colors', () => {
    const s = swatches(json.colors.light);
    expect(s).toHaveLength(32);
    expect(s[0]).toEqual({ field: 'background', label: 'Background', css: '#faf9f5ff' });
  });
  it('produces the four radius samples', () => {
    expect(radiusSamples(json)).toEqual([
      { name: 'sm', px: 12 },
      { name: 'md', px: 14 },
      { name: 'lg', px: 16 },
      { name: 'xl', px: 20 },
    ]);
  });
  it('produces seven shadow samples with CSS box-shadow strings', () => {
    const s = shadowSamples(json);
    expect(s).toHaveLength(7);
    expect(s[0]).toEqual({ name: 'xs2', css: '0px 1px 3px 0px #0000000d' });
  });
});

describe('runGenerator — UI result mapping', () => {
  it('returns `empty` for blank/whitespace input (not an error)', () => {
    expect(runGenerator('   \n  ', 'faithful').status).toBe('empty');
  });
  it('returns `ok` with both artifacts for a valid theme', () => {
    const r = runGenerator(claudeCss(), 'faithful');
    expect(r.status).toBe('ok');
    if (r.status === 'ok') {
      expect(r.result.themeJson.radiusBase).toBe(16);
      expect(r.result.dartSource).toContain('lightTheme');
    }
  });
  it('returns `error` with the v3 message for a Tailwind-v3 paste', () => {
    const r = runGenerator('@tailwind base;\n:root{--background:0 0% 100%;}', 'faithful');
    expect(r.status).toBe('error');
    if (r.status === 'error') expect(r.message).toMatch(/Tailwind v3/);
  });
  it('returns `error` listing missing colors when the 32-color gate fails', () => {
    const r = runGenerator(':root{--background:#fff;} .dark{--background:#000;}', 'faithful');
    expect(r.status).toBe('error');
    if (r.status === 'error') expect(r.message).toMatch(/Missing required color/);
  });
});

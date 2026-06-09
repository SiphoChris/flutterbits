import { describe, it, expect } from 'vitest';
import { parseHex, parseRgb, parseHsl, parseOklch, parseCssColor } from './parse';

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
    expect(parseHsl('hsl(15.1111 55.5556% 52.3529%)')).toEqual({ r: 201, g: 100, b: 66, a: 255 });
  });
});

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

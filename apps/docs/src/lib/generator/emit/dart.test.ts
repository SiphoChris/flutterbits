import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { emitDart } from './dart';
import { resolveTheme, toThemeJson } from './index';
import { parseTheme } from '../parse';
import { COLOR_FIELD_NAMES } from '../types';
import type { ThemeJson } from '../types';

function claudeJson(): ThemeJson {
  const css = readFileSync(new URL('../__fixtures__/claude.hex.css', import.meta.url), 'utf8');
  return toThemeJson(resolveTheme(parseTheme(css)));
}

describe('emitDart — structure', () => {
  const dart = emitDart(claudeJson());

  it('emits the two const FwTokens and the shared consts', () => {
    expect(dart).toContain('const FwRadii _radii = FwRadii(base: 16, sm: 12, md: 14, lg: 16, xl: 20);');
    expect(dart).toContain('const FwShadows _shadows = FwShadows(');
    expect(dart).toContain('const FwTypographyTheme _type = FwTypographyTheme(');
    expect(dart).toContain('const FwTokens lightTheme = FwTokens(');
    expect(dart).toContain('const FwTokens darkTheme = FwTokens(');
  });
  it('imports painting + flutterwindcss (no Material)', () => {
    expect(dart).toContain("import 'package:flutter/painting.dart';");
    expect(dart).toContain("import 'package:flutterwindcss/flutterwindcss.dart';");
    expect(dart).not.toContain('material.dart');
  });
  it('emits the font names and font-registration guidance (never a silent bundle)', () => {
    expect(dart).toContain('Outfit');
    expect(dart).toContain('Geist Mono');
    // The dev must REGISTER the fonts (bundle or google_fonts); the engine applies them.
    expect(dart).toMatch(/REGISTER the fonts/);
    expect(dart).toMatch(/google_fonts/);
  });
  it('omits tracking when 0 (FwTypographyTheme default)', () => {
    expect(dart).not.toContain('tracking:');
  });
  it('emits color literals as Color(0xAARRGGBB)', () => {
    expect(dart).toContain('background: Color(0xFFFAF9F5)');
    expect(dart).toContain('primary: Color(0xFFC96442)');
  });
  it('omits zero blurRadius/spreadRadius but keeps non-zero ones', () => {
    // Claude xs2: 0 1px 3px 0px → blurRadius 3, no spreadRadius.
    expect(dart).toContain('BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 3)');
    // sm second layer carries spreadRadius -1.
    expect(dart).toContain('spreadRadius: -1');
  });
});

describe('emitDart — totality (S3: every ThemeJson field is consumed)', () => {
  const json = claudeJson();
  const dart = emitDart(json);

  it('emits radiusBase and every radius step', () => {
    expect(dart).toContain(`radiusBase: ${json.radiusBase}`);
    for (const v of Object.values(json.radii)) expect(dart).toContain(String(v));
  });
  it('emits all 64 color literals (32 light + 32 dark) for every field', () => {
    for (const field of COLOR_FIELD_NAMES) {
      expect(dart).toContain(`${field}: Color(0x${json.colors.light[field]})`);
      expect(dart).toContain(`${field}: Color(0x${json.colors.dark[field]})`);
    }
  });
  it('emits every shadow slot with its color', () => {
    for (const slot of Object.keys(json.shadows)) {
      expect(dart).toContain(`${slot}: <BoxShadow>[`);
    }
  });
  it('emits the conversion mode in the header', () => {
    expect(dart).toContain('Conversion: faithful');
  });
});

describe('emitDart — reporting & conditional fields', () => {
  it('emits tracking when non-zero', () => {
    const css = readFileSync(new URL('../__fixtures__/claude.hex.css', import.meta.url), 'utf8').replace(
      '--tracking-normal: 0em;',
      '--tracking-normal: -0.025em;',
    );
    const dart = emitDart(toThemeJson(resolveTheme(parseTheme(css))));
    expect(dart).toContain('tracking: -0.025');
  });
  it('lists dropped unknown vars and defaulted tokens in the header comments', () => {
    const css = `:root { ${ALL_COLORS} --brand-glow: #fff; } .dark { ${ALL_COLORS} }`;
    const dart = emitDart(toThemeJson(resolveTheme(parseTheme(css))));
    expect(dart).toContain('Dropped unknown CSS vars: brand-glow');
    // No fonts/shadows/radius defined → all defaulted and reported.
    expect(dart).toMatch(/--font-sans absent/);
    expect(dart).toMatch(/shadow scale/);
  });
});

// A minimal 32-color block (oklch) for the reporting test.
const ALL_COLORS = [
  'background',
  'foreground',
  'card',
  'card-foreground',
  'popover',
  'popover-foreground',
  'primary',
  'primary-foreground',
  'secondary',
  'secondary-foreground',
  'muted',
  'muted-foreground',
  'accent',
  'accent-foreground',
  'destructive',
  'destructive-foreground',
  'border',
  'input',
  'ring',
  'chart-1',
  'chart-2',
  'chart-3',
  'chart-4',
  'chart-5',
  'sidebar',
  'sidebar-foreground',
  'sidebar-primary',
  'sidebar-primary-foreground',
  'sidebar-accent',
  'sidebar-accent-foreground',
  'sidebar-border',
  'sidebar-ring',
]
  .map((c) => `--${c}: oklch(0.6 0.1 40);`)
  .join(' ');

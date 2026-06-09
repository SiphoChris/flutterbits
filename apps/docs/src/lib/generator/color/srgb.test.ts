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
    expect(linearToSrgb(0.001)).toBeCloseTo(0.01292, 9);
    expect(linearToSrgb(0.5)).toBeCloseTo(0.735356, 5);
  });

  it('channelTo8 clamps then rounds to nearest', () => {
    expect(channelTo8(0)).toBe(0);
    expect(channelTo8(1)).toBe(255);
    expect(channelTo8(1.5)).toBe(255);
    expect(channelTo8(-0.1)).toBe(0);
    expect(channelTo8(201 / 255)).toBe(201);
  });

  it('alphaTo8 rounds to nearest (verified shadow alphas)', () => {
    expect(alphaTo8(0.05)).toBe(13);
    expect(alphaTo8(0.1)).toBe(26);
    expect(alphaTo8(0.25)).toBe(64);
    expect(alphaTo8(0.15)).toBe(38);
    expect(alphaTo8(1)).toBe(255);
  });

  it('rgba8ToArgbHex formats AARRGGBB uppercase', () => {
    expect(rgba8ToArgbHex({ r: 201, g: 100, b: 66, a: 255 })).toBe('FFC96442');
    expect(rgba8ToArgbHex({ r: 0, g: 0, b: 0, a: 13 })).toBe('0D000000');
  });
});

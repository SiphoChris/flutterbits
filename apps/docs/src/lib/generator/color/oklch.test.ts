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

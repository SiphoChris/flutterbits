import { rgba8ToArgbHex } from '../color';
import { SHADOW_SLOTS } from '../types';
import type {
  ResolvedColors,
  ResolvedShadows,
  ResolvedTheme,
  ShadowSlot,
  ThemeJson,
  ThemeJsonShadow,
} from '../types';

/// G3 — serialize a [ResolvedTheme] into the [ThemeJson] **source of truth**
/// (spec §4.4). Colors and shadow colors become `AARRGGBB` hex strings; every
/// other field is carried through unchanged. The emitted `theme.dart` is then a
/// pure function of this JSON (`emitDart`, see `dart.ts`).

function colorsToHex(colors: ResolvedColors): Record<string, string> {
  const out: Record<string, string> = {};
  for (const [field, rgba] of Object.entries(colors)) out[field] = rgba8ToArgbHex(rgba);
  return out;
}

function shadowsToJson(shadows: ResolvedShadows): Record<ShadowSlot, ThemeJsonShadow[]> {
  const out = {} as Record<ShadowSlot, ThemeJsonShadow[]>;
  for (const { slot } of SHADOW_SLOTS) {
    out[slot] = shadows[slot].map((l) => ({
      color: rgba8ToArgbHex(l.color),
      x: l.x,
      y: l.y,
      blur: l.blur,
      spread: l.spread,
    }));
  }
  return out;
}

/// Build the [ThemeJson] from a resolved theme.
export function toThemeJson(resolved: ResolvedTheme): ThemeJson {
  return {
    radiusBase: resolved.radii.base,
    radii: resolved.radii,
    colors: {
      light: colorsToHex(resolved.light),
      dark: colorsToHex(resolved.dark),
    },
    shadows: shadowsToJson(resolved.shadows),
    typography: resolved.typography,
    meta: resolved.meta,
  };
}

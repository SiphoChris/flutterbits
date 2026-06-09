import type { ConversionMode } from '../color/types';
import { parseTheme } from '../parse';
import type { GenerateResult } from '../types';
import { resolveTheme } from './resolve';
import { toThemeJson } from './theme-json';
import { emitDart } from './dart';

export { resolveTheme } from './resolve';
export { toThemeJson } from './theme-json';
export { emitDart } from './dart';

/// The end-to-end generator (spec §2): pasted tweakcn v4 CSS → `theme.json` (the
/// source of truth) + a drop-in `theme.dart`. Throws a clear, user-facing error
/// on a Tailwind-v3 input, a missing `:root`/`.dark` block, or a missing required
/// color (the 32-color hard gate) — the UI (G4) surfaces these.
export function generateTheme(css: string, mode: ConversionMode = 'faithful'): GenerateResult {
  const raw = parseTheme(css);
  const resolved = resolveTheme(raw, mode);
  const themeJson = toThemeJson(resolved);
  return { themeJson, dartSource: emitDart(themeJson) };
}

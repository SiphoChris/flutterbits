# Changelog

## 1.0.1

- **Docs** — the documentation site is live at
  [flutterbits.vercel.app](https://flutterbits.vercel.app/docs/flutterwindcss); the README and links
  now point to it (guides, the `.tw` utility reference, theming, layout, and the theme generator).
  No API or behaviour changes.

## 1.0.0

Initial release.

`flutterwindcss` is Tailwind CSS v4's design system and styling vocabulary for Flutter — a
Material-free styling engine over the framework's primitive widgets layer.

- **Tokens** — the full Tailwind v4 color palette (`FwPalette`, baked, no runtime color math) and
  the complete shadcn semantic vocabulary (`FwColors` — 32 roles: the 19 core + `chart1…5` +
  8 `sidebar*`), plus radius, shadow, typography, opacity, border-width, z-index, blur and
  breakpoint scales.
- **Theming** — `FwTheme` (pure path) and `FwThemeExtension` (Material interop), read via
  `context.fw`; `FwTokens.light` / `FwTokens.dark`; and `FwAnimatedTheme`, which crossfades every
  token (`FwTokens.lerp`) on a theme or brightness change.
- **The `.tw` utility API** — an accumulator with last-wins conflict resolution that resolves lazily
  against interaction states (`hover`/`focus`/`pressed`/`disabled`, plus `group`/`peer`) and
  viewport/container breakpoints (`sm`…`xl`, `containerSm`…). Covers spacing, sizing, color,
  gradients, borders, radius, typography, effects, filters, transforms (2D + 3D), blend modes, and
  interactivity.
- **Layout widgets** — `FwRow` / `FwColumn` / `FwWrap`, `FwStack` / `FwPositioned`, and `FwGrid`
  (a real CSS-grid render object), all directional (RTL-aware) and responsive.

Requires Flutter ≥ 3.29 / Dart ≥ 3.7.

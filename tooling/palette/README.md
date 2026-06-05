# Tailwind v4 palette source

`tailwind_v4_palette.json` holds the Tailwind CSS v4 default color palette as
sRGB hex. Every hue (slate…rose) × shades 50–950, plus black/white.

**Source of truth: Tailwind's own *published* hex** (what tailwindcss.com/docs/colors
and every Tailwind reference show, e.g. `orange-500 = #ff6900`). Tailwind defines
colors in OKLCH but publishes **gamut-clipped** sRGB hex, kept close to its legacy
v3 values. We transcribe those published values verbatim so `FwPalette` matches the
Tailwind colors developers recognize.

**Do NOT "improve" these by gamut-mapping the OKLCH yourself.** For the ~79
saturated out-of-gamut shades, a proper CSS-Color-4 gamut map produces *different*
hex than Tailwind publishes (e.g. orange-500 would become `~#fc7100`). That belongs
to the theme **generator** (AGENTS.md §7), which gamut-maps *arbitrary user themes*
to match browser rendering — a different job from reproducing Tailwind's own palette.
The out-of-gamut contract is pinned by `test/tokens/palette_baked_test.dart`.

These values are transcribed, not computed in Dart (AGENTS.md §7 keeps color
math out of the Dart side). To regenerate the baked Dart constants after editing
the JSON:

```
dart run tooling/bake_palette.dart   # run from the repo root
```

This rewrites `packages/flutterwindcss/lib/src/tokens/palette.g.dart`.

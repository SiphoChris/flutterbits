# Tailwind v4 palette source

`tailwind_v4_palette.json` holds the Tailwind CSS v4 default color palette as
sRGB hex — the published hex equivalents of Tailwind's OKLCH definitions
(source: `tailwindlabs/tailwindcss`, `packages/tailwindcss/src/compat/colors.ts`).
Every hue (slate…rose) × shades 50–950, plus black/white.

These values are transcribed, not computed in Dart (AGENTS.md §7 keeps color
math out of the Dart side). To regenerate the baked Dart constants after editing
the JSON:

```
dart run tooling/bake_palette.dart   # run from the repo root
```

This rewrites `packages/flutterwindcss/lib/src/tokens/palette.g.dart`.

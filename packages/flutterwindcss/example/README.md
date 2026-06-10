# flutterwindcss example

A minimal, **Material-free** app that shows the three things every flutterwindcss
app uses:

1. **A theme, provided once** — `FwAnimatedTheme(tokens: ...)` wraps the app and
   crossfades every token (`FwTokens.lerp`) when it changes.
2. **Tokens read via `context.fw`** — semantic roles like `colors.primary`,
   `colors.mutedForeground`, `radii.md`.
3. **The `.tw` utility chain + layout widgets** — single-box styling (`.px`,
   `.bg`, `.rounded`, …) and directional, responsive layout (`FwColumn`).

Tapping the button toggles light/dark so you can watch the theme crossfade.

## Run

```sh
flutter run        # any device, e.g. -d chrome / -d windows / -d macos
```

For a much larger tour of the engine — every utility, the layout widgets, grid,
group/peer, and animated theming — see the **`apps/example`** showcase in the
[flutterbits monorepo](https://github.com/SiphoChris/flutterbits).

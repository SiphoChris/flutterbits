---
name: using-flutterwindcss
description: Use when building or editing a Flutter UI that depends on the flutterwindcss package — styling widgets with the .tw utility API, reading semantic theme tokens via context.fw, laying out with FwRow/FwColumn/FwGrid, or wiring a theme/fonts. Covers the rules, patterns, and gotchas so the code is correct first try.
---

# Using flutterwindcss

`flutterwindcss` is **Tailwind CSS's styling vocabulary for Flutter** — design tokens + a typed,
chainable utility API (`.tw`) over Flutter's *primitive* widgets. It is **Material-free** (works in a
bare `WidgetsApp` *and* inside a `MaterialApp`) and themes by **semantic indirection** like shadcn/ui.

Full docs: https://flutterbits.vercel.app/docs/flutterwindcss

## Mental model (read once)

- **Styling is declarative.** You don't hand-nest `Padding(child: DecoratedBox(...))`. You declare a
  flat set of utilities and the engine builds the widget tree: `child.tw.px(4).bg(c).rounded(8)`.
- **One `.tw` chain = one styled box.** Chaining order doesn't define structure — conflicts resolve
  **last-wins** (`.px(2).px(4)` ⇒ `px-4`), exactly like overriding a CSS class.
- **`.tw` is single-box only.** Multi-child layout (direction, `gap`, positioning, grid) is **separate
  widgets** (`FwRow`/`FwColumn`/`FwWrap`/`FwStack`/`FwGrid`/`FwScroll`), not `.tw`.
- **Semantic tokens reskin everything.** Reference roles (`context.fw.colors.primary`), not raw
  swatches, and swapping the theme reskins the whole app.
- **Directional by default.** Spacing/alignment/radius are RTL-aware (`ps`/`pe`, `start`/`end`).

## Setup

```bash
flutter pub add flutterwindcss
```

```dart
import 'package:flutterwindcss/flutterwindcss.dart'; // the ONLY import (never src/...)
```

Provide tokens once near the root — **pure path** or **Material interop**:

```dart
// Pure path (no Material): WidgetsApp + FwTheme (or FwAnimatedTheme to crossfade theme changes).
FwTheme(tokens: FwTokens.light, child: const HomeScreen());

// Material interop: register tokens as a ThemeData extension; context.fw resolves through it.
MaterialApp(
  theme: ThemeData(extensions: const [FwThemeExtension(tokens: FwTokens.light)]),
  darkTheme: ThemeData(extensions: const [FwThemeExtension(tokens: FwTokens.dark)]),
  home: const HomeScreen(),
);
```

`FwTokens.light` / `FwTokens.dark` are the built-in stock themes. For a custom theme, paste a
tweakcn/shadcn theme into the generator (https://flutterbits.vercel.app/theme-generator) → copy a
`theme.dart` → use its `lightTheme` / `darkTheme`. **You are not required to provide a theme** — see
"No theme" below.

## Styling with `.tw`

`.tw` begins a chain on **any** widget; `context.fw` reads the active tokens.

```dart
final t = context.fw;
Text('Save').tw
    .px(4).py(2)                       // padding (1 unit = 4 logical px) — px-4 py-2
    .bg(t.colors.primary)              // bg-primary (semantic token)
    .text(t.colors.primaryForeground)  // text color
    .rounded(t.radii.md)               // border-radius
    .hover((s) => s.opacity(0.9));     // hover: variant
```

Utility families on `.tw` (see docs for the full list): spacing (`p`/`px`/`m`/`ms`…), sizing
(`w`/`h`/`min`/`max`/`size`/`wFraction`/`wFull`/`aspect`/`square`), color/bg (`bg`/`text`/`bgGradient`/
`bgGradientToR`/`bgImage`), borders (`border`/`borderS`/`borderDashed`/`rounded`/`roundedFull`/`clip`),
typography (`textSize`/`weight`/`leading`/`tracking`/`align`/`underline`/`overline`/`lineThrough`/
`truncate`/`lineClamp`/`nowrap`), effects (`shadow`/`shadowMd`/`ring`/`opacity`/`blur`/`backdropBlur`/
`blendMode`), color filters (`grayscale`/`brightness`/`contrast`/`saturate`/`invert`/`sepia`/
`hueRotate`), `fit(BoxFit, {alignment})`, transforms (`scale`/`rotate`/`translate`/`skewX`/`rotateX`/
`perspective`/`transformOrigin`), interactivity (`cursor`/`pointerEventsNone`/`invisible`).

### States, responsive, relations

```dart
box.tw
   .bg(t.colors.secondary)
   .hover((s) => s.bg(t.colors.primary))     // hover: / focus: / pressed: / disabled:
   .md((s) => s.px(8))                         // sm/md/lg/xl/xl2 viewport; containerSm…container2xl
   .groupHover((s) => s.text(t.colors.foreground)); // needs an FwGroup ancestor; peerHover needs FwPeer

// Component-owned states (selected/checked/open/…): whenState(WidgetState.selected, (s) => …)
// and pass the active states to FwStyled. dark is theme-level (swap FwTokens), not a per-utility variant.
```

## Layout (NOT `.tw`)

```dart
FwRow(gap: 2, children: [a, b]);              // flex; FwColumn / FwWrap likewise. gap = space between.
FwRow(divideWidth: 1, divideColor: t.colors.border, children: […]); // divide-x (RTL-aware)
FwStack(children: [base, FwPositioned(top: 1, end: 1, child: badge)]); // directional inset + z
FwGrid(columns: FwTrack.repeat(3, const FwFr()), columnGap: 2, children: […]); // real CSS grid
FwScroll(axis: Axis.vertical, thumbColor: t.colors.border, child: …); // overflow-auto; snapExtent for snap
```
Layout widgets are themselves chainable with `.tw` for box styling: `FwRow(...).tw.p(4).bg(c)`.

## Fonts

The engine applies the theme's `sans` family automatically (`FwTheme` sets it as the default;
`fontSans`/`fontSerif`/`fontMono` resolve to the theme). It **bundles no fonts** — you *register* them
(bundle the `.ttf` in `pubspec.yaml`, or use `google_fonts`). `font('Inter')` sets a literal family for
one chain. Guide: https://flutterbits.vercel.app/docs/flutterwindcss/fonts

## No theme (you're not forced into one)

Raw values need no `FwTheme`: `Text('Hi').tw.px(4).bg(FwPalette.blue.shade600).rounded(8).font('Inter')`
works with zero theme. Semantic tokens (`context.fw.colors.*`) require a theme; `context.fwOrNull`
reads tokens without throwing when a theme is optional. The role sugars (`fontSans`/`roundedMd`/
`shadowMd`) fall back to `FwTokens.light` defaults when no theme is present.

## Rules (do / don't)

- ✅ **Use semantic tokens** for themeable colors (`t.colors.primary`), not raw `Color(0x…)` or
  `FwPalette.*`, when you want the widget to follow the theme. (Raw palette is fine for fixed,
  non-themed accents.)
- ✅ **Read tokens via `context.fw`** (or `context.fwOrNull`). Don't call `Theme.of(context)` for fw tokens.
- ✅ **Use directional setters** (`ps`/`pe`/`ms`/`me`, `start`/`end`) so RTL is free. Avoid left/right.
- ✅ **One `.tw` chain per box.** For multiple children, reach for a layout widget — don't nest `.tw`.
- ✅ `const Text('x').tw…` is correct — `const` binds the inner widget; the chain is runtime. Keep it.
- ❌ Don't import `package:flutterwindcss/src/...` — only the package barrel is supported.
- ❌ Don't mix a token-role sugar with its literal in one chain (`.fontSans.font('X')`, `.roundedMd.rounded(4)`) — it asserts.
- ❌ Don't expect element animations from the engine — use `flutter_animate` (it composes with `.tw`:
  `widget.tw.…().animate().fadeIn()`). The engine animates **theme** transitions via `FwAnimatedTheme`.

## Quick recipes

```dart
// Button
GestureDetector(
  onTap: onTap,
  child: const Text('Continue').tw
      .px(4).py(2).rounded(t.radii.md)
      .bg(t.colors.primary).text(t.colors.primaryForeground)
      .weight(FwFontWeight.semibold)
      .hover((s) => s.opacity(0.9)),
);

// Card
FwColumn(gap: 2, children: [title, body]).tw
    .p(4).bg(t.colors.card).text(t.colors.cardForeground)
    .rounded(t.radii.lg).border(1, color: t.colors.border).shadow(t.shadows.sm);

// Responsive grid: 1 col on phones, 3 at md+ (viewport = screen width)
FwGrid(
  columns: const [FwFr()],
  viewport: const {FwBreakpoint.md: FwGridPatch(columns: [FwFr(), FwFr(), FwFr()])},
  children: cards,
);
```

## Gotchas

- Spacing/sizing units are **4 logical px** (`p(4)` = 16px), like Tailwind.
- `object-fit` (`fit`) needs a **bounded** box (set a size, or constrain it) or it renders at natural size.
- `FwGrid` is a real CSS-grid render object; `subgrid` is intentionally not implemented.
- A `FwScroll` `trackColor` forces the thumb visible (a track behind no thumb is meaningless).
- Goldens/visuals: this is pure widgets-layer code — it runs on **all 6 Flutter platforms**.

When in doubt, check the docs: https://flutterbits.vercel.app/docs/flutterwindcss

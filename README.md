<div align="center">

# flutterbits + flutterwindcss

### Tailwind CSS's styling vocabulary and shadcn/ui's copy‑paste components — for Flutter.

[![CI](https://github.com/SiphoChris/flutterbits/actions/workflows/ci.yaml/badge.svg)](https://github.com/SiphoChris/flutterbits/actions/workflows/ci.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.29-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%E2%89%A53.7-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Material‑free](https://img.shields.io/badge/Material‑free-yes-success)](#mental-model)
[![Status](https://img.shields.io/badge/status-early%20development-orange)](#project-status)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#contributing)

</div>

---

![Flutterbits Banner](assets/flutterbits.png)

---

## What is this?

Two products in one monorepo, built so that **any [tweakcn](https://tweakcn.com)/shadcn theme you paste into a web generator becomes a working Flutter `theme.dart`** — theme portability no other Flutter UI library offers.

- **`flutterwindcss`** — Tailwind CSS v4's *design system and styling vocabulary* for Flutter. Design tokens (spacing, radius, semantic colors, typography, shadows) and a typed, compile‑time utility API (`.tw`) over Flutter's primitive widgets. This is the **Tailwind** layer.
- **`flutterbits`** — shadcn/ui for Flutter. **Copy‑paste** components you own, fetched via a CLI from a registry, styled entirely through `flutterwindcss` and semantic tokens. This is the **shadcn/ui** layer.

## Why it's different

| | Typical Flutter UI kit | flutterbits |
|---|---|---|
| Styling | Material widgets + `ThemeData` | Material‑free; Tailwind‑style typed utilities over the widgets layer |
| Components | Versioned dependency you can't edit | **Copy‑paste source you own**, updatable via a `diff` CLI |
| Theming | Hand‑port every color | **Paste a tweakcn/shadcn theme → get `theme.dart`** |
| Tokens | Raw colors scattered in code | **Semantic indirection** (`primary`, `muted`, `border`) — swap the theme, reskin everything |

## Mental model

Flutter has no structure/style split and no CSS cascade — the widget tree *is* the styling. flutterwindcss re‑creates Tailwind's **vocabulary and token discipline**, not a CSS engine. Theming works by **semantic indirection**, exactly like shadcn: components reference role‑named tokens (`primary`, `mutedForeground`, `border`), never raw palette swatches, so swapping the theme reskins everything.

**"Material‑free"** means no Material *components or visuals* — but the framework's generic widgets layer (`Container`, `DecoratedBox`, `FocusableActionDetector`, `WidgetState`, `Semantics`, …) is used freely. The single sanctioned Material touch in the whole repo is a `ThemeExtension` bridge so the same component works in a bare `WidgetsApp` **and** inside a `MaterialApp`.

## Project status

> **Early development.** The foundation is being built module‑by‑module, each one fully implemented, tested, and reviewed before the next begins — no stubs, no "TODO: productionize later."

**✅ Shipped (`flutterwindcss`):**

- **Tokens (module 1)** — the full **Tailwind v4 color palette** (22 hues × 11 shades, baked from published sRGB hex — zero runtime color math); the **19 shadcn semantic tokens** (`background`, `foreground`, `primary`, `muted`, `border`, `ring`, …); complete **scales** (spacing 1 unit = 4px, derived + named radius, box‑shadow, typography, opacity, border‑width, z‑index, blur, breakpoints); `FwTokens.light`/`dark` (const, `lerp`‑animatable); the frozen `FwState`/`FwBreakpoint` enums; and a **CI‑authoritative golden harness**.
- **Theme access (module 2)** — `FwTheme` (InheritedWidget, pure path) + `FwThemeExtension` (Material interop) + `context.fw`, resolving in both paths with a clear error when neither is present.
- **The `FwStyle` resolver + `.tw` API (module 3)** — an accumulator with last‑wins conflict resolution that resolves lazily against interaction states and **viewport vs. container** width (kept distinct), so `hover:`/`focus:`/`pressed:`/`disabled:` variants and `sm:`/`md:`/`container*:` prefixes are first‑class. Includes the full primitive render chain and `FwStyled`, which inserts `MediaQuery`/`LayoutBuilder`/interaction wrappers only when a layer needs them — and never a spurious focus tab stop. Ships the `padding` + `bg` setters; the rest land per family below.
- **Spacing + sizing setters (module 4)** — the typed `.tw` setters for `margin` (`m/mx/my/ms/me/mt/mb`, directional per‑edge merge), fixed/min/max sizing (`w/h/minW/minH/maxW/maxH`, utility‑unit), fractional sizing (`wFraction`/`hFraction` + `align`, `wFull`/`hFull`), and aspect (`aspect`/`square`) — over module 3's existing render chain. Unit + LTR/RTL × light/dark goldens.
- **Color + border + radius setters (module 5)** — `bgGradient`; a directional, accumulating border (`FwBorderSpec`: uniform `border(w, {color})`, independent `borderWidth`/`borderColor` axes, per‑edge `borderS/E/T/B`); per‑corner directional radius (`rounded`/`roundedT/B/S/E`/`roundedNone`/`roundedFull`); and `clip`. Lands the content‑clip radius **deflation by border width** deferred from module 3, plus a clear assert for Flutter's "rounded borders must be uniform" limitation. Unit + LTR/RTL × light/dark goldens.
- **Typography setters (module 6)** — `text` (color), `textSize`, `weight` (CSS `100…900` → `FontWeight`), `leading` (line‑height ×), `tracking` (letter‑spacing), `align`, and `underline`/`lineThrough` (which combine) — over module 3's `DefaultTextStyle`/`IconTheme` merge. Unit + LTR/RTL × light/dark goldens.
- **Effects setters (module 7)** — `shadow` (theme `List<BoxShadow>`), `opacity`, `blur` (content), and `backdropBlur` — over module 3's shadow/opacity/`ImageFiltered`/`BackdropFilter` chain, with range/sign guards. Unit + light/dark goldens.
- **Layout widgets (module 8)** — the six dedicated multi‑child widgets the single‑box `.tw` chain can't express: `FwRow`/`FwColumn` (flex with typed `gap`), `FwWrap`, `FwStack`/`FwPositioned` (directional `inset` + stable `z`‑order), and `FwGrid` (a sealed `FwFr`/`FwPx` column‑track grammar). All directional (RTL‑free), each chainable with `.tw` for box styling; `gap`/spacing use the framework's native `spacing`. (Container queries — `containerSm…` — already shipped with the module‑3 resolver.) Unit + LTR/RTL × light/dark goldens.

**🚧 Next on the roadmap:**

1. **The rest of the engine** — transforms (`scale`/`rotate`/`translate`) and animated theming (`FwAnimatedTheme`). (Each adds typed `.tw` setters / dedicated widgets over the already‑built resolver + render chain.)
2. **`flutterbits` components**, the **registry + CLI** (`flutterbits add` / `diff`), and the **tweakcn → `theme.dart` generator**.

See [`docs/superpowers/specs`](docs/superpowers/specs) for the full engine design and [`docs/superpowers/plans`](docs/superpowers/plans) for the implementation plans.

## Repository layout

```
packages/
  flutterwindcss/        # pub package: tokens, FwTheme, FwStyle accumulator, .tw utilities
apps/                    # (planned) docs site + tweakcn generator, example/golden showcase
registry/                # (planned) source-of-truth copy-paste components
tooling/                 # registry builder + the Tailwind palette baker
docs/superpowers/        # design specs and implementation plans
```

Dependency resolution uses **pub workspaces** (`resolution: workspace`).

## Getting started (development)

> Requires **Flutter ≥ 3.29 / Dart ≥ 3.7** (the wide‑gamut `Color` API and `Flex` spacing land in 3.27; we floor at 3.7 for the modern `dart format` style). CI verifies this floor on a pinned 3.29 job, and pins 3.41.9 for deterministic goldens.

```bash
# From the repo root
flutter pub get                                   # resolves the workspace

cd packages/flutterwindcss
flutter test                                      # run the unit + golden suite
flutter analyze --fatal-infos --fatal-warnings    # zero-warning bar
dart format --line-length 100 .                   # 100-col formatting

# Regenerate the baked Tailwind palette (from repo root)
dart run tooling/bake_palette.dart
```

A peek at the eventual authoring experience:

```dart
// Components read tokens only via context.fw, and style through .tw:
Text('Click me')
  .tw
  .px(4).py(2)                      // padding in utility units (4px each)
  .bg(context.fw.colors.primary)    // semantic token — themes for free
  .rounded(context.fw.radii.md)
  .hover((s) => s.bg(context.fw.colors.accent));
```

## Design principles (non‑negotiable)

- **Semantic tokens only** in components — never hardcoded colors or raw palette swatches.
- **Directional by default** (`EdgeInsetsDirectional`, `BorderRadiusDirectional`) — RTL is free.
- **Provider‑agnostic** token access via `context.fw` — never `Theme.of(context)` directly.
- **No runtime string parsing** — utilities are typed method calls resolved at compile time.
- **Accessibility is required**, not optional — roles, focus rings, and keyboard activation ship with every component.

The complete operating manual lives in [`AGENTS.md`](AGENTS.md).

## Contributing

This is an early‑stage solo project rolling out wave‑by‑wave behind a strict golden‑test safety net. Issues and PRs are welcome — please read [`AGENTS.md`](AGENTS.md) first; it encodes the architecture decisions that keep theme portability and Material‑freedom intact.

## Acknowledgements

Inspired by [Tailwind CSS](https://tailwindcss.com), [shadcn/ui](https://ui.shadcn.com), and [tweakcn](https://tweakcn.com). Built on [Flutter](https://flutter.dev).

## License

[MIT](LICENSE) © 2026 Sipho Nkebe

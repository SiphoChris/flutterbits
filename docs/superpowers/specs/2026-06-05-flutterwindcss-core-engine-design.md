# flutterwindcss — Core Styling Engine (v1) Design

**Status:** Approved direction, pending spec review
**Date:** 2026-06-05
**Scope:** The `packages/flutterwindcss` styling engine — token system, theme access, and the `FwStyle` resolver / `.tw` utility API. This is the foundation every other product in the monorepo (flutterbits components, the registry/CLI, the theme generator) depends on.

> **Quality bar:** Production-grade. Nothing in this engine ships as a stub or a "TODO: make this real later." The *architecture* is complete on day one; implementation lands as fully-complete modules (§12). Where a capability is genuinely out of scope for the engine, it is listed under Non-Goals (§2) with the sub-project that owns it — it is not silently half-built.

---

## 1. What this engine is

`flutterwindcss` is Tailwind CSS v4's **design system and styling vocabulary**, expressed as a typed, compile-time Flutter API over the framework's primitive widgets layer (`package:flutter/widgets.dart`). It provides:

1. A **token system** — the Tailwind v4 palette, the semantic shadcn token set, and the full Tailwind v4 scales (spacing, radius, shadow, typography, opacity, border-width, z-index, breakpoints).
2. **Provider-agnostic theme access** — `context.fw`, resolving a Material-free `FwTheme` first and falling back to a Material `FwThemeExtension`, so identical component code works in a bare `WidgetsApp` and inside a `MaterialApp`.
3. The **`FwStyle` resolver + `.tw` utility API** — Tailwind's utility vocabulary as typed method chains that accumulate into one immutable description and resolve to a single composed widget, with first-class interaction states, viewport-responsive breakpoints, and container queries.

It is **Material-free** (visuals/components), directional-by-default (RTL is free), and accessible by construction.

### Mental model

Flutter has no structure/style split and no CSS cascade — the widget tree *is* the styling. We re-create Tailwind's **vocabulary and token discipline**, not a CSS engine. Theming works by **semantic indirection** (shadcn-style): consumers reference role-named tokens (`primary`, `muted`, `border`), never raw swatches, so swapping the theme reskins everything.

---

## 2. Non-Goals (owned by other sub-projects, not deferred features of this engine)

These are **separate products** in the monorepo, each with its own spec → plan → build cycle. They are not part of the styling engine and their absence here is a scope boundary, not a stub:

- **flutterbits components** (`registry/`) — `FwButton` et al. The engine is their dependency; they are authored against it later.
- **The theme generator** (`apps/docs`, TypeScript) — the tweakcn→`theme.dart` OKLCH pipeline. Per AGENTS.md §7, color math lives **only** there. This engine consumes `FwTokens`; it never parses or converts CSS color strings.
- **The registry builder + CLI** (`flutterbits_cli`, `tooling/`).
- **The docs site + example showcase app** beyond the minimal golden-test harness this engine needs.

What the engine *does* own and ships complete: every token, every utility family in §6/§12, state variants, viewport responsive, container queries, animated theming, RTL, accessibility hooks, and the deterministic golden-test harness.

---

## 3. Architecture overview

```
context.fw  ─────────────►  FwTokens (colors · radii · shadows · typography · scales)
   │                              ▲
   │  resolves                    │ provided by
   ▼                              │
FwTheme (InheritedWidget)  ──┐    │
FwThemeExtension (Material) ─┴────┘

widget.tw  ──►  FwStyled (StatelessWidget, wraps child + FwStyle)
                   │  hosts FocusableActionDetector → Set<WidgetState>
                   │  hosts LayoutBuilder/MediaQuery → BoxConstraints + viewport Size
                   ▼
                FwStyle.resolve(context, states, constraints) ──► ResolvedStyle
                   │
                   ▼
                primitive build chain (outer→inner):
                ConstrainedBox → Transform → Opacity → DecoratedBox(shadow,bg,border,radius)
                  → ClipRRect(if overflow) → Padding → DefaultTextStyle+IconTheme → child
```

The keystone is that **`FwStyle` is a lazy resolver, not a static property bag.** Resolution takes the interaction-state set and the layout/viewport size, so state variants and responsive breakpoints are first-class inputs rather than features bolted on later.

---

## 4. Token system (`lib/src/tokens/`)

All token values are sourced from the **Tailwind v4 default theme** and **shadcn default theme**, verified against current official docs during implementation (not reproduced from memory). All token types are `@immutable`, `const`-constructible, expose `lerp` for animated theming, and override `==`/`hashCode`.

### 4.1 `FwPalette` (`tokens/palette.dart`)
The raw Tailwind v4 color palette — every hue (`slate, gray, zinc, neutral, stone, red, orange, amber, yellow, lime, green, emerald, teal, cyan, sky, blue, indigo, violet, purple, fuchsia, pink, rose`) × shades `50,100,…,900,950`, plus `black`/`white`. Values are the Tailwind v4 OKLCH definitions, converted **once at authoring time** to `Color` (sRGB) and embedded as `const`. Exposed as `FwPalette.blue.shade500` etc.

> Rationale: components use semantic tokens only (AGENTS.md §3.1). The palette exists to **build** themes (the default `FwTokens`, and to give app authors the Tailwind vocabulary for non-themeable one-offs). It is not the conversion pipeline — these are baked constants, the generator (§2) owns runtime conversion.

### 4.2 `FwColors` (`tokens/colors.dart`)
The 19 semantic tokens (the contract the generator targets):
`background, foreground, card, cardForeground, popover, popoverForeground, primary, primaryForeground, secondary, secondaryForeground, muted, mutedForeground, accent, accentForeground, destructive, destructiveForeground, border, input, ring`.
`const` constructor, static `lerp(a, b, t)` lerping every field with `Color.lerp`.

### 4.3 `FwRadii` (`tokens/radii.dart`)
Built two ways:
- `FwRadii.fromBase(double base)` — derives the shadcn-style set used by components: `sm = base×0.6, md = base×0.8, lg = base×1.0, xl = base×1.4`, plus `none = 0` and `full = Radius.circular(9999)`.
- The full Tailwind v4 named scale (`xs .125rem, sm .25rem, md .375rem, lg .5rem, xl .75rem, 2xl 1rem, 3xl 1.5rem, 4xl 2rem`) is available on `FwRadii` for utility use.
Values are `Radius`/`double`; `lerp` provided.

### 4.4 `FwShadows` (`tokens/shadows.dart`)
The Tailwind v4 box-shadow scale (`2xs, xs, sm, md, lg, xl, 2xl`) and inset variants, each a `List<BoxShadow>`. Verified values, e.g. `sm = [0 1px 3px rgb(0 0 0 /.1), 0 1px 2px -1px rgb(0 0 0 /.1)]`. `lerp` lerps shadow lists element-wise.

### 4.5 `FwTypography` (`tokens/typography.dart`)
- **Font-size scale** `xs…9xl` with paired line-heights (Tailwind v4 `--text-*` + `--text-*--line-height`).
- **Font-weight** `thin(100)…black(900)`.
- **Tracking** (letter-spacing) `tighter…widest`.
- **Leading** (line-height) `tight…loose`.
- **Font families** — `sans/serif/mono` family *names* only. The engine never bundles fonts; `google_fonts` wiring is the host app's concern. Unknown families surface as the platform default with no silent substitution claim.

### 4.6 Scalar scales (`tokens/scales.dart`)
- **Spacing:** base `0.25rem` → `fwSpace(double units) => units * 4.0` logical px (1 unit = 4 px). Fractional units supported (`fwSpace(0.5)` = 2 px).
- **Opacity:** `0…100` step scale → `double`.
- **Border-width:** `0,1,2,4,8` px.
- **Z-index:** `0,10,20,30,40,50`.
- **Breakpoints:** `FwBreakpoint { sm 640, md 768, lg 1024, xl 1280, xl2 1536 }` (Tailwind v4 `40/48/64/80/96rem` at 16px root). Min-width, mobile-first.
- **Blur:** `xs…3xl` (4…64 px) for `blur`/`backdrop-blur`.

### 4.7 `FwTokens` (`tokens/tokens.dart`)
Bundles the per-theme resolved values a component reads:
```dart
class FwTokens {
  final FwColors colors;
  final FwRadii radii;        // .fromBase(radius) for the active theme
  final FwShadows shadows;
  final FwTypography typography;
  final double radiusBase;    // the shadcn --radius this theme was built from
  const FwTokens({...});
  static FwTokens lerp(FwTokens a, FwTokens b, double t);
  static const FwTokens light = /* shadcn-neutral defaults */;
  static const FwTokens dark  = /* shadcn-neutral defaults */;
}
```
`FwTokens.light/dark` carry the stock shadcn-neutral values so the engine is usable and testable standalone. This is **not** duplicating the generator — the generator emits *custom* `FwTokens`; these are sane defaults. The palette/scales (radii named scale, shadows, typography, breakpoints, blur, z, border-width, spacing) are theme-independent constants and are exposed directly, not per-`FwTokens`.

---

## 5. Theme access (`lib/src/theme/`)

### 5.1 `FwTheme` (`theme/fw_theme.dart`)
An `InheritedWidget` carrying the active `FwTokens`. Light/dark switching is the host app's job (AGENTS.md §5): the host provides whichever instance is active. `updateShouldNotify` compares tokens identity/value.

### 5.2 `FwThemeExtension` (`theme/fw_theme_extension.dart`)
A `ThemeExtension<FwThemeExtension>` carrying `FwTokens`, with `copyWith` and `lerp` (so Material's theme animation drives `FwTokens.lerp` correctly). **This file is the single sanctioned `package:flutter/material.dart` import in the entire repo** (AGENTS.md §3.5). No other engine or component file imports Material.

### 5.3 `context.fw` (`theme/context_fw.dart`)
```dart
extension FwContext on BuildContext {
  FwTokens get fw { /* see resolution */ }
}
```
Resolution order:
1. `dependOnInheritedWidgetOfExactType<FwTheme>()` → its `tokens`.
2. else `Theme.of(this).extension<FwThemeExtension>()?.tokens`.
3. else throw a `FlutterError` with a clear, actionable message ("No FwTheme or FwThemeExtension found in the widget tree. Wrap your app in FwTheme(...) or add FwThemeExtension to your ThemeData.extensions.") and a `DiagnosticsNode` chain.

Components read tokens **only** via `context.fw` (AGENTS.md §3.4) — never `Theme.of` directly.

---

## 6. The `FwStyle` resolver + `.tw` API (`lib/src/style/`)

### 6.1 Data model
`FwStyle` (`style/fw_style.dart`) is `@immutable`. It stores **base** utility values plus **layers** (state + responsive + container closures, captured as resolved sub-`FwStyle`s). All base fields are nullable (null = unset):

- **Spacing:** `padding (EdgeInsetsDirectional?)`, `margin (EdgeInsetsDirectional?)`, `gap (double?)`.
- **Sizing:** `width, height, minWidth, minHeight, maxWidth, maxHeight (double?)`, `widthFactor, heightFactor (double?)` for fractional, `aspectRatio (double?)`.
- **Color/decoration:** `background (Color?)`, `gradient (Gradient?)`, `borderColor (Color?)`, `borderWidth (double?)`, `borderRadius (BorderRadiusDirectional?)`, `boxShadow (List<BoxShadow>?)`.
- **Foreground/text:** `foreground (Color?)`, `fontSize, fontWeight, letterSpacing, lineHeight (… ?)`, `textAlign (TextAlign?)`, `textDecoration (TextDecoration?)`.
- **Effects:** `opacity (double?)`, `blur (double?)`, `backdropBlur (double?)`.
- **Layout (when child is a flex):** `flexDirection (Axis?)`, `mainAxisAlignment`, `crossAxisAlignment`, `wrap (bool?)`.
- **Transform:** `scale, rotation (double?)`, `translate (Offset?)`.
- **Overflow/clip:** `clipBehavior (Clip?)`.
- **Layers:** `Map<FwStateKey, FwStyle> stateLayers`, `List<(_BreakpointKind, double, FwStyle)> responsiveLayers` (ordered).

**Last-wins** is intrinsic: each utility returns a `copyWith` overwriting just its field(s), so `.px(4).px(2)` ⇒ padding 8 px.

### 6.2 `FwStyled` (`style/fw_styled.dart`)
The widget the user actually places in the tree:
```dart
extension TwExtension on Widget {
  FwStyled get tw => FwStyled._(child: this, style: const FwStyle());
}
```
`FwStyled` is a `StatelessWidget` exposing every utility method (each returns a new `FwStyled` with an updated `FwStyle` — immutable, chainable, last-wins). Its `build`:
1. Wraps in `LayoutBuilder` (for container queries + constraints) and reads `MediaQuery.sizeOf` (for viewport responsive).
2. Wraps in `FocusableActionDetector` to source `Set<WidgetState>` (hovered/focused/pressed/disabled) — **only if** any state layer or interactivity is present, to avoid needless focus nodes.
3. Calls `style.resolve(context, states, constraints)` → `ResolvedStyle`.
4. Renders `ResolvedStyle.build(child)`.

### 6.3 Resolution (`style/resolve.dart`)
```dart
ResolvedStyle FwStyle.resolve(BuildContext context, Set<WidgetState> states, BoxConstraints c);
```
`ResolvedStyle` is the flattened concrete value set (non-nullable defaults applied). Layering precedence (deterministic, documented, unit-tested):
1. **Base** values.
2. **Responsive layers** whose breakpoint is satisfied (viewport for `.sm/.md/…`, constraint width for `.containerSm/…`), applied **ascending by breakpoint** so the largest satisfied wins (mobile-first, matches Tailwind).
3. **State layers** for currently-active `WidgetState`s, applied in **declared order** (last-declared active state wins).

Each layer is merged field-by-field via the same last-wins overwrite. Responsive and state are orthogonal axes; both are flattened in the single `resolve` pass.

### 6.4 Render chain (`ResolvedStyle.build`)
Hand-composed primitives, **fixed documented order**, outer→inner; each wrapper emitted only if its inputs are set:
```
ConstrainedBox(min/max w/h)
  → Transform(scale/rotate/translate)
    → Opacity
      → BackdropFilter(backdropBlur)
        → DecoratedBox(BoxDecoration: gradient|color, Border.all(color,width), BorderRadiusDirectional, boxShadow)
          → ClipRRect(if clipBehavior)
            → Padding(EdgeInsetsDirectional)
              → DefaultTextStyle.merge + IconTheme.merge (foreground, font*, align, decoration)
                → ImageFiltered(blur)   // content blur, distinct from backdropBlur
                  → child
```
`margin` renders as an outermost `Padding` above `ConstrainedBox`. Flex utilities apply when `child` is a `Flex`/the style declares a flex container (composed via `Flex` with the resolved axis/alignment/gap). The order is asserted by widget tests so it never silently drifts.

### 6.5 Utility surface (complete — see §12 for the module each lands in)
Directional throughout (AGENTS.md §3.3); spacing args in utility units:
`p, px, py, ps, pe, pt, pb · m, mx, my, ms, me, mt, mb · gap · w, h, minW, minH, maxW, maxH, wFull, hFull, wFraction, hFraction, square, aspect · bg, bgGradient · border, borderColor, borderWidth, borderX/Y/S/E · rounded, roundedT/B/S/E, roundedAll, roundedNone, roundedFull · shadow(FwShadow) · opacity · blur, backdropBlur · text(color), fontSize, fontWeight, leading, tracking, textAlign, underline/lineThrough · row, col, wrap, items*, justify* · scale, rotate, translate · clip · hover, focus, pressed, disabled, whenState · sm, md, lg, xl, xl2 · containerSm…container2xl`.

---

## 7. RTL & accessibility

- **RTL:** every spacing/alignment/radius API is directional (`EdgeInsetsDirectional`, `AlignmentDirectional`, `BorderRadiusDirectional`). The engine never exposes a `left/right` variant. RTL is correct with zero consumer effort. A golden test renders a representative styled widget under both `TextDirection.ltr` and `rtl`.
- **Accessibility:** the engine is styling, so it does not impose semantics — but it **must not erase** them. `FwStyled` is semantics-transparent (wraps, never replaces, the child's `Semantics`). `FocusableActionDetector` exposes focus state for the visible focus-ring utility (`ring` token). Components add roles/labels; the engine guarantees it never swallows them (asserted by a test that a `Semantics(button:true)` child survives a full `.tw` chain).

---

## 8. Public API surface (`lib/flutterwindcss.dart`)

The barrel re-exports exactly the supported surface (AGENTS.md §3.6): `context.fw`, the `.tw` extension + `FwStyled`, `FwStyle` (for advanced composition), `FwTokens/FwColors/FwRadii/FwShadows/FwTypography`, `FwPalette`, `FwTheme`, `FwThemeExtension`, the enums (`FwShadow`, `FwBreakpoint`, `FwState…`), and `fwSpace`. Nothing under `lib/src/` is importable by consumers. Adding to the surface is always allowed; **renaming/removing requires a deprecation cycle** (every copied component in the wild pins these names).

---

## 9. Coding conventions

Per AGENTS.md §4: `Fw`-prefixed public types; `const` wherever the analyzer allows; **typed enums + exhaustive `switch`** for all variant resolution (no `default:` papering over new cases); `dart format` at 100 cols; `flutter analyze` with **zero** warnings; `///` doc-comments on every public member explaining *why* for non-obvious choices; `Color.withValues(alpha:)` never `withOpacity`. No runtime string-parsing of styles (AGENTS.md §3.7) — utilities are typed method calls resolved at compile time.

---

## 10. Testing strategy (`test/` + `apps/example` golden harness)

Every module is **done only when** unit + golden tests are green and `flutter analyze` is clean.

- **Unit tests** (`test/`):
  - `FwStyle` last-wins per field; a chain flattens to one `ResolvedStyle`.
  - Layer precedence: base < responsive(larger wins) < state(last-declared wins); responsive×state orthogonality.
  - `resolve` honors `states` and `constraints` (hover changes bg; `md` breakpoint changes padding at width≥768; `containerMd` keys off constraint width).
  - Render chain: each wrapper present iff its field is set; documented order asserted via the pumped element tree.
  - `context.fw` resolves `FwTheme`; falls back to `FwThemeExtension` inside a `MaterialApp`; throws the clear error when neither exists.
  - Token `lerp` midpoints (colors, radii, shadows, typography, full `FwTokens.lerp`).
  - Palette/scale values spot-checked against the documented Tailwind v4 numbers.
- **Golden tests** (in `apps/example`, the compile+golden target): representative styled widgets per module, **light + dark**, **LTR + RTL**, plus interaction states pumped (hover/focus/pressed/disabled). Uses `matchesGoldenFile`.
- **Deterministic golden harness (built in module 1, not deferred):** goldens are generated and verified **only in a pinned Linux CI container** with a bundled fixed font (Tailwind v4 font rendering differs across Windows/macOS/Linux — see Risk R1). `flutter_test_config.dart` loads the fixed font and disables shadow rasterization variance. Local `--update-goldens` on Windows is documented as non-authoritative; CI is the source of truth. This resolves the AGENTS.md §9 "deterministic across machines" requirement with a concrete mechanism rather than a claim.

---

## 11. Risks & mitigations

- **R1 — Golden non-determinism across OS.** Flutter goldens depend on platform font hinting. *Mitigation:* CI-only golden generation in a pinned container with a bundled font (§10). Authoritative goldens never come from a dev machine.
- **R2 — `MediaQuery`-based responsive vs. tests.** Viewport responsive needs a `MediaQuery` ancestor. *Mitigation:* `FwStyled` reads `MediaQuery.maybeOf` and treats absence as "smallest breakpoint" (base only) rather than throwing; tests pump explicit `MediaQuery` sizes.
- **R3 — `FocusableActionDetector` cost when unused.** *Mitigation:* only inserted when the style declares state layers or focus/ring; pure-static styles render without it.
- **R4 — Palette OKLCH→sRGB authoring accuracy.** Baked palette constants must match Tailwind's intent. *Mitigation:* convert via a documented one-off script using the same OKLCH→OKLab→linear-sRGB→gamut-map math the generator will use, and spot-check against published Tailwind hex equivalents in a unit test. (The *runtime* pipeline still lives only in the generator per §2; this is authoring-time only.)
- **R5 — Container queries + responsive both wrapping in `LayoutBuilder`/`MediaQuery`.** Potential rebuild overhead. *Mitigation:* single `LayoutBuilder` per `FwStyled`, only when responsive/container layers exist; static styles skip it.

---

## 12. Delivery: complete-module sequence

The architecture above is fixed up front. Implementation lands as modules, **each 100% complete (impl + unit + golden + analyzer-clean) when merged** — no stubs, no cross-module TODOs.

| # | Module | Lands |
|---|--------|-------|
| 0 | **Scaffold** | `git` repo, root pub-workspace `pubspec.yaml`, `packages/flutterwindcss` package skeleton, barrel, analysis_options (100-col, strict), the pinned-font golden harness + `flutter_test_config.dart`, CI workflow running analyze+test+golden in the pinned container. |
| 1 | **Tokens** | `FwPalette` (full v4 palette, baked), `FwColors`, `FwRadii`, `FwShadows`, `FwTypography`, scalar scales, `FwTokens` + `light/dark`, all `lerp`. Unit tests + value spot-checks. |
| 2 | **Theme access** | `FwTheme`, `FwThemeExtension`, `context.fw`, both paths + error. Tests incl. `MaterialApp` fallback. |
| 3 | **Resolver core** | `FwStyle`, `ResolvedStyle`, `FwStyled`, render chain, the state/responsive/container layering engine + precedence. The `.tw` entry. Tests for last-wins, precedence, render order, RTL transparency, semantics transparency. |
| 4 | **Spacing + sizing** | padding/margin/gap, w/h/min/max, fractional, aspect. Unit + golden. |
| 5 | **Color + border + radius + gradient** | bg, gradient, border (directional), radius (directional + named + full), using semantic tokens. Unit + golden (light/dark). |
| 6 | **Typography** | size/weight/leading/tracking/align/decoration via `DefaultTextStyle`/`IconTheme`. Unit + golden. |
| 7 | **Effects** | shadow (token scale), opacity, blur, backdrop-blur. Unit + golden. |
| 8 | **Layout + container queries** | flex (row/col/wrap/gap/align/justify), position/inset, aspect, overflow/clip, the `.containerSm…` family. Unit + golden. |
| 9 | **Transforms** | scale/rotate/translate. Unit + golden. |
| 10 | **Animated theming** | `FwAnimatedTheme` driving `FwTokens.lerp` over a duration/curve. Unit + golden (mid-transition pump). |

Modules 4–9 each also add their utilities' **state + responsive + container** variants (the layering engine from module 3 makes this uniform, not per-utility work).

**Definition of done (whole engine):** every module merged; `flutter analyze` zero warnings; `flutter test` green; all goldens reviewed; the public barrel (§8) stable; a smoke example in `apps/example` renders a fully-`.tw`-styled widget in both a bare `WidgetsApp` and a `MaterialApp`, light/dark, LTR/RTL.

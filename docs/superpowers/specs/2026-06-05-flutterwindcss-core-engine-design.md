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
3. The **`FwStyle` resolver + `.tw` utility API** — Tailwind's utility vocabulary as typed method chains that accumulate into one immutable description (last-wins on conflicts, no duplicate wrappers) and resolve to a composed primitive subtree, with first-class interaction states, viewport-responsive breakpoints, and container queries. Multi-child layout (flex/stack/grid) is handled by dedicated widgets (§6.6), not the single-child chain.

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

The engine has **two distinct surfaces** (see §6.0 for why the split is structural, not stylistic):

- **`.tw` — single-box styling.** An extension on a single `Widget` that styles *that box*: padding, margin, background, border, radius, shadow, opacity, blur, transform, text defaults, sizing, aspect, clip. Everything here genuinely composes onto one child.
- **Layout widgets — multi-child structure.** `FwRow`/`FwColumn`/`FwWrap`/`FwStack`/`FwPositioned`/`FwGrid`. These own the concerns that need multiple children or a stacking context: flex direction/alignment, `gap`, positioning, `inset`, `z-index`. They produce a single subtree that `.tw` can then style as a box.

```
context.fw  ─────────────►  FwTokens (colors · radii · shadows · typography · scales)
   │                              ▲
   │  resolves                    │ provided by
   ▼                              │
FwTheme (InheritedWidget)  ──┐    │
FwThemeExtension (Material) ─┴────┘

widget.tw  ──►  FwStyled (StatelessWidget, wraps ONE child + FwStyle)
                   │  hover/focus/pressed layer present? → MouseRegion + non-traversable Focus + Listener → Set<WidgetState>
                   │  responsive/container layers present? → MediaQuery (viewport) and/or
                   │                                          LayoutBuilder (container) → Size/constraints
                   ▼
                FwStyle.resolve(states, viewportWidth:, containerWidth:) ──► ResolvedStyle   (nested layers flattened)
                   │
                   ▼
                primitive build chain — see §6.4 for the exact, test-asserted order

FwRow/FwColumn/FwWrap/FwStack/FwPositioned/FwGrid  ──►  multi-child layout (own widgets, not .tw)
```

The keystone is that **`FwStyle` is a lazy resolver, not a static property bag.** Resolution takes the interaction-state set and the layout/viewport size, so state variants and responsive breakpoints are first-class inputs rather than features bolted on later. Layers are **nested** (a layer's value is itself an `FwStyle`), so combined conditions like `md:hover:` resolve jointly.

---

## 4. Token system (`lib/src/tokens/`)

All token values are sourced from the **Tailwind v4 default theme** and **shadcn default theme**, verified against current official docs during implementation (not reproduced from memory). All token types are `@immutable`, `const`-constructible, expose `lerp` for animated theming, and override `==`/`hashCode`.

### 4.1 `FwPalette` (`tokens/palette.dart`)
The raw Tailwind v4 color palette — every hue (`slate, gray, zinc, neutral, stone, red, orange, amber, yellow, lime, green, emerald, teal, cyan, sky, blue, indigo, violet, purple, fuchsia, pink, rose`) × shades `50,100,…,900,950`, plus `black`/`white`. The baked `const Color` values are **Tailwind's own published sRGB hex** (e.g. `orange-500 = #ff6900`), as shown on tailwindcss.com/docs/colors — transcribed, not re-derived. Exposed as `FwPalette.blue.shade500` etc.

> **Conversion policy (important, easy to get wrong).** Tailwind v4 defines colors in OKLCH but **publishes gamut-*clipped* sRGB hex** (kept close to its legacy v3 hex). For the ~79 saturated out-of-gamut shades, that clipped hex differs from the CSS-Color-4 *gamut-mapped* value a browser renders. The baked palette **matches Tailwind's published hex** (so `FwPalette.orange.shade500` is the `#ff6900` developers recognize), **not** the gamut-mapped value.
> - **Baked palette** = transcribe Tailwind's published (clipped) hex.
> - **Generator default** (AGENTS.md §7) = the *same* faithful-clip conversion, so a pasted shadcn/Tailwind theme yields the colors developers recognize and **agrees with `FwPalette`** by construction. (Opt-in perceptual/gamut-map mode exists for extreme out-of-gamut colors or a P3 target.)
>
> So palette and generator-default are **coherent** — they use one conversion philosophy. The earlier "they differ by design" framing was superseded by the §7 decision to default the generator to Tailwind-fidelity; gamut-mapping is the opt-in, not the default.

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
- **Z-index:** `0,10,20,30,40,50` — consumed by `FwStack`/`FwPositioned` paint ordering (not a `.tw` utility; a single box has no stacking context).
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
`FwTokens.light/dark` carry the stock shadcn-neutral values so the engine is usable and testable standalone. This is **not** duplicating the generator — the generator emits *custom* `FwTokens`; these are sane defaults. They are composed **purely from already-baked `const Color` palette literals** (§4.1) — no OKLCH→sRGB conversion runs at `const`-eval time (Dart cannot; conversion is the authoring-time script of R4). So `light/dark` are genuine compile-time constants, not runtime-computed. The palette/scales (radii named scale, shadows, typography, breakpoints, blur, z, border-width, spacing) are theme-independent constants and are exposed directly, not per-`FwTokens`.

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

### 6.0 Why `.tw` is single-box and layout is separate widgets
`.tw` is `extension on Widget` — it wraps exactly **one** child and styles that box. That structurally rules out any concern needing multiple children or a stacking context: flex (`Row`/`Column` need `children:`), `gap` (a between-children property of a flex, not injectable into an already-built child), positioning/`inset`/`z-index` (need a `Stack` ancestor). A wrapper cannot reach into a constructed `Row` and rewrite its `children`/`spacing`. So those concerns live in **dedicated layout widgets** (§6.6), and `FwStyle` carries **only** what genuinely composes onto a single box. This is a hard boundary, decided here, so it never gets bent back into the chain.

What this does **not** sacrifice: the accumulator's real value is **last-wins conflict resolution** and **emitting no duplicate/redundant wrappers** — not literal element flatness. The render chain (§6.4) is intentionally a multi-level nest of explicit primitives; that explicitness (vs. a single `Container`) is what buys precise ordering and avoids `Container`'s `color`-vs-`decoration` assertion. "One widget" means *one node in the author's code*, not one element at runtime.

### 6.1 Data model
`FwStyle` (`style/fw_style.dart`) is `@immutable`. It stores **base** single-box values plus **nested layers**. All base fields are nullable (null = unset):

- **Spacing:** `padding (EdgeInsetsDirectional?)`, `margin (EdgeInsetsDirectional?)`.
- **Sizing:** `width, height, minWidth, minHeight, maxWidth, maxHeight (double?)`, `widthFactor, heightFactor (double?)` (fractional), `factorAlignment (AlignmentDirectional?)`, `aspectRatio (double?)`.
- **Color/decoration:** `background (Color?)`, `gradient (Gradient?)`, `borderSpec (FwBorderSpec? — four directional edges)` resolving at resolve-time to a uniform `Border` or a `BorderDirectional` `BoxBorder`, `borderRadius (BorderRadiusDirectional?)`, `boxShadow (List<BoxShadow>?)`. *(Corrected — module 5: the working name `border`/`BorderSideSpec` became the field **`borderSpec`** of type **`FwBorderSpec`** — it describes the whole four-edge border, not one side, and the field was renamed off `border` so the `.border(...)` utility can own that name since `FwStyle` mixes in the setter ops. The M3 `BoxBorder? border` placeholder had no setter, so the rename broke nothing.)*
- **Foreground/text:** `foreground (Color?)`, `fontSize, fontWeight, letterSpacing, lineHeight (… ?)`, `textAlign (TextAlign?)`, `textDecoration (TextDecoration?)`.
- **Effects:** `groupOpacity (double?)`, `contentBlur (double?)`, `backdropBlurSigma (double?)` — renamed from `opacity`/`blur`/`backdropBlur` (corrected — module 7) so the Tailwind-natural `.tw` setters `opacity`/`blur`/`backdropBlur` don't collide with the fields. `ResolvedStyle` keeps the terse render-chain names (`opacity`/`blur`/`backdropBlur`); the resolve projection maps between the two. Plus `boxShadow (List<BoxShadow>?)` (set by `shadow`).
- **Transform:** `scale, rotation (double?)`, `translate (Offset?)`.
- **Overflow/clip:** `clipBehavior (Clip?)`.
- **Layers (nested):** `List<FwLayer> layers`, where `FwLayer = (FwCondition condition, FwStyle style)` and `FwCondition` is one of `state(WidgetState)`, `viewport(FwBreakpoint)`, or `container(FwBreakpoint)`. A layer's `style` is a full `FwStyle` and **may itself contain layers**, so `.md((s) => s.hover((s2) => …))` produces a `viewport(md)` layer whose nested style has a `state(hovered)` layer — `md:hover:` resolves jointly (Finding #8). Layers preserve declaration order.

**Last-wins** is intrinsic: each base utility returns a `copyWith` that **overwrites** just its field(s) — it is replacement, never accumulation. In `.px(4).px(2)`, the second call overwrites the first: the `.px(4)` is **discarded** and the resolved horizontal padding is `2` units = **8 logical px** (`fwSpace(2)`), not `4+2`. Each variant method (`.hover`, `.md`, …) instead **appends** a layer.

### 6.2 `FwStyled` (`style/fw_styled.dart`)
The widget the user places in the tree:
```dart
extension TwExtension on Widget {
  FwStyled get tw => FwStyled._(child: this, style: const FwStyle());
}
```
`FwStyled` is a `StatelessWidget` exposing every base + variant utility (each returns a new `FwStyled` with an updated `FwStyle`). Its `build` inserts ancestors **conditionally**, so a purely-static style is a lean tree:
1. **If** any `viewport`/`container` layer exists → read `MediaQuery.maybeOf(context)?.size` for viewport conditions, and wrap in a single `LayoutBuilder` for `container` conditions. If neither layer kind exists, neither is inserted. (Viewport uses `MediaQuery`, **not** `LayoutBuilder`, so it does not break intrinsic sizing — see R6.) The `LayoutBuilder` wraps the *entire* resolve+build, **outside** the §6.4 sizing wrappers — so **container queries measure the box's incoming constraint width** (the space the parent offers), **not** the box's own post-`width`/`min`/`max` size (Finding #1). This is deliberate: it is well-defined and avoids a feedback cycle where a `container` layer that sets `width` would change the very width it is measured against. Documented on every `.containerXx` utility.
2. **If** any layer is keyed on a **live-sourced** state (`hover`/`focus`/`pressed`) **at any nesting depth** → wrap to source those states live. The check is computed once over the **flattened** layer set (recursing into nested layers), so `md:hover:` (a `state` layer nested under a `viewport` layer) still gets sourced at large viewports. **Component-managed** states (`selected`, `disabled`, …) are *not* live-sourced — they are injected via `FwStyled.states` and resolve without any interaction wrapper. **Mechanism (corrected — module 3):** visual-only live sourcing uses `MouseRegion` (hover) + a **non-traversable** `Focus` (`canRequestFocus: false`, `skipTraversal: true`; focus) + `Listener` (press), **not** `FocusableActionDetector`. FAD's internal `Focus` overrides a passed node's `canRequestFocus`/`skipTraversal` while `enabled`, so it *cannot* be made non-traversable — it would add a tab stop, violating §7. The chosen primitives add no tab stop (Finding #9). A real focusable detector + visible `ring` is added by an interactive **component** (which owns the action), not by the engine.
3. Calls `style.resolve(states, viewportWidth: …, containerWidth: …)` → `ResolvedStyle`.
4. Renders `ResolvedStyle.build(child)`.

### 6.3 Resolution (`style/resolve.dart`)
```dart
// Two widths are passed separately (corrected — module 3): a viewport layer
// keys off the screen size, a container layer off the enclosing constraint, so
// one can never satisfy the other. `FwStyled` supplies each from its own source
// (MediaQuery vs LayoutBuilder); resolution itself needs no BuildContext.
ResolvedStyle FwStyle.resolve(Set<WidgetState> states, {double? viewportWidth, double? containerWidth});
```
`ResolvedStyle` is the flattened concrete value set (non-nullable defaults applied). Algorithm:
1. **Disabled suppression first (Finding #7):** if `WidgetState.disabled ∈ states`, remove `hovered`/`focused`/`pressed` from the working set before any layer matching, and the pressed gesture recognizer is guarded so it cannot re-add `pressed`. Disabled therefore always wins regardless of declaration order.
2. Start from **base** fields.
3. Walk `layers` in declaration order; a layer **matches** when its condition holds (`state` ∈ working set; a **viewport** breakpoint ≤ `viewportWidth`; a **container** breakpoint ≤ `containerWidth` — the two widths are kept distinct). For each matching layer, **recurse**: resolve its nested `FwStyle` against the same `(states, viewportWidth, containerWidth)` and merge the result field-by-field (last-wins). Because matching layers are applied in declaration order, the **last-declared matching layer wins** among equals; nested recursion gives joint `md:hover:` semantics for free.
4. Apply non-null defaults → `ResolvedStyle`.

Precedence is deterministic, documented, and unit-tested (base < matching layers in declared order; nested conditions resolve jointly; disabled suppresses interaction states).

### 6.4 Render chain (`ResolvedStyle.build`)
Hand-composed primitives, **fixed order, asserted by widget tests**, outer→inner; each wrapper emitted only if its inputs are set. Note the decoration **splits into a shadow layer and a surface layer** so that backdrop-blur (which must be clipped) does not clip away the shadow:
```
Padding(margin, EdgeInsetsDirectional)                       ← margin is outermost
  → ConstrainedBox(min/max)  ⊕  SizedBox(width/height)       ← sizing rules below
    → AspectRatio(aspectRatio)
      → FractionallySizedBox(widthFactor/heightFactor, alignment: factorAlignment)
        → Transform(scale/rotate/translate)                  ← transforms the rendered result incl. shadow
          → ImageFiltered(blur)                              ← CONTENT blur: filters the WHOLE element
            → Opacity(opacity)                               ← only when group opacity is needed (else folded)
              → _ShadowBox(boxShadow only, UNCLIPPED)        ← shadow paints here, outside any clip
                → _Surface:
                    IF backdropBlur set:
                      ClipRRect(borderRadius)                ← clips the backdrop to the box shape
                        → BackdropFilter(backdropBlur)       ← blurs content painted BEHIND the box
                          → DecoratedBox(gradient|color, border, radius)   ← composites ON TOP of backdrop
                    ELSE:
                      DecoratedBox(gradient|color, border, radius)
                  → ClipRRect(borderRadius INSET by borderWidth, if clipBehavior != none)  ← clips CONTENT
                    → Padding(padding, EdgeInsetsDirectional)
                      → DefaultTextStyle.merge + IconTheme.merge (foreground, font*, align, decoration)
                        → child
```
`borderSpec` resolves to `Border.fromBorderSide(side)` (uniform — all four edges equal) or `BorderDirectional(start/end/top/bottom)` (per-side) — Finding #5. **Flutter limitation (as-built, module 5):** Flutter's painter rounds a border **only** when it is uniform; a per-side `BorderDirectional` combined with a `borderRadius` throws in `BorderDirectional.paint`. The render chain surfaces this as a **clear debug `assert`** at build time (rather than Flutter's cryptic paint-time crash) — "use a uniform border when rounding, or drop the radius." The content **clip** may still round freely under a per-side border; the limitation is only the decoration's stroke. Per-side *rounded* borders would need a custom `RenderObject` and are out of v1 scope (AGENTS.md §11 spirit). Specifics the tests pin (because the order is asserted):

- **Backdrop-blur layering (Finding #1):** `BackdropFilter` sits **above** the surface `DecoratedBox` (so the semi-transparent decoration composites over the blurred backdrop, matching CSS `backdrop-filter`) and is wrapped in its own `ClipRRect(borderRadius)` so it only frosts the box region. `boxShadow` is therefore moved to the outer, **unclipped** `_ShadowBox` so the clip required by backdrop-blur never eats the shadow. Content `blur` (`ImageFiltered`, Finding #4) is the *opposite* filter — it blurs the element's own rendering (bg + border + content) and wraps the whole element. The two are distinct layer positions and both are golden-tested.
- **Transform vs. shadow ordering (Finding #2):** `boxShadow` paints in the inner `_ShadowBox`, beneath the outer `Transform`; this is intentional and correct — `Transform` transforms the already-rendered result (including the shadow), matching CSS `transform`. Do not "fix" this by hoisting the shadow above the transform.
- **Transform is paint-only, not layout (review note #2):** `scale`/`rotate`/`translate` change painting and hit-testing geometry but **not** the box's layout footprint — a `.scale(1.5)` box still occupies its unscaled size, so it visually overlaps siblings in an `FwRow` and does not reflow (matches CSS `transform`). Documented on the transform utilities so a web dev expecting reflow isn't surprised.
- **Sizing reconciliation (Finding #6):** a fixed `width`/`height` produces a **tight** constraint and **wins on its axis**; `min*/max*` apply only to axes without a fixed value. Setting both a fixed dim and a `min/max` on the *same* axis throws an `assert` in debug (fixed-wins in release). `widthFactor`/`heightFactor` use `FractionallySizedBox` with author-settable `factorAlignment` (default `AlignmentDirectional.centerStart`).
- **ClipRRect geometry (Finding #3):** the content clip reuses the decoration's `BorderRadiusDirectional`, deflating **each corner by its two adjacent edge widths** (read directionally off the resolved `BoxBorder`), clamped at 0, so clipped content never bleeds across the stroke. *(Status: **landed in module 5** alongside the `.border`/`.rounded`/`.clip` setters it is coupled to — the content clip now deflates by the per-edge border width; with no border the un-deflated radius is used. Asserted in `render_chain_test`.)*
- **Opacity (Finding #11):** opacity folds into the **solid `background` alpha** only when the box has a solid background **and** no `gradient`, no `boxShadow`, and no child needing group opacity (e.g. an empty/overlay box) — in that case no `Opacity`/`saveLayer` is emitted. Whenever a gradient, shadow, or real child content is present, a true `Opacity` layer is used (folding alpha into a shadow or one gradient stop would not reproduce group opacity). *(Status: module 3 always emits a true `Opacity` (always correct); the fold is a **deferred perf optimization** behind the same tests.)*

### 6.5 `.tw` utility surface (single-box; see §12 for the landing module)
Directional throughout (AGENTS.md §3.3); spacing args in utility units:
`p, px, py, ps, pe, pt, pb · m, mx, my, ms, me, mt, mb · w, h, minW, minH, maxW, maxH, wFull, hFull, wFraction(f, {align}), hFraction(f, {align}), square, aspect · bg, bgGradient · border, borderColor, borderWidth, borderS/E/T/B (per-side) · rounded, roundedT/B/S/E, roundedAll, roundedNone, roundedFull · shadow(FwShadow) · opacity · blur, backdropBlur · text(color), fontSize, fontWeight, leading, tracking, textAlign, underline/lineThrough · scale, rotate, translate · clip · hover, focus, pressed, disabled, whenState · sm, md, lg, xl, xl2 · containerSm…container2xl`.

> `square` is sugar for `aspectRatio: 1` (writes the `aspectRatio` field, so it last-wins against `aspect`); it does **not** set `width == height`. `wFraction`/`hFraction` take an optional `align` (→ `factorAlignment`), the only way to control fractional-size alignment.
>
> **Units (module 5):** unlike spacing/sizing (utility units, `fwSpace`), **border-width and radius args are in logical px** — `border(2)` is 2 px (Tailwind's `0/1/2/4/8` border scale) and `rounded(t.radii.md)` takes a token value directly. `border(w, {color})` is uniform; `borderWidth`/`borderColor` set one axis keeping the other (order-independent); `borderS/E/T/B` are per-edge. `rounded` overwrites all corners; `roundedT/B/S/E` merge per-corner; `roundedNone`/`roundedFull` are getters; `roundedAll` is an explicit synonym of `rounded`. `clip([Clip = antiAlias])` lands here too (it was unassigned in §12; the Finding #3 deflation needs it).
>
> **Typography (module 6):** the as-built utilities are `text(Color) · textSize(double) · weight(int) · leading(double) · tracking(double) · align(TextAlign) · underline · lineThrough`. The §6.5 list above wrote `fontSize`/`fontWeight`/`textAlign`, but those collide with the `FwStyle` **fields** of the same name (the mixin can't redeclare them), so the utilities took collision-free Tailwind-faithful names (`textSize`/`weight`/`align`) — the fields are unchanged. `weight` takes the **CSS int scale** `100..900` (the `FwFontWeight` token values) and maps to a Flutter `FontWeight`. `textSize` is logical px (`FwFontSize.*.px`); `leading` is a line-height **multiple** (`FwLeading.*`); `tracking` is **absolute logical px** (Flutter's model — *not* em; the em-based `FwTracking` scale must be multiplied by the font size at the call site). `textSize`/`leading` assert `> 0`; `weight` asserts a valid step; `tracking` may be negative. `underline`/`lineThrough` **combine** (Tailwind-style) rather than last-wins. Text goldens use Flutter's built-in deterministic test font (no bundled face).
>
> **Effects (module 7):** `shadow(List<BoxShadow>) · opacity(double) · blur(double) · backdropBlur(double)`. The §6.5 list above wrote `shadow(FwShadow)`, but no `FwShadow` enum exists (the token is the `FwShadows` *scale* on `FwTokens.shadows`) and the ops layer has no context to resolve a selector — so `shadow` takes the **resolved list** the component reads from the theme: `shadow(context.fw.shadows.md)` (empty list = no shadow), mirroring `bg(Color)`. The `opacity`/`blur`/`backdropBlur` setters write the renamed `FwStyle` fields `groupOpacity`/`contentBlur`/`backdropBlurSigma` (§6.1). Guards: `opacity` in `0..1`; `blur`/`backdropBlur` sigmas `>= 0`. Backdrop blur is covered by `render_chain_test` (needs a textured backdrop), not the effects golden.
>
> `whenState(WidgetState, (s) => …)` accepts **any** `WidgetState`, but a layer only matches when that state is in the **active set**. `FwStyled` **live-sources `hovered/focused/pressed`** (via `MouseRegion`/non-traversable-`Focus`/`Listener`, corrected — module 3); every other state — including **`disabled`** — is **component-managed** and injected via `FwStyled`'s optional `states` parameter (or a `WidgetStatesController` it owns), never sourced by the engine. So `hover/focus/pressed` are the engine-sourced sugar; `disabled` and `whenState(...)` are the escape hatches for injected states, and an un-injected custom state is inert. (A style whose only state layers are component-managed resolves **statelessly** — no interaction wrappers are inserted.)

> Note: `row/col/wrap/gap/items*/justify*/position/inset/z` are **not** here — they belong to the layout widgets (§6.6).

### 6.6 Layout widgets (`lib/src/layout/`)
Multi-child structure the single-box chain cannot express. Each is a normal widget producing one subtree, so it can itself be styled with `.tw` (e.g. `FwColumn(...).tw.p(4).bg(c)`):

- **`FwRow` / `FwColumn`** — flex with typed `gap` (spacing inserted between children, in utility units), `mainAxisAlignment`, `crossAxisAlignment`, and `mainAxisSize` **defaulting to `MainAxisSize.max`** (Flutter's default — chosen deliberately to avoid layout surprises; web refugees expecting shrink-to-fit opt into `MainAxisSize.min` explicitly, and it's documented on the constructor). `gap` renders via `Flex`'s native `spacing` where available, else interleaved `SizedBox`.
- **`FwWrap`** — `Wrap` with directional run/cross spacing + alignment.
- **`FwStack` / `FwPositioned`** — stacking context; `FwPositioned` carries directional `inset` (`start/end/top/bottom`) and `z` for paint order (children sorted by `z`, then declaration order). This is where the `z-index` scale (§4.6) is consumed.
- **`FwGrid`** — the AGENTS.md §11 grid helper. **v1 grammar (pinned):** a single set of **column tracks** mixing `fr` (flex) and fixed-px tracks (e.g. `[Fr(1), Fr(2)]` or `[Px(200), Fr(1)]`) with a directional **column gap** and equal-structure wrapping rows — all implementable with `Flex`/`Expanded` (`fr` → `Expanded(flex:)`, fixed → `SizedBox`). **Cell/row spanning, auto-placement, and `subgrid` are Non-Goals** (AGENTS.md §11) and require a custom `RenderObject` we are *not* shipping in v1. "FwGrid ships complete" means complete *for this grammar*, stated so it's falsifiable.

Variant/responsive layering applies to layout widgets too (e.g. a responsive `gap`) via the same `FwStyle` layer engine, exposed through their constructors where it makes sense. All directional; all golden-tested LTR + RTL.

---

## 7. RTL & accessibility

- **RTL:** every spacing/alignment/radius API is directional (`EdgeInsetsDirectional`, `AlignmentDirectional`, `BorderRadiusDirectional`). The engine never exposes a `left/right` variant. RTL is correct with zero consumer effort. A golden test renders a representative styled widget under both `TextDirection.ltr` and `rtl`.
- **Accessibility:** the engine is styling, so it does not impose semantics — but it **must not erase or pollute** them. `FwStyled` is semantics-transparent (wraps, never replaces, the child's `Semantics`). Visual-only live-state styling uses a **non-traversable** `Focus` (`canRequestFocus: false`) plus `MouseRegion`/`Listener`, so a `hover:`-only box is reskinned **without** becoming a focus traversal stop and **without** adding a `focusable` semantics flag (§6.2, Finding #9 — verified: the merged node stays `focusable=false`). The visible focus-**ring** (`ring` token) belongs to an interactive **component**, which owns the action and makes its box genuinely focusable; the engine never invents focusability. Asserted by tests that (a) a `Semantics(button:true)` child survives a full `.tw` chain (static **and** interactive paths), and (b) a `hover:`-only box does **not** appear in focus traversal.

---

## 8. Public API surface (`lib/flutterwindcss.dart`)

The barrel re-exports exactly the supported surface (AGENTS.md §3.6): `context.fw`, the `.tw` extension + `FwStyled`, `FwStyle` (for advanced composition) and its public value types (`FwBorderSpec`, `FwLayer`/`FwCondition`), the layout widgets (`FwRow`, `FwColumn`, `FwWrap`, `FwStack`, `FwPositioned`, `FwGrid`), `FwTokens/FwColors/FwRadii/FwShadows/FwTypography`, `FwPalette`, `FwTheme`, `FwThemeExtension`, `FwAnimatedTheme`, the enums/scales (`FwBreakpoint`, `FwState`, `FwBlur`, `FwFontSize`, …), and `fwSpace`. (There is no `FwShadow` enum — corrected, module 7; the shadow scale is the exported `FwShadows` class, and `shadow()` takes a resolved `List<BoxShadow>`.) Nothing under `lib/src/` is importable by consumers. Adding to the surface is always allowed; **renaming/removing requires a deprecation cycle** (every copied component in the wild pins these names).

---

## 9. Coding conventions

Per AGENTS.md §4: `Fw`-prefixed public types; `const` wherever the analyzer allows; **typed enums + exhaustive `switch`** for all variant resolution (no `default:` papering over new cases); `dart format` at 100 cols; `flutter analyze` with **zero** warnings; `///` doc-comments on every public member explaining *why* for non-obvious choices; `Color.withValues(alpha:)` never `withOpacity`. No runtime string-parsing of styles (AGENTS.md §3.7) — utilities are typed method calls resolved at compile time.

---

## 10. Testing strategy (in-package `test/` + golden harness)

> Refinement (locked during planning): **engine goldens live in-package** at `packages/flutterwindcss/test/golden/` — a library tests its own widgets, and this avoids a premature cross-package app dependency. `apps/example` is the **component** compile + golden target (a later sub-project), not the engine's.

Every module is **done only when** unit + golden tests are green and `flutter analyze` is clean.

- **Unit tests** (`test/`):
  - `FwStyle` last-wins per field; a chain flattens to one `ResolvedStyle`.
  - Layer precedence: base < matching layers in declared order; **nested** `md:hover:` resolves jointly; **disabled suppresses** hover/focus/pressed (wins regardless of declaration order).
  - `resolve` honors `states` and `viewport`/width (hover changes bg; `md` breakpoint changes padding at viewport ≥768; `containerMd` keys off the `LayoutBuilder` constraint width).
  - Render chain: each wrapper present iff its field is set; documented order asserted via the pumped element tree.
  - `context.fw` resolves `FwTheme`; falls back to `FwThemeExtension` inside a `MaterialApp`; throws the clear error when neither exists.
  - Token `lerp` midpoints (colors, radii, shadows, typography, full `FwTokens.lerp`).
  - Palette/scale values spot-checked against the documented Tailwind v4 numbers.
- **Golden tests** (in-package, `packages/flutterwindcss/test/golden/`): representative styled widgets per module, **light + dark**, **LTR + RTL**, plus interaction states pumped (hover/focus/pressed/disabled). Uses `matchesGoldenFile`.
- **Deterministic golden harness (built in module 1, not deferred):** goldens are generated and verified **only in a pinned Linux CI container** with a bundled fixed font (Tailwind v4 font rendering differs across Windows/macOS/Linux — see Risk R1). `flutter_test_config.dart` loads the fixed font and disables shadow rasterization variance. Local `--update-goldens` on Windows is documented as non-authoritative; CI is the source of truth. This resolves the AGENTS.md §9 "deterministic across machines" requirement with a concrete mechanism rather than a claim.

---

## 11. Risks & mitigations

- **R1 — Golden non-determinism across OS.** Flutter goldens depend on platform font hinting. *Mitigation:* CI-only golden generation in a pinned container with a bundled font (§10). Authoritative goldens never come from a dev machine.
- **R2 — `MediaQuery`-based responsive vs. tests.** Viewport responsive needs a `MediaQuery` ancestor. *Mitigation:* `FwStyled` reads `MediaQuery.maybeOf` and treats absence as "smallest breakpoint" (base only) rather than throwing; tests pump explicit `MediaQuery` sizes.
- **R3 — interaction-sourcing cost + spurious focus when unused.** *Mitigation:* the `MouseRegion`/non-traversable-`Focus`/`Listener` wrappers are inserted **only** when a layer is keyed on a live-sourced state (`hover`/`focus`/`pressed`); component-managed states (`selected`/`disabled`) inject via `FwStyled.states` and resolve statelessly, and pure-static styles render with none of these. The visual-only `Focus` uses `canRequestFocus: false`, so it neither becomes a tab stop nor adds a `focusable` flag (§6.2, Finding #9). *(Corrected — module 3: `FocusableActionDetector` is **not** used here; its internal `Focus` overrides a passed node's `canRequestFocus`/`skipTraversal` while `enabled`, so it cannot be made non-traversable. A real focusable detector + ring lands with interactive components.)*
- **R4 — Palette must match Tailwind's *published* hex, not a re-derivation.** Baked palette constants must equal what Tailwind ships (and what every Tailwind reference shows), e.g. `orange-500 = #ff6900`. *Mitigation:* transcribe Tailwind's **published sRGB hex** into the source JSON; do **not** re-derive via gamut-mapping — Tailwind publishes gamut-*clipped* hex, so gamut-mapping would diverge from Tailwind for the ~79 out-of-gamut shades (see §4.1). A unit test pins out-of-gamut swatches (e.g. `orange-500`) to Tailwind's published hex so a bad transcription is caught. (This corrects the original R4, which wrongly said to use the generator's gamut-map math here — that math is for arbitrary user themes in the generator, not for reproducing Tailwind's own palette.)
- **R5 — Container queries + responsive rebuild overhead.** *Mitigation:* viewport responsive uses `MediaQuery` (no `LayoutBuilder`); a single `LayoutBuilder` is inserted only when `container` layers exist; static styles skip both.
- **R6 — `LayoutBuilder` breaks intrinsic sizing.** `LayoutBuilder` is a relayout boundary that does not report intrinsic dimensions, so an `FwStyled` carrying **container-query** layers placed inside `IntrinsicWidth`/`IntrinsicHeight` or a min/max-content measuring parent will misbehave. *Mitigation:* scoped to container-query usage only (viewport responsive is `MediaQuery`-based and unaffected); documented on the `.containerXx` API with the recommendation to avoid it under intrinsic-sizing ancestors. Not a silent failure — it is called out at the call site in docs.
- **R7 — `.tw`-vs-layout split is a public-API boundary.** Moving flex/position/z out of `.tw` must be right the first time (deprecation cost later). *Mitigation:* the boundary is fixed in §6.0 and covered by the barrel surface (§8); layout widgets ship complete in their module, not as an afterthought.

---

## 12. Delivery: complete-module sequence

The architecture above is fixed up front. Implementation lands as modules, **each 100% complete (impl + unit + golden + analyzer-clean) when merged** — no stubs, no cross-module TODOs.

| # | Module | Lands |
|---|--------|-------|
| 0 | **Scaffold** | `git` repo, root pub-workspace `pubspec.yaml`, `packages/flutterwindcss` package skeleton, barrel, analysis_options (100-col, strict), the pinned-font golden harness + `flutter_test_config.dart`, CI workflow running analyze+test+golden in the pinned container. |
| 1 | **Tokens** | `FwPalette` (full v4 palette, baked), `FwColors`, `FwRadii`, `FwShadows`, `FwTypography`, scalar scales, `FwTokens` + `light/dark`, all `lerp`. Unit tests + value spot-checks. **Freeze the `FwState` and `FwBreakpoint` enums here as frozen API contract** — they feed exhaustive `switch`es across nearly every later module, so a late addition forces re-touching all of them (and the zero-warning bar makes that loud). Treat them as final from module 1's first commit. |
| 2 | **Theme access** | `FwTheme`, `FwThemeExtension`, `context.fw`, both paths + error. Tests incl. `MaterialApp` fallback. |
| 3 | **Resolver core** ✅ landed | `FwStyle`, `ResolvedStyle`, `FwStyled`, render chain, the **nested** layering engine + precedence (incl. disabled suppression, joint `md:hover:`), **two-width** resolve (viewport vs container kept distinct), conditional `MediaQuery`/`LayoutBuilder`/interaction-sourcing (`MouseRegion`+non-traversable-`Focus`+`Listener`) insertion. The `.tw` entry. Ships the **padding + bg** base slice + the full variant surface; modules 4–9 add the rest. Tests for last-wins, precedence, nested resolution, render order, sizing reconciliation, focus-traversal hygiene, RTL + semantics transparency. **Landed in M5** (coupled to border width): content-clip radius **deflation** (Finding #3). **Deferred (perf-only)**: opacity fold (Finding #11) — an always-correct `Opacity` is emitted meanwhile. |
| 4 | **Spacing + sizing** ✅ landed | margin (`m/mx/my/ms/me/mt/mb`, per-edge merge), fixed/min/max sizing (`w/h/minW/minH/maxW/maxH`, `fwSpace` units), fractional (`wFraction`/`hFraction` + `align`, `wFull`/`hFull`), aspect (`aspect`/`square`) setters — the sizing reconciliation + render-chain wrappers already existed from module 3; this adds only the typed `.tw` setters. (`padding` shipped as module 3's slice.) Unit (`fw_sizing_ops_test`) + golden (`sizing_slice`, LTR/RTL × light/dark). (`gap` lands with the flex widgets in module 8.) |
| 5 | **Color + border + radius + gradient** ✅ landed | `bgGradient`; border via `FwBorderSpec` (uniform `border(w,{color})` + independent `borderWidth`/`borderColor` axes + per-edge `borderS/E/T/B`, directional); radius `rounded`/`roundedAll`/`roundedT/B/S/E` (per-corner merge) + `roundedNone`/`roundedFull`; `clip` (it was unassigned in this table; the deflation needs it). Renamed the M3 placeholder field `border`→`borderSpec` so `.border()` is free (`BorderSideSpec`→`FwBorderSpec`). **Landed the content-clip radius deflation by per-edge border width (Finding #3), deferred from module 3**, and a clear **assert** for the Flutter limitation that a per-side border can't be rounded (§6.4 Finding #5). Border-width/radius args are logical px (not utility units). Unit (`fw_border_spec_test`, `fw_color_ops_test`, updated `render_chain_test`) + golden (`decoration_slice`, light/dark × LTR/RTL). |
| 6 | **Typography** ✅ landed | `text(Color)`, `textSize(double px)`, `weight(int 100..900 → FontWeight)`, `leading(double ×)`, `tracking(double px)`, `align(TextAlign)`, `underline`/`lineThrough` (combine) — writing the M3 text fields consumed by the `DefaultTextStyle`/`IconTheme` merge. Utility names `textSize`/`weight`/`align` avoid the field/setter collision (`fontSize`/`fontWeight`/`textAlign` fields are unchanged); `tracking` is absolute px not em (documented); sizes/leading guarded `> 0`. Unit (`fw_text_ops_test`) + golden (`typography_slice`, light/dark × LTR/RTL, built-in deterministic test font). |
| 7 | **Effects** ✅ landed | `shadow(List<BoxShadow>)` (resolved token list, theme-aware — *not* an `FwShadow` enum, which doesn't exist; corrected), `opacity(double 0..1)`, `blur(double sigma)`, `backdropBlur(double sigma)` — over the M3 `_ShadowBox`/`Opacity`/`ImageFiltered`/`BackdropFilter` wrappers. The `FwStyle` effect fields were renamed (`opacity`→`groupOpacity`, `blur`→`contentBlur`, `backdropBlur`→`backdropBlurSigma`) to free the setter names; `ResolvedStyle`/render chain unchanged. Guards on range/sign. Unit (`fw_effect_ops_test`) + golden (`effects_slice`, shadow + opacity, light/dark). |
| 8 | **Layout widgets + container queries** | `FwRow`/`FwColumn`/`FwWrap`/`FwStack`/`FwPositioned`/`FwGrid` (flex/gap/align, positioning/inset/z, grid tracks) as dedicated multi-child widgets (§6.6), plus the `.containerSm…` query family on `.tw`. Unit + golden (LTR + RTL). |
| 9 | **Transforms** | scale/rotate/translate (`.tw`). Unit + golden. |
| 10 | **Animated theming** | `FwAnimatedTheme` — an **`ImplicitlyAnimatedWidget`** (Material-free) that tweens between the old and new `FwTokens` via `FwTokens.lerp` over a `duration`/`curve` whenever the `tokens` it's given change, providing the interpolated tokens down through `FwTheme`. It does **not** ride Material's `ThemeData` animation (the pure path has none). Unit + golden (mid-transition pump). |

Modules 4–9 each also add their utilities' **state + responsive + container** variants (the nested layering engine from module 3 makes this uniform, not per-utility work).

**Definition of done (whole engine):** every module merged; `flutter analyze` zero warnings; `flutter test` green; all goldens reviewed; the public barrel (§8) stable; an in-package smoke test renders a fully-`.tw`-styled widget in both a bare `WidgetsApp` and a `MaterialApp`, light/dark, LTR/RTL (a richer showcase in `apps/example` follows with the component sub-project).

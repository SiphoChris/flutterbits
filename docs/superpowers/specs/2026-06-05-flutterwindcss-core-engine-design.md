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
                   │  state layers/action present? → FocusableActionDetector → Set<WidgetState>
                   │  responsive/container layers present? → MediaQuery (viewport) and/or
                   │                                          LayoutBuilder (container) → Size/constraints
                   ▼
                FwStyle.resolve(context, states, size) ──► ResolvedStyle   (nested layers flattened)
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
- **Color/decoration:** `background (Color?)`, `gradient (Gradient?)`, `border (BorderSideSpec? perSide)` resolving to uniform `Border` or `BorderDirectional`, `borderRadius (BorderRadiusDirectional?)`, `boxShadow (List<BoxShadow>?)`.
- **Foreground/text:** `foreground (Color?)`, `fontSize, fontWeight, letterSpacing, lineHeight (… ?)`, `textAlign (TextAlign?)`, `textDecoration (TextDecoration?)`.
- **Effects:** `opacity (double?)`, `blur (double?)`, `backdropBlur (double?)`.
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
2. **If** any `state` layer exists **at any nesting depth** *or* the styled box is interactive → wrap in `FocusableActionDetector` to source `Set<WidgetState>`. The "has a state layer" check is computed once over the **flattened** layer set (recursing into nested layers), so `md:hover:` (a `state` layer nested under a `viewport` layer) still gets a detector at large viewports. For **visual-only** state styling (no `onPressed`/action), the detector is configured non-focusable (`descendantsAreFocusable: true`, own `skipTraversal: true`, no focus node) so a `hover:`-only card never becomes a tab stop (Finding #9). A real focus node + ring is added only when an action is present.
3. Calls `style.resolve(context, states, size)` → `ResolvedStyle`.
4. Renders `ResolvedStyle.build(child)`.

### 6.3 Resolution (`style/resolve.dart`)
```dart
ResolvedStyle FwStyle.resolve(BuildContext context, Set<WidgetState> states, Size? viewport);
```
`ResolvedStyle` is the flattened concrete value set (non-nullable defaults applied). Algorithm:
1. **Disabled suppression first (Finding #7):** if `WidgetState.disabled ∈ states`, remove `hovered`/`focused`/`pressed` from the working set before any layer matching, and the pressed gesture recognizer is guarded so it cannot re-add `pressed`. Disabled therefore always wins regardless of declaration order.
2. Start from **base** fields.
3. Walk `layers` in declaration order; a layer **matches** when its condition holds (`state` ∈ working set; `viewport`/`container` breakpoint ≤ available width). For each matching layer, **recurse**: resolve its nested `FwStyle` against the same `(states, viewport/width)` and merge the result field-by-field (last-wins). Because matching layers are applied in declaration order, the **last-declared matching layer wins** among equals; nested recursion gives joint `md:hover:` semantics for free.
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
`border` resolves to `Border.all(side)` (uniform) or `BorderDirectional(start/end/top/bottom)` (per-side) — Finding #5. Specifics the tests pin (because the order is asserted):

- **Backdrop-blur layering (Finding #1):** `BackdropFilter` sits **above** the surface `DecoratedBox` (so the semi-transparent decoration composites over the blurred backdrop, matching CSS `backdrop-filter`) and is wrapped in its own `ClipRRect(borderRadius)` so it only frosts the box region. `boxShadow` is therefore moved to the outer, **unclipped** `_ShadowBox` so the clip required by backdrop-blur never eats the shadow. Content `blur` (`ImageFiltered`, Finding #4) is the *opposite* filter — it blurs the element's own rendering (bg + border + content) and wraps the whole element. The two are distinct layer positions and both are golden-tested.
- **Transform vs. shadow ordering (Finding #2):** `boxShadow` paints in the inner `_ShadowBox`, beneath the outer `Transform`; this is intentional and correct — `Transform` transforms the already-rendered result (including the shadow), matching CSS `transform`. Do not "fix" this by hoisting the shadow above the transform.
- **Transform is paint-only, not layout (review note #2):** `scale`/`rotate`/`translate` change painting and hit-testing geometry but **not** the box's layout footprint — a `.scale(1.5)` box still occupies its unscaled size, so it visually overlaps siblings in an `FwRow` and does not reflow (matches CSS `transform`). Documented on the transform utilities so a web dev expecting reflow isn't surprised.
- **Sizing reconciliation (Finding #6):** a fixed `width`/`height` produces a **tight** constraint and **wins on its axis**; `min*/max*` apply only to axes without a fixed value. Setting both a fixed dim and a `min/max` on the *same* axis throws an `assert` in debug (fixed-wins in release). `widthFactor`/`heightFactor` use `FractionallySizedBox` with author-settable `factorAlignment` (default `AlignmentDirectional.centerStart`).
- **ClipRRect geometry (Finding #3):** the content clip reuses the decoration's `BorderRadiusDirectional`, deflated by `borderWidth`, so clipped content never bleeds across the stroke.
- **Opacity (Finding #11):** opacity folds into the **solid `background` alpha** only when the box has a solid background **and** no `gradient`, no `boxShadow`, and no child needing group opacity (e.g. an empty/overlay box) — in that case no `Opacity`/`saveLayer` is emitted. Whenever a gradient, shadow, or real child content is present, a true `Opacity` layer is used (folding alpha into a shadow or one gradient stop would not reproduce group opacity).

### 6.5 `.tw` utility surface (single-box; see §12 for the landing module)
Directional throughout (AGENTS.md §3.3); spacing args in utility units:
`p, px, py, ps, pe, pt, pb · m, mx, my, ms, me, mt, mb · w, h, minW, minH, maxW, maxH, wFull, hFull, wFraction(f, {align}), hFraction(f, {align}), square, aspect · bg, bgGradient · border, borderColor, borderWidth, borderS/E/T/B (per-side) · rounded, roundedT/B/S/E, roundedAll, roundedNone, roundedFull · shadow(FwShadow) · opacity · blur, backdropBlur · text(color), fontSize, fontWeight, leading, tracking, textAlign, underline/lineThrough · scale, rotate, translate · clip · hover, focus, pressed, disabled, whenState · sm, md, lg, xl, xl2 · containerSm…container2xl`.

> `square` is sugar for `aspectRatio: 1` (writes the `aspectRatio` field, so it last-wins against `aspect`); it does **not** set `width == height`. `wFraction`/`hFraction` take an optional `align` (→ `factorAlignment`), the only way to control fractional-size alignment.
>
> `whenState(WidgetState, (s) => …)` accepts **any** `WidgetState`, but a layer only matches when that state is in the **active set**. `FwStyled` sources `hovered/focused/pressed/disabled` from its `FocusableActionDetector`; states outside that set (`selected/error/dragged/…`) never match **unless a component injects them** via `FwStyled`'s optional `states` parameter (or a `WidgetStatesController` it owns). So the four sugar methods (`hover/focus/pressed/disabled`) cover everything the engine sources on its own; `whenState` is the documented escape hatch for component-managed states, and the docs state plainly that an un-injected custom state is inert.

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
- **Accessibility:** the engine is styling, so it does not impose semantics — but it **must not erase or pollute** them. `FwStyled` is semantics-transparent (wraps, never replaces, the child's `Semantics`). The `FocusableActionDetector` exposes focus state for the visible focus-ring utility (`ring` token) **only when an action is present**; visual-only state styling (e.g. `hover:` on a card) is non-focusable and adds no traversal stop (§6.2, Finding #9). Components add roles/labels; the engine guarantees it never swallows them or injects spurious tab stops — asserted by tests that (a) a `Semantics(button:true)` child survives a full `.tw` chain, and (b) a `hover:`-only box does **not** appear in focus traversal.

---

## 8. Public API surface (`lib/flutterwindcss.dart`)

The barrel re-exports exactly the supported surface (AGENTS.md §3.6): `context.fw`, the `.tw` extension + `FwStyled`, `FwStyle` (for advanced composition), the layout widgets (`FwRow`, `FwColumn`, `FwWrap`, `FwStack`, `FwPositioned`, `FwGrid`), `FwTokens/FwColors/FwRadii/FwShadows/FwTypography`, `FwPalette`, `FwTheme`, `FwThemeExtension`, `FwAnimatedTheme`, the enums (`FwShadow`, `FwBreakpoint`, `FwState…`), and `fwSpace`. Nothing under `lib/src/` is importable by consumers. Adding to the surface is always allowed; **renaming/removing requires a deprecation cycle** (every copied component in the wild pins these names).

---

## 9. Coding conventions

Per AGENTS.md §4: `Fw`-prefixed public types; `const` wherever the analyzer allows; **typed enums + exhaustive `switch`** for all variant resolution (no `default:` papering over new cases); `dart format` at 100 cols; `flutter analyze` with **zero** warnings; `///` doc-comments on every public member explaining *why* for non-obvious choices; `Color.withValues(alpha:)` never `withOpacity`. No runtime string-parsing of styles (AGENTS.md §3.7) — utilities are typed method calls resolved at compile time.

---

## 10. Testing strategy (`test/` + `apps/example` golden harness)

Every module is **done only when** unit + golden tests are green and `flutter analyze` is clean.

- **Unit tests** (`test/`):
  - `FwStyle` last-wins per field; a chain flattens to one `ResolvedStyle`.
  - Layer precedence: base < matching layers in declared order; **nested** `md:hover:` resolves jointly; **disabled suppresses** hover/focus/pressed (wins regardless of declaration order).
  - `resolve` honors `states` and `viewport`/width (hover changes bg; `md` breakpoint changes padding at viewport ≥768; `containerMd` keys off the `LayoutBuilder` constraint width).
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
- **R3 — `FocusableActionDetector` cost + spurious focus when unused.** *Mitigation:* only inserted when the style declares state layers or an action; and for visual-only states it is non-focusable (`skipTraversal`, no focus node) so it neither costs a focus node nor adds a tab stop (§6.2, Finding #9). Pure-static styles render without it entirely.
- **R4 — Palette OKLCH→sRGB authoring accuracy.** Baked palette constants must match Tailwind's intent. *Mitigation:* convert via a documented one-off script using the same OKLCH→OKLab→linear-sRGB→gamut-map math the generator will use, and spot-check against published Tailwind hex equivalents in a unit test. (The *runtime* pipeline still lives only in the generator per §2; this is authoring-time only.)
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
| 3 | **Resolver core** | `FwStyle`, `ResolvedStyle`, `FwStyled`, render chain, the **nested** layering engine + precedence (incl. disabled suppression, joint `md:hover:`), conditional `MediaQuery`/`LayoutBuilder`/`FocusableActionDetector` insertion. The `.tw` entry. Tests for last-wins, precedence, nested resolution, render order, sizing reconciliation, focus-traversal hygiene, RTL + semantics transparency. |
| 4 | **Spacing + sizing** | padding/margin, w/h/min/max, fractional (+ alignment), aspect, sizing reconciliation. Unit + golden. (`gap` lands with the flex widgets in module 8.) |
| 5 | **Color + border + radius + gradient** | bg, gradient, border (directional), radius (directional + named + full), using semantic tokens. Unit + golden (light/dark). |
| 6 | **Typography** | size/weight/leading/tracking/align/decoration via `DefaultTextStyle`/`IconTheme`. Unit + golden. |
| 7 | **Effects** | shadow (token scale), opacity, blur, backdrop-blur. Unit + golden. |
| 8 | **Layout widgets + container queries** | `FwRow`/`FwColumn`/`FwWrap`/`FwStack`/`FwPositioned`/`FwGrid` (flex/gap/align, positioning/inset/z, grid tracks) as dedicated multi-child widgets (§6.6), plus the `.containerSm…` query family on `.tw`. Unit + golden (LTR + RTL). |
| 9 | **Transforms** | scale/rotate/translate (`.tw`). Unit + golden. |
| 10 | **Animated theming** | `FwAnimatedTheme` — an **`ImplicitlyAnimatedWidget`** (Material-free) that tweens between the old and new `FwTokens` via `FwTokens.lerp` over a `duration`/`curve` whenever the `tokens` it's given change, providing the interpolated tokens down through `FwTheme`. It does **not** ride Material's `ThemeData` animation (the pure path has none). Unit + golden (mid-transition pump). |

Modules 4–9 each also add their utilities' **state + responsive + container** variants (the nested layering engine from module 3 makes this uniform, not per-utility work).

**Definition of done (whole engine):** every module merged; `flutter analyze` zero warnings; `flutter test` green; all goldens reviewed; the public barrel (§8) stable; a smoke example in `apps/example` renders a fully-`.tw`-styled widget in both a bare `WidgetsApp` and a `MaterialApp`, light/dark, LTR/RTL.

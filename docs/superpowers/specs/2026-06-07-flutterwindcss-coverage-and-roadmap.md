# flutterwindcss — Tailwind coverage & roadmap (gap analysis)

**Status:** living roadmap · **Date:** 2026-06-07 (last updated 2026-06-08) · **Audience:** engine maintainers planning the components/docs phase.

## Purpose

Map Tailwind's utility surface onto the flutterwindcss engine: what's shipped, what's
worth building next, what we deliberately delegate, and the small set that is genuinely
impossible in Flutter. This is a **prioritization** document, not a promise to clone every
Tailwind utility — we build "the things that matter and aren't a hard add."

### Guiding principles (from AGENTS.md §11/§12)

- **Only impossibility excuses not-building** — cost, code volume, "needs a `RenderObject`,"
  or "needs a bespoke protocol" are reasons to *plan*, not refuse. So the roadmap is sorted
  by **value × ease**, and almost everything is "buildable, someday," not "can't."
- **Three layers.** Tailwind is core utilities + official plugins + the CSS engine itself.
  They map to three homes: the **flutterwindcss engine** (core utilities), **flutterbits**
  components (opinionated styling like `prose`/forms), and the §11a impossible set (the CSS
  cascade machinery). A feature in the wrong layer is not "missing from the engine."
- **Don't rebuild what already works.** Two properties of the typed API mean some Tailwind
  features need no new code (see below).

## Distance to Tailwind (current — audited 2026-06-08)

Verified against the code by an adversarial review pass. Headline:

- **~96% of high-traffic, daily-use Tailwind utilities are built** (module 15 added scroll/
  rings/named sugar/gradients; modules 16–17 added `divide`, scroll-snap, `bg-image`, 3D
  transforms, `mix-blend-mode`, and `text-shadow`), and **~82–85% of Tailwind's *portable*
  utility surface** overall. The remaining distance is **breadth in the long tail**, not depth
  — and most of it is correctly the **flutterbits component layer** or genuinely impossible.
- **Everything developers reach for daily is done:** spacing, sizing, color, typography
  (incl. line-clamp/truncate/family/tracking), borders + radius (+ dashed/dotted + named
  sugar), shadows (+ named sugar), `ring`, opacity, blur, gradients (+ direction sugar),
  the full color-filter set + object-fit, transforms, the complete flex/grid/stack/scroll
  layout vocabulary, responsive + container variants, and hover/focus/pressed/disabled +
  group/peer states.
- **Two multipliers** make effective coverage higher than a raw class count: arbitrary
  values are native, and `bgGradient`/`shadow` are pass-through (radial/conic gradients and
  arbitrary shadows already work).
- **Verified against the full v4 catalog (2026-06-08):** an authoritative pass over every
  Tailwind v4 utility section (Layout, Flex/Grid, Spacing, Sizing, Typography, Backgrounds,
  Borders, Effects, Filters, Tables, Transitions, Transforms, Interactivity, SVG, A11y) found
  the remaining unbuilt-*engine* items are the by-demand niche below — everything else is
  delegated or a stated no-analog. A follow-up pass (also 2026-06-08) caught a long tail of
  lower-frequency utilities that were absent from every bucket; they are now enumerated with
  verdicts + mechanisms in **"Full long-tail enumeration"** below, so the catalog cross-check
  is genuinely exhaustive (nothing silently missing).
- **Legitimately out (not counted against the engine):** animation → `flutter_animate`
  (§11b); forms/prose/tables (border-collapse/spacing/table-layout/caption)/SVG (fill/stroke)/
  `sr-only`/`accent-color`/`caret-color`/`resize`/`appearance-none`/`field-sizing`/list-style →
  the flutterbits component layer.
- **By-demand niche (feasible, not yet built):** `inset-shadow`/`inset-ring` (custom painter),
  `mask-*` (ShaderMask family), backdrop **color** filters (needs a shader; forward color
  filters are built), `columns` (multi-column RenderObject), negative margins (`-m-*`; no
  faithful Flutter layout analog — asserts cleanly), `scroll-margin`/`scroll-padding`/
  `overscroll-behavior`/`scrollbar-width`/gutter, `order`, `bg-radial`/`bg-conic` named sugar
  (pass-through already works), text-decoration styling (color/style/thickness), `font-variant-
  numeric`. Each has a Flutter mechanism; none blocks the next phase.
- **Genuinely impossible / no analog (tiny):** true CSS cascade, pseudo-elements/`content`,
  `float`/`clear`, `touch-action`, `box-decoration-break`, `text-wrap: balance/pretty`, `auto`
  hyphenation, `bg-attachment: fixed`. **`text-transform`** is impossible *as a render-time
  style* (Flutter's `TextStyle` has no transform hook) but feasible as content mutation — left
  out by product decision (2026-06-08). (`will-change` was previously listed here; it is
  actually **feasible** via `RepaintBoundary` — corrected to By-demand in the long-tail table
  below, a capability-raising fix per §12.)

**Built since the early summary (modules 13–17):** transform extras + interactivity + `size`
(13); **`group-*` / `peer-*`** (14); the **ergonomics** layer (15 — gradient sugar, `ring`,
named-scale `shadow*`/`rounded*`, `FwScroll`, dashed/dotted borders); **`divide`** +
**scroll-snap** (16); and **`bg-image`** + **3D transforms** (`rotateX/Y` + `perspective`) +
**`mix-blend-mode`** + **`text-shadow`** (17). There is **no remaining high-value daily-driver
miss** in the engine — the leftover items are the by-demand niche and delegated/impossible sets
listed in the headline. The engine is ready for the components/docs phase.

By-demand / larger (still unbuilt): sticky (L, slivers), backdrop color filters (M), negative
margins (M). (`scroll-snap`, dashed borders, and `bg-image` from the earlier version of this
line are now **shipped** — modules 15–17.)

**Engine audit status:** an adversarial review of the full engine (resolver cascade, render
chain, grid render object, tokens/lerp, modules 11–12) found **no correctness bugs**; one
hardening gap was fixed (`FwGridItem` span cap, matching the existing line-number cap) and
the object-fit bounded-constraint behavior was documented. The example app now has widget
smoke tests (every section, light/dark, LTR/RTL) and is covered by CI.

## Full long-tail enumeration (2026-06-08 — nothing silently dropped)

A second adversarial pass cross-checked **every** Tailwind v4 utility section against the
code and against the lists above, specifically hunting for utilities that were *absent from
both the code and every bucket here* (i.e. silently missing). The pass found the items below.
They were previously unlisted; each now has a verdict and a Flutter mechanism so the §12
"no silent scope reduction" bar holds. **None is a daily-driver; none blocks the next phase.**

Verdict legend as above, plus **Free/N-A** (Flutter's model makes it a no-op or it is already
covered) and **No-analog** (genuinely impossible — §11a bar: no faithful Flutter implementation).

| Utility (Tailwind v4) | Verdict | Flutter mechanism / reason | Size |
|---|---|---|---|
| `order-*` (flex/grid item order) | **By-demand** | Sort children by an order key at `FwRow`/`FwColumn`/`FwGrid` build, or resolve at the list-building site (you own child order, like `:nth-child`). | S |
| `isolation` (`isolate`) | **By-demand** | Wrap a subtree in a `RepaintBoundary`/`saveLayer` to form a new compositing group so `mix-blend-mode` blends *within* it. Companion to the shipped `mix-blend-mode`. | S–M |
| `overscroll-behavior` (`overscroll-*`) | **By-demand** | A knob on `FwScroll` selecting `ScrollPhysics` (clamping/never) + an `OverscrollNotification` boundary. | S |
| `background-blend-mode` | **By-demand** | `BoxDecoration.backgroundBlendMode` — blends a box's own color/gradient/image *layers* (distinct from element-level `mix-blend-mode`, which is shipped). | S |
| `bg-clip` / **`bg-clip-text`** | **By-demand** | Gradient text via `ShaderMask` over the `Text`; `bg-clip-padding/border` via `clipBehavior`. The highest-demand item here (gradient headings). | M |
| `bg-origin` | **By-demand** | `DecorationImage` alignment + a padding-aware origin. | S |
| `outline-*` (distinct from `ring`) | **By-demand** | Mostly covered by the shipped `ring`; a literal CSS `outline` (outside the border-box, no layout effect) is another zero-inset spread shadow or a painted stroke. | S |
| `drop-shadow-*` **filter** (alpha-following) | **By-demand** | `ImageFiltered` with a blur+offset compose — follows the alpha channel (non-rectangular), unlike the rectangular box `shadow-*` which is shipped. | M |
| `text-indent` | **By-demand** | Leading `WidgetSpan` inset or `Text.rich` first-line indent. | S |
| `vertical-align` | **By-demand** | `PlaceholderAlignment`/`textBaseline` on inline `WidgetSpan` (inline/rich-text only). Block-level alignment is already layout (`FwStack`/align). | S–M |
| `word-break` / `overflow-wrap` (`break-all`/`break-words`) | **By-demand** | `softWrap` covers normal wrapping; `break-all` needs zero-width-space injection or a custom line-breaker. | M |
| `scroll-behavior` (`scroll-smooth`) | **By-demand** | Animate via the `FwScroll` `ScrollController` (`animateTo`); programmatic-scroll concern. | S |
| `will-change` | **By-demand** (was mis-listed Impossible — capability-raising correction, §12) | `RepaintBoundary` is Flutter's faithful layer-promotion hint; `will-change` is an optimization hint, not a visual, so it is feasible, not impossible. | S |
| `user-select-*` | **Delegate** | `SelectionArea`/`SelectableText` — a content/component concern, → flutterbits. | — |
| `box-sizing` (`box-border`/`box-content`) | **Free/N-A** | Flutter has no content-box model; our decoration always sizes the border-box (`box-border`). `box-content` has no faithful analog and is not needed. | — |
| `text-wrap: balance` / `pretty` | **No-analog** | Flutter's line breaker has no balanced/pretty mode; no faithful implementation (§11a bar). | — |
| `hyphens` (true hyphenation) | **No-analog** | Flutter has no hyphenation dictionary hook; `manual` (soft-hyphen) works via the character itself, but `auto` hyphenation has no analog. | — |
| `bg-attachment: fixed` | **No-analog** | A viewport-fixed background needs scroll-coupled paint Flutter does not model; `local`/`scroll` are the default behavior. | — |
| `line-clamp-none` (reset inside a layer) | **Known limitation (general)** | One instance of a general rule, not a special case: the whole-field overlay has no "unset" sentinel, so a responsive/state/group layer can *override* but never *clear* a field back to unset. Fields with an inverse setter (`notItalic`/`visible`/`wrap`/`borderSolid`/`shadowNone`/`roundedNone`) can be re-set in a layer; the rest (`maxLines`/`lineClamp`, `aspectRatio`, `fit`, `blendMode`, color filters, `mouseCursor`, transforms, fractional align) are override-only in a layer — set the desired value at the base instead. Documented on `FwStyle`. | — |

This list plus the headline buckets covers the v4 **utility** catalog. A second adversarial pass
(below) extended the cross-check to **variants** and a set of utility micro-gaps the first pass had
not literally enumerated — so the "nothing silently dropped" guarantee now holds for the *whole* v4
surface, variants included.

## Second exhaustive cross-check (2026-06-10 — utilities *and* variants)

A five-front reconciliation took the authoritative v4 surface from tailwindcss.com and matched **every
utility and every variant** against the code + the buckets above. It found **no broken claim** (nothing
the engine advertises is missing) but surfaced items that were feasible/delegated/impossible yet **not
literally bucketed anywhere** — concentrated in (1) the variant tail and (2) low-level transition
utilities. All are recorded here with a verdict + mechanism; none touches a §3 hard rule, none is a
daily-driver miss, and the first pass's verdicts are unchanged.

### Utility micro-gaps (newly enumerated)

| Utility (v4) | Verdict | Flutter mechanism / reason | Size |
|---|---|---|---|
| `object-position` (`object-top`/`-left`/…) | **By-demand** | `fit()` maps to `FittedBox` but hard-codes center; add an optional directional `alignment` param passed to `FittedBox.alignment`. | S |
| `overline` (text-decoration-line) | **By-demand (trivial)** | `TextDecoration.overline` exists; the `underline`/`lineThrough` getters silently omit the third line — add an `overline` getter mirroring them via `_addDecoration`. | S |
| `underline-offset-*` | **No-analog** | Flutter `TextStyle` exposes `decorationThickness` but **no** underline-offset; only achievable via a custom text painter. (The first pass listed decoration color/style/thickness as By-demand but omitted offset, which is actually *less* feasible.) | — / M (painter) |
| `decoration-{color}` / `-{style}` / `-{thickness}` | **By-demand** | `TextStyle.decorationColor`/`decorationStyle`/`decorationThickness` (already noted L59-60; re-confirmed). | S |
| `font-stretch-*` | **By-demand** | Variable fonts only: `FontVariation('wdth', pct)` via `TextStyle.fontVariations`. Static fonts have no width axis. | S |
| `font-smoothing` (`antialiased`/`subpixel`) | **No-analog** | Flutter has no per-`TextStyle` smoothing switch (a `-webkit-`/`-moz-` rendering hint, not a portable style). | — |
| `whitespace-pre`/`-pre-line`/`-pre-wrap`/`break-spaces` | **By-demand** | Only `whitespace-normal`(`wrap`)/`-nowrap`(`nowrap`) are built; the `pre*` family needs explicit `softWrap`/`Text` whitespace handling. (Coverage's generic "whitespace ✅" overstated — corrected.) | S–M |
| `hyphens-none` / `-manual` | **Built/Free** | `manual` works via the soft-hyphen character; `none` is the default (no auto breaker). Only `hyphens-auto` is No-analog (already listed). | — |
| `*-min` / `*-max` / `*-fit` (min/max/fit-content) | **By-demand** | Intrinsic sizing → `IntrinsicWidth`/`IntrinsicHeight` / `mainAxisSize.min` (layout-widget territory, not a px value). | S–M |
| `w-screen`/`h-screen`, `*-dvw/dvh/lvh/svh`, container scale `3xs..7xl`, `*-lh` | **Free/N-A** | Arbitrary-value-first: pass the resolved px (viewport units via `MediaQuery`; `lh` = leading×fontSize). No named keyword needed. | — |
| `m-auto` / `mx-auto` (auto-margin centering) | **Delegate → layout** | Centering/pushing is `Align`/`Spacer`/`mainAxisAlignment` on the layout widgets, not a single-box setter (like `space-*`→`gap`). | — |
| logical **block-axis** spacing `pbs/pbe`, `mbs/mbe` | **Free/N-A** | Single (horizontal) writing mode ⇒ block-start/end ≡ `pt`/`pb`/`mt`/`mb`, already built. (Inline `ps/pe/ms/me` are the directional ones that matter.) | — |
| `bg-repeat-space` / `bg-repeat-round` | **By-demand** | `ImageRepeat` has only `{repeat,repeatX,repeatY,noRepeat}`; `space`/`round` need a custom `DecorationImagePainter` computing whole-tile counts + gaps / rescale. | M |
| `border-double` / `divide-double` | **By-demand** | `BorderStyle` is `{none,solid}`; add a `double` case to `FwDashedBorderPainter`/`FwBorderStyle` painting two split strokes. | S–M |
| gradient interpolation modifiers (`/oklch`, `/longer`…) | **Free/N-A** | Flutter `Gradient` interpolates in sRGB only; no per-gradient colorspace hook (cosmetic — affects mid-tones). | — |
| `mask-type` (alpha/luminance) | **By-demand (fold into `mask-*`)** | The blanket `mask-*` (ShaderMask) entry targets CSS `mask-image`; `mask-type` is the SVG-`<mask>` alpha-vs-luminance selector — express via `ShaderMask` + optional luminance matrix. | M |
| `drop-shadow-*` **filter** (alpha-following) | **By-demand** | Already listed L107 (`ImageFiltered` blur+offset); re-confirmed distinct from box `shadow`. | M |
| backdrop **color** filters (`backdrop-brightness`…`-opacity`) | **By-demand** | Already listed (L57/215); the family note covers all eight. | M |
| **transition** utilities — `transition`/`-property`, `duration-*`, `ease-*`, `delay-*`, `transition-discrete` | **Delegate → `flutter_animate`** | The element-animation delegation (§11b) covers these, but only `animate-*` was named. The low-level sub-property utilities map to `flutter_animate`'s `duration`/`curve`/`delay` (and `Curves.*` for `ease-*`); enumerated here so they're not silently missing. | — |
| `transform-style` (`transform-3d`/`preserve-3d`, `transform-flat`) | **By-demand** | Nested 3D composition needs a custom multi-child render object propagating the parent `Matrix4`+perspective into children. The natural completion of the shipped `rotateX/Y`+`perspective`. | L |
| `backface-visibility` (`backface-hidden`) | **By-demand** | After a 3D rotate, cull paint when the transformed normal faces away (sign of z) — flip-card staple. | S–M |
| `perspective-origin-*` | **By-demand** | Offset the vanishing point: translate around the `Matrix4.setEntry(3,2,…)` perspective entry; one directional setter. | S |
| `scale-z-*` / `scale-3d` / `translate-z-*` | **By-demand** | Add z entries to the transform `Matrix4`; only meaningful under perspective (like `rotateX/Y`). Lowest-frequency 3D piece. | S |
| `transform-gpu` / `transform-cpu` | **Free/N-A** | Flutter always composites transforms on the GPU; these are no-op hints. | — |
| `columns` fragmentation `break-before/after/inside` | **No-analog (screen) / By-demand (in `columns`)** | Flutter models no paged/fragmentation media; within a future multi-column render object, `break-inside-avoid` is a feasible per-child hint. | M |
| `grid-flow-col` (column auto-flow) | **By-demand** | A column-major placement pass in `RenderFwGrid._place` (row-flow + `dense` are built; column-flow is documented on `FwGrid` as a limitation — echoed here). | M |
| `position: fixed` | **By-demand** | Viewport-pinned via `Overlay`/`OverlayEntry` or a top-level `FwStack` (companion to the `sticky` entry). | M |
| `color-scheme` | **Free/N-A** | The light/dark `FwTokens` selection the host drives **is** color-scheme; no separate utility needed. | — |
| `scroll-snap-stop` (`snap-always`/`-normal`) | **By-demand** | A bool on `_FwSnapPhysics` clamping the fling target to ±1 page. | S |
| `scroll-snap-type` (`snap-mandatory`/`-proximity`/`-none`/axis) | **By-demand** | Axis = `FwScroll.axis`; `snapExtent` already implies mandatory-on-axis; proximity = a threshold in `createBallisticSimulation`; `none` = `snapExtent: null`. | S–M |
| `scrollbar-color` | **By-demand (half-built)** | `FwScroll.thumbColor` already wired; expose `RawScrollbar.trackColor` too. | S |
| `scrollbar-gutter` | **By-demand** | Reserve scrollbar-thickness padding (already named L58). | S |
| `scroll-behavior` (`scroll-smooth`) | **By-demand** | Already listed L111 (`ScrollController.animateTo`). | S |
| SVG `fill` / `stroke` / **`stroke-width`** | **Delegate / By-demand** | `fill`/`stroke` are icon theming (`Icon(color:)` / `lucide_icons_flutter`, a sanctioned dep) → flutterbits; `stroke-width` (`Paint.strokeWidth` in `CustomPaint`/`flutter_svg`) was unnamed — now recorded. | S |
| `forced-color-adjust` | **No-analog / Free** | Flutter has no forced-colors/system-palette-override mode to opt out of (honors `MediaQuery.highContrast` only). | — |
| `sr-only` / `not-sr-only` | **Delegate → flutterbits** (already L52) | Mechanism is engine-trivial (`Semantics(label:…, child: SizedBox.shrink())`); kept with components since it pairs with accessible component markup. | S |
| `appearance`/`accent-color`/`caret-color`/`field-sizing`/`resize` | **Delegate → flutterbits** (already L52) | Form-control concerns. | — |

### Variants (the under-documented surface)

The first pass covered the **utilities** but treated variants as "done" because the daily ones are. Full
reconciliation of the v4 variant system:

**Built / first-class:** `hover` `focus` `active`(pressed) `disabled` + `whenState(WidgetState,…)` for any
component-injected state; `sm`–`2xl` + container `@sm`–`@2xl`; `group-*`/`peer-*` (hover/focus/pressed/
disabled, **named**); stacking (`md:hover:` ⇒ nested layers); arbitrary breakpoints (`min-[…]`, native);
arbitrary values (`[…]`, native); RTL/LTR (directional-by-default, free). `:first/:last/:odd/:even/:nth`
resolve at the **list-building site** (you own child order).

| Variant(s) (v4) | Verdict | Flutter mechanism / reason |
|---|---|---|
| component-state pseudo-classes: `checked` `required` `valid`/`invalid` `open` `target` `read-only` `placeholder-shown` `indeterminate` `enabled` `default` `optional` `in-range`… | **Built (via `whenState`)** | These are component-owned booleans → inject the matching `WidgetState` and key a layer with `whenState`. Now documented as the path (was implicit). |
| `focus-within`, `focus-visible` | **By-demand** | `focus-within` = a wrapper `Focus(onFocusChange)` feeding `groupFocus`; `focus-visible` = `FocusManager.highlightMode == traditional`. |
| `has-*`, `group-has-*`, `peer-has-*`, `in-*` | **By-demand** | The inverse of `group-*`: a descendant→ancestor `Notification` channel mirroring `FwGroup`. |
| `not-*` | **By-demand** | Invert a matched condition in the resolver. |
| `aria-*`, `data-*`, `supports-*` | **By-demand** | Bridge to `whenState` (arbitrary boolean states); `supports-*` ≈ a capability check at build. |
| media variants: `motion-safe`/`motion-reduce`, `portrait`/`landscape`, `contrast-more`/`-less`, `pointer-*`/`any-pointer-*`, `inverted-colors` | **By-demand** | A resolver `FwMediaCondition` reading `MediaQuery` (`disableAnimations`, `orientation`, `highContrast`, `navigationMode`/gesture settings). |
| `dark` (as a per-utility variant) | **Free/N-A (by design)** | Dark mode is a whole-theme swap (`FwAnimatedTheme` + dark `FwTokens`), not a per-box `dark:` layer — the semantic-token model reskins everything from one switch. Stated as a design difference. |
| pseudo-elements `placeholder` `marker` `selection` `first-line` `first-letter` `file` `backdrop` `details-content` | **No-analog / component** | Same class as `::before/::after` (§11a): no implicit content/pseudo-element slots; faithful idiom is explicit child composition (e.g. a placeholder is a real widget). |
| `*` (direct children), `**` (all descendants), arbitrary `[&:…]` selectors | **No-analog (§11a)** | A bounded "style direct children" helper is feasible at a layout widget, but the open-ended selector/cascade model is the impossible set — there is no DOM/selector engine. |
| `print` | **No-analog** | Flutter has no print-stylesheet/paged-media model. |
| `starting` (`@starting-style`) | **Delegate → `flutter_animate`** | Enter-transition concern → the animation layer (§11b). |
| `!important` modifier | **Free/N-A** | The typed accumulator has no specificity war; last-wins is explicit and ordered. |

**Net of the second pass:** every v4 utility *and* variant now has a verdict. The engine delivers the
daily-driver utilities **and** the daily-driver variants; the remainder is long-tail breadth — feasible
(by-demand, mostly **S**), delegated (animation, forms, icons), or a small honest no-analog set
(selector/cascade model, pseudo-elements, print, font-smoothing, underline-offset, `bg-attachment:
fixed`, balanced/pretty text-wrap, auto-hyphens, `text-transform` as a render-style).

## Two things that are already "free"

1. **Arbitrary values are native.** Tailwind needs `w-[37px]`; here you write `.w(37)`. The
   whole API is arbitrary-value-first, so there is nothing to add for `[..]` syntax.
2. **Pass-through types.** `bgGradient(Gradient)` and `shadow(List<BoxShadow>)` accept *any*
   Flutter value. So **radial/conic/multi-stop gradients and arbitrary shadows already work
   today** — only the *named-scale sugar* (`bg-gradient-to-r`, `shadow-md` aliases) is
   unbuilt, and `shadow-md` etc. already exist via `context.fw.shadows`.

## Coverage snapshot (shipped, current — modules 0–17)

| Tailwind category | Status |
|---|---|
| Spacing (padding/margin, directional) | ✅ (negative margins `-m-*` ⬜ — not yet built, §"By-demand") |
| Sizing (w/h/min/max, fractional, aspect, square) | ✅ |
| Color: background, text color | ✅ |
| Gradients | ✅ pass-through (`bgGradient`) + direction sugar `bgGradientTo*` (module 15) |
| Border (uniform + per-edge, width/color) | ✅ |
| Border style: dashed / dotted (drop-zones) | ✅ (module 15, custom painter) |
| Focus `ring` (+ offset) | ✅ (module 15) |
| Named-scale sugar: `shadow-md`, `rounded-lg` | ✅ (module 15, theme-resolved) |
| Overflow / scroll (`overflow-auto/scroll`, `FwScroll`) | ✅ (module 15) |
| `divide-*` (border between flex children) | ✅ (module 16, `FwRow`/`FwColumn`) |
| Scroll-snap (`snap-*`) | ✅ (module 16, `FwScroll.snapExtent`) |
| Background-image (`bg-[url]`, fit/position/repeat) | ✅ (module 17) |
| 3D transforms (`rotate-x/y`, `perspective`) | ✅ (module 17) |
| `mix-blend-mode` | ✅ (module 17, `FwBlendMode`) |
| Text-shadow (`text-shadow-*`) | ✅ (module 17) |
| Border-radius (per-corner, directional) | ✅ |
| Typography: size, weight, leading, tracking, align, underline/strike | ✅ |
| Typography: family, line-clamp/truncate, text-overflow, whitespace | ✅ (module 11) |
| Shadow, opacity, blur, backdrop-blur | ✅ |
| Transforms: scale, rotate, translate, scaleX/Y, skewX/Y, transform-origin | ✅ (module 13) |
| 3D transforms: rotate-x/y, perspective | ✅ (module 17) |
| Interactivity: cursor, pointer-events-none, visibility, italic | ✅ (module 13) |
| Interactivity: `group-*` / `peer-*` state propagation (named) | ✅ (module 14) |
| Flexbox (`FwRow`/`FwColumn`/`FwWrap`) | ✅ |
| Grid (`fr`/`px`/`auto`/`minmax`, span, placement, dense, align, distribute) | ✅ (`subgrid` de-scoped, §11b) |
| Position / inset / z (`FwStack`/`FwPositioned`) | ✅ |
| Responsive variants (`sm…2xl`) + container queries | ✅ (cascade precedence, audit-corrected) |
| Interaction states (hover/focus/pressed/disabled) | ✅ |
| Dark mode + theme transitions (`FwAnimatedTheme`) | ✅ |
| RTL / directional | ✅ everywhere |
| Full Tailwind v4 palette + named scales | ✅ |

That is the high-traffic ~80% of day-to-day Tailwind. The rest is the long tail below.

## Roadmap

Verdict legend: **Build** (do next) · **By-demand** (feasible, schedule when a real need
appears) · **Delegate** (use an existing solution / the component layer) · **Impossible**
(§11a). Size: **S** ≈ a setter or two · **M** ≈ a new render-chain layer / condition / color
matrices · **L** ≈ a new widget / sliver / render object or cross-cutting work.

### Tier 1 — Build next (matter a lot, not a hard add)

These are core vocabulary, small, and fit the existing single-box `.tw` model.
**Modules 11 (text completeness) and 12 (filters & fit) are shipped.** Tier 1 is
complete; the next work is Tier 2 (by demand).

| Utility | Tailwind | Flutter mechanism | Home | Size | Status |
|---|---|---|---|---|---|
| **Line-clamp / truncate / text-overflow** | `line-clamp-N`, `truncate`, `text-ellipsis`, `text-clip` | `DefaultTextStyle.merge` carries `maxLines`/`overflow`/`softWrap` — fields + setters `maxLines`/`lineClamp`/`truncate`/`overflow` | `.tw` typography | **S** | ✅ module 11 |
| **Font family** | `font-sans/serif/mono`, `font-[...]` | `TextStyle.fontFamily` via the same `DefaultTextStyle.merge` — setters `font`/`fontSans`/`fontSerif`/`fontMono` | `.tw` typography | **S** | ✅ module 11 |
| **Whitespace / wrapping** | `whitespace-nowrap`, `whitespace-normal` | `softWrap` via `DefaultTextStyle.merge` — setters `nowrap`/`wrap` | `.tw` typography | **S** | ✅ module 11 |
| **Color filters** | `brightness/contrast/saturate/grayscale/invert/sepia/hue-rotate` | `ColorFiltered` + `ColorFilter.matrix`, composed within a chain (same render-chain slot as the existing blur `ImageFiltered`) | `.tw` effects | **M** | ✅ module 12 |
| **Object-fit** | `object-cover/contain/fill/...` | wrap child in `FittedBox(fit: BoxFit.*)` — setter `fit` | `.tw` (`fit()`) | **S–M** | ✅ module 12 |

Notes: line-clamp is the most glaring single omission — it is core text vocabulary and a few
hours. Color matrices must be transcribed correctly (guard ranges; test against known
values). Backdrop *color* filters (`backdrop-brightness`) are harder (Flutter's
`BackdropFilter` takes an `ImageFilter`, not a `ColorFilter`) — ship forward color filters
first; treat backdrop color filters as By-demand.

### Tier 2 — Worth building, schedule by demand

Feasible, larger, or lower-frequency. Each is a real idiom, none is a wall.

| Utility | Flutter mechanism | Home | Size |
|---|---|---|---|
| ~~**`group-*` / `peer-*`** (parent/sibling state propagation)~~ | ✅ shipped (module 14). `FwGroup` broadcasts its state to descendants and hosts the peer channel `FwPeer`s publish into (one scope, two channels — Flutter has no sibling selectors); `FwGroupCondition` (relation + state + name) the resolver matches; `groupHover`/`peerHover`/… setters. Named groups/peers supported. | resolver + new widgets | — |
| ~~Transform extras (`skew`, `scale-x/y`, `transform-origin`)~~ | ✅ shipped (module 13). 3D `rotate-x/y`/`perspective` remain ⬜ (by-demand) | `.tw` transform | — |
| ~~**Overflow / scroll** (`overflow-auto/scroll`)~~ | ✅ shipped (module 15) — `FwScroll` (`SingleChildScrollView` + `RawScrollbar`, Material-free). `overflow-hidden` is `.clip()`. | new widget | — |
| ~~**Named-scale sugar** (`shadow-md`, `rounded-lg`, `bg-gradient-to-r`)~~ | ✅ shipped (module 15) — `shadowSm/Md/…`, `roundedSm/Md/Lg/Xl` (theme-resolved via a gated build-time pass), gradient `bgGradientTo*`. | `.tw` | — |
| ~~**`ring` utility**~~ | ✅ shipped (module 15) — `ring(width, {color, offset, offsetColor})`, a zero-blur spread shadow composed with `shadow`. | `.tw` effects | — |
| ~~**Dashed/dotted borders**~~ | ✅ shipped (module 15) — `borderDashed`/`borderDotted` via `FwDashedBorderPainter` (uniform). | `.tw` border | — |
| ~~**`divide-*`** (borders between flex children)~~ | ✅ shipped (module 16) — `divideWidth`/`divideColor` on `FwRow`/`FwColumn` insert a directional (RTL-aware) border between non-last children. | layout widgets | — |
| ~~**`bg-image`** (background-image)~~ | ✅ shipped (module 17) — `bgImage(ImageProvider, {fit, alignment, repeat})` → `DecorationImage` on the surface decoration. | `.tw` decoration | — |
| ~~**`mix-blend-mode`**~~ | ✅ shipped (module 17) — `blendMode(BlendMode)` via `FwBlendMode` (a `saveLayer` carrying the blend mode; unbounded layer so transformed/overflowing content still blends). | `.tw` effects | — |
| ~~**3D transforms** (`rotate-x/y`, `perspective`)~~ | ✅ shipped (module 17) — `rotateX`/`rotateY`/`perspective` via `Matrix4.setEntry(3,2,-1/d)` + `rotationX/Y`, origin-anchored by `Transform.alignment`. | `.tw` transform | — |
| ~~**Scroll-snap** (`snap-*`)~~ | ✅ shipped (module 16) — `FwScroll.snapExtent`/`snapAlign` via a real `ScrollPhysics` (settles on item multiples; not a `PageView`). | layout widget | — |
| **Negative margins** (`-m-*`) | split positive/negative per edge — positive via `Padding`, negative via `Transform.translate` (paint-only) or a custom parent-data offset. *Currently asserts with a clear "not yet supported" message* (margin renders via `Padding`, non-negative only). | `.tw` spacing | **M** |
| **Backdrop color filters** (`backdrop-brightness`…) | harder — `BackdropFilter` takes an `ImageFilter`, not a `ColorFilter` | `.tw` effects | **M** |
| **Sticky** (`position: sticky`) | `SliverPersistentHeader` (sliver context) | new widget | **L** |
| **`scroll-margin` / `scroll-padding`** | scroll-snap is shipped; the snap-target inset utilities are the remaining piece — a snap-target offset on `FwScroll` | layout widget | **M** |

**`space-x-*` / `space-y-*`: already covered — use `gap`.** Tailwind's `space-*` inserts margin
*between* siblings; Flutter's `Flex.spacing` (which `FwRow`/`FwColumn`'s `gap` uses) is exactly
that — space between, no trailing edge. So `gap` is the faithful, better equivalent; there is no
separate `space-*` API by design (a redundant one would just wrap `gap`).

None of the remaining items is impossible — each names its Flutter mechanism and is scheduled, not
refused (AGENTS.md §11/§12). They are deliberately **not** built yet because the shipped surface
covers the daily-driver set; these are long-tail breadth.

### Tier 3 — Delegate (don't build into the engine)

| Want | Decision |
|---|---|
| **Element animation / `tailwindcss-animate`** (`transition`, `duration`, `animate-spin/pulse`, enter/exit) | **Delegate to [`flutter_animate`](https://pub.dev/packages/flutter_animate).** It already exposes a *chaining* API (`widget.animate().fadeIn().slide()`), is Material-free, and is a sanctioned dependency. The engine deliberately does **not** ship an element-animation subsystem — that would duplicate a mature package. The engine's animation responsibility ends at **theme transitions** (`FwAnimatedTheme`, already shipped). shadcn-style data-state enter/exit transitions are composed with `flutter_animate` at the **flutterbits component** level, where the component owns the state machine. Recorded in AGENTS.md §11b. |
| **`prose` / `@tailwindcss/typography`** | **flutterbits** — opinionated multi-element styling is exactly the copy-paste component layer's job, not a single-box utility. |
| **`@tailwindcss/forms`** | **flutterbits** — form-control components. |

### Tier 4 — Impossible (AGENTS.md §11a, already documented)

| Want | Why not |
|---|---|
| True **CSS cascade** (open-ended inheritance) | Flutter has no cascade by design; we provide the specific inheritances that matter (`DefaultTextStyle`, `IconTheme`, token providers) as explicit `InheritedWidget`s. |
| **Pseudo-elements `::before/::after` + `content`** | No implicit, DOM-less content slots; the faithful idiom is explicit child composition. |

Note: `:nth-child`/`:first/:last/:odd/:even` are **not** impossible — resolve them at the
list-building site (you know each child's index), so they need no engine feature.

## Recommended sequencing

1. **Module 11 — Text completeness:** ✅ **shipped** — `font`/`fontSans/Serif/Mono`,
   `maxLines`, `lineClamp`, `truncate`, `overflow`, `nowrap`/`wrap`.
2. **Module 12 — Filters & fit:** ✅ **shipped** — `grayscale`/`brightness`/`contrast`/
   `saturate`/`invert`/`sepia`/`hueRotate` (composed color matrices) + `fit`.
3. **Module 14 — Group/peer:** ✅ **shipped** — `FwGroup`/`FwPeer`, `group-*`/`peer-*`
   variants (named), the `FwGroupCondition` resolver member. See
   `2026-06-07-flutterwindcss-m14-group-peer-design.md`.
4. **Module 15 — Ergonomics + completeness:** ✅ **shipped** — gradient direction sugar,
   `ring`, named-scale `shadow*`/`rounded*` sugar, `FwScroll`, dashed/dotted borders.
5. **Modules 16–17 — Final Tailwind completeness:** ✅ **shipped** — `divide` + scroll-snap
   (16); `bg-image`, 3D transforms, `mix-blend-mode`, `text-shadow` (17). Verified against the
   full v4 catalog. **The engine is complete for the next phase (components + docs).**
6. **Then, by demand only:** the niche/delegated/impossible sets in the headline — built when a
   real flutterbits component needs one.
7. **Never (in the engine):** an element-animation subsystem (→ `flutter_animate`); `prose`
   and forms (→ flutterbits); the §11a impossible set.

## Pre-docs completeness — done (module 15, 2026-06-07)

All three pre-docs recommendations shipped in **module 15**, plus dashed borders (raised by a real
drop-zone need):

- ✅ **Named-scale sugar** — `shadowXs2/Xs/Sm/Md/Lg/Xl/2xl`/`shadowNone`, `roundedSm/Md/Lg/Xl`
  (theme-resolved at build), and gradient `bgGradientTo{Top,Bottom,Start,End,…}` + `bgLinear`.
- ✅ **Scroll** — `FwScroll` (`overflow-auto/scroll`), Material-free.
- ✅ **Focus `ring`** — `ring(width, {color, offset, offsetColor})`.
- ✅ **Dashed/dotted borders** — `borderDashed`/`borderDotted` (drop-to-upload zones).

The engine now covers the daily-driver set **and** the most-noticed long-tail. `divide`,
`bg-image`, `mix-blend-mode`, 3D transforms, and scroll-snap have since **shipped** (modules
16–17). The remaining Tier 2 items (sticky, backdrop color filters, negative margins,
`scroll-margin`/`scroll-padding`) plus the long-tail enumeration ship by-demand — each recorded
above with a mechanism and size, **nothing silently dropped**.

## Non-goals reaffirmed

- We are **not** cloning the entire Tailwind ecosystem. Plugins and opinionated component
  styling belong to flutterbits or to existing packages.
- We do **not** build a CSS engine (cascade/specificity/pseudo-elements). We re-create
  Tailwind's *vocabulary and token discipline*.
- Animation is a solved problem in the Flutter ecosystem; we point devs at `flutter_animate`
  rather than reimplement it.

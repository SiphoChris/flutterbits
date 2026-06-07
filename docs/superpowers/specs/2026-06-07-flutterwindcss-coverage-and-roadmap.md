# flutterwindcss — Tailwind coverage & roadmap (gap analysis)

**Status:** living roadmap · **Date:** 2026-06-07 · **Audience:** engine maintainers planning modules 11+.

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

## Distance to Tailwind (current — audited 2026-06-07)

Verified against the code by an adversarial review pass. Headline:

- **~92–94% of high-traffic, daily-use Tailwind utilities are built** (up from ~85–90% before
  module 15, which closed the most-noticed daily gaps — scroll, focus rings, named
  shadow/radius sugar, gradient directions), and **~78–82% of Tailwind's *portable* utility
  surface** overall. The remaining distance is **breadth in the long tail**, not depth.
- **Everything developers reach for daily is done:** spacing, sizing, color, typography
  (incl. line-clamp/truncate/family/tracking), borders + radius (+ dashed/dotted + named
  sugar), shadows (+ named sugar), `ring`, opacity, blur, gradients (+ direction sugar),
  the full color-filter set + object-fit, transforms, the complete flex/grid/stack/scroll
  layout vocabulary, responsive + container variants, and hover/focus/pressed/disabled +
  group/peer states.
- **Two multipliers** make effective coverage higher than a raw class count: arbitrary
  values are native, and `bgGradient`/`shadow` are pass-through (radial/conic gradients and
  arbitrary shadows already work).
- **The two remaining daily-driver misses** are `divide-*` (lists/menus) and `text-transform`
  (`uppercase` labels) — both feasible and small; build by demand while building components.
- **Legitimately out (not counted against the engine):** animation → `flutter_animate`
  (§11b); forms/prose/tables/SVG/`sr-only`/`accent-color`/`caret-color`/`resize`/
  `appearance-none` → the flutterbits component layer.
- **Genuinely impossible / no analog (tiny):** true CSS cascade, pseudo-elements/`content`,
  `float`/`clear`, `will-change`, `touch-action`. **`text-transform`** is impossible *as a
  render-time style* (Flutter's `TextStyle` has no transform hook) but **feasible as content
  mutation** at the `Text`-building site / a helper — so it is "not yet built (S)", not
  impossible.

**Built since the early summary (modules 13–15):** transform extras + interactivity + `size`
(module 13); **`group-*` / `peer-*`** state propagation (module 14); and the **ergonomics +
completeness** layer (module 15 — gradient direction sugar, `ring`, named-scale `shadow*`/
`rounded*` sugar, `FwScroll` (`overflow-auto/scroll`), and dashed/dotted borders). So the
remaining **highest-value NOT-BUILT items** (excluding out/delegated), by value × ease:

1. **`divide-*`** (S–M) — a separator flag on `FwRow`/`FwColumn`. Most-used remaining miss.
2. **`text-transform`** (`uppercase`/`lowercase`/`capitalize`) (S) — content mutation at the
   `Text`-building site / a helper (not a render-time style; see headline).
3. **`bg-image`** (S–M), **`mix-blend-mode`** (M), **3D transforms** (M), **negative margins**
   (M, asserts cleanly today).

By-demand / larger: sticky (L, slivers), scroll-snap (L), backdrop color filters (M),
dashed borders (M, custom painter), `bg-image` (S–M).

**Engine audit status:** an adversarial review of the full engine (resolver cascade, render
chain, grid render object, tokens/lerp, modules 11–12) found **no correctness bugs**; one
hardening gap was fixed (`FwGridItem` span cap, matching the existing line-number cap) and
the object-fit bounded-constraint behavior was documented. The example app now has widget
smoke tests (every section, light/dark, LTR/RTL) and is covered by CI.

## Two things that are already "free"

1. **Arbitrary values are native.** Tailwind needs `w-[37px]`; here you write `.w(37)`. The
   whole API is arbitrary-value-first, so there is nothing to add for `[..]` syntax.
2. **Pass-through types.** `bgGradient(Gradient)` and `shadow(List<BoxShadow>)` accept *any*
   Flutter value. So **radial/conic/multi-stop gradients and arbitrary shadows already work
   today** — only the *named-scale sugar* (`bg-gradient-to-r`, `shadow-md` aliases) is
   unbuilt, and `shadow-md` etc. already exist via `context.fw.shadows`.

## Coverage snapshot (shipped, current — modules 0–14)

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
| Border-radius (per-corner, directional) | ✅ |
| Typography: size, weight, leading, tracking, align, underline/strike | ✅ |
| Typography: family, line-clamp/truncate, text-overflow, whitespace | ✅ (module 11) |
| Shadow, opacity, blur, backdrop-blur | ✅ |
| Transforms: scale, rotate, translate, scaleX/Y, skewX/Y, transform-origin | ✅ (module 13; 3D rotate ⬜) |
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
| **`divide-*`** (borders between flex children) | a flag on `FwRow`/`FwColumn` that inserts directional separators | layout widgets | **S–M** |
| **Negative margins** (`-m-*`) | split positive/negative per edge — positive via `Padding`, negative via `Transform.translate` (paint-only) or a custom parent-data offset. *Currently asserts with a clear "not yet supported" message* (margin renders via `Padding`, non-negative only). | `.tw` spacing | **M** |
| **`bg-image`** (background-image) | `DecorationImage` on the surface decoration | `.tw` decoration | **S–M** |
| **`mix-blend-mode`** | `BlendMode` via a `saveLayer`/`ShaderMask` wrapper | `.tw` effects | **M** |
| **3D transforms** (`rotate-x/y`, `perspective`) | `Matrix4.setEntry` perspective + `rotateX/Y` | `.tw` transform | **M** |
| **Backdrop color filters** (`backdrop-brightness`…) | harder — `BackdropFilter` takes an `ImageFilter`, not a `ColorFilter` | `.tw` effects | **M** |
| **Sticky** (`position: sticky`) | `SliverPersistentHeader` (sliver context) | new widget | **L** |
| **Scroll-snap / scroll-margin** | `ScrollPhysics`/`PageView`-style | new widget | **L** |

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
5. **Then, by demand:** the remaining Tier 2 list, prioritized by what real flutterbits
   components need.
6. **Never (in the engine):** an element-animation subsystem (→ `flutter_animate`); `prose`
   and forms (→ flutterbits); the §11a impossible set.

## Pre-docs completeness — done (module 15, 2026-06-07)

All three pre-docs recommendations shipped in **module 15**, plus dashed borders (raised by a real
drop-zone need):

- ✅ **Named-scale sugar** — `shadowXs2/Xs/Sm/Md/Lg/Xl/2xl`/`shadowNone`, `roundedSm/Md/Lg/Xl`
  (theme-resolved at build), and gradient `bgGradientTo{Top,Bottom,Start,End,…}` + `bgLinear`.
- ✅ **Scroll** — `FwScroll` (`overflow-auto/scroll`), Material-free.
- ✅ **Focus `ring`** — `ring(width, {color, offset, offsetColor})`.
- ✅ **Dashed/dotted borders** — `borderDashed`/`borderDotted` (drop-to-upload zones).

The engine now covers the daily-driver set **and** the most-noticed long-tail. Remaining Tier 2
items (divide, bg-image, mix-blend, 3D transforms, sticky, scroll-snap, backdrop color filters,
negative margins) ship by-demand — each recorded above with a mechanism and size, **nothing
silently dropped**.

## Non-goals reaffirmed

- We are **not** cloning the entire Tailwind ecosystem. Plugins and opinionated component
  styling belong to flutterbits or to existing packages.
- We do **not** build a CSS engine (cascade/specificity/pseudo-elements). We re-create
  Tailwind's *vocabulary and token discipline*.
- Animation is a solved problem in the Flutter ecosystem; we point devs at `flutter_animate`
  rather than reimplement it.

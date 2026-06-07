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

- **~85–90% of high-traffic, daily-use Tailwind utilities are built**, and **~70–75% of
  Tailwind's *portable* utility surface** overall. The remaining distance is **breadth in
  the long tail**, not depth in the core.
- **Everything developers reach for daily is done:** spacing, sizing, color, typography
  (incl. line-clamp/truncate/family), borders + radius, shadows, opacity, blur, gradients,
  the full color-filter set + object-fit, transforms, the complete flex/grid/stack layout
  vocabulary, responsive + container variants, and hover/focus/pressed/disabled states.
- **Two multipliers** make effective coverage higher than a raw class count: arbitrary
  values are native, and `bgGradient`/`shadow` are pass-through (radial/conic gradients and
  arbitrary shadows already work).
- **Legitimately out (not counted against the engine):** animation → `flutter_animate`
  (§11b); forms/prose/tables/SVG/`sr-only` → the flutterbits component layer.
- **Genuinely impossible / no analog (tiny):** true CSS cascade, pseudo-elements/`content`,
  `float`/`clear`, `text-transform` as a render-time style, `will-change`.

**Highest-value NOT-BUILT items** (excluding the out/delegated set), by value × ease:

1. **`group-*` / `peer-*`** (M–L) — parent/sibling state propagation; the most-used missing
   interactivity feature. `FwGroup` ancestor broadcasting via `InheritedWidget` + a new
   resolver condition.
2. **Overflow / scroll** (`overflow-auto/scroll`) (M) — a scroll widget (`overflow-hidden`
   already = `.clip()`).
3. **`cursor-*` + `pointer-events-none`** (S each) — `MouseRegion(cursor:)` / `IgnorePointer`;
   cheap, high everyday value on web/desktop.
4. **Transform extras** — `skew`, `scale-x/y`, `transform-origin` (M) — extend the composed
   `Matrix4` (field already present, currently uniform).
5. **`divide-*`** (S–M) — a separator flag on `FwRow`/`FwColumn`.
6. **`mix-blend-mode`** (M) and **named-scale sugar** (`shadow-md`/`bg-gradient-to-r`, S).

By-demand / larger: sticky (L, slivers), scroll-snap (L), backdrop color filters (M),
dashed borders (M, custom painter), `bg-image` (S–M), `font-style: italic` (S).

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

## Coverage snapshot (shipped, modules 0–10)

| Tailwind category | Status |
|---|---|
| Spacing (padding/margin, directional) | ✅ |
| Sizing (w/h/min/max, fractional, aspect, square) | ✅ |
| Color: background, text color | ✅ |
| Gradients | ✅ via pass-through (`bgGradient`); named sugar ⬜ |
| Border (uniform + per-edge, width/color) | ✅ |
| Border-radius (per-corner, directional) | ✅ |
| Typography: size, weight, leading, tracking, align, underline/strike | ✅ |
| Typography: family, line-clamp/truncate, text-overflow, whitespace | ✅ (module 11) |
| Shadow, opacity, blur, backdrop-blur | ✅ |
| Transforms: scale, rotate, translate | ✅ (skew / per-axis / 3D ⬜) |
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
| **`group-*` / `peer-*`** (parent/sibling state propagation) | an `FwGroup` ancestor broadcasts hover/focus via `InheritedWidget`/`ValueNotifier`; add an `FwGroupStateCondition` the resolver matches | resolver + new widget | **M–L** |
| **Transform extras** (`skew`, `scale-x/y`, `rotate-x/y`, `perspective`, `transform-origin`) | extend the composed `Matrix4` in the transform field; origin via `Transform(alignment:)` | `.tw` transform | **M** |
| **`divide-*`** (borders between flex children) | a flag on `FwRow`/`FwColumn` that inserts directional separators | layout widgets | **S–M** |
| **`mix-blend-mode`** | `BlendMode` via a `saveLayer`/`ShaderMask` wrapper | `.tw` effects | **M** |
| **Overflow / scroll** (`overflow-auto/scroll`) | `SingleChildScrollView`/`Scrollbar` — needs a *scroll widget*, not a single-box layer (`overflow-hidden` already = `.clip()`) | new widget | **M** |
| **Sticky** (`position: sticky`) | `SliverPersistentHeader` (sliver context) | new widget | **L** |
| **Scroll-snap / scroll-margin** | `ScrollPhysics`/`PageView`-style | new widget | **L** |

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
3. **Then, by demand:** `group`/`peer`, transform extras, `divide`, overflow/scroll, blend,
   sticky (Tier 2), prioritized by what real flutterbits components need.
4. **Never (in the engine):** an element-animation subsystem (→ `flutter_animate`); `prose`
   and forms (→ flutterbits); the §11a impossible set.

## Non-goals reaffirmed

- We are **not** cloning the entire Tailwind ecosystem. Plugins and opinionated component
  styling belong to flutterbits or to existing packages.
- We do **not** build a CSS engine (cascade/specificity/pseudo-elements). We re-create
  Tailwind's *vocabulary and token discipline*.
- Animation is a solved problem in the Flutter ecosystem; we point devs at `flutter_animate`
  rather than reimplement it.

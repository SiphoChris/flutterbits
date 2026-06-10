# flutterbits — product charter (identity, taxonomy, platform, catalog)

**Status:** design · **Date:** 2026-06-10 · **Audience:** anyone building the flutterbits component layer.
**Supersedes/extends:** the "flutterbits" framing in `AGENTS.md` §1, the roadmap note in the coverage doc, and `apps/docs/content/docs/flutterbits/index.mdx`. Companion specs: `2026-06-10-flutterbits-structure-and-routing-design.md` (the structure layer) and `2026-06-10-flutterbits-registry-cli-design.md` (the registry + CLI).

---

## 1. What flutterbits is (the identity, sharpened)

flutterbits is **two things in one library**, and the second one is the differentiator:

1. **shadcn/ui for Flutter** — a registry of **copy-paste components you own** (Button, Card, Input, Dialog…), styled entirely through `flutterwindcss` semantic tokens, fetched via a CLI. This is the trust layer: a dev who knows shadcn finds the familiar set and it just works.

2. **An opinionated "structure" layer that models how app developers think** — `Layout`, `Screen`, navigation, and routing that read like a Next.js / Expo app rather than Flutter's `MaterialApp`/`Scaffold`/`Navigator` ceremony. **No other Flutter UI library ships this.** It is the reason flutterbits is more than "shadcn ported."

> **AGENTS.md §1 reconciliation.** The manual currently calls flutterbits "shadcn/ui for Flutter — copy-paste components." That is necessary but no longer sufficient: flutterbits *also* ships the opinionated structure/app-framework layer above. The identity is **"shadcn's copy-paste components *plus* an opinionated, intention-revealing app skeleton."**

### 1.1 The governing design principle — intention-revealing structure

> The widget tree should read like a **description of the app**, not its plumbing. `Screen`, `Layout`, `header`/`body`/`footer` say *what the thing is*; `MaterialApp`/`Scaffold` say *what framework you imported*. flutterbits models the mental model of a Next.js/Expo developer — **layouts wrap screens, screens compose blocks, blocks compose primitives** — so the code reads top-down as the rendered artifact.

This is consistent with — not a violation of — the engine's Material-free stance: a `Screen` is built from `package:flutter/widgets.dart` primitives + `context.fw`, never a wrapper around `Scaffold`.

### 1.2 The "Material-like" framing

flutterbits' structure layer plays the **role** Material plays — the batteries-included app skeleton you reach for first — **without** Material's visuals or ceremony, and as **copy-paste source you own** (so you can rip it open). It is "the opinionated default way to build a flutterbits app."

### 1.3 The three rules (design north star)

Every flutterbits artifact is held to the author's three rules, in order of weight:

1. **Works good** — complete, correct, accessible, tested (goldens + the `apps/gallery` compile target — the flutterbits component app, separate from the engine's `apps/example`). No demoware.
2. **Looks good** — semantic-token styled so it reskins with any pasted theme; polished defaults.
3. **Feels good (most important)** — the API is a joy to write. Minimal concepts, call sites that read like sentences, one idea expressed one way.

These are not decoration; "feels good" is an explicit acceptance criterion. Where two designs are equally correct, the more pleasant-to-write one wins.

---

## 2. Taxonomy — the tiers

Four tiers (the originally-considered "tools" tier is **dropped** — what would have lived there is either a registry *install-type* (`util`), see the registry spec, or belongs in `flutterwindcss`).

| Tier | What it is | shadcn analog | The "feel" |
|---|---|---|---|
| **primitives** | Button, Badge, Input, Card, Switch, Dialog… | shadcn components (parity) | trust / familiarity |
| **structure** | `Layout`, `Screen`, nav, app-shell, routing | *(none — the differentiator)* | "reads like Next.js/Expo" |
| **blocks** | music-player card, stat grid, charts, auth form, splash | shadcn blocks | "feels like a real app" |
| **templates** | full app scaffolds wiring all three | *(none)* | "clone-and-go" |

**Altitude rule:** `structure` is a *different altitude* from the engine's layout primitives. `FwRow`/`FwColumn`/`FwGrid` (flutterwindcss) are flex/grid **layout primitives**; `Layout`/`Screen` (flutterbits) are **app-shell semantics** — safe areas, status-bar styling, nav regions, scroll ownership, routing. No overlap.

### 2.1 Components that *re-home* into the structure layer

A naïve clone of shadcn's flat list is wrong for Flutter. Several shadcn "components" are, in flutterbits, expressions of the structure layer rather than standalone primitives:

- **Sheet / Drawer / Dialog** → presentation modes of a `Screen` (`FwPresentation.sheet/dialog/fullScreen`), not separate component APIs. What remains is content + chrome (`SheetHandle`). (See structure/routing spec.)
- **Sidebar** → `SidebarLayout`, a `Layout` shell (sibling to `TabsLayout`). Structure, not a primitive. (Desktop/web → by-demand, §4.)
- **Tabs** → splits in two: *navigation* tabs = `TabsLayout` (structure); *in-page* content tabs = a `Tabs` primitive.

---

## 3. The catalog

Organised by tier and by "maps cleanly / re-homes / adapt-by-demand." **None of the by-demand items is impossible** — each has a Flutter idiom and ships when a real need appears (AGENTS.md §11b discipline).

### 3.1 Structure (flutterbits-native — the differentiator)

`Layout`, `Screen`, `TabsLayout`, `SidebarLayout` (by-demand, desktop/web), `TopBar`, `BottomNav` + `NavDestination`, `BackButton`, `SheetHandle`. Routing types (`FwRoute`, `FwRoutePattern`, `FwPresentation`, `FwTransition`). Full design in the structure/routing spec.

### 3.2 Primitives — shadcn parity that maps cleanly to Flutter

Button, Badge, Card, Input, Textarea, Label, Checkbox, RadioGroup, Switch, Slider, Select, Accordion, Alert, Avatar, Progress, Separator, Skeleton, Toggle, ToggleGroup, Tooltip, Popover, DropdownMenu, Tabs (in-page), Collapsible, AspectRatio, Spinner, Pagination, Carousel, Calendar, DatePicker, InputOTP.

- **Variant/size naming mirrors shadcn**, with one forced deviation: `default` is a **Dart reserved word**, so it cannot be an enum constant — the shadcn `default` variant is `primary` and the `default` size is `md`. Full set — variants `primary / secondary / destructive / outline / ghost / link`; sizes `sm / md / lg / icon`. Implemented as **typed enums + exhaustive `switch`** (the cva equivalent; AGENTS.md §4).
- All require `flutterwindcss` (semantic tokens) — that is the whole styling model.

### 3.3 App-feel components shadcn lacks (because shadcn is web-only)

`ThemeToggle`, `Splash`, `PullToRefresh`, `SegmentedControl`, `SearchBar`, `EmptyState`, `ListItem`. Plus the imperative feedback helpers `showConfirm` / `showSheet` / `Toaster` + `showToast`.

### 3.4 Blocks (tier 2 — "feels like an app")

music-player card, stat/metric grid, Chart(s), auth form, profile header, settings list, onboarding carousel. Blocks compose structure + primitives.

### 3.5 shadcn web-centric — adapt or defer (by-demand, none impossible)

Command (⌘K palette), Combobox, DataTable (Flutter wants a different idiom than a web grid), Resizable, Menubar, NavigationMenu, HoverCard (no hover on touch), Breadcrumb, ContextMenu (→ long-press on mobile). Each needs an honest Flutter rethink; scheduled, not refused.

### 3.6 The overlay substrate (cross-cutting dependency)

Popover, DropdownMenu, Tooltip, Select, Combobox, and ContextMenu all sit on the **same** behavioral plumbing — an **anchored overlay** (`OverlayPortal` + `CompositedTransformFollower` + edge-flip positioning, floating above the screen, dismiss-on-outside-tap). This is flutterbits' equivalent of shadcn's Radix dependency.

It is built **once** as a shared **lib util** (`anchor`) — the flutterbits analog of shadcn's `cn.ts`: a predictable, pasted-once file every overlay component imports. It must be built **before** the components that depend on it. (Install mechanics in the registry/CLI spec.) The anchored positioning itself — measuring available space and flipping/shifting placement at viewport edges — is **real work the eventual `anchor` spec owns** (feasible, not free; §12). `OverlayPortal`/`CompositedTransformFollower` are in `widgets.dart`, so the substrate is buildable Material-free.

---

## 4. Platform — mobile-first, portable, matures by demand

**Decision: mobile-first as the design *center*; portable but not desktop-tuned.**

- **Design center = phones.** Touch targets ≥ ~44px, safe-area aware, `TabsLayout`/`BottomNav` + sheets are the default navigation idioms, status-bar styling is first-class.
- **Portable, not exclusive.** Every component still *runs* on web/desktop (they are plain widgets) and keeps full **keyboard + focus-ring + `Semantics` accessibility** (AGENTS.md §6 requires this regardless of platform). They are simply not *optimized* for desktop density/hover.
- **Hover is enhancement-only** — never required to operate anything, so touch loses nothing.
- **Catalog impact.** `TabsLayout`/`BottomNav` are v1 core; `SidebarLayout` and the desktop-centric shadcn set (§3.5) are **by-demand**, not v1.
- **Tablets / large phones** — *styling* reuses the engine's existing responsive + container-query variants (no new work there). Adaptive *navigation* (rail/sidebar, multi-pane, master-detail) is **structure-layer work, by-demand** — `.tw` breakpoint variants restyle a box, they do not restructure the shell — see `SidebarLayout`. (Corrected 2026-06-10: an earlier "no new work" blanket was a silent scope reduction — §12.)
- **Maturation.** Desktop/web become first-class "with need" — the §11b "feasible, scheduled" framing, not a "can't."

**Boundary (no drift):** this is a **flutterbits** stance only. **`flutterwindcss` stays fully platform-agnostic** (the universal styling engine), and the **web theme generator is unaffected** (a build-time web tool). Mobile-first describes how the *components* are designed, not the engine.

---

## 5. Naming — unprefixed components, `Fw` engine

- **flutterbits components are unprefixed**: `Button`, `Card`, `Badge`, `Screen`, `Layout`. This is the shadcn DX, and these are **source you own** (copied into your project), so they need no namespace.
- **`flutterwindcss` engine types stay `Fw`-prefixed**: `FwColumn`, `FwTokens`, `FwBreakpoint`. The **flutterbits structure *value types*** that ship as library code also carry `Fw` (they are not components a dev composes): `FwRoute`, `FwRoutePattern`, `FwPresentation`, `FwTransition`, `FwStatusBar`. `FwStatusBar` is a **flutterbits** type — it wraps `package:flutter/services.dart`'s system-UI overlay style; it is **not** an engine type (the engine never touches `services.dart`). When you see `Fw` in a flutterbits component, that is the engine *or* a structure value type showing through — never a component.

> **AGENTS.md §4 reconciliation.** "Public types are prefixed `Fw`" is an **engine** rule (`flutterwindcss`). It does **not** apply to flutterbits *components*, which are deliberately unprefixed (copy-paste, shadcn-style). The routing/structure *base types* that ship as library code (e.g. `FwRoute`, `FwPresentation`) keep `Fw`; the *components* a dev composes (`Screen`, `Layout`, `Button`) do not.

### 5.1 The name-clash, handled honestly

There are **two** clash surfaces — and an earlier draft of this section wrongly claimed only one existed. Corrected 2026-06-10 (verified against the Flutter SDK):

1. **`package:flutter/widgets.dart` itself** — which *every* flutterbits app imports — exports some common nouns: `Form`/`FormField`, `Icon`, `Image`, `Table`, `Title`, `Navigator`, `Page`, `Visibility`, `Spacer`, `Semantics`, `Builder`, `Actions`, `Overlay`, `OverlayPortal`, `Banner`. A component named `Form`/`Icon`/`Image`/`Table` **would collide even in a Material-free app**. (The prior "zero clashes in the intended world" claim was false.)
2. **`package:flutter/material.dart`** additionally defines `Card`, `Badge`, `Switch`, `Slider`, `Checkbox`, `Drawer`, `Tooltip`, `BackButton`. These clash **only** in the rare Material-interop case (possible because flutterwindcss can theme Material via the `FwThemeExtension` bridge). Verified **absent** from `widgets.dart` (so clash-free in a pure app): `Button`, `Card`, `Badge`, `Input`, `Dialog`, `Sheet`, `Switch`, `Slider`, `Checkbox`, `Tooltip`, `Tabs`, `Layout`, `Screen`.

**Hard authoring rule (MUST):** every component name is checked against `package:flutter/widgets.dart` **before it ships**. A name that collides there is **renamed** — the dev cannot avoid importing `widgets.dart`, so `widgets.dart` wins (e.g. an icon wrapper is `Lucide`/`Img`, not `Icon`/`Image`; a data grid is `DataTable`, not `Table`; there is no `Form` component — auth screens compose `Input`s directly). The shadcn set is overwhelmingly clash-free; the handful that aren't get a distinct name. (This is why the catalog §3.2/§3.5 names `DataTable`, never `Table`, and lists no `Form`/`Icon`/`Image` component.)

**Material interop** is then handled by the **barrel** (`ui.dart`) as an escape hatch: `import 'components/ui/ui.dart' as ui;` → `ui.Card`, `ui.Button` — explicit namespacing on demand, with no `Fw` noise forced on the common case.

This is still better than prefixing every component `Fw` (which would make the engine and components look identical and kill the shadcn feel); the cost is a naming-discipline rule, not a global prefix.

---

## 6. Dependency policy

- **Core stays dependency-free.** Primitives (Button, Card, Input…) need only `widgets.dart` + `flutterwindcss`. A copied `Button` drags in nothing.
- **Sanctioned deps are declared per-component in the manifest `pubDeps`**, never globally — exactly as shadcn lists a component's npm deps:
  - **`lucide_icons_flutter`** (sanctioned) — icons.
  - **`flutter_animate`** (sanctioned, AGENTS.md §11b) — the motion layer. Toast slide-in, Skeleton shimmer, Accordion/Collapsible expand, Splash, the `ThemeToggle` icon crossfade compose it. The engine deliberately ships no element-animation subsystem; components own their state machines and animate with `flutter_animate`.
  - **`go_router`** (newly sanctioned — see §6.1) — the routing engine the structure layer wraps.
  - **`flutter_svg`** — **by-demand**, only on blocks that render real SVG illustrations (illustrated `EmptyState`, onboarding art). Not core; most things use lucide or simple shapes.
- **The payoff:** `add button` installs zero deps; `add toast` installs `flutter_animate`; `add layout` installs `go_router` (+ `lucide_icons_flutter` and `flutter_animate` — the structure layer's full `pubDeps` set; see structure spec §7). Every component is honest about exactly what it costs.

### 6.1 `go_router` — newly sanctioned dependency (justification)

> **AGENTS.md §12 reconciliation.** §12 lists `lucide_icons_flutter` and `flutter_animate` as sanctioned; **`go_router` is added** as a sanctioned dep for the structure layer. Justification: building a router de-novo over Navigator 2.0 is a tar pit and violates "don't rebuild what works"; `go_router` is the Flutter-team-endorsed router and provides deep links, web URLs, and `ShellRoute` (persistent shells) for free. flutterbits **wraps** it in a thin, typed, intention-revealing face — it does not fork it. The router engine is a trusted dependency; only the ergonomic wrapper is owned. `go_router` is a `pubDep` of the structure components **only** — it never touches `flutterwindcss`.

---

## 7. Where everything lives (package vs registry)

- **`flutterwindcss` stays styling-only** (tokens + utilities + `FwRow`/`FwColumn`/`FwGrid`). It never learns routing, components, or app-shell concepts exist. Folding any of that in would blur "the Tailwind layer" and force unrelated deps (e.g. `go_router`) onto token-only users.
- **`flutterbits` is copy-paste source** (the registry): primitives, structure (`Layout`/`Screen`/routing), blocks, templates, and `util`s (`anchor`, overlay helpers). Components **import** `flutterwindcss` (which is why flutterbits cannot work without it) and declare `pubDeps` for anything else.
- **No new runtime package is introduced for v1.** Routing is copy-paste source + a `go_router` `pubDep`, not a new published package. If a genuinely shared runtime emerges later, it is promoted to a package then — not pre-emptively.

---

## 8. Decomposition & sequencing

This charter is the umbrella. Implementation is decomposed into specs, each its own spec → plan → build cycle:

1. **This charter** — identity, taxonomy, platform, catalog, naming, deps. *(done)*
2. **`2026-06-10-flutterbits-structure-and-routing-design.md`** — `Layout`, `Screen`, routing, presentations, navigation DX.
3. **`2026-06-10-flutterbits-registry-cli-design.md`** — manifest schema, install-types, `init`/`add`/`diff`, barrel regen, `flutterbits.json`, hosting.
4. **Per-component specs** — small, one component (or tight group) each, with `button` as the canonical template.

**First vertical slice (proves the whole stack end-to-end):** `Layout` + `Screen` + routing + `Button` + `ThemeToggle`, rendered in **`apps/gallery`** — a **new** flutterbits component showcase + golden/compile target, created with this slice and kept separate from the engine's `apps/example` (decision 2026-06-10). `ThemeToggle` is the chosen first concrete component — tiny, pure "feel good," and it forces every layer to play together (`Layout` owning theme → the `Switch` primitive → semantic-token reskin → the engine's `FwAnimatedTheme` transition).

---

## 9. Open questions (deferred, by explicit decision)

- **State management / data conventions** — deferred. flutterbits blesses **no** controller/view-model/folder-structure pattern in v1; Screens stay pure UI. Conventions are introduced later "when we have earned the right to impose them" (recorded decision, 2026-06-10). This is a deliberate de-scope, not an omission.
- **`SidebarLayout` and the desktop-centric set** — by-demand (§4).
- **Codegen routing** — explicitly rejected for v1 (forces `build_runner` on every consumer; awkward in a copy-paste model). The typed hand-written route is the chosen DX. May be offered as an *optional* layer later — capability-raising, not locked out.

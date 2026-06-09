# Docs site — design

**Status:** shipped (brainstorm 2026-06-09; built PR #30, branded PR #31, expanded PR #33) ·
**Home:** `apps/docs` (Fumadocs / Next.js / TS) ·
**Audience:** whoever builds and maintains the documentation site.

The docs site documents **both** products in the monorepo under one roof. This spec defines its
information architecture and the content of the first substantive pass.

> **Update (2026-06-09, post-v1).** After the first pass the engine docs felt thin next to the
> 148-setter API, so the **"no exhaustive reference" non-goal below was lifted**: a **Utility
> reference** section was added — five family pages (spacing/sizing; backgrounds, borders & radius;
> typography; effects & filters; transforms & interactivity) covering the full `.tw` surface, with
> the `styling` page slimmed to the accumulator model + a family map. Same pass: the redundant
> flutterwindcss/flutterbits **top-nav links were removed** (the sidebar tab switcher already
> handles product switching; only Theme generator remains in the nav); the home hero uses the
> **transparent no-bg logo**; and, with flutterwindcss published to pub.dev v1.0.0, **installation
> now uses `flutter pub add flutterwindcss`** (was a Git dependency).

---

## 1. Goal & scope

One Fumadocs site, titled **flutterbits**, covering both products with a clear separation:

- **flutterwindcss** — *Tailwind's styling vocabulary for Flutter* (the engine). **Fully built**
  (modules 0–17) and the substance of this pass.
- **flutterbits** — *shadcn/ui for Flutter* (the copy-paste component registry). **Not built yet**
  (no components, no CLI, no registry) — so it gets a single concept/overview page this pass.

**Decisions (from the brainstorm):**
1. flutterbits → **concept/overview page only** for now; structure lets components slot in later.
2. flutterwindcss → a **"core docs set"** (teaching the model), not an exhaustive per-utility
   reference. Reference pages grow incrementally later.
3. Separation → Fumadocs **sidebar tabs** (a root switcher), one doc tree per product.
4. Tailwind references → **inline "Tailwind equivalent" callouts** on each concept page (no
   separate mapping page this pass).

**Non-goals this pass:** exhaustive per-utility reference; flutterbits component pages; a "Coming
from Tailwind" mapping page; API-dartdoc generation. All are future, additive passes.

---

## 2. Information architecture

```
flutterbits (site title)
├── Home (/)                      landing: the two products, links into each
├── flutterwindcss (sidebar tab)  the engine
│   ├── Introduction
│   ├── Installation
│   ├── Styling with .tw
│   ├── Colors
│   ├── Semantic tokens & theming
│   ├── Conditional styling (states)
│   ├── Breakpoints & responsive
│   ├── Layout
│   └── Theme generator           (moved from the current top-level docs page)
└── flutterbits (sidebar tab)     the registry
    └── Overview                  ("Components — coming soon")
```

Content layout under `apps/docs/content/docs/`:

```
content/docs/
  meta.json                       # tab/root ordering: flutterwindcss first, then flutterbits
  flutterwindcss/
    meta.json                     # { "root": true, "title": "flutterwindcss", "icon": ... , pages [...] }
    index.mdx                     # Introduction
    installation.mdx
    styling.mdx
    colors.mdx
    theming.mdx
    states.mdx
    breakpoints.mdx
    layout.mdx
    theme-generator.mdx           # moved here (was content/docs/theme-generator.mdx)
  flutterbits/
    meta.json                     # { "root": true, "title": "flutterbits", "icon": ... }
    index.mdx                     # Overview
```

Removed: the scaffold placeholders `content/docs/index.mdx` ("Hello World") and
`content/docs/test.mdx` ("Components"). The old top-level `meta.json` is replaced by the tab roots.

**Sidebar tabs mechanism:** Fumadocs renders a root switcher when folders are marked `root: true`
in their `meta.json` (each becomes a sidebar tab). Exact config (folder roots vs. an explicit
`sidebar.tabs` array in `DocsLayout`) is confirmed at implementation time against the installed
Fumadocs version — whichever the version documents. This is a known Fumadocs feature, not invented.

---

## 3. Site shell changes (`apps/docs`)

- **Title → `flutterbits`.** `src/lib/shared.ts` `appName` (drives the nav title and metadata) →
  `flutterbits`. Sweep any other "My App" / scaffold string.
- **Home page** (`src/app/(home)/page.tsx`) — replace the "Hello World" placeholder with a real
  landing: one line on what the project is, two cards ("flutterwindcss — styling engine" → its
  Introduction; "flutterbits — components" → its Overview), and a card/link to the Theme generator.
  Keep it simple and consistent with the Fumadocs neutral theme (matches the generator route's
  styling approach).
- **Nav links** (`src/lib/layout.shared.tsx`) — keep the Docs + Theme generator links; ensure they
  still resolve after the content move (Theme generator route is unchanged at `/theme-generator`;
  the *docs page* for it moves under the flutterwindcss tab).

---

## 4. Content principles (every page)

- **Real API only.** Every code sample uses the actual shipped public surface. Symbols are verified
  against `packages/flutterwindcss/lib` (the barrel + `lib/src/...`) and `apps/example` while
  writing — never invented (AGENTS §12 "Don't invent APIs"). If unsure a setter exists, check first.
- **Inline Tailwind equivalents.** Concept pages show the equivalent Tailwind class in context via a
  short callout or inline note (e.g. *"`p(4)` → Tailwind `p-4` → 16 px"*), so Tailwind users map
  knowledge in place.
- **Honest about limitations.** Where a page states a limitation, it matches §11 of AGENTS.md and
  the code (e.g. uniform-rounded-border constraint, `subgrid` de-scoped, fonts not bundled). No
  limitation is asserted that is merely "not yet built" without saying so.
- **Material-free framing.** Examples use `package:flutter/widgets.dart`, `context.fw`, and the
  pure-path setup, with the `MaterialApp` interop noted where relevant.
- **Fumadocs components.** Use the registered MDX components: `Callout`, `Cards`/`Card`, `Tabs`/`Tab`,
  fenced code blocks. (Verified available in `fumadocs-ui/mdx`.)

---

## 5. Per-page content outline (flutterwindcss)

1. **Introduction** — what flutterwindcss is (Tailwind's vocabulary + token discipline for Flutter,
   over Flutter's *primitive* widgets); the mental model (Flutter has no structure/style split — the
   widget tree *is* the styling; no CSS cascade; theming via **semantic indirection**); "material-free"
   = no Material components/visuals, but the generic widgets layer is fair game; how it relates to
   flutterbits (the components layer that consumes these tokens) and to Tailwind/shadcn.
2. **Installation** — add the pub dependency; wrap the app in `FwTheme` on the pure path
   (`WidgetsApp`) **and** the `MaterialApp` interop via `FwThemeExtension`; read tokens with
   `context.fw`; a first styled widget with `.tw`. Toolchain floor note (Flutter ≥ 3.29 / Dart ≥ 3.7).
3. **Styling with `.tw`** — the accumulator model: a `.tw` chain collects into one immutable `FwStyle`
   and renders as a single styled node; **last-wins** conflict resolution; the chain resolves lazily.
   Tour the single-box setter families with examples + Tailwind equivalents: spacing (`p`/`px`/`m`/…),
   sizing (`w`/`h`/`min`/`max`/fractional), color (`bg`/`text`), border + radius, typography, effects
   (`shadow`/`opacity`/`blur`). Note: multi-child layout is **not** `.tw` → see Layout.
4. **Colors** — two layers: the raw **`FwPalette`** (baked Tailwind v4 palette, usable standalone)
   vs. **semantic color roles** resolved by the theme; the color setters (`bg`/`text`/`border`/…);
   guidance: components use semantic roles, raw palette is for building themes / one-off raw colors.
5. **Semantic tokens & theming** — the **32-token** shadcn vocabulary (19 core + chart + sidebar);
   **semantic indirection** (swap the theme → everything reskins); `FwTheme`/`FwTokens`, light + dark;
   `FwAnimatedTheme` (crossfade on theme/brightness change); pointer to the **Theme generator** to
   produce a `theme.dart`.
6. **Conditional styling (states)** — interaction-state variants `hover:`/`focus:`/`pressed:`/
   `disabled:`; how the resolver sources state (visual-only, material-free); `group`/`peer`
   propagation (`groupHover`/`peerHover`, named groups/peers). Note Flutter has no DOM sibling
   selectors → explicit `FwGroup`/`FwPeer` scope.
7. **Breakpoints & responsive** — viewport prefixes (`sm:`/`md:`/`lg:`…) and **container queries**
   (distinct from viewport); responsive layout (e.g. grid column counts) ties back to Layout.
8. **Layout** — the dedicated multi-child widgets the single-box chain can't express:
   `FwRow`/`FwColumn` (flex + `gap`), `FwWrap`, `FwStack`/`FwPositioned` (directional `inset`, `z`),
   `FwGrid` (real CSS-grid render object: `fr`/`px`/`auto`/`minmax`, spanning, placement, alignment;
   `subgrid` de-scoped). Directional by default (RTL-free); chainable with `.tw`.
9. **Theme generator** — the existing page, moved under this tab; light edits so its cross-links and
   "see theming" references fit the new IA.

## 6. Per-page content outline (flutterbits)

1. **Overview** — flutterbits is **shadcn/ui for Flutter**: copy-paste components you **own** (fetched
   via a CLI from a registry, not a versioned dependency), styled **entirely** through flutterwindcss
   semantic tokens (so a generated `theme.dart` reskins them). The planned CLI (`flutterbits add`/
   `diff`) and the registry model. A clear **"Components — coming soon"** Callout: the engine and
   theming are ready; components land next. Links to the flutterwindcss Introduction + Theme generator.

---

## 7. Verification

- **Renders:** run the dev server and load each new page + both sidebar tabs + the home page;
  confirm zero console errors beyond the known `favicon.ico` 404; confirm the tab switcher works and
  the Theme generator page resolves at its new location.
- **CI:** `apps/docs` `docs-generator` job (eslint + scoped tsc + vitest) stays green — note this
  job does **not** build MDX, so rendering is verified manually on the dev server (as for G4/G5).
- **No drift:** the moved `theme-generator.mdx` keeps working; any link to the old path is updated.
  README/AGENTS already describe the products; update only if a statement is falsified.

---

## 8. Delivery

One focused docs PR (`feat/docs-site`) — the IA only makes sense whole (a half-built tab switcher is
worse than none). Per the established workflow: branch → PR → green CI → `gh` merge. The content is
sequential and low-risk; if it grows too large to review, split flutterwindcss content from the
shell/flutterbits in a second PR.

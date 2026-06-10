# flutterbits — registry & CLI (design)

**Status:** design · **Date:** 2026-06-10 · **Audience:** implementers of the `flutterbits` CLI and registry tooling.
**Parent:** `2026-06-10-flutterbits-charter.md`. **Sibling:** `2026-06-10-flutterbits-structure-and-routing-design.md`.
**Extends:** `AGENTS.md` §8 (registry & CLI) — adds `init`, the barrel, install-types, and `flutterbits.json` that §8 did not yet specify.

---

## 1. Model recap (the copy-paste contract)

Components are **source the developer owns**, not a versioned dependency. The CLI fetches a component's files from a **registry** into the host project; the dev reads and edits freely. `registry/*.dart` is the **single source of truth**; JSON manifests are **generated** from it, never hand-edited (AGENTS.md §8).

---

## 2. Install-types (the shadcn `registry:ui`/`lib`/`hook` analog)

The registry needs to know *what kind* of thing each item is so the CLI places it in the right predictable path. Three types:

| `type` | Default target | Purpose | In barrel? |
|---|---|---|---|
| `component` | `lib/components/ui/<name>.dart` | a primitive / structure / block / template | yes |
| `util` | `lib/components/ui/_utils/<name>.dart` | shared lib utility (the `anchor`/overlay substrate, formatters, the `cn`-equivalents, `showConfirm`/`showSheet`/`showToast`) | only if `exported: true` |
| `barrel` | `lib/components/ui/ui.dart` | the regenerated re-export file (managed by the CLI; never authored) | n/a |

**On "hooks":** Flutter has no native hook concept (`flutter_hooks` is a separate dep we are **not** taking — charter §6). What shadcn calls `registry:hook` is, here, a plain Dart `util` — a utility / widget / extension. Same *role*, different mechanism.

### 2.1 The `anchor` util = flutterbits' `cn.ts`

In shadcn, `cn()` lives in a predictable `lib/utils.ts` every project has, and components import it. The flutterbits analog is the **overlay substrate** (`anchor`): the anchored-overlay behavior (`OverlayPortal` + `CompositedTransformFollower` + edge-flip positioning) that Popover, DropdownMenu, Tooltip, Select, Combobox, and ContextMenu all share (charter §3.6). It is a `util`, pasted once into `_utils/anchor.dart`, pulled in as a `registryDep` by every overlay component, and **built before** them.

`anchor` is **internal** (`exported: false`): components import it by relative path; it does not appear in the barrel. Dev-facing helpers like `showConfirm`/`showToast` are `util`s with `exported: true`.

---

## 3. Manifest schema (extends AGENTS.md §8)

```jsonc
{
  "name": "popover",
  "type": "component",            // component | util  (barrel is CLI-managed, not authored)
  "description": "An anchored floating panel.",
  "exported": true,               // does the barrel re-export it? (components: true; internal utils: false)
  "pubDeps": ["flutter_animate"], // pub packages to `flutter pub add`
  "registryDeps": ["anchor"],     // other registry items to install first (recursive)
  "files": [
    { "path": "popover.dart", "type": "component", "target": null, "content": "<dart source>" }
  ]
}
```

- `type`/`target` per **file** lets one item ship files to different predictable locations; `target: null` uses the type default (§2). A `target` override allows custom paths for advanced cases.
- `registryDeps` resolves inter-item needs recursively (e.g. `dialog` → `button`; `popover` → `anchor`). `pubDeps` are real pub packages.
- Manifests are produced by `tooling/build_registry.dart` **from** `registry/*.dart` — `content` is never hand-edited (AGENTS.md §8).
- **Versioning (recorded decision, 2026-06-10).** v1 manifests carry **no** revision/version field, and `diff` (§5.3) compares the dev's copy against the **current** registry source — the same model, and the same limitation, as shadcn. There is no recorded baseline of "which upstream revision I copied from," so `diff` cannot perfectly separate *upstream changes since I copied* from *my own edits*; it shows the full delta and the dev judges. Accepted for v1; a per-file `revision` hash may be added later (capability-raising, not required now). This is a deliberate scope bound, not an oversight.

---

## 4. `flutterbits.json` (the project config — shadcn `components.json` analog)

`init` writes this to the project root; every other command reads it. It records where things go so the CLI never guesses:

```jsonc
{
  "registry": "https://flutterbits.vercel.app/r",  // registry endpoint (served by apps/docs)
  "componentsDir": "lib/components/ui",
  "utilsDir": "lib/components/ui/_utils",
  "barrel": "lib/components/ui/ui.dart",
  "theme": "lib/theme.dart",                        // where the generated theme.dart lives
  "interop": false                                   // true if the app also uses Material (affects nothing yet; reserved)
}
```

---

## 5. Commands

### 5.1 `flutterbits init`

Scaffolds a flutterbits-ready project:

1. Ensures `flutterwindcss` is a dependency (`flutter pub add flutterwindcss`).
2. Creates `lib/components/ui/` and `lib/components/ui/_utils/`.
3. Writes a starter `theme.dart` at the configured `theme` path — a default `FwTokens` light/dark in **exactly the shape the `apps/docs` generator emits** (AGENTS.md §7), so that regenerating from a pasted tweakcn theme is a **drop-in file replacement** at `flutterbits.json.theme`, requiring no component edits (AGENTS.md §7's "drop-in" guarantee). The CLI never does color math (that lives only in `apps/docs`); it just writes the default file.
4. Writes an initial barrel `ui.dart` (empty export list, with the generated-file header).
5. Optionally scaffolds a starter `Layout` (root wiring) so `runApp` is intention-revealing from line one.
6. Writes `flutterbits.json`.

### 5.2 `flutterbits add <name> [<name>…]`

1. Fetch the manifest(s) from `registry`.
2. Resolve `registryDeps` **recursively** (so `add popover` also installs `anchor`; `add dialog` also installs `button`); de-duplicate.
3. Write each file to its `type`/`target`-determined path (§2). Refuse to clobber a modified file without `--overwrite` (the dev owns it).
4. `flutter pub add` every collected `pubDep`.
5. **Regenerate the barrel** (§6).
6. `dart format --line-length 100` the written files.

### 5.3 `flutterbits diff <name>`

The copy-paste **survival mechanism**: shows what changed in the upstream registry version **vs the dev's local copy**, so they can merge upstream improvements (bug fixes, new variants, a11y fixes, Flutter-API-driven changes) **on their own terms**. It **does not auto-merge** — the dev may have customized their copy; merging is their call (like reviewing a PR against a fork). This is why a single canonical `registry/*.dart` source matters: `diff` always has one version to compare against.

### 5.4 `flutterbits remove <name>` (by-demand)

Removes a component's files and **regenerates the barrel**. Leaves `pubDeps` in place by default (other components may share them); `--prune-deps` to attempt removal of now-unused deps. Scheduled by-demand, not v1-blocking.

---

## 6. The barrel (`ui.dart`) — regeneration rules

The barrel is the convenience the dev wanted: import the whole component set from one place instead of file-by-file.

- **Fully regenerated** by the CLI on every `add`/`remove` — **never hand-edited**. It carries a header making that explicit:
  ```dart
  // GENERATED BY flutterbits — do not edit. Run `flutterbits add/remove` to update.
  export 'button.dart';
  export 'card.dart';
  export 'theme_toggle.dart';
  export 'screen.dart';
  export 'layout.dart';
  export '_utils/overlays.dart';   // exported helper util (showConfirm/showSheet/showToast)
  ```
- **Exports `exported: true` items only** — every `component`, plus dev-facing `util`s. **Internal utils** (`anchor`) are imported directly by the components that need them and are **not** in the barrel (keeps plumbing out of the public surface, so no `show`-clause gymnastics are needed).
- **Usage:** `import 'package:my_app/components/ui/ui.dart';` — one import for all installed components.
- **No barrel name collisions.** The hard authoring rule (charter §5.1) guarantees **no exported component name collides with `package:flutter/widgets.dart`** (the rule that bans a `Form`/`Icon`/`Image`/`Table` component), so a wildcard `export` is always safe to import alongside `widgets.dart`. Registry item names are unique, so two components never export the same top-level symbol either. (If a future exception ever forced it, the barrel would emit `export 'x.dart' hide <sym>;` — but the standing rule is to **rename at authoring time**, not paper over with `hide`.)
- **Interop escape hatch (charter §5.1):** a dev mixing Material in can namespace the whole set — `import '.../ui/ui.dart' as ui;` → `ui.Card`, `ui.Button` — resolving any *Material* name clash explicitly, with no `Fw` prefix forced on the common case. The barrel thus doubles as the Material-clash resolver.

---

## 7. Hosting & tooling

- **Registry source of truth:** `registry/*.dart` (one component per file; no barrel that re-exports registry components — they are copied individually, AGENTS.md §4/§8).
- **Manifest build:** `dart run tooling/build_registry.dart` generates the JSON manifests from the Dart source (AGENTS.md §10 "planned commands").
- **Registry endpoint:** served by `apps/docs` (the Next.js site already plans a registry endpoint, AGENTS.md §2). The CLI's `registry` URL points at it. Each component also gets a docs page with source + a Copy button (shadcn-style).
- **CLI package:** `packages/flutterbits_cli` (Dart), exposing the `flutterbits` command (AGENTS.md §2). The CLI **fetches components only** — it does **no** color math or theme generation (that lives solely in `apps/docs`; AGENTS.md §7).

### 7.1 Component previews (how a dev sees it before copying) — decided 2026-06-10

shadcn shows *live* previews because its components **are** the web; flutterbits components are Flutter, so a React reimplementation would show a **different artifact than the one copied** — **rejected** (it would be a fake). Both supported previews render the **real** component:

- **(A) Golden images — the always-on default.** Every component already ships `variant × size × brightness` goldens (AGENTS.md §9). The docs surface those PNGs directly: **100% faithful** (the image *is* the CI-tested render), instant, SEO-friendly, zero runtime cost. This is the primary preview on every component page.
- **(C) DartPad embeds — live + editable, where deps allow.** An official Flutter live-editor iframe runs the **real** Dart: `flutterwindcss` (pub-published) as a dependency + the component source inlined + a tiny demo `main`. Because the component is copy-paste source, the embed *is* the code you copy — preview and source are the same artifact. **Verify per component:** DartPad's pub support must cover that component's `pubDeps` (`flutterwindcss` is fine; confirm `go_router`/`flutter_animate`/`lucide_icons_flutter` before relying on a live embed — otherwise fall back to the golden image).

**Deferred (not rejected):** (B) a single Flutter-Web gallery (one CanvasKit build, lazy iframe) for richer interaction — added by-demand if A+C prove insufficient.

---

## 8. Build/verify discipline (inherited)

- A component is "done" per AGENTS.md §6: styled through `.tw` with semantic tokens, typed-enum variants with exhaustive `switch`, Material-free interaction states, keyboard + focus ring, `Semantics`, directional layout, a manifest entry (§3), goldens for every variant × size × brightness in `apps/example`, and rendered there so CI compiles it.
- `diff` correctness depends on the canonical `registry/*.dart` source staying authoritative; the manifest's `content` is always regenerated, never edited (§3).

---

## 9. Sequencing

1. **Registry plumbing first** — `tooling/build_registry.dart`, the manifest schema (§3), `flutterbits.json` (§4), and the `apps/docs` registry endpoint.
2. **CLI** — `init`, `add` (with recursive `registryDeps` + barrel regen), `diff`. `remove` by-demand.
3. **First vertical slice** (charter §8) — `Layout` + `Screen` + routing + `Button` + `ThemeToggle`, installed via the real CLI into `apps/example`, proving manifest → fetch → place → barrel → compile → golden end-to-end. (`apps/example` is today the *engine* showcase, AGENTS.md §2; this slice is where it **gains a `flutterbits.json` and becomes the component compile + golden target** alongside that role — a real transition, not an assumed-done state.)
4. **The overlay `anchor` util** before any overlay component (Popover/Dropdown/Tooltip/Select/Combobox/ContextMenu).

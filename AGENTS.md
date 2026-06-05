# AGENTS.md

Operating manual for coding agents working in this repository. Read this fully before editing. The rules here are **decisions already made** — do not re-litigate or "improve" them without being explicitly asked. When a rule says MUST / MUST NOT, treat it as a hard constraint that fails review if broken.

> Nested `AGENTS.md` files may exist inside individual packages. The closest file to the code you are editing wins; this root file is the fallback.

---

## 1. What this project is

Two products in one monorepo:

- **`flutterwindcss`** — Tailwind CSS's *design system and styling vocabulary* for Flutter. A real pub dependency. It provides design tokens (spacing, radius, semantic colors) and a utility authoring API over Flutter's **primitive** widgets. This is the "Tailwind" layer.
- **`flutterbits`** — shadcn/ui for Flutter. **Copy-paste** components (the developer owns the source, fetched via a CLI from a registry), styled entirely through `flutterwindcss` and semantic tokens. This is the "shadcn/ui" layer.

The headline feature is **theme portability**: a developer pastes any [tweakcn](https://tweakcn.com)/shadcn theme into a web generator and gets a working Flutter `theme.dart`. No other Flutter UI library does this — protect it.

### Mental model (read this once, internalize it)

- Flutter has **no structure/style split**. The widget tree *is* the styling. There is no CSS cascade. We re-create Tailwind's *vocabulary and token discipline*, not a CSS engine.
- Theming works by **semantic indirection**, exactly like shadcn: components reference semantic tokens (`primary`, `muted`, `border`), never raw palette swatches. Swapping the theme reskins everything because of this indirection. Break it once and that component silently stops theming.
- "Material-free" means we do not use Material **components or visuals**. We freely use the framework's generic layer (`package:flutter/widgets.dart`): `Container`, `Padding`, `Row`/`Column`, `DecoratedBox`, `FocusableActionDetector`, `WidgetState`, `Semantics`, etc.

---

## 2. Repository layout

```
packages/
  flutterwindcss/        # pub package: tokens, FwTheme, FwStyle accumulator, .tw utilities
  flutterbits_cli/       # Dart CLI exposing the `flutterbits` command (add/diff components)
registry/                # SOURCE OF TRUTH for components: .dart files + JSON manifests
apps/
  docs/                  # Fumadocs (Next.js) site: docs + the tweakcn -> theme.dart generator + registry endpoint
  example/               # Flutter showcase app; ALSO the golden-test + compile target for the registry
tooling/                 # registry builder, melos config, CI scripts
```

> **This is the *target* layout.** Today only `packages/flutterwindcss/` and `tooling/bake_palette.dart` exist; `flutterbits_cli/`, `registry/`, `apps/`, and the melos config are planned (the README marks them `(planned)`). Don't go looking for dirs that aren't there yet.

- **Toolchain floor (hard): Flutter ≥ 3.29 / Dart ≥ 3.7.** The wide-gamut `Color` API (`Color.withValues` per §3.8, and the `Color.a/.r/.g/.b` accessors), the `Row`/`Column`/`Flex` `spacing` parameter, and pub workspaces require 3.27/3.6 — below that, the code will not compile. We floor one minor higher at **Dart 3.7** so `dart format` uses the modern "tall" style (Dart 3.7+) rather than the legacy short style; mixing the two fails the format check. This floor is set in every `pubspec.yaml` `environment:` and **verified by a CI job pinned to it** (separate from the golden job, which pins a newer version for determinism). Keep the floor identical in the pubspecs and the README.
- Dependency resolution: **pub workspaces** (`resolution: workspace` in each `pubspec.yaml`). Task running / versioning / publishing: **Melos** — the intended cross-package runner, adopted once the workspace holds multiple packages. While `flutterwindcss` is the only package, use plain `flutter`/`dart` per-package (see §10).
- The site (`apps/docs`) is **TypeScript**. The packages and CLI are **Dart**. Keep the boundary clean (see §7).

---

## 3. Non-negotiable architecture rules

These encode hard-won decisions. Violating any of them is a review failure.

1. **Semantic tokens only in components.** A `flutterbits` component MUST reference `context.fw.colors.<semantic>` (e.g. `primary`, `mutedForeground`, `border`). It MUST NOT hardcode `Color(0x...)` or reach for a raw Tailwind palette swatch for anything themeable. The only allowed literal color is fully transparent (`Color(0x00000000)`) for "no fill".

2. **Accumulator styling model.** Single-box utilities collect into one immutable `FwStyle` and render as a single styled node *in component code*. Internally that node is a fixed, documented chain of widgets-layer primitives (`ConstrainedBox`/`DecoratedBox`/`Padding`/…) — **not** literally one Element. The win is **last-wins conflict resolution** + emitting no duplicate wrappers, not flatness (`.px(4).px(2)` ⇒ padding 2 units). `FwStyle` is a **lazy resolver**: it resolves against the active interaction states and the viewport/container size, so `hover:`/`focus:`/`pressed:`/`disabled:` and `sm:`/`md:`/container-query variants are first-class, not bolted on. You MUST NOT hand-nest style wrappers (`Padding(child: DecoratedBox(child: ...))`) in component code — express single-box styling through `.tw`. **Multi-child layout is NOT `.tw`:** flex direction/alignment, `gap`, positioning/`inset`, and `z-index` live in dedicated layout widgets (`FwRow`/`FwColumn`/`FwWrap`/`FwStack`/`FwPositioned`/`FwGrid`), because a single-child wrapper structurally cannot express them. Canonical implementation: `packages/flutterwindcss/lib/src/style/`. Imitate it.

3. **Directional by default.** All spacing/alignment/radius MUST use the directional variants: `EdgeInsetsDirectional`, `AlignmentDirectional`, `BorderRadiusDirectional`. Never `EdgeInsets.only(left:/right:)` or `Alignment.centerLeft`. This is what makes RTL free; retrofitting it later is expensive.

4. **Provider-agnostic token access.** Components read tokens ONLY via `context.fw`. They MUST NOT call `Theme.of(context)` directly. `context.fw` resolves the Material-free `FwTheme` first and falls back to `FwThemeExtension`, so the same component works in a bare `WidgetsApp` and inside a `MaterialApp`. See `packages/flutterwindcss/lib/src/theme/`.

5. **No Material in components.** `flutterbits` component files MUST NOT import `package:flutter/material.dart`. Use `package:flutter/widgets.dart`. State styling uses `WidgetState`/`FocusableActionDetector` (widgets layer), not `InkWell`/`MaterialState`. The *only* sanctioned Material touch in the whole repo is the `FwThemeExtension` bridge in `flutterwindcss`.

6. **Respect the public API contract.** Components depend ONLY on the `flutterwindcss` barrel surface: `.tw`, `context.fw`, and the token types. They MUST NOT import from `flutterwindcss/lib/src/...` directly or use private helpers. Adding to the public surface is fine anytime; **renaming or removing requires a deprecation cycle**, because every copied component in the wild pins those names.

7. **No runtime string parsing for styles.** Styling is typed method calls resolved at compile time. Do not introduce a `"p-4 bg-primary"` className parser. (This was deliberately rejected.)

8. **Color API:** use `Color.withValues(alpha: ...)`. Never `withOpacity` (deprecated).

---

## 4. Coding conventions (Dart)

- Public types are prefixed `Fw` (`FwStyle`, `FwButton`, `FwColors`, `FwButtonVariant`).
- Prefer `const` constructors wherever the analyzer allows; leaf widgets that never change should be `const`.
- Variants are **typed enums + exhaustive `switch`** (the cva equivalent). No stringly-typed variant maps. The `switch` must be exhaustive so the compiler catches a missing case — do not add a `default:` that papers over new enum values.
- Every file passes `dart format` (100-col) and `flutter analyze` with **zero** warnings before you call a task done.
- Doc-comment every public member with `///`. Explain *why*, not just *what*, when a choice is non-obvious.
- One component per file in `registry/`. No barrel that re-exports registry components (they are copied individually).

---

## 5. The token system

Semantic colors (the shadcn set — this list is the contract the generator targets):

`background, foreground, card, cardForeground, popover, popoverForeground, primary, primaryForeground, secondary, secondaryForeground, muted, mutedForeground, accent, accentForeground, destructive, destructiveForeground, border, input, ring`

- Radius is derived from one base value (shadcn `--radius`): `sm = ×0.6, md = ×0.8, lg = ×1, xl = ×1.4`. Components use `t.radii.md` etc., never a literal radius.
- Spacing scale: **1 utility unit = 4 logical pixels** (`fwSpace`). `.px(4)` ⇒ 16 px.
- Two `FwTokens` instances exist per theme (light + dark). Theme switching is the host app's job; transitions animate via `FwTokens.lerp`.
- The semantic set is not the whole token system. A `FwTokens` bundle carries `colors` (the 19 above), `radii`, `shadows` (`FwShadows`), and `typography`. **Theme-independent** scales live on their own types: the raw Tailwind v4 palette (`FwPalette`, baked — used to *build* themes, never referenced directly by components), the Tailwind named radius/typography/shadow/blur scales, and scalar scales for opacity, border-width, z-index, and breakpoints. The interaction-state and breakpoint enums (`FwState`, `FwBreakpoint`) are a **frozen API contract** — exhaustive `switch`es depend on them, so adding a value is a breaking change, not additive.
- To add a new semantic token: add the field to `FwColors` (+ `copyWith`, `lerp`, `==`/`hashCode`), wire it into the `FwTokens.light`/`dark` defaults, add it to the generator's parse map (§7), and document it. Adding a *semantic color* is additive and safe; adding an `FwState`/`FwBreakpoint` enum value is **not** (see above).

---

## 6. Authoring a flutterbits component

Until the first component lands, follow the component checklist below and the engine design spec's component patterns (`docs/superpowers/specs`, §6). Once `registry/button.dart` exists it becomes the canonical template (it mirrors the reference `flutterbits/button.dart`). A component is **done** only when ALL of these hold:

- [ ] Styled through `.tw`, using semantic tokens for every themeable value.
- [ ] Variants/sizes are typed enums with an exhaustive `switch` resolver.
- [ ] Interaction states (hover/focus/pressed/disabled) handled via `FocusableActionDetector` + local state, Material-free.
- [ ] Keyboard activation wired via `ActivateIntent` → `CallbackAction`; a visible focus ring uses `context.fw.colors.ring`.
- [ ] Wrapped in `Semantics(...)` with correct role/flags (`button: true`, `enabled:`, labels). Accessibility is **required**, not optional — Flutter supports it, so we ship it (target web/desktop included).
- [ ] Directional layout throughout (§3.3).
- [ ] A registry manifest entry (§8) listing pub deps and `registryDeps`.
- [ ] Golden tests for **every variant × size × brightness** (§9).
- [ ] Imported and rendered in `apps/example` so CI compiles it.

If a desired behavior genuinely cannot be done in Flutter, do not fake it — add it to the **Won't-do list** (§11) and note it in the component's docs.

---

## 7. The theme generator (`apps/docs`, TypeScript)

- Input: a pasted tweakcn/shadcn theme (`:root` + `.dark` blocks). Output: a downloadable `theme.dart` **and** a `theme.json` (the JSON is the source of truth; the Dart file is the emitted artifact).
- MUST parse **all four** color formats: `oklch()`, `hsl()`, `rgb()`, hex. OKLCH is the tweakcn default (Tailwind v4).
- Color conversion: OKLCH → OKLab → linear sRGB → gamma-encode → **gamut-map** (do not naively clamp; clamping shifts hue). sRGB target by default; optionally target display-P3 for wider gamut. **This rule is for converting *arbitrary user themes* faithfully to what a browser renders.** It does **not** govern the baked `FwPalette` (`flutterwindcss`), which instead transcribes **Tailwind's own published (gamut-clipped) hex** so it matches the recognizable Tailwind values — see the engine spec §4.1 "Conversion policy." The two can differ for out-of-gamut shades by design.
- Parse **color, radius, shadow, and typography** tokens — not just color. "The theme works" is false if shadows and type don't come across.
- **Fonts:** the generator emits the `fontFamily` *name* and optional `google_fonts` wiring. It MUST NOT pretend to bundle an arbitrary font. If the family is unknown, emit a clearly-commented `// TODO: bundle this font or map it` rather than a silent fallback.
- **Color math lives only here.** The Dart CLI does NOT generate themes; it only fetches components. Do not duplicate the conversion in Dart.
- The emitted `theme.dart` defines two `FwTokens` (light/dark) against the §5 contract. Regenerating MUST be a drop-in file replacement requiring no edits to component code.

---

## 8. Registry & CLI

- Registry manifest per component (JSON): `{ name, description, pubDeps: [...], registryDeps: [...], files: [{ path, content }] }`. `registryDeps` resolves inter-component needs (e.g. `dialog` pulls in `button`).
- `flutterbits add <name>` writes files into the host project (default `lib/components/ui/`), installs `pubDeps`, recursively adds `registryDeps`, then runs `dart format`.
- `flutterbits diff <name>` shows upstream changes vs the developer's copy (the copy-paste survival mechanism — analogous to shadcn's diff).
- The registry build step (`tooling/`) generates manifests FROM the `registry/*.dart` source. Never hand-edit a manifest's `content`.

---

## 9. Testing — mandatory, not optional

This is the safety net that makes a solo, wave-by-wave rollout survivable.

- **Golden tests** use `matchesGoldenFile`. **`flutterwindcss` engine goldens live in-package** (`packages/flutterwindcss/test/golden/`) — a library tests its own widgets. **Component goldens** (every variant × size × brightness) live in `apps/example`, which is also the registry compile target.
- CI pins a **fixed font** and platform so goldens are deterministic across machines, and **CI (Linux) is the authoritative golden platform** — goldens are generated/verified there, and a local `--update-goldens` on a dev box is *not* authoritative. A golden diff on CI is a failing build, not a nuisance.
- Update goldens only intentionally: `flutter test --update-goldens`, and review the image diff before committing.
- `flutterwindcss` gets unit tests for `FwStyle` resolution — especially **last-wins conflict behavior** and that chaining produces a single resolved widget.
- Before marking any task done: `flutter analyze` (zero warnings) AND `flutter test` (green) AND the registry compiles in `apps/example`.

---

## 10. Commands

Adjust paths if the layout drifts; keep this section current.

**Current commands** (while `flutterwindcss` is the only package — use plain `flutter`/`dart`):

| Task | Command |
|---|---|
| Resolve workspace deps | `flutter pub get` |
| Analyze (zero-warning bar) | `cd packages/flutterwindcss && flutter analyze --fatal-infos --fatal-warnings` |
| Format (100-col) | `dart format --line-length 100 .` |
| Run tests | `cd packages/flutterwindcss && flutter test` |
| Update goldens (local = non-authoritative; CI is the source of truth) | `cd packages/flutterwindcss && flutter test --update-goldens` |
| Bake Tailwind palette (regenerate `palette.g.dart`) | `dart run tooling/bake_palette.dart` |

**Planned commands** (once the corresponding products exist):

| Task | Command |
|---|---|
| Build registry manifests | `dart run tooling/build_registry.dart` |
| Run docs site / generator | `cd apps/docs && pnpm dev` |
| Run showcase app | `cd apps/example && flutter run` |

Once the workspace holds multiple packages, **Melos** wraps the per-package commands (`melos bootstrap`, `melos run analyze`, `melos run test`); adopt it then, not before.

---

## 11. Won't-do list (don't waste effort here)

These have no faithful Flutter equivalent. Don't attempt to fake them; document them where relevant:

- True CSS cascade / inheritance semantics (we use explicit `DefaultTextStyle`/`IconTheme` instead).
- CSS Grid `subgrid` and grid auto-placement. (Simple `grid-template-columns: 1fr 2fr` IS doable via flex — ship an `FwGrid` helper, don't apologize.)
- Pseudo-elements as implicit content (use explicit child composition).

Everything else — sticky (slivers), container queries (`LayoutBuilder`), backdrop blur (`BackdropFilter`), hover/focus/keyboard — IS implementable as a Flutter idiom. Prefer a helper widget over a docs note.

---

## 12. Agent operating rules

- **Read before you edit.** Open the canonical sources (`lib/src/style/`, `lib/src/theme/`, `lib/src/tokens/`, and once it exists `registry/button.dart`) and match their patterns before writing new code.
- **Small, focused changes.** One component or one utility group per change. Don't refactor unrelated code in passing.
- **No new dependencies without justification.** Prefer the framework's widgets layer. Known sanctioned deps: `lucide_icons_flutter` (icons), `flutter_animate` (animation). Anything else needs a reason in the PR description.
- **Don't invent APIs.** If unsure whether a Flutter symbol exists in the widgets layer, verify before using it. Do not assume Material symbols are available.
- **Surface assumptions.** If a task is ambiguous (which variant set? which platforms?), state the assumption you made inline rather than guessing silently.
- **Never weaken the rules in §3 to make a task pass.** If a rule blocks you, stop and flag it — don't import Material, don't hardcode a color, don't nest wrappers to ship faster.
- **Definition of done** = matches §6 (components) or compiles+tested+documented (everything else), analyzer clean, goldens reviewed.

---

## 13. Glossary

- **Semantic token** — a role-named design value (`primary`) resolved by the active theme; the unit of theming.
- **Accumulator model** — single-box utilities merge into one immutable `FwStyle` that resolves lazily (against interaction states + viewport/container size) to a fixed chain of widgets-layer primitives; last-wins on conflicts. Multi-child layout (`FwRow`/`FwColumn`/`FwStack`/`FwGrid`) is separate widgets, not `.tw`.
- **`.tw`** — the entry getter that begins a style chain on any widget. Distinct from `context.fw` (token access).
- **Copy-paste / registry model** — components are source the developer owns, fetched via the CLI, not a versioned dependency.
- **Pure path / interop path** — Material-free app (`FwTheme` + `WidgetsApp`) vs. Material app (`FwThemeExtension` on `ThemeData`).
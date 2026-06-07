# flutterwindcss Module 3 — Resolver Core: Design

> Scope/partition design for the engine keystone. This layers on the core engine
> spec (`2026-06-05-flutterwindcss-core-engine-design.md`, §6) — it does **not**
> re-derive the render chain, data model, or resolution algorithm, which are
> already pinned there. Its job is to decide **what Module 3 builds vs. defers**,
> the file breakdown, and the test plan, so the implementation plan can be written
> task-by-task.

**Goal:** Land the `FwStyle` resolver engine — the lazy, nested-layer styling core
that every later module extends. After Module 3, the engine is *structurally
complete*: the full data model exists, the full render chain renders, the full
variant/responsive/container layering works, and `.tw` is usable. Modules 4–9 then
only add typed base-setter sugar + per-slice goldens; they never re-touch the core.

**Depends on:** Module 1 (tokens — `FwTokens`, `FwShadows`, scales, `FwState`,
`FwBreakpoint`) and Module 2 (`context.fw`). All merged on `main`.

**Spec:** core engine design §6 (§6.0 boundary, §6.1 data model, §6.2 `FwStyled`,
§6.3 resolution, §6.4 render chain, §6.5 utility surface), §7 RTL/a11y, §10 testing,
§11 risks (R2, R3, R5, R6).

---

## 1. Decision: full data model + full render chain up front

Module 3 builds the **entire** §6.1 data model and the **entire** §6.4 render chain,
not a vertical slice that grows.

**Why (the partition principle):** §6.4 is a single, fixed, *test-asserted* wrapper
order. If it were built incrementally, that order-assertion test would churn in every
module 4–9 — each later module editing the core's most delicate test. That violates
the project rule "each module 100% complete when merged, no cross-module TODOs"
(engine spec §7, §12). Defining all-nullable fields and the whole chain once lets the
resolve + last-wins logic be written a single time, and makes 4–9 purely additive.

**Consequence for testing the chain:** the render-order test constructs `FwStyle`
**directly** with fields populated — it does not need ergonomic `.tw` setters. So the
full chain is testable in Module 3 even though most base setters ship later.

**Consequence for testing the engine ergonomically:** last-wins (`.px(4).px(2)`) and
state layering (`.hover((s) => s.bg(...))`) need *some* base setters. Module 3 ships a
**representative base-setter slice — `padding` (`p/px/py/ps/pe/pt/pb`) + `bg`** — and
the **complete** variant/layer surface (`hover/focus/pressed/disabled/whenState`,
`sm/md/lg/xl/xl2`, `containerSm…container2xl`), because the variant methods *are* the
layering engine. These two base families are exactly what engine-spec §10's canonical
tests use (`.px` for last-wins; hover-changes-`bg` for a state layer) and make a real
LTR/RTL/hover golden possible.

> Minor ownership note: `bg`'s base setter lands here as the engine's test vehicle;
> Module 5 (color/border/radius/gradient) builds on it by adding `bgGradient`, border,
> and radius setters — it does not re-implement `bg`. `padding` setters land here;
> Module 4 adds the remaining spacing/sizing (`margin`, `w/h/min/max`, fractional,
> aspect). Both overlaps are documented so the later modules know `bg`/`padding`
> already exist.

---

## 2. Scope partition

**Module 3 owns (engine):**

| Unit | File | Responsibility |
|---|---|---|
| `FwStyle` | `lib/src/style/fw_style.dart` | Full §6.1 immutable data model: every base field (spacing, sizing, color/decoration, foreground/text, effects, transform, clip) + `List<FwLayer> layers`; `copyWith` (replacement = last-wins); `==`/`hashCode`. Hosts the variant/layer methods (append a layer). |
| `FwLayer`, `FwCondition` | `lib/src/style/fw_layer.dart` | `FwLayer = (FwCondition, FwStyle)`; `FwCondition` = `state(WidgetState)` \| `viewport(FwBreakpoint)` \| `container(FwBreakpoint)`. Layers nest (a layer's style may itself carry layers). |
| `ResolvedStyle`, `FwStyle.resolve` | `lib/src/style/resolve.dart` | Full §6.3: disabled-suppression-first; base → matching layers overlaid in **cascade order** (breakpoints by min-width, then states; declaration order tie-breaks — corrected — audit, was raw declaration order); recurse into nested styles (joint `md:hover:`); field-by-field last-wins merge. Produces the flattened, non-nullable-defaulted `ResolvedStyle`. |
| `ResolvedStyle.build` | `lib/src/style/resolved_style.dart` | The complete §6.4 chain, outer→inner, each wrapper emitted only when its input is set; `_ShadowBox`/`_Surface` split + backdrop-blur layering; sizing reconciliation (§6.4 Finding #6); opacity folding (Finding #11); clip geometry (Finding #3). |
| `_ShadowBox`, `_Surface` | (private, in `resolved_style.dart`) | Internal primitives for the unclipped-shadow / backdrop-clip split. Not exported. |
| `FwStyled`, `.tw` | `lib/src/style/fw_styled.dart` | §6.2 `StatelessWidget`: conditional `MediaQuery`/`LayoutBuilder`/interaction-sourcing (`MouseRegion`+non-traversable-`Focus`+`Listener`, corrected — module 3, *not* `FocusableActionDetector`) insertion (computed over the *flattened* layer set); semantics-transparent; focus-traversal hygiene (visual-only states non-focusable, Finding #9); optional `states` injection param. The `.tw` entry extension. Hosts the representative base setters + the full variant/responsive/container methods. |

**Deferred (later modules add setters + goldens only):** `margin`, `w/h/min/max`,
fractional, `square`/`aspect` (M4); `bgGradient`, border (per-side + directional),
`rounded*`, `shadow()` (M5); typography setters (M6); `opacity`/`blur`/`backdropBlur`
(M7); layout widgets (M8); `scale`/`rotate`/`translate` (M9). The *fields* for all of
these exist in `FwStyle` from Module 3; later modules add the ergonomic methods that
set them.

---

## 3. Resolution & precedence (restating the contract Module 3 must satisfy)

From §6.3 — pinned here as the acceptance contract:

1. **Disabled suppression first:** if `WidgetState.disabled ∈ states`, drop
   `hovered/focused/pressed` from the working set before any layer matching, and guard
   the press recognizer so it cannot re-add `pressed`. Disabled wins regardless of
   declaration order.
2. Start from **base** fields.
3. Find the **matching** layers (`state` ∈ working set; `viewport`/`container`
   breakpoint min-width ≤ available width), resolving each nested `FwStyle` first so
   joint `md:hover:` comes for free.
4. Overlay them onto the base in **cascade order** (corrected — audit, was raw
   declaration order): breakpoint layers by min-width ascending (container over
   viewport at the same breakpoint), then state layers (above breakpoints, like a CSS
   pseudo-class), with declaration order only as the within-tier tie-break. Breakpoint
   precedence is therefore order-independent (`.md(...).sm(...)` ≡ `.sm(...).md(...)`),
   matching the layout widgets' `fwActivePatches`. Merge field-by-field, last-wins.
5. Apply non-nullable defaults to produce `ResolvedStyle`.

**Width sources (R2/R5/R6):** viewport conditions read `MediaQuery.maybeOf(context)?.size`
(absent ⇒ smallest breakpoint, base only — never throws). Container conditions read the
single wrapping `LayoutBuilder`'s incoming constraint width — the space the parent offers,
measured **outside** the sizing wrappers (Finding #1), so a `container` layer that sets
`width` can't feed back on its own measurement. Both ancestors are inserted **only** when
the flattened layer set actually contains that condition kind.

---

## 4. Test plan (engine spec §10)

**Unit / widget tests (`test/style/`):**
- **Last-wins per field:** `FwStyle().px(4).px(2)` resolves horizontal padding to
  `fwSpace(2)` = 8 px (the `.px(4)` is discarded, not summed).
- **Chain flattens to one `ResolvedStyle`:** a multi-utility chain resolves to a single
  value set.
- **Layer precedence (cascade):** base < breakpoints (by min-width; container > viewport
  at the same breakpoint) < state layers; declaration order only breaks within-tier ties.
  Breakpoint precedence is order-independent (`.md(...).sm(...)` ≡ `.sm(...).md(...)`); a
  `hover:` beats a `sm:` at ≥ sm.
- **Nested joint resolution:** `.md((s) => s.hover((s2) => s2.bg(X)))` applies `X` only
  when viewport ≥ 768 **and** hovered.
- **Disabled suppression:** disabled removes hover/focus/pressed effects regardless of
  where the disabled layer is declared.
- **`resolve` honors inputs:** hover changes `bg`; `md` changes `padding` at viewport
  ≥768 and not below; `containerMd` keys off the `LayoutBuilder` constraint width.
- **Render chain order:** construct `FwStyle` directly with each field group set; assert
  each wrapper is present **iff** its field is set, and assert the documented outer→inner
  order via the pumped element tree (incl. shadow-outside-clip and backdrop-above-surface).
- **Sizing reconciliation:** fixed `width` wins its axis (tight constraint); `min/max`
  apply only to axes without a fixed value; fixed + min/max on the same axis asserts in
  debug.
- **Conditional ancestor insertion:** a purely-static style inserts no `MediaQuery`
  reader / `LayoutBuilder` / interaction sourcing; a `hover:`-only style inserts
  visual-only sourcing — `MouseRegion` + a **non-traversable** `Focus` + `Listener`
  (no tab stop; corrected — module 3, *not* a `FocusableActionDetector`; see §7). A
  focusable detector + visible `ring` belongs to an action-bearing **component**, not the
  engine.
- **Semantics transparency:** a `Semantics(button: true)` child survives a full `.tw`
  chain; a `hover:`-only box does **not** appear in focus traversal (§7).

**Golden tests (`test/golden/`, CI/Linux authoritative):** the representative slice
(`padding` + `bg` + rounded-via-direct-field if needed) rendered **light + dark** and
**LTR + RTL**, plus **hovered** pumped — proving the golden harness works against the
engine. The exhaustive per-utility goldens are modules 4–9's job.

---

## 5. Risks carried into implementation

- **R2** — no `MediaQuery` ⇒ base-only, never throw. Tests pump explicit sizes.
- **R3** — interaction sourcing (`MouseRegion` + non-traversable `Focus` + `Listener`)
  only when a live-sourced state layer is present; visual-only is non-focusable (no tab
  stop). Corrected — module 3: *not* a `FocusableActionDetector` (see §7).
- **R5/R6** — `LayoutBuilder` inserted only for container layers; viewport stays
  `MediaQuery`-based; document the intrinsic-sizing caveat on `.containerXx`.
- New: the **render-chain order test is the engine's most brittle test** — it is the
  contract modules 4–9 rely on. Keep it asserting *relative* order + presence, not exact
  element counts, so adding a sibling wrapper later (within spec) doesn't false-fail.

---

## 6. Definition of done (Module 3)

Engine spec §12 + §10: `FwStyle`/`ResolvedStyle`/`FwStyled`/render chain/layering all
implemented; the representative base-setter slice + full variant surface usable; all
§4 unit + golden tests green on CI; `flutter analyze --fatal-infos --fatal-warnings`
clean; `dart format` clean; all four arch-guards pass; barrel exports the new public
surface (`.tw`/`FwStyled`/`FwStyle`). No stubs, no cross-module TODOs.

---

## 7. As-built corrections (recorded post-TDD)

What landed differed from this design and the original engine spec in three deliberate
ways — each stricter/more correct, each now reflected in the engine spec:

1. **Two-width resolution.** `resolve(Set<WidgetState> states, {double? viewportWidth,
   double? containerWidth})` — viewport and container widths are passed **separately**,
   not merged into one. A box mixing `md:` and `containerMd:` resolves each from its own
   source (`MediaQuery` vs `LayoutBuilder`); neither can satisfy the other. (The plan had
   tentatively unified them to a single width — rejected as a correctness gap.)

2. **Interaction sourcing uses `MouseRegion` + non-traversable `Focus` + `Listener`, not
   `FocusableActionDetector`.** FAD's internal `Focus` overrides a passed node's
   `canRequestFocus`/`skipTraversal` while `enabled`, so it cannot be made non-traversable
   — it would add a tab stop and violate §7. The chosen primitives add no tab stop and no
   `focusable` semantics flag (verified: a `Semantics(button:true)` child keeps
   `button=true, focusable=false` through the interactive path). A real focusable detector
   + visible `ring` is an interactive **component's** job, not the engine's.

3. **Interaction wrappers activate only for live-sourced states.** Only a layer keyed on
   `hover`/`focus`/`pressed` inserts the wrappers; component-managed states (`selected`,
   `disabled`, …) inject via `FwStyled.states` and resolve **statelessly**. (Audit fix —
   the first cut over-triggered on any state condition.)

**Deferrals (tracked, not silent):**
- **Content-clip radius deflation by border width (Finding #3)** → **landed in module 5**
  (✅ done). It was coupled to the border width module 5 introduces and untestable in
  module 3 (no `.border`/`.rounded`/`.clip` setters shipped here). Module 5 now deflates
  each content-clip corner by its adjacent per-edge border widths; with no border the
  un-deflated radius is used. See engine spec §6.4 Finding #3 and the module 5 row.
- **Opacity fold (Finding #11)** → deferred **perf** optimization. Module 3 always emits a
  true `Opacity` (always correct); the fold lands later behind the same tests.

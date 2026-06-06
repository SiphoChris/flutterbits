# flutterwindcss — Real CSS Grid Engine (design)

> **Status:** design approved-in-spirit (supersedes the AGENTS.md §11 / core-engine §6.6 claim that grid spanning / auto-placement / subgrid are Non-Goals). This document is the **feasibility verdict + architecture** for a faithful CSS-Grid-Level-1 `FwGrid` built on a custom `RenderObject`. It exists because the prior "needs a custom `RenderObject`, out of v1 scope" framing was a shortcut, not a real limitation (AGENTS.md §12 "Feasibility honesty").

## 1. Feasibility verdict (the honest audit of each "Non-Goal")

| Capability | Prior claim | Reality | Verdict |
|---|---|---|---|
| `fr`/`px` column tracks | "doable via flex" ✅ | true | already shipped (M8) |
| **`auto` / `minmax()` tracks** | implied out of scope | a track-sizing algorithm over child intrinsic sizes; standard | **BUILD** |
| **Explicit row tracks + implicit rows** | out of scope | a second axis sized the same way | **BUILD** |
| **Cell/row spanning (`grid-column`/`grid-row`)** | "needs a custom RenderObject → out of v1" | needs a custom `RenderObject` — which is normal Flutter, not impossible | **BUILD** |
| **Auto-placement (sparse + dense)** | out of scope | a pure-logic packing algorithm (CSS §8) | **BUILD** |
| **Item + self alignment (justify/align items/self)** | out of scope | offset/size each child within its cell rect | **BUILD** |
| **`subgrid`** | "out of v1" | possible via a parent→child track-line-sharing protocol; the hardest piece | **DE-SCOPED (not built)** — *feasible*, but deliberately left out for v1 by explicit decision (negligible real-world usage); AGENTS.md §11b. Documented as a known `FwGrid` limitation, **not** as "impossible". |

**Nothing here is impossible in Flutter.** A `RenderBox` with `ContainerRenderObjectMixin` can express arbitrary 2-D layout; `RenderFlex`/`RenderWrap`/`RenderTable` are existing proofs. Subgrid is the one item we *choose* not to build for v1 (cost ≫ demand), recorded honestly as a de-scope (AGENTS.md §11b), never as a limitation of the framework. (CSS masonry / `grid-template-areas` string parsing are sugar we can add later; not impossible either.)

## 2. Architecture

`FwGrid` becomes a `MultiChildRenderObjectWidget` over a new `RenderFwGrid extends RenderBox with ContainerRenderObjectMixin<RenderBox, FwGridParentData>, RenderBoxContainerDefaultsMixin`. Placement metadata rides a `ParentDataWidget` `FwGridItem` (exactly the `Stack`/`Positioned` pattern). Items without an `FwGridItem` are span-1, auto-placed.

```
FwGrid(MultiChildRenderObjectWidget)
  ├─ columns: List<FwGridTrack>           (explicit, required, non-empty)
  ├─ rows: List<FwGridTrack>?             (explicit row template; optional)
  ├─ autoRows: FwGridTrack = FwAuto()     (sizes implicit rows beyond `rows`)
  ├─ columnGap / rowGap (utility units)
  ├─ dense: bool = false                  (auto-placement packing)
  ├─ alignItems / justifyItems: FwGridAlign = stretch
  ├─ viewport/container: Map<FwBreakpoint, FwGridPatch>   (responsive, as M8)
  └─ children: [ FwGridItem(...) | any Widget ]

FwGridItem(ParentDataWidget<FwGridParentData>)
  ├─ columnStart: int?  (1-based grid line; null = auto)
  ├─ columnSpan: int = 1
  ├─ rowStart: int?     (1-based; null = auto)
  ├─ rowSpan: int = 1
  ├─ justifySelf / alignSelf: FwGridAlign?  (null = inherit grid)
  └─ child
```

### 2.1 Track model (`FwGridTrack` sealed — extends the M8 grammar)

```
sealed FwGridTrack
  ├─ FwFr(int flex)              flexible — share of leftover space
  ├─ FwPx(double size)          fixed logical px
  ├─ FwAuto()                   max-content of the track's items
  └─ FwMinMax(double minPx, FwGridTrack max)   clamp: min ≤ size ≤ max(track)
```

`FwFr`/`FwPx` are unchanged (M8). `FwAuto`/`FwMinMax` are additive. A `repeat(n, track)` is a **pure helper** `FwTrack.repeat(n, t) → List<FwGridTrack>` (sugar; no engine change). The cell resolver stays an exhaustive `switch` (compiler-checked, no `default:`).

### 2.2 Layout algorithm (per axis: columns first, then rows)

Faithful to CSS Grid §11 track sizing, scoped to the track functions above:

1. **Placement** (CSS §8): seat explicitly-placed items (`columnStart`/`rowStart`), build an occupancy matrix of `columns.length` columns × growing rows, then auto-place the rest row-major into the first region that fits the item's span (`dense` reconsiders earlier holes; sparse advances a cursor). Spans clamp to the column count (an over-span logs and clamps — never silently overflows).
2. **Base sizes:** `FwPx`→its size; `FwAuto`→0; `FwFr`→0; `FwMinMax`→`minPx`.
3. **Intrinsic resolution** for `auto`/`minmax` tracks: each item contributes its max-intrinsic main size to the auto tracks it spans; for multi-track spans the contribution beyond already-fixed tracks is distributed evenly across the spanned auto tracks (CSS §11.5 "distribute extra space"). Implemented and unit-pinned.
4. **Flex (`fr`) resolution:** `free = available − Σ(non-fr base) − Σ gaps`; each `fr` = `max(0, free × flex/Σflex)`. **If the axis is unbounded** (e.g. width = ∞), `fr` falls back to its max-content size (an `fr` cannot divide infinite space) — asserted/documented at the call site, mirroring `Flex` under unbounded constraints.
5. **`minmax` clamp:** final size clamped to `[minPx, max-resolved]`.
6. **Position + size children:** each item gets the rect spanning its tracks (+ interior gaps); `stretch` makes the child fill the rect, otherwise the child lays out to its own size and is offset by `justify/align (self ?? grid)`.

Rows reuse the identical track-sizing function on the cross axis; implicit rows (beyond an explicit `rows` template) are sized by `autoRows`.

### 2.3 Alignment vocabulary

`FwGridAlign { stretch, start, end, center }` (directional: `start`/`end` resolve against `TextDirection` on the inline axis). Grid-level `alignItems`/`justifyItems` default `stretch`; per-item `alignSelf`/`justifySelf` override. (Content-distribution `align/justifyContent` for the case where tracks underflow the container is a **named follow-on** — mechanism: offset/space the track origins; listed here so it is a known, scoped capability, not a silent omission.)

### 2.4 `subgrid` — DE-SCOPED for v1 (feasible, deliberately not built)

`subgrid` is **feasible**: a child `FwGrid(subgridColumns: true)` placed spanning *k* parent columns would adopt the parent's *k* resolved column track lines instead of its own `columns`. **Mechanism:** `RenderFwGrid` exposes its resolved track offsets; a subgrid child reads the parent `RenderFwGrid` via `parent is RenderFwGrid` during layout and uses the slice of track lines covering its placement — a bespoke but bounded parent→child layout protocol.

**Decision (2026-06, explicit sign-off):** we do **not** build it for v1. Real-world `subgrid` usage is negligible and the protocol's cost is disproportionate to that demand (AGENTS.md §11b). This is recorded as a **documented `FwGrid` limitation** — a deliberate de-scope, *not* a framework limitation and *not* "impossible". The doc-comment on `FwGrid` and the engine-spec grid row state it plainly so a developer knows it is unavailable and why. Revisit only on concrete demand.

## 3. Compatibility & migration

- The M8 surface (`columns: [FwFr(), FwPx(200)]`, `columnGap`/`rowGap`, row-major auto-flow of span-1 items, partial-row padding, responsive `FwGridPatch`) is a **strict subset** — existing call sites and goldens keep working unchanged. The old hand-rolled `Row`/`Column` chunking is replaced by `RenderFwGrid`; the M8 grid golden must be re-reviewed (layout is equivalent for the span-1 case, but pixel rounding may differ — regenerate + eyeball).
- `FwGridTrack`/`FwFr`/`FwPx` stay; `FwAuto`/`FwMinMax`/`FwGridItem`/`FwGridAlign` are added to the barrel (§8).

## 4. Testing (production bar)

- **Unit (`RenderFwGrid`):** track sizing for every track type and mix (fr/px/auto/minmax), unbounded-width fr fallback, gap math, span clamping, sparse vs dense placement, explicit placement + collision with auto items, implicit-row growth, per-axis independence.
- **Widget:** `FwGridItem` span renders across the right cells; `stretch` vs `start/center/end` self-alignment; RTL mirrors column order and `start` alignment (executable geometry via `getRect`, not only goldens — per the test-audit lesson).
- **Golden:** a spanning + auto-placement + mixed-track scene, light/dark × LTR/RTL; a `minmax`/`auto` scene. Plus the regenerated M8 equivalence golden. (No subgrid golden — de-scoped, §2.4.)

## 5. Delivery sequence (each phase: impl + unit + golden + analyzer-clean, no stubs)

1. ✅ **Track model + `RenderFwGrid`** — `FwAuto`/`FwMinMax`, parent data, `FwGridItem`, widget→render wiring; **px/fr/auto** track sizing (replaces the M8 flex internals — goldens unchanged, i.e. pixel-parity for the M8 subset).
2. ✅ **Spanning + explicit placement + auto-placement (sparse + `dense`)** — the placement algorithm + multi-track intrinsic distribution.
3. ✅ **`minmax` + alignment (items/self)** — fr-with-floor clamp + cell alignment (`stretch`/`start`/`end`/`center`, RTL-aware inline).

**All three landed** (2026-06): one `RenderFwGrid` covering px/fr/auto/minmax tracks (both axes), spanning, explicit + sparse/dense auto-placement, item/self alignment, RTL, and the responsive `FwGridPatch` surface. Unit: `fw_grid_test` (geometry-based — 19 cases). Golden: `grid_slice` (spanning + px/fr/auto, light/dark × LTR/RTL) + the unchanged M8 `layout_slice`/`layout_responsive`.

**Not built (both honest, neither "impossible"):** `subgrid` — de-scoped (§2.4, AGENTS.md §11b); **content-distribution alignment** (`justify`/`align-content` for track underflow) — *not yet built* (mechanism: offset/space the track origins; rarely needed since `fr` absorbs spare space), recorded on the `FwGrid` doc-comment. Engine spec §6.6 + §12 grid row + AGENTS.md §11 updated (no-drift).

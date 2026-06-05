# flutterwindcss Module 4 — Spacing + Sizing Setters Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: `superpowers:test-driven-development`. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the typed `.tw` **base setters** for margin, fixed/min/max sizing, fractional sizing (+alignment), and aspect ratio to `FwStyleOps`. This is the module 4 row of the core-engine delivery table (spec §12).

**Why this module is thin (no new architecture).** Module 3 already landed *every* `FwStyle` field (margin, w/h/min/max, fractional, aspect), the resolution merge over them, and the §6.4 render-chain wrappers (`ConstrainedBox` sizing reconciliation, `FractionallySizedBox`, `AspectRatio`, outermost margin `Padding`). What was deferred to module 4 (spec §12 + m3 design §2) was **only the ergonomic typed setters** that write those fields. So there is **no separate design doc**: the design is the core engine spec §6.5 (utility surface) and §6.4 (render chain) — module 4 makes no new architecture decisions, it exposes existing capability. This plan records the setter contract + tests.

**Spec:** core engine design `docs/superpowers/specs/2026-06-05-flutterwindcss-core-engine-design.md` §6.4, §6.5, §12 (row 4); m3 module design §2 ("Deferred (later modules add setters + goldens only): `margin`, `w/h/min/max`, fractional, `square`/`aspect` (M4)").

---

## Setter contract

All spacing/sizing args are in **utility units** (`1 unit = 4 logical px`, `fwSpace`), matching padding (spec §6.5: "spacing args in utility units"). Tailwind's width/height scale *is* its spacing scale (`w-4` = `1rem` = 16 px = `fwSpace(4)`), so sizing reuses `fwSpace`. Directional throughout (AGENTS.md §3.3).

### Margin (per-edge merge; last-wins per edge — mirrors padding)
`m(units)` all sides · `mx` start+end · `my` top+bottom · `ms` start · `me` end · `mt` top · `mb` bottom. Uses an `EdgeInsetsDirectional` per-edge merge identical to `_mergePad`, so `.mx(4).my(2)` keeps both axes and `.mx(4).mx(2)` overwrites horizontal (last-wins).

### Fixed / min / max sizing (replacement; independent fields)
`w(units)` → `width` · `h(units)` → `height` · `minW/minH/maxW/maxH` → the matching `min*/max*` field. Each writes one field via `copyWith` (last-wins). The render chain's sizing reconciliation (spec §6.4 Finding #6: fixed wins its axis; `assert` on fixed+min/max same axis) already governs how these combine — module 4 adds no new reconciliation.

### Fractional / full (write the `*Factor` fields → `FractionallySizedBox`)
`wFraction(double f, {AlignmentDirectional? align})` → `widthFactor: f` (+ `factorAlignment` iff `align` given) · `hFraction(...)` → `heightFactor`. `wFull` / `hFull` are getters = `wFraction(1)` / `hFraction(1)` (Tailwind `w-full`/`h-full` = 100% of parent). `align` is the **only** way to control fractional alignment (spec §6.5); when omitted, resolution defaults `factorAlignment` to `AlignmentDirectional.centerStart`.

### Aspect (writes the single `aspectRatio` field)
`aspect(double ratio)` → `aspectRatio: ratio` · `square` (getter) = `aspect(1)`. Per spec §6.5, `square` is sugar for `aspectRatio: 1` (last-wins against `aspect` since same field); it does **not** set `width == height`.

> **No-arg utilities are getters** (`wFull`, `hFull`, `square`) — matches the spec writing them without parens (`wFull, hFull` vs `wFraction(f, {align})`) and reads naturally in a chain (`.tw.wFull`). This establishes the convention later no-arg utilities follow (`roundedFull`/`roundedNone`, M5).

---

## Task 1: Margin setters (TDD)

**Files:** modify `lib/src/style/fw_style_ops.dart`; test `test/style/fw_sizing_ops_test.dart` (margin group).

- [ ] **RED** — margin tests: `m` all edges; `ms/me/mt/mb` single edge; `mx`+`my` per-edge merge keeps both; `mx`+`mx` overwrites (last-wins); units are `fwSpace`. Run, watch fail.
- [ ] **GREEN** — add `_mergeMargin` + `m/mx/my/ms/me/mt/mb` to the mixin. Run, watch pass.

## Task 2: Sizing setters (TDD)

**Files:** modify `lib/src/style/fw_style_ops.dart`; same test file (sizing group).

- [ ] **RED** — sizing tests: `w/h/minW/minH/maxW/maxH` write the right field in `fwSpace`; `wFull`/`hFull` write `widthFactor`/`heightFactor` = 1.0; `wFraction(0.5)` writes factor, no alignment unless given; `wFraction(0.5, align:)` writes `factorAlignment`; `aspect(16/9)` writes `aspectRatio`; `square` writes `aspectRatio` 1 and last-wins against `aspect`. Run, watch fail.
- [ ] **GREEN** — add the sizing/fractional/aspect setters. Run, watch pass.

## Task 3: Golden — sizing/margin slice (LTR/RTL, light/dark)

**Files:** test `test/golden/sizing_slice_golden_test.dart`.

- [ ] Representative widget exercising margin (directional, so RTL mirrors) + a fixed/min box + bg, rendered light LTR and dark RTL. `matchesGoldenFile`. Local generation is **non-authoritative** (CI is the source of truth, spec §10) — record golden bytes but flag that CI re-verifies.

## Task 4: Analyze, full test, docs alignment (no-drift), commits

- [ ] `flutter analyze --fatal-infos --fatal-warnings` → `No issues found!`
- [ ] `flutter test` → all green.
- [ ] **No-drift doc sweep:** update the `FwStyleOps` header doc-comment ("Module 3 ships only padding + bg … Modules 4–9 extend" → reflect M4 landed spacing+sizing); mark spec §12 row 4 as landed; verify README module status line. Same commit(s) as code.
- [ ] Commit per task with `feat(style):` / `test(style):` / `docs:` messages.

**Definition of done:** all setters in §6.5's spacing/sizing group exist, typed, directional, `fwSpace`-based; unit + golden green; analyzer clean; docs aligned (no statement left describing M4 as unbuilt).

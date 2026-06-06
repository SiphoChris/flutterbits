# flutterwindcss Module 8 — Layout Widgets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. ALSO REQUIRED per task: `superpowers:test-driven-development`. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the six multi-child layout widgets the single-box `.tw` chain structurally cannot express — `FwRow`/`FwColumn`/`FwWrap`/`FwStack`/`FwPositioned`/`FwGrid` — as dedicated, directional, golden-tested widgets (spec §6.6, delivery table §12 row 8).

**Architecture:** Each is a thin, immutable `StatelessWidget` over a framework primitive (`Flex`/`Wrap`/`Stack`/`PositionedDirectional`), exposing Tailwind-shaped, directional, typed parameters. They produce one subtree, so any of them can be box-styled by chaining `.tw` (e.g. `FwColumn(...).tw.p(4).bg(c)`). `gap`/spacing use `Flex`/`Wrap`/`Row`/`Column` **native `spacing`** (the toolchain floor guarantees it — AGENTS.md §2). `FwGrid` uses a **sealed `FwGridTrack`** grammar (`FwFr`/`FwPx`) resolved with an exhaustive `switch` to `Expanded(flex:)` / `SizedBox(width:)`. `FwStack` consumes the z-index scale by stably sorting children by `FwPositioned.z`.

**Tech Stack:** Dart / Flutter widgets layer (`Flex`, `Wrap`, `Stack`, `PositionedDirectional`, `Expanded`, `SizedBox`), the M1 scalar scales (`fwSpace`, `fwZIndices`), `flutter_test` + the in-package pinned-font golden harness.

**Spec:** core engine design §6.0 (why layout is separate from `.tw`), §6.6 (the widgets), §4.6 (z-index scale), §3.3 (directional-by-default), §8 (barrel surface), §12 (row 8).

---

## Scope note (container queries already shipped — no-drift)

Spec §12 row 8 bundles "the `.containerSm…` query family on `.tw`" with the layout widgets. That family **already landed in module 3** — `containerSm…container2xl` are in `fw_style_ops.dart`, `FwContainerCondition` is in `fw_layer.dart`, and `FwStyled` already inserts the `LayoutBuilder` and threads `containerWidth` through `resolve`. So **this module is the six layout widgets only**. Task 6 corrects the §12 row-8 wording (the container family is M3, demonstrated, not re-built here).

## Design decisions (recorded; correct/extend the spec)

1. **`gap`/spacing render via native `spacing`, always (not interleaved `SizedBox`).** Spec §6.6 hedged "via `Flex`'s native `spacing` where available, else interleaved `SizedBox`." The AGENTS.md §2 toolchain floor (Flutter ≥ 3.29) **guarantees** `Flex`/`Row`/`Column`'s `spacing` parameter, so the `SizedBox` fallback is dead code we will not write. `Wrap` has always had `spacing`/`runSpacing`. Corrects §6.6 to "via native `spacing` (guaranteed by the toolchain floor)."

2. **`gap`, `FwWrap` spacing, `FwGrid` gaps, and `FwPositioned` inset are in utility units** (`fwSpace`, 1 unit = 4 px) — they are spacing concerns and Tailwind's `gap-*`/`inset-*` ride the spacing scale. **`FwPx` track size is logical px** (it is an explicit fixed-pixel track, spec §6.6 `[Px(200), Fr(1)]`). Documented on each parameter so the unit is never ambiguous.

3. **`FwGrid` track grammar is a sealed `FwGridTrack`** with two `final` subclasses `FwFr(int flex = 1)` and `FwPx(double size)`. Spec §6.6 wrote bare `Fr`/`Px`, which violate the AGENTS.md §4 `Fw`-prefix rule for public types. A **sealed** base (mirroring `FwCondition`) lets the cell builder `switch` exhaustively with no `default:` — the compiler catches a future track kind. `FwFr` asserts `flex > 0`; `FwPx` asserts `size >= 0`. Corrects §6.6/§8 (`Fr`/`Px` → `FwGridTrack`/`FwFr`/`FwPx`; add the three to the barrel list).

4. **`FwGrid` lays children row-major into equal-structure rows.** Children chunk into rows of `columns.length`; the last (partial) row is **padded with `SizedBox.shrink()` cells** so every column track keeps the same width across rows (spec §6.6 "equal-structure wrapping rows"). Rows are `Row`s (RTL-aware horizontal `Flex`) inside a `CrossAxisAlignment.stretch` `Column` so each row spans the full width and `fr` tracks resolve against it.

5. **`FwStack` z-ordering is a stable sort by `FwPositioned.z`.** Non-positioned children and `FwPositioned` without an explicit `z` default to `z = 0`. `List.sort` is not stable, so we sort `(index, child)` records with an index tiebreaker — equal-`z` children keep declaration order (spec §6.6). `FwStack` **materializes** each `FwPositioned` into a real `PositionedDirectional` (a `Stack` inspects its *direct* children's parent data, so a wrapper class would not be recognized as positioned).

6. **`FwPositioned` is a data-carrying widget that only `FwStack` interprets.** Its `build` throws a clear `FlutterError` ("must be a direct child of `FwStack`") — guarding the misuse rather than silently mis-rendering (AGENTS.md §3.9). `inset` is directional via `PositionedDirectional` (RTL-free, §3.3); `z` is honored only by `FwStack`'s sort.

7. **`mainAxisSize` defaults to `MainAxisSize.max`** on `FwRow`/`FwColumn` (Flutter's default; spec §6.6) — documented on the constructor so a web refugee expecting shrink-to-fit opts into `MainAxisSize.min` explicitly.

8. **Responsive layout-property layering is fully built (production — corrected from an initial "deferred" draft).** Spec §6.6 requires responsive layering on layout widgets ("a responsive `gap` … via the same layer engine"). Each widget takes optional `viewport`/`container` maps `Map<FwBreakpoint, Patch>`, where `Patch` is a per-widget bag of nullable fields (`FwFlexPatch`/`FwWrapPatch`/`FwGridPatch`/`FwStackPatch`/`FwPositionedPatch`). At build the widget folds matching patches onto its static base — mobile-first, largest breakpoint wins, container after viewport — reusing the box engine's `FwBreakpoint` min-width semantics and `FwStyled`'s conditional `MediaQuery`/`LayoutBuilder` insertion (a static widget inserts neither). Covers responsive `gap`/alignment, grid **column count**, and positioned **inset**. `z` is non-responsive by nature (paint order, not a per-breakpoint value). Shared plumbing in `layout/fw_responsive.dart`. **Static usage is unchanged** (scalar params); responsive is opt-in via the maps. (This supersedes an initial draft that deferred this — deferring a spec-required capability was wrong; see Task 7.)

---

## File structure

```
packages/flutterwindcss/lib/src/layout/      # NEW directory
  fw_responsive.dart # shared responsive plumbing (Task 7): width sourcing + patch folding
  fw_flex.dart      # FwRow, FwColumn (+ FwFlexPatch)
  fw_wrap.dart      # FwWrap (+ FwWrapPatch)
  fw_stack.dart     # FwStack, FwPositioned (+ FwStackPatch, FwPositionedPatch)
  fw_grid.dart      # FwGridTrack (sealed) + FwFr/FwPx, FwGrid (+ FwGridPatch)
packages/flutterwindcss/lib/flutterwindcss.dart   # add four exports
packages/flutterwindcss/test/style/
  fw_flex_test.dart     # + responsive cases
  fw_wrap_test.dart     # + responsive cases
  fw_stack_test.dart    # + responsive cases
  fw_grid_test.dart     # + responsive cases (incl. responsive column count)
packages/flutterwindcss/test/golden/
  layout_slice_golden_test.dart       # flex + stack + grid, light LTR + dark RTL
  layout_responsive_golden_test.dart  # same scene narrow vs wide (Task 7)
```

Split by responsibility (flex / wrap / stack / grid), each file small and focused — matching the per-concern layout of `lib/src/style/`.

---

## Task 1: `FwRow` / `FwColumn` (flex with typed gap)

**Files:**
- Create: `packages/flutterwindcss/lib/src/layout/fw_flex.dart`
- Modify: `packages/flutterwindcss/lib/flutterwindcss.dart`
- Test: `packages/flutterwindcss/test/style/fw_flex_test.dart`

- [ ] **Step 1 — Write the failing test** (`test/style/fw_flex_test.dart`):

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  group('FwRow', () {
    testWidgets('builds a horizontal Flex with native spacing from gap units', (t) async {
      await t.pumpWidget(_wrap(const FwRow(gap: 2, children: [SizedBox(), SizedBox()])));
      final flex = t.widget<Flex>(find.byType(Flex));
      expect(flex.direction, Axis.horizontal);
      expect(flex.spacing, 8.0); // gap 2 × 4px
      expect(flex.children.length, 2);
    });

    testWidgets('defaults: gap 0, mainAxisSize.max', (t) async {
      await t.pumpWidget(_wrap(const FwRow(children: [SizedBox()])));
      final flex = t.widget<Flex>(find.byType(Flex));
      expect(flex.spacing, 0.0);
      expect(flex.mainAxisSize, MainAxisSize.max);
    });

    testWidgets('passes through alignment + mainAxisSize', (t) async {
      await t.pumpWidget(
        _wrap(
          const FwRow(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [SizedBox()],
          ),
        ),
      );
      final flex = t.widget<Flex>(find.byType(Flex));
      expect(flex.mainAxisAlignment, MainAxisAlignment.spaceBetween);
      expect(flex.crossAxisAlignment, CrossAxisAlignment.end);
      expect(flex.mainAxisSize, MainAxisSize.min);
    });
  });

  group('FwColumn', () {
    testWidgets('builds a vertical Flex with native spacing', (t) async {
      await t.pumpWidget(_wrap(const FwColumn(gap: 3, children: [SizedBox()])));
      final flex = t.widget<Flex>(find.byType(Flex));
      expect(flex.direction, Axis.vertical);
      expect(flex.spacing, 12.0); // gap 3 × 4px
    });
  });

  testWidgets('a flex widget can itself be styled with .tw', (t) async {
    await t.pumpWidget(_wrap(const FwRow(children: [SizedBox()]).tw.p(2)));
    expect(find.byType(FwStyled), findsOneWidget);
    expect(find.byType(FwRow), findsOneWidget);
  });

  test('negative gap asserts', () {
    expect(() => FwRow(gap: -1, children: const []), throwsAssertionError);
  });
}
```

- [ ] **Step 2 — Run, watch fail.** `cd packages/flutterwindcss && flutter test test/style/fw_flex_test.dart` → FAIL (`FwRow`/`FwColumn` undefined).

- [ ] **Step 3 — Implement** (`lib/src/layout/fw_flex.dart`):

```dart
import 'package:flutter/widgets.dart';

import '../tokens/scales.dart';

/// A horizontal flex row with a typed [gap] (spec §6.6). Like Tailwind's
/// `flex flex-row gap-*`. Directional: children flow start→end, mirroring in RTL
/// (the underlying [Flex] honors [Directionality]).
///
/// [gap] is in **utility units** (1 unit = 4 logical px) and renders via the
/// framework's native [Flex.spacing] (guaranteed by the toolchain floor,
/// AGENTS.md §2). [mainAxisSize] defaults to [MainAxisSize.max] (Flutter's
/// default); pass [MainAxisSize.min] for shrink-to-fit. Style the row as a box by
/// chaining `.tw` (e.g. `FwRow(...).tw.p(4).bg(c)`).
class FwRow extends StatelessWidget {
  /// Creates a horizontal flex. [gap] must be `>= 0`.
  const FwRow({
    required this.children,
    this.gap = 0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    super.key,
  }) : assert(gap >= 0, 'flutterwindcss: gap must be >= 0 (got $gap).');

  /// The row's children, in start→end order.
  final List<Widget> children;

  /// Space between children, in utility units (× 4 logical px).
  final double gap;

  /// Alignment along the main (horizontal) axis.
  final MainAxisAlignment mainAxisAlignment;

  /// Alignment along the cross (vertical) axis.
  final CrossAxisAlignment crossAxisAlignment;

  /// Whether the row shrink-wraps its children ([MainAxisSize.min]) or fills the
  /// available main-axis extent ([MainAxisSize.max], the default).
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) => Flex(
    direction: Axis.horizontal,
    mainAxisAlignment: mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment,
    mainAxisSize: mainAxisSize,
    spacing: fwSpace(gap),
    children: children,
  );
}

/// A vertical flex column with a typed [gap] (spec §6.6). Like Tailwind's
/// `flex flex-col gap-*`. See [FwRow] for the [gap]/[mainAxisSize] semantics; the
/// cross axis here is horizontal, so [crossAxisAlignment] is RTL-aware.
class FwColumn extends StatelessWidget {
  /// Creates a vertical flex. [gap] must be `>= 0`.
  const FwColumn({
    required this.children,
    this.gap = 0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    super.key,
  }) : assert(gap >= 0, 'flutterwindcss: gap must be >= 0 (got $gap).');

  /// The column's children, in top→bottom order.
  final List<Widget> children;

  /// Space between children, in utility units (× 4 logical px).
  final double gap;

  /// Alignment along the main (vertical) axis.
  final MainAxisAlignment mainAxisAlignment;

  /// Alignment along the cross (horizontal) axis (RTL-aware).
  final CrossAxisAlignment crossAxisAlignment;

  /// Whether the column shrink-wraps ([MainAxisSize.min]) or fills the main-axis
  /// extent ([MainAxisSize.max], the default).
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) => Flex(
    direction: Axis.vertical,
    mainAxisAlignment: mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment,
    mainAxisSize: mainAxisSize,
    spacing: fwSpace(gap),
    children: children,
  );
}
```

- [ ] **Step 4 — Add the barrel export** (`lib/flutterwindcss.dart`, in the Module 3 styling block, alphabetical by path — insert before `fw_layer.dart`):

```dart
export 'src/layout/fw_flex.dart';
```

- [ ] **Step 5 — Run, watch pass.** `flutter test test/style/fw_flex_test.dart` → PASS.
- [ ] **Step 6 — Analyze.** `flutter analyze --fatal-infos --fatal-warnings` → `No issues found!`
- [ ] **Step 7 — Commit.** `feat(layout): FwRow/FwColumn — flex with typed gap (M8)`

---

## Task 2: `FwWrap` (wrapping flow with run/cross spacing)

**Files:**
- Create: `packages/flutterwindcss/lib/src/layout/fw_wrap.dart`
- Modify: `packages/flutterwindcss/lib/flutterwindcss.dart`
- Test: `packages/flutterwindcss/test/style/fw_wrap_test.dart`

- [ ] **Step 1 — Write the failing test** (`test/style/fw_wrap_test.dart`):

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  testWidgets('FwWrap maps gap/runGap units to Wrap spacing/runSpacing', (t) async {
    await t.pumpWidget(
      _wrap(const FwWrap(gap: 2, runGap: 3, children: [SizedBox(), SizedBox()])),
    );
    final w = t.widget<Wrap>(find.byType(Wrap));
    expect(w.spacing, 8.0); // gap 2 × 4
    expect(w.runSpacing, 12.0); // runGap 3 × 4
    expect(w.children.length, 2);
  });

  testWidgets('defaults: zero spacing, horizontal direction', (t) async {
    await t.pumpWidget(_wrap(const FwWrap(children: [SizedBox()])));
    final w = t.widget<Wrap>(find.byType(Wrap));
    expect(w.spacing, 0.0);
    expect(w.runSpacing, 0.0);
    expect(w.direction, Axis.horizontal);
  });

  testWidgets('passes through alignment', (t) async {
    await t.pumpWidget(
      _wrap(
        const FwWrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [SizedBox()],
        ),
      ),
    );
    final w = t.widget<Wrap>(find.byType(Wrap));
    expect(w.alignment, WrapAlignment.center);
    expect(w.runAlignment, WrapAlignment.spaceBetween);
    expect(w.crossAxisAlignment, WrapCrossAlignment.end);
  });

  test('negative gap / runGap assert', () {
    expect(() => FwWrap(gap: -1, children: const []), throwsAssertionError);
    expect(() => FwWrap(runGap: -1, children: const []), throwsAssertionError);
  });
}
```

- [ ] **Step 2 — Run, watch fail.** `flutter test test/style/fw_wrap_test.dart` → FAIL (`FwWrap` undefined).

- [ ] **Step 3 — Implement** (`lib/src/layout/fw_wrap.dart`):

```dart
import 'package:flutter/widgets.dart';

import '../tokens/scales.dart';

/// A wrapping flow layout (spec §6.6) — Tailwind's `flex flex-wrap gap-*`.
/// Children flow along the main axis and wrap onto new runs when they overflow.
/// Directional: horizontal flow honors [Directionality] (RTL flows end→start).
///
/// [gap] is the **between-children** spacing within a run; [runGap] is the
/// spacing **between runs** — both in utility units (× 4 logical px). Style the
/// whole flow as a box by chaining `.tw`.
class FwWrap extends StatelessWidget {
  /// Creates a wrapping flow. [gap] and [runGap] must be `>= 0`.
  const FwWrap({
    required this.children,
    this.gap = 0,
    this.runGap = 0,
    this.direction = Axis.horizontal,
    this.alignment = WrapAlignment.start,
    this.runAlignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    super.key,
  }) : assert(gap >= 0, 'flutterwindcss: gap must be >= 0 (got $gap).'),
       assert(runGap >= 0, 'flutterwindcss: runGap must be >= 0 (got $runGap).');

  /// The children to flow.
  final List<Widget> children;

  /// Between-children spacing within a run, in utility units (× 4 logical px).
  final double gap;

  /// Between-runs spacing, in utility units (× 4 logical px).
  final double runGap;

  /// Main-axis flow direction (default horizontal).
  final Axis direction;

  /// Alignment of children within a run (main axis).
  final WrapAlignment alignment;

  /// Alignment of the runs within the cross axis.
  final WrapAlignment runAlignment;

  /// Alignment of children within a run on the cross axis.
  final WrapCrossAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) => Wrap(
    direction: direction,
    spacing: fwSpace(gap),
    runSpacing: fwSpace(runGap),
    alignment: alignment,
    runAlignment: runAlignment,
    crossAxisAlignment: crossAxisAlignment,
    children: children,
  );
}
```

- [ ] **Step 4 — Add the barrel export** (`lib/flutterwindcss.dart`, alphabetical — after `fw_flex.dart`, before `fw_layer.dart`):

```dart
export 'src/layout/fw_wrap.dart';
```

- [ ] **Step 5 — Run, watch pass.** `flutter test test/style/fw_wrap_test.dart` → PASS.
- [ ] **Step 6 — Analyze.** `flutter analyze --fatal-infos --fatal-warnings` → clean.
- [ ] **Step 7 — Commit.** `feat(layout): FwWrap — wrapping flow with run/cross spacing (M8)`

---

## Task 3: `FwStack` / `FwPositioned` (stacking context + z-index)

**Files:**
- Create: `packages/flutterwindcss/lib/src/layout/fw_stack.dart`
- Modify: `packages/flutterwindcss/lib/flutterwindcss.dart`
- Test: `packages/flutterwindcss/test/style/fw_stack_test.dart`

- [ ] **Step 1 — Write the failing test** (`test/style/fw_stack_test.dart`):

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  testWidgets('FwStack materializes FwPositioned into PositionedDirectional', (t) async {
    await t.pumpWidget(
      _wrap(
        FwStack(
          children: [
            const SizedBox(),
            FwPositioned(start: 2, top: 3, child: Container(key: const Key('p'))),
          ],
        ),
      ),
    );
    expect(find.byType(Stack), findsOneWidget);
    final pos = t.widget<PositionedDirectional>(find.byType(PositionedDirectional));
    expect(pos.start, 8.0); // inset 2 × 4px
    expect(pos.top, 12.0); // inset 3 × 4px
    expect(pos.end, isNull);
    expect(pos.bottom, isNull);
    // The FwPositioned wrapper itself is never built into the tree.
    expect(find.byType(FwPositioned), findsNothing);
  });

  testWidgets('children are stably sorted by z, then declaration order', (t) async {
    // Declared a(z10), b(z0), c(z10): paint order must be b, a, c.
    await t.pumpWidget(
      _wrap(
        FwStack(
          children: [
            FwPositioned(z: 10, child: Container(key: const Key('a'))),
            FwPositioned(z: 0, child: Container(key: const Key('b'))),
            FwPositioned(z: 10, child: Container(key: const Key('c'))),
          ],
        ),
      ),
    );
    final stack = t.widget<Stack>(find.byType(Stack));
    Key keyOf(Widget positioned) =>
        ((positioned as PositionedDirectional).child as Container).key!;
    expect(stack.children.map(keyOf).toList(), const [
      Key('b'),
      Key('a'),
      Key('c'),
    ]);
  });

  testWidgets('non-positioned children default to z 0 and keep their slot', (t) async {
    await t.pumpWidget(
      _wrap(
        FwStack(
          children: [
            FwPositioned(z: 20, child: Container(key: const Key('top'))),
            Container(key: const Key('base')),
          ],
        ),
      ),
    );
    final stack = t.widget<Stack>(find.byType(Stack));
    // base (z0) paints first, then top (z20).
    expect((stack.children.first as Container).key, const Key('base'));
    expect(
      ((stack.children.last as PositionedDirectional).child as Container).key,
      const Key('top'),
    );
  });

  testWidgets('a bare FwPositioned outside FwStack throws a clear error', (t) async {
    await t.pumpWidget(_wrap(FwPositioned(child: const SizedBox())));
    expect(t.takeException(), isA<FlutterError>());
  });

  test('negative inset asserts', () {
    expect(
      () => FwPositioned(start: -1, child: const SizedBox()),
      throwsAssertionError,
    );
  });
}
```

- [ ] **Step 2 — Run, watch fail.** `flutter test test/style/fw_stack_test.dart` → FAIL (`FwStack`/`FwPositioned` undefined).

- [ ] **Step 3 — Implement** (`lib/src/layout/fw_stack.dart`):

```dart
import 'package:flutter/widgets.dart';

import '../tokens/scales.dart';

/// A stacking context (spec §6.6) — Tailwind's `relative` container for absolute
/// children. Layers its [children] back-to-front. [FwPositioned] children are
/// placed by directional inset; plain children sit at [alignment].
///
/// **Paint order = z-index then declaration order.** Children carry an optional
/// `z` via [FwPositioned] (the §4.6 `fwZIndices` scale); plain children and
/// `FwPositioned` without a `z` default to `0`. Equal-`z` children keep
/// declaration order (the sort is stable). Style the stack as a box with `.tw`.
class FwStack extends StatelessWidget {
  /// Creates a stack. Children paint in ascending `z`, ties broken by order.
  const FwStack({
    required this.children,
    this.alignment = AlignmentDirectional.topStart,
    this.clipBehavior = Clip.hardEdge,
    super.key,
  });

  /// The stacked children (may include [FwPositioned] for absolute placement).
  final List<Widget> children;

  /// Where non-positioned children sit (directional; default top-start).
  final AlignmentDirectional alignment;

  /// How to clip children that overflow the stack (default [Clip.hardEdge]).
  final Clip clipBehavior;

  static int _zOf(Widget w) => w is FwPositioned ? w.z : 0;

  @override
  Widget build(BuildContext context) {
    // Decorate with the original index so the sort is stable (List.sort is not).
    final indexed = <(int, Widget)>[
      for (var i = 0; i < children.length; i++) (i, children[i]),
    ]..sort((a, b) {
      final byZ = _zOf(a.$2).compareTo(_zOf(b.$2));
      return byZ != 0 ? byZ : a.$1.compareTo(b.$1);
    });

    return Stack(
      alignment: alignment,
      clipBehavior: clipBehavior,
      children: [for (final (_, w) in indexed) _materialize(w)],
    );
  }

  // A Stack inspects its *direct* children's parent data, so an FwPositioned
  // wrapper would not be recognized — convert it to a real PositionedDirectional.
  Widget _materialize(Widget w) {
    if (w is! FwPositioned) return w;
    return PositionedDirectional(
      start: w.start == null ? null : fwSpace(w.start!),
      end: w.end == null ? null : fwSpace(w.end!),
      top: w.top == null ? null : fwSpace(w.top!),
      bottom: w.bottom == null ? null : fwSpace(w.bottom!),
      child: w.child,
    );
  }
}

/// Absolute placement inside an [FwStack] (spec §6.6) — Tailwind's `absolute`
/// with directional `inset-*` and a `z-*` paint order.
///
/// `inset` values ([start]/[end]/[top]/[bottom]) are in **utility units**
/// (× 4 logical px) and directional (RTL-aware via [PositionedDirectional]); a
/// `null` edge is unconstrained. [z] orders painting within the stack (the §4.6
/// `fwZIndices` scale: `0,10,20,30,40,50`); it is honored **only** by [FwStack].
///
/// This is a data-carrying widget: [FwStack] reads its fields and builds the real
/// positioned child. Used anywhere else it throws (a positioned child has no
/// meaning without a stacking parent).
class FwPositioned extends StatelessWidget {
  /// Creates a positioned child. Each non-null inset must be `>= 0`.
  const FwPositioned({
    required this.child,
    this.start,
    this.end,
    this.top,
    this.bottom,
    this.z = 0,
    super.key,
  }) : assert(start == null || start >= 0, 'flutterwindcss: inset must be >= 0 (start=$start).'),
       assert(end == null || end >= 0, 'flutterwindcss: inset must be >= 0 (end=$end).'),
       assert(top == null || top >= 0, 'flutterwindcss: inset must be >= 0 (top=$top).'),
       assert(bottom == null || bottom >= 0, 'flutterwindcss: inset must be >= 0 (bottom=$bottom).');

  /// The positioned content.
  final Widget child;

  /// Inset from the start edge (RTL-aware), utility units; `null` = unconstrained.
  final double? start;

  /// Inset from the end edge (RTL-aware), utility units; `null` = unconstrained.
  final double? end;

  /// Inset from the top edge, utility units; `null` = unconstrained.
  final double? top;

  /// Inset from the bottom edge, utility units; `null` = unconstrained.
  final double? bottom;

  /// Paint order within the [FwStack] (§4.6 scale); higher paints on top.
  final int z;

  @override
  Widget build(BuildContext context) => throw FlutterError(
    'FwPositioned must be a direct child of FwStack — it carries inset/z data '
    'that only FwStack interprets.',
  );
}
```

- [ ] **Step 4 — Add the barrel export** (`lib/flutterwindcss.dart`, alphabetical — after `fw_layer.dart`, before `fw_style.dart`):

```dart
export 'src/layout/fw_stack.dart';
```

- [ ] **Step 5 — Run, watch pass.** `flutter test test/style/fw_stack_test.dart` → PASS.
- [ ] **Step 6 — Analyze.** `flutter analyze --fatal-infos --fatal-warnings` → clean.
- [ ] **Step 7 — Commit.** `feat(layout): FwStack/FwPositioned — stacking context + z-index (M8)`

---

## Task 4: `FwGrid` + `FwGridTrack` (fr/px column tracks)

**Files:**
- Create: `packages/flutterwindcss/lib/src/layout/fw_grid.dart`
- Modify: `packages/flutterwindcss/lib/flutterwindcss.dart`
- Test: `packages/flutterwindcss/test/style/fw_grid_test.dart`

- [ ] **Step 1 — Write the failing test** (`test/style/fw_grid_test.dart`):

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  group('FwGridTrack', () {
    test('FwFr defaults to flex 1 and asserts > 0', () {
      expect(const FwFr().flex, 1);
      expect(const FwFr(2).flex, 2);
      expect(() => FwFr(0), throwsAssertionError);
    });

    test('FwPx carries a logical-px size and asserts >= 0', () {
      expect(const FwPx(200).size, 200.0);
      expect(() => FwPx(-1), throwsAssertionError);
    });
  });

  testWidgets('fr tracks become Expanded(flex:), px tracks become SizedBox(width:)', (t) async {
    await t.pumpWidget(
      _wrap(
        const FwGrid(
          columns: [FwPx(200), FwFr(2)],
          children: [SizedBox(), SizedBox()],
        ),
      ),
    );
    final row = t.widget<Row>(find.byType(Row));
    expect(row.children.length, 2);
    final fixed = row.children[0] as SizedBox;
    expect(fixed.width, 200.0);
    final flexible = row.children[1] as Expanded;
    expect(flexible.flex, 2);
  });

  testWidgets('children chunk row-major into rows of columns.length', (t) async {
    await t.pumpWidget(
      _wrap(
        const FwGrid(
          columns: [FwFr(), FwFr()],
          children: [SizedBox(), SizedBox(), SizedBox()], // 3 → 2 rows
        ),
      ),
    );
    expect(find.byType(Row), findsNWidgets(2));
  });

  testWidgets('a partial last row is padded to full track structure', (t) async {
    await t.pumpWidget(
      _wrap(
        const FwGrid(
          columns: [FwFr(), FwFr()],
          children: [SizedBox(), SizedBox(), SizedBox()],
        ),
      ),
    );
    final rows = t.widgetList<Row>(find.byType(Row)).toList();
    // Every row keeps both tracks so columns line up across rows.
    expect(rows[0].children.length, 2);
    expect(rows[1].children.length, 2);
  });

  testWidgets('column/row gaps map utility units to native spacing', (t) async {
    await t.pumpWidget(
      _wrap(
        const FwGrid(
          columns: [FwFr(), FwFr()],
          columnGap: 2,
          rowGap: 3,
          children: [SizedBox(), SizedBox(), SizedBox(), SizedBox()],
        ),
      ),
    );
    final outer = t.widget<Column>(find.byType(Column));
    expect(outer.spacing, 12.0); // rowGap 3 × 4
    final row = t.widget<Row>(find.byType(Row).first);
    expect(row.spacing, 8.0); // columnGap 2 × 4
  });

  test('empty columns asserts', () {
    expect(() => FwGrid(columns: const [], children: const []), throwsAssertionError);
  });
}
```

- [ ] **Step 2 — Run, watch fail.** `flutter test test/style/fw_grid_test.dart` → FAIL (`FwGrid`/`FwFr`/`FwPx` undefined).

- [ ] **Step 3 — Implement** (`lib/src/layout/fw_grid.dart`):

```dart
import 'package:flutter/widgets.dart';

import '../tokens/scales.dart';

/// A single column track for [FwGrid] (spec §6.6). Sealed so the cell builder can
/// `switch` exhaustively — a new track kind is a compile error, not a silent
/// fallthrough. The v1 grammar is two kinds: flexible [FwFr] and fixed [FwPx].
sealed class FwGridTrack {
  /// Const base constructor.
  const FwGridTrack();
}

/// A flexible (`fr`) track that takes a share of the leftover width proportional
/// to [flex] (Tailwind/CSS `1fr`, `2fr`, …). Renders as an [Expanded].
final class FwFr extends FwGridTrack {
  /// Creates an `fr` track with the given [flex] weight (must be `> 0`).
  const FwFr([this.flex = 1]) : assert(flex > 0, 'flutterwindcss: fr flex must be > 0 (got $flex).');

  /// The flex weight (CSS `Nfr`).
  final int flex;
}

/// A fixed-width track of [size] **logical pixels** (CSS `200px`). Renders as a
/// [SizedBox] of that width.
final class FwPx extends FwGridTrack {
  /// Creates a fixed-px track of [size] logical pixels (must be `>= 0`).
  const FwPx(this.size) : assert(size >= 0, 'flutterwindcss: px track size must be >= 0 (got $size).');

  /// The track width in logical pixels.
  final double size;
}

/// A simple CSS-grid helper (spec §6.6, AGENTS.md §11) — a single set of column
/// [columns] tracks (mixing [FwFr]/[FwPx]) with [children] laid **row-major** and
/// wrapped into equal-structure rows. Tailwind's `grid grid-cols-* gap-*`.
///
/// `columnGap`/`rowGap` are in **utility units** (× 4 logical px). Directional:
/// each row is an RTL-aware horizontal flex. A partial final row is padded with
/// empty cells so every column track lines up across rows.
///
/// **Out of scope (Non-Goals, AGENTS.md §11):** cell/row spanning,
/// auto-placement, and `subgrid` — they require a custom `RenderObject`. "Ships
/// complete" means complete for this fr/px column grammar.
class FwGrid extends StatelessWidget {
  /// Creates a grid. [columns] must be non-empty; gaps must be `>= 0`.
  const FwGrid({
    required this.columns,
    required this.children,
    this.columnGap = 0,
    this.rowGap = 0,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    super.key,
  }) : assert(columns.length > 0, 'flutterwindcss: FwGrid needs at least one column track.'),
       assert(columnGap >= 0, 'flutterwindcss: columnGap must be >= 0 (got $columnGap).'),
       assert(rowGap >= 0, 'flutterwindcss: rowGap must be >= 0 (got $rowGap).');

  /// The column tracks, applied left→right (start→end) to each row.
  final List<FwGridTrack> columns;

  /// The grid items, placed row-major across [columns].
  final List<Widget> children;

  /// Between-column spacing, in utility units (× 4 logical px).
  final double columnGap;

  /// Between-row spacing, in utility units (× 4 logical px).
  final double rowGap;

  /// Cross-axis (vertical) alignment of cells within a row.
  final CrossAxisAlignment crossAxisAlignment;

  Widget _cell(FwGridTrack track, Widget child) => switch (track) {
    FwFr(:final flex) => Expanded(flex: flex, child: child),
    FwPx(:final size) => SizedBox(width: size, child: child),
  };

  @override
  Widget build(BuildContext context) {
    final cols = columns.length;
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += cols) {
      rows.add(
        Row(
          crossAxisAlignment: crossAxisAlignment,
          spacing: fwSpace(columnGap),
          children: [
            for (var c = 0; c < cols; c++)
              _cell(
                columns[c],
                start + c < children.length ? children[start + c] : const SizedBox.shrink(),
              ),
          ],
        ),
      );
    }
    // Stretch so each row spans the full width and fr tracks resolve against it.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: fwSpace(rowGap),
      children: rows,
    );
  }
}
```

- [ ] **Step 4 — Add the barrel export** (`lib/flutterwindcss.dart`, alphabetical — after `fw_flex.dart`/before `fw_layer.dart` ordering; place `fw_grid.dart` after `fw_flex.dart`):

```dart
export 'src/layout/fw_grid.dart';
```

  Final Module-3-block export order (alphabetical by path) becomes: `fw_border_spec.dart`, `fw_flex.dart`, `fw_grid.dart`, `fw_layer.dart`, `fw_stack.dart`, `fw_style.dart`, `fw_style_ops.dart`, `fw_styled.dart`, `fw_wrap.dart`. Re-order the inserted lines to match.

- [ ] **Step 5 — Run, watch pass.** `flutter test test/style/fw_grid_test.dart` → PASS.
- [ ] **Step 6 — Analyze.** `flutter analyze --fatal-infos --fatal-warnings` → clean (verifies the exhaustive `switch` needs no `default:`).
- [ ] **Step 7 — Commit.** `feat(layout): FwGrid + FwGridTrack (fr/px tracks) (M8)`

---

## Task 5: Golden slice — layout (flex + stack + grid, LTR + RTL)

**Files:**
- Create: `packages/flutterwindcss/test/golden/layout_slice_golden_test.dart`

- [ ] **Step 1 — Write the golden test.** Three small layouts, each proving directionality (row order, positioned inset, grid order all mirror in RTL); light LTR + dark RTL:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Golden slice for the module 8 layout widgets. Each frame proves directional
// layout: FwRow children flow start→end (mirroring in RTL), FwPositioned inset is
// directional, and FwGrid lays out row-major start→end. Local generation is
// non-authoritative; CI (Linux, pinned font) is the source of truth (spec §10).
Widget _frame(FwTokens tokens, TextDirection dir, Widget child) => FwTheme(
  tokens: tokens,
  child: Directionality(
    textDirection: dir,
    child: MediaQuery(
      data: const MediaQueryData(size: Size(220, 160)),
      child: ColoredBox(color: tokens.colors.background, child: Center(child: child)),
    ),
  ),
);

Widget _swatch(Color c, {double w = 10, double h = 8}) =>
    const SizedBox.shrink().tw.w(w).h(h).bg(c);

Widget _flex(BuildContext context) {
  final c = context.fw.colors;
  return FwRow(
    gap: 2,
    mainAxisSize: MainAxisSize.min,
    children: [_swatch(c.primary), _swatch(c.secondary), _swatch(c.accent)],
  );
}

Widget _stack(BuildContext context) {
  final c = context.fw.colors;
  return FwStack(
    children: [
      _swatch(c.muted, w: 24, h: 24),
      FwPositioned(start: 1, top: 1, z: 10, child: _swatch(c.primary, w: 8, h: 8)),
    ],
  );
}

Widget _grid(BuildContext context) {
  final c = context.fw.colors;
  return SizedBox(
    width: 120,
    child: FwGrid(
      columns: const [FwPx(40), FwFr()],
      columnGap: 1,
      rowGap: 1,
      children: [
        _swatch(c.primary, w: 40),
        _swatch(c.secondary),
        _swatch(c.accent, w: 40),
        _swatch(c.destructive),
      ],
    ),
  );
}

Widget _scene(BuildContext context) => FwColumn(
  gap: 3,
  mainAxisSize: MainAxisSize.min,
  children: [_flex(context), _stack(context), _grid(context)],
);

void main() {
  testWidgets('layout slice — light LTR (row/stack/grid flow start→end)', (t) async {
    await t.pumpWidget(
      _frame(FwTokens.light, TextDirection.ltr, Builder(builder: _scene)),
    );
    await expectLater(
      find.byType(FwColumn),
      matchesGoldenFile('goldens/layout_light_ltr.png'),
    );
  });

  testWidgets('layout slice — dark RTL (everything mirrors)', (t) async {
    await t.pumpWidget(
      _frame(FwTokens.dark, TextDirection.rtl, Builder(builder: _scene)),
    );
    await expectLater(
      find.byType(FwColumn),
      matchesGoldenFile('goldens/layout_dark_rtl.png'),
    );
  });
}
```

- [ ] **Step 2 — Generate the golden bytes (non-authoritative).** `flutter test --update-goldens test/golden/layout_slice_golden_test.dart`; confirm both PNGs written, and eyeball: LTR has the row swatches left→right, the positioned dot top-left, the 40px grid column on the left; RTL mirrors all three.
- [ ] **Step 3 — Run without updating, watch pass.** `flutter test test/golden/layout_slice_golden_test.dart` → PASS. CI (Linux) re-verifies (spec §10).
- [ ] **Step 4 — Commit.** `test(layout): golden slice — flex/stack/grid, light/dark, LTR/RTL (M8)`

---

## Task 6: Analyze, format, full suite, no-drift doc sweep

**Files:** Modify `lib/src/style/fw_style_ops.dart` (header note), the engine spec, README.

- [ ] **Step 1 — Format.** `dart format --line-length 100 .`
- [ ] **Step 2 — Analyze.** `flutter analyze --fatal-infos --fatal-warnings` → `No issues found!`
- [ ] **Step 3 — Full suite.** `flutter test` → all green.
- [ ] **Step 4 — No-drift doc sweep (same commit):**
  - **`fw_style_ops.dart` header (lines ~20-22):** record **M8 added the layout widgets** (`FwRow`/`FwColumn`/`FwWrap`/`FwStack`/`FwPositioned`/`FwGrid`) as dedicated widgets (not `.tw` setters); note the container-query family already shipped in M3; remaining: module 9 (transforms), 10 (animated theming).
  - **Engine spec §6.6:** (a) change "via `Flex`'s native `spacing` where available, else interleaved `SizedBox`" → "via native `spacing` (guaranteed by the toolchain floor)"; (b) replace bare `Fr`/`Px` with the sealed `FwGridTrack` + `FwFr`/`FwPx` grammar; (c) rewrite the closing "responsive layering applies to layout widgets too" paragraph to the **as-built** decision: v1 layout widgets take concrete values, box-level responsiveness via `.tw`, responsive *layout-property* layering deferred + documented (Design decision 8). Add a "corrected — module 8" note.
  - **Engine spec §8 (barrel surface):** add `FwGridTrack`/`FwFr`/`FwPx` to the exported layout types alongside the six widgets (the six were already listed).
  - **Engine spec §12 row 8:** mark **✅ landed**; restate as the six layout widgets; note the `.containerSm…` family was already delivered in M3 (the row-8 bundling was redundant), and list the as-built decisions (native spacing, `FwGridTrack` grammar, deferred responsive layout-property layering).
  - **README "✅ Shipped" list:** add a module 8 bullet (the six layout widgets, directional, gap via native spacing, `FwGrid` fr/px grammar); update the "🚧 Next on the roadmap" line to drop layout widgets + container queries (container queries already shipped) and leave transforms + animated theming.
- [ ] **Step 5 — Re-run analyze + test after doc edits** (`flutter analyze --fatal-infos --fatal-warnings` + `flutter test`) → clean + green.
- [ ] **Step 6 — Commit.** `docs: align spec/README + ops header to module 8 as-built`

---

## Task 7: Responsive layout-property layering (production — un-defers Design decision 8)

**Files:** Create `lib/src/layout/fw_responsive.dart`; modify `fw_flex.dart`/`fw_wrap.dart`/`fw_grid.dart`/`fw_stack.dart` (add `viewport`/`container` patch maps + a `*Patch` type each + resolution in `build`); extend the four unit tests with responsive cases; create `test/golden/layout_responsive_golden_test.dart`; update spec §6.6/§8/§12, README, ops header.

- [x] **Shared plumbing** (`fw_responsive.dart`): `fwBuildResponsive` (inserts a `MediaQuery` read for viewport, one `LayoutBuilder` for container, neither when static), `fwActivePatches` (yields matching patches sorted ascending by `FwBreakpoint.minWidth` — largest wins; viewport before container), `fwHasViewport`/`fwHasContainer`.
- [x] **Per-widget patch types** (nullable-field bags): `FwFlexPatch` (gap/alignments/mainAxisSize), `FwWrapPatch` (gap/runGap/alignments/direction), `FwGridPatch` (columns/gaps/crossAxisAlignment — responsive **column count**), `FwStackPatch` (alignment/clip), `FwPositionedPatch` (start/end/top/bottom inset). `z` is **not** responsive (structural paint order).
- [x] **Resolution in each `build`**: fold matching patches onto the static base values, last-wins per field; build the framework primitive with the resolved values. `FwStack` sources widths when it *or any positioned child* declares a responsive override, and resolves each child's inset.
- [x] **Static path untouched**: scalar params unchanged; a widget with no maps inserts no `MediaQuery`/`LayoutBuilder`.
- [x] **Tests**: each `fw_*_test.dart` gains responsive cases (breakpoint cross-over, largest-wins cascade, container-vs-viewport, "static inserts no LayoutBuilder"); `layout_responsive_golden_test` pumps one scene at narrow (<md) and wide (≥md) — gap widens, grid goes 1→3 columns.
- [x] **No-drift**: spec §6.6 responsive paragraph rewritten to as-built (not deferred), §8 lists the patch types, §12 row 8 marks responsive built; README + ops header updated.

---

## Definition of done

- `FwRow`/`FwColumn`/`FwWrap`/`FwStack`/`FwPositioned`/`FwGrid` (+ sealed `FwGridTrack`/`FwFr`/`FwPx`) exist, exported from the barrel, directional, typed, and guarded; each can be box-styled by chaining `.tw`.
- `gap`/spacing/grid gaps/inset use utility units; `FwPx` uses logical px; z-index via stable sort honoring `fwZIndices`; `FwGrid` exhaustive `switch` (no `default:`).
- Unit (`fw_flex_test`, `fw_wrap_test`, `fw_stack_test`, `fw_grid_test`) + golden (`layout_slice`, LTR/RTL × light/dark) green; `flutter analyze --fatal-infos --fatal-warnings` clean; `dart format` clean.
- No-drift: spec §6.6/§8/§12, README, ops header all match as-built; the native-spacing, `FwGridTrack`-naming, deferred-responsive-layout, and container-queries-already-in-M3 corrections recorded.

## Self-review (spec coverage)

- §6.6 `FwRow`/`FwColumn` (gap, alignment, `mainAxisSize.max`) → Task 1. ✅
- §6.6 `FwWrap` (run/cross spacing + alignment) → Task 2. ✅
- §6.6 `FwStack`/`FwPositioned` (directional inset, z paint order, §4.6 scale) → Task 3. ✅
- §6.6 `FwGrid` (fr/px column tracks, gap, wrapping rows; spanning/auto-placement Non-Goals) → Task 4. ✅
- §6.0/§6.6 each layout widget is `.tw`-stylable → Task 1 Step 1 (last test) + golden swatches. ✅
- §3.3 directional throughout (Flex/Wrap honor Directionality; `PositionedDirectional`; RTL grid) → Tasks 1-4 + golden RTL. ✅
- §8 barrel exports (six widgets + track types) → Tasks 1-4 Step 4 + Task 6. ✅
- §10 goldens (light/dark, LTR/RTL) → Task 5. ✅
- §12 row 8 + no-drift (incl. container-queries-already-M3 correction) → Task 6. ✅
- §6.6 "responsive layering on layout widgets" → Design decision 8 (deferred, documented) + Task 6 spec correction. ✅
```

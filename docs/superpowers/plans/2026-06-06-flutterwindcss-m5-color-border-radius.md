# flutterwindcss Module 5 — Color + Border + Radius + Gradient Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: `superpowers:test-driven-development`. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the typed `.tw` setters for **gradient**, **border** (directional, per-side, independent color/width axes), **radius** (directional + named + full), and **clip**, and land the deferred **content-clip radius deflation by border width** (engine spec §6.4 Finding #3). This is the module 5 row of the core-engine delivery table (spec §12).

**Architecture:** Module 3 already shipped the `FwStyle` fields (`gradient`, `borderRadius`, `clipBehavior`), the resolution merge, and the §6.4 render-chain wrappers (`DecoratedBox` surface, content `ClipRRect`). This module adds the ergonomic setters that write those fields, **replaces** the M3 placeholder `border` field (typed `BoxBorder?`, no setter) with a proper accumulating `FwBorderSpec` so per-side directional borders merge last-wins like padding, and finally wires the border width into the content clip's corner-radius deflation that M3 deferred (it was coupled to the border width this module introduces). No change to resolution precedence or the render-chain order.

**Tech Stack:** Dart / Flutter widgets layer (`package:flutter/painting.dart` border/radius primitives), `flutter_test` (+ in-package golden harness, CI-authoritative).

**Spec:** core engine design `docs/superpowers/specs/2026-06-05-flutterwindcss-core-engine-design.md` §6.1 (data model — border), §6.4 (render chain, Finding #3 + #5), §6.5 (utility surface — `bg`/`bgGradient`, `border*`, `rounded*`, `clip`), §12 (row 5); m3 design §7 (Finding #3 deferral → M5).

---

## Design decisions (recorded; correct/extend the spec where it was under-specified)

These resolve genuine gaps in the engine spec. Per AGENTS.md §12 ("fix a wrong spec with judgment"), they are recorded here and swept back into the engine spec in Task 8.

1. **Border representation — `FwBorderSpec`, not `BoxBorder`.** Spec §6.1 sketched the field as `border (BorderSideSpec? perSide)`. M3 shipped it as a bare `BoxBorder? border` placeholder with **no setter** (unusable). To support Tailwind's *independent* color and width axes (`.borderColor(c).borderWidth(2)` is order-independent) and **per-edge last-wins merge** (like padding's `_mergePad`), the accumulator must store the four edges separately. A `BoxBorder` cannot be cleanly decomposed/merged. So this module introduces a small value type `FwBorderSpec { BorderSide? start, end, top, bottom }` and **resolves it to a concrete `BoxBorder` at resolve time** (uniform → `Border`, per-side → `BorderDirectional`, per §6.4 Finding #5). `ResolvedStyle.border` stays `BoxBorder?` — the render chain is unchanged. Corrects the spec's working name `BorderSideSpec` → **`FwBorderSpec`** (it describes the whole four-edge border, not one side).

2. **Field rename `FwStyle.border` → `FwStyle.borderSpec`.** `FwStyle` mixes in `FwStyleOps`, so a setter method and a field cannot share the name `border` (Dart). The project's established convention keeps the *utility* name Tailwind-faithful and lets the *field* take the descriptive name (`bg`/`background`, `rounded`/`borderRadius`, `shadow`/`boxShadow`). Following it, the **utility wins** the name `.border(...)` (spec §6.5, web-dev muscle memory) and the **field** is renamed `border` → `borderSpec`. The rename is self-documenting (the field now holds an `FwBorderSpec`, not a `BoxBorder`) and **safe today**: `border` shipped in M3 as an unusable placeholder (no setter could write it) and there are no copy-paste components in the wild yet, so §8's "renaming requires a deprecation cycle" — which exists to protect pinned component code — does not bite. `ResolvedStyle.border` (a different class, no ops mixin) keeps its name.

3. **Border width and radius args are in *logical px*, not utility units.** Padding/margin/sizing use `fwSpace` (1 unit = 4 px) because they ride Tailwind's spacing scale. Borders ride Tailwind's *border-width* scale (`fwBorderWidths = [0,1,2,4,8]` px) and radii ride the radius tokens (`t.radii.md`, `FwRadiusScale.*`, all px). So `border(2)` = 2 logical px and `rounded(t.radii.lg)` takes a token value directly. Documented on every setter so a reader doesn't multiply by 4.

4. **`clip` lands here (spec §12 left it unassigned).** §6.5 lists `clip` in the utility surface but §12 never assigned it to a module. Its natural home is module 5: the content-clip radius **deflation** (Finding #3) is meaningless without a clip, and clip pairs conceptually with radius+border (the rounded-card story). So `clip([Clip behavior = Clip.antiAlias])` ships here. Recorded as a §12 assignment in Task 8.

5. **Deflation geometry.** The content clip reuses the decoration's `BorderRadiusDirectional`, deflating **each corner** by its two adjacent edge widths (CSS inner-border-radius math): `topStart` insets x by the start-edge width and y by the top-edge width, etc., clamped at 0. Edge widths are read directionally off the resolved `BoxBorder` (`BorderDirectional.start/end/top/bottom`, or `Border.left/right/top/bottom` mapped start←left/end←right for the uniform case — symmetric, so the mapping is exact). The clip **rect** is not inset (only the radius), matching Finding #3's wording ("reuses ... deflated by borderWidth") — the corner is where content actually bleeds across a stroke.

---

## Setter contract (all in `FwStyleOps`, shared by `FwStyle` + `FwStyled`)

### Gradient
`bgGradient(Gradient)` → writes the `gradient` field (last-wins). The render chain already prefers `gradient` over `background` when both are set (M3 `_decorate`).

### Border (per-edge merge; independent color & width)
- `border(double width, {Color? color})` — uniform: sets `width` (px) on all four edges, plus `color` if given. (Tailwind bare `border` = `border(1)`.)
- `borderWidth(double width)` — sets width on all four edges, **keeping** each edge's color.
- `borderColor(Color color)` — sets color on all four edges, **keeping** each edge's width.
- `borderS/E/T/B({double? width, Color? color})` — per-edge (directional `S`/`E` mirror under RTL); merges with the other edges (last-wins per edge).

Width controls visibility: an edge paints iff its width > 0. Color defaults to `BorderSide`'s opaque black until set (components pass `context.fw.colors.border`). `FwBorderSpec.resolve()` returns `null` when no edge would paint, so a color-only chain emits no `DecoratedBox` border.

### Radius (per-corner merge; directional)
- `rounded(double radius)` — every corner = `radius` px (overwrites all corners, last-wins).
- `roundedAll(double radius)` — explicit synonym of `rounded` (spec's named surface).
- `roundedT/B/S/E(double radius)` — per-edge pair, merges per-corner (`T`=topStart+topEnd, `B`=bottomStart+bottomEnd, `S`=topStart+bottomStart, `E`=topEnd+bottomEnd).
- `roundedNone` (getter) — all corners 0.
- `roundedFull` (getter) — all corners `Radius.circular(9999)` (pill).

### Clip
- `clip([Clip behavior = Clip.antiAlias])` — writes `clipBehavior`; the content clip uses the **deflated** radius (Finding #3).

> No-arg utilities are getters (`roundedNone`, `roundedFull`) — the convention M4 established (`wFull`/`square`).

---

## File structure

- **Create** `lib/src/style/fw_border_spec.dart` — the `FwBorderSpec` value type (+ `merge`, `resolve`, `==`/`hashCode`).
- **Modify** `lib/src/style/fw_style.dart` — rename field `border`→`borderSpec`, retype `BoxBorder?`→`FwBorderSpec?` (field, ctor, `copyWith`, `==`, `hashCode`, import).
- **Modify** `lib/src/style/resolve.dart` — `_overlay` param rename; projection `border: merged.borderSpec?.resolve()`.
- **Modify** `lib/src/style/fw_style_ops.dart` — add gradient/border/radius/clip setters (+ import `fw_border_spec.dart`).
- **Modify** `lib/src/style/resolved_style_build.dart` — deflate the content-clip radius by border width.
- **Modify** `lib/flutterwindcss.dart` — export `fw_border_spec.dart`.
- **Create** `test/style/fw_border_spec_test.dart`, `test/style/fw_color_ops_test.dart` (border/radius/gradient/clip setters), `test/golden/decoration_slice_golden_test.dart`.
- **Modify** `test/style/render_chain_test.dart` — assert the deflation.

---

## Task 1: `FwBorderSpec` value type (TDD)

**Files:** Create `lib/src/style/fw_border_spec.dart`; Create `test/style/fw_border_spec_test.dart`; Modify `lib/flutterwindcss.dart`.

- [ ] **Step 1 — Write the failing test** (`test/style/fw_border_spec_test.dart`):

```dart
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/fw_border_spec.dart';

void main() {
  test('empty / width-0 spec resolves to null (nothing paints)', () {
    expect(const FwBorderSpec().resolve(), isNull);
    expect(const FwBorderSpec(start: BorderSide(width: 0)).resolve(), isNull);
  });

  test('uniform spec resolves to a non-directional Border', () {
    const side = BorderSide(color: Color(0xFF112233), width: 2);
    final b = const FwBorderSpec(start: side, end: side, top: side, bottom: side).resolve();
    expect(b, isA<Border>());
    expect((b! as Border).top, side);
  });

  test('per-side spec resolves to a directional BorderDirectional', () {
    const thick = BorderSide(color: Color(0xFF112233), width: 4);
    const thin = BorderSide(color: Color(0xFF112233), width: 1);
    final b = const FwBorderSpec(start: thick, end: thin, top: thin, bottom: thin).resolve();
    expect(b, isA<BorderDirectional>());
    expect((b! as BorderDirectional).start, thick);
    expect((b as BorderDirectional).end, thin);
  });

  test('null edges resolve to BorderSide.none on the directional border', () {
    const top = BorderSide(width: 2);
    final b = const FwBorderSpec(top: top).resolve()! as BorderDirectional;
    expect(b.top, top);
    expect(b.start, BorderSide.none);
    expect(b.bottom, BorderSide.none);
  });

  test('merge replaces only the given edges (per-edge last-wins)', () {
    const a = BorderSide(width: 1);
    const c = BorderSide(width: 4);
    final merged = const FwBorderSpec(start: a, top: a).merge(start: c);
    expect(merged.start, c);
    expect(merged.top, a);
    expect(merged.end, isNull);
  });

  test('== / hashCode compare all four edges', () {
    const a = FwBorderSpec(start: BorderSide(width: 1));
    const b = FwBorderSpec(start: BorderSide(width: 1));
    const d = FwBorderSpec(start: BorderSide(width: 2));
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == d, isFalse);
  });
}
```

- [ ] **Step 2 — Run, watch fail.** `cd packages/flutterwindcss && flutter test test/style/fw_border_spec_test.dart` → FAIL (`fw_border_spec.dart` missing).

- [ ] **Step 3 — Implement** (`lib/src/style/fw_border_spec.dart`):

```dart
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';

/// An accumulating, directional border description (spec §6.1). Each edge is an
/// optional [BorderSide]; `null` means "no border declared on that edge". The
/// `.tw` border setters merge per-edge (last-wins per edge), mirroring how
/// padding accumulates, and [resolve] converts to a concrete [BoxBorder] for the
/// render chain.
///
/// Corrects the engine spec §6.1 working name `BorderSideSpec` — this type
/// describes the whole four-edge border, not a single side. An edge paints only
/// when its width is > 0, so a color-only chain stays invisible (matching
/// Tailwind, where `border-{color}` alone shows nothing without a width).
@immutable
class FwBorderSpec {
  /// Creates a border spec. Any omitted edge is unset (`null`).
  const FwBorderSpec({this.start, this.end, this.top, this.bottom});

  /// Start edge (RTL-aware).
  final BorderSide? start;

  /// End edge (RTL-aware).
  final BorderSide? end;

  /// Top edge.
  final BorderSide? top;

  /// Bottom edge.
  final BorderSide? bottom;

  /// Returns a copy with the given edges replaced (unset args keep the current
  /// edge) — the per-edge merge the setters use for last-wins-per-edge.
  FwBorderSpec merge({BorderSide? start, BorderSide? end, BorderSide? top, BorderSide? bottom}) =>
      FwBorderSpec(
        start: start ?? this.start,
        end: end ?? this.end,
        top: top ?? this.top,
        bottom: bottom ?? this.bottom,
      );

  bool get _paints =>
      (start?.width ?? 0) > 0 ||
      (end?.width ?? 0) > 0 ||
      (top?.width ?? 0) > 0 ||
      (bottom?.width ?? 0) > 0;

  /// Converts to a concrete [BoxBorder], or `null` when no edge paints. A uniform
  /// border (all four edges equal) becomes a direction-agnostic [Border]; any
  /// per-edge difference becomes a [BorderDirectional] so `start`/`end` mirror
  /// under RTL (spec §6.4 Finding #5).
  BoxBorder? resolve() {
    if (!_paints) return null;
    final s = start ?? BorderSide.none;
    final e = end ?? BorderSide.none;
    final t = top ?? BorderSide.none;
    final b = bottom ?? BorderSide.none;
    if (s == e && e == t && t == b) return Border.fromBorderSide(s);
    return BorderDirectional(start: s, end: e, top: t, bottom: b);
  }

  @override
  bool operator ==(Object other) =>
      other is FwBorderSpec &&
      start == other.start &&
      end == other.end &&
      top == other.top &&
      bottom == other.bottom;

  @override
  int get hashCode => Object.hash(start, end, top, bottom);
}
```

- [ ] **Step 4 — Export it** (`lib/flutterwindcss.dart`, keep alphabetical by path — before `fw_layer.dart`):

```dart
export 'src/style/fw_border_spec.dart';
export 'src/style/fw_layer.dart';
```

- [ ] **Step 5 — Run, watch pass.** `flutter test test/style/fw_border_spec_test.dart` → PASS.

- [ ] **Step 6 — Commit.** `feat(style): FwBorderSpec — accumulating directional border (M5)`

---

## Task 2: Migrate `FwStyle.border` → `borderSpec: FwBorderSpec?` (refactor, tests stay green)

**Files:** Modify `lib/src/style/fw_style.dart`, `lib/src/style/resolve.dart`. No behavior change (no test constructs `FwStyle(border: ...)` — verified by grep), so the existing suite must stay green.

- [ ] **Step 1 — Edit `fw_style.dart`:**
  - Add import: `import 'fw_border_spec.dart';`
  - In the constructor, rename `this.border` → `this.borderSpec`.
  - Replace the field declaration:

```dart
  /// Accumulating border description (uniform or per-side directional); resolves
  /// to a concrete `BoxBorder` at resolve time. Renamed from M3's `border`
  /// placeholder (spec §6.1; the field now holds an [FwBorderSpec], not a
  /// `BoxBorder`).
  final FwBorderSpec? borderSpec;
```

  - In `copyWith`: rename the param `BoxBorder? border` → `FwBorderSpec? borderSpec`, and the body line `border: border ?? this.border,` → `borderSpec: borderSpec ?? this.borderSpec,`.
  - In `operator ==`: `border == other.border` → `borderSpec == other.borderSpec`.
  - In `hashCode`: the `border,` entry → `borderSpec,`.
  - Remove the now-unused `BoxBorder` reference (the `package:flutter/painting.dart` import stays for `EdgeInsetsDirectional`/`BorderRadiusDirectional`/`Gradient`/`Color`).

- [ ] **Step 2 — Edit `resolve.dart`:**
  - In `_overlay`, rename the param/body `border: top.border` → `borderSpec: top.borderSpec`.
  - In the `ResolvedStyle(...)` projection, change `border: merged.border,` → `border: merged.borderSpec?.resolve(),` (FwBorderSpec → BoxBorder for the render chain; `ResolvedStyle.border` is unchanged `BoxBorder?`).

- [ ] **Step 3 — Run the whole suite, watch it stay green.** `flutter test` → all pass (pure refactor).

- [ ] **Step 4 — Analyze.** `flutter analyze --fatal-infos --fatal-warnings` → `No issues found!`

- [ ] **Step 5 — Commit.** `refactor(style): FwStyle.border → borderSpec (FwBorderSpec) (M5)`

---

## Task 3: Border setters (TDD)

**Files:** Modify `lib/src/style/fw_style_ops.dart`; Create `test/style/fw_color_ops_test.dart`.

- [ ] **Step 1 — Write the failing test** (`test/style/fw_color_ops_test.dart`, border group):

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/fw_border_spec.dart';
import 'package:flutterwindcss/src/style/fw_style.dart';

const _c = Color(0xFF112233);
const _d = Color(0xFF445566);

void main() {
  group('border', () {
    test('border(w) sets width on every edge; resolves to a uniform Border', () {
      final s = const FwStyle().border(2);
      final spec = s.borderSpec!;
      expect(spec.start!.width, 2);
      expect(spec.end!.width, 2);
      expect(spec.top!.width, 2);
      expect(spec.bottom!.width, 2);
      expect(spec.resolve(), isA<Border>());
    });

    test('border(w, color:) sets width + color on every edge', () {
      final spec = const FwStyle().border(2, color: _c).borderSpec!;
      expect(spec.top!.color, _c);
      expect(spec.top!.width, 2);
    });

    test('borderColor + borderWidth are order-independent (independent axes)', () {
      final a = const FwStyle().borderColor(_c).borderWidth(3).borderSpec!;
      final b = const FwStyle().borderWidth(3).borderColor(_c).borderSpec!;
      expect(a.top!.color, _c);
      expect(a.top!.width, 3);
      expect(b.top!.color, _c);
      expect(b.top!.width, 3);
    });

    test('borderS/E/T/B set one edge and merge with the others (last-wins)', () {
      final spec = const FwStyle().border(1, color: _c).borderS(width: 4, color: _d).borderSpec!;
      expect(spec.start!.width, 4);
      expect(spec.start!.color, _d);
      expect(spec.end!.width, 1); // untouched
      expect(spec.resolve(), isA<BorderDirectional>());
    });

    test('per-edge color only keeps the existing width', () {
      final spec = const FwStyle().borderWidth(2).borderT(color: _d).borderSpec!;
      expect(spec.top!.color, _d);
      expect(spec.top!.width, 2);
    });
  });
}
```

- [ ] **Step 2 — Run, watch fail.** `flutter test test/style/fw_color_ops_test.dart` → FAIL (no `border` method).

- [ ] **Step 3 — Implement in `fw_style_ops.dart`.** Add `import 'fw_border_spec.dart';` at the top, then insert this block after the `// ---- Background ----` section (after `bg`):

```dart
  // ---- Gradient ----

  /// Gradient background fill (replaces a solid [bg] when both are set; the
  /// render chain prefers the gradient). Last-wins.
  T bgGradient(Gradient gradient) => fwRebuild(fwStyle.copyWith(gradient: gradient));

  // ---- Border (per-edge merge; color & width are independent axes) ----
  //
  // Widths are in **logical px** (Tailwind's 0/1/2/4/8 `fwBorderWidths` scale),
  // NOT utility units — borders ride the border-width scale, not spacing. An edge
  // paints only when width > 0; color defaults to BorderSide's opaque black until
  // set (components pass `context.fw.colors.border`).

  FwBorderSpec get _borderSpec => fwStyle.borderSpec ?? const FwBorderSpec();

  BorderSide _withWidth(BorderSide? s, double width) =>
      (s ?? const BorderSide()).copyWith(width: width, style: BorderStyle.solid);

  BorderSide _withColor(BorderSide? s, Color color) =>
      (s ?? const BorderSide(width: 0)).copyWith(color: color, style: BorderStyle.solid);

  FwBorderSpec _borderEach(BorderSide Function(BorderSide?) f) {
    final b = _borderSpec;
    return FwBorderSpec(start: f(b.start), end: f(b.end), top: f(b.top), bottom: f(b.bottom));
  }

  BorderSide _edge(BorderSide? existing, double? width, Color? color) {
    var s = (existing ?? const BorderSide(width: 0)).copyWith(style: BorderStyle.solid);
    if (width != null) s = s.copyWith(width: width);
    if (color != null) s = s.copyWith(color: color);
    return s;
  }

  /// Uniform border of [width] logical px on every edge (plus [color] if given).
  /// Tailwind's bare `border` is `border(1)`.
  T border(double width, {Color? color}) => fwRebuild(
        fwStyle.copyWith(
          borderSpec: _borderEach((s) {
            var side = _withWidth(s, width);
            if (color != null) side = side.copyWith(color: color);
            return side;
          }),
        ),
      );

  /// Sets the border [width] (logical px) on every edge, keeping each edge color.
  T borderWidth(double width) =>
      fwRebuild(fwStyle.copyWith(borderSpec: _borderEach((s) => _withWidth(s, width))));

  /// Sets the border [color] on every edge, keeping each edge width.
  T borderColor(Color color) =>
      fwRebuild(fwStyle.copyWith(borderSpec: _borderEach((s) => _withColor(s, color))));

  /// Border on the start edge (RTL-aware); merges with the other edges.
  T borderS({double? width, Color? color}) => fwRebuild(
        fwStyle.copyWith(borderSpec: _borderSpec.merge(start: _edge(_borderSpec.start, width, color))),
      );

  /// Border on the end edge (RTL-aware); merges with the other edges.
  T borderE({double? width, Color? color}) => fwRebuild(
        fwStyle.copyWith(borderSpec: _borderSpec.merge(end: _edge(_borderSpec.end, width, color))),
      );

  /// Border on the top edge; merges with the other edges.
  T borderT({double? width, Color? color}) => fwRebuild(
        fwStyle.copyWith(borderSpec: _borderSpec.merge(top: _edge(_borderSpec.top, width, color))),
      );

  /// Border on the bottom edge; merges with the other edges.
  T borderB({double? width, Color? color}) => fwRebuild(
        fwStyle.copyWith(borderSpec: _borderSpec.merge(bottom: _edge(_borderSpec.bottom, width, color))),
      );
```

- [ ] **Step 4 — Run, watch pass.** `flutter test test/style/fw_color_ops_test.dart` → PASS.

- [ ] **Step 5 — Commit.** `feat(style): border + gradient setters (M5)`

---

## Task 4: Radius + clip setters (TDD)

**Files:** Modify `lib/src/style/fw_style_ops.dart`; same test file `test/style/fw_color_ops_test.dart` (radius + clip groups).

- [ ] **Step 1 — Add the failing tests** (append to `fw_color_ops_test.dart`'s `main`):

```dart
  group('radius', () {
    test('rounded sets every corner; last-wins on repeat', () {
      final r = const FwStyle().rounded(8).rounded(4).borderRadius!;
      expect(r.topStart, const Radius.circular(4));
      expect(r.bottomEnd, const Radius.circular(4));
    });

    test('roundedAll is a synonym of rounded', () {
      expect(const FwStyle().roundedAll(6).borderRadius, const FwStyle().rounded(6).borderRadius);
    });

    test('roundedT/B/S/E set their corner pair and merge per-corner', () {
      final r = const FwStyle().roundedT(8).roundedB(4).borderRadius!;
      expect(r.topStart, const Radius.circular(8));
      expect(r.topEnd, const Radius.circular(8));
      expect(r.bottomStart, const Radius.circular(4));
      expect(r.bottomEnd, const Radius.circular(4));
    });

    test('roundedS/E are directional (start/end corners)', () {
      final r = const FwStyle().roundedS(8).borderRadius!;
      expect(r.topStart, const Radius.circular(8));
      expect(r.bottomStart, const Radius.circular(8));
      expect(r.topEnd, Radius.zero);
    });

    test('roundedNone zeroes; roundedFull pills', () {
      expect(const FwStyle().rounded(8).roundedNone.borderRadius, BorderRadiusDirectional.zero);
      expect(const FwStyle().roundedFull.borderRadius!.topStart, const Radius.circular(9999));
    });
  });

  group('clip', () {
    test('clip() defaults to antiAlias; clip(x) writes the behavior', () {
      expect(const FwStyle().clip().clipBehavior, Clip.antiAlias);
      expect(const FwStyle().clip(Clip.hardEdge).clipBehavior, Clip.hardEdge);
    });
  });
```

- [ ] **Step 2 — Run, watch fail.** `flutter test test/style/fw_color_ops_test.dart` → FAIL (no `rounded`/`clip`).

- [ ] **Step 3 — Implement in `fw_style_ops.dart`** (insert after the border block, before `// ---- Variant layering ----`):

```dart
  // ---- Radius (per-corner merge; directional) ----
  //
  // Radius args are in **logical px** (token values like `t.radii.md`,
  // `FwRadiusScale.*`), NOT utility units.

  BorderRadiusDirectional _mergeRadius({
    Radius? topStart,
    Radius? topEnd,
    Radius? bottomStart,
    Radius? bottomEnd,
  }) {
    final r = fwStyle.borderRadius ?? BorderRadiusDirectional.zero;
    return BorderRadiusDirectional.only(
      topStart: topStart ?? r.topStart,
      topEnd: topEnd ?? r.topEnd,
      bottomStart: bottomStart ?? r.bottomStart,
      bottomEnd: bottomEnd ?? r.bottomEnd,
    );
  }

  /// Rounds every corner to [radius] logical px (overwrites all corners, last-wins).
  T rounded(double radius) =>
      fwRebuild(fwStyle.copyWith(borderRadius: BorderRadiusDirectional.all(Radius.circular(radius))));

  /// Explicit synonym of [rounded] (the spec's named `roundedAll` surface).
  T roundedAll(double radius) => rounded(radius);

  /// Rounds the top corners (topStart + topEnd); merges per-corner.
  T roundedT(double radius) => fwRebuild(
        fwStyle.copyWith(
          borderRadius: _mergeRadius(
            topStart: Radius.circular(radius),
            topEnd: Radius.circular(radius),
          ),
        ),
      );

  /// Rounds the bottom corners (bottomStart + bottomEnd); merges per-corner.
  T roundedB(double radius) => fwRebuild(
        fwStyle.copyWith(
          borderRadius: _mergeRadius(
            bottomStart: Radius.circular(radius),
            bottomEnd: Radius.circular(radius),
          ),
        ),
      );

  /// Rounds the start corners (topStart + bottomStart, RTL-aware); merges per-corner.
  T roundedS(double radius) => fwRebuild(
        fwStyle.copyWith(
          borderRadius: _mergeRadius(
            topStart: Radius.circular(radius),
            bottomStart: Radius.circular(radius),
          ),
        ),
      );

  /// Rounds the end corners (topEnd + bottomEnd, RTL-aware); merges per-corner.
  T roundedE(double radius) => fwRebuild(
        fwStyle.copyWith(
          borderRadius: _mergeRadius(
            topEnd: Radius.circular(radius),
            bottomEnd: Radius.circular(radius),
          ),
        ),
      );

  /// Removes all rounding (overwrites all corners).
  T get roundedNone => fwRebuild(fwStyle.copyWith(borderRadius: BorderRadiusDirectional.zero));

  /// Pill / fully-rounded corners (radius 9999).
  T get roundedFull => rounded(9999);

  // ---- Clip ----

  /// Clips overflowing content to the box shape; the content clip uses the
  /// border-radius **deflated by the border width** (spec §6.4 Finding #3).
  T clip([Clip behavior = Clip.antiAlias]) =>
      fwRebuild(fwStyle.copyWith(clipBehavior: behavior));
```

- [ ] **Step 4 — Run, watch pass.** `flutter test test/style/fw_color_ops_test.dart` → PASS.

- [ ] **Step 5 — Commit.** `feat(style): radius + clip setters (M5)`

---

## Task 5: Content-clip radius deflation by border width (Finding #3) (TDD)

**Files:** Modify `lib/src/style/resolved_style_build.dart`; Modify `test/style/render_chain_test.dart`.

- [ ] **Step 1 — Add the failing test** (append to `render_chain_test.dart`'s `main`):

```dart
  testWidgets('content clip radius is deflated by the border width (Finding #3)', (t) async {
    const r = 10.0;
    const w = 3.0;
    await _pump(
      t,
      ResolvedStyle(
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadiusDirectional.all(Radius.circular(r)),
        border: Border.all(width: w),
        background: const Color(0xFF112233),
      ),
    );
    // The content ClipRRect (inside the surface DecoratedBox) uses radius r - w.
    final clip = t.widget<ClipRRect>(find.byType(ClipRRect));
    final radius = clip.borderRadius as BorderRadiusDirectional;
    expect(radius.topStart, const Radius.circular(r - w));
  });

  testWidgets('content clip without a border uses the un-deflated radius', (t) async {
    await _pump(
      t,
      const ResolvedStyle(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadiusDirectional.all(Radius.circular(10)),
      ),
    );
    final clip = t.widget<ClipRRect>(find.byType(ClipRRect));
    final radius = clip.borderRadius as BorderRadiusDirectional;
    expect(radius.topStart, const Radius.circular(10));
  });
```

> Note: when both a backdrop blur and a content clip are present the tree has two `ClipRRect`s; these tests set no `backdropBlur`, so `find.byType(ClipRRect)` is unambiguous (one match).

- [ ] **Step 2 — Run, watch fail.** `flutter test test/style/render_chain_test.dart` → the deflation test FAILS (radius is still 10, not 7).

- [ ] **Step 3 — Implement in `resolved_style_build.dart`.** Replace the content-clip block:

```dart
    // Content clip, inset by border width, if clipping requested.
    if (clipBehavior != null && clipBehavior != Clip.none && borderRadius != null) {
      current = ClipRRect(clipBehavior: clipBehavior!, borderRadius: borderRadius!, child: current);
    }
```

with:

```dart
    // Content clip: reuse the decoration radius, deflated by the border width so
    // clipped content never bleeds across the stroke (spec §6.4 Finding #3).
    if (clipBehavior != null && clipBehavior != Clip.none && borderRadius != null) {
      final clipRadius =
          border == null ? borderRadius! : _deflateRadius(borderRadius!, border!);
      current = ClipRRect(clipBehavior: clipBehavior!, borderRadius: clipRadius, child: current);
    }
```

and add these private helpers inside the `ResolvedStyleBuild` extension (next to `_decorate`):

```dart
  /// Deflates each corner of [r] by its two adjacent edge widths (CSS inner
  /// border-radius), clamped at 0 — so the content clip hugs the inside of the
  /// stroke (spec §6.4 Finding #3).
  BorderRadiusDirectional _deflateRadius(BorderRadiusDirectional r, BoxBorder border) {
    final w = _edgeWidths(border);
    Radius inset(Radius c, double dx, double dy) {
      final x = c.x - dx, y = c.y - dy;
      return Radius.elliptical(x < 0 ? 0 : x, y < 0 ? 0 : y);
    }

    return BorderRadiusDirectional.only(
      topStart: inset(r.topStart, w.start, w.top),
      topEnd: inset(r.topEnd, w.end, w.top),
      bottomStart: inset(r.bottomStart, w.start, w.bottom),
      bottomEnd: inset(r.bottomEnd, w.end, w.bottom),
    );
  }

  /// Reads the per-edge stroke widths off a resolved [BoxBorder], directionally.
  /// A uniform `Border` is symmetric, so mapping start←left / end←right is exact.
  EdgeInsetsDirectional _edgeWidths(BoxBorder border) {
    if (border is BorderDirectional) {
      return EdgeInsetsDirectional.only(
        start: border.start.width,
        end: border.end.width,
        top: border.top.width,
        bottom: border.bottom.width,
      );
    }
    if (border is Border) {
      return EdgeInsetsDirectional.only(
        start: border.left.width,
        end: border.right.width,
        top: border.top.width,
        bottom: border.bottom.width,
      );
    }
    return EdgeInsetsDirectional.zero;
  }
```

- [ ] **Step 4 — Run, watch pass.** `flutter test test/style/render_chain_test.dart` → PASS (both new tests + existing).

- [ ] **Step 5 — Commit.** `feat(style): deflate content-clip radius by border width — Finding #3 (M5)`

---

## Task 6: Golden — decoration slice (LTR/RTL, light/dark)

**Files:** Create `test/golden/decoration_slice_golden_test.dart`.

- [ ] **Step 1 — Write the golden test.** A card-like box exercising gradient-vs-bg, a thicker **start** border (so RTL mirrors it), directional **start** rounding, and a content clip (so the deflation runs), using semantic tokens:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Golden slice for the module 5 color/border/radius setters. The box carries a
// semantic background, a thick **start** border + thin **end** border (so RTL
// mirrors them), start-corner rounding, and an antialias clip (exercising the
// Finding #3 radius deflation) — proving the typed decoration setters drive the
// directional render chain end-to-end. Local generation is non-authoritative;
// CI (Linux, pinned font) is the source of truth for these bytes (spec §10).
Widget _frame(FwTokens tokens, TextDirection dir, Widget child) => FwTheme(
  tokens: tokens,
  child: Directionality(
    textDirection: dir,
    child: MediaQuery(
      data: const MediaQueryData(size: Size(200, 140)),
      child: Center(child: child),
    ),
  ),
);

Widget _box(BuildContext context) {
  final c = context.fw.colors;
  return const SizedBox.shrink()
      .tw
      .w(28)
      .h(20)
      .bg(c.card)
      .borderS(width: 4, color: c.ring)
      .borderE(width: 1, color: c.border)
      .roundedS(context.fw.radii.lg)
      .clip();
}

void main() {
  testWidgets('decoration slice — light LTR', (t) async {
    await t.pumpWidget(_frame(FwTokens.light, TextDirection.ltr, Builder(builder: _box)));
    await expectLater(
      find.byType(FwStyled).first,
      matchesGoldenFile('goldens/decoration_light_ltr.png'),
    );
  });

  testWidgets('decoration slice — dark RTL (start border + start radius mirror)', (t) async {
    await t.pumpWidget(_frame(FwTokens.dark, TextDirection.rtl, Builder(builder: _box)));
    await expectLater(
      find.byType(FwStyled).first,
      matchesGoldenFile('goldens/decoration_dark_rtl.png'),
    );
  });
}
```

- [ ] **Step 2 — Generate the golden bytes locally (non-authoritative).** `flutter test --update-goldens test/golden/decoration_slice_golden_test.dart`. Confirm `test/golden/goldens/decoration_light_ltr.png` + `decoration_dark_rtl.png` are written, and eyeball them (thick start edge on the left in LTR, on the right in RTL).

- [ ] **Step 3 — Run without updating, watch pass.** `flutter test test/golden/decoration_slice_golden_test.dart` → PASS. Note in the commit body that **CI (Linux) re-verifies** these bytes (spec §10).

- [ ] **Step 4 — Commit.** `test(style): golden slice — decoration (border/radius/clip), light/dark, LTR/RTL (M5)`

---

## Task 7: Analyze, format, full test, no-drift doc sweep

**Files:** docs only (`fw_style_ops.dart` header doc-comment, engine spec §6.1/§6.4/§12, m3 design §7, README).

- [ ] **Step 1 — Format.** `dart format --line-length 100 .` → no changes (or only the new files).
- [ ] **Step 2 — Analyze.** `cd packages/flutterwindcss && flutter analyze --fatal-infos --fatal-warnings` → `No issues found!`
- [ ] **Step 3 — Full suite.** `flutter test` → all green.
- [ ] **Step 4 — No-drift doc sweep (same commit as the verification):**
  - **`fw_style_ops.dart` header doc-comment:** update the "Modules 5–9 extend this mixin" sentence to record that **M5 added color/border/radius/gradient/clip**; the remaining modules are 6 (typography), 7 (effects), 8 (layout), 9 (transforms).
  - **Engine spec §6.1:** change `border (BorderSideSpec? perSide)` → `borderSpec (FwBorderSpec? — four directional edges)`, and note it resolves to `BoxBorder` at resolve time; record the M3-placeholder rename.
  - **Engine spec §6.4 Finding #3:** flip the *Status* line from "deferred to M5 / emitted without deflation" to "**landed in M5** — content clip radius deflated by per-edge border width."
  - **Engine spec §6.5:** note radius/border-width args are logical px (not utility units); add `clip` as shipped in M5.
  - **Engine spec §12 row 5:** mark **✅ landed**; record that `clip` (unassigned in the original table) landed here because the deflation requires it; list the as-built setter names. Also tweak the row-3 "Deferred to M5 (Finding #3)" note to "landed M5".
  - **m3 design §7 deferrals:** mark the "Content-clip radius deflation by border width (Finding #3) → module 5" bullet as **done**.
  - **README "Shipped" list:** add a module 5 bullet (color/border/radius/gradient/clip + Finding #3 deflation) and drop color/border/radius/gradient from the "Next on the roadmap → Utility families" line.
- [ ] **Step 5 — Re-run analyze + test after doc edits** (doc-comment changes can affect analysis): `flutter analyze --fatal-infos --fatal-warnings && flutter test` → clean + green.
- [ ] **Step 6 — Commit.** `docs: align spec/README/plan + ops doc to module 5 as-built`

---

## Definition of done

- Every §6.5 color/border/radius/gradient/clip setter exists, typed, directional, with the documented px/unit semantics; `bgGradient` writes `gradient`; `border*` accumulate per-edge via `FwBorderSpec`; `rounded*` merge per-corner; `clip` writes `clipBehavior`.
- The deferred **Finding #3** content-clip radius deflation by border width is implemented and tested.
- Unit (`fw_border_spec_test`, `fw_color_ops_test`, updated `render_chain_test`) + golden (`decoration_slice`) green; `flutter analyze --fatal-infos --fatal-warnings` clean; `dart format` clean.
- No-drift: no spec/plan/README/doc-comment statement still describes M5 as unbuilt or Finding #3 as deferred; the `border`→`borderSpec` rename and `BorderSideSpec`→`FwBorderSpec` correction are recorded in the engine spec.
- Barrel exports `FwBorderSpec`.

---

## Self-review (spec coverage)

- §6.5 `bgGradient` → Task 3. ✅
- §6.5 `border, borderColor, borderWidth, borderS/E/T/B` → Task 3. ✅
- §6.5 `rounded, roundedT/B/S/E, roundedAll, roundedNone, roundedFull` → Task 4. ✅
- §6.5 `clip` → Task 4 (assignment recorded). ✅
- §6.4 Finding #3 (deflation, deferred from M3) → Task 5. ✅
- §6.4 Finding #5 (uniform `Border` vs per-side `BorderDirectional`) → Task 1 (`FwBorderSpec.resolve`). ✅
- §10 goldens (light/dark, LTR/RTL) → Task 6. ✅
- §12 row 5 + no-drift → Task 7. ✅
- `bg` (already M3), `shadow`/`opacity`/`blur`/`backdropBlur` (M7 per §12, not M5) — correctly out of scope; the m3 design §2's stray "`shadow()` (M5)" is superseded by the authoritative §12 (shadow = M7). Noted, not implemented here.

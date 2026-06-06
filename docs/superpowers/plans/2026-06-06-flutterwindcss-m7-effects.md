# flutterwindcss Module 7 — Effects Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: `superpowers:test-driven-development`. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the typed `.tw` effect setters — drop shadow (token scale), group opacity, content blur, and backdrop blur — over the render-chain wrappers M3 already built. This is the module 7 row of the core-engine delivery table (spec §12).

**Architecture:** Module 3 already landed the effect `FwStyle` fields, the resolution merge, and the §6.4 render-chain wrappers (`_ShadowBox` unclipped shadow, `Opacity`, `ImageFiltered` content blur, `ClipRRect`+`BackdropFilter` backdrop blur). This module adds only the typed setters that write those fields. The one structural change is a **field rename on `FwStyle`** (not `ResolvedStyle`) so the setters can take their Tailwind-natural names without colliding with the data-model fields.

**Tech Stack:** Dart / Flutter widgets layer (`BoxShadow`, `Opacity`, `ImageFiltered`, `BackdropFilter`), the M1 shadow token scale (`FwShadows` on `FwTokens.shadows`), `flutter_test` + in-package golden harness.

**Spec:** core engine design §4.4 (shadow tokens), §6.4 (render chain — Findings #1/#2/#11), §6.5 (utility surface), §12 (row 7).

---

## Design decisions (recorded; correct/extend the spec)

1. **Setter-vs-field collision resolved by renaming the `FwStyle` fields; `ResolvedStyle` is untouched.** `FwStyle` mixes in `FwStyleOps`, so a setter can't share a name with an `FwStyle` field. The Tailwind-natural setter names `opacity` and `blur` are exactly the M3 field names, and there is no clean alternative *setter* name (unlike M6's `text-{size}`→`textSize`). So — as in M5's `border`→`borderSpec` — the **fields** yield. The setters keep the perfect Tailwind names; the fields take accurate descriptive variants already used verbatim in the render-chain comments ("group opacity", "content blur"):

   | Concept | `FwStyle` field (renamed) | `ResolvedStyle` field (unchanged) | Setter |
   |---|---|---|---|
   | drop shadow | `boxShadow` (no collision) | `boxShadow` | `shadow(List<BoxShadow>)` |
   | group opacity | `opacity` → **`groupOpacity`** | `opacity` | `opacity(double)` |
   | content blur | `blur` → **`contentBlur`** | `blur` | `blur(double)` |
   | backdrop blur | `backdropBlur` → **`backdropBlurSigma`** | `backdropBlur` | `backdropBlur(double)` |

   Keeping `ResolvedStyle` (the internal resolved struct — not exported, no mixin, no collision) unchanged means **the render chain and the brittle `render_chain_test` are untouched**; the only blast radius is `FwStyle` (field decls/ctor/`copyWith`/`==`/`hashCode`) and the one field-by-field projection in `resolve.dart` (`opacity: merged.groupOpacity`, etc.). No existing test references these on `FwStyle` (verified by grep — all effect-field tests use `ResolvedStyle`). The FwStyle↔ResolvedStyle name mapping lives in the resolve projection and is documented there.

2. **`shadow` takes a resolved `List<BoxShadow>`, not an `FwShadow` enum.** Spec §6.5/§8 wrote `shadow(FwShadow)` and listed an `FwShadow` enum — but **no such enum exists** (the token is the `FwShadows` *scale class* on `FwTokens.shadows`, with steps `xs2…xl2`), and the ops layer has no `BuildContext` to resolve an enum against the active theme's scale. So `shadow` takes the already-resolved list the component reads from the theme — `shadow(context.fw.shadows.md)` — exactly mirroring how `bg(Color)`/`text(Color)`/`rounded(double)` take resolved token values, not selectors. This keeps shadows theme-aware (a custom theme's `shadows` flow through). Corrects §6.5 (`shadow(FwShadow)` → `shadow(List<BoxShadow>)`) and §8 (drop the phantom `FwShadow` enum; `FwShadows` is already exported).

3. **Guards (M5-audit principle).** `opacity` must be in `0.0..1.0` (assert); `blur`/`backdropBlur` sigmas must be `>= 0` (assert; `0` = no blur). `shadow` takes a list (an empty list = no shadow, handled by the render chain) — no guard.

4. **Backdrop blur is not golden-tested directly (needs a textured backdrop).** It is already covered by the M3 `render_chain_test` (`shadow emits an outer DecoratedBox even with a backdrop clip`) and a new unit test for the setter. The golden exercises the visible-on-a-flat-frame effects: drop shadow + group opacity (+ a content-blur variant). Documented so the coverage gap is explicit, not silent.

---

## Setter contract (all in `FwStyleOps`)

| Utility | `FwStyle` field | Arg | Notes |
|---|---|---|---|
| `shadow(List<BoxShadow>)` | `boxShadow` | token list (`context.fw.shadows.md`) | empty list = no shadow |
| `opacity(double)` | `groupOpacity` | `0.0..1.0` | asserts range; `fwOpacity(50)` helper available |
| `blur(double)` | `contentBlur` | sigma px `>= 0` | content blur (whole element) |
| `backdropBlur(double)` | `backdropBlurSigma` | sigma px `>= 0` | frosts content behind the box |

---

## File structure

- **Modify** `lib/src/style/fw_style.dart` — rename the three effect fields (decl, ctor, `copyWith`, `==`, `hashCode`).
- **Modify** `lib/src/style/resolve.dart` — `_overlay` (FwStyle→FwStyle, renamed) + the projection to `ResolvedStyle` (maps renamed FwStyle fields → unchanged ResolvedStyle fields).
- **Modify** `lib/src/style/fw_style_ops.dart` — add the effect setters (after the typography block, before variant layering).
- **Create** `test/style/fw_effect_ops_test.dart` — unit tests + guards.
- **Create** `test/golden/effects_slice_golden_test.dart` — shadow + opacity, light/dark.
- **Modify** engine spec §6.5/§8/§12, README, `fw_style_ops.dart` header (no-drift).

---

## Task 1: Rename `FwStyle` effect fields (refactor, tests stay green)

**Files:** Modify `lib/src/style/fw_style.dart`, `lib/src/style/resolve.dart`. No behavior change; no test touches these on `FwStyle` (verified).

- [ ] **Step 1 — Edit `fw_style.dart`:**
  - Field decls: `final double? opacity;` → `final double? groupOpacity;`; `final double? blur;` → `final double? contentBlur;`; `final double? backdropBlur;` → `final double? backdropBlurSigma;` (keep the doc-comments, updated to mention the setter that writes them).
  - Constructor: `this.opacity` → `this.groupOpacity`, `this.blur` → `this.contentBlur`, `this.backdropBlur` → `this.backdropBlurSigma`.
  - `copyWith`: rename the three params and their `?? this.` body lines identically.
  - `operator ==`: `opacity == other.opacity` → `groupOpacity == other.groupOpacity`, etc.
  - `hashCode`: rename the three entries.

- [ ] **Step 2 — Edit `resolve.dart`:**
  - In `_overlay` (FwStyle→FwStyle copy), rename `opacity: top.opacity` → `groupOpacity: top.groupOpacity`, `blur: top.blur` → `contentBlur: top.contentBlur`, `backdropBlur: top.backdropBlur` → `backdropBlurSigma: top.backdropBlurSigma`.
  - In the `ResolvedStyle(...)` projection, map the renamed fields to the **unchanged** `ResolvedStyle` names with a short comment:

```dart
      // FwStyle uses descriptive names (groupOpacity/contentBlur/backdropBlurSigma)
      // to free the .tw setter names; ResolvedStyle keeps the terse render-chain
      // names. This is the one place the two vocabularies meet.
      opacity: merged.groupOpacity,
      blur: merged.contentBlur,
      backdropBlur: merged.backdropBlurSigma,
```

- [ ] **Step 3 — Run the whole suite, watch it stay green.** `cd packages/flutterwindcss && flutter test` → all pass (pure refactor).
- [ ] **Step 4 — Analyze.** `flutter analyze --fatal-infos --fatal-warnings` → `No issues found!`
- [ ] **Step 5 — Commit.** `refactor(style): rename FwStyle effect fields to free the .tw setter names (M7)`

---

## Task 2: Effect setters (TDD)

**Files:** Modify `lib/src/style/fw_style_ops.dart`; Create `test/style/fw_effect_ops_test.dart`.

- [ ] **Step 1 — Write the failing test** (`test/style/fw_effect_ops_test.dart`):

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/fw_style.dart';
import 'package:flutterwindcss/src/tokens/scales.dart';
import 'package:flutterwindcss/src/tokens/shadows.dart';

void main() {
  group('effect setters', () {
    test('shadow writes the boxShadow list (last-wins)', () {
      final md = FwShadows.defaults.md;
      expect(const FwStyle().shadow(md).boxShadow, md);
      final lg = FwShadows.defaults.lg;
      expect(const FwStyle().shadow(md).shadow(lg).boxShadow, lg);
    });

    test('opacity writes groupOpacity (accepts fwOpacity helper)', () {
      expect(const FwStyle().opacity(0.5).groupOpacity, 0.5);
      expect(const FwStyle().opacity(fwOpacity(40)).groupOpacity, 0.4);
    });

    test('blur writes contentBlur; backdropBlur writes backdropBlurSigma', () {
      expect(const FwStyle().blur(8).contentBlur, 8);
      expect(const FwStyle().backdropBlur(12).backdropBlurSigma, 12);
    });
  });

  group('guards', () {
    test('opacity out of 0..1 asserts', () {
      expect(() => const FwStyle().opacity(-0.1), throwsAssertionError);
      expect(() => const FwStyle().opacity(1.1), throwsAssertionError);
    });

    test('negative blur / backdropBlur asserts', () {
      expect(() => const FwStyle().blur(-1), throwsAssertionError);
      expect(() => const FwStyle().backdropBlur(-1), throwsAssertionError);
    });

    test('opacity 0 and 1 and zero blur are allowed', () {
      expect(const FwStyle().opacity(0).groupOpacity, 0);
      expect(const FwStyle().opacity(1).groupOpacity, 1);
      expect(const FwStyle().blur(0).contentBlur, 0);
    });
  });
}
```

- [ ] **Step 2 — Run, watch fail.** `flutter test test/style/fw_effect_ops_test.dart` → FAIL (no `shadow`/`opacity`/… methods).

- [ ] **Step 3 — Implement in `fw_style_ops.dart`** (insert after the typography block's `lineThrough`, before `// ---- Variant layering ----`):

```dart
  // ---- Effects ----
  //
  // The FwStyle fields are named groupOpacity/contentBlur/backdropBlurSigma so
  // these Tailwind-natural setters don't collide (the field names also match the
  // render-chain's "group opacity" / "content blur" terminology). Blur args are
  // Gaussian sigmas in logical px.

  /// Drop shadow from the theme scale; pass a resolved list like
  /// `context.fw.shadows.md` (an empty list = no shadow). Last-wins.
  T shadow(List<BoxShadow> shadows) => fwRebuild(fwStyle.copyWith(boxShadow: shadows));

  /// Group opacity `0.0..1.0` (Tailwind `opacity-*`); `fwOpacity(50)` maps the
  /// `0..100` scale. Applies to the whole box as one layer.
  T opacity(double value) {
    assert(value >= 0.0 && value <= 1.0, 'flutterwindcss: opacity must be 0.0..1.0 (got $value).');
    return fwRebuild(fwStyle.copyWith(groupOpacity: value));
  }

  /// Content blur — Gaussian sigma in logical px, blurs the whole element
  /// (Tailwind `blur-*`; `FwBlur.md.sigma` for the named scale). Must be `>= 0`.
  T blur(double sigma) {
    assert(sigma >= 0, 'flutterwindcss: blur sigma must be >= 0 (got $sigma).');
    return fwRebuild(fwStyle.copyWith(contentBlur: sigma));
  }

  /// Backdrop blur — frosts content painted *behind* the box (Tailwind
  /// `backdrop-blur-*`). Gaussian sigma in logical px; must be `>= 0`.
  T backdropBlur(double sigma) {
    assert(sigma >= 0, 'flutterwindcss: backdrop blur sigma must be >= 0 (got $sigma).');
    return fwRebuild(fwStyle.copyWith(backdropBlurSigma: sigma));
  }
```

- [ ] **Step 4 — Run, watch pass.** `flutter test test/style/fw_effect_ops_test.dart` → PASS.
- [ ] **Step 5 — Commit.** `feat(style): effect setters — shadow/opacity/blur/backdropBlur (M7)`

---

## Task 3: Golden — effects slice (shadow + opacity, light/dark)

**Files:** Create `test/golden/effects_slice_golden_test.dart`.

- [ ] **Step 1 — Write the golden test.** A rounded card with a theme drop shadow and group opacity, on a contrasting frame so both read; light LTR + dark RTL (effects aren't directional, but the pair keeps harness symmetry and covers both themes):

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Golden slice for the module 7 effects. A rounded card carries a theme drop
// shadow (FwShadows scale) and group opacity, over the app background so the
// shadow and translucency both read. Backdrop blur needs a textured backdrop and
// is covered by render_chain_test instead (noted in the plan). Local generation
// is non-authoritative; CI (Linux) is the source of truth (spec §10).
Widget _frame(FwTokens tokens, TextDirection dir, Widget child) => FwTheme(
  tokens: tokens,
  child: Directionality(
    textDirection: dir,
    child: MediaQuery(
      data: const MediaQueryData(size: Size(200, 140)),
      child: ColoredBox(color: tokens.colors.background, child: Center(child: child)),
    ),
  ),
);

Widget _card(BuildContext context) {
  final c = context.fw.colors;
  return const SizedBox.shrink()
      .tw
      .w(28)
      .h(18)
      .bg(c.card)
      .rounded(context.fw.radii.lg)
      .shadow(context.fw.shadows.lg)
      .opacity(0.9);
}

void main() {
  testWidgets('effects slice — light LTR (shadow + opacity)', (t) async {
    await t.pumpWidget(_frame(FwTokens.light, TextDirection.ltr, const Builder(builder: _card)));
    await expectLater(
      find.byType(FwStyled).first,
      matchesGoldenFile('goldens/effects_light_ltr.png'),
    );
  });

  testWidgets('effects slice — dark RTL (shadow + opacity)', (t) async {
    await t.pumpWidget(_frame(FwTokens.dark, TextDirection.rtl, const Builder(builder: _card)));
    await expectLater(
      find.byType(FwStyled).first,
      matchesGoldenFile('goldens/effects_dark_rtl.png'),
    );
  });
}
```

- [ ] **Step 2 — Generate the golden bytes (non-authoritative).** `flutter test --update-goldens test/golden/effects_slice_golden_test.dart`; confirm both PNGs written and eyeball (soft shadow under a slightly-translucent rounded card, light vs dark).
- [ ] **Step 3 — Run without updating, watch pass.** `flutter test test/golden/effects_slice_golden_test.dart` → PASS. CI (Linux) re-verifies (spec §10).
- [ ] **Step 4 — Commit.** `test(style): golden slice — effects (shadow + opacity), light/dark (M7)`

---

## Task 4: Analyze, format, full test, no-drift doc sweep

- [ ] **Step 1 — Format.** `dart format --line-length 100 .`
- [ ] **Step 2 — Analyze.** `flutter analyze --fatal-infos --fatal-warnings` → `No issues found!`
- [ ] **Step 3 — Full suite.** `flutter test` → all green.
- [ ] **Step 4 — No-drift doc sweep (same commit):**
  - **`fw_style_ops.dart` header:** record **M7 added effects**; remaining modules 8 (layout), 9 (transforms), 10 (animated theming).
  - **Engine spec §6.5:** correct `shadow(FwShadow)` → `shadow(List<BoxShadow>)` (token list, theme-aware); note `opacity`/`blur`/`backdropBlur` setters write the renamed `FwStyle` fields `groupOpacity`/`contentBlur`/`backdropBlurSigma`; guards (opacity 0..1, sigmas ≥ 0).
  - **Engine spec §8:** drop the phantom `FwShadow` enum from the barrel list (the exported shadow type is `FwShadows`); the enums line keeps `FwBreakpoint`/`FwState`/`FwBlur`.
  - **Engine spec §12 row 7:** mark **✅ landed**; list the as-built setters + the field-rename + the `shadow(List<BoxShadow>)` correction.
  - **Engine spec §6.1:** update the effects field names (`opacity`→`groupOpacity`, `blur`→`contentBlur`, `backdropBlur`→`backdropBlurSigma`) with a note they're renamed to free the setter names (ResolvedStyle keeps the terse names).
  - **README "Shipped" list:** add a module 7 bullet; drop "effects" from the roadmap line.
- [ ] **Step 5 — Re-run analyze + test after doc edits.**
- [ ] **Step 6 — Commit.** `docs: align spec/README + ops doc to module 7 as-built`

---

## Definition of done

- `shadow`/`opacity`/`blur`/`backdropBlur` setters exist, typed, guarded; `shadow` takes the theme `List<BoxShadow>`; the `FwStyle` effect fields are renamed and `ResolvedStyle`/render chain are unchanged.
- Unit (`fw_effect_ops_test`) + golden (`effects_slice`) green; `flutter analyze --fatal-infos --fatal-warnings` clean; `dart format` clean.
- No-drift: spec §6.1/§6.5/§8/§12, README, ops header all match as-built; the `shadow(FwShadow)`→`shadow(List<BoxShadow>)` and phantom-`FwShadow`-enum corrections recorded.

## Self-review (spec coverage)

- §6.5 `shadow` → Task 2 (as `shadow(List<BoxShadow>)`, corrected). ✅
- §6.5 `opacity` → Task 2 (field `groupOpacity`, guard). ✅
- §6.5 `blur`, `backdropBlur` → Task 2 (fields `contentBlur`/`backdropBlurSigma`, guards). ✅
- §6.4 render-chain wrappers (`_ShadowBox`/`Opacity`/`ImageFiltered`/`BackdropFilter`) — exist (M3), unchanged. ✅
- §10 goldens (light/dark) → Task 3 (+ backdrop-blur coverage noted via render_chain_test). ✅
- §12 row 7 + no-drift → Task 4. ✅

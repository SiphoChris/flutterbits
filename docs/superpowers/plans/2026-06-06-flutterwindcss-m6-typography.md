# flutterwindcss Module 6 — Typography Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: `superpowers:test-driven-development`. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the typed `.tw` typography setters (text color, size, weight, line-height/leading, letter-spacing/tracking, alignment, underline/line-through) over the `DefaultTextStyle`/`IconTheme` merge the render chain already does. This is the module 6 row of the core-engine delivery table (spec §12).

**Architecture:** Module 3 already landed every typography `FwStyle` field (`foreground`, `fontSize`, `fontWeight`, `letterSpacing`, `lineHeight`, `textAlign`, `textDecoration`), the resolution merge, and the §6.4 render-chain text block (`DefaultTextStyle.merge(... ) → IconTheme.merge(...)`). This module adds **only** the ergonomic setters that write those fields — no new architecture, no render-chain change.

**Tech Stack:** Dart / Flutter widgets layer (`TextStyle`, `FontWeight`, `TextAlign`, `TextDecoration`), the M1 typography tokens (`FwFontSize`, `FwFontWeight`, `FwLeading`, `FwTracking`), `flutter_test` + the in-package golden harness (CI-authoritative).

**Spec:** core engine design `docs/superpowers/specs/2026-06-05-flutterwindcss-core-engine-design.md` §4.5 (typography tokens), §6.4 (render-chain text block), §6.5 (utility surface), §12 (row 6).

---

## Design decisions (recorded; correct/extend the spec where it was under-specified)

1. **Setter names avoid the field/setter collision (spec §6.5 was internally inconsistent).** `FwStyle` mixes in `FwStyleOps`, so a setter method cannot share a name with an `FwStyle` field. §6.5 listed `fontSize`, `fontWeight`, `textAlign` as utilities, but §6.1 also named the **fields** `fontSize`, `fontWeight`, `textAlign` — the same collision class as `border` in M5. Here the fields' names are already good and their **types are not changing**, so (unlike M5, where the field type changed and `border`→`borderSpec` was self-documenting) renaming the fields would be pure churn. Instead the **utilities** take clean, collision-free, Tailwind-faithful names; the fields stay. Mapping (field → utility):
   - `foreground` → **`text(Color)`** (no collision; kept from §6.5)
   - `fontSize` → **`textSize(double)`** (Tailwind `text-{size}`; avoids the `fontSize` field)
   - `fontWeight` → **`weight(int)`** (Tailwind `font-{weight}`; avoids the `fontWeight` field)
   - `lineHeight` → **`leading(double)`** (kept from §6.5; field is `lineHeight`)
   - `letterSpacing` → **`tracking(double)`** (kept from §6.5; field is `letterSpacing`)
   - `textAlign` → **`align(TextAlign)`** (avoids the `textAlign` field; the only single-box alignment, so unambiguous)
   - `textDecoration` → **`underline` / `lineThrough`** getters (kept from §6.5)

   The guiding principle is the same one M5 used — *keep the utility name clean & Tailwind-faithful, minimise churn* — it simply lands on "rename the setter" here because the field names are already right and unchanged.

2. **`weight` takes the CSS int scale and converts to `FontWeight`.** The M1 token `FwFontWeight.bold` is the int `700` (the Tailwind/CSS scale), but `TextStyle.fontWeight` wants a `FontWeight` object. So `weight(int)` accepts `100..900` (the token values) and maps to `FontWeight.values[(w ~/ 100) - 1]`, making `weight(FwFontWeight.semibold)` read naturally. Guarded: must be a multiple of 100 in `100..900`.

3. **`tracking` is absolute logical px (Flutter's model), NOT em — a genuine limitation, documented.** Tailwind letter-spacing (and the `FwTracking` token, e.g. `wide = 0.025`) is **em-relative**; Flutter's `TextStyle.letterSpacing` is **absolute logical px**, and the spacing is applied at render time with no font size in scope to multiply by. So `tracking(double)` takes absolute px. To use the em-based `FwTracking` scale, multiply by the font size at the call site: `tracking(FwTracking.wide * FwFontSize.base.px)`. Documented on the setter so the em/px mismatch isn't a silent foot-gun.

4. **`leading` is a line-height *multiple* (Flutter `TextStyle.height`).** Matches the `FwLeading` scale (`normal = 1.5`) and Tailwind's unitless `leading-*`. `leading(1.5)` = 1.5× the font size.

5. **Sizes/leading are guarded `> 0`; tracking may be negative.** Font size and line-height multiples must be positive (assert in debug, per the M5 audit's guard-what-devs-shouldn't-do principle). Letter-spacing legitimately goes negative (`FwTracking.tighter`), so it is **not** guarded.

6. **`underline`/`lineThrough` combine (not last-wins).** Like Tailwind (`underline line-through` shows both), `.underline.lineThrough` produces `TextDecoration.combine([...])`. Repeats are idempotent (the mask ORs). This is a deliberate per-field merge, like padding edges — documented.

7. **Text goldens use Flutter's built-in deterministic test font; no binary font is bundled.** `flutter test` renders text with a fixed, platform-independent test font, so text goldens are already CI-deterministic without committing a font asset (and its license). This **corrects the harness's earlier assumption** (`flutter_test_config.dart` comment: "added … in the typography module"): the `_loadFixedFontsIfPresent` hook stays wired for a future real-font swap, but M6 does not add one. Consequence: weight/family differences are not visually distinct under the test font (they are covered by unit tests); size, color, alignment, and decoration *are* visible.

---

## Setter contract (all in `FwStyleOps`)

| Utility | Writes field | Arg | Notes |
|---|---|---|---|
| `text(Color)` | `foreground` | color | also drives icon color (render chain `IconTheme`) |
| `textSize(double)` | `fontSize` | logical px (`FwFontSize.lg.px`) | also drives icon size; asserts `> 0` |
| `weight(int)` | `fontWeight` | `100..900` (`FwFontWeight.bold`) | int→`FontWeight`; asserts valid step |
| `leading(double)` | `lineHeight` | multiple (`FwLeading.normal`) | line-height ×; asserts `> 0` |
| `tracking(double)` | `letterSpacing` | logical px (see decision 3) | may be negative |
| `align(TextAlign)` | `textAlign` | `TextAlign.*` | start/end are directional |
| `underline` (getter) | `textDecoration` | — | combines |
| `lineThrough` (getter) | `textDecoration` | — | combines |

---

## File structure

- **Modify** `lib/src/style/fw_style_ops.dart` — add the typography setters (after the radius/clip block, before variant layering). No new imports (`Color`/`FontWeight`/`TextAlign`/`TextDecoration`/`TextStyle` come from `package:flutter/widgets.dart`, already imported).
- **Create** `test/style/fw_text_ops_test.dart` — unit tests for every setter + guards + decoration combine.
- **Create** `test/golden/typography_slice_golden_test.dart` — a styled `Text`, light LTR + dark RTL.
- **Modify** `test/flutter_test_config.dart` — correct the "typography module adds a font" comment to the as-built decision (no bundle).

---

## Task 1: Color / size / weight / leading / tracking / align setters (TDD)

**Files:** Modify `lib/src/style/fw_style_ops.dart`; Create `test/style/fw_text_ops_test.dart`.

- [ ] **Step 1 — Write the failing test** (`test/style/fw_text_ops_test.dart`):

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/fw_style.dart';
import 'package:flutterwindcss/src/tokens/typography.dart';

const _c = Color(0xFF112233);

void main() {
  group('value setters', () {
    test('text writes foreground', () {
      expect(const FwStyle().text(_c).foreground, _c);
    });

    test('textSize writes fontSize in logical px (last-wins)', () {
      expect(const FwStyle().textSize(18).fontSize, 18);
      expect(const FwStyle().textSize(18).textSize(24).fontSize, 24);
      expect(const FwStyle().textSize(FwFontSize.lg.px).fontSize, 18);
    });

    test('weight maps the CSS int scale to FontWeight', () {
      expect(const FwStyle().weight(700).fontWeight, FontWeight.w700);
      expect(const FwStyle().weight(FwFontWeight.semibold).fontWeight, FontWeight.w600);
      expect(const FwStyle().weight(100).fontWeight, FontWeight.w100);
      expect(const FwStyle().weight(900).fontWeight, FontWeight.w900);
    });

    test('leading writes the line-height multiple', () {
      expect(const FwStyle().leading(1.5).lineHeight, 1.5);
      expect(const FwStyle().leading(FwLeading.tight).lineHeight, 1.25);
    });

    test('tracking writes letterSpacing and may be negative', () {
      expect(const FwStyle().tracking(0.5).letterSpacing, 0.5);
      expect(const FwStyle().tracking(-0.4).letterSpacing, -0.4);
    });

    test('align writes textAlign', () {
      expect(const FwStyle().align(TextAlign.center).textAlign, TextAlign.center);
    });
  });

  group('guards', () {
    test('non-positive font size asserts', () {
      expect(() => const FwStyle().textSize(0), throwsAssertionError);
      expect(() => const FwStyle().textSize(-1), throwsAssertionError);
    });

    test('non-positive leading asserts', () {
      expect(() => const FwStyle().leading(0), throwsAssertionError);
    });

    test('out-of-range / unstepped weight asserts', () {
      expect(() => const FwStyle().weight(50), throwsAssertionError);
      expect(() => const FwStyle().weight(1000), throwsAssertionError);
      expect(() => const FwStyle().weight(450), throwsAssertionError);
    });
  });
}
```

- [ ] **Step 2 — Run, watch fail.** `cd packages/flutterwindcss && flutter test test/style/fw_text_ops_test.dart` → FAIL (no `text`/`textSize`/… methods).

- [ ] **Step 3 — Implement in `fw_style_ops.dart`** (insert after the `// ---- Clip ----` block, before `// ---- Variant layering ----`):

```dart
  // ---- Typography ----
  //
  // Setters take clean, collision-free names (the FwStyle fields already own
  // `fontSize`/`fontWeight`/`textAlign`, and FwStyle mixes in these ops). Sizes
  // are logical px; `leading` is a line-height multiple; `tracking` is absolute
  // logical px (Flutter's model), NOT em — to use the em-based FwTracking scale,
  // multiply by the font size, e.g. `tracking(FwTracking.wide * FwFontSize.base.px)`.

  /// Default text/icon color for descendants (Tailwind `text-{color}`).
  T text(Color color) => fwRebuild(fwStyle.copyWith(foreground: color));

  /// Default font size in logical px (Tailwind `text-{size}`); also sets icon
  /// size. Pass a token value like `FwFontSize.lg.px`. Must be `> 0`.
  T textSize(double px) {
    assert(px > 0, 'flutterwindcss: font size must be > 0 (got $px).');
    return fwRebuild(fwStyle.copyWith(fontSize: px));
  }

  /// Default font weight on the CSS scale `100..900` (Tailwind `font-{weight}`);
  /// pass a token like `FwFontWeight.semibold`. Maps to a Flutter [FontWeight].
  T weight(int weight) {
    assert(
      weight >= 100 && weight <= 900 && weight % 100 == 0,
      'flutterwindcss: font weight must be 100..900 in steps of 100 (got $weight).',
    );
    return fwRebuild(fwStyle.copyWith(fontWeight: FontWeight.values[(weight ~/ 100) - 1]));
  }

  /// Default line-height as a multiple of the font size (Tailwind `leading-*`);
  /// pass a token like `FwLeading.normal`. Must be `> 0`.
  T leading(double multiple) {
    assert(multiple > 0, 'flutterwindcss: leading (line-height multiple) must be > 0 (got $multiple).');
    return fwRebuild(fwStyle.copyWith(lineHeight: multiple));
  }

  /// Default letter-spacing in **absolute logical px** (Flutter's model;
  /// Tailwind/`FwTracking` are em — multiply by the font size to convert). May be
  /// negative (tighter tracking).
  T tracking(double logicalPx) => fwRebuild(fwStyle.copyWith(letterSpacing: logicalPx));

  /// Default text alignment (Tailwind `text-{align}`); `start`/`end` are RTL-aware.
  T align(TextAlign align) => fwRebuild(fwStyle.copyWith(textAlign: align));
```

- [ ] **Step 4 — Run, watch pass.** `flutter test test/style/fw_text_ops_test.dart` → PASS.

- [ ] **Step 5 — Commit.** `feat(style): typography value setters — text/textSize/weight/leading/tracking/align (M6)`

---

## Task 2: Decoration getters (underline / lineThrough, combine) (TDD)

**Files:** Modify `lib/src/style/fw_style_ops.dart`; same test file (decoration group).

- [ ] **Step 1 — Add the failing tests** (append to `fw_text_ops_test.dart`'s `main`):

```dart
  group('decoration', () {
    test('underline / lineThrough set their decoration', () {
      expect(const FwStyle().underline.textDecoration, TextDecoration.underline);
      expect(const FwStyle().lineThrough.textDecoration, TextDecoration.lineThrough);
    });

    test('underline + lineThrough combine (both present, order-independent)', () {
      final a = const FwStyle().underline.lineThrough.textDecoration!;
      final b = const FwStyle().lineThrough.underline.textDecoration!;
      for (final d in <TextDecoration>[a, b]) {
        expect(d.contains(TextDecoration.underline), isTrue);
        expect(d.contains(TextDecoration.lineThrough), isTrue);
      }
    });

    test('repeating a decoration is idempotent', () {
      expect(const FwStyle().underline.underline.textDecoration, TextDecoration.underline);
    });
  });
```

- [ ] **Step 2 — Run, watch fail.** `flutter test test/style/fw_text_ops_test.dart` → FAIL (no `underline`).

- [ ] **Step 3 — Implement in `fw_style_ops.dart`** (insert right after `align`, still inside the Typography block):

```dart
  T _addDecoration(TextDecoration d) {
    final existing = fwStyle.textDecoration;
    final combined = existing == null || existing == TextDecoration.none
        ? d
        : TextDecoration.combine(<TextDecoration>[existing, d]);
    return fwRebuild(fwStyle.copyWith(textDecoration: combined));
  }

  /// Underlines descendant text; combines with any existing decoration (Tailwind
  /// `underline`).
  T get underline => _addDecoration(TextDecoration.underline);

  /// Strikes through descendant text; combines with any existing decoration
  /// (Tailwind `line-through`).
  T get lineThrough => _addDecoration(TextDecoration.lineThrough);
```

- [ ] **Step 4 — Run, watch pass.** `flutter test test/style/fw_text_ops_test.dart` → PASS.

- [ ] **Step 5 — Commit.** `feat(style): underline / lineThrough decoration setters (M6)`

---

## Task 3: Golden — typography slice (LTR/RTL, light/dark)

**Files:** Create `test/golden/typography_slice_golden_test.dart`; Modify `test/flutter_test_config.dart` (comment correction).

- [ ] **Step 1 — Correct the harness comment** in `flutter_test_config.dart` (the doc + the helper body), replacing the "added … in the typography module" wording:

  - Doc-comment line: change "Loads any bundled fixed fonts (added when text first renders, in the typography module)…" to "Loads any bundled fixed fonts if present. The typography module (M6) deliberately uses Flutter's built-in deterministic test font instead of a bundled face, so this stays a no-op until a real font is ever needed…".
  - `_loadFixedFontsIfPresent` body comment: change "Intentionally empty in Module 0; the typography module appends FontLoader registrations." to "Intentionally empty: M6 typography uses the deterministic built-in test font; this hook remains for a future real-font swap."

- [ ] **Step 2 — Write the golden test:**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

// Golden slice for the module 6 typography setters. A styled Text in a padded
// card exercises color + size + weight + leading + start-alignment + underline.
// Text renders with Flutter's built-in deterministic test font (no bundled
// face), so size/color/alignment/decoration are visible and CI-stable; weight is
// unit-tested rather than golden-tested (not visually distinct under that font).
// `align(TextAlign.start)` + a fixed width makes RTL mirror the text to the end.
// Local generation is non-authoritative; CI (Linux) is the source of truth.
Widget _frame(FwTokens tokens, TextDirection dir, Widget child) => FwTheme(
  tokens: tokens,
  child: Directionality(
    textDirection: dir,
    child: MediaQuery(
      data: const MediaQueryData(size: Size(220, 120)),
      child: Center(child: child),
    ),
  ),
);

Widget _text(BuildContext context) {
  final c = context.fw.colors;
  return const Text('Ag')
      .tw
      .w(40)
      .p(2)
      .bg(c.card)
      .text(c.cardForeground)
      .textSize(FwFontSize.xl2.px)
      .weight(FwFontWeight.bold)
      .leading(FwLeading.tight)
      .align(TextAlign.start)
      .underline;
}

void main() {
  testWidgets('typography slice — light LTR', (t) async {
    await t.pumpWidget(_frame(FwTokens.light, TextDirection.ltr, const Builder(builder: _text)));
    await expectLater(
      find.byType(FwStyled).first,
      matchesGoldenFile('goldens/typography_light_ltr.png'),
    );
  });

  testWidgets('typography slice — dark RTL (start alignment mirrors to the end)', (t) async {
    await t.pumpWidget(_frame(FwTokens.dark, TextDirection.rtl, const Builder(builder: _text)));
    await expectLater(
      find.byType(FwStyled).first,
      matchesGoldenFile('goldens/typography_dark_rtl.png'),
    );
  });
}
```

- [ ] **Step 3 — Generate the golden bytes (non-authoritative).** `flutter test --update-goldens test/golden/typography_slice_golden_test.dart`. Confirm `goldens/typography_light_ltr.png` + `typography_dark_rtl.png` are written; eyeball them (underlined glyphs; start-aligned text left in LTR, right in RTL; light vs dark card).

- [ ] **Step 4 — Run without updating, watch pass.** `flutter test test/golden/typography_slice_golden_test.dart` → PASS. Note CI (Linux) re-verifies (spec §10).

- [ ] **Step 5 — Commit.** `test(style): golden slice — typography, light/dark, LTR/RTL (M6)`

---

## Task 4: Analyze, format, full test, no-drift doc sweep

**Files:** docs only (`fw_style_ops.dart` header, engine spec §6.5/§12, README).

- [ ] **Step 1 — Format.** `dart format --line-length 100 .`
- [ ] **Step 2 — Analyze.** `cd packages/flutterwindcss && flutter analyze --fatal-infos --fatal-warnings` → `No issues found!`
- [ ] **Step 3 — Full suite.** `flutter test` → all green.
- [ ] **Step 4 — No-drift doc sweep (same commit as verification):**
  - **`fw_style_ops.dart` header doc-comment:** record that **M6 added typography**; remaining modules are 7 (effects), 8 (layout), 9 (transforms).
  - **Engine spec §6.5:** correct the typography utilities to the as-built names — `text(color), textSize, weight, leading, tracking, align, underline/lineThrough` — with a note that `fontSize`/`fontWeight`/`textAlign` were renamed to avoid the field/setter collision, `weight` takes the CSS int scale, and `tracking` is absolute px (not em).
  - **Engine spec §12 row 6:** mark **✅ landed**; list the as-built setters + the int-weight/px-tracking/test-font decisions.
  - **README "Shipped" list:** add a module 6 bullet (typography setters); drop "typography" from the "Next on the roadmap → Utility families" line.
- [ ] **Step 5 — Re-run analyze + test after doc edits.**
- [ ] **Step 6 — Commit.** `docs: align spec/README + ops doc to module 6 as-built`

---

## Definition of done

- Every §6.5 typography utility exists (as-built names), typed, with documented units and guards; `weight` maps the int scale; `tracking` documents the em→px caveat; `underline`/`lineThrough` combine.
- Unit (`fw_text_ops_test`) + golden (`typography_slice`, light/dark × LTR/RTL) green; `flutter analyze --fatal-infos --fatal-warnings` clean; `dart format` clean.
- No-drift: no spec/README/doc-comment still describes M6 as unbuilt; the setter-name corrections + the deterministic-test-font decision are recorded (engine spec §6.5/§12, `flutter_test_config.dart`).

## Self-review (spec coverage)

- §6.5 `text(color)` → Task 1. ✅
- §6.5 `fontSize` → `textSize` (renamed, recorded) → Task 1. ✅
- §6.5 `fontWeight` → `weight` (renamed, int scale) → Task 1. ✅
- §6.5 `leading`, `tracking` → Task 1 (px caveat for tracking). ✅
- §6.5 `textAlign` → `align` (renamed) → Task 1. ✅
- §6.5 `underline/lineThrough` → Task 2 (combine). ✅
- §6.4 render-chain text block — already exists (M3); unchanged, exercised by the golden. ✅
- §10 goldens (light/dark, LTR/RTL) → Task 3. ✅
- §12 row 6 + no-drift → Task 4. ✅

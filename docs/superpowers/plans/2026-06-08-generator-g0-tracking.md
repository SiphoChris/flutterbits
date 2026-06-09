# Generator G0 — `tracking` on `FwTypographyTheme` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a theme-level `tracking` (letter-spacing) field to `FwTypographyTheme` so the tweakcn→`theme.dart` generator can round-trip and interpolate shadcn's `--tracking-normal`, without changing any existing theme's rendering.

**Architecture:** `FwTypographyTheme` (in `lib/src/tokens/tokens.dart`) gains a numeric `tracking` field (em, default `0`), a static `FwTypographyTheme.lerp` (family names hard-crossover at `t=0.5`, `tracking` interpolates linearly), and `FwTokens.lerp` is rewired to call it instead of its current hard typography crossover. Default `0` keeps `FwTokens.light`/`dark`, `FwTypographyTheme.standard`, and every existing golden byte-identical. A doc drift sweep fixes a now-misleading `radii.dart` comment and updates the spec/AGENTS.md statements the new field falsifies.

**Tech Stack:** Dart 3.7+ / Flutter 3.29+, `flutter_test`. Source of truth: `docs/superpowers/specs/2026-06-08-tweakcn-theme-generator-design.md` §5.

**Branch:** This is generator module **G0**, one PR. Create a branch `feat/generator-g0-tracking` off `main` (after the `docs/generator-spec` branch merges, or branch from it). All tasks below commit to that branch; open the PR after Task 4.

---

## File Structure

- **Modify:** `packages/flutterwindcss/lib/src/tokens/tokens.dart` — `FwTypographyTheme` (field + `lerp` + `==`/`hashCode` + docs) and `FwTokens.lerp` (rewire).
- **Modify:** `packages/flutterwindcss/lib/src/tokens/radii.dart` — fix the misleading "Prefer `FwRadii.fromBase`" doc-comment (doc only).
- **Modify:** `packages/flutterwindcss/test/tokens/tokens_test.dart` — new assertions for `tracking` (field default, equality, `FwTypographyTheme.lerp`, `FwTokens.lerp` interpolation).
- **Modify (docs, drift):** `docs/superpowers/specs/2026-06-08-tweakcn-theme-generator-design.md` §5; `AGENTS.md` §5/§7 statements about `--tracking-normal`.

No barrel change (no new public type), no `apps/example` change (default `0` preserves rendering), no new dependency.

---

## Task 1: Add the `tracking` field to `FwTypographyTheme`

**Files:**
- Modify: `packages/flutterwindcss/lib/src/tokens/tokens.dart` (class `FwTypographyTheme`, ~lines 170–203)
- Test: `packages/flutterwindcss/test/tokens/tokens_test.dart`

- [ ] **Step 1: Write the failing test**

Append these two tests inside `main()` in `packages/flutterwindcss/test/tokens/tokens_test.dart` (after the existing `'typography carries sans/serif/mono; family aliases sans'` test):

```dart
  test('typography tracking defaults to 0 and round-trips', () {
    expect(FwTypographyTheme.standard.tracking, 0);
    expect(const FwTypographyTheme().tracking, 0);
    const t = FwTypographyTheme(sans: 'Outfit', tracking: -0.025);
    expect(t.tracking, -0.025);
  });

  test('typography equality and hashCode include tracking', () {
    const a = FwTypographyTheme(sans: 'Outfit', tracking: 0);
    const b = FwTypographyTheme(sans: 'Outfit', tracking: -0.025);
    expect(a == b, isFalse);
    expect(a.hashCode == b.hashCode, isFalse);
    // Same tracking + same families stays equal.
    expect(a == const FwTypographyTheme(sans: 'Outfit'), isTrue);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd packages/flutterwindcss && flutter test test/tokens/tokens_test.dart --plain-name tracking`
Expected: FAIL — compile error / no named parameter `tracking` for `FwTypographyTheme`.

- [ ] **Step 3: Add the field, doc, and equality**

In `packages/flutterwindcss/lib/src/tokens/tokens.dart`, replace the `FwTypographyTheme` constructor, fields, `standard`, `==`, and `hashCode` with the version below (this adds `tracking` to the constructor, fields, `==`, and `hashCode`; it does **not** yet add `lerp` — that is Task 2):

```dart
  /// Creates a typography theme from its family names and base letter-spacing.
  const FwTypographyTheme({
    this.sans = FwFontFamily.sans,
    this.serif = FwFontFamily.serif,
    this.mono = FwFontFamily.mono,
    this.tracking = 0,
  });

  /// The default UI/body (sans) family name.
  final String sans;

  /// The serif family name.
  final String serif;

  /// The monospace family name.
  final String mono;

  /// Theme base letter-spacing in **em** (shadcn `--tracking-normal`), stored as an
  /// em multiple (e.g. `-0.025` for `-0.025em`). Consumers convert to Flutter's
  /// logical-px `TextStyle.letterSpacing` as `tracking × fontSize` at the text-apply
  /// site — the token only carries the value. `0` (the default) means no extra
  /// tracking, preserving prior behavior and all existing goldens.
  final double tracking;

  /// Convenience alias for [sans] — the default body family.
  String get family => sans;

  /// The standard theme using the platform sans/serif/mono families and zero tracking.
  static const FwTypographyTheme standard = FwTypographyTheme();

  @override
  bool operator ==(Object other) =>
      other is FwTypographyTheme &&
      other.sans == sans &&
      other.serif == serif &&
      other.mono == mono &&
      other.tracking == tracking;

  @override
  int get hashCode => Object.hash(sans, serif, mono, tracking);
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd packages/flutterwindcss && flutter test test/tokens/tokens_test.dart --plain-name tracking`
Expected: PASS (2 tests).

- [ ] **Step 5: Run the full token suite (no regressions)**

Run: `cd packages/flutterwindcss && flutter test test/tokens/tokens_test.dart`
Expected: PASS — all tests green (the existing equality/typography tests still hold; default `tracking: 0` keeps `standard` and the literal themes unchanged).

- [ ] **Step 6: Commit**

```bash
git add packages/flutterwindcss/lib/src/tokens/tokens.dart packages/flutterwindcss/test/tokens/tokens_test.dart
git commit -m "feat(tokens): add tracking (em) field to FwTypographyTheme

Carries shadcn --tracking-normal; default 0 preserves all existing
themes/goldens. Included in == and hashCode."
```

---

## Task 2: Add `FwTypographyTheme.lerp`

**Files:**
- Modify: `packages/flutterwindcss/lib/src/tokens/tokens.dart` (class `FwTypographyTheme`)
- Test: `packages/flutterwindcss/test/tokens/tokens_test.dart`

- [ ] **Step 1: Write the failing test**

Append inside `main()` in `tokens_test.dart`:

```dart
  test('FwTypographyTheme.lerp crosses families at 0.5 and interpolates tracking', () {
    const a = FwTypographyTheme(sans: 'A', serif: 'As', mono: 'Am', tracking: 0);
    const b = FwTypographyTheme(sans: 'B', serif: 'Bs', mono: 'Bm', tracking: -0.04);

    // Families hard-crossover at t = 0.5 (strings cannot interpolate).
    expect(FwTypographyTheme.lerp(a, b, 0.0).sans, 'A');
    expect(FwTypographyTheme.lerp(a, b, 0.49).sans, 'A');
    expect(FwTypographyTheme.lerp(a, b, 0.5).sans, 'B');
    expect(FwTypographyTheme.lerp(a, b, 1.0).mono, 'Bm');

    // tracking interpolates linearly (continuous through the crossover).
    expect(FwTypographyTheme.lerp(a, b, 0.0).tracking, 0);
    expect(FwTypographyTheme.lerp(a, b, 0.5).tracking, closeTo(-0.02, 1e-9));
    expect(FwTypographyTheme.lerp(a, b, 1.0).tracking, closeTo(-0.04, 1e-9));
  });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd packages/flutterwindcss && flutter test test/tokens/tokens_test.dart --plain-name "FwTypographyTheme.lerp"`
Expected: FAIL — `lerp` is not defined for `FwTypographyTheme`.

- [ ] **Step 3: Implement `lerp`**

In `packages/flutterwindcss/lib/src/tokens/tokens.dart`, add this static method to `FwTypographyTheme`, immediately before the `@override bool operator ==` line:

```dart
  /// Interpolates two typography themes. Family **names** are [String]s and cannot
  /// numerically interpolate, so they hard-crossover at `t = 0.5` (the approach
  /// Flutter uses for non-lerpable fields); [tracking] is numeric and interpolates
  /// linearly, so it stays continuous through the crossover.
  static FwTypographyTheme lerp(FwTypographyTheme a, FwTypographyTheme b, double t) {
    final FwTypographyTheme families = t < 0.5 ? a : b;
    return FwTypographyTheme(
      sans: families.sans,
      serif: families.serif,
      mono: families.mono,
      tracking: a.tracking + (b.tracking - a.tracking) * t,
    );
  }
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd packages/flutterwindcss && flutter test test/tokens/tokens_test.dart --plain-name "FwTypographyTheme.lerp"`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/flutterwindcss/lib/src/tokens/tokens.dart packages/flutterwindcss/test/tokens/tokens_test.dart
git commit -m "feat(tokens): add FwTypographyTheme.lerp

Family names hard-crossover at t=0.5; tracking interpolates linearly."
```

---

## Task 3: Rewire `FwTokens.lerp` to interpolate typography

**Files:**
- Modify: `packages/flutterwindcss/lib/src/tokens/tokens.dart` (`FwTokens.lerp`, ~lines 133–141)
- Test: `packages/flutterwindcss/test/tokens/tokens_test.dart`

- [ ] **Step 1: Write the failing test**

Append inside `main()` in `tokens_test.dart`:

```dart
  test('FwTokens.lerp interpolates typography tracking', () {
    FwTokens withTracking(double tracking) => FwTokens(
      colors: FwTokens.light.colors,
      radii: FwTokens.light.radii,
      shadows: FwTokens.light.shadows,
      typography: FwTypographyTheme(sans: 'A', tracking: tracking),
      radiusBase: FwTokens.light.radiusBase,
    );
    final a = withTracking(0);
    final b = withTracking(-0.04);
    expect(FwTokens.lerp(a, b, 0.5).typography.tracking, closeTo(-0.02, 1e-9));
  });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd packages/flutterwindcss && flutter test test/tokens/tokens_test.dart --plain-name "FwTokens.lerp interpolates typography tracking"`
Expected: FAIL — the current `FwTokens.lerp` hard-crossovers typography, so at `t=0.5` it returns `b.typography` (`tracking == -0.04`), not the interpolated `-0.02`.

- [ ] **Step 3: Rewire `FwTokens.lerp`**

In `packages/flutterwindcss/lib/src/tokens/tokens.dart`, replace the existing `FwTokens.lerp` body:

```dart
  /// Interpolates two themes (drives FwAnimatedTheme later).
  static FwTokens lerp(FwTokens a, FwTokens b, double t) => FwTokens(
    colors: FwColors.lerp(a.colors, b.colors, t),
    radii: FwRadii.lerp(a.radii, b.radii, t),
    shadows: FwShadows.lerp(a.shadows, b.shadows, t),
    // String family names cannot numerically interpolate; use a hard
    // crossover at t=0.5 (same approach Flutter takes for non-lerpable fields).
    typography: t < 0.5 ? a.typography : b.typography,
    radiusBase: a.radiusBase + (b.radiusBase - a.radiusBase) * t,
  );
```

with:

```dart
  /// Interpolates two themes (drives FwAnimatedTheme later).
  static FwTokens lerp(FwTokens a, FwTokens b, double t) => FwTokens(
    colors: FwColors.lerp(a.colors, b.colors, t),
    radii: FwRadii.lerp(a.radii, b.radii, t),
    shadows: FwShadows.lerp(a.shadows, b.shadows, t),
    // Family names hard-crossover at t=0.5 while tracking interpolates — see
    // FwTypographyTheme.lerp. (Was a whole-object crossover before tracking.)
    typography: FwTypographyTheme.lerp(a.typography, b.typography, t),
    radiusBase: a.radiusBase + (b.radiusBase - a.radiusBase) * t,
  );
```

- [ ] **Step 4: Run the new test to verify it passes**

Run: `cd packages/flutterwindcss && flutter test test/tokens/tokens_test.dart --plain-name "FwTokens.lerp interpolates typography tracking"`
Expected: PASS.

- [ ] **Step 5: Run the whole package suite to confirm no regression**

Run: `cd packages/flutterwindcss && flutter test`
Expected: PASS — all tests, including the existing `'lerp carries typography across the t=0.5 threshold'` and `'lerp boundaries carry the whole non-color object intact'` tests. (These still hold: with both themes at `tracking: 0`, `FwTypographyTheme.lerp` returns a value equal to the crossed-over family object, so equality is preserved; goldens are untouched because `FwTokens.light`/`dark` carry `tracking: 0`.)

- [ ] **Step 6: Commit**

```bash
git add packages/flutterwindcss/lib/src/tokens/tokens.dart packages/flutterwindcss/test/tokens/tokens_test.dart
git commit -m "feat(tokens): interpolate typography tracking in FwTokens.lerp

Replaces the whole-object typography crossover with FwTypographyTheme.lerp
so tracking animates continuously during theme transitions; family names
still crossover at t=0.5. Existing crossover tests unaffected (tracking 0)."
```

---

## Task 4: Doc drift sweep + final quality gate

No production code changes — fix the docs the new field/behavior falsified (§12 no-drift), then run the full zero-warning gate.

**Files:**
- Modify: `packages/flutterwindcss/lib/src/tokens/radii.dart` (doc-comment, ~lines 9 and 18–26)
- Modify: `docs/superpowers/specs/2026-06-08-tweakcn-theme-generator-design.md` (§5)
- Modify: `AGENTS.md` (§5 typography bundle list; §7 `--tracking-normal` "recorded gap" note)

- [ ] **Step 1: Fix the misleading `radii.dart` doc-comment**

In `packages/flutterwindcss/lib/src/tokens/radii.dart`, replace the explicit-constructor doc line:

```dart
  /// Creates a radius set from explicit values. Prefer [FwRadii.fromBase].
```

with:

```dart
  /// Creates a radius set from explicit per-step values.
  ///
  /// Use this when the steps are **not** the stock ×-factor ratios — e.g. a
  /// generated theme using shadcn's *additive* derivation (`sm = base−4`,
  /// `md = base−2`, `lg = base`, `xl = base+4`), which coincides with
  /// [FwRadii.fromBase] only at the 10px default and diverges otherwise. For
  /// stock ×-factor themes, prefer [FwRadii.fromBase].
```

- [ ] **Step 2: Correct the spec's class location and the `tracking` status**

In `docs/superpowers/specs/2026-06-08-tweakcn-theme-generator-design.md`, in the §5 opening line, replace:

```markdown
A small, coordinated Dart change so the emit target exists. In
`packages/flutterwindcss/lib/src/tokens/typography.dart` (and `tokens.dart`):
```

with:

```markdown
A small, coordinated Dart change so the emit target exists. `FwTypographyTheme`
lives in `packages/flutterwindcss/lib/src/tokens/tokens.dart` (not `typography.dart`,
which holds only the static type scales); edit it there:
```

- [ ] **Step 3: Update AGENTS.md statements the field falsified**

In `AGENTS.md` §7 "Known generator-phase additions", replace the `--tracking-normal` sentence:

```markdown
**`--tracking-normal`:** add a `tracking` field to `FwTypographyTheme` (numeric → `lerp`-able) when the generator lands, and emit it; until then it is a *recorded* gap, not silently dropped.
```

with:

```markdown
**`--tracking-normal`:** `FwTypographyTheme.tracking` (em, `lerp`-able) **exists as of generator module G0**; the generator emits it. (Stored as an em multiple; converted to `letterSpacing` at the text-apply site.)
```

Then in §5, in the sentence describing the typography bundle, replace:

```markdown
and `typography` (`sans`/`serif`/`mono` family names — flutterwindcss bundles no fonts, so the generator emits a `google_fonts` wiring stub rather than a silent fallback, per §7).
```

with:

```markdown
and `typography` (`sans`/`serif`/`mono` family names **plus `tracking`** (em letter-spacing) — flutterwindcss bundles no fonts, so the generator emits a `google_fonts` wiring stub rather than a silent fallback, per §7).
```

- [ ] **Step 4: Confirm no other doc references are stale**

Run: `cd packages/flutterwindcss && git grep -n "tracking-normal\|FwTypographyTheme" -- .. ':!**/plans/**'`
Expected: review each hit; the only statements implying the field is "not yet added" should be the ones edited in Steps 2–3. (The README has no `FwTypographyTheme` field list to update; if a hit shows otherwise, update it to include `tracking`.)

- [ ] **Step 5: Format and analyze (zero-warning bar)**

Run: `cd packages/flutterwindcss && dart format --line-length 100 lib test && flutter analyze --fatal-infos --fatal-warnings`
Expected: `dart format` reports the touched files unchanged or reformatted; `flutter analyze` → "No issues found!".

- [ ] **Step 6: Full test gate**

Run: `cd packages/flutterwindcss && flutter test`
Expected: PASS — entire suite green.

- [ ] **Step 7: Commit**

```bash
git add packages/flutterwindcss/lib/src/tokens/radii.dart docs/superpowers/specs/2026-06-08-tweakcn-theme-generator-design.md AGENTS.md
git commit -m "docs(drift): align radii doc + spec/AGENTS with FwTypographyTheme.tracking

Fix radii.dart's misleading 'prefer fromBase' comment (additive themes
need the explicit ctor); correct the spec's class location; mark the
AGENTS.md --tracking-normal gap as closed by G0."
```

- [ ] **Step 8: Open the PR**

```bash
git push -u origin feat/generator-g0-tracking
gh pr create --fill --base main
```

Then merge per the project workflow (`gh pr merge`).

---

## Self-Review notes (already reconciled)

- **Spec §5 coverage:** field (T1), `==`/`hashCode` (T1), `FwTypographyTheme.lerp` (T2), `FwTokens.lerp` rewire (T3), `light`/`dark`/`standard` unchanged (default `0`, verified by full suite in T1/T3), drift sweep incl. `radii.dart` doc + AGENTS.md + spec location (T4). em units documented on the field (T1). The render-path application of `tracking` is the spec's explicit recorded follow-on — **out of G0 scope** by decision; not a task here.
- **Existing-test compatibility:** `'lerp carries typography across the t=0.5 threshold'` and `'lerp boundaries carry the whole non-color object intact'` remain green because both endpoints have `tracking: 0`, so `FwTypographyTheme.lerp` returns a value equal to the hard-crossover family object.
- **No placeholders / type consistency:** method named `FwTypographyTheme.lerp` consistently in T2/T3; field named `tracking` throughout; all code blocks complete.

# flutterwindcss Module 0 + Module 1 (Scaffold + Tokens) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the `flutterwindcss` pub-workspace package with a strict analyzer + deterministic golden-test harness (Module 0), then implement the complete, immutable, `lerp`-able token system — Tailwind v4 palette, the 19 shadcn semantic tokens, all scales, and `FwTokens.light/dark` (Module 1).

**Architecture:** A Dart/Flutter package under `packages/flutterwindcss` resolved via pub workspaces. Tokens are pure `@immutable` `const` data classes with `lerp`; the raw Tailwind v4 palette is **baked** from published sRGB hex (no color math in Dart — honors AGENTS.md §7 / spec R4) via a one-off `tooling/` generator into a committed `palette.g.dart`. The `FwState`/`FwBreakpoint` enums are frozen here as permanent API contract (spec §12).

**Tech Stack:** Dart 3.11, Flutter (widgets layer only), `flutter_test`, `flutter_lints`. No third-party runtime deps.

**Spec:** `docs/superpowers/specs/2026-06-05-flutterwindcss-core-engine-design.md` (§4 tokens, §10 testing, §12 modules 0–1).

---

## File Structure

Module 0:
- `pubspec.yaml` — root pub-workspace manifest (workspace members).
- `packages/flutterwindcss/pubspec.yaml` — the package (`resolution: workspace`).
- `packages/flutterwindcss/analysis_options.yaml` — strict analyzer + lint bar.
- `packages/flutterwindcss/lib/flutterwindcss.dart` — public barrel (exports grow per module).
- `packages/flutterwindcss/test/flutter_test_config.dart` — golden harness bootstrap (font loader hook, golden tolerance).
- `packages/flutterwindcss/test/golden/_harness_smoke_test.dart` — proves the golden pipeline end-to-end.
- `packages/flutterwindcss/test/golden/goldens/harness_smoke.png` — authoritative golden (generated on CI/Linux).
- `.github/workflows/ci.yaml` — analyze + test (incl. goldens) on Ubuntu.
- `.gitattributes` — force LF + mark `*.png` binary (golden stability across the Windows dev box).

Module 1 (all under `packages/flutterwindcss/`):
- `lib/src/tokens/palette.g.dart` — **generated** baked Tailwind v4 palette (`const Color`s).
- `lib/src/tokens/palette.dart` — `FwPalette` / `FwSwatch` access over the generated map.
- `lib/src/tokens/colors.dart` — `FwColors` (19 semantic tokens) + `lerp`.
- `lib/src/tokens/radii.dart` — `FwRadii` (shadcn-derived set + Tailwind named scale) + `lerp`.
- `lib/src/tokens/shadows.dart` — `FwShadows` (Tailwind box-shadow scale) + `lerp`.
- `lib/src/tokens/typography.dart` — `FwTypography` (font-size/weight/tracking/leading/families).
- `lib/src/tokens/scales.dart` — `fwSpace`, opacity/border-width/z/blur scales, `FwBreakpoint`, `FwState`.
- `lib/src/tokens/tokens.dart` — `FwTokens` bundle + `light`/`dark` + `lerp`.
- `tooling/palette/tailwind_v4_palette.json` — committed source hex values.
- `tooling/bake_palette.dart` — JSON → `palette.g.dart` generator (no color math; pure transcription).
- Tests mirror each under `test/tokens/`.

---

## MODULE 0 — Scaffold + Golden Harness

### Task 0.1: Root pub-workspace manifest

**Files:**
- Create: `pubspec.yaml`

- [ ] **Step 1: Write the root workspace manifest**

```yaml
# Root pub-workspace manifest. Members set `resolution: workspace`.
name: _flutterbits_workspace
publish_to: none

environment:
  sdk: ^3.11.0

workspace:
  - packages/flutterwindcss
```

- [ ] **Step 2: Commit**

```bash
git add pubspec.yaml
git commit -m "chore: root pub-workspace manifest"
```

### Task 0.2: The flutterwindcss package manifest

**Files:**
- Create: `packages/flutterwindcss/pubspec.yaml`

- [ ] **Step 1: Write the package manifest**

```yaml
name: flutterwindcss
description: >-
  Tailwind CSS v4 design system and styling vocabulary for Flutter — tokens,
  theming, and a typed utility API over the widgets layer.
version: 0.1.0
publish_to: none
resolution: workspace

environment:
  sdk: ^3.11.0
  flutter: '>=3.24.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
```

- [ ] **Step 2: Resolve dependencies**

Run: `cd packages/flutterwindcss && flutter pub get`
Expected: `Got dependencies!` and a generated `.dart_tool/` (gitignored). If pub reports a workspace error, confirm Task 0.1's `pubspec.yaml` is at repo root.

- [ ] **Step 3: Commit**

```bash
git add packages/flutterwindcss/pubspec.yaml
git commit -m "chore: flutterwindcss package manifest"
```

### Task 0.3: Strict analyzer config

**Files:**
- Create: `packages/flutterwindcss/analysis_options.yaml`

- [ ] **Step 1: Write the analyzer config (zero-warning bar)**

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    # Any analyzer hint/warning fails CI.
    todo: ignore
    missing_required_param: error
    missing_return: error

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_constructors_in_immutables
    - prefer_const_declarations
    - prefer_final_locals
    - require_trailing_commas
    - directives_ordering
    - always_declare_return_types
    - public_member_api_docs
```

> `public_member_api_docs` enforces the AGENTS.md §4 rule that every public member is `///`-documented. Generated files (`*.g.dart`) are excluded in Task 1.2.

- [ ] **Step 2: Commit**

```bash
git add packages/flutterwindcss/analysis_options.yaml
git commit -m "chore: strict analyzer + lint bar"
```

### Task 0.4: Public barrel stub

**Files:**
- Create: `packages/flutterwindcss/lib/flutterwindcss.dart`

- [ ] **Step 1: Write the barrel**

```dart
/// flutterwindcss — Tailwind CSS v4's design system and styling vocabulary
/// for Flutter.
///
/// This barrel is the entire supported public surface. Consumers import only
/// this file; importing from `src/` is unsupported (AGENTS.md §3.6).
library;

// Token system (Module 1).
export 'src/tokens/colors.dart';
export 'src/tokens/palette.dart';
export 'src/tokens/radii.dart';
export 'src/tokens/scales.dart';
export 'src/tokens/shadows.dart';
export 'src/tokens/tokens.dart';
export 'src/tokens/typography.dart';
```

> The `export`s reference files created in Module 1. Analyze will fail until Task 1.x create them — that is expected; do not run `flutter analyze` on the package until Module 1 is underway. (If you want a green analyze at the end of Module 0, temporarily comment the exports and uncomment them in Task 1.1; the plan assumes Module 1 follows immediately.)

- [ ] **Step 2: Commit**

```bash
git add packages/flutterwindcss/lib/flutterwindcss.dart
git commit -m "chore: public barrel stub"
```

### Task 0.5: Golden harness bootstrap

**Files:**
- Create: `packages/flutterwindcss/test/flutter_test_config.dart`

- [ ] **Step 1: Write the harness bootstrap**

```dart
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Global test bootstrap, auto-discovered by `flutter test`.
///
/// Loads any bundled fixed fonts (added when text first renders, in the
/// typography module) so text goldens are deterministic, and pins the golden
/// comparator. Non-text goldens (solid fills, borders) are deterministic
/// without a custom font. CI (Linux) is the authoritative golden platform;
/// `--update-goldens` on a dev machine is NOT authoritative (spec §10, R1).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Load fixed fonts from test/fonts/ if present. No-op until the typography
  // module adds a font; keeps the harness wired from Module 0.
  await _loadFixedFontsIfPresent();

  await testMain();
}

Future<void> _loadFixedFontsIfPresent() async {
  // Fonts are registered here as they are added. Intentionally empty in
  // Module 0; the typography module appends FontLoader registrations.
}
```

- [ ] **Step 2: Commit**

```bash
git add packages/flutterwindcss/test/flutter_test_config.dart
git commit -m "test: golden harness bootstrap"
```

### Task 0.6: Smoke golden proving the pipeline

**Files:**
- Create: `packages/flutterwindcss/test/golden/_harness_smoke_test.dart`
- Create (generated): `packages/flutterwindcss/test/golden/goldens/harness_smoke.png`

- [ ] **Step 1: Write the smoke golden test**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('golden harness renders a deterministic solid fill', (tester) async {
    await tester.pumpWidget(
      const Center(
        child: SizedBox(
          width: 64,
          height: 64,
          // Opaque fill: no anti-aliased edges, so it is byte-identical
          // across platforms — the safe smoke test for the pipeline itself.
          child: ColoredBox(color: Color(0xFF2563EB)),
        ),
      ),
    );

    await expectLater(
      find.byType(ColoredBox),
      matchesGoldenFile('goldens/harness_smoke.png'),
    );
  });
}
```

- [ ] **Step 2: Run to verify it fails (no golden yet)**

Run: `cd packages/flutterwindcss && flutter test test/golden/_harness_smoke_test.dart`
Expected: FAIL — "Could not be compared against non-existent file" referencing `goldens/harness_smoke.png`.

- [ ] **Step 3: Generate the golden**

Run: `cd packages/flutterwindcss && flutter test --update-goldens test/golden/_harness_smoke_test.dart`
Expected: PASS; `goldens/harness_smoke.png` now exists.

> Note: this baseline is generated on the current (Windows) machine. CI will regenerate/verify on Linux; if CI's first run diffs on this opaque fill (it should not, as there are no AA edges), re-baseline from CI per Task 0.7's notes.

- [ ] **Step 4: Run again to verify it passes**

Run: `cd packages/flutterwindcss && flutter test test/golden/_harness_smoke_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/flutterwindcss/test/golden/_harness_smoke_test.dart \
        packages/flutterwindcss/test/golden/goldens/harness_smoke.png
git commit -m "test: smoke golden proving the harness pipeline"
```

### Task 0.7: CI workflow + git attributes

**Files:**
- Create: `.github/workflows/ci.yaml`
- Create: `.gitattributes`

- [ ] **Step 1: Write `.gitattributes`**

```gitattributes
* text=auto eol=lf
*.png binary
*.ttf binary
*.otf binary
```

- [ ] **Step 2: Write the CI workflow (Ubuntu = authoritative golden platform)**

```yaml
name: ci

on:
  push:
    branches: [main]
  pull_request:

jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: packages/flutterwindcss
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - name: Analyze (zero warnings)
        run: flutter analyze --fatal-infos --fatal-warnings
      - name: Format check
        run: dart format --output=none --set-exit-if-changed --line-length 100 .
      - name: Test (incl. goldens)
        run: flutter test
      - name: Upload golden failures
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: golden-failures
          path: packages/flutterwindcss/test/**/failures/
          if-no-files-found: ignore
```

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/ci.yaml .gitattributes
git commit -m "ci: analyze + format + golden tests on ubuntu"
```

- [ ] **Step 4: (After first CI run) reconcile the smoke golden**

If CI's golden job fails on `harness_smoke.png`, download the `golden-failures` artifact, confirm the diff is only sub-pixel platform noise, replace the committed PNG with CI's rendition, and commit:

```bash
git commit -am "test: re-baseline smoke golden from CI (authoritative platform)"
```

---

## MODULE 1 — Token System

> All token classes: `@immutable`, `const` constructor, `==`/`hashCode` (use `Object.hash`), a static `lerp(a, b, t)`, and `///` docs on every public member. Values come from the Tailwind v4 + shadcn defaults cited inline; verify against the spec's §4 tables.

### Task 1.1: Freeze the `FwState` and `FwBreakpoint` enums + scalar scales

**Files:**
- Create: `packages/flutterwindcss/lib/src/tokens/scales.dart`
- Test: `packages/flutterwindcss/test/tokens/scales_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutterwindcss/flutterwindcss.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fwSpace maps 1 unit to 4 logical pixels', () {
    expect(fwSpace(0), 0);
    expect(fwSpace(0.5), 2);
    expect(fwSpace(4), 16);
  });

  test('FwBreakpoint carries Tailwind v4 min-widths', () {
    expect(FwBreakpoint.sm.minWidth, 640);
    expect(FwBreakpoint.md.minWidth, 768);
    expect(FwBreakpoint.lg.minWidth, 1024);
    expect(FwBreakpoint.xl.minWidth, 1280);
    expect(FwBreakpoint.xl2.minWidth, 1536);
  });

  test('FwState enumerates the four engine-sourced interaction states', () {
    expect(FwState.values, hasLength(4));
    expect(FwState.values, containsAll(<FwState>[
      FwState.hovered, FwState.focused, FwState.pressed, FwState.disabled,
    ]));
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd packages/flutterwindcss && flutter test test/tokens/scales_test.dart`
Expected: FAIL — `scales.dart` / symbols undefined.

- [ ] **Step 3: Implement `scales.dart`**

```dart
import 'package:flutter/widgets.dart' show WidgetState;

/// One utility spacing unit in logical pixels. Tailwind v4 base is `0.25rem`;
/// at the 16px root that is 4 logical pixels (spec §4.6). Fractional units
/// (e.g. `0.5`) are supported.
const double fwSpaceUnit = 4.0;

/// Converts a count of utility spacing [units] to logical pixels.
double fwSpace(double units) => units * fwSpaceUnit;

/// Tailwind v4 viewport breakpoints (min-width, mobile-first). Values are the
/// `40/48/64/80/96rem` defaults at a 16px root (spec §4.6).
enum FwBreakpoint {
  /// `>= 640` logical px.
  sm(640),

  /// `>= 768` logical px.
  md(768),

  /// `>= 1024` logical px.
  lg(1024),

  /// `>= 1280` logical px.
  xl(1280),

  /// `>= 1536` logical px.
  xl2(1536);

  const FwBreakpoint(this.minWidth);

  /// The inclusive minimum width at which this breakpoint is active.
  final double minWidth;
}

/// The interaction states the engine sources on its own (spec §6.5). Frozen
/// API contract — exhaustive `switch`es depend on this set (spec §12).
/// Component-managed states (e.g. selected) are fed as raw [WidgetState]s via
/// `whenState`, not added here.
enum FwState {
  /// Pointer is over the box.
  hovered,

  /// Box has input focus.
  focused,

  /// Box is being pressed/activated.
  pressed,

  /// Box is disabled; suppresses the other three (spec §6.3).
  disabled;

  /// The framework [WidgetState] this maps to.
  WidgetState get widgetState => switch (this) {
        FwState.hovered => WidgetState.hovered,
        FwState.focused => WidgetState.focused,
        FwState.pressed => WidgetState.pressed,
        FwState.disabled => WidgetState.disabled,
      };
}

/// Tailwind v4 opacity scale step (`0..100`) as a 0..1 double.
double fwOpacity(int step) => (step.clamp(0, 100)) / 100.0;

/// Tailwind v4 border-width scale (logical px): 0, 1, 2, 4, 8.
const List<double> fwBorderWidths = <double>[0, 1, 2, 4, 8];

/// Tailwind v4 z-index scale, consumed by FwStack/FwPositioned (spec §4.6).
const List<int> fwZIndices = <int>[0, 10, 20, 30, 40, 50];

/// Tailwind v4 blur scale (sigma in logical px): xs..3xl.
enum FwBlur {
  /// 4px. 
  xs(4),
  /// 8px. 
  sm(8),
  /// 12px. 
  md(12),
  /// 16px. 
  lg(16),
  /// 24px. 
  xl(24),
  /// 40px. 
  xl2(40),
  /// 64px. 
  xl3(64);

  const FwBlur(this.sigma);

  /// Gaussian blur sigma in logical pixels.
  final double sigma;
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cd packages/flutterwindcss && flutter test test/tokens/scales_test.dart`
Expected: PASS.

- [ ] **Step 5: Analyze**

Run: `cd packages/flutterwindcss && flutter analyze --fatal-warnings lib/src/tokens/scales.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add packages/flutterwindcss/lib/src/tokens/scales.dart \
        packages/flutterwindcss/test/tokens/scales_test.dart
git commit -m "feat(tokens): scalar scales + frozen FwState/FwBreakpoint enums"
```

### Task 1.2: Bake the Tailwind v4 palette (generator + generated file)

**Files:**
- Create: `tooling/palette/tailwind_v4_palette.json`
- Create: `tooling/bake_palette.dart`
- Create (generated): `packages/flutterwindcss/lib/src/tokens/palette.g.dart`
- Modify: `packages/flutterwindcss/analysis_options.yaml` (exclude generated files)

> Rationale: the palette is sRGB values **published by Tailwind** (no OKLCH→sRGB math in Dart — AGENTS.md §7 / spec R4). The JSON is the committed source of truth; the generator transcribes it to `const Color`s.

- [ ] **Step 1: Create the source JSON (fill ALL hues from Tailwind v4 source)**

Source: Tailwind v4 default theme published hex values. Below is the schema with two hues shown; **add every hue** (`slate, gray, zinc, neutral, stone, red, orange, amber, yellow, lime, green, emerald, teal, cyan, sky, blue, indigo, violet, purple, fuchsia, pink, rose`), shades `50,100,200,300,400,500,600,700,800,900,950`, plus `black`/`white`:

```json
{
  "black": "#000000",
  "white": "#ffffff",
  "neutral": {
    "50": "#fafafa", "100": "#f5f5f5", "200": "#e5e5e5", "300": "#d4d4d4",
    "400": "#a1a1a1", "500": "#737373", "600": "#525252", "700": "#404040",
    "800": "#262626", "900": "#171717", "950": "#0a0a0a"
  },
  "blue": {
    "50": "#eff6ff", "100": "#dbeafe", "200": "#bedbff", "300": "#8ec5ff",
    "400": "#51a2ff", "500": "#2b7fff", "600": "#155dfc", "700": "#1447e6",
    "800": "#193cb8", "900": "#1c398e", "950": "#162456"
  }
}
```

> Transcribe the remaining hues from the Tailwind v4 palette. Spot values will be checked against the spec §4 OKLCH source in Task 1.2 Step 5; if you only have OKLCH, convert once using any external tool (NOT in Dart) and record the hex here.

- [ ] **Step 2: Write the generator**

```dart
// tooling/bake_palette.dart
// Transcribes tooling/palette/tailwind_v4_palette.json into a Dart source file
// of `const Color`s. No color math — pure hex → ARGB transcription.
import 'dart:convert';
import 'dart:io';

void main() {
  final jsonFile = File('tooling/palette/tailwind_v4_palette.json');
  final data = jsonDecode(jsonFile.readAsStringSync()) as Map<String, dynamic>;

  final b = StringBuffer()
    ..writeln('// GENERATED by tooling/bake_palette.dart — do not edit by hand.')
    ..writeln('// Source: tooling/palette/tailwind_v4_palette.json (Tailwind v4).')
    ..writeln("import 'dart:ui' show Color;")
    ..writeln()
    ..writeln('/// Baked Tailwind v4 palette swatches, keyed `hue-shade` (e.g. `blue-500`).')
    ..writeln('/// Single-tone entries (`black`, `white`) are keyed by name.')
    ..writeln('const Map<String, Color> fwBakedPalette = <String, Color>{');

  data.forEach((hue, value) {
    if (value is String) {
      b.writeln("  '$hue': ${_color(value)},");
    } else {
      (value as Map<String, dynamic>).forEach((shade, hex) {
        b.writeln("  '$hue-$shade': ${_color(hex as String)},");
      });
    }
  });
  b.writeln('};');

  File('packages/flutterwindcss/lib/src/tokens/palette.g.dart')
      .writeAsStringSync(b.toString());
  stdout.writeln('Wrote palette.g.dart (${data.length} hue groups).');
}

String _color(String hex) {
  final h = hex.replaceFirst('#', '');
  final argb = 0xFF000000 | int.parse(h, radix: 16);
  return 'Color(0x${argb.toRadixString(16).toUpperCase().padLeft(8, '0')})';
}
```

- [ ] **Step 3: Run the generator**

Run: `dart run tooling/bake_palette.dart`
Expected: `Wrote palette.g.dart (...)` and the file exists with `Color(0xFF...)` entries.

- [ ] **Step 4: Exclude generated files from lint docs rule**

In `packages/flutterwindcss/analysis_options.yaml`, add under `analyzer:`:

```yaml
  exclude:
    - lib/**/*.g.dart
```

- [ ] **Step 5: Write a spot-check test**

```dart
// test/tokens/palette_baked_test.dart
import 'package:flutterwindcss/src/tokens/palette.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:ui';

void main() {
  test('baked palette has known Tailwind v4 sRGB values', () {
    expect(fwBakedPalette['blue-500'], const Color(0xFF2B7FFF));
    expect(fwBakedPalette['neutral-950'], const Color(0xFF0A0A0A));
    expect(fwBakedPalette['white'], const Color(0xFFFFFFFF));
  });

  test('every non-tone hue has all 11 shades', () {
    const shades = ['50','100','200','300','400','500','600','700','800','900','950'];
    for (final hue in ['neutral', 'blue']) {
      for (final s in shades) {
        expect(fwBakedPalette['$hue-$s'], isNotNull, reason: '$hue-$s missing');
      }
    }
  });
}
```

- [ ] **Step 6: Run the spot-check**

Run: `cd packages/flutterwindcss && flutter test test/tokens/palette_baked_test.dart`
Expected: PASS. (If a value mismatches, fix the JSON and re-run Step 3.)

- [ ] **Step 7: Commit**

```bash
git add tooling/palette/tailwind_v4_palette.json tooling/bake_palette.dart \
        packages/flutterwindcss/lib/src/tokens/palette.g.dart \
        packages/flutterwindcss/analysis_options.yaml \
        packages/flutterwindcss/test/tokens/palette_baked_test.dart
git commit -m "feat(tokens): bake Tailwind v4 palette from published hex"
```

### Task 1.3: `FwPalette` typed access

**Files:**
- Create: `packages/flutterwindcss/lib/src/tokens/palette.dart`
- Test: `packages/flutterwindcss/test/tokens/palette_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:ui';
import 'package:flutterwindcss/flutterwindcss.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FwPalette exposes hues and shades', () {
    expect(FwPalette.blue.shade500, const Color(0xFF2B7FFF));
    expect(FwPalette.neutral.shade950, const Color(0xFF0A0A0A));
  });

  test('FwPalette exposes single tones', () {
    expect(FwPalette.white, const Color(0xFFFFFFFF));
    expect(FwPalette.black, const Color(0xFF000000));
  });

  test('FwSwatch.shade(n) returns the nearest defined shade', () {
    expect(FwPalette.blue.shade(500), FwPalette.blue.shade500);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd packages/flutterwindcss && flutter test test/tokens/palette_test.dart`
Expected: FAIL — `FwPalette` undefined.

- [ ] **Step 3: Implement `palette.dart`**

```dart
import 'dart:ui' show Color;

import 'palette.g.dart';

/// A single Tailwind hue with its 11 shades (`50`..`950`).
@immutable
class FwSwatch {
  /// Creates a swatch for [hue] (e.g. `'blue'`), reading baked values.
  const FwSwatch(this.hue);

  /// The hue name, e.g. `'blue'`.
  final String hue;

  Color _s(int shade) {
    final c = fwBakedPalette['$hue-$shade'];
    assert(c != null, 'Missing palette value $hue-$shade');
    return c ?? const Color(0xFF000000);
  }

  /// Lightest shade.
  Color get shade50 => _s(50);
  /// @nodoc
  Color get shade100 => _s(100);
  /// @nodoc
  Color get shade200 => _s(200);
  /// @nodoc
  Color get shade300 => _s(300);
  /// @nodoc
  Color get shade400 => _s(400);
  /// The base/DEFAULT shade.
  Color get shade500 => _s(500);
  /// @nodoc
  Color get shade600 => _s(600);
  /// @nodoc
  Color get shade700 => _s(700);
  /// @nodoc
  Color get shade800 => _s(800);
  /// @nodoc
  Color get shade900 => _s(900);
  /// Darkest shade.
  Color get shade950 => _s(950);

  /// Returns the swatch's [shade] (`50`,`100`,…,`950`).
  Color shade(int shade) => _s(shade);
}

/// The raw Tailwind v4 color palette. Used to build themes and for non-themeable
/// one-offs; components style with semantic tokens, not these (AGENTS.md §3.1).
abstract final class FwPalette {
  /// Pure black (`#000`).
  static const Color black = Color(0xFF000000);

  /// Pure white (`#fff`).
  static const Color white = Color(0xFFFFFFFF);

  /// @nodoc
  static const FwSwatch slate = FwSwatch('slate');
  /// @nodoc
  static const FwSwatch gray = FwSwatch('gray');
  /// @nodoc
  static const FwSwatch zinc = FwSwatch('zinc');
  /// @nodoc
  static const FwSwatch neutral = FwSwatch('neutral');
  /// @nodoc
  static const FwSwatch stone = FwSwatch('stone');
  /// @nodoc
  static const FwSwatch red = FwSwatch('red');
  /// @nodoc
  static const FwSwatch orange = FwSwatch('orange');
  /// @nodoc
  static const FwSwatch amber = FwSwatch('amber');
  /// @nodoc
  static const FwSwatch yellow = FwSwatch('yellow');
  /// @nodoc
  static const FwSwatch lime = FwSwatch('lime');
  /// @nodoc
  static const FwSwatch green = FwSwatch('green');
  /// @nodoc
  static const FwSwatch emerald = FwSwatch('emerald');
  /// @nodoc
  static const FwSwatch teal = FwSwatch('teal');
  /// @nodoc
  static const FwSwatch cyan = FwSwatch('cyan');
  /// @nodoc
  static const FwSwatch sky = FwSwatch('sky');
  /// @nodoc
  static const FwSwatch blue = FwSwatch('blue');
  /// @nodoc
  static const FwSwatch indigo = FwSwatch('indigo');
  /// @nodoc
  static const FwSwatch violet = FwSwatch('violet');
  /// @nodoc
  static const FwSwatch purple = FwSwatch('purple');
  /// @nodoc
  static const FwSwatch fuchsia = FwSwatch('fuchsia');
  /// @nodoc
  static const FwSwatch pink = FwSwatch('pink');
  /// @nodoc
  static const FwSwatch rose = FwSwatch('rose');
}
```

> Add `import 'package:meta/meta.dart' show immutable;` if `@immutable` is unresolved — but `package:flutter/widgets.dart` re-exports it; since this file avoids Flutter, import `package:meta/meta.dart`. Add `meta` to `dependencies` if not transitively present (it is, via flutter). Prefer: `import 'package:flutter/foundation.dart' show immutable;`.

- [ ] **Step 4: Fix the import per the note**

Replace the first import line with:

```dart
import 'package:flutter/foundation.dart' show immutable;
import 'dart:ui' show Color;
```

- [ ] **Step 5: Run to verify it passes**

Run: `cd packages/flutterwindcss && flutter test test/tokens/palette_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add packages/flutterwindcss/lib/src/tokens/palette.dart \
        packages/flutterwindcss/test/tokens/palette_test.dart
git commit -m "feat(tokens): FwPalette typed swatch access"
```

### Task 1.4: `FwColors` (19 semantic tokens) + lerp

**Files:**
- Create: `packages/flutterwindcss/lib/src/tokens/colors.dart`
- Test: `packages/flutterwindcss/test/tokens/colors_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:ui';
import 'package:flutterwindcss/flutterwindcss.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const a = FwColors(
    background: Color(0xFF000000), foreground: Color(0xFFFFFFFF),
    card: Color(0xFF000000), cardForeground: Color(0xFFFFFFFF),
    popover: Color(0xFF000000), popoverForeground: Color(0xFFFFFFFF),
    primary: Color(0xFF000000), primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFF000000), secondaryForeground: Color(0xFFFFFFFF),
    muted: Color(0xFF000000), mutedForeground: Color(0xFFFFFFFF),
    accent: Color(0xFF000000), accentForeground: Color(0xFFFFFFFF),
    destructive: Color(0xFF000000), destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0xFF000000), input: Color(0xFF000000), ring: Color(0xFF000000),
  );

  test('lerp(a, a, .5) == a for every field', () {
    final r = FwColors.lerp(a, a, 0.5);
    expect(r, a);
  });

  test('lerp interpolates primary halfway', () {
    final b = a.copyWith(primary: const Color(0xFFFFFFFF));
    final r = FwColors.lerp(a, b, 0.5);
    expect(r.primary, Color.lerp(const Color(0xFF000000), const Color(0xFFFFFFFF), 0.5));
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd packages/flutterwindcss && flutter test test/tokens/colors_test.dart`
Expected: FAIL — `FwColors` undefined.

- [ ] **Step 3: Implement `colors.dart`**

```dart
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show immutable;

/// The 19 shadcn semantic color tokens — the contract the theme generator
/// targets (spec §4.2, §5). Components reference these, never raw swatches.
@immutable
class FwColors {
  /// Creates a semantic color set. All fields are required; a theme defines
  /// every role.
  const FwColors({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.popoverForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.input,
    required this.ring,
  });

  /// App background.
  final Color background;
  /// Default foreground/text on [background].
  final Color foreground;
  /// Card surface.
  final Color card;
  /// Foreground on [card].
  final Color cardForeground;
  /// Popover/overlay surface.
  final Color popover;
  /// Foreground on [popover].
  final Color popoverForeground;
  /// Primary action color.
  final Color primary;
  /// Foreground on [primary].
  final Color primaryForeground;
  /// Secondary action color.
  final Color secondary;
  /// Foreground on [secondary].
  final Color secondaryForeground;
  /// Muted surface.
  final Color muted;
  /// Foreground on [muted].
  final Color mutedForeground;
  /// Accent surface.
  final Color accent;
  /// Foreground on [accent].
  final Color accentForeground;
  /// Destructive/danger color.
  final Color destructive;
  /// Foreground on [destructive].
  final Color destructiveForeground;
  /// Default border color.
  final Color border;
  /// Form input border color.
  final Color input;
  /// Focus-ring color.
  final Color ring;

  /// Returns a copy with the given fields replaced.
  FwColors copyWith({
    Color? background, Color? foreground, Color? card, Color? cardForeground,
    Color? popover, Color? popoverForeground, Color? primary,
    Color? primaryForeground, Color? secondary, Color? secondaryForeground,
    Color? muted, Color? mutedForeground, Color? accent, Color? accentForeground,
    Color? destructive, Color? destructiveForeground, Color? border,
    Color? input, Color? ring,
  }) {
    return FwColors(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      cardForeground: cardForeground ?? this.cardForeground,
      popover: popover ?? this.popover,
      popoverForeground: popoverForeground ?? this.popoverForeground,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      secondary: secondary ?? this.secondary,
      secondaryForeground: secondaryForeground ?? this.secondaryForeground,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      destructive: destructive ?? this.destructive,
      destructiveForeground: destructiveForeground ?? this.destructiveForeground,
      border: border ?? this.border,
      input: input ?? this.input,
      ring: ring ?? this.ring,
    );
  }

  /// Linearly interpolates every token between [a] and [b] at [t].
  static FwColors lerp(FwColors a, FwColors b, double t) {
    Color l(Color x, Color y) => Color.lerp(x, y, t)!;
    return FwColors(
      background: l(a.background, b.background),
      foreground: l(a.foreground, b.foreground),
      card: l(a.card, b.card),
      cardForeground: l(a.cardForeground, b.cardForeground),
      popover: l(a.popover, b.popover),
      popoverForeground: l(a.popoverForeground, b.popoverForeground),
      primary: l(a.primary, b.primary),
      primaryForeground: l(a.primaryForeground, b.primaryForeground),
      secondary: l(a.secondary, b.secondary),
      secondaryForeground: l(a.secondaryForeground, b.secondaryForeground),
      muted: l(a.muted, b.muted),
      mutedForeground: l(a.mutedForeground, b.mutedForeground),
      accent: l(a.accent, b.accent),
      accentForeground: l(a.accentForeground, b.accentForeground),
      destructive: l(a.destructive, b.destructive),
      destructiveForeground: l(a.destructiveForeground, b.destructiveForeground),
      border: l(a.border, b.border),
      input: l(a.input, b.input),
      ring: l(a.ring, b.ring),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FwColors &&
      other.background == background &&
      other.foreground == foreground &&
      other.card == card &&
      other.cardForeground == cardForeground &&
      other.popover == popover &&
      other.popoverForeground == popoverForeground &&
      other.primary == primary &&
      other.primaryForeground == primaryForeground &&
      other.secondary == secondary &&
      other.secondaryForeground == secondaryForeground &&
      other.muted == muted &&
      other.mutedForeground == mutedForeground &&
      other.accent == accent &&
      other.accentForeground == accentForeground &&
      other.destructive == destructive &&
      other.destructiveForeground == destructiveForeground &&
      other.border == border &&
      other.input == input &&
      other.ring == ring;

  @override
  int get hashCode => Object.hashAll(<Object>[
        background, foreground, card, cardForeground, popover, popoverForeground,
        primary, primaryForeground, secondary, secondaryForeground, muted,
        mutedForeground, accent, accentForeground, destructive,
        destructiveForeground, border, input, ring,
      ]);
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cd packages/flutterwindcss && flutter test test/tokens/colors_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/flutterwindcss/lib/src/tokens/colors.dart \
        packages/flutterwindcss/test/tokens/colors_test.dart
git commit -m "feat(tokens): FwColors 19 semantic tokens + lerp"
```

### Task 1.5: `FwRadii` + lerp

**Files:**
- Create: `packages/flutterwindcss/lib/src/tokens/radii.dart`
- Test: `packages/flutterwindcss/test/tokens/radii_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutterwindcss/flutterwindcss.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromBase derives the shadcn-style set', () {
    final r = FwRadii.fromBase(10);
    expect(r.sm, 6);   // ×0.6
    expect(r.md, 8);   // ×0.8
    expect(r.lg, 10);  // ×1.0
    expect(r.xl, 14);  // ×1.4
    expect(r.none, 0);
    expect(r.full, 9999);
  });

  test('lerp interpolates the base', () {
    final r = FwRadii.lerp(FwRadii.fromBase(0), FwRadii.fromBase(10), 0.5);
    expect(r.lg, 5);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd packages/flutterwindcss && flutter test test/tokens/radii_test.dart`
Expected: FAIL — `FwRadii` undefined.

- [ ] **Step 3: Implement `radii.dart`**

```dart
import 'package:flutter/foundation.dart' show immutable;

/// Border-radius tokens. The `sm/md/lg/xl` set is derived from one shadcn
/// `--radius` base (spec §4.3): `sm ×0.6, md ×0.8, lg ×1.0, xl ×1.4`. The
/// Tailwind v4 named scale is also exposed for utility use.
@immutable
class FwRadii {
  /// Creates a radius set from explicit values. Prefer [FwRadii.fromBase].
  const FwRadii({
    required this.base,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  /// Derives the shadcn-style set from a single [base] radius (logical px).
  factory FwRadii.fromBase(double base) => FwRadii(
        base: base,
        sm: base * 0.6,
        md: base * 0.8,
        lg: base * 1.0,
        xl: base * 1.4,
      );

  /// The shadcn `--radius` this set was derived from.
  final double base;

  /// `base ×0.6`.
  final double sm;
  /// `base ×0.8`.
  final double md;
  /// `base ×1.0`.
  final double lg;
  /// `base ×1.4`.
  final double xl;

  /// No rounding.
  double get none => 0;
  /// Pill/fully-rounded sentinel (`9999`).
  double get full => 9999;

  /// Linearly interpolates the derived set via the [base].
  static FwRadii lerp(FwRadii a, FwRadii b, double t) =>
      FwRadii.fromBase(a.base + (b.base - a.base) * t);

  @override
  bool operator ==(Object other) =>
      other is FwRadii &&
      other.base == base &&
      other.sm == sm &&
      other.md == md &&
      other.lg == lg &&
      other.xl == xl;

  @override
  int get hashCode => Object.hash(base, sm, md, lg, xl);
}

/// The Tailwind v4 named border-radius scale (logical px), independent of theme.
abstract final class FwRadiusScale {
  /// `0.125rem` → 2px.
  static const double xs = 2;
  /// `0.25rem` → 4px.
  static const double sm = 4;
  /// `0.375rem` → 6px.
  static const double md = 6;
  /// `0.5rem` → 8px.
  static const double lg = 8;
  /// `0.75rem` → 12px.
  static const double xl = 12;
  /// `1rem` → 16px.
  static const double xl2 = 16;
  /// `1.5rem` → 24px.
  static const double xl3 = 24;
  /// `2rem` → 32px.
  static const double xl4 = 32;
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cd packages/flutterwindcss && flutter test test/tokens/radii_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/flutterwindcss/lib/src/tokens/radii.dart \
        packages/flutterwindcss/test/tokens/radii_test.dart
git commit -m "feat(tokens): FwRadii derived set + Tailwind named scale + lerp"
```

### Task 1.6: `FwShadows` + lerp

**Files:**
- Create: `packages/flutterwindcss/lib/src/tokens/shadows.dart`
- Test: `packages/flutterwindcss/test/tokens/shadows_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:ui';
import 'package:flutterwindcss/flutterwindcss.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sm matches the Tailwind v4 two-layer shadow', () {
    final sm = FwShadows.defaults.sm;
    expect(sm, hasLength(2));
    expect(sm.first.offset, const Offset(0, 1));
    expect(sm.first.blurRadius, 3);
  });

  test('lerp blends layer-wise', () {
    final r = FwShadows.lerp(FwShadows.none, FwShadows.defaults, 0.5);
    expect(r.sm.first.color.a, closeTo(FwShadows.defaults.sm.first.color.a * 0.5, 0.001));
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd packages/flutterwindcss && flutter test test/tokens/shadows_test.dart`
Expected: FAIL — `FwShadows` undefined.

- [ ] **Step 3: Implement `shadows.dart`**

```dart
import 'package:flutter/painting.dart' show BoxShadow;
import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'dart:ui' show Color, Offset;

/// The Tailwind v4 box-shadow scale as Flutter [BoxShadow] lists (spec §4.4).
@immutable
class FwShadows {
  /// Creates a shadow scale.
  const FwShadows({
    required this.xs2,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xl2,
  });

  /// `shadow-2xs`.
  final List<BoxShadow> xs2;
  /// `shadow-xs`.
  final List<BoxShadow> xs;
  /// `shadow-sm`.
  final List<BoxShadow> sm;
  /// `shadow-md`.
  final List<BoxShadow> md;
  /// `shadow-lg`.
  final List<BoxShadow> lg;
  /// `shadow-xl`.
  final List<BoxShadow> xl;
  /// `shadow-2xl`.
  final List<BoxShadow> xl2;

  static const Color _k = Color(0x00000000);

  /// Tailwind v4 default shadow values (black at documented alphas).
  static const FwShadows defaults = FwShadows(
    xs2: <BoxShadow>[BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1))],
    xs: <BoxShadow>[
      BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2),
    ],
    sm: <BoxShadow>[
      BoxShadow(color: Color(0x1A000000), offset: Offset(0, 1), blurRadius: 3),
      BoxShadow(color: Color(0x1A000000), offset: Offset(0, 1), blurRadius: 2, spreadRadius: -1),
    ],
    md: <BoxShadow>[
      BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 6, spreadRadius: -1),
      BoxShadow(color: Color(0x1A000000), offset: Offset(0, 2), blurRadius: 4, spreadRadius: -2),
    ],
    lg: <BoxShadow>[
      BoxShadow(color: Color(0x1A000000), offset: Offset(0, 10), blurRadius: 15, spreadRadius: -3),
      BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 6, spreadRadius: -4),
    ],
    xl: <BoxShadow>[
      BoxShadow(color: Color(0x1A000000), offset: Offset(0, 20), blurRadius: 25, spreadRadius: -5),
      BoxShadow(color: Color(0x1A000000), offset: Offset(0, 8), blurRadius: 10, spreadRadius: -6),
    ],
    xl2: <BoxShadow>[
      BoxShadow(color: Color(0x40000000), offset: Offset(0, 25), blurRadius: 50, spreadRadius: -12),
    ],
  );

  /// An all-empty scale (used as a lerp origin / `shadow-none`).
  static const FwShadows none = FwShadows(
    xs2: <BoxShadow>[], xs: <BoxShadow>[], sm: <BoxShadow>[], md: <BoxShadow>[],
    lg: <BoxShadow>[], xl: <BoxShadow>[], xl2: <BoxShadow>[],
  );

  static List<BoxShadow> _lerpList(List<BoxShadow> a, List<BoxShadow> b, double t) {
    final n = a.length > b.length ? a.length : b.length;
    return List<BoxShadow>.generate(n, (i) {
      final x = i < a.length ? a[i] : b[i].copyWith(color: _k);
      final y = i < b.length ? b[i] : a[i].copyWith(color: _k);
      return BoxShadow.lerp(x, y, t)!;
    });
  }

  /// Layer-wise interpolation of every step.
  static FwShadows lerp(FwShadows a, FwShadows b, double t) => FwShadows(
        xs2: _lerpList(a.xs2, b.xs2, t),
        xs: _lerpList(a.xs, b.xs, t),
        sm: _lerpList(a.sm, b.sm, t),
        md: _lerpList(a.md, b.md, t),
        lg: _lerpList(a.lg, b.lg, t),
        xl: _lerpList(a.xl, b.xl, t),
        xl2: _lerpList(a.xl2, b.xl2, t),
      );

  @override
  bool operator ==(Object other) =>
      other is FwShadows &&
      listEquals(other.xs2, xs2) &&
      listEquals(other.xs, xs) &&
      listEquals(other.sm, sm) &&
      listEquals(other.md, md) &&
      listEquals(other.lg, lg) &&
      listEquals(other.xl, xl) &&
      listEquals(other.xl2, xl2);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(xs2), Object.hashAll(xs), Object.hashAll(sm),
        Object.hashAll(md), Object.hashAll(lg), Object.hashAll(xl),
        Object.hashAll(xl2),
      );
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cd packages/flutterwindcss && flutter test test/tokens/shadows_test.dart`
Expected: PASS. (If `Color.a` is unavailable, the SDK is pre-3.27; use `((color.value >> 24) & 0xFF) / 255` instead — but environment is Dart 3.11/Flutter 3.24+, so `.a` exists.)

- [ ] **Step 5: Commit**

```bash
git add packages/flutterwindcss/lib/src/tokens/shadows.dart \
        packages/flutterwindcss/test/tokens/shadows_test.dart
git commit -m "feat(tokens): FwShadows Tailwind v4 scale + layer-wise lerp"
```

### Task 1.7: `FwTypography`

**Files:**
- Create: `packages/flutterwindcss/lib/src/tokens/typography.dart`
- Test: `packages/flutterwindcss/test/tokens/typography_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutterwindcss/flutterwindcss.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('font sizes match Tailwind v4 (16px root)', () {
    expect(FwFontSize.base.px, 16);   // 1rem
    expect(FwFontSize.sm.px, 14);     // .875rem
    expect(FwFontSize.xl2.px, 24);    // 1.5rem
  });

  test('base size carries its paired line-height ratio', () {
    expect(FwFontSize.base.lineHeight, closeTo(1.5, 0.0001));
  });

  test('weights and tracking expose Tailwind values', () {
    expect(FwFontWeight.semibold, 600);
    expect(FwTracking.tight, -0.025);
    expect(FwLeading.normal, 1.5);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd packages/flutterwindcss && flutter test test/tokens/typography_test.dart`
Expected: FAIL — symbols undefined.

- [ ] **Step 3: Implement `typography.dart`**

```dart
/// Typography tokens mirroring the Tailwind v4 scales (spec §4.5). At a 16px
/// root, `1rem = 16` logical px. Line-heights are the paired `--text-*-
/// -line-height` ratios.
library;

/// Tailwind v4 font-size steps with paired line-height ratios.
enum FwFontSize {
  /// `0.75rem`.
  xs(12, 1 / 0.75),
  /// `0.875rem`.
  sm(14, 1.25 / 0.875),
  /// `1rem`.
  base(16, 1.5 / 1),
  /// `1.125rem`.
  lg(18, 1.75 / 1.125),
  /// `1.25rem`.
  xl(20, 1.75 / 1.25),
  /// `1.5rem`.
  xl2(24, 2 / 1.5),
  /// `1.875rem`.
  xl3(30, 2.25 / 1.875),
  /// `2.25rem`.
  xl4(36, 2.5 / 2.25),
  /// `3rem`.
  xl5(48, 1),
  /// `3.75rem`.
  xl6(60, 1),
  /// `4.5rem`.
  xl7(72, 1),
  /// `6rem`.
  xl8(96, 1),
  /// `8rem`.
  xl9(128, 1);

  const FwFontSize(this.px, this.lineHeight);

  /// Font size in logical pixels.
  final double px;

  /// Paired line-height as a multiple of [px].
  final double lineHeight;
}

/// Tailwind v4 font weights.
abstract final class FwFontWeight {
  /// 100. 
  static const int thin = 100;
  /// 200. 
  static const int extralight = 200;
  /// 300. 
  static const int light = 300;
  /// 400. 
  static const int normal = 400;
  /// 500. 
  static const int medium = 500;
  /// 600. 
  static const int semibold = 600;
  /// 700. 
  static const int bold = 700;
  /// 800. 
  static const int extrabold = 800;
  /// 900. 
  static const int black = 900;
}

/// Tailwind v4 letter-spacing (`em`).
abstract final class FwTracking {
  /// -0.05em. 
  static const double tighter = -0.05;
  /// -0.025em. 
  static const double tight = -0.025;
  /// 0. 
  static const double normal = 0;
  /// 0.025em. 
  static const double wide = 0.025;
  /// 0.05em. 
  static const double wider = 0.05;
  /// 0.1em. 
  static const double widest = 0.1;
}

/// Tailwind v4 line-height multipliers.
abstract final class FwLeading {
  /// 1.25. 
  static const double tight = 1.25;
  /// 1.375. 
  static const double snug = 1.375;
  /// 1.5. 
  static const double normal = 1.5;
  /// 1.625. 
  static const double relaxed = 1.625;
  /// 2.0. 
  static const double loose = 2.0;
}

/// Font-family *names* only — the engine never bundles fonts (spec §4.5).
abstract final class FwFontFamily {
  /// Default UI sans family name. Host wires the actual font.
  static const String sans = 'sans-serif';
  /// Serif family name.
  static const String serif = 'serif';
  /// Monospace family name.
  static const String mono = 'monospace';
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cd packages/flutterwindcss && flutter test test/tokens/typography_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/flutterwindcss/lib/src/tokens/typography.dart \
        packages/flutterwindcss/test/tokens/typography_test.dart
git commit -m "feat(tokens): FwTypography Tailwind v4 type scales"
```

### Task 1.8: `FwTokens` bundle + light/dark + lerp

**Files:**
- Create: `packages/flutterwindcss/lib/src/tokens/tokens.dart`
- Test: `packages/flutterwindcss/test/tokens/tokens_test.dart`

> The `light`/`dark` values are the shadcn default (neutral) theme, composed **purely from baked `const` palette literals** (spec §4.7 / R4). The values below are the shadcn defaults expressed against `FwPalette`; verify each role against the spec §5 contract.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutterwindcss/flutterwindcss.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light and dark are distinct const themes', () {
    expect(FwTokens.light, isNot(equals(FwTokens.dark)));
    expect(FwTokens.light.colors.background, isNot(FwTokens.dark.colors.background));
  });

  test('radii derive from the theme base', () {
    expect(FwTokens.light.radii.base, FwTokens.light.radiusBase);
  });

  test('lerp(light, dark, 0) == light and (.,.,1) == dark', () {
    expect(FwTokens.lerp(FwTokens.light, FwTokens.dark, 0).colors.background,
        FwTokens.light.colors.background);
    expect(FwTokens.lerp(FwTokens.light, FwTokens.dark, 1).colors.background,
        FwTokens.dark.colors.background);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd packages/flutterwindcss && flutter test test/tokens/tokens_test.dart`
Expected: FAIL — `FwTokens` undefined.

- [ ] **Step 3: Implement `tokens.dart`**

```dart
import 'package:flutter/foundation.dart' show immutable;

import 'colors.dart';
import 'palette.dart';
import 'radii.dart';
import 'shadows.dart';
import 'typography.dart';

/// The per-theme resolved token bundle a component reads via `context.fw`
/// (spec §4.7). Theme-independent scales (palette, named radii, type, blur,
/// z, border-width) are exposed by their own classes, not here.
@immutable
class FwTokens {
  /// Creates a token bundle.
  const FwTokens({
    required this.colors,
    required this.radii,
    required this.shadows,
    required this.typography,
    required this.radiusBase,
  });

  /// Semantic colors for this theme.
  final FwColors colors;
  /// Radius set derived from [radiusBase].
  final FwRadii radii;
  /// Box-shadow scale.
  final FwShadows shadows;
  /// Typography marker (scales are static; present for future per-theme type).
  final FwTypographyTheme typography;
  /// The shadcn `--radius` this theme was built from (logical px).
  final double radiusBase;

  /// The stock shadcn-neutral **light** theme. Composed from baked `const`
  /// palette literals — no runtime color computation (spec §4.7 / R4).
  static const FwTokens light = FwTokens(
    radiusBase: 8,
    radii: FwRadii(base: 8, sm: 4.8, md: 6.4, lg: 8, xl: 11.2),
    shadows: FwShadows.defaults,
    typography: FwTypographyTheme.standard,
    colors: FwColors(
      background: FwPalette.white,
      foreground: Color(0xFF0A0A0A), // neutral-950
      card: FwPalette.white,
      cardForeground: Color(0xFF0A0A0A),
      popover: FwPalette.white,
      popoverForeground: Color(0xFF0A0A0A),
      primary: Color(0xFF171717), // neutral-900
      primaryForeground: Color(0xFFFAFAFA), // neutral-50
      secondary: Color(0xFFF5F5F5), // neutral-100
      secondaryForeground: Color(0xFF171717),
      muted: Color(0xFFF5F5F5),
      mutedForeground: Color(0xFF737373), // neutral-500
      accent: Color(0xFFF5F5F5),
      accentForeground: Color(0xFF171717),
      destructive: Color(0xFFE7000B), // red-600-ish per shadcn
      destructiveForeground: FwPalette.white,
      border: Color(0xFFE5E5E5), // neutral-200
      input: Color(0xFFE5E5E5),
      ring: Color(0xFFA1A1A1), // neutral-400
    ),
  );

  /// The stock shadcn-neutral **dark** theme.
  static const FwTokens dark = FwTokens(
    radiusBase: 8,
    radii: FwRadii(base: 8, sm: 4.8, md: 6.4, lg: 8, xl: 11.2),
    shadows: FwShadows.defaults,
    typography: FwTypographyTheme.standard,
    colors: FwColors(
      background: Color(0xFF0A0A0A), // neutral-950
      foreground: Color(0xFFFAFAFA),
      card: Color(0xFF171717),
      cardForeground: Color(0xFFFAFAFA),
      popover: Color(0xFF171717),
      popoverForeground: Color(0xFFFAFAFA),
      primary: Color(0xFFFAFAFA),
      primaryForeground: Color(0xFF171717),
      secondary: Color(0xFF262626), // neutral-800
      secondaryForeground: Color(0xFFFAFAFA),
      muted: Color(0xFF262626),
      mutedForeground: Color(0xFFA1A1A1),
      accent: Color(0xFF262626),
      accentForeground: Color(0xFFFAFAFA),
      destructive: Color(0xFFFF6467), // red-400-ish per shadcn dark
      destructiveForeground: Color(0xFF0A0A0A),
      border: Color(0x1AFFFFFF), // white/10
      input: Color(0x26FFFFFF), // white/15
      ring: Color(0xFF737373),
    ),
  );

  /// Interpolates two themes (drives FwAnimatedTheme later).
  static FwTokens lerp(FwTokens a, FwTokens b, double t) => FwTokens(
        colors: FwColors.lerp(a.colors, b.colors, t),
        radii: FwRadii.lerp(a.radii, b.radii, t),
        shadows: FwShadows.lerp(a.shadows, b.shadows, t),
        typography: FwTypographyTheme.standard,
        radiusBase: a.radiusBase + (b.radiusBase - a.radiusBase) * t,
      );

  @override
  bool operator ==(Object other) =>
      other is FwTokens &&
      other.colors == colors &&
      other.radii == radii &&
      other.shadows == shadows &&
      other.radiusBase == radiusBase;

  @override
  int get hashCode => Object.hash(colors, radii, shadows, radiusBase);
}

/// Placeholder per-theme typography marker. Type scales are static
/// (`FwFontSize` etc.); this exists so a theme can carry a default family in a
/// later module without changing the `FwTokens` shape.
@immutable
class FwTypographyTheme {
  /// Creates a typography theme with a default sans [family].
  const FwTypographyTheme({required this.family});

  /// The default font family name.
  final String family;

  /// The standard theme using the platform sans family.
  static const FwTypographyTheme standard = FwTypographyTheme(family: FwFontFamily.sans);

  @override
  bool operator ==(Object other) =>
      other is FwTypographyTheme && other.family == family;

  @override
  int get hashCode => family.hashCode;
}
```

> Note: `Color` is used unqualified here; add `import 'dart:ui' show Color;` at the top. The neutral hex values above are the baked palette literals (cross-checked against Task 1.2's JSON); where a comment cites a palette shade, the literal must equal `fwBakedPalette['<that shade>']` — Task 1.8 Step 5 asserts a sample.

- [ ] **Step 4: Add the missing import**

At the top of `tokens.dart`, add:

```dart
import 'dart:ui' show Color;
```

- [ ] **Step 5: Add a value-provenance assertion to the test**

Append to `test/tokens/tokens_test.dart`:

```dart
  test('light theme literals match baked palette swatches', () {
    expect(FwTokens.light.colors.border, FwPalette.neutral.shade200);
    expect(FwTokens.dark.colors.background, FwPalette.neutral.shade950);
  });
```

- [ ] **Step 6: Run to verify it passes**

Run: `cd packages/flutterwindcss && flutter test test/tokens/tokens_test.dart`
Expected: PASS. (If the provenance assertion fails, correct the literal in `tokens.dart` to match the baked swatch.)

- [ ] **Step 7: Commit**

```bash
git add packages/flutterwindcss/lib/src/tokens/tokens.dart \
        packages/flutterwindcss/test/tokens/tokens_test.dart
git commit -m "feat(tokens): FwTokens bundle + shadcn light/dark + lerp"
```

### Task 1.9: Full-package green gate

**Files:** none (verification only).

- [ ] **Step 1: Analyze the whole package**

Run: `cd packages/flutterwindcss && flutter analyze --fatal-infos --fatal-warnings`
Expected: `No issues found!` (Barrel exports now all resolve.)

- [ ] **Step 2: Format check**

Run: `cd packages/flutterwindcss && dart format --output=none --set-exit-if-changed --line-length 100 .`
Expected: exit 0 (no files would change). If it fails, run `dart format --line-length 100 .` and re-commit.

- [ ] **Step 3: Run the full suite**

Run: `cd packages/flutterwindcss && flutter test`
Expected: All tests PASS (scales, palette, colors, radii, shadows, typography, tokens, smoke golden).

- [ ] **Step 4: Commit any format fixups**

```bash
git add -A
git commit -m "chore: module 1 format + analyze green" --allow-empty
```

---

## Self-Review

**Spec coverage (spec §4, §10, §12 modules 0–1):**
- §4.1 FwPalette → Tasks 1.2, 1.3. §4.2 FwColors → 1.4. §4.3 FwRadii (derived + named) → 1.5. §4.4 FwShadows → 1.6. §4.5 FwTypography → 1.7. §4.6 scales/breakpoints/states/blur/z/border-width → 1.1. §4.7 FwTokens + light/dark + lerp → 1.8.
- §10 harness (pinned-font hook, CI-authoritative goldens, smoke golden) → Tasks 0.5–0.7.
- §12 module 0 scaffold → 0.1–0.7; enum freeze → 1.1.
- Deferred to later module plans (correctly out of scope here): theme access (§5, module 2), resolver/`.tw` (§6, module 3+), utilities, layout widgets, animated theming. The barrel currently exports only tokens.

**Placeholder scan:** No "TBD/TODO/handle appropriately". The only "fill in" is Task 1.2 Step 1 (transcribe remaining palette hues) — that is a data-entry instruction with an explicit source and a spot-check test, not a code placeholder.

**Type consistency:** `FwColors.copyWith`/`lerp`, `FwRadii.fromBase`/`lerp`, `FwShadows.defaults`/`none`/`lerp`, `FwTokens.light`/`dark`/`lerp`, `FwState`/`FwBreakpoint`/`FwBlur`, `FwPalette`/`FwSwatch.shade*`, `FwFontSize.px/lineHeight` — names are used identically across tasks and the barrel exports match the files created.

**Known follow-ups for the next plan (module 2 — theme access):** the barrel will add `theme/*`; `context.fw` consumes `FwTokens` from Task 1.8; `FwThemeExtension.lerp` will reuse `FwTokens.lerp`. No rework of Module 1 needed.

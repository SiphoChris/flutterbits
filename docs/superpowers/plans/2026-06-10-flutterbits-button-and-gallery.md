# flutterbits `Button` + `apps/gallery` — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the flutterbits component app (`apps/gallery`) and author the canonical `Button` component — the template every later component imitates — with full behavioral tests and golden coverage.

**Architecture:** `Button` is a Material-free `StatefulWidget` that sources its own interaction states (hover/focus/pressed/disabled) via `FocusableActionDetector` + a tap detector (AGENTS.md §6 — action-bearing components own their states), resolves a `(variant, size, states)` → visual treatment with exhaustive `switch`es in plain Dart, and renders a single styled box through the `flutterwindcss` `.tw` chain using only semantic tokens (`context.fw.colors.*`). `apps/gallery` is a new pub-workspace member (mirroring `apps/example`) that hosts the component, its widget smoke test, and its goldens.

**Tech Stack:** Dart/Flutter (≥3.29/3.7), `flutterwindcss` (path dep), `package:flutter/widgets.dart` + `package:flutter/services.dart` (keyboard), `flutter_test` goldens. No Material, no other deps.

**Scope note (no silent reduction):** This plan delivers `Button` + `apps/gallery` end-to-end. The **registry source-of-truth file (`registry/button.dart`), the manifest JSON, and `tooling/build_registry.dart` are deliberately moved to the next plan** (the registry + CLI slice), because the manifest's metadata-source (where `description`/`pubDeps`/`registryDeps` come from when "generated from the .dart") is a registry-spec decision best made alongside the CLI — not invented here. For this plan, `Button` is authored at its consumer-shaped home `apps/gallery/lib/components/ui/button.dart`; the registry/CLI plan promotes it to `registry/` and adds the install path. This is an explicit, recorded adjustment to the original "manifest in plan 1" scope.

**Reconciliation this plan performs (no-drift):** `default` is a Dart reserved word and cannot be an enum constant, so the shadcn `default` variant/size map to `primary` (variant) and `md` (size). Task 7 updates the charter §3.2 + AGENTS.md §where-named to record this. Every other shadcn variant/size name is used verbatim.

---

## File Structure

| File | Responsibility |
|---|---|
| `apps/gallery/pubspec.yaml` | New workspace member `flutterbits_gallery`; deps `flutter` + `flutterwindcss` (path); `uses-material-design: false`. |
| `pubspec.yaml` (root) | Add `apps/gallery` to the `workspace:` list. |
| `apps/gallery/analysis_options.yaml` | Lints (mirror `apps/example`). |
| `apps/gallery/lib/components/ui/button.dart` | The `Button` component + `ButtonVariant`/`ButtonSize` enums. The canonical template. |
| `apps/gallery/lib/main.dart` | Material-free `WidgetsApp` host rendering a Button gallery (so CI compiles the component). |
| `apps/gallery/test/button_behavior_test.dart` | Widget tests: renders label, tap fires, disabled blocks, keyboard activates, Semantics flags. |
| `apps/gallery/test/button_golden_test.dart` | Goldens: every variant × size × brightness grid, plus focused-ring and RTL. |
| `apps/gallery/test/gallery_smoke_test.dart` | The app builds + renders without exceptions (light/dark/LTR/RTL). |

---

## Task 0: Scaffold `apps/gallery` and register it in the workspace

**Files:**
- Create: `apps/gallery/pubspec.yaml`
- Modify: `pubspec.yaml` (root, `workspace:` list)
- Create: `apps/gallery/analysis_options.yaml`
- Create: `apps/gallery/lib/main.dart` (placeholder for now)

- [ ] **Step 1: Create `apps/gallery/pubspec.yaml`**

```yaml
name: flutterbits_gallery
description: >-
  flutterbits COMPONENT gallery — a Material-free Flutter app showcasing the
  copy-paste components, and the golden-test + compile target for the registry.
publish_to: none
version: 1.0.0+1

# Joins the repo's pub workspace (root pubspec.yaml `workspace:`).
resolution: workspace

environment:
  # Match the toolchain floor (AGENTS.md §2): Flutter 3.29 / Dart 3.7.
  sdk: '>=3.7.0 <4.0.0'
  flutter: '>=3.29.0'

dependencies:
  flutter:
    sdk: flutter
  # The styling engine every component styles through.
  flutterwindcss:
    path: ../../packages/flutterwindcss

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  # Material-free: components run on the pure path (WidgetsApp + FwTheme).
  uses-material-design: false
```

- [ ] **Step 2: Add `apps/gallery` to the root workspace list**

In `pubspec.yaml` (root), under `workspace:`, add the line so it reads:

```yaml
workspace:
  - packages/flutterwindcss
  - packages/flutterwindcss/example
  - apps/example
  - apps/gallery
```

- [ ] **Step 3: Create `apps/gallery/analysis_options.yaml`**

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-raw-types: true
```

- [ ] **Step 4: Create a placeholder `apps/gallery/lib/main.dart`** (replaced in Task 6)

```dart
import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

void main() => runApp(const GalleryApp());

/// Material-free root for the flutterbits component gallery.
class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FwTheme(
      tokens: FwTokens.light,
      child: WidgetsApp(
        title: 'flutterbits gallery',
        color: const Color(0xFF2563EB),
        debugShowCheckedModeBanner: false,
        pageRouteBuilder: <T extends Object?>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          );
        },
        home: Builder(
          builder: (context) => ColoredBox(
            color: context.fw.colors.background,
            child: const Center(child: Text('flutterbits gallery')),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Resolve and analyze**

Run: `flutter pub get` (from repo root) then `cd apps/gallery && flutter analyze --fatal-infos --fatal-warnings`
Expected: deps resolve; analyze reports **No issues found**.

- [ ] **Step 6: Commit**

```bash
git add apps/gallery pubspec.yaml
git commit -m "feat(gallery): scaffold apps/gallery (flutterbits component target)"
```

---

## Task 1: `Button` enums + skeleton + first behavior test

**Files:**
- Create: `apps/gallery/lib/components/ui/button.dart`
- Create: `apps/gallery/test/button_behavior_test.dart`

- [ ] **Step 1: Write the failing test** (`button_behavior_test.dart`)

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';
import 'package:flutterbits_gallery/components/ui/button.dart';

Widget _host(Widget child) => FwTheme(
  tokens: FwTokens.light,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Center(child: child),
    ),
  ),
);

void main() {
  testWidgets('renders its label and reports button semantics', (t) async {
    await t.pumpWidget(_host(Button(onPressed: () {}, child: const Text('Save'))));
    expect(find.text('Save'), findsOneWidget);

    final semantics = t.getSemantics(find.text('Save'));
    expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(semantics.hasFlag(SemanticsFlag.isEnabled), isTrue);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `cd apps/gallery && flutter test test/button_behavior_test.dart`
Expected: FAIL — `button.dart` / `Button` does not exist (compile error).

- [ ] **Step 3: Write the minimal skeleton** (`button.dart`)

```dart
import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

/// shadcn's button variants. `primary` is shadcn's `default` (`default` is a
/// Dart reserved word, so it cannot be an enum constant).
enum ButtonVariant { primary, secondary, destructive, outline, ghost, link }

/// shadcn's button sizes. `md` is shadcn's `default` size (same reserved-word
/// reason as above).
enum ButtonSize { sm, md, lg, icon }

/// A Material-free, themeable button — shadcn parity. Copy-paste source you own.
///
/// Sources its own interaction states (hover/focus/pressed/disabled) and styles a
/// single box through `.tw` using semantic tokens only (AGENTS.md §3.1/§6).
class Button extends StatefulWidget {
  const Button({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.md,
    this.semanticLabel,
  });

  /// The button's content (a `Text`, an icon widget, or a row of both).
  final Widget child;

  /// Tapped/activated callback. `null` disables the button.
  final VoidCallback? onPressed;

  final ButtonVariant variant;
  final ButtonSize size;

  /// Optional accessibility label (defaults to the child's own semantics).
  final String? semanticLabel;

  /// Whether the button is interactive.
  bool get enabled => onPressed != null;

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: widget.child,
    );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd apps/gallery && flutter test test/button_behavior_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add apps/gallery/lib/components/ui/button.dart apps/gallery/test/button_behavior_test.dart
git commit -m "feat(button): skeleton + variant/size enums + semantics"
```

---

## Task 2: Tap and disabled behavior

**Files:**
- Modify: `apps/gallery/lib/components/ui/button.dart`
- Modify: `apps/gallery/test/button_behavior_test.dart`

- [ ] **Step 1: Add failing tests**

Append to `button_behavior_test.dart`'s `main()`:

```dart
  testWidgets('fires onPressed when tapped', (t) async {
    var taps = 0;
    await t.pumpWidget(_host(Button(onPressed: () => taps++, child: const Text('Go'))));
    await t.tap(find.text('Go'));
    expect(taps, 1);
  });

  testWidgets('disabled (onPressed null) does not fire and reports disabled', (t) async {
    await t.pumpWidget(_host(const Button(onPressed: null, child: Text('Nope'))));
    await t.tap(find.text('Nope'));
    // No callback to fire; assert it is reported disabled to a11y.
    final semantics = t.getSemantics(find.text('Nope'));
    expect(semantics.hasFlag(SemanticsFlag.isEnabled), isFalse);
  });
```

- [ ] **Step 2: Run to verify failure**

Run: `cd apps/gallery && flutter test test/button_behavior_test.dart`
Expected: FAIL — `fires onPressed` fails (no tap wiring yet).

- [ ] **Step 3: Wire the tap detector in `button.dart`**

Replace `_ButtonState.build` with:

```dart
  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed, // null when disabled → inert
        child: widget.child,
      ),
    );
  }
```

- [ ] **Step 4: Run to verify pass**

Run: `cd apps/gallery && flutter test test/button_behavior_test.dart`
Expected: PASS (all four tests).

- [ ] **Step 5: Commit**

```bash
git add apps/gallery/lib/components/ui/button.dart apps/gallery/test/button_behavior_test.dart
git commit -m "feat(button): tap + disabled behavior"
```

---

## Task 3: Keyboard activation (Enter / Space) + focus/hover/press sourcing

**Files:**
- Modify: `apps/gallery/lib/components/ui/button.dart`
- Modify: `apps/gallery/test/button_behavior_test.dart`

- [ ] **Step 1: Add a failing keyboard test**

Append to `main()`:

```dart
  testWidgets('activates via keyboard (Enter) when focused', (t) async {
    var taps = 0;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await t.pumpWidget(_host(
      Focus(focusNode: focus, child: Button(onPressed: () => taps++, child: const Text('K'))),
    ));
    focus.requestFocus();
    await t.pump();
    // The button's own FocusableActionDetector takes focus on traversal; send Enter.
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump();
    expect(taps, 1);
  });
```

Add the import at the top of the test file:

```dart
import 'package:flutter/services.dart';
```

- [ ] **Step 2: Run to verify failure**

Run: `cd apps/gallery && flutter test test/button_behavior_test.dart`
Expected: FAIL — Enter does nothing (no `FocusableActionDetector`/actions yet).

- [ ] **Step 3: Add `FocusableActionDetector` + state sourcing in `button.dart`**

Add `import 'package:flutter/services.dart';` at the top. Replace `_ButtonState` with:

```dart
class _ButtonState extends State<Button> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  void _set(VoidCallback f) {
    if (mounted) setState(f);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowHoverHighlight: (h) => _set(() => _hovered = h),
        onShowFocusHighlight: (f) => _set(() => _focused = f),
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: enabled ? (_) => _set(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => _set(() => _pressed = false) : null,
          onTapCancel: enabled ? () => _set(() => _pressed = false) : null,
          child: widget.child,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run to verify pass**

Run: `cd apps/gallery && flutter test test/button_behavior_test.dart`
Expected: PASS (all five tests).

- [ ] **Step 5: Commit**

```bash
git add apps/gallery/lib/components/ui/button.dart apps/gallery/test/button_behavior_test.dart
git commit -m "feat(button): keyboard activation + hover/focus/press sourcing"
```

---

## Task 4: Variant + size styling through `.tw` (the visual core)

**Files:**
- Modify: `apps/gallery/lib/components/ui/button.dart`
- Modify: `apps/gallery/test/button_behavior_test.dart`

This task adds the styled box. There is no color-assert in widget tests (that is the goldens' job, Task 5); the behavioral test here asserts the styled box is present and the existing behavior still holds.

- [ ] **Step 1: Add a structural test**

Append to `main()`:

```dart
  testWidgets('renders a single styled box (FwStyled) per variant', (t) async {
    for (final v in ButtonVariant.values) {
      await t.pumpWidget(_host(Button(variant: v, onPressed: () {}, child: const Text('x'))));
      expect(find.byType(FwStyled), findsOneWidget, reason: 'variant $v');
    }
  });
```

- [ ] **Step 2: Run to verify failure**

Run: `cd apps/gallery && flutter test test/button_behavior_test.dart`
Expected: FAIL — no `FwStyled` in the tree (child is rendered raw).

- [ ] **Step 3: Implement the styling build**

In `button.dart`, replace the `GestureDetector(... child: widget.child)` so its `child:` is the styled box, by inserting a `_styled(context)` helper and using it. Add this method to `_ButtonState` and call it:

```dart
  /// The single styled box: resolves (variant, size, states) → one `.tw` chain.
  Widget _styled(BuildContext context) {
    final c = context.fw.colors;
    final enabled = widget.enabled;

    // Base treatment per variant (transparent fill uses the one allowed literal,
    // Color(0x00000000), per AGENTS.md §3.1).
    const transparent = Color(0x00000000);
    late Color baseBg;
    late Color baseFg;
    Color? borderColor;
    var isLink = false;
    switch (widget.variant) {
      case ButtonVariant.primary:
        baseBg = c.primary;
        baseFg = c.primaryForeground;
      case ButtonVariant.secondary:
        baseBg = c.secondary;
        baseFg = c.secondaryForeground;
      case ButtonVariant.destructive:
        baseBg = c.destructive;
        baseFg = c.destructiveForeground;
      case ButtonVariant.outline:
        baseBg = transparent;
        baseFg = c.foreground;
        borderColor = c.border;
      case ButtonVariant.ghost:
        baseBg = transparent;
        baseFg = c.foreground;
      case ButtonVariant.link:
        baseBg = transparent;
        baseFg = c.primary;
        isLink = true;
    }

    // Hover/press treatment (shadcn: filled → /90 (secondary /80); outline/ghost
    // → accent; link → underline).
    var bg = baseBg;
    var fg = baseFg;
    final interacting = enabled && (_hovered || _pressed);
    if (interacting) {
      switch (widget.variant) {
        case ButtonVariant.primary:
        case ButtonVariant.destructive:
          bg = baseBg.withValues(alpha: 0.9);
        case ButtonVariant.secondary:
          bg = baseBg.withValues(alpha: 0.8);
        case ButtonVariant.outline:
        case ButtonVariant.ghost:
          bg = c.accent;
          fg = c.accentForeground;
        case ButtonVariant.link:
          break; // underline handled below
      }
    }
    final underlineNow = isLink && enabled && (_hovered || _focused);

    // Content: shrink-wrap width, center vertically within the fixed height.
    final inner = widget.size == ButtonSize.icon
        ? Center(child: widget.child)
        : Center(widthFactor: 1.0, child: widget.child);

    var box = inner.tw
        .bg(bg)
        .text(fg)
        .textSize(FwFontSize.sm.px)
        .weight(FwFontWeight.medium)
        .roundedMd;

    box = switch (widget.size) {
      ButtonSize.sm => box.h(9).px(3),
      ButtonSize.md => box.h(10).px(4),
      ButtonSize.lg => box.h(11).px(8),
      ButtonSize.icon => box.size(10),
    };

    if (borderColor != null) box = box.border(1, color: borderColor);
    if (underlineNow) box = box.underline;
    if (_focused && enabled) {
      box = box.ring(2, color: c.ring, offset: 2, offsetColor: c.background);
    }
    if (!enabled) box = box.opacity(0.5);

    return box;
  }
```

Then change the `GestureDetector`'s child from `widget.child` to `_styled(context)`:

```dart
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: enabled ? (_) => _set(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => _set(() => _pressed = false) : null,
          onTapCancel: enabled ? () => _set(() => _pressed = false) : null,
          child: _styled(context),
        ),
```

- [ ] **Step 4: Run the full behavior suite to verify pass**

Run: `cd apps/gallery && flutter test test/button_behavior_test.dart`
Expected: PASS (all six tests — label/semantics, tap, disabled, keyboard, styled-box).

- [ ] **Step 5: Analyze (zero-warning bar) + format**

Run: `cd apps/gallery && flutter analyze --fatal-infos --fatal-warnings` then `dart format --line-length 100 lib test`
Expected: No issues found; formatter makes no further changes after re-run.

- [ ] **Step 6: Commit**

```bash
git add apps/gallery/lib/components/ui/button.dart apps/gallery/test/button_behavior_test.dart
git commit -m "feat(button): variant/size/state styling via .tw + semantic tokens"
```

---

## Task 5: Golden coverage (every variant × size × brightness, + focus ring + RTL)

**Files:**
- Create: `apps/gallery/test/button_golden_test.dart`

> **Golden authority:** goldens are generated/verified on **CI Linux** (AGENTS.md §9). A local `--update-goldens` is **non-authoritative** — generate the baseline locally to author the test, but the committed baseline must come from CI (or be regenerated there). Note this in the PR.

- [ ] **Step 1: Write the golden test**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';
import 'package:flutterbits_gallery/components/ui/button.dart';

Widget _frame(FwTokens tokens, TextDirection dir, Widget child) => FwTheme(
  tokens: tokens,
  child: Directionality(
    textDirection: dir,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: ColoredBox(
        color: tokens.colors.background,
        child: Center(child: Padding(padding: const EdgeInsets.all(16), child: child)),
      ),
    ),
  ),
);

/// One row per variant; one column per size. Disabled appears in its own row.
Widget _grid() {
  Widget cell(ButtonVariant v, ButtonSize s) => Button(
    variant: v,
    size: s,
    onPressed: () {},
    child: s == ButtonSize.icon ? const Text('+') : Text(v.name),
  );
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final v in ButtonVariant.values)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in ButtonSize.values)
                Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: cell(v, s)),
            ],
          ),
        ),
      // A disabled row (primary across sizes).
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in ButtonSize.values)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Button(size: s, onPressed: null, child: s == ButtonSize.icon ? const Text('+') : const Text('off')),
              ),
          ],
        ),
      ),
    ],
  );
}

void main() {
  testWidgets('button grid — light LTR', (t) async {
    await t.binding.setSurfaceSize(const Size(520, 420));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(_frame(FwTokens.light, TextDirection.ltr, _grid()));
    await expectLater(find.byType(Column).first, matchesGoldenFile('goldens/button_grid_light.png'));
  });

  testWidgets('button grid — dark LTR', (t) async {
    await t.binding.setSurfaceSize(const Size(520, 420));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(_frame(FwTokens.dark, TextDirection.ltr, _grid()));
    await expectLater(find.byType(Column).first, matchesGoldenFile('goldens/button_grid_dark.png'));
  });

  testWidgets('button grid — light RTL (padding/border mirror)', (t) async {
    await t.binding.setSurfaceSize(const Size(520, 420));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(_frame(FwTokens.light, TextDirection.rtl, _grid()));
    await expectLater(find.byType(Column).first, matchesGoldenFile('goldens/button_grid_rtl.png'));
  });
}
```

- [ ] **Step 2: Generate the baseline locally (to author), then run to verify**

Run: `cd apps/gallery && flutter test --update-goldens test/button_golden_test.dart`
Then inspect the three PNGs under `apps/gallery/test/goldens/` (open them) and confirm: filled variants show token colors, outline shows a border, link is underlined-on-default? (no — link underlines only on hover/focus, so the static golden shows it plain), disabled row is dimmed, RTL mirrors padding/border.
Then: `flutter test test/button_golden_test.dart` → Expected: PASS against the just-written baseline.

- [ ] **Step 3: Commit (baseline regenerated on CI)**

```bash
git add apps/gallery/test/button_golden_test.dart apps/gallery/test/goldens/
git commit -m "test(button): golden grid (variant x size x brightness + RTL)"
```

---

## Task 6: Render `Button` in the gallery app + smoke test

**Files:**
- Modify: `apps/gallery/lib/main.dart`
- Create: `apps/gallery/test/gallery_smoke_test.dart`

- [ ] **Step 1: Write the failing smoke test**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbits_gallery/main.dart';

void main() {
  testWidgets('gallery builds and renders without exceptions', (t) async {
    await t.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(const GalleryApp());
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    // Every variant label is on screen.
    expect(find.text('primary'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `cd apps/gallery && flutter test test/gallery_smoke_test.dart`
Expected: FAIL — the placeholder home shows no buttons (`find.text('primary')` finds nothing).

- [ ] **Step 3: Replace `main.dart`'s `home` with a real Button gallery**

Replace the `home:` `Builder` in `main.dart` with a scrolling gallery:

```dart
        home: Builder(
          builder: (context) => ColoredBox(
            color: context.fw.colors.background,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final v in ButtonVariant.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            for (final s in ButtonSize.values)
                              Button(
                                variant: v,
                                size: s,
                                onPressed: () {},
                                child: s == ButtonSize.icon ? const Text('+') : Text(v.name),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
```

Add the import at the top of `main.dart`:

```dart
import 'components/ui/button.dart';
```

- [ ] **Step 4: Run to verify pass + analyze + format**

Run: `cd apps/gallery && flutter test test/gallery_smoke_test.dart`
Expected: PASS.
Run: `cd apps/gallery && flutter analyze --fatal-infos --fatal-warnings` then `dart format --line-length 100 lib test`
Expected: No issues; no formatting changes on re-run.

- [ ] **Step 5: Run the full gallery suite**

Run: `cd apps/gallery && flutter test`
Expected: all tests PASS (behavior + golden + smoke).

- [ ] **Step 6: Commit**

```bash
git add apps/gallery/lib/main.dart apps/gallery/test/gallery_smoke_test.dart
git commit -m "feat(gallery): render the Button gallery + smoke test"
```

---

## Task 7: Reconcile docs (charter + AGENTS) for the `default`→`primary`/`md` naming

**Files:**
- Modify: `docs/superpowers/specs/2026-06-10-flutterbits-charter.md` (§3.2)
- Modify: `AGENTS.md` (§4 naming, where the variant/size naming is stated)

- [ ] **Step 1: Update charter §3.2** — change the variant/size naming line to record the reserved-word deviation. Replace the bullet that reads "variants `default / secondary / destructive / outline / ghost / link`; sizes `sm / default / lg / icon`" with:

```markdown
- **Variant/size naming mirrors shadcn**, with one forced deviation: `default` is a **Dart reserved word**, so the shadcn `default` variant is `primary` and the `default` size is `md`. Full set — variants `primary / secondary / destructive / outline / ghost / link`; sizes `sm / md / lg / icon`. Implemented as **typed enums + exhaustive `switch`** (the cva equivalent; AGENTS.md §4).
```

- [ ] **Step 2: Add a one-line note in AGENTS.md §4** after the variants rule (the line about "Variants are typed enums + exhaustive switch"):

```markdown
  - Where a shadcn name is a Dart reserved word, deviate minimally and document it: the `default` button variant → `primary`, the `default` size → `md` (`default` cannot be an enum constant). Mirror every other shadcn name verbatim.
```

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/specs/2026-06-10-flutterbits-charter.md AGENTS.md
git commit -m "docs: record default->primary/md (Dart reserved word) for button"
```

---

## Self-Review (completed at authoring)

- **Spec coverage:** AGENTS.md §6 component checklist — styled via `.tw` + semantic tokens (Task 4 ✓), typed enums + exhaustive `switch` (Tasks 1/4 ✓), Material-free interaction states via `FocusableActionDetector` (Task 3 ✓), keyboard activation via `ActivateIntent`→`CallbackAction` (Task 3 ✓), visible focus ring using `context.fw.colors.ring` (Task 4 ✓), `Semantics(button:, enabled:, label:)` (Task 1 ✓), directional layout — `.px`/`.roundedMd`/`.border` are directional and covered by the RTL golden (Task 5 ✓), goldens for variant×size×brightness (Task 5 ✓), rendered in `apps/gallery` so CI compiles it (Task 6 ✓). Manifest entry is explicitly deferred to the registry/CLI plan (scope note).
- **Placeholder scan:** none — every code/test/command step is concrete.
- **Type consistency:** `ButtonVariant{primary,secondary,destructive,outline,ghost,link}` and `ButtonSize{sm,md,lg,icon}` are used identically in Tasks 1/4/5/6; `_styled`/`_set`/`_hovered`/`_focused`/`_pressed` names are consistent across tasks; `FwFontSize.sm.px`, `FwFontWeight.medium`, and the `.tw` setters (`.h/.px/.bg/.text/.textSize/.weight/.roundedMd/.border/.ring/.opacity/.underline/.size`) match the engine API in `fw_style_ops.dart`.
- **Reserved-word check:** `primary`/`md` used everywhere (never `default` as an identifier).

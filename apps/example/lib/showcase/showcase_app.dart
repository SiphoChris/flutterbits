// The showcase shell: a Material-free WidgetsApp on the pure path, an animated
// semantic-theme switcher (Default ⇄ Claude) + light/dark + LTR/RTL switch, a
// pure/Material host switch (proving the interop path), a category tab bar, and
// the selected section in a scroll view. Every pixel is styled through `.tw` +
// `context.fw`, so one theme swap reskins everything.
//
// This is the example's ONE Material import — used solely to demo the *interop
// path* (`Theme` + `FwThemeExtension` on `ThemeData`). The engine itself never
// imports Material (AGENTS §3.5); the example may, to show it works under both.
import 'package:flutter/material.dart' show Theme, ThemeData;
import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

import 'common.dart';
import 'sections/color_border_radius.dart';
import 'sections/effects.dart';
import 'sections/group_peer.dart';
import 'sections/interactivity.dart';
import 'sections/layout.dart';
import 'sections/palette_scales.dart';
import 'sections/responsive.dart';
import 'sections/spacing_sizing.dart';
import 'sections/states.dart';
import 'sections/tokens.dart';
import 'sections/transforms.dart';
import 'sections/typography.dart';
import 'sections/utilities.dart';
import 'themes.dart';

/// Root widget: owns brightness, text direction, and the selected category.
class ShowcaseApp extends StatefulWidget {
  const ShowcaseApp({super.key});

  @override
  State<ShowcaseApp> createState() => _ShowcaseAppState();
}

class _ShowcaseAppState extends State<ShowcaseApp> {
  bool _dark = false;
  bool _rtl = false;
  bool _material = false; // host: false = pure FwTheme path, true = Material interop.
  int _themeIndex = 0; // index into kDemoThemes; the active semantic theme.
  ShowcaseCategory _category = ShowcaseCategory.tokens;

  @override
  Widget build(BuildContext context) {
    final theme = kDemoThemes[_themeIndex];
    final tokens = theme.resolve(isDark: _dark);
    final shell = _Shell(
      dark: _dark,
      rtl: _rtl,
      material: _material,
      themeName: theme.name,
      category: _category,
      onToggleDark: () => setState(() => _dark = !_dark),
      onToggleRtl: () => setState(() => _rtl = !_rtl),
      onToggleHost: () => setState(() => _material = !_material),
      onCycleTheme: () => setState(() => _themeIndex = (_themeIndex + 1) % kDemoThemes.length),
      onSelect: (c) => setState(() => _category = c),
    );
    return WidgetsApp(
      title: 'flutterwindcss showcase',
      color: const Color(0xFF000000),
      debugShowCheckedModeBanner: false,
      pageRouteBuilder: <T extends Object?>(RouteSettings settings, WidgetBuilder builder) {
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        );
      },
      home:
          _material
              // Interop path: tokens come from a `ThemeData` extension and there
              // is NO `FwTheme` ancestor, so every `context.fw` read below
              // resolves via the `FwThemeExtension` fallback — the SAME shell and
              // sections, proving they render identically under Material
              // (AGENTS §3.4). (Theme changes snap here; the crossfade is a
              // pure-path `FwAnimatedTheme` feature.)
              ? Theme(data: ThemeData(extensions: [FwThemeExtension(tokens: tokens)]), child: shell)
              // Pure path: `FwAnimatedTheme` tweens between bundles, so switching
              // theme OR brightness crossfades every `context.fw`-styled
              // descendant — proof that semantic tokens reskin from one swap.
              : FwAnimatedTheme(tokens: tokens, child: shell),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({
    required this.dark,
    required this.rtl,
    required this.material,
    required this.themeName,
    required this.category,
    required this.onToggleDark,
    required this.onToggleRtl,
    required this.onToggleHost,
    required this.onCycleTheme,
    required this.onSelect,
  });

  final bool dark;
  final bool rtl;
  final bool material;
  final String themeName;
  final ShowcaseCategory category;
  final VoidCallback onToggleDark;
  final VoidCallback onToggleRtl;
  final VoidCallback onToggleHost;
  final VoidCallback onCycleTheme;
  final ValueChanged<ShowcaseCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    return DefaultTextStyle(
      style: TextStyle(
        color: t.colors.foreground,
        fontSize: FwFontSize.base.px,
        decoration: TextDecoration.none,
      ),
      child: SizedBox.expand(
        child: SafeArea(
          child: FwColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _Header(
                dark: dark,
                rtl: rtl,
                material: material,
                themeName: themeName,
                onToggleDark: onToggleDark,
                onToggleRtl: onToggleRtl,
                onToggleHost: onToggleHost,
                onCycleTheme: onCycleTheme,
              ),
              _TabBar(category: category, onSelect: onSelect),
              Expanded(
                child: Directionality(
                  textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                  child: SingleChildScrollView(child: _sectionFor(category).tw.p(5)),
                ),
              ),
            ],
          ),
        ),
      ).tw.bg(t.colors.background),
    );
  }

  Widget _sectionFor(ShowcaseCategory c) => switch (c) {
    ShowcaseCategory.tokens => const TokensSection(),
    ShowcaseCategory.paletteScales => const PaletteScalesSection(),
    ShowcaseCategory.spacing => const SpacingSizingSection(),
    ShowcaseCategory.decoration => const ColorBorderRadiusSection(),
    ShowcaseCategory.typography => const TypographySection(),
    ShowcaseCategory.effects => const EffectsSection(),
    ShowcaseCategory.transforms => const TransformsSection(),
    ShowcaseCategory.states => const StatesSection(),
    ShowcaseCategory.interactivity => const InteractivitySection(),
    ShowcaseCategory.groupPeer => const GroupPeerSection(),
    ShowcaseCategory.utilities => const UtilitiesSection(),
    ShowcaseCategory.responsive => const ResponsiveSection(),
    ShowcaseCategory.layout => const LayoutSection(),
  };
}

class _Header extends StatelessWidget {
  const _Header({
    required this.dark,
    required this.rtl,
    required this.material,
    required this.themeName,
    required this.onToggleDark,
    required this.onToggleRtl,
    required this.onToggleHost,
    required this.onCycleTheme,
  });

  final bool dark;
  final bool rtl;
  final bool material;
  final String themeName;
  final VoidCallback onToggleDark;
  final VoidCallback onToggleRtl;
  final VoidCallback onToggleHost;
  final VoidCallback onCycleTheme;

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    return FwRow(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        FwColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          gap: 1,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'flutterwindcss',
            ).tw.textSize(FwFontSize.xl.px).weight(FwFontWeight.extrabold),
            Text(
              material
                  ? 'interop path · context.fw via FwThemeExtension on ThemeData'
                  : 'every capability · Material-free · pure path',
            ).tw.textSize(FwFontSize.xs.px).text(t.colors.mutedForeground),
          ],
        ),
        FwRow(
          gap: 2,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Cycles the semantic theme; the whole app reskins on tap.
            _PillButton(label: 'Theme: $themeName', onTap: onCycleTheme, filled: true),
            // Swaps the token host: pure FwTheme path ⇄ Material interop.
            _PillButton(label: material ? 'Host: Material' : 'Host: Pure', onTap: onToggleHost),
            _PillButton(label: rtl ? 'RTL' : 'LTR', onTap: onToggleRtl),
            _PillButton(label: dark ? 'Dark' : 'Light', onTap: onToggleDark),
          ],
        ),
      ],
    ).tw.px(5).py(4).bg(t.colors.card).borderB(width: 1, color: t.colors.border);
  }
}

/// A small tappable pill used for the header toggles (auto hover state).
class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap, this.filled = false});

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    final base = Text(
      label,
    ).tw.px(4).py(2).textSize(FwFontSize.sm.px).weight(FwFontWeight.semibold).rounded(t.radii.md);
    final styled =
        filled
            ? base
                .bg(t.colors.primary)
                .text(t.colors.primaryForeground)
                .hover((s) => s.opacity(0.9))
            : base
                .bg(t.colors.secondary)
                .text(t.colors.secondaryForeground)
                .border(1, color: t.colors.border)
                .hover((s) => s.bg(t.colors.accent).text(t.colors.accentForeground));
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: styled);
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.category, required this.onSelect});

  final ShowcaseCategory category;
  final ValueChanged<ShowcaseCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    return FwWrap(
      gap: 2,
      runGap: 2,
      children: <Widget>[
        for (final c in ShowcaseCategory.values)
          _Tab(label: c.label, selected: c == category, onTap: () => onSelect(c)),
      ],
    ).tw.px(5).py(3).bg(t.colors.card).borderB(width: 1, color: t.colors.border);
  }
}

/// A category tab: selected uses the primary fill; unselected is interactive
/// (auto-sourced hover).
class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    final base = Text(
      label,
    ).tw.px(3).py(2).textSize(FwFontSize.sm.px).weight(FwFontWeight.semibold).rounded(t.radii.md);
    final styled =
        selected
            ? base.bg(t.colors.primary).text(t.colors.primaryForeground)
            : base
                .text(t.colors.mutedForeground)
                .hover((s) => s.bg(t.colors.secondary).text(t.colors.secondaryForeground));
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: styled);
  }
}

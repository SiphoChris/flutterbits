// Tokens section: the full shadcn semantic vocabulary (all 32 — 19 core + 5
// chart + 8 sidebar), the derived radius scale, the box-shadow scale, and the
// typography families — all read from `context.fw` so they re-theme live with
// the light/dark toggle.
import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

import '../common.dart';

/// Showcases the active [FwTokens] bundle: colors, radii, shadows, typography.
class TokensSection extends StatelessWidget {
  const TokensSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    final c = t.colors;

    // The 19 core shadcn semantic colors, paired with a sensible foreground.
    final colorPairs = <(String, Color, Color)>[
      ('background', c.background, c.foreground),
      ('foreground', c.foreground, c.background),
      ('card', c.card, c.cardForeground),
      ('cardForeground', c.cardForeground, c.card),
      ('popover', c.popover, c.popoverForeground),
      ('popoverFg', c.popoverForeground, c.popover),
      ('primary', c.primary, c.primaryForeground),
      ('primaryFg', c.primaryForeground, c.primary),
      ('secondary', c.secondary, c.secondaryForeground),
      ('secondaryFg', c.secondaryForeground, c.secondary),
      ('muted', c.muted, c.mutedForeground),
      ('mutedFg', c.mutedForeground, c.muted),
      ('accent', c.accent, c.accentForeground),
      ('accentFg', c.accentForeground, c.accent),
      ('destructive', c.destructive, c.destructiveForeground),
      ('destructiveFg', c.destructiveForeground, c.destructive),
      ('border', c.border, c.foreground),
      ('input', c.input, c.foreground),
      ('ring', c.ring, c.background),
    ];

    // The 5 chart data-viz colors (foreground = the theme background for legibility).
    final chartColors = <(String, Color)>[
      ('chart-1', c.chart1),
      ('chart-2', c.chart2),
      ('chart-3', c.chart3),
      ('chart-4', c.chart4),
      ('chart-5', c.chart5),
    ];

    // The 8 sidebar tokens, paired with their foregrounds.
    final sidebarPairs = <(String, Color, Color)>[
      ('sidebar', c.sidebar, c.sidebarForeground),
      ('sidebarFg', c.sidebarForeground, c.sidebar),
      ('sidebarPrimary', c.sidebarPrimary, c.sidebarPrimaryForeground),
      ('sidebarPrimaryFg', c.sidebarPrimaryForeground, c.sidebarPrimary),
      ('sidebarAccent', c.sidebarAccent, c.sidebarAccentForeground),
      ('sidebarAccentFg', c.sidebarAccentForeground, c.sidebarAccent),
      ('sidebarBorder', c.sidebarBorder, c.sidebarForeground),
      ('sidebarRing', c.sidebarRing, c.sidebar),
    ];

    return FwColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      gap: 4,
      children: <Widget>[
        ShowcaseSection(
          title: 'Core semantic colors (19)',
          description:
              'Components reference these role names — never raw swatches — so swapping the theme reskins everything.',
          children: <Widget>[
            FwWrap(
              gap: 3,
              runGap: 3,
              children: <Widget>[
                for (final (name, bg, fg) in colorPairs) Swatch(name: name, bg: bg, fg: fg),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Chart colors (5)',
          description:
              'shadcn chart-1…5 — the categorical data-viz palette, part of the baked-in vocabulary.',
          children: <Widget>[
            FwWrap(
              gap: 3,
              runGap: 3,
              children: <Widget>[
                for (final (name, bg) in chartColors) Swatch(name: name, bg: bg, fg: c.background),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Sidebar (8)',
          description:
              'The sidebar component’s own sub-theme — generated themes reskin it alongside everything else.',
          children: <Widget>[
            FwWrap(
              gap: 3,
              runGap: 3,
              children: <Widget>[
                for (final (name, bg, fg) in sidebarPairs) Swatch(name: name, bg: bg, fg: fg),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Radius scale',
          description: 'Derived from one base value: sm ×0.6, md ×0.8, lg ×1, xl ×1.4.',
          children: <Widget>[
            FwWrap(
              gap: 4,
              runGap: 4,
              children: <Widget>[
                _radius(context, 'none', 0),
                _radius(context, 'sm', t.radii.sm),
                _radius(context, 'md', t.radii.md),
                _radius(context, 'lg', t.radii.lg),
                _radius(context, 'xl', t.radii.xl),
                _radius(context, 'full', 9999),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Shadow scale',
          description: 'Theme-provided elevation: xs2 → xl2.',
          children: <Widget>[
            FwWrap(
              gap: 6,
              runGap: 6,
              children: <Widget>[
                _shadow(context, 'xs2', t.shadows.xs2),
                _shadow(context, 'xs', t.shadows.xs),
                _shadow(context, 'sm', t.shadows.sm),
                _shadow(context, 'md', t.shadows.md),
                _shadow(context, 'lg', t.shadows.lg),
                _shadow(context, 'xl', t.shadows.xl),
                _shadow(context, 'xl2', t.shadows.xl2),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Typography families',
          description:
              'The theme carries sans/serif/mono family names (flutterwindcss bundles no fonts — '
              'the generator emits a google_fonts wiring stub); the type scale lives on FwFontSize.',
          children: <Widget>[
            for (final (label, fam) in <(String, String)>[
              ('sans', t.typography.sans),
              ('serif', t.typography.serif),
              ('mono', t.typography.mono),
            ])
              Text('$label: $fam').tw.textSize(FwFontSize.base.px).weight(FwFontWeight.medium),
          ],
        ),
      ],
    );
  }

  Widget _radius(BuildContext context, String label, double radius) {
    final t = context.fw;
    return DemoTile(
      label: label,
      child: const SizedBox(
        width: 56,
        height: 40,
      ).tw.bg(t.colors.primary).rounded(radius).border(1, color: t.colors.border),
    );
  }

  Widget _shadow(BuildContext context, String label, List<BoxShadow> shadow) {
    final t = context.fw;
    return DemoTile(
      label: label,
      child: const SizedBox(
        width: 56,
        height: 40,
      ).tw.bg(t.colors.card).rounded(t.radii.md).border(1, color: t.colors.border).shadow(shadow),
    );
  }
}

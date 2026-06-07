// Palette & scales section: the baked Tailwind v4 palette (FwPalette, used to
// *build* themes — never referenced by components) and the theme-independent
// named scales (font size, weight, tracking, leading, blur, breakpoints).
import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

import '../common.dart';

/// Shows the raw palette and the fixed scalar/named scales.
class PaletteScalesSection extends StatelessWidget {
  const PaletteScalesSection({super.key});

  static const List<(String, FwSwatch)> _hues = <(String, FwSwatch)>[
    ('slate', FwPalette.slate),
    ('gray', FwPalette.gray),
    ('zinc', FwPalette.zinc),
    ('neutral', FwPalette.neutral),
    ('stone', FwPalette.stone),
    ('red', FwPalette.red),
    ('orange', FwPalette.orange),
    ('amber', FwPalette.amber),
    ('yellow', FwPalette.yellow),
    ('lime', FwPalette.lime),
    ('green', FwPalette.green),
    ('emerald', FwPalette.emerald),
    ('teal', FwPalette.teal),
    ('cyan', FwPalette.cyan),
    ('sky', FwPalette.sky),
    ('blue', FwPalette.blue),
    ('indigo', FwPalette.indigo),
    ('violet', FwPalette.violet),
    ('purple', FwPalette.purple),
    ('fuchsia', FwPalette.fuchsia),
    ('pink', FwPalette.pink),
    ('rose', FwPalette.rose),
  ];

  static const List<int> _shades = <int>[50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950];

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    return FwColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      gap: 4,
      children: <Widget>[
        ShowcaseSection(
          title: 'Tailwind v4 palette (22 × 11)',
          description:
              'Baked from published sRGB hex — zero runtime color math. Used to build themes; components never touch it directly.',
          children: <Widget>[
            FwColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              gap: 1,
              children: <Widget>[
                for (final (name, swatch) in _hues)
                  FwRow(
                    gap: 1,
                    children: <Widget>[
                      SizedBox(
                        width: 64,
                        child: Text(
                          name,
                        ).tw.textSize(FwFontSize.xs.px).text(t.colors.mutedForeground),
                      ),
                      for (final shade in _shades)
                        const SizedBox(width: 24, height: 18).tw.bg(swatch.shade(shade)),
                    ],
                  ),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Font-size scale (FwFontSize)',
          description: 'xs → xl9, each with its own line-height.',
          children: <Widget>[
            FwWrap(
              gap: 4,
              runGap: 3,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                for (final size in FwFontSize.values)
                  Text(
                    '${size.name} ${size.px.toInt()}',
                  ).tw.textSize(size.px <= 36 ? size.px : 36).text(t.colors.foreground),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Weight · tracking · leading',
          children: <Widget>[
            DemoTile(
              label: 'FwFontWeight 100 → 900',
              child: FwWrap(
                gap: 3,
                runGap: 2,
                children: <Widget>[
                  for (final w in const <int>[100, 300, 400, 500, 700, 900])
                    Text('w$w').tw.weight(w).textSize(FwFontSize.lg.px),
                ],
              ),
            ),
            DemoTile(
              label: 'FwTracking tight → widest',
              child: FwColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                gap: 1,
                children: <Widget>[
                  Text('tight').tw.tracking(FwTracking.tight).textSize(FwFontSize.sm.px),
                  Text('normal').tw.tracking(FwTracking.normal).textSize(FwFontSize.sm.px),
                  Text('widest').tw.tracking(FwTracking.widest).textSize(FwFontSize.sm.px),
                ],
              ),
            ),
            DemoTile(
              label: 'FwLeading tight → loose',
              child: FwRow(
                gap: 4,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _leading(context, 'tight', FwLeading.tight),
                  _leading(context, 'normal', FwLeading.normal),
                  _leading(context, 'loose', FwLeading.loose),
                ],
              ),
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Blur scale & breakpoints',
          children: <Widget>[
            DemoTile(
              label: 'FwBlur xs → xl2 (sigma)',
              child: Text(
                FwBlur.values.map((b) => '${b.name}=${b.sigma.toInt()}').join('  ·  '),
              ).tw.textSize(FwFontSize.sm.px).text(t.colors.mutedForeground),
            ),
            DemoTile(
              label: 'FwBreakpoint (logical px)',
              child: Text(
                FwBreakpoint.values.map((b) => '${b.name}=${b.minWidth.toInt()}').join('  ·  '),
              ).tw.textSize(FwFontSize.sm.px).text(t.colors.mutedForeground),
            ),
          ],
        ),
      ],
    );
  }

  Widget _leading(BuildContext context, String label, double leading) {
    final t = context.fw;
    return FwColumn(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      gap: 1,
      children: <Widget>[
        Text(label).tw.textSize(FwFontSize.xs.px).text(t.colors.mutedForeground),
        SizedBox(
          width: 120,
          child: Text(
            'two lines of body text to show line height',
          ).tw.textSize(FwFontSize.sm.px).leading(leading),
        ),
      ],
    );
  }
}

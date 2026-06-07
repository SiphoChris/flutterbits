// Effects section: shadow (theme list), opacity (Tailwind opacity scale),
// content blur, and backdrop blur over busy content.
import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

import '../common.dart';

/// Demonstrates the effects `.tw` setters.
class EffectsSection extends StatelessWidget {
  const EffectsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    return FwColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      gap: 4,
      children: <Widget>[
        ShowcaseSection(
          title: 'Shadow',
          description: 'shadow(List<BoxShadow>) from the theme elevation scale.',
          children: <Widget>[
            FwWrap(
              gap: 6,
              runGap: 6,
              children: <Widget>[
                _shadow(context, 'sm', t.shadows.sm),
                _shadow(context, 'md', t.shadows.md),
                _shadow(context, 'lg', t.shadows.lg),
                _shadow(context, 'xl', t.shadows.xl),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Opacity',
          description: 'opacity(0..1) — using the Tailwind opacity steps via fwOpacity().',
          children: <Widget>[
            FwWrap(
              gap: 3,
              runGap: 3,
              children: <Widget>[
                for (final step in const <int>[100, 75, 50, 25, 10])
                  demoChip(
                    '$step%',
                    (b) => b
                        .bg(t.colors.primary)
                        .text(t.colors.primaryForeground)
                        .rounded(t.radii.md)
                        .opacity(fwOpacity(step)),
                  ),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Content blur',
          description: 'blur(sigma) blurs the box content (FwBlur scale).',
          children: <Widget>[
            FwWrap(
              gap: 6,
              runGap: 6,
              children: <Widget>[
                for (final b in const <FwBlur>[FwBlur.xs, FwBlur.sm, FwBlur.md, FwBlur.lg])
                  demoChip(
                    b.name,
                    (s) => s
                        .bg(t.colors.accent)
                        .text(t.colors.accentForeground)
                        .rounded(t.radii.md)
                        .blur(b.sigma),
                  ),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Backdrop blur',
          description:
              'backdropBlur(sigma) frosts whatever is painted behind — here a palette stripe.',
          children: <Widget>[
            FwStack(
              alignment: AlignmentDirectional.center,
              children: <Widget>[
                // Busy backdrop.
                FwRow(
                  children: <Widget>[
                    for (final c in <Color>[
                      FwPalette.red.shade400,
                      FwPalette.amber.shade400,
                      FwPalette.green.shade400,
                      FwPalette.sky.shade400,
                      FwPalette.violet.shade400,
                    ])
                      Expanded(child: const SizedBox(height: 80).tw.bg(c)),
                  ],
                ),
                // Frosted panel over it.
                Center(
                      child: Text(
                        'backdropBlur(12)',
                      ).tw.weight(FwFontWeight.semibold).text(t.colors.foreground),
                    ).tw
                    .px(5)
                    .py(4)
                    .rounded(t.radii.lg)
                    .bg(t.colors.background.withValues(alpha: 0.4))
                    .backdropBlur(12),
              ],
            ),
          ],
        ),
      ],
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

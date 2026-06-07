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
        ShowcaseSection(
          title: 'Color filters (module 12)',
          description: 'CSS filter functions on a colourful gradient; they compose within a chain.',
          children: <Widget>[
            FwWrap(
              gap: 4,
              runGap: 4,
              children: <Widget>[
                _filter(context, 'none', (b) => b),
                _filter(context, 'grayscale', (b) => b.grayscale()),
                _filter(context, 'brightness 1.4', (b) => b.brightness(1.4)),
                _filter(context, 'contrast 1.6', (b) => b.contrast(1.6)),
                _filter(context, 'saturate 2', (b) => b.saturate(2)),
                _filter(context, 'invert', (b) => b.invert()),
                _filter(context, 'sepia', (b) => b.sepia()),
                _filter(context, 'hueRotate 90°', (b) => b.hueRotate(90)),
                _filter(context, 'grayscale→bright', (b) => b.grayscale().brightness(1.5)),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Object-fit (module 12)',
          description:
              'fit(BoxFit.*) scales the content to its box — contain fits inside, cover fills.',
          children: <Widget>[
            FwRow(
              gap: 6,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _fitDemo(context, 'contain', BoxFit.contain),
                _fitDemo(context, 'cover', BoxFit.cover),
                _fitDemo(context, 'fill', BoxFit.fill),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _filter(BuildContext context, String label, FwStyled Function(FwStyled) filter) {
    final t = context.fw;
    final box = const SizedBox(width: 64, height: 40).tw
        .rounded(t.radii.md)
        .bgGradient(
          LinearGradient(
            colors: <Color>[
              FwPalette.red.shade500,
              FwPalette.blue.shade500,
              FwPalette.green.shade500,
            ],
          ),
        );
    return DemoTile(label: label, child: filter(box));
  }

  Widget _fitDemo(BuildContext context, String label, BoxFit fit) {
    final t = context.fw;
    return DemoTile(
      label: label,
      // A wide label scaled to a fixed box via object-fit.
      child: SizedBox(
        width: 80,
        height: 40,
        child: Text(
          'FIT',
        ).tw.fit(fit).bg(t.colors.muted).text(t.colors.mutedForeground).weight(FwFontWeight.black),
      ),
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

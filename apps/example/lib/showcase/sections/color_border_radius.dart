// Color · border · radius section: solid fill, gradients, the accumulating
// directional border (uniform, per-axis, per-edge), per-corner radius, and clip.
import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

import '../common.dart';

/// Demonstrates fill, gradient, border, radius, and clip `.tw` setters.
class ColorBorderRadiusSection extends StatelessWidget {
  const ColorBorderRadiusSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    return FwColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      gap: 4,
      children: <Widget>[
        ShowcaseSection(
          title: 'Fill & gradient',
          description: 'bg(color) and bgGradient(Gradient) — gradients built from semantic tokens.',
          children: <Widget>[
            FwWrap(
              gap: 4,
              runGap: 4,
              children: <Widget>[
                DemoTile(
                  label: 'bg(primary)',
                  child: const SizedBox().tw.w(20).h(10).bg(t.colors.primary).rounded(t.radii.md),
                ),
                DemoTile(
                  label: 'bgGradient (linear)',
                  child: const SizedBox().tw
                      .w(28)
                      .h(10)
                      .rounded(t.radii.md)
                      .bgGradient(
                        LinearGradient(
                          begin: AlignmentDirectional.centerStart,
                          end: AlignmentDirectional.centerEnd,
                          colors: <Color>[t.colors.primary, t.colors.accent],
                        ),
                      ),
                ),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Border',
          description:
              'Uniform border(w, color) can be rounded. Per-edge borders (borderS/E/T/B) cannot be rounded — Flutter only rounds when every edge matches — so those stay square.',
          children: <Widget>[
            FwWrap(
              gap: 4,
              runGap: 4,
              children: <Widget>[
                for (final w in fwBorderWidths)
                  demoChip(
                    'border(${w.toInt()})',
                    (b) => b
                        .text(t.colors.foreground)
                        .rounded(t.radii.md)
                        .border(w, color: t.colors.primary),
                  ),
                // Independent width/colour axes (accumulating).
                demoChip(
                  'borderWidth+Color',
                  (b) => b
                      .text(t.colors.foreground)
                      .rounded(t.radii.md)
                      .borderWidth(3)
                      .borderColor(t.colors.destructive),
                ),
              ],
            ),
            DemoTile(
              label: 'per-edge (square): borderS · borderT · borderE+borderB',
              child: FwWrap(
                gap: 4,
                runGap: 4,
                children: <Widget>[
                  demoChip(
                    'borderS(4)',
                    (b) => b
                        .bg(t.colors.muted)
                        .text(t.colors.mutedForeground)
                        .borderS(width: 4, color: t.colors.primary),
                  ),
                  demoChip(
                    'borderT(4)',
                    (b) => b
                        .bg(t.colors.muted)
                        .text(t.colors.mutedForeground)
                        .borderT(width: 4, color: t.colors.accent),
                  ),
                  demoChip(
                    'borderE+borderB',
                    (b) => b
                        .bg(t.colors.muted)
                        .text(t.colors.mutedForeground)
                        .borderE(width: 3, color: t.colors.primary)
                        .borderB(width: 3, color: t.colors.accent),
                  ),
                ],
              ),
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Radius (per corner, directional)',
          description:
              'rounded / roundedT / roundedB / roundedS / roundedE / roundedNone / roundedFull.',
          children: <Widget>[
            FwWrap(
              gap: 4,
              runGap: 4,
              children: <Widget>[
                _radiusBox(context, 'none', (b) => b.roundedNone),
                _radiusBox(context, 'rounded(md)', (b) => b.rounded(t.radii.md)),
                _radiusBox(context, 'roundedT', (b) => b.roundedT(t.radii.lg)),
                _radiusBox(context, 'roundedB', (b) => b.roundedB(t.radii.lg)),
                _radiusBox(context, 'roundedS', (b) => b.roundedS(t.radii.lg)),
                _radiusBox(context, 'roundedE', (b) => b.roundedE(t.radii.lg)),
                _radiusBox(context, 'roundedFull', (b) => b.roundedFull),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Clip',
          description:
              'clip() clips the child to the (radius-deflated) content box. The rotated child overflows without it.',
          children: <Widget>[
            DemoTile(
              label: 'no clip  vs  clip() — rotated child',
              child: FwRow(
                gap: 6,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[_clipDemo(context, clip: false), _clipDemo(context, clip: true)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _clipDemo(BuildContext context, {required bool clip}) {
    final t = context.fw;
    final child = const SizedBox(width: 110, height: 28).tw.bg(t.colors.accent).rotate(22);
    final base = child.tw
        .w(26)
        .h(14)
        .bg(t.colors.muted)
        .rounded(t.radii.lg)
        .border(1, color: t.colors.border);
    return DemoTile(label: clip ? 'clip()' : 'no clip', child: clip ? base.clip() : base);
  }

  Widget _radiusBox(BuildContext context, String label, FwStyled Function(FwStyled) radius) {
    final t = context.fw;
    return DemoTile(
      label: label,
      child: radius(
        const SizedBox(width: 56, height: 36).tw.bg(t.colors.primary),
      ).border(1, color: t.colors.border),
    );
  }
}

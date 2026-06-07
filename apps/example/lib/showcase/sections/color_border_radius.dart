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
              label: 'per-edge (square): each edge individually, then all four at once',
              child: FwWrap(
                gap: 6,
                runGap: 6,
                children: <Widget>[
                  // Each edge on its own, high-contrast so the single stroke is clear.
                  _edgeBox(context, 'S', (b) => b.borderS(width: 4, color: t.colors.primary)),
                  _edgeBox(context, 'T', (b) => b.borderT(width: 4, color: t.colors.primary)),
                  _edgeBox(context, 'E', (b) => b.borderE(width: 4, color: t.colors.primary)),
                  _edgeBox(context, 'B', (b) => b.borderB(width: 4, color: t.colors.primary)),
                  // All four, each a distinct colour — proves per-edge accumulation.
                  _edgeBox(
                    context,
                    '4×',
                    (b) => b
                        .borderT(width: 4, color: FwPalette.red.shade500)
                        .borderE(width: 4, color: FwPalette.green.shade500)
                        .borderB(width: 4, color: FwPalette.blue.shade500)
                        .borderS(width: 4, color: FwPalette.amber.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Border style (dashed / dotted)',
          description:
              'borderDashed / borderDotted — Flutter has no dashed BorderSide, so these are painted. '
              'Uniform borders only; they follow the corner radius. The drop-to-upload staple.',
          children: <Widget>[
            FwWrap(
              gap: 6,
              runGap: 6,
              children: <Widget>[
                Center(child: const Text('Drop files').tw.text(t.colors.mutedForeground)).tw
                    .w(36)
                    .h(18)
                    .bg(t.colors.muted)
                    .rounded(t.radii.lg)
                    .border(2, color: t.colors.mutedForeground)
                    .borderDashed,
                const SizedBox(
                  width: 110,
                  height: 64,
                ).tw.rounded(t.radii.lg).border(2, color: t.colors.primary).borderDotted,
                const SizedBox(
                  width: 110,
                  height: 64,
                ).tw.border(2, color: t.colors.border).borderDashed,
              ],
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

  /// A fixed box showing a single (or multi) per-edge border, high-contrast.
  Widget _edgeBox(BuildContext context, String label, FwStyled Function(FwStyled) edges) {
    final t = context.fw;
    return DemoTile(
      label: label,
      child: edges(
        Center(
          child: Text(label).tw.textSize(FwFontSize.xs.px).text(t.colors.mutedForeground),
        ).tw.w(16).h(14).bg(t.colors.card),
      ),
    );
  }

  /// Clip demo: a rotated bar paints beyond the box (rotation overflows the box's
  /// paint bounds — unlike an oversized child, which the tight `w/h` constraints
  /// would just clamp). Without `clip()` the bar's ends poke past the rounded
  /// corners; with it, the bar is cut to the rounded shape.
  Widget _clipDemo(BuildContext context, {required bool clip}) {
    final t = context.fw;
    final bar = const SizedBox(
      width: 150,
      height: 26,
    ).tw.bgGradientToEnd(<Color>[t.colors.primary, t.colors.destructive]).rotate(28);
    final base = Center(
      child: bar,
    ).tw.w(26).h(26).bg(t.colors.muted).rounded(t.radii.xl).border(2, color: t.colors.border);
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

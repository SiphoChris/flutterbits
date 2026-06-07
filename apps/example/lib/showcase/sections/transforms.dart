// Transforms section: paint-only transforms (no reflow, matching CSS
// `transform`) — scale, rotate, and translate / translateX / translateY.
import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

import '../common.dart';

/// Demonstrates the transform `.tw` setters (composed T·R·S).
class TransformsSection extends StatelessWidget {
  const TransformsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.fw;

    FwStyled fill(FwStyled b) => b
        .px(4)
        .py(3)
        .bg(t.colors.primary)
        .text(t.colors.primaryForeground)
        .rounded(t.radii.md)
        .weight(FwFontWeight.semibold);

    return FwColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      gap: 4,
      children: <Widget>[
        ShowcaseSection(
          title: 'Scale',
          children: <Widget>[
            FwWrap(
              gap: 8,
              runGap: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                demoChip('0.75', (b) => fill(b).scale(0.75)),
                demoChip('1.0', (b) => fill(b)),
                demoChip('1.3', (b) => fill(b).scale(1.3)),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Rotate (degrees)',
          children: <Widget>[
            FwWrap(
              gap: 8,
              runGap: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                demoChip('-15°', (b) => fill(b).rotate(-15)),
                demoChip('0°', (b) => fill(b)),
                demoChip('15°', (b) => fill(b).rotate(15)),
                demoChip('45°', (b) => fill(b).rotate(45)),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Translate (utility units)',
          description: 'Paint-only: neighbours do not reflow.',
          children: <Widget>[
            FwWrap(
              gap: 10,
              runGap: 10,
              children: <Widget>[
                demoChip('translateX(3)', (b) => fill(b).translateX(3)),
                demoChip('translateY(-3)', (b) => fill(b).translateY(-3)),
                demoChip('translate(2,2)', (b) => fill(b).translate(2, 2)),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Per-axis scale & skew (module 13)',
          children: <Widget>[
            FwWrap(
              gap: 10,
              runGap: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                demoChip('scaleX 1.6', (b) => fill(b).scaleX(1.6)),
                demoChip('scaleY 1.6', (b) => fill(b).scaleY(1.6)),
                demoChip('skewX 20°', (b) => fill(b).skewX(20)),
                demoChip('skewY 12°', (b) => fill(b).skewY(12)),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Composed (T·R·S)',
          children: <Widget>[
            FwWrap(
              gap: 10,
              runGap: 10,
              children: <Widget>[
                demoChip('rotate+scale', (b) => fill(b).rotate(-12).scale(1.15)),
                demoChip('all three', (b) => fill(b).translateY(-2).rotate(8).scale(1.1)),
                // transformOrigin: rotate about the top-start corner, not center.
                demoChip(
                  'rotate @ origin',
                  (b) => fill(b).rotate(20).transformOrigin(AlignmentDirectional.topStart),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

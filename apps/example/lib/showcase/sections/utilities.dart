// Utilities section (module 15): gradient direction sugar, the focus `ring`,
// named-scale shadow/radius sugar, dashed "drop-zone" borders, and FwScroll.
import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

import '../common.dart';

/// Demonstrates the module 15 ergonomics + utility additions.
class UtilitiesSection extends StatelessWidget {
  const UtilitiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    return FwColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      gap: 4,
      children: <Widget>[
        ShowcaseSection(
          title: 'Gradient direction sugar',
          description: 'bgGradientTo{End,Bottom,BottomEnd,…} — RTL-aware, colors from tokens.',
          children: <Widget>[
            FwWrap(
              gap: 4,
              runGap: 4,
              children: <Widget>[
                const SizedBox(
                  width: 80,
                  height: 56,
                ).tw.roundedLg.bgGradientToEnd(<Color>[t.colors.primary, t.colors.accent]),
                const SizedBox(
                  width: 80,
                  height: 56,
                ).tw.roundedLg.bgGradientToBottom(<Color>[t.colors.secondary, t.colors.muted]),
                const SizedBox(width: 80, height: 56).tw.roundedLg.bgGradientToBottomEnd(<Color>[
                  t.colors.primary,
                  t.colors.destructive,
                ]),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Named-scale sugar (theme-resolved)',
          description: 'roundedSm/Md/Lg/Xl and shadowSm/Md/Lg/Xl track the active theme.',
          children: <Widget>[
            DemoTile(
              label: 'radius: roundedSm · roundedMd · roundedLg · roundedXl',
              child: FwWrap(
                gap: 4,
                runGap: 4,
                children: <Widget>[
                  const SizedBox(width: 56, height: 40).tw.bg(t.colors.secondary).roundedSm,
                  const SizedBox(width: 56, height: 40).tw.bg(t.colors.secondary).roundedMd,
                  const SizedBox(width: 56, height: 40).tw.bg(t.colors.secondary).roundedLg,
                  const SizedBox(width: 56, height: 40).tw.bg(t.colors.secondary).roundedXl,
                ],
              ),
            ),
            DemoTile(
              label: 'shadow: shadowSm · shadowMd · shadowLg · shadowXl',
              child: FwWrap(
                gap: 6,
                runGap: 6,
                children: <Widget>[
                  const SizedBox(width: 56, height: 40).tw.bg(t.colors.card).roundedMd.shadowSm,
                  const SizedBox(width: 56, height: 40).tw.bg(t.colors.card).roundedMd.shadowMd,
                  const SizedBox(width: 56, height: 40).tw.bg(t.colors.card).roundedMd.shadowLg,
                  const SizedBox(width: 56, height: 40).tw.bg(t.colors.card).roundedMd.shadowXl,
                ],
              ),
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Focus ring',
          description: 'ring(width, color) — a zero-blur spread shadow; composes with shadow.',
          children: <Widget>[
            FwWrap(
              gap: 6,
              runGap: 6,
              children: <Widget>[
                const SizedBox(
                  width: 90,
                  height: 44,
                ).tw.bg(t.colors.card).roundedMd.ring(2, color: t.colors.ring),
                const SizedBox(width: 90, height: 44).tw
                    .bg(t.colors.card)
                    .roundedMd
                    .shadow(t.shadows.sm)
                    .ring(2, color: t.colors.ring, offset: 2, offsetColor: t.colors.background),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Dashed / dotted borders',
          description: 'borderDashed / borderDotted — the drop-to-upload staple.',
          children: <Widget>[
            FwWrap(
              gap: 6,
              runGap: 6,
              children: <Widget>[
                Center(child: const Text('Drop files here').tw.text(t.colors.mutedForeground)).tw
                    .w(40)
                    .h(20)
                    .bg(t.colors.muted)
                    .rounded(t.radii.lg)
                    .border(2, color: t.colors.mutedForeground)
                    .borderDashed,
                const SizedBox(
                  width: 120,
                  height: 56,
                ).tw.rounded(t.radii.lg).border(2, color: t.colors.border).borderDotted,
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Scroll (FwScroll)',
          description: 'overflow-auto/scroll — Material-free SingleChildScrollView + RawScrollbar.',
          children: <Widget>[
            SizedBox(
              height: 120,
              child: FwScroll(
                thumbColor: t.colors.border,
                child: FwColumn(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  gap: 2,
                  children: <Widget>[
                    for (var i = 1; i <= 20; i++)
                      Text('Scrollable row $i').tw
                          .px(3)
                          .py(2)
                          .bg(i.isEven ? t.colors.muted : t.colors.card)
                          .text(t.colors.foreground),
                  ],
                ),
              ),
            ).tw.rounded(t.radii.md).border(1, color: t.colors.border).clip(),
          ],
        ),
      ],
    );
  }
}

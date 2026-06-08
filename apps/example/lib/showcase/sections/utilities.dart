// Utilities section (modules 15–17): gradient direction sugar, the focus `ring`,
// named-scale shadow/radius sugar, dashed "drop-zone" borders, FwScroll + scroll-snap,
// divide (16), and 3D transforms + mix-blend + text-shadow (17).
import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

import '../common.dart';

/// Demonstrates the module 15 ergonomics + the module 16/17 completeness additions.
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
          title: 'Scroll (FwScroll) + snap',
          description:
              'overflow-auto/scroll, Material-free. The horizontal strip uses snapExtent — '
              'fling it and it settles on a card (scroll-snap).',
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
            DemoTile(
              // The snap pitch MUST equal each card's full footprint or the
              // carousel drifts: card = w(30)=120px + trailing me(2)=8px = 128px.
              // Only a trailing margin (not mx) so the first card's leading edge
              // sits at offset 0, aligning the snap grid. 16 cards (≈2048px) so it
              // overflows any window and is clearly scrollable.
              label: 'snapExtent: 128 — fling it; it settles on a card (scroll-snap)',
              child: SizedBox(
                height: 72,
                child: FwScroll(
                  axis: Axis.horizontal,
                  snapExtent: 128,
                  showScrollbar: false,
                  child: FwRow(
                    children: <Widget>[
                      for (var i = 1; i <= 16; i++)
                        Center(
                          child: Text(
                            'Card $i',
                          ).tw.weight(FwFontWeight.semibold).text(t.colors.primaryForeground),
                        ).tw.w(30).h(16).me(2).bg(t.colors.primary).rounded(t.radii.lg),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Divide (module 16)',
          description:
              'divideWidth/divideColor — a border BETWEEN flex children (Tailwind divide).',
          children: <Widget>[
            DemoTile(
              label: 'FwColumn divide (rows)',
              child: FwColumn(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                divideWidth: 1,
                divideColor: t.colors.border,
                children: <Widget>[
                  for (final s in const <String>['Profile', 'Billing', 'Team', 'Logout'])
                    Text(s).tw.px(3).py(3).text(t.colors.foreground),
                ],
              ),
            ).tw.bg(t.colors.card).rounded(t.radii.md).border(1, color: t.colors.border).clip(),
          ],
        ),
        ShowcaseSection(
          title: '3D transforms + mix-blend + text-shadow (module 17)',
          description:
              'mix-blend composites a layer against what is painted BEHIND it. The two tiles '
              'below are identical except the top square sets blendMode(multiply): yellow × cyan '
              'multiply = green, so the overlap turns green only on the right. perspective+rotateY '
              'foreshortens a card in 3D; textShadow glows descendant text.',
          children: <Widget>[
            FwWrap(
              gap: 10,
              runGap: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                DemoTile(
                  label: 'normal (no blend) — opaque overlap',
                  child: _blendPair(context, blend: false),
                ),
                DemoTile(
                  label: 'mix-blend multiply — overlap → green',
                  child: _blendPair(context, blend: true),
                ),
                DemoTile(
                  label: 'perspective + rotateY',
                  child: Center(child: const Text('3D').tw.text(t.colors.primaryForeground)).tw
                      .w(20)
                      .h(16)
                      .bg(t.colors.primary)
                      .rounded(t.radii.md)
                      .perspective(260)
                      .rotateY(38),
                ),
                DemoTile(
                  label: 'text-shadow',
                  child: const Text('Glow').tw
                      .textSize(FwFontSize.xl2.px)
                      .weight(FwFontWeight.bold)
                      .text(t.colors.foreground)
                      .textShadow(<Shadow>[
                        Shadow(color: t.colors.primary, blurRadius: 8, offset: const Offset(0, 2)),
                      ]),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Two overlapping squares — yellow under, cyan over. With [blend] the cyan
  /// square uses `blendMode(multiply)`, so the overlap multiplies against the
  /// yellow backdrop (yellow × cyan = green); without it the cyan paints opaque.
  /// Side-by-side this makes mix-blend unmistakable.
  Widget _blendPair(BuildContext context, {required bool blend}) {
    final under = const SizedBox(width: 52, height: 52).tw.bg(FwPalette.yellow.shade400);
    var over = const SizedBox(width: 52, height: 52).tw.bg(FwPalette.cyan.shade400);
    if (blend) over = over.blendMode(BlendMode.multiply);
    return SizedBox(
      width: 84,
      height: 84,
      child: FwStack(
        children: <Widget>[
          FwPositioned(top: 0, start: 0, child: under),
          FwPositioned(top: 32, start: 32, child: over),
        ],
      ),
    );
  }
}

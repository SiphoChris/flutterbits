// Spacing & sizing section: directional padding/margin per edge, fixed and
// min/max sizing, fractional sizing, and aspect/square. Padding and margin are
// visualized as a muted ring around a primary inner block.
import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

import '../common.dart';

/// Demonstrates the spacing/sizing `.tw` setters (1 unit = 4 logical px).
class SpacingSizingSection extends StatelessWidget {
  const SpacingSizingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    return FwColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      gap: 4,
      children: <Widget>[
        ShowcaseSection(
          title: 'Padding (directional)',
          description:
              'p / px / py / ps / pe / pt / pb — the muted ring is the padding; ps/pe mirror under RTL.',
          children: <Widget>[
            FwWrap(
              gap: 4,
              runGap: 4,
              children: <Widget>[
                _pad(context, 'p(4)', (b) => b.p(4)),
                _pad(context, 'px(6) py(2)', (b) => b.px(6).py(2)),
                _pad(context, 'ps(8)', (b) => b.ps(8)),
                _pad(context, 'pe(8)', (b) => b.pe(8)),
                _pad(context, 'pt(8)', (b) => b.pt(8)),
                _pad(context, 'pb(8)', (b) => b.pb(8)),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Margin (directional)',
          description:
              'm / mx / my / ms / me / mt / mb — the gap inside the bordered parent is the margin.',
          children: <Widget>[
            FwWrap(
              gap: 4,
              runGap: 4,
              children: <Widget>[
                _margin(context, 'm(2)', (b) => b.m(2)),
                _margin(context, 'ms(6)', (b) => b.ms(6)),
                _margin(context, 'mt(6)', (b) => b.mt(6)),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Fixed & clamped sizing',
          description: 'w / h in utility units, and minW/maxW clamps under tight content.',
          children: <Widget>[
            FwWrap(
              gap: 4,
              runGap: 4,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: <Widget>[
                DemoTile(
                  label: 'w(16) h(10)',
                  child: const SizedBox().tw.w(16).h(10).bg(t.colors.primary).rounded(t.radii.md),
                ),
                DemoTile(
                  label: 'w(28) h(8)',
                  child: const SizedBox().tw.w(28).h(8).bg(t.colors.accent).rounded(t.radii.md),
                ),
                DemoTile(
                  label: 'minW(20) · short text',
                  child: Text('hi').tw
                      .px(2)
                      .py(2)
                      .minW(20)
                      .bg(t.colors.secondary)
                      .text(t.colors.secondaryForeground)
                      .rounded(t.radii.md)
                      .align(TextAlign.center),
                ),
                DemoTile(
                  label: 'maxW(34) · long text wraps',
                  child: Text('a longer label that exceeds the max width and wraps').tw
                      .px(3)
                      .py(2)
                      .maxW(34)
                      .bg(t.colors.muted)
                      .text(t.colors.mutedForeground)
                      .rounded(t.radii.md),
                ),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Fractional sizing & aspect',
          description: 'wFraction / wFull (of the parent), an aspect ratio, and square.',
          children: <Widget>[
            DemoTile(
              label: 'wFraction(0.5) · wFraction(0.75) · wFull',
              child: FwColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                gap: 2,
                children: <Widget>[
                  _bar(context, '50%', 0.5, t.colors.primary, t.colors.primaryForeground),
                  _bar(context, '75%', 0.75, t.colors.accent, t.colors.accentForeground),
                  Center(
                        child: Text(
                          'wFull',
                        ).tw.textSize(FwFontSize.sm.px).weight(FwFontWeight.semibold),
                      ).tw
                      .h(10)
                      .wFull
                      .bg(t.colors.secondary)
                      .text(t.colors.secondaryForeground)
                      .rounded(t.radii.md),
                ],
              ),
            ),
            DemoTile(
              label: 'aspect(16/9) · square',
              child: FwRow(
                gap: 4,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 160,
                    child: Center(
                      child: Text(
                        '16:9',
                      ).tw.textSize(FwFontSize.sm.px).text(t.colors.primaryForeground),
                    ).tw.aspect(16 / 9).bg(t.colors.primary).rounded(t.radii.md),
                  ),
                  SizedBox(
                    width: 64,
                    child: Center(
                      child: Text(
                        '1:1',
                      ).tw.textSize(FwFontSize.sm.px).text(t.colors.accentForeground),
                    ).tw.square.bg(t.colors.accent).rounded(t.radii.md),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bar(BuildContext context, String label, double factor, Color bg, Color fg) {
    final t = context.fw;
    return Center(
      child: Text(label).tw.textSize(FwFontSize.sm.px).weight(FwFontWeight.semibold),
    ).tw.h(10).wFraction(factor).bg(bg).text(fg).rounded(t.radii.md);
  }

  Widget _pad(BuildContext context, String label, FwStyled Function(FwStyled) pad) {
    final t = context.fw;
    final inner = Text(
      'child',
    ).tw.px(2).py(1).bg(t.colors.primary).text(t.colors.primaryForeground).rounded(t.radii.sm);
    return DemoTile(
      label: label,
      child: pad(inner.tw).bg(t.colors.muted).rounded(t.radii.md).border(1, color: t.colors.border),
    );
  }

  Widget _margin(BuildContext context, String label, FwStyled Function(FwStyled) margin) {
    final t = context.fw;
    final inner = margin(
      Text(
        'child',
      ).tw.px(2).py(1).bg(t.colors.primary).text(t.colors.primaryForeground).rounded(t.radii.sm),
    );
    return DemoTile(
      label: label,
      child: inner.tw.bg(t.colors.muted).rounded(t.radii.md).border(1, color: t.colors.border),
    );
  }
}

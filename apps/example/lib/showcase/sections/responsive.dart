// Responsive section: viewport breakpoint variants (sm/md/lg/xl) that react to
// the screen width, and container-query variants (containerSm/Md/…) that react
// to the *enclosing constraint* width — shown statically across fixed-width
// containers so the difference is visible without resizing.
import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

import '../common.dart';

/// Demonstrates viewport and container responsive variants on `.tw`.
class ResponsiveSection extends StatelessWidget {
  const ResponsiveSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    return FwColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      gap: 4,
      children: <Widget>[
        ShowcaseSection(
          title: 'Viewport variants',
          description:
              'Resize the window: the fill changes at sm (640) / md (768) / lg (1024) screen widths.',
          children: <Widget>[
            Center(
                  child: Text('secondary < sm · accent ≥ sm · primary ≥ md · destructive ≥ lg').tw
                      .textSize(FwFontSize.sm.px)
                      .weight(FwFontWeight.semibold)
                      .align(TextAlign.center),
                ).tw
                .p(4)
                .wFull
                .rounded(t.radii.md)
                .bg(t.colors.secondary)
                .text(t.colors.secondaryForeground)
                .sm((s) => s.bg(t.colors.accent).text(t.colors.accentForeground))
                .md((s) => s.bg(t.colors.primary).text(t.colors.primaryForeground))
                .lg((s) => s.bg(t.colors.destructive).text(t.colors.destructiveForeground)),
          ],
        ),
        ShowcaseSection(
          title: 'Container queries',
          description:
              'The same box in 320 / 700 / 820 px containers — styled by its container width, not the screen.',
          children: <Widget>[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: FwRow(
                gap: 4,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[_cq(context, 320), _cq(context, 700), _cq(context, 820)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cq(BuildContext context, double width) {
    final t = context.fw;
    return SizedBox(
      width: width,
      child: Center(child: Text('${width.toInt()} px').tw.weight(FwFontWeight.semibold)).tw
          .p(4)
          .wFull
          .rounded(t.radii.md)
          .border(1, color: t.colors.border)
          .bg(t.colors.muted)
          .text(t.colors.mutedForeground)
          .containerSm((s) => s.bg(t.colors.secondary).text(t.colors.secondaryForeground))
          .containerMd((s) => s.bg(t.colors.primary).text(t.colors.primaryForeground)),
    );
  }
}

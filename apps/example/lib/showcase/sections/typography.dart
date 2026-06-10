// Typography section: the text `.tw` setters — color, size, weight, leading,
// tracking, alignment, and the combining underline/line-through decorations.
import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

import '../common.dart';

/// Demonstrates the typography `.tw` setters over DefaultTextStyle merging.
class TypographySection extends StatelessWidget {
  const TypographySection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    return FwColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      gap: 4,
      children: <Widget>[
        ShowcaseSection(
          title: 'Size & weight',
          children: <Widget>[
            const Text(
              'Display · xl4 / black',
            ).tw.textSize(FwFontSize.xl4.px).weight(FwFontWeight.black).leading(FwLeading.tight),
            const Text(
              'Heading · xl2 / bold',
            ).tw.textSize(FwFontSize.xl2.px).weight(FwFontWeight.bold),
            const Text(
              'Title · xl / semibold',
            ).tw.textSize(FwFontSize.xl.px).weight(FwFontWeight.semibold),
            const Text(
              'Body · base / normal — the quick brown fox jumps over the lazy dog.',
            ).tw.textSize(FwFontSize.base.px),
            const Text(
              'Caption · sm / medium',
            ).tw.textSize(FwFontSize.sm.px).weight(FwFontWeight.medium),
          ],
        ),
        ShowcaseSection(
          title: 'Color',
          description: 'text(color) sets the foreground; resolves against the theme.',
          children: <Widget>[
            FwWrap(
              gap: 4,
              runGap: 2,
              children: <Widget>[
                Text('foreground').tw.text(t.colors.foreground),
                Text('mutedForeground').tw.text(t.colors.mutedForeground),
                Text('primary').tw.text(t.colors.primary).weight(FwFontWeight.semibold),
                Text('destructive').tw.text(t.colors.destructive).weight(FwFontWeight.semibold),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Leading (line height)',
          children: <Widget>[
            FwRow(
              gap: 6,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _para(context, 'tight', FwLeading.tight),
                _para(context, 'normal', FwLeading.normal),
                _para(context, 'loose', FwLeading.loose),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Tracking (letter spacing)',
          description:
              'tracking() takes absolute px — multiply the em FwTracking scale by the font size '
              '(here ×lg). Most visible on caps.',
          children: <Widget>[
            for (final (label, em) in const <(String, double)>[
              ('tighter', FwTracking.tighter),
              ('tight', FwTracking.tight),
              ('normal', FwTracking.normal),
              ('wide', FwTracking.wide),
              ('wider', FwTracking.wider),
              ('widest', FwTracking.widest),
            ])
              Text(
                '$label · LETTER SPACING',
              ).tw.tracking(em * FwFontSize.lg.px).textSize(FwFontSize.lg.px),
          ],
        ),
        ShowcaseSection(
          title: 'Alignment & decorations',
          children: <Widget>[
            DemoTile(
              label: 'align: start / center / end',
              child: FwColumn(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                gap: 1,
                children: <Widget>[
                  Text('start').tw.align(TextAlign.start),
                  Text('center').tw.align(TextAlign.center),
                  Text('end').tw.align(TextAlign.end),
                ],
              ),
            ),
            DemoTile(
              label: 'underline · lineThrough · both combine',
              child: FwWrap(
                gap: 5,
                runGap: 2,
                children: <Widget>[
                  Text('underline').tw.underline.text(t.colors.primary),
                  Text('lineThrough').tw.lineThrough.text(t.colors.mutedForeground),
                  Text('overline').tw.overline.text(t.colors.primary),
                  Text('all three').tw.underline.lineThrough.overline.text(t.colors.destructive),
                ],
              ),
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Truncation, wrapping & family (module 11)',
          children: <Widget>[
            DemoTile(
              label: 'truncate (1 line + ellipsis)',
              child: SizedBox(
                width: 220,
                child:
                    const Text(
                      'A single very long line that will be ellipsized at the edge of the box.',
                    ).tw.truncate,
              ),
            ),
            DemoTile(
              label: 'lineClamp(2)',
              child: SizedBox(
                width: 220,
                child: const Text(
                  'Tailwind line-clamp-2: this paragraph is capped at two lines and then '
                  'ellipsized, no matter how much text follows after the clamp point.',
                ).tw.lineClamp(2),
              ),
            ),
            DemoTile(
              label: 'maxLines(2) + overflow(fade)',
              child: SizedBox(
                width: 220,
                child: const Text(
                  'maxLines caps the line count; overflow picks how the cut edge looks — here '
                  'a soft fade rather than an ellipsis, after two full lines of text.',
                ).tw.maxLines(2).overflow(TextOverflow.fade),
              ),
            ),
            DemoTile(
              label: 'nowrap (whitespace-nowrap, one line)',
              child: SizedBox(
                width: 220,
                child:
                    const Text(
                      'nowrap keeps this on a single line even though it is far too long to fit.',
                    ).tw.nowrap,
              ),
            ),
            DemoTile(
              label: 'font family: sans · serif · mono',
              child: FwColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                gap: 1,
                children: <Widget>[
                  const Text('The quick brown fox — sans').tw.fontSans,
                  const Text('The quick brown fox — serif').tw.fontSerif,
                  const Text('The quick brown fox — mono').tw.fontMono,
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _para(BuildContext context, String label, double leading) {
    final t = context.fw;
    return FwColumn(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      gap: 1,
      children: <Widget>[
        Text(label).tw.textSize(FwFontSize.xs.px).text(t.colors.mutedForeground),
        SizedBox(
          width: 130,
          child: Text(
            'three short lines of body text shown here to reveal line height',
          ).tw.textSize(FwFontSize.sm.px).leading(leading),
        ),
      ],
    );
  }
}

// Interactivity section (module 13): cursor, pointer-events, visibility, and the
// italic typography toggle. Some effects (cursor) only show with a live pointer.
import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

import '../common.dart';

/// Demonstrates the module 13 interactivity + visibility utilities.
class InteractivitySection extends StatelessWidget {
  const InteractivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    return FwColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      gap: 4,
      children: <Widget>[
        ShowcaseSection(
          title: 'Cursor',
          description: 'cursor(SystemMouseCursors.*) — hover with a pointer to see each cursor.',
          children: <Widget>[
            FwWrap(
              gap: 4,
              runGap: 4,
              children: <Widget>[
                _cursorChip(context, 'click', SystemMouseCursors.click),
                _cursorChip(context, 'text', SystemMouseCursors.text),
                _cursorChip(context, 'grab', SystemMouseCursors.grab),
                _cursorChip(context, 'forbidden', SystemMouseCursors.forbidden),
                _cursorChip(context, 'resizeColumn', SystemMouseCursors.resizeColumn),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Pointer-events & visibility',
          description:
              'pointerEventsNone ignores taps; invisible hides the box but keeps its space.',
          children: <Widget>[
            DemoTile(
              label: 'invisible (middle box) keeps its layout slot',
              child: FwRow(
                gap: 3,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _box(context, 'a', BlockTone.primary),
                  _box(context, 'b', BlockTone.accent).tw.invisible,
                  _box(context, 'c', BlockTone.secondary),
                ],
              ),
            ),
            DemoTile(
              label: 'pointerEventsNone — this chip ignores pointer input',
              child:
                  Text('inert').tw
                      .px(4)
                      .py(2)
                      .rounded(t.radii.md)
                      .bg(t.colors.muted)
                      .text(t.colors.mutedForeground)
                      .pointerEventsNone,
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Italic',
          children: <Widget>[
            const Text(
              'Normal then italic — emphasis via fontStyle.',
            ).tw.textSize(FwFontSize.lg.px),
            const Text('Italic body text (Tailwind italic).').tw.italic.textSize(FwFontSize.lg.px),
          ],
        ),
      ],
    );
  }

  Widget _cursorChip(BuildContext context, String label, MouseCursor cursor) {
    final t = context.fw;
    return Text(label).tw
        .px(4)
        .py(3)
        .weight(FwFontWeight.semibold)
        .rounded(t.radii.md)
        .bg(t.colors.secondary)
        .text(t.colors.secondaryForeground)
        .border(1, color: t.colors.border)
        .cursor(cursor);
  }

  Widget _box(BuildContext context, String label, BlockTone tone) =>
      Block(label: label, tone: tone, height: 9, width: 10);
}

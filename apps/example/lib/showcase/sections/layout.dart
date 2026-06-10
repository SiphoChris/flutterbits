// Layout & grid section: the dedicated multi-child widgets the single-box `.tw`
// chain cannot express — FwRow/FwColumn (typed gap + alignment), FwWrap,
// FwStack/FwPositioned (directional inset + z-order), and the real CSS-grid
// FwGrid (fr/px/auto/minmax tracks, spanning, placement, dense auto-placement,
// item alignment, track distribution, responsive columns).
import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

import '../common.dart';

/// Demonstrates every layout widget and the grid feature set.
class LayoutSection extends StatelessWidget {
  const LayoutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return FwColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      gap: 4,
      children: <Widget>[
        _rowColumn(context),
        _wrap(context),
        _stack(context),
        _gridTracks(context),
        _gridSpanning(context),
        _gridDense(context),
        _gridAlignment(context),
        _gridDistribution(context),
        _gridResponsive(context),
      ],
    );
  }

  // --- Row & Column ---------------------------------------------------------

  Widget _rowColumn(BuildContext context) {
    Widget row(MainAxisAlignment a) => FwRow(
      gap: 2,
      mainAxisAlignment: a,
      children: <Widget>[
        for (final l in const <String>['1', '2', '3'])
          Block(label: l, tone: BlockTone.primary, height: 9, width: 12),
      ],
    );
    return ShowcaseSection(
      title: 'FwRow & FwColumn',
      description:
          'Typed gap (utility units) via native Flex.spacing; directional, RTL-aware alignment.',
      children: <Widget>[
        DemoTile(label: 'mainAxisAlignment: start', child: row(MainAxisAlignment.start)),
        DemoTile(label: 'center', child: row(MainAxisAlignment.center)),
        DemoTile(label: 'spaceBetween', child: row(MainAxisAlignment.spaceBetween)),
        DemoTile(
          label: 'FwColumn gap(2)',
          child: FwColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            gap: 2,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Block(label: 'a', tone: BlockTone.secondary, height: 8),
              Block(label: 'b', tone: BlockTone.secondary, height: 8),
            ],
          ),
        ),
      ],
    );
  }

  // --- Wrap -----------------------------------------------------------------

  Widget _wrap(BuildContext context) {
    return ShowcaseSection(
      title: 'FwWrap',
      description:
          'Flows children and wraps to new runs; independent gap (main) and runGap (cross).',
      children: <Widget>[
        FwWrap(
          gap: 3,
          runGap: 3,
          children: <Widget>[
            for (var i = 1; i <= 12; i++)
              Block(label: '$i', tone: BlockTone.accent, height: 9, width: 14),
          ],
        ),
      ],
    );
  }

  // --- Stack & Positioned ---------------------------------------------------

  Widget _stack(BuildContext context) {
    final t = context.fw;
    return ShowcaseSection(
      title: 'FwStack & FwPositioned',
      description: 'Directional inset (start/end mirror under RTL) and explicit z paint-order.',
      children: <Widget>[
        FwStack(
          children: <Widget>[
            Center(
              child: Text('base layer').tw.weight(FwFontWeight.semibold),
            ).tw.h(24).wFull.bg(t.colors.muted).text(t.colors.mutedForeground).rounded(t.radii.md),
            // z-order: the accent (z:0) is declared AFTER the primary (z:1) but
            // paints under it, proving z wins over child order.
            FwPositioned(
              top: 3,
              start: 3,
              z: 1,
              child: _badge(context, 'z: 1', t.colors.primary, t.colors.primaryForeground),
            ),
            FwPositioned(
              top: 6,
              start: 8,
              z: 0,
              child: _badge(context, 'z: 0', t.colors.accent, t.colors.accentForeground),
            ),
            FwPositioned(
              top: 2,
              end: 2,
              child: _badge(
                context,
                'end-anchored',
                t.colors.destructive,
                t.colors.destructiveForeground,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _badge(BuildContext context, String label, Color bg, Color fg) {
    final t = context.fw;
    return Text(label).tw
        .px(3)
        .py(2)
        .textSize(FwFontSize.xs.px)
        .weight(FwFontWeight.bold)
        .bg(bg)
        .text(fg)
        .rounded(t.radii.md);
  }

  // --- Grid: tracks ---------------------------------------------------------

  Widget _gridTracks(BuildContext context) {
    return ShowcaseSection(
      title: 'FwGrid — tracks (px / fr / auto / minmax)',
      description: 'Mixed column track functions; auto sizes to content, fr shares the rest.',
      children: <Widget>[
        DemoTile(
          label: 'columns: 60px · 1fr · 2fr · auto',
          child: FwGrid(
            columnGap: 2,
            rowGap: 2,
            columns: <FwGridTrack>[const FwPx(60), const FwFr(), const FwFr(2), const FwAuto()],
            children: const <Widget>[
              Block(label: '60px', tone: BlockTone.primary),
              Block(label: '1fr', tone: BlockTone.secondary),
              Block(label: '2fr', tone: BlockTone.accent),
              Block(label: 'auto', tone: BlockTone.muted),
            ],
          ),
        ),
        DemoTile(
          label: 'columns: minmax(80, 1fr) · minmax(40, 120px)',
          child: FwGrid(
            columnGap: 2,
            rowGap: 2,
            columns: <FwGridTrack>[const FwMinMax(80, FwFr()), const FwMinMax(40, FwPx(120))],
            children: const <Widget>[
              Block(label: 'flex floor 80', tone: BlockTone.primary),
              Block(label: '≤120', tone: BlockTone.accent),
            ],
          ),
        ),
      ],
    );
  }

  // --- Grid: spanning & placement ------------------------------------------

  Widget _gridSpanning(BuildContext context) {
    return ShowcaseSection(
      title: 'FwGrid — spanning & explicit placement',
      description: 'FwGridItem: columnSpan / rowSpan and 1-based columnStart / rowStart.',
      children: <Widget>[
        FwGrid(
          columnGap: 2,
          rowGap: 2,
          columns: FwTrack.repeat(3, const FwFr()),
          children: <Widget>[
            const FwGridItem(
              columnSpan: 2,
              child: Block(label: 'columnSpan: 2', tone: BlockTone.primary),
            ),
            const Block(label: 'auto', tone: BlockTone.muted),
            const FwGridItem(
              rowSpan: 2,
              child: Block(label: 'rowSpan: 2', tone: BlockTone.accent, height: 24),
            ),
            const Block(label: 'auto', tone: BlockTone.muted),
            const Block(label: 'auto', tone: BlockTone.muted),
            const FwGridItem(
              columnStart: 2,
              child: Block(label: 'columnStart: 2', tone: BlockTone.secondary),
            ),
          ],
        ),
      ],
    );
  }

  // --- Grid: dense auto-placement ------------------------------------------

  Widget _gridDense(BuildContext context) {
    return ShowcaseSection(
      title: 'FwGrid — dense auto-placement',
      description: 'dense back-fills holes left by wide items earlier in the flow.',
      children: <Widget>[
        FwGrid(
          dense: true,
          columnGap: 2,
          rowGap: 2,
          columns: FwTrack.repeat(4, const FwFr()),
          children: <Widget>[
            const FwGridItem(columnSpan: 3, child: Block(label: 'span 3', tone: BlockTone.primary)),
            const Block(label: '1', tone: BlockTone.muted),
            const Block(label: '2', tone: BlockTone.muted),
            const FwGridItem(columnSpan: 2, child: Block(label: 'span 2', tone: BlockTone.accent)),
            const Block(label: '3', tone: BlockTone.muted),
          ],
        ),
      ],
    );
  }

  // --- Grid: item alignment -------------------------------------------------

  Widget _gridAlignment(BuildContext context) {
    Widget grid(FwGridAlign align, FwGridAlign justify) => FwGrid(
      columnGap: 2,
      rowGap: 2,
      autoRows: const FwPx(56),
      alignItems: align,
      justifyItems: justify,
      columns: FwTrack.repeat(3, const FwFr()),
      children: const <Widget>[
        Block(label: 'a', tone: BlockTone.primary, height: 6, width: 10),
        Block(label: 'b', tone: BlockTone.secondary, height: 6, width: 10),
        Block(label: 'c', tone: BlockTone.accent, height: 6, width: 10),
      ],
    );
    return ShowcaseSection(
      title: 'FwGrid — item alignment',
      description:
          'alignItems (block axis) & justifyItems (inline axis, RTL-aware) within taller cells.',
      children: <Widget>[
        DemoTile(
          label: 'alignItems: start · justifyItems: start',
          child: grid(FwGridAlign.start, FwGridAlign.start),
        ),
        DemoTile(
          label: 'alignItems: center · justifyItems: center',
          child: grid(FwGridAlign.center, FwGridAlign.center),
        ),
        DemoTile(
          label: 'alignItems: end · justifyItems: end',
          child: grid(FwGridAlign.end, FwGridAlign.end),
        ),
        DemoTile(
          label: 'per-item alignSelf / justifySelf override the container',
          child: FwGrid(
            columnGap: 2,
            rowGap: 2,
            autoRows: const FwPx(56),
            alignItems: FwGridAlign.start, // container default: top + start
            justifyItems: FwGridAlign.start,
            columns: FwTrack.repeat(3, const FwFr()),
            children: const <Widget>[
              Block(label: 'a', tone: BlockTone.primary, height: 6, width: 10),
              FwGridItem(
                alignSelf: FwGridAlign.center, // this item: vertically centered…
                justifySelf: FwGridAlign.end, // …and pushed to the inline end
                child: Block(label: 'self', tone: BlockTone.accent, height: 6, width: 10),
              ),
              Block(label: 'c', tone: BlockTone.secondary, height: 6, width: 10),
            ],
          ),
        ),
      ],
    );
  }

  // --- Grid: track distribution --------------------------------------------

  Widget _gridDistribution(BuildContext context) {
    Widget grid(FwGridDistribute dist) => FwGrid(
      rowGap: 2,
      justifyContent: dist,
      columns: const <FwGridTrack>[FwPx(56), FwPx(56), FwPx(56)],
      children: const <Widget>[
        Block(label: '1', tone: BlockTone.primary),
        Block(label: '2', tone: BlockTone.secondary),
        Block(label: '3', tone: BlockTone.accent),
      ],
    );
    return ShowcaseSection(
      title: 'FwGrid — track distribution',
      description: 'justifyContent spreads spare space when fixed (px) tracks do not fill the row.',
      children: <Widget>[
        DemoTile(label: 'spaceBetween', child: grid(FwGridDistribute.spaceBetween)),
        DemoTile(label: 'spaceAround', child: grid(FwGridDistribute.spaceAround)),
        DemoTile(label: 'center', child: grid(FwGridDistribute.center)),
      ],
    );
  }

  // --- Grid: responsive columns --------------------------------------------

  Widget _gridResponsive(BuildContext context) {
    return ShowcaseSection(
      title: 'FwGrid — responsive columns',
      description:
          'grid-cols-2 md:grid-cols-4 — column count changes at the md viewport breakpoint.',
      children: <Widget>[
        FwGrid(
          columnGap: 3,
          rowGap: 3,
          columns: FwTrack.repeat(2, const FwFr()),
          viewport: <FwBreakpoint, FwGridPatch>{
            FwBreakpoint.md: FwGridPatch(columns: FwTrack.repeat(4, const FwFr())),
          },
          children: <Widget>[
            for (var i = 1; i <= 8; i++) Block(label: 'Cell $i', tone: BlockTone.muted),
          ],
        ),
      ],
    );
  }
}

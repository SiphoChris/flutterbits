// Group & peer section (module 14): Tailwind group-*/peer-* state propagation.
//
// - FwGroup sources its own hover/focus/pressed and broadcasts to descendants;
//   a `.tw` child reacts with groupHover/groupFocus/… No per-child wiring.
// - FwPeer (inside the same FwGroup scope) publishes its state so a SIBLING
//   reacts with peerHover/…. Flutter has no sibling selectors, so the FwGroup is
//   the explicit shared scope.
// - Named groups (group/name) let a nested reactor target an outer group.
import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

import '../common.dart';

/// Demonstrates group/peer state propagation (hover with a pointer to drive it).
class GroupPeerSection extends StatelessWidget {
  const GroupPeerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return FwColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      gap: 4,
      children: <Widget>[
        ShowcaseSection(
          title: 'group-hover',
          description:
              'Hover anywhere on the card — the title and the chip react to the GROUP, not '
              'themselves.',
          children: <Widget>[const _GroupCard()],
        ),
        ShowcaseSection(
          title: 'peer-hover / peer-focus',
          description:
              'Hover (or, on web/desktop, focus) the first chip — its SIBLING label reacts via '
              'peer-*. The peer styles nothing on itself.',
          children: <Widget>[const _PeerRow()],
        ),
        ShowcaseSection(
          title: 'Named group (nested)',
          description:
              'The inner box targets the OUTER group by name — hover the outer card padding and '
              'it still reacts.',
          children: <Widget>[const _NamedGroup()],
        ),
      ],
    );
  }
}

/// A card whose children react to the card (group) being hovered.
class _GroupCard extends StatelessWidget {
  const _GroupCard();

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    return FwGroup(
      child: FwColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            gap: 3,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Project Atlas').tw
                  .weight(FwFontWeight.semibold)
                  .text(t.colors.foreground)
                  .groupHover((s) => s.text(t.colors.primary)),
              Text('Hover the card').tw.textSize(FwFontSize.sm.px).text(t.colors.mutedForeground),
              Text('Open').tw
                  .px(3)
                  .py(2)
                  .textSize(FwFontSize.sm.px)
                  .weight(FwFontWeight.semibold)
                  .rounded(t.radii.md)
                  .bg(t.colors.secondary)
                  .text(t.colors.secondaryForeground)
                  .groupHover((s) => s.bg(t.colors.primary).text(t.colors.primaryForeground)),
            ],
          ).tw
          .p(4)
          .rounded(t.radii.lg)
          .bg(t.colors.card)
          .border(1, color: t.colors.border)
          .groupHover((s) => s.border(1, color: t.colors.primary).shadow(t.shadows.md)),
    );
  }
}

/// A peer chip and a sibling label that reacts to the peer's hover/focus.
class _PeerRow extends StatelessWidget {
  const _PeerRow();

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    return FwGroup(
      child: FwRow(
        gap: 4,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          FwPeer(
            child: Text('Hover me (peer)').tw
                .px(3)
                .py(2)
                .weight(FwFontWeight.semibold)
                .rounded(t.radii.md)
                .bg(t.colors.secondary)
                .text(t.colors.secondaryForeground)
                .border(1, color: t.colors.border),
          ),
          Text('← reacts to the peer').tw
              .textSize(FwFontSize.sm.px)
              .text(t.colors.mutedForeground)
              .peerHover((s) => s.text(t.colors.primary).weight(FwFontWeight.bold))
              .peerFocus((s) => s.text(t.colors.primary)),
        ],
      ),
    );
  }
}

/// A nested group: the inner reactor targets the outer group by name.
class _NamedGroup extends StatelessWidget {
  const _NamedGroup();

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    return FwGroup(
      name: 'card',
      child: FwColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        gap: 3,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Outer card (group/card)',
          ).tw.textSize(FwFontSize.sm.px).text(t.colors.mutedForeground),
          // A closer group would shadow an unnamed group-hover; naming targets
          // the outer one explicitly.
          FwGroup(
            child: Text('I follow the OUTER group').tw
                .px(3)
                .py(2)
                .weight(FwFontWeight.semibold)
                .rounded(t.radii.md)
                .bg(t.colors.muted)
                .text(t.colors.mutedForeground)
                .groupHover(
                  (s) => s.bg(t.colors.primary).text(t.colors.primaryForeground),
                  name: 'card',
                ),
          ),
        ],
      ).tw.p(5).rounded(t.radii.lg).bg(t.colors.card).border(1, color: t.colors.border),
    );
  }
}

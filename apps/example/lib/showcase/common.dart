// Shared scaffolding for the flutterwindcss showcase: the category enum, the
// titled section card, demo tiles, and small styled helpers reused across every
// section. Everything here is styled through `.tw` + `context.fw` (no Material).
import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

/// The top-level showcase categories, in display order. Each maps to one
/// section widget in `showcase_app.dart`.
enum ShowcaseCategory {
  tokens('Tokens'),
  paletteScales('Palette & scales'),
  spacing('Spacing & sizing'),
  decoration('Color · border · radius'),
  typography('Typography'),
  effects('Effects'),
  transforms('Transforms'),
  states('States'),
  responsive('Responsive'),
  layout('Layout & grid');

  const ShowcaseCategory(this.label);

  /// Human-readable tab label.
  final String label;
}

/// A titled card that groups related demos, with an optional description.
class ShowcaseSection extends StatelessWidget {
  const ShowcaseSection({required this.title, required this.children, this.description, super.key});

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    return FwColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          gap: 4,
          children: <Widget>[
            Text(title.toUpperCase()).tw
                .textSize(FwFontSize.xs.px)
                .weight(FwFontWeight.bold)
                .tracking(FwTracking.wider)
                .text(t.colors.mutedForeground),
            if (description != null)
              Text(description!).tw.textSize(FwFontSize.sm.px).text(t.colors.mutedForeground),
            ...children,
          ],
        ).tw
        .p(5)
        .bg(t.colors.card)
        .rounded(t.radii.lg)
        .border(1, color: t.colors.border)
        .shadow(t.shadows.sm);
  }
}

/// A single demo with a small caption above it.
class DemoTile extends StatelessWidget {
  const DemoTile({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    return FwColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      gap: 2,
      children: <Widget>[
        Text(label).tw.textSize(FwFontSize.xs.px).text(t.colors.mutedForeground),
        child,
      ],
    );
  }
}

/// A small labeled box that shrink-wraps its label, styled by [style]. Avoids
/// `Center` (which stretches under a `Wrap`'s bounded width) so chips flow
/// side-by-side.
Widget demoChip(String label, FwStyled Function(FwStyled base) style) {
  final base = Text(label).tw.textSize(FwFontSize.xs.px).weight(FwFontWeight.semibold).px(3).py(2);
  return style(base);
}

/// A fixed-size labeled swatch for color tokens.
class Swatch extends StatelessWidget {
  const Swatch({required this.name, required this.bg, required this.fg, super.key});

  final String name;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    return Center(
      child: Text(name).tw.textSize(FwFontSize.xs.px).weight(FwFontWeight.semibold),
    ).tw.w(26).h(16).bg(bg).text(fg).rounded(t.radii.md).border(1, color: t.colors.border);
  }
}

/// A neutral filled block used as generic demo content (e.g. inside layout
/// containers). [label] is centered; [tone] picks the fill. With no [width] it
/// fills the width its parent gives it (e.g. a grid cell); pass [width] (utility
/// units) to size the coloured box itself (e.g. inside a Row/Wrap).
class Block extends StatelessWidget {
  const Block({
    required this.label,
    this.tone = BlockTone.muted,
    this.height = 12,
    this.width,
    super.key,
  });

  final String label;
  final BlockTone tone;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    final (bg, fg) = switch (tone) {
      BlockTone.primary => (t.colors.primary, t.colors.primaryForeground),
      BlockTone.secondary => (t.colors.secondary, t.colors.secondaryForeground),
      BlockTone.accent => (t.colors.accent, t.colors.accentForeground),
      BlockTone.muted => (t.colors.muted, t.colors.mutedForeground),
    };
    var box = Center(
      child: Text(label).tw.textSize(FwFontSize.sm.px).weight(FwFontWeight.semibold),
    ).tw.h(height).bg(bg).text(fg).rounded(t.radii.md);
    if (width != null) {
      box = box.w(width!);
    }
    return box;
  }
}

/// Fill tones for [Block].
enum BlockTone { primary, secondary, accent, muted }

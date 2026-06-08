import 'package:flutter/widgets.dart';

import '../tokens/scales.dart';
import 'fw_responsive.dart';

/// A per-breakpoint override of an [FwRow]/[FwColumn]'s layout properties
/// (spec §6.6). A bag of nullable fields: a `null` field leaves the widget's base
/// value untouched, so a patch only changes what it names. Supplied via the
/// `viewport`/`container` maps on the flex widgets, it makes `gap`/alignment
/// responsive (`gap-2 md:gap-6` in Tailwind terms).
@immutable
class FwFlexPatch {
  /// Creates a flex override. A non-null [gap] must be `>= 0`.
  const FwFlexPatch({this.gap, this.mainAxisAlignment, this.crossAxisAlignment, this.mainAxisSize})
    : assert(gap == null || gap >= 0, 'flutterwindcss: gap must be >= 0 (got $gap).');

  /// Overriding gap in utility units (× 4 logical px), or `null` to keep the base.
  final double? gap;

  /// Overriding main-axis alignment, or `null` to keep the base.
  final MainAxisAlignment? mainAxisAlignment;

  /// Overriding cross-axis alignment, or `null` to keep the base.
  final CrossAxisAlignment? crossAxisAlignment;

  /// Overriding main-axis size, or `null` to keep the base.
  final MainAxisSize? mainAxisSize;
}

/// A horizontal flex row with a typed [gap] (spec §6.6). Like Tailwind's
/// `flex flex-row gap-*`. Directional: children flow start→end, mirroring in RTL
/// (the underlying [Flex] honors [Directionality]).
///
/// [gap] is in **utility units** (1 unit = 4 logical px) and renders via the
/// framework's native [Flex.spacing] (guaranteed by the toolchain floor,
/// AGENTS.md §2). [mainAxisSize] defaults to [MainAxisSize.max] (Flutter's
/// default); pass [MainAxisSize.min] for shrink-to-fit. Style the row as a box by
/// chaining `.tw` (e.g. `FwRow(...).tw.p(4).bg(c)`).
///
/// **Responsive:** pass [viewport] and/or [container] maps of [FwFlexPatch] keyed
/// by [FwBreakpoint] to vary `gap`/alignment by screen or container width
/// (mobile-first, largest matching breakpoint wins). A row with neither map
/// resolves statically and inserts no `MediaQuery`/`LayoutBuilder` (spec §6.6).
class FwRow extends StatelessWidget {
  /// Creates a horizontal flex. [gap] must be `>= 0`.
  const FwRow({
    required this.children,
    this.gap = 0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.divideWidth = 0,
    this.divideColor,
    this.viewport,
    this.container,
    super.key,
  }) : assert(gap >= 0, 'flutterwindcss: gap must be >= 0 (got $gap).'),
       assert(divideWidth >= 0, 'flutterwindcss: divideWidth must be >= 0 (got $divideWidth).'),
       assert(
         divideWidth == 0 || divideColor != null,
         'flutterwindcss: divideWidth > 0 requires a divideColor (e.g. '
         'context.fw.colors.border).',
       );

  /// The row's children, in start→end order.
  final List<Widget> children;

  /// Space between children, in utility units (× 4 logical px).
  final double gap;

  /// Alignment along the main (horizontal) axis.
  final MainAxisAlignment mainAxisAlignment;

  /// Alignment along the cross (vertical) axis.
  final CrossAxisAlignment crossAxisAlignment;

  /// Whether the row shrink-wraps its children ([MainAxisSize.min]) or fills the
  /// available main-axis extent ([MainAxisSize.max], the default).
  final MainAxisSize mainAxisSize;

  /// Divider thickness in **logical px** (Tailwind `divide-x`). When `> 0`, an
  /// **end-edge** border (RTL-aware) is drawn on every child except the last —
  /// a border *between* children, exactly like Tailwind's
  /// `& > :not(:last-child) { border-inline-end-width }`. Requires [divideColor].
  final double divideWidth;

  /// Divider colour (Tailwind `divide-<color>`); pass a token such as
  /// `context.fw.colors.border`. Required when [divideWidth] `> 0`.
  final Color? divideColor;

  /// Viewport-breakpoint overrides (keyed off the screen width).
  final Map<FwBreakpoint, FwFlexPatch>? viewport;

  /// Container-breakpoint overrides (keyed off the enclosing constraint width).
  final Map<FwBreakpoint, FwFlexPatch>? container;

  @override
  Widget build(BuildContext context) => _buildFlex(Axis.horizontal, _Flexish.row(this), context);
}

/// A vertical flex column with a typed [gap] (spec §6.6). Like Tailwind's
/// `flex flex-col gap-*`. See [FwRow] for the [gap]/[mainAxisSize] and
/// [viewport]/[container] responsive semantics; the cross axis here is
/// horizontal, so [crossAxisAlignment] is RTL-aware.
class FwColumn extends StatelessWidget {
  /// Creates a vertical flex. [gap] must be `>= 0`.
  const FwColumn({
    required this.children,
    this.gap = 0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.divideWidth = 0,
    this.divideColor,
    this.viewport,
    this.container,
    super.key,
  }) : assert(gap >= 0, 'flutterwindcss: gap must be >= 0 (got $gap).'),
       assert(divideWidth >= 0, 'flutterwindcss: divideWidth must be >= 0 (got $divideWidth).'),
       assert(
         divideWidth == 0 || divideColor != null,
         'flutterwindcss: divideWidth > 0 requires a divideColor (e.g. '
         'context.fw.colors.border).',
       );

  /// The column's children, in top→bottom order.
  final List<Widget> children;

  /// Space between children, in utility units (× 4 logical px).
  final double gap;

  /// Alignment along the main (vertical) axis.
  final MainAxisAlignment mainAxisAlignment;

  /// Alignment along the cross (horizontal) axis (RTL-aware).
  final CrossAxisAlignment crossAxisAlignment;

  /// Whether the column shrink-wraps ([MainAxisSize.min]) or fills the main-axis
  /// extent ([MainAxisSize.max], the default).
  final MainAxisSize mainAxisSize;

  /// Divider thickness in **logical px** (Tailwind `divide-y`). When `> 0`, a
  /// **bottom** border is drawn on every child except the last — a border
  /// *between* children. Requires [divideColor].
  final double divideWidth;

  /// Divider colour (Tailwind `divide-<color>`); pass a token such as
  /// `context.fw.colors.border`. Required when [divideWidth] `> 0`.
  final Color? divideColor;

  /// Viewport-breakpoint overrides (keyed off the screen width).
  final Map<FwBreakpoint, FwFlexPatch>? viewport;

  /// Container-breakpoint overrides (keyed off the enclosing constraint width).
  final Map<FwBreakpoint, FwFlexPatch>? container;

  @override
  Widget build(BuildContext context) => _buildFlex(Axis.vertical, _Flexish.column(this), context);
}

// ---- Shared flex builder (FwRow and FwColumn differ only in axis) ----

/// A read-only view over the flex fields shared by [FwRow]/[FwColumn], so the
/// resolution + build logic lives in exactly one place.
class _Flexish {
  const _Flexish({
    required this.children,
    required this.gap,
    required this.mainAxisAlignment,
    required this.crossAxisAlignment,
    required this.mainAxisSize,
    required this.divideWidth,
    required this.divideColor,
    required this.viewport,
    required this.container,
  });

  factory _Flexish.row(FwRow r) => _Flexish(
    children: r.children,
    gap: r.gap,
    mainAxisAlignment: r.mainAxisAlignment,
    crossAxisAlignment: r.crossAxisAlignment,
    mainAxisSize: r.mainAxisSize,
    divideWidth: r.divideWidth,
    divideColor: r.divideColor,
    viewport: r.viewport,
    container: r.container,
  );

  factory _Flexish.column(FwColumn c) => _Flexish(
    children: c.children,
    gap: c.gap,
    mainAxisAlignment: c.mainAxisAlignment,
    crossAxisAlignment: c.crossAxisAlignment,
    mainAxisSize: c.mainAxisSize,
    divideWidth: c.divideWidth,
    divideColor: c.divideColor,
    viewport: c.viewport,
    container: c.container,
  );

  final List<Widget> children;
  final double gap;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double divideWidth;
  final Color? divideColor;
  final Map<FwBreakpoint, FwFlexPatch>? viewport;
  final Map<FwBreakpoint, FwFlexPatch>? container;
}

/// Wraps each child except the last in a trailing-edge border (Tailwind
/// `divide`): an **end** border for a row, a **bottom** border for a column —
/// a separator *between* children. Returns [children] unchanged when no divider.
List<Widget> _withDividers(List<Widget> children, Axis direction, double width, Color? color) {
  if (width <= 0 || color == null || children.length < 2) return children;
  final side = BorderSide(width: width, color: color);
  final border =
      direction == Axis.horizontal ? BorderDirectional(end: side) : BorderDirectional(bottom: side);
  final decoration = BoxDecoration(border: border);
  return <Widget>[
    for (var i = 0; i < children.length; i++)
      if (i == children.length - 1)
        children[i]
      else
        DecoratedBox(decoration: decoration, child: children[i]),
  ];
}

/// Builds the [Flex] for a row or column, resolving any responsive patches
/// against the active widths first.
Widget _buildFlex(Axis direction, _Flexish f, BuildContext context) {
  final children = _withDividers(f.children, direction, f.divideWidth, f.divideColor);
  Widget flexWith(double gap, MainAxisAlignment maa, CrossAxisAlignment caa, MainAxisSize mas) =>
      Flex(
        direction: direction,
        mainAxisAlignment: maa,
        crossAxisAlignment: caa,
        mainAxisSize: mas,
        spacing: fwSpace(gap),
        children: children,
      );

  final hasV = fwHasViewport(f.viewport);
  final hasC = fwHasContainer(f.container);
  if (!hasV && !hasC) {
    return flexWith(f.gap, f.mainAxisAlignment, f.crossAxisAlignment, f.mainAxisSize);
  }

  return fwBuildResponsive(
    context,
    needsViewport: hasV,
    needsContainer: hasC,
    build: (vw, cw) {
      var gap = f.gap;
      var maa = f.mainAxisAlignment;
      var caa = f.crossAxisAlignment;
      var mas = f.mainAxisSize;
      for (final p in fwActivePatches(f.viewport, f.container, vw, cw)) {
        gap = p.gap ?? gap;
        maa = p.mainAxisAlignment ?? maa;
        caa = p.crossAxisAlignment ?? caa;
        mas = p.mainAxisSize ?? mas;
      }
      return flexWith(gap, maa, caa, mas);
    },
  );
}

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
    this.viewport,
    this.container,
    super.key,
  }) : assert(gap >= 0, 'flutterwindcss: gap must be >= 0 (got $gap).');

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
    this.viewport,
    this.container,
    super.key,
  }) : assert(gap >= 0, 'flutterwindcss: gap must be >= 0 (got $gap).');

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

  /// Viewport-breakpoint overrides (keyed off the screen width).
  final Map<FwBreakpoint, FwFlexPatch>? viewport;

  /// Container-breakpoint overrides (keyed off the enclosing constraint width).
  final Map<FwBreakpoint, FwFlexPatch>? container;

  @override
  Widget build(BuildContext context) =>
      _buildFlex(Axis.vertical, _Flexish.column(this), context);
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
    required this.viewport,
    required this.container,
  });

  factory _Flexish.row(FwRow r) => _Flexish(
    children: r.children,
    gap: r.gap,
    mainAxisAlignment: r.mainAxisAlignment,
    crossAxisAlignment: r.crossAxisAlignment,
    mainAxisSize: r.mainAxisSize,
    viewport: r.viewport,
    container: r.container,
  );

  factory _Flexish.column(FwColumn c) => _Flexish(
    children: c.children,
    gap: c.gap,
    mainAxisAlignment: c.mainAxisAlignment,
    crossAxisAlignment: c.crossAxisAlignment,
    mainAxisSize: c.mainAxisSize,
    viewport: c.viewport,
    container: c.container,
  );

  final List<Widget> children;
  final double gap;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final Map<FwBreakpoint, FwFlexPatch>? viewport;
  final Map<FwBreakpoint, FwFlexPatch>? container;
}

/// Builds the [Flex] for a row or column, resolving any responsive patches
/// against the active widths first.
Widget _buildFlex(Axis direction, _Flexish f, BuildContext context) {
  Widget flexWith(double gap, MainAxisAlignment maa, CrossAxisAlignment caa, MainAxisSize mas) =>
      Flex(
        direction: direction,
        mainAxisAlignment: maa,
        crossAxisAlignment: caa,
        mainAxisSize: mas,
        spacing: fwSpace(gap),
        children: f.children,
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

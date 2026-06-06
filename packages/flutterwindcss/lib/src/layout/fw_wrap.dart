import 'package:flutter/widgets.dart';

import '../tokens/scales.dart';
import 'fw_responsive.dart';

/// A per-breakpoint override of an [FwWrap]'s layout properties (spec §6.6). A bag
/// of nullable fields: `null` leaves the base value untouched. Supplied via the
/// `viewport`/`container` maps on [FwWrap] to make spacing/alignment responsive.
@immutable
class FwWrapPatch {
  /// Creates a wrap override. Non-null [gap]/[runGap] must be `>= 0`.
  const FwWrapPatch({
    this.gap,
    this.runGap,
    this.direction,
    this.alignment,
    this.runAlignment,
    this.crossAxisAlignment,
  }) : assert(gap == null || gap >= 0, 'flutterwindcss: gap must be >= 0 (got $gap).'),
       assert(runGap == null || runGap >= 0, 'flutterwindcss: runGap must be >= 0 (got $runGap).');

  /// Overriding between-children spacing (utility units), or `null`.
  final double? gap;

  /// Overriding between-runs spacing (utility units), or `null`.
  final double? runGap;

  /// Overriding flow direction, or `null`.
  final Axis? direction;

  /// Overriding within-run alignment, or `null`.
  final WrapAlignment? alignment;

  /// Overriding run alignment, or `null`.
  final WrapAlignment? runAlignment;

  /// Overriding cross-axis alignment within a run, or `null`.
  final WrapCrossAlignment? crossAxisAlignment;
}

/// A wrapping flow layout (spec §6.6) — Tailwind's `flex flex-wrap gap-*`.
/// Children flow along the main axis and wrap onto new runs when they overflow.
/// Directional: horizontal flow honors [Directionality] (RTL flows end→start).
///
/// [gap] is the **between-children** spacing within a run; [runGap] is the
/// spacing **between runs** — both in utility units (× 4 logical px). Style the
/// whole flow as a box by chaining `.tw`.
///
/// **Responsive:** pass [viewport]/[container] maps of [FwWrapPatch] keyed by
/// [FwBreakpoint] to vary spacing/alignment by screen or container width. A wrap
/// with neither map resolves statically (no `MediaQuery`/`LayoutBuilder`).
class FwWrap extends StatelessWidget {
  /// Creates a wrapping flow. [gap] and [runGap] must be `>= 0`.
  const FwWrap({
    required this.children,
    this.gap = 0,
    this.runGap = 0,
    this.direction = Axis.horizontal,
    this.alignment = WrapAlignment.start,
    this.runAlignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.viewport,
    this.container,
    super.key,
  }) : assert(gap >= 0, 'flutterwindcss: gap must be >= 0 (got $gap).'),
       assert(runGap >= 0, 'flutterwindcss: runGap must be >= 0 (got $runGap).');

  /// The children to flow.
  final List<Widget> children;

  /// Between-children spacing within a run, in utility units (× 4 logical px).
  final double gap;

  /// Between-runs spacing, in utility units (× 4 logical px).
  final double runGap;

  /// Main-axis flow direction (default horizontal).
  final Axis direction;

  /// Alignment of children within a run (main axis).
  final WrapAlignment alignment;

  /// Alignment of the runs within the cross axis.
  final WrapAlignment runAlignment;

  /// Alignment of children within a run on the cross axis.
  final WrapCrossAlignment crossAxisAlignment;

  /// Viewport-breakpoint overrides (keyed off the screen width).
  final Map<FwBreakpoint, FwWrapPatch>? viewport;

  /// Container-breakpoint overrides (keyed off the enclosing constraint width).
  final Map<FwBreakpoint, FwWrapPatch>? container;

  Widget _wrapWith(
    double gap,
    double runGap,
    Axis direction,
    WrapAlignment alignment,
    WrapAlignment runAlignment,
    WrapCrossAlignment crossAxisAlignment,
  ) => Wrap(
    direction: direction,
    spacing: fwSpace(gap),
    runSpacing: fwSpace(runGap),
    alignment: alignment,
    runAlignment: runAlignment,
    crossAxisAlignment: crossAxisAlignment,
    children: children,
  );

  @override
  Widget build(BuildContext context) {
    final hasV = fwHasViewport(viewport);
    final hasC = fwHasContainer(container);
    if (!hasV && !hasC) {
      return _wrapWith(gap, runGap, direction, alignment, runAlignment, crossAxisAlignment);
    }
    return fwBuildResponsive(
      context,
      needsViewport: hasV,
      needsContainer: hasC,
      build: (vw, cw) {
        var g = gap;
        var rg = runGap;
        var dir = direction;
        var al = alignment;
        var ra = runAlignment;
        var ca = crossAxisAlignment;
        for (final p in fwActivePatches(viewport, container, vw, cw)) {
          g = p.gap ?? g;
          rg = p.runGap ?? rg;
          dir = p.direction ?? dir;
          al = p.alignment ?? al;
          ra = p.runAlignment ?? ra;
          ca = p.crossAxisAlignment ?? ca;
        }
        return _wrapWith(g, rg, dir, al, ra, ca);
      },
    );
  }
}

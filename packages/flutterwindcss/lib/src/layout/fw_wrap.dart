import 'package:flutter/widgets.dart';

import '../tokens/scales.dart';

/// A wrapping flow layout (spec §6.6) — Tailwind's `flex flex-wrap gap-*`.
/// Children flow along the main axis and wrap onto new runs when they overflow.
/// Directional: horizontal flow honors [Directionality] (RTL flows end→start).
///
/// [gap] is the **between-children** spacing within a run; [runGap] is the
/// spacing **between runs** — both in utility units (× 4 logical px). Style the
/// whole flow as a box by chaining `.tw`.
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

  @override
  Widget build(BuildContext context) => Wrap(
    direction: direction,
    spacing: fwSpace(gap),
    runSpacing: fwSpace(runGap),
    alignment: alignment,
    runAlignment: runAlignment,
    crossAxisAlignment: crossAxisAlignment,
    children: children,
  );
}

import 'package:flutter/widgets.dart';

import '../tokens/scales.dart';

/// A horizontal flex row with a typed [gap] (spec §6.6). Like Tailwind's
/// `flex flex-row gap-*`. Directional: children flow start→end, mirroring in RTL
/// (the underlying [Flex] honors [Directionality]).
///
/// [gap] is in **utility units** (1 unit = 4 logical px) and renders via the
/// framework's native [Flex.spacing] (guaranteed by the toolchain floor,
/// AGENTS.md §2). [mainAxisSize] defaults to [MainAxisSize.max] (Flutter's
/// default); pass [MainAxisSize.min] for shrink-to-fit. Style the row as a box by
/// chaining `.tw` (e.g. `FwRow(...).tw.p(4).bg(c)`).
class FwRow extends StatelessWidget {
  /// Creates a horizontal flex. [gap] must be `>= 0`.
  const FwRow({
    required this.children,
    this.gap = 0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
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

  @override
  Widget build(BuildContext context) => Flex(
    direction: Axis.horizontal,
    mainAxisAlignment: mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment,
    mainAxisSize: mainAxisSize,
    spacing: fwSpace(gap),
    children: children,
  );
}

/// A vertical flex column with a typed [gap] (spec §6.6). Like Tailwind's
/// `flex flex-col gap-*`. See [FwRow] for the [gap]/[mainAxisSize] semantics; the
/// cross axis here is horizontal, so [crossAxisAlignment] is RTL-aware.
class FwColumn extends StatelessWidget {
  /// Creates a vertical flex. [gap] must be `>= 0`.
  const FwColumn({
    required this.children,
    this.gap = 0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
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

  @override
  Widget build(BuildContext context) => Flex(
    direction: Axis.vertical,
    mainAxisAlignment: mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment,
    mainAxisSize: mainAxisSize,
    spacing: fwSpace(gap),
    children: children,
  );
}

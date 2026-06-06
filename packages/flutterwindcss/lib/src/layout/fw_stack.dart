import 'package:flutter/widgets.dart';

import '../tokens/scales.dart';

/// A stacking context (spec §6.6) — Tailwind's `relative` container for absolute
/// children. Layers its [children] back-to-front. [FwPositioned] children are
/// placed by directional inset; plain children sit at [alignment].
///
/// **Paint order = z-index then declaration order.** Children carry an optional
/// `z` via [FwPositioned] (the §4.6 `fwZIndices` scale); plain children and
/// `FwPositioned` without a `z` default to `0`. Equal-`z` children keep
/// declaration order (the sort is stable). Style the stack as a box with `.tw`.
class FwStack extends StatelessWidget {
  /// Creates a stack. Children paint in ascending `z`, ties broken by order.
  const FwStack({
    required this.children,
    this.alignment = AlignmentDirectional.topStart,
    this.clipBehavior = Clip.hardEdge,
    super.key,
  });

  /// The stacked children (may include [FwPositioned] for absolute placement).
  final List<Widget> children;

  /// Where non-positioned children sit (directional; default top-start).
  final AlignmentDirectional alignment;

  /// How to clip children that overflow the stack (default [Clip.hardEdge]).
  final Clip clipBehavior;

  static int _zOf(Widget w) => w is FwPositioned ? w.z : 0;

  @override
  Widget build(BuildContext context) {
    // Decorate with the original index so the sort is stable (List.sort is not).
    final indexed = <(int, Widget)>[for (var i = 0; i < children.length; i++) (i, children[i])]
      ..sort((a, b) {
        final byZ = _zOf(a.$2).compareTo(_zOf(b.$2));
        return byZ != 0 ? byZ : a.$1.compareTo(b.$1);
      });

    return Stack(
      alignment: alignment,
      clipBehavior: clipBehavior,
      children: [for (final (_, w) in indexed) _materialize(w)],
    );
  }

  // A Stack inspects its *direct* children's parent data, so an FwPositioned
  // wrapper would not be recognized — convert it to a real PositionedDirectional.
  Widget _materialize(Widget w) {
    if (w is! FwPositioned) return w;
    return PositionedDirectional(
      start: w.start == null ? null : fwSpace(w.start!),
      end: w.end == null ? null : fwSpace(w.end!),
      top: w.top == null ? null : fwSpace(w.top!),
      bottom: w.bottom == null ? null : fwSpace(w.bottom!),
      child: w.child,
    );
  }
}

/// Absolute placement inside an [FwStack] (spec §6.6) — Tailwind's `absolute`
/// with directional `inset-*` and a `z-*` paint order.
///
/// `inset` values ([start]/[end]/[top]/[bottom]) are in **utility units**
/// (× 4 logical px) and directional (RTL-aware via [PositionedDirectional]); a
/// `null` edge is unconstrained. [z] orders painting within the stack (the §4.6
/// `fwZIndices` scale: `0,10,20,30,40,50`); it is honored **only** by [FwStack].
///
/// This is a data-carrying widget: [FwStack] reads its fields and builds the real
/// positioned child. Used anywhere else it throws (a positioned child has no
/// meaning without a stacking parent).
class FwPositioned extends StatelessWidget {
  /// Creates a positioned child. Each non-null inset must be `>= 0`.
  const FwPositioned({
    required this.child,
    this.start,
    this.end,
    this.top,
    this.bottom,
    this.z = 0,
    super.key,
  }) : assert(start == null || start >= 0, 'flutterwindcss: inset must be >= 0 (start=$start).'),
       assert(end == null || end >= 0, 'flutterwindcss: inset must be >= 0 (end=$end).'),
       assert(top == null || top >= 0, 'flutterwindcss: inset must be >= 0 (top=$top).'),
       assert(
         bottom == null || bottom >= 0,
         'flutterwindcss: inset must be >= 0 (bottom=$bottom).',
       );

  /// The positioned content.
  final Widget child;

  /// Inset from the start edge (RTL-aware), utility units; `null` = unconstrained.
  final double? start;

  /// Inset from the end edge (RTL-aware), utility units; `null` = unconstrained.
  final double? end;

  /// Inset from the top edge, utility units; `null` = unconstrained.
  final double? top;

  /// Inset from the bottom edge, utility units; `null` = unconstrained.
  final double? bottom;

  /// Paint order within the [FwStack] (§4.6 scale); higher paints on top.
  final int z;

  @override
  Widget build(BuildContext context) =>
      throw FlutterError(
        'FwPositioned must be a direct child of FwStack — it carries inset/z data '
        'that only FwStack interprets.',
      );
}

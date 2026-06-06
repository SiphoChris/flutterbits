import 'package:flutter/widgets.dart';

import '../tokens/scales.dart';
import 'fw_responsive.dart';

/// A per-breakpoint override of an [FwStack]'s own properties (spec §6.6).
/// Supplied via [FwStack]'s `viewport`/`container` maps to make the stack's
/// [alignment]/[clipBehavior] responsive. (Per-child placement is overridden via
/// [FwPositionedPatch] instead.)
@immutable
class FwStackPatch {
  /// Creates a stack override; `null` fields keep the base.
  const FwStackPatch({this.alignment, this.clipBehavior});

  /// Overriding alignment of non-positioned children, or `null`.
  final AlignmentDirectional? alignment;

  /// Overriding overflow clip, or `null`.
  final Clip? clipBehavior;
}

/// A per-breakpoint override of an [FwPositioned] child's directional inset
/// (spec §6.6) — Tailwind's `inset-* md:inset-*`. `null` fields keep the base
/// inset. `z` is intentionally **not** responsive: paint order is a structural
/// property, not a per-breakpoint value.
@immutable
class FwPositionedPatch {
  /// Creates an inset override. Each non-null inset must be `>= 0`.
  const FwPositionedPatch({this.start, this.end, this.top, this.bottom})
    : assert(start == null || start >= 0, 'flutterwindcss: inset must be >= 0 (start=$start).'),
      assert(end == null || end >= 0, 'flutterwindcss: inset must be >= 0 (end=$end).'),
      assert(top == null || top >= 0, 'flutterwindcss: inset must be >= 0 (top=$top).'),
      assert(bottom == null || bottom >= 0, 'flutterwindcss: inset must be >= 0 (bottom=$bottom).');

  /// Overriding start inset (utility units), or `null`.
  final double? start;

  /// Overriding end inset (utility units), or `null`.
  final double? end;

  /// Overriding top inset (utility units), or `null`.
  final double? top;

  /// Overriding bottom inset (utility units), or `null`.
  final double? bottom;
}

/// A stacking context (spec §6.6) — Tailwind's `relative` container for absolute
/// children. Layers its [children] back-to-front. [FwPositioned] children are
/// placed by directional inset; plain children sit at [alignment].
///
/// **Paint order = z-index then declaration order.** Children carry an optional
/// `z` via [FwPositioned] (the §4.6 `fwZIndices` scale); plain children and
/// `FwPositioned` without a `z` default to `0`. Equal-`z` children keep
/// declaration order (the sort is stable). Style the stack as a box with `.tw`.
///
/// **Responsive:** [viewport]/[container] maps of [FwStackPatch] vary the stack's
/// own [alignment]/[clipBehavior]; each [FwPositioned] child carries its own
/// responsive inset maps. The stack sources widths (inserting `MediaQuery`/one
/// `LayoutBuilder`) only when it or any positioned child declares a responsive
/// override — otherwise it resolves statically.
class FwStack extends StatelessWidget {
  /// Creates a stack. Children paint in ascending `z`, ties broken by order.
  const FwStack({
    required this.children,
    this.alignment = AlignmentDirectional.topStart,
    this.clipBehavior = Clip.hardEdge,
    this.viewport,
    this.container,
    super.key,
  });

  /// The stacked children (may include [FwPositioned] for absolute placement).
  final List<Widget> children;

  /// Where non-positioned children sit (directional; default top-start).
  final AlignmentDirectional alignment;

  /// How to clip children that overflow the stack (default [Clip.hardEdge]).
  final Clip clipBehavior;

  /// Viewport-breakpoint overrides for the stack itself (keyed off screen width).
  final Map<FwBreakpoint, FwStackPatch>? viewport;

  /// Container-breakpoint overrides for the stack itself (keyed off the
  /// enclosing constraint width).
  final Map<FwBreakpoint, FwStackPatch>? container;

  static int _zOf(Widget w) => w is FwPositioned ? w.z : 0;

  /// The children ordered for painting: a **stable** sort by `z`, then by
  /// declaration order (`List.sort` is not stable, so we sort `(index, child)`).
  List<Widget> _ordered() {
    final indexed = <(int, Widget)>[for (var i = 0; i < children.length; i++) (i, children[i])]
      ..sort((a, b) {
        final byZ = _zOf(a.$2).compareTo(_zOf(b.$2));
        return byZ != 0 ? byZ : a.$1.compareTo(b.$1);
      });
    return [for (final (_, w) in indexed) w];
  }

  static Widget _stack(AlignmentDirectional alignment, Clip clip, List<Widget> children) =>
      Stack(alignment: alignment, clipBehavior: clip, children: children);

  // A Stack inspects its *direct* children's parent data, so an FwPositioned
  // wrapper would not be recognized — convert it to a real PositionedDirectional,
  // resolving its (possibly responsive) inset against the active widths.
  static Widget _materialize(Widget w, double? viewportWidth, double? containerWidth) {
    if (w is! FwPositioned) return w;
    final (start, end, top, bottom) = w.resolveInsets(viewportWidth, containerWidth);
    return PositionedDirectional(
      start: start == null ? null : fwSpace(start),
      end: end == null ? null : fwSpace(end),
      top: top == null ? null : fwSpace(top),
      bottom: bottom == null ? null : fwSpace(bottom),
      child: w.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordered = _ordered();
    final hasV =
        fwHasViewport(viewport) ||
        ordered.any((w) => w is FwPositioned && fwHasViewport(w.viewport));
    final hasC =
        fwHasContainer(container) ||
        ordered.any((w) => w is FwPositioned && fwHasContainer(w.container));

    if (!hasV && !hasC) {
      return _stack(alignment, clipBehavior, [
        for (final w in ordered) _materialize(w, null, null),
      ]);
    }

    return fwBuildResponsive(
      context,
      needsViewport: hasV,
      needsContainer: hasC,
      build: (vw, cw) {
        var al = alignment;
        var clip = clipBehavior;
        for (final p in fwActivePatches(viewport, container, vw, cw)) {
          al = p.alignment ?? al;
          clip = p.clipBehavior ?? clip;
        }
        return _stack(al, clip, [for (final w in ordered) _materialize(w, vw, cw)]);
      },
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
/// **Responsive:** [viewport]/[container] maps of [FwPositionedPatch] make the
/// inset vary by screen or container width (`inset-1 md:inset-5`). `z` is not
/// responsive (paint order is structural). The owning [FwStack] resolves these.
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
    this.viewport,
    this.container,
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

  /// Viewport-breakpoint inset overrides (keyed off the screen width).
  final Map<FwBreakpoint, FwPositionedPatch>? viewport;

  /// Container-breakpoint inset overrides (keyed off the enclosing constraint).
  final Map<FwBreakpoint, FwPositionedPatch>? container;

  /// Resolves the effective inset (in utility units) against the active widths,
  /// folding any matching responsive patches onto the base. Called by [FwStack].
  (double?, double?, double?, double?) resolveInsets(
    double? viewportWidth,
    double? containerWidth,
  ) {
    var s = start;
    var e = end;
    var t = top;
    var b = bottom;
    for (final p in fwActivePatches(viewport, container, viewportWidth, containerWidth)) {
      s = p.start ?? s;
      e = p.end ?? e;
      t = p.top ?? t;
      b = p.bottom ?? b;
    }
    return (s, e, t, b);
  }

  @override
  Widget build(BuildContext context) =>
      throw FlutterError(
        'FwPositioned must be a direct child of FwStack — it carries inset/z data '
        'that only FwStack interprets.',
      );
}

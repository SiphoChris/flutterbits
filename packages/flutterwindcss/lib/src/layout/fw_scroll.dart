import 'package:flutter/widgets.dart';

/// Where a snapped item aligns within the viewport (Tailwind `snap-start`/
/// `snap-center`/`snap-end`), used with [FwScroll.snapExtent] (module 16).
enum FwSnapAlign {
  /// The item's leading edge aligns to the viewport's leading edge.
  start,

  /// The item is centred in the viewport.
  center,

  /// The item's trailing edge aligns to the viewport's trailing edge.
  end,
}

/// A Material-free scroll container — the Flutter mapping of Tailwind
/// `overflow-auto` / `overflow-scroll` (module 15).
///
/// `overflow-hidden` is already `.tw.clip()` (a single-box concern); scrolling
/// needs a real scroll widget, so it lives here rather than on `.tw`. Built from
/// the widgets layer only: a [SingleChildScrollView] wrapped in a [RawScrollbar]
/// (NOT Material's `Scrollbar`), so it works on the pure path.
///
/// Scrolls a single [child] along one [axis] (default vertical). For both axes,
/// nest two `FwScroll`s (an inner horizontal inside an outer vertical). Like the
/// other layout widgets it is theme-independent; pass [thumbColor] (e.g.
/// `context.fw.colors.border`) for a themed scrollbar.
class FwScroll extends StatefulWidget {
  /// Creates a scroll container around [child].
  const FwScroll({
    required this.child,
    this.axis = Axis.vertical,
    this.showScrollbar = true,
    this.alwaysShowScrollbar = false,
    this.controller,
    this.padding,
    this.physics,
    this.reverse = false,
    this.thumbColor,
    this.snapExtent,
    this.snapAlign = FwSnapAlign.start,
    super.key,
  }) : assert(
         snapExtent == null || snapExtent > 0,
         'flutterwindcss: snapExtent must be > 0 (got $snapExtent).',
       );

  /// The scrollable content.
  final Widget child;

  /// Scroll axis (Tailwind `overflow-y-*` = vertical, `overflow-x-*` = horizontal).
  final Axis axis;

  /// Whether to show a [RawScrollbar] (Tailwind always shows one; default true).
  final bool showScrollbar;

  /// Whether the scrollbar thumb is always visible (Tailwind `overflow-scroll`)
  /// vs. appearing on scroll/hover (`overflow-auto`, the default).
  final bool alwaysShowScrollbar;

  /// An external controller. If null, `FwScroll` owns one (and disposes it). The
  /// scrollbar shares whichever controller is used.
  final ScrollController? controller;

  /// Inner padding around the scrollable content.
  final EdgeInsetsGeometry? padding;

  /// Scroll physics (defaults to the platform default).
  final ScrollPhysics? physics;

  /// Reverses the scroll direction (content starts at the far edge).
  final bool reverse;

  /// Scrollbar thumb colour (defaults to [RawScrollbar]'s neutral grey). Pass a
  /// token such as `context.fw.colors.border` for a themed scrollbar.
  final Color? thumbColor;

  /// Item size in logical px to snap to (Tailwind scroll-snap / `snap-*`). When
  /// set, the scroll settles on multiples of this extent — the carousel pattern
  /// (uniform-size items). `null` = free scrolling. Must be `> 0`.
  final double? snapExtent;

  /// How a snapped item aligns in the viewport (Tailwind `snap-start/center/end`).
  /// Only applies when [snapExtent] is set.
  final FwSnapAlign snapAlign;

  @override
  State<FwScroll> createState() => _FwScrollState();
}

class _FwScrollState extends State<FwScroll> {
  // Owned only when the caller did not supply one (then we must dispose it).
  ScrollController? _owned;

  ScrollController get _controller => widget.controller ?? (_owned ??= ScrollController());

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Scroll-snap composes the snap physics over the caller's physics (or the
    // platform default), so momentum still feels native but settles on items.
    final ScrollPhysics? physics =
        widget.snapExtent == null
            ? widget.physics
            : _FwSnapPhysics(
              itemExtent: widget.snapExtent!,
              align: widget.snapAlign,
              parent: widget.physics ?? const AlwaysScrollableScrollPhysics(),
            );

    Widget content = SingleChildScrollView(
      scrollDirection: widget.axis,
      controller: _controller,
      padding: widget.padding,
      physics: physics,
      reverse: widget.reverse,
      child: widget.child,
    );

    if (widget.showScrollbar) {
      content = RawScrollbar(
        controller: _controller,
        thumbVisibility: widget.alwaysShowScrollbar,
        thumbColor: widget.thumbColor,
        child: content,
      );
    }
    return content;
  }
}

/// Scroll physics that snaps the resting offset to multiples of [itemExtent]
/// (Tailwind scroll-snap), honouring [align]. Direction of the fling biases which
/// boundary it lands on. Composed over a parent physics so momentum is native.
class _FwSnapPhysics extends ScrollPhysics {
  const _FwSnapPhysics({required this.itemExtent, required this.align, super.parent});

  final double itemExtent;
  final FwSnapAlign align;

  @override
  _FwSnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _FwSnapPhysics(itemExtent: itemExtent, align: align, parent: buildParent(ancestor));

  /// The alignment offset added to an item's leading edge so it lands at the
  /// requested viewport position (0 for start; a fraction of the slack for
  /// center/end).
  double _alignOffset(ScrollMetrics position) {
    // Clamp at 0: when an item is larger than the viewport the slack is negative,
    // and a negative center/end offset would push the snap target off-screen
    // (a silently broken carousel). Degrading to snap-to-start is the sane result.
    final slack = (position.viewportDimension - itemExtent).clamp(0.0, double.infinity);
    return switch (align) {
      FwSnapAlign.start => 0,
      FwSnapAlign.center => slack / 2,
      FwSnapAlign.end => slack,
    };
  }

  double _snapTarget(ScrollMetrics position, double velocity, Tolerance tolerance) {
    final alignOffset = _alignOffset(position);
    final page = (position.pixels + alignOffset) / itemExtent;
    final double target;
    if (velocity < -tolerance.velocity) {
      target = page.floorToDouble();
    } else if (velocity > tolerance.velocity) {
      target = page.ceilToDouble();
    } else {
      target = page.roundToDouble();
    }
    return (target * itemExtent - alignOffset).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    // Out of range → let the parent handle the edge bounce.
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    final target = _snapTarget(position, velocity, tolerance);
    if ((target - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(spring, position.pixels, target, velocity, tolerance: tolerance);
  }

  @override
  bool get allowImplicitScrolling => false;
}

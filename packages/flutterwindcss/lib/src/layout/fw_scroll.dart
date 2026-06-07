import 'package:flutter/widgets.dart';

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
    super.key,
  });

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
    Widget content = SingleChildScrollView(
      scrollDirection: widget.axis,
      controller: _controller,
      padding: widget.padding,
      physics: widget.physics,
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

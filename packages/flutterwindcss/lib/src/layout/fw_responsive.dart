import 'package:flutter/widgets.dart';

import '../tokens/scales.dart';

/// Shared responsive-resolution plumbing for the layout widgets (spec §6.6).
///
/// Layout *properties* (a flex `gap`, a grid's column count, a positioned
/// `inset`) are not box-styling fields, so they cannot ride the `FwStyle` layer
/// engine that `.tw` uses. They instead reuse that engine's **breakpoint
/// semantics**: the same [FwBreakpoint] min-widths, the same viewport-vs-container
/// distinction, and the same "insert only the ancestors you need" discipline as
/// `FwStyled` (spec §6.2). A widget with no responsive maps inserts nothing and
/// resolves statically.
///
/// Responsive overrides are supplied as `Map<FwBreakpoint, Patch>` — one map for
/// `viewport` breakpoints (keyed off the screen size) and one for `container`
/// breakpoints (keyed off the enclosing constraint). Each `Patch` is a per-widget
/// bag of nullable fields; resolution folds the matching patches onto the
/// widget's static base values, last-wins per field.

/// Builds a layout subtree with the viewport/container widths it needs, inserting
/// only the required ancestors: a `MediaQuery` read for viewport responsiveness
/// and a single `LayoutBuilder` for container queries (spec §6.2, R5/R6).
typedef FwResponsiveChildBuilder = Widget Function(double? viewportWidth, double? containerWidth);

/// Resolves the widths [build] needs. [needsViewport] reads `MediaQuery`;
/// [needsContainer] wraps in one `LayoutBuilder` (which measures the box's
/// incoming constraint width, like `FwStyled`, spec §6.2 Finding #1).
Widget fwBuildResponsive(
  BuildContext context, {
  required bool needsViewport,
  required bool needsContainer,
  required FwResponsiveChildBuilder build,
}) {
  if (needsContainer) {
    return LayoutBuilder(
      builder:
          (ctx, constraints) => build(
            needsViewport ? MediaQuery.maybeOf(ctx)?.size.width : null,
            constraints.maxWidth.isFinite ? constraints.maxWidth : null,
          ),
    );
  }
  return build(needsViewport ? MediaQuery.maybeOf(context)?.size.width : null, null);
}

/// Yields the patches whose breakpoint is satisfied by the resolved widths.
///
/// Each map is walked in **ascending breakpoint width** (independent of map
/// insertion order) so the largest matching breakpoint is applied last — i.e.
/// last-wins, mobile-first, exactly like Tailwind's `md:`/`lg:` cascade.
/// [viewport] patches are yielded before [container] patches, so a container
/// override wins a viewport one on the same property (the more specific context).
Iterable<P> fwActivePatches<P>(
  Map<FwBreakpoint, P>? viewport,
  Map<FwBreakpoint, P>? container,
  double? viewportWidth,
  double? containerWidth,
) sync* {
  if (viewport != null && viewportWidth != null) {
    final bps = viewport.keys.toList()..sort((a, b) => a.minWidth.compareTo(b.minWidth));
    for (final bp in bps) {
      if (viewportWidth >= bp.minWidth) yield viewport[bp] as P;
    }
  }
  if (container != null && containerWidth != null) {
    final bps = container.keys.toList()..sort((a, b) => a.minWidth.compareTo(b.minWidth));
    for (final bp in bps) {
      if (containerWidth >= bp.minWidth) yield container[bp] as P;
    }
  }
}

/// Whether a viewport map carries any breakpoint (so a `MediaQuery` read is due).
bool fwHasViewport<P>(Map<FwBreakpoint, P>? viewport) => viewport != null && viewport.isNotEmpty;

/// Whether a container map carries any breakpoint (so a `LayoutBuilder` is due).
bool fwHasContainer<P>(Map<FwBreakpoint, P>? container) =>
    container != null && container.isNotEmpty;

import 'package:flutter/widgets.dart';

import '../tokens/scales.dart';
import 'fw_responsive.dart';

/// A single column track for [FwGrid] (spec §6.6). Sealed so the cell builder can
/// `switch` exhaustively — a new track kind is a compile error, not a silent
/// fallthrough. The v1 grammar is two kinds: flexible [FwFr] and fixed [FwPx].
sealed class FwGridTrack {
  /// Const base constructor.
  const FwGridTrack();
}

/// A flexible (`fr`) track that takes a share of the leftover width proportional
/// to [flex] (Tailwind/CSS `1fr`, `2fr`, …). Renders as an [Expanded].
final class FwFr extends FwGridTrack {
  /// Creates an `fr` track with the given [flex] weight (must be `> 0`).
  const FwFr([this.flex = 1])
    : assert(flex > 0, 'flutterwindcss: fr flex must be > 0 (got $flex).');

  /// The flex weight (CSS `Nfr`).
  final int flex;
}

/// A fixed-width track of [size] **logical pixels** (CSS `200px`). Renders as a
/// [SizedBox] of that width.
final class FwPx extends FwGridTrack {
  /// Creates a fixed-px track of [size] logical pixels (must be `>= 0`).
  const FwPx(this.size)
    : assert(size >= 0, 'flutterwindcss: px track size must be >= 0 (got $size).');

  /// The track width in logical pixels.
  final double size;
}

/// A per-breakpoint override of an [FwGrid]'s layout (spec §6.6). A bag of
/// nullable fields: `null` keeps the base. Supplied via [FwGrid]'s
/// `viewport`/`container` maps — notably to change the **column count**
/// responsively (`grid-cols-1 md:grid-cols-3`).
@immutable
class FwGridPatch {
  /// Creates a grid override. Non-null gaps must be `>= 0`. A non-null [columns]
  /// must be non-empty — but that is guarded where the columns resolve (in
  /// [FwGrid.build]), since a `const` constructor cannot inspect a list's length.
  const FwGridPatch({this.columns, this.columnGap, this.rowGap, this.crossAxisAlignment})
    : assert(
        columnGap == null || columnGap >= 0,
        'flutterwindcss: columnGap must be >= 0 (got $columnGap).',
      ),
      assert(rowGap == null || rowGap >= 0, 'flutterwindcss: rowGap must be >= 0 (got $rowGap).');

  /// Overriding column tracks (non-empty), or `null` to keep the base count.
  final List<FwGridTrack>? columns;

  /// Overriding between-column spacing (utility units), or `null`.
  final double? columnGap;

  /// Overriding between-row spacing (utility units), or `null`.
  final double? rowGap;

  /// Overriding cross-axis alignment of cells, or `null`.
  final CrossAxisAlignment? crossAxisAlignment;
}

/// A simple CSS-grid helper (spec §6.6, AGENTS.md §11) — a single set of column
/// [columns] tracks (mixing [FwFr]/[FwPx]) with [children] laid **row-major** and
/// wrapped into equal-structure rows. Tailwind's `grid grid-cols-* gap-*`.
///
/// `columnGap`/`rowGap` are in **utility units** (× 4 logical px). Directional:
/// each row is an RTL-aware horizontal flex. A partial final row is padded with
/// empty cells so every column track lines up across rows.
///
/// **Width:** `FwFr` tracks divide the grid's incoming width, so place an `FwGrid`
/// where its width is bounded (a normal column/parent supplies this; under a
/// horizontally-unbounded parent, give it a width via `.tw.w(...)` or a
/// `SizedBox`). A grid of only `FwPx` tracks needs no bounded width.
///
/// **Responsive:** pass [viewport]/[container] maps of [FwGridPatch] keyed by
/// [FwBreakpoint] to vary the **column count**, gaps, or alignment by screen or
/// container width (`grid-cols-1 md:grid-cols-3`). A grid with neither map
/// resolves statically (no `MediaQuery`/`LayoutBuilder`).
///
/// **Out of scope (Non-Goals, AGENTS.md §11):** cell/row spanning,
/// auto-placement, and `subgrid` — they require a custom `RenderObject`. "Ships
/// complete" means complete for this fr/px column grammar.
class FwGrid extends StatelessWidget {
  /// Creates a grid. [columns] must be non-empty; gaps must be `>= 0`.
  ///
  /// Not `const`: the non-empty-columns guard inspects [columns], which is not
  /// const-evaluable (and an empty track list would loop forever in [build]).
  FwGrid({
    required this.columns,
    required this.children,
    this.columnGap = 0,
    this.rowGap = 0,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.viewport,
    this.container,
    super.key,
  }) : assert(columns.isNotEmpty, 'flutterwindcss: FwGrid needs at least one column track.'),
       assert(columnGap >= 0, 'flutterwindcss: columnGap must be >= 0 (got $columnGap).'),
       assert(rowGap >= 0, 'flutterwindcss: rowGap must be >= 0 (got $rowGap).');

  /// The column tracks, applied start→end to each row.
  final List<FwGridTrack> columns;

  /// The grid items, placed row-major across [columns].
  final List<Widget> children;

  /// Between-column spacing, in utility units (× 4 logical px).
  final double columnGap;

  /// Between-row spacing, in utility units (× 4 logical px).
  final double rowGap;

  /// Cross-axis (vertical) alignment of cells within a row.
  final CrossAxisAlignment crossAxisAlignment;

  /// Viewport-breakpoint overrides (keyed off the screen width).
  final Map<FwBreakpoint, FwGridPatch>? viewport;

  /// Container-breakpoint overrides (keyed off the enclosing constraint width).
  final Map<FwBreakpoint, FwGridPatch>? container;

  static Widget _cell(FwGridTrack track, Widget child) => switch (track) {
    FwFr(:final flex) => Expanded(flex: flex, child: child),
    FwPx(:final size) => SizedBox(width: size, child: child),
  };

  static Widget _grid(
    List<FwGridTrack> columns,
    List<Widget> children,
    double columnGap,
    double rowGap,
    CrossAxisAlignment crossAxisAlignment,
  ) {
    // Guarded here (not in the const patch ctor) since a resolved column set must
    // be non-empty — an empty list would loop forever below.
    assert(columns.isNotEmpty, 'flutterwindcss: FwGrid resolved to zero column tracks.');
    final cols = columns.length;
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += cols) {
      rows.add(
        Row(
          crossAxisAlignment: crossAxisAlignment,
          spacing: fwSpace(columnGap),
          children: [
            for (var c = 0; c < cols; c++)
              _cell(
                columns[c],
                start + c < children.length ? children[start + c] : const SizedBox.shrink(),
              ),
          ],
        ),
      );
    }
    // Stretch so each row spans the full width and fr tracks resolve against it.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: fwSpace(rowGap),
      children: rows,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasV = fwHasViewport(viewport);
    final hasC = fwHasContainer(container);
    if (!hasV && !hasC) {
      return _grid(columns, children, columnGap, rowGap, crossAxisAlignment);
    }
    return fwBuildResponsive(
      context,
      needsViewport: hasV,
      needsContainer: hasC,
      build: (vw, cw) {
        var cols = columns;
        var cGap = columnGap;
        var rGap = rowGap;
        var caa = crossAxisAlignment;
        for (final p in fwActivePatches(viewport, container, vw, cw)) {
          cols = p.columns ?? cols;
          cGap = p.columnGap ?? cGap;
          rGap = p.rowGap ?? rGap;
          caa = p.crossAxisAlignment ?? caa;
        }
        return _grid(cols, children, cGap, rGap, caa);
      },
    );
  }
}

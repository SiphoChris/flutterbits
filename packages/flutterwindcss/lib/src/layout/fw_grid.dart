import 'package:flutter/widgets.dart';

import '../tokens/scales.dart';

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

/// A simple CSS-grid helper (spec §6.6, AGENTS.md §11) — a single set of column
/// [columns] tracks (mixing [FwFr]/[FwPx]) with [children] laid **row-major** and
/// wrapped into equal-structure rows. Tailwind's `grid grid-cols-* gap-*`.
///
/// `columnGap`/`rowGap` are in **utility units** (× 4 logical px). Directional:
/// each row is an RTL-aware horizontal flex. A partial final row is padded with
/// empty cells so every column track lines up across rows.
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

  Widget _cell(FwGridTrack track, Widget child) => switch (track) {
    FwFr(:final flex) => Expanded(flex: flex, child: child),
    FwPx(:final size) => SizedBox(width: size, child: child),
  };

  @override
  Widget build(BuildContext context) {
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
}

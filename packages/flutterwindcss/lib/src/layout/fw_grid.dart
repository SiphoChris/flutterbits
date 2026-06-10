import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../tokens/scales.dart';
import 'fw_responsive.dart';

/// Upper bound on an explicit [FwGridItem] grid line (1-based). This is a
/// defensive backstop, not a semantic limit on grid size: an explicit
/// `rowStart`/`columnStart` larger than this is almost certainly a typo, and the
/// row-flow placer would otherwise grow its implicit-row occupancy grid up to
/// that line — a single absurd value could allocate unboundedly. Real grids use
/// a handful of lines; anything past this fails fast in debug instead.
const int _fwMaxGridLine = 100000;

/// A single column/row track for [FwGrid] (grid engine spec §2.1). Sealed so the
/// sizing code can `switch` exhaustively — a new track kind is a compile error,
/// not a silent fallthrough.
///
/// v1 grammar: flexible [FwFr], fixed [FwPx], content-sized [FwAuto], and clamped
/// [FwMinMax]. (`subgrid` is a documented, deliberately de-scoped Non-Goal —
/// AGENTS.md §11b / grid engine spec §2.4.)
sealed class FwGridTrack {
  /// Const base constructor.
  const FwGridTrack();
}

/// A flexible (`fr`) track that takes a share of the leftover space proportional
/// to [flex] (CSS `1fr`, `2fr`, …). Under an unbounded main axis it falls back to
/// its content (max-intrinsic) size, since `fr` cannot divide infinite space.
final class FwFr extends FwGridTrack {
  /// Creates an `fr` track with the given [flex] weight (must be `> 0`).
  const FwFr([this.flex = 1])
    : assert(flex > 0, 'flutterwindcss: fr flex must be > 0 (got $flex).');

  /// The flex weight (CSS `Nfr`).
  final int flex;
}

/// A fixed-extent track of [size] **logical pixels** (CSS `200px`).
final class FwPx extends FwGridTrack {
  /// Creates a fixed-px track of [size] logical pixels (must be `>= 0`).
  const FwPx(this.size)
    : assert(size >= 0, 'flutterwindcss: px track size must be >= 0 (got $size).');

  /// The track extent in logical pixels.
  final double size;
}

/// A content-sized (`auto`) track: sizes to the max-content of the items that
/// occupy it (CSS `auto` / `max-content`).
final class FwAuto extends FwGridTrack {
  /// Creates a content-sized track.
  const FwAuto();
}

/// A clamped track (CSS `minmax(min, max)`): grows from [minPx] up to [max]'s
/// resolved size. [max] may be [FwPx], [FwAuto], or [FwFr] (a `minmax(100, 1fr)`
/// track participates in `fr` distribution with a [minPx] floor); a nested
/// `minmax` is not allowed (CSS forbids it).
final class FwMinMax extends FwGridTrack {
  /// Creates a clamped track. [minPx] must be `>= 0`; [max] must not be a
  /// [FwMinMax].
  const FwMinMax(this.minPx, this.max)
    : assert(minPx >= 0, 'flutterwindcss: minmax min must be >= 0 (got $minPx).'),
      assert(max is! FwMinMax, 'flutterwindcss: minmax max cannot itself be minmax.');

  /// The lower bound in logical pixels.
  final double minPx;

  /// The upper-bound track function (`FwPx`/`FwAuto`/`FwFr`).
  final FwGridTrack max;
}

/// Sugar: a list with [track] repeated [count] times (CSS `repeat(n, track)`).
abstract final class FwTrack {
  /// `repeat(count, track)` — e.g. `FwTrack.repeat(3, const FwFr())`.
  static List<FwGridTrack> repeat(int count, FwGridTrack track) {
    assert(count > 0, 'flutterwindcss: repeat count must be > 0 (got $count).');
    return <FwGridTrack>[for (var i = 0; i < count; i++) track];
  }
}

/// Alignment of a grid item within its cell (grid engine spec §2.3). `start`/`end`
/// are RTL-aware on the inline (horizontal) axis.
enum FwGridAlign {
  /// Fill the cell (the default).
  stretch,

  /// Pack to the start edge (inline: left in LTR, right in RTL; block: top).
  start,

  /// Pack to the end edge (inline: right in LTR, left in RTL; block: bottom).
  end,

  /// Center within the cell.
  center,
}

/// Distribution of **spare space between tracks** when the tracks don't fill the
/// grid's available extent on an axis (CSS `justify-content`/`align-content`).
/// Only takes effect when there is leftover space and no `fr` track on that axis
/// (an `fr` track already absorbs all spare). `start` (the default) packs the
/// tracks at the start edge.
enum FwGridDistribute {
  /// Pack tracks at the start (default; leftover space trails).
  start,

  /// Pack tracks at the end (leftover space leads).
  end,

  /// Center the track block; leftover space splits to both ends.
  center,

  /// Spread tracks so the first/last touch the edges; equal space between.
  spaceBetween,

  /// Equal space around each track (half-size gaps at the ends).
  spaceAround,

  /// Equal space between tracks and at both ends.
  spaceEvenly,
}

/// Per-breakpoint override of an [FwGrid]'s layout (grid engine spec; carries the
/// M8 responsive surface forward). `null` fields keep the base — notably to change
/// the **column count** responsively (`grid-cols-1 md:grid-cols-3`).
@immutable
class FwGridPatch {
  /// Creates a grid override. Non-null gaps must be `>= 0`; a non-null [columns]
  /// must be non-empty (guarded where columns resolve, in the widget build).
  const FwGridPatch({
    this.columns,
    this.rows,
    this.autoRows,
    this.columnGap,
    this.rowGap,
    this.alignItems,
    this.justifyItems,
    this.justifyContent,
    this.alignContent,
  }) : assert(
         columnGap == null || columnGap >= 0,
         'flutterwindcss: columnGap must be >= 0 (got $columnGap).',
       ),
       assert(rowGap == null || rowGap >= 0, 'flutterwindcss: rowGap must be >= 0 (got $rowGap).');

  /// Overriding column tracks (non-empty), or `null`.
  final List<FwGridTrack>? columns;

  /// Overriding explicit row tracks, or `null`.
  final List<FwGridTrack>? rows;

  /// Overriding implicit-row track, or `null`.
  final FwGridTrack? autoRows;

  /// Overriding between-column spacing (utility units), or `null`.
  final double? columnGap;

  /// Overriding between-row spacing (utility units), or `null`.
  final double? rowGap;

  /// Overriding block-axis item alignment, or `null`.
  final FwGridAlign? alignItems;

  /// Overriding inline-axis item alignment, or `null`.
  final FwGridAlign? justifyItems;

  /// Overriding inline-axis track distribution, or `null`.
  final FwGridDistribute? justifyContent;

  /// Overriding block-axis track distribution, or `null`.
  final FwGridDistribute? alignContent;
}

/// A real CSS-Grid container (grid engine spec) backed by [RenderFwGrid].
///
/// Lays [children] into a grid of [columns] tracks (`fr`/`px`/`auto`/`minmax`),
/// row-major, growing implicit rows (sized by [autoRows]) as needed. Items may
/// **span** and be **explicitly placed** via [FwGridItem]; bare children are
/// span-1 and auto-placed. `columnGap`/`rowGap` are utility units (× 4 px);
/// `FwPx` track sizes are logical px. All directional (RTL mirrors column order
/// and `start`/`end` alignment).
///
/// **Responsive:** [viewport]/[container] maps of [FwGridPatch] vary the column
/// count, tracks, gaps, or alignment by screen/container width; a grid with
/// neither resolves statically (no `MediaQuery`/`LayoutBuilder`).
///
/// **Known limitations:** `subgrid` is **not** supported — a deliberate v1
/// de-scope (negligible real-world usage), *not* a Flutter limitation (grid
/// engine spec §2.4 / AGENTS.md §11b). Also, this is a **row-flow** grid with a
/// fixed column count: a partial-explicit item (`rowStart` given, column auto)
/// whose requested row is already full advances to the next row rather than
/// growing an implicit column (CSS would add one; this grammar has no implicit
/// columns). Give such items room or place them fully (`columnStart` + `rowStart`).
///
/// Everything else in CSS Grid Level 1 is supported: spanning, explicit
/// placement, sparse + `dense` auto-placement, `fr`/`px`/`auto`/`minmax` tracks
/// (both axes), item/self alignment ([alignItems]/[justifyItems]/`*Self`), and
/// track content-distribution ([justifyContent]/[alignContent]).
class FwGrid extends StatelessWidget {
  /// Creates a grid. [columns] must be non-empty; gaps must be `>= 0`.
  FwGrid({
    required this.columns,
    required this.children,
    this.rows,
    this.autoRows = const FwAuto(),
    this.columnGap = 0,
    this.rowGap = 0,
    this.alignItems = FwGridAlign.stretch,
    this.justifyItems = FwGridAlign.stretch,
    this.justifyContent = FwGridDistribute.start,
    this.alignContent = FwGridDistribute.start,
    this.dense = false,
    this.viewport,
    this.container,
    super.key,
  }) : assert(columns.isNotEmpty, 'flutterwindcss: FwGrid needs at least one column track.'),
       assert(columnGap >= 0, 'flutterwindcss: columnGap must be >= 0 (got $columnGap).'),
       assert(rowGap >= 0, 'flutterwindcss: rowGap must be >= 0 (got $rowGap).');

  /// The column tracks, applied start→end.
  final List<FwGridTrack> columns;

  /// Explicit row tracks (optional); implicit rows beyond these use [autoRows].
  final List<FwGridTrack>? rows;

  /// Track sizing for implicit rows (default content-sized [FwAuto]).
  final FwGridTrack autoRows;

  /// The grid items.
  final List<Widget> children;

  /// Between-column spacing, in utility units (× 4 logical px).
  final double columnGap;

  /// Between-row spacing, in utility units (× 4 logical px).
  final double rowGap;

  /// Block-axis (vertical) alignment of items within their cells.
  final FwGridAlign alignItems;

  /// Inline-axis (horizontal) alignment of items within their cells.
  final FwGridAlign justifyItems;

  /// Inline-axis distribution of spare space between columns when they don't
  /// fill the grid's width (CSS `justify-content`; default `start`).
  final FwGridDistribute justifyContent;

  /// Block-axis distribution of spare space between rows when they don't fill
  /// the grid's height (CSS `align-content`; default `start`).
  final FwGridDistribute alignContent;

  /// Auto-placement packing (CSS `grid-auto-flow: dense`): when `true`,
  /// later auto-placed items backfill earlier holes instead of only advancing a
  /// cursor. Default `false` (sparse, preserves source order).
  final bool dense;

  /// Viewport-breakpoint overrides (keyed off the screen width).
  final Map<FwBreakpoint, FwGridPatch>? viewport;

  /// Container-breakpoint overrides (keyed off the enclosing constraint width).
  final Map<FwBreakpoint, FwGridPatch>? container;

  @override
  Widget build(BuildContext context) {
    final hasV = fwHasViewport(viewport);
    final hasC = fwHasContainer(container);
    if (!hasV && !hasC) {
      return _raw(
        columns,
        rows,
        autoRows,
        columnGap,
        rowGap,
        alignItems,
        justifyItems,
        justifyContent,
        alignContent,
      );
    }
    return fwBuildResponsive(
      context,
      needsViewport: hasV,
      needsContainer: hasC,
      build: (vw, cw) {
        var cols = columns;
        var rws = rows;
        var aRows = autoRows;
        var cGap = columnGap;
        var rGap = rowGap;
        var ai = alignItems;
        var ji = justifyItems;
        var jc = justifyContent;
        var ac = alignContent;
        for (final p in fwActivePatches(viewport, container, vw, cw)) {
          cols = p.columns ?? cols;
          rws = p.rows ?? rws;
          aRows = p.autoRows ?? aRows;
          cGap = p.columnGap ?? cGap;
          rGap = p.rowGap ?? rGap;
          ai = p.alignItems ?? ai;
          ji = p.justifyItems ?? ji;
          jc = p.justifyContent ?? jc;
          ac = p.alignContent ?? ac;
        }
        return _raw(cols, rws, aRows, cGap, rGap, ai, ji, jc, ac);
      },
    );
  }

  Widget _raw(
    List<FwGridTrack> cols,
    List<FwGridTrack>? rws,
    FwGridTrack aRows,
    double cGap,
    double rGap,
    FwGridAlign ai,
    FwGridAlign ji,
    FwGridDistribute jc,
    FwGridDistribute ac,
  ) {
    assert(cols.isNotEmpty, 'flutterwindcss: FwGrid resolved to zero column tracks.');
    // Release-safe backstop: an empty resolved column list would make the render
    // object spin (no column ever fits a span-≥1 item, so placement never
    // terminates). The assert above catches it in debug; in release, fall back to
    // the base `columns` (the main constructor guarantees that is non-empty)
    // rather than hang. Belt-and-suspenders with the FwGridPatch constructor assert.
    if (cols.isEmpty) cols = columns;
    return _RawFwGrid(
      columns: cols,
      rows: rws,
      autoRows: aRows,
      columnGap: fwSpace(cGap),
      rowGap: fwSpace(rGap),
      alignItems: ai,
      justifyItems: ji,
      justifyContent: jc,
      alignContent: ac,
      dense: dense,
      children: children,
    );
  }
}

/// Per-item placement + self-alignment inside an [FwGrid] (grid engine spec §2).
/// A `ParentDataWidget`, exactly like `Positioned` for `Stack`. Line numbers are
/// **1-based** (CSS `grid-column-start`); `null` means auto-place on that axis.
class FwGridItem extends ParentDataWidget<FwGridParentData> {
  /// Creates a placed/spanning grid item. Spans must be `>= 1`; explicit line
  /// numbers must be `>= 1`.
  const FwGridItem({
    required super.child,
    this.columnStart,
    this.columnSpan = 1,
    this.rowStart,
    this.rowSpan = 1,
    this.justifySelf,
    this.alignSelf,
    super.key,
  }) : assert(columnSpan >= 1, 'flutterwindcss: columnSpan must be >= 1 (got $columnSpan).'),
       assert(rowSpan >= 1, 'flutterwindcss: rowSpan must be >= 1 (got $rowSpan).'),
       // Cap spans like the start lines: rowSpan grows the implicit-row occupancy
       // grid, so an absurd value would allocate unboundedly (columnSpan is also
       // clamped to the column count at layout, but cap it here for symmetry).
       assert(
         columnSpan <= _fwMaxGridLine,
         'flutterwindcss: columnSpan $columnSpan exceeds the sane cap '
         '($_fwMaxGridLine) — almost certainly a typo.',
       ),
       assert(
         rowSpan <= _fwMaxGridLine,
         'flutterwindcss: rowSpan $rowSpan exceeds the sane cap '
         '($_fwMaxGridLine) — almost certainly a typo.',
       ),
       assert(
         columnStart == null || columnStart >= 1,
         'flutterwindcss: columnStart is a 1-based line (got $columnStart).',
       ),
       assert(
         rowStart == null || rowStart >= 1,
         'flutterwindcss: rowStart is a 1-based line (got $rowStart).',
       ),
       assert(
         columnStart == null || columnStart <= _fwMaxGridLine,
         'flutterwindcss: columnStart $columnStart exceeds the sane line cap '
         '($_fwMaxGridLine) — almost certainly a typo.',
       ),
       assert(
         rowStart == null || rowStart <= _fwMaxGridLine,
         'flutterwindcss: rowStart $rowStart exceeds the sane line cap '
         '($_fwMaxGridLine) — almost certainly a typo.',
       );

  /// 1-based column line to start at, or `null` to auto-place. Asserted within a
  /// sane cap ([_fwMaxGridLine]) so a typo can't grow the grid unboundedly.
  final int? columnStart;

  /// Number of columns to span (default 1).
  final int columnSpan;

  /// 1-based row line to start at, or `null` to auto-place. Asserted within a
  /// sane cap ([_fwMaxGridLine]) so a typo can't grow the grid unboundedly.
  final int? rowStart;

  /// Number of rows to span (default 1).
  final int rowSpan;

  /// Inline-axis self-alignment (overrides the grid's `justifyItems`).
  final FwGridAlign? justifySelf;

  /// Block-axis self-alignment (overrides the grid's `alignItems`).
  final FwGridAlign? alignSelf;

  @override
  void applyParentData(RenderObject renderObject) {
    final pd = renderObject.parentData! as FwGridParentData;
    var changed = false;
    if (pd.columnStart != columnStart) {
      pd.columnStart = columnStart;
      changed = true;
    }
    if (pd.columnSpan != columnSpan) {
      pd.columnSpan = columnSpan;
      changed = true;
    }
    if (pd.rowStart != rowStart) {
      pd.rowStart = rowStart;
      changed = true;
    }
    if (pd.rowSpan != rowSpan) {
      pd.rowSpan = rowSpan;
      changed = true;
    }
    if (pd.justifySelf != justifySelf) {
      pd.justifySelf = justifySelf;
      changed = true;
    }
    if (pd.alignSelf != alignSelf) {
      pd.alignSelf = alignSelf;
      changed = true;
    }
    if (changed) {
      final target = renderObject.parent;
      if (target is RenderObject) {
        target.markNeedsLayout();
      }
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => FwGrid;
}

/// Parent data for a child of [RenderFwGrid]: placement intent + resolved cell.
class FwGridParentData extends ContainerBoxParentData<RenderBox> {
  /// 1-based explicit column line, or `null` (auto).
  int? columnStart;

  /// Column span (>= 1).
  int columnSpan = 1;

  /// 1-based explicit row line, or `null` (auto).
  int? rowStart;

  /// Row span (>= 1).
  int rowSpan = 1;

  /// Inline self-alignment override.
  FwGridAlign? justifySelf;

  /// Block self-alignment override.
  FwGridAlign? alignSelf;
}

/// The `MultiChildRenderObjectWidget` half of [FwGrid] (created with already
/// responsive-resolved values; gaps already in logical px).
class _RawFwGrid extends MultiChildRenderObjectWidget {
  const _RawFwGrid({
    required this.columns,
    required this.rows,
    required this.autoRows,
    required this.columnGap,
    required this.rowGap,
    required this.alignItems,
    required this.justifyItems,
    required this.justifyContent,
    required this.alignContent,
    required this.dense,
    required super.children,
  });

  final List<FwGridTrack> columns;
  final List<FwGridTrack>? rows;
  final FwGridTrack autoRows;
  final double columnGap;
  final double rowGap;
  final FwGridAlign alignItems;
  final FwGridAlign justifyItems;
  final FwGridDistribute justifyContent;
  final FwGridDistribute alignContent;
  final bool dense;

  @override
  RenderFwGrid createRenderObject(BuildContext context) => RenderFwGrid(
    columns: columns,
    rows: rows,
    autoRows: autoRows,
    columnGap: columnGap,
    rowGap: rowGap,
    alignItems: alignItems,
    justifyItems: justifyItems,
    justifyContent: justifyContent,
    alignContent: alignContent,
    dense: dense,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderFwGrid renderObject) {
    renderObject
      ..columns = columns
      ..rows = rows
      ..autoRows = autoRows
      ..columnGap = columnGap
      ..rowGap = rowGap
      ..alignItems = alignItems
      ..justifyItems = justifyItems
      ..justifyContent = justifyContent
      ..alignContent = alignContent
      ..dense = dense
      ..textDirection = Directionality.of(context);
  }
}

/// The grid layout `RenderObject` (grid engine spec §2.2). Sizes column then row
/// tracks, places items row-major (honoring [FwGridItem] spans + explicit lines),
/// and positions each child in its cell with item/self alignment, directional.
class RenderFwGrid extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, FwGridParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, FwGridParentData> {
  /// Creates the grid render object.
  RenderFwGrid({
    required List<FwGridTrack> columns,
    required List<FwGridTrack>? rows,
    required FwGridTrack autoRows,
    required double columnGap,
    required double rowGap,
    required FwGridAlign alignItems,
    required FwGridAlign justifyItems,
    required FwGridDistribute justifyContent,
    required FwGridDistribute alignContent,
    required bool dense,
    required TextDirection textDirection,
  }) : _columns = columns,
       _rows = rows,
       _autoRows = autoRows,
       _columnGap = columnGap,
       _rowGap = rowGap,
       _alignItems = alignItems,
       _justifyItems = justifyItems,
       _justifyContent = justifyContent,
       _alignContent = alignContent,
       _dense = dense,
       _textDirection = textDirection;

  List<FwGridTrack> _columns;

  /// The column tracks.
  List<FwGridTrack> get columns => _columns;
  set columns(List<FwGridTrack> v) {
    if (_columns != v) {
      _columns = v;
      markNeedsLayout();
    }
  }

  List<FwGridTrack>? _rows;

  /// The explicit row tracks, or `null`.
  List<FwGridTrack>? get rows => _rows;
  set rows(List<FwGridTrack>? v) {
    if (_rows != v) {
      _rows = v;
      markNeedsLayout();
    }
  }

  FwGridTrack _autoRows;

  /// The implicit-row track.
  FwGridTrack get autoRows => _autoRows;
  set autoRows(FwGridTrack v) {
    if (_autoRows != v) {
      _autoRows = v;
      markNeedsLayout();
    }
  }

  double _columnGap;

  /// Between-column gap in logical px.
  double get columnGap => _columnGap;
  set columnGap(double v) {
    if (_columnGap != v) {
      _columnGap = v;
      markNeedsLayout();
    }
  }

  double _rowGap;

  /// Between-row gap in logical px.
  double get rowGap => _rowGap;
  set rowGap(double v) {
    if (_rowGap != v) {
      _rowGap = v;
      markNeedsLayout();
    }
  }

  FwGridAlign _alignItems;

  /// Block-axis item alignment.
  FwGridAlign get alignItems => _alignItems;
  set alignItems(FwGridAlign v) {
    if (_alignItems != v) {
      _alignItems = v;
      markNeedsLayout();
    }
  }

  FwGridAlign _justifyItems;

  /// Inline-axis item alignment.
  FwGridAlign get justifyItems => _justifyItems;
  set justifyItems(FwGridAlign v) {
    if (_justifyItems != v) {
      _justifyItems = v;
      markNeedsLayout();
    }
  }

  FwGridDistribute _justifyContent;

  /// Inline-axis track distribution.
  FwGridDistribute get justifyContent => _justifyContent;
  set justifyContent(FwGridDistribute v) {
    if (_justifyContent != v) {
      _justifyContent = v;
      markNeedsLayout();
    }
  }

  FwGridDistribute _alignContent;

  /// Block-axis track distribution.
  FwGridDistribute get alignContent => _alignContent;
  set alignContent(FwGridDistribute v) {
    if (_alignContent != v) {
      _alignContent = v;
      markNeedsLayout();
    }
  }

  bool _dense;

  /// Whether auto-placement backfills holes (CSS `dense`).
  bool get dense => _dense;
  set dense(bool v) {
    if (_dense != v) {
      _dense = v;
      markNeedsLayout();
    }
  }

  TextDirection _textDirection;

  /// The ambient text direction (mirrors columns + `start`/`end` under RTL).
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection v) {
    if (_textDirection != v) {
      _textDirection = v;
      markNeedsLayout();
    }
  }

  @override
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! FwGridParentData) {
      child.parentData = FwGridParentData();
    }
  }

  /// Resolves where each child sits, returning per-child `(col, row)` cells (in
  /// `children` order) and the total row count — **without** mutating parent data,
  /// so it is safe to call from intrinsic/dry-layout queries as well as layout.
  ///
  /// **Two-pass, CSS-faithful (corrected — audit):** pass 1 reserves every
  /// *fully* explicit item (both `columnStart` and `rowStart` given); pass 2
  /// auto-places the rest (partial-explicit + auto) into the remaining holes, so
  /// an auto item can never steal a cell an explicit item asked for. Sparse
  /// advances a cursor; `dense` first-fits from the origin. A partial-explicit
  /// item locks the given axis and searches the other; if its requested row is
  /// full it advances (this row-flow grammar has no implicit columns to grow —
  /// documented on [FwGrid]).
  ({List<({int col, int row})> cells, int rowCount}) _place(
    List<RenderBox> children,
    int colCount,
  ) {
    final occupancy = <List<bool>>[];
    List<bool> rowAt(int r) {
      while (occupancy.length <= r) {
        occupancy.add(List<bool>.filled(colCount, false));
      }
      return occupancy[r];
    }

    bool fits(int r, int c, int colSpan, int rowSpan) {
      if (c < 0 || c + colSpan > colCount) return false;
      for (var rr = r; rr < r + rowSpan; rr++) {
        final row = rowAt(rr);
        for (var cc = c; cc < c + colSpan; cc++) {
          if (row[cc]) return false;
        }
      }
      return true;
    }

    void occupy(int r, int c, int colSpan, int rowSpan) {
      for (var rr = r; rr < r + rowSpan; rr++) {
        final row = rowAt(rr);
        for (var cc = c; cc < c + colSpan; cc++) {
          row[cc] = true;
        }
      }
    }

    final cells = List<({int col, int row})?>.filled(children.length, null);

    // Pass 1 — reserve fully-explicit items first (CSS places these before auto).
    for (var i = 0; i < children.length; i++) {
      final pd = children[i].parentData! as FwGridParentData;
      if (pd.columnStart != null && pd.rowStart != null) {
        final colSpan = pd.columnSpan.clamp(1, colCount);
        assert(
          pd.columnStart! <= colCount - colSpan + 1,
          'flutterwindcss: FwGridItem.columnStart (${pd.columnStart}) places a '
          'span-$colSpan item past the last of $colCount columns; it will be '
          'clamped to fit. Reduce columnStart/columnSpan or add columns.',
        );
        final c = (pd.columnStart! - 1).clamp(0, colCount - colSpan);
        final r = pd.rowStart! - 1;
        occupy(r, c, colSpan, pd.rowSpan);
        cells[i] = (col: c, row: r);
      }
    }

    // Pass 2 — auto-place the rest into the holes left by the reserved items.
    var cursorRow = 0;
    var cursorCol = 0;
    for (var i = 0; i < children.length; i++) {
      if (cells[i] != null) continue;
      final pd = children[i].parentData! as FwGridParentData;
      final colSpan = pd.columnSpan.clamp(1, colCount);
      final rowSpan = pd.rowSpan;

      int r;
      int c;
      if (pd.columnStart != null) {
        // Locked column; first free row.
        assert(
          pd.columnStart! <= colCount - colSpan + 1,
          'flutterwindcss: FwGridItem.columnStart (${pd.columnStart}) places a '
          'span-$colSpan item past the last of $colCount columns; it will be '
          'clamped to fit. Reduce columnStart/columnSpan or add columns.',
        );
        c = (pd.columnStart! - 1).clamp(0, colCount - colSpan);
        r = 0;
        while (!fits(r, c, colSpan, rowSpan)) {
          r++;
        }
      } else if (pd.rowStart != null) {
        // Locked row; first free column (advances rows if the row fills).
        r = pd.rowStart! - 1;
        c = 0;
        while (!fits(r, c, colSpan, rowSpan)) {
          c++;
          if (c + colSpan > colCount) {
            c = 0;
            r++;
          }
        }
      } else if (_dense) {
        r = 0;
        c = 0;
        while (!fits(r, c, colSpan, rowSpan)) {
          c++;
          if (c + colSpan > colCount) {
            c = 0;
            r++;
          }
        }
      } else {
        r = cursorRow;
        c = cursorCol;
        while (!fits(r, c, colSpan, rowSpan)) {
          c++;
          if (c + colSpan > colCount) {
            c = 0;
            r++;
          }
        }
        cursorRow = r;
        cursorCol = c + colSpan;
        if (cursorCol >= colCount) {
          cursorCol = 0;
          cursorRow = r + 1;
        }
      }
      occupy(r, c, colSpan, rowSpan);
      cells[i] = (col: c, row: r);
    }

    return (cells: <({int col, int row})>[for (final e in cells) e!], rowCount: occupancy.length);
  }

  /// Resolves track sizes along one axis. [intrinsic] yields the content size of
  /// a track index (max over items occupying it, distributed across spans).
  List<double> _resolveAxis({
    required List<FwGridTrack> tracks,
    required double available,
    required double gap,
    required double Function(int index) intrinsic,
  }) {
    final n = tracks.length;
    final sizes = List<double>.filled(n, 0);
    final isFlex = List<bool>.filled(n, false);
    final flexFloor = List<double>.filled(n, 0);
    var totalFlex = 0;

    for (var i = 0; i < n; i++) {
      final t = tracks[i];
      switch (t) {
        case FwPx(:final size):
          sizes[i] = size;
        case FwAuto():
          sizes[i] = intrinsic(i);
        case FwFr(:final flex):
          isFlex[i] = true;
          totalFlex += flex;
        case FwMinMax(:final minPx, :final max):
          switch (max) {
            case FwPx(:final size):
              sizes[i] = intrinsic(i).clamp(minPx, size);
            case FwAuto():
              // clamp(minPx, ∞) == max(minPx, content), evaluating intrinsic once.
              sizes[i] = intrinsic(i).clamp(minPx, double.infinity);
            case FwFr():
              isFlex[i] = true;
              flexFloor[i] = minPx;
              totalFlex += max.flex;
              sizes[i] = minPx;
            case FwMinMax():
              sizes[i] = minPx; // disallowed by assert; defensive
          }
      }
    }

    if (totalFlex > 0) {
      if (available.isFinite) {
        final used =
            sizes.fold<double>(0, (a, b) => a + b) -
            // floors are already in `sizes` for minmax-fr; subtract them so they
            // are not double-counted against free space (they are re-added by the
            // flex share which is floored at flexFloor).
            flexFloor.fold<double>(0, (a, b) => a + b);
        var free = available - used - gap * (n - 1);
        if (free < 0) free = 0;
        _distributeFlex(tracks, sizes, isFlex, flexFloor, free);
      } else {
        // Unbounded: fr falls back to content size.
        for (var i = 0; i < n; i++) {
          if (isFlex[i]) {
            final c = intrinsic(i);
            sizes[i] = c < flexFloor[i] ? flexFloor[i] : c;
          }
        }
      }
    }
    return sizes;
  }

  /// Distributes [free] space across the flex tracks proportionally, respecting
  /// per-track [floors] (a `minmax(min, fr)` track never shrinks below `min`).
  /// Iterative so a track pinned to its floor releases its share to the others.
  void _distributeFlex(
    List<FwGridTrack> tracks,
    List<double> sizes,
    List<bool> isFlex,
    List<double> floors,
    double free,
  ) {
    final pinned = List<bool>.filled(tracks.length, false);
    int flexOf(int i) => switch (tracks[i]) {
      FwFr(:final flex) => flex,
      FwMinMax(:final max) => max is FwFr ? max.flex : 0,
      _ => 0,
    };

    var remaining = free;
    while (true) {
      var totalFlex = 0;
      for (var i = 0; i < tracks.length; i++) {
        if (isFlex[i] && !pinned[i]) totalFlex += flexOf(i);
      }
      if (totalFlex == 0) break;
      // One unit per pass, from the pass-start remaining (corrected — audit:
      // computing each track's share against an already-reduced `remaining` used
      // a stale total and spuriously pinned later tracks, losing space).
      final unit = remaining / totalFlex;
      final violators = <int>[];
      for (var i = 0; i < tracks.length; i++) {
        if (isFlex[i] && !pinned[i] && unit * flexOf(i) < floors[i]) violators.add(i);
      }
      if (violators.isEmpty) {
        // No floor violations at this unit: assign the final shares and finish.
        for (var i = 0; i < tracks.length; i++) {
          if (isFlex[i] && !pinned[i]) sizes[i] = unit * flexOf(i);
        }
        break;
      }
      // Pin every violator to its floor (using the same pass-start unit), drop
      // their floors from `remaining`, then re-resolve the rest next pass.
      for (final i in violators) {
        sizes[i] = floors[i];
        remaining -= floors[i];
        pinned[i] = true;
      }
      if (remaining < 0) remaining = 0;
    }
  }

  double _sum(List<double> xs) => xs.fold<double>(0, (a, b) => a + b);

  /// The row tracks for a grid with [rowCount] rows: explicit [rows] first, then
  /// [autoRows] for any implicit rows beyond the template.
  List<FwGridTrack> _rowTracks(int rowCount) {
    final explicit = _rows ?? const <FwGridTrack>[];
    return <FwGridTrack>[
      for (var i = 0; i < rowCount; i++) (i < explicit.length ? explicit[i] : _autoRows),
    ];
  }

  /// Whether an axis has any flex track (`fr` or `minmax(_, fr)`), which absorbs
  /// all spare space → content-distribution is a no-op on that axis.
  bool _axisHasFlex(List<FwGridTrack> tracks) =>
      tracks.any((t) => t is FwFr || (t is FwMinMax && t.max is FwFr));

  /// Track start origins along an axis after distributing spare space per
  /// [distribute] (CSS `justify`/`align-content`). Returns the origins and the
  /// axis extent (the grid's size on that axis). Distribution only applies when
  /// the axis is bounded, has spare space, and has no flex track.
  ({List<double> origins, double extent}) _distribute(
    List<double> sizes,
    double gap,
    double available,
    FwGridDistribute distribute,
    bool hasFlex,
  ) {
    final n = sizes.length;
    // Defense-in-depth: a zero-track axis would divide by `n` (spaceAround) or
    // make `content` negative. The column/row guards make this unreachable, but
    // this is a pure function reused by dry-layout — keep it total.
    if (n == 0) return (origins: const <double>[], extent: 0.0);
    final content = _sum(sizes) + gap * (n - 1);
    var leading = 0.0;
    var between = 0.0;
    var extent = content;
    if (!hasFlex &&
        distribute != FwGridDistribute.start &&
        available.isFinite &&
        available > content) {
      final spare = available - content;
      extent = available;
      switch (distribute) {
        case FwGridDistribute.start:
          break;
        case FwGridDistribute.end:
          leading = spare;
        case FwGridDistribute.center:
          leading = spare / 2;
        case FwGridDistribute.spaceBetween:
          if (n > 1) between = spare / (n - 1);
        case FwGridDistribute.spaceAround:
          between = spare / n;
          leading = between / 2;
        case FwGridDistribute.spaceEvenly:
          between = spare / (n + 1);
          leading = between;
      }
    }
    final origins = List<double>.filled(n, 0);
    if (n > 0) origins[0] = leading;
    for (var i = 1; i < n; i++) {
      origins[i] = origins[i - 1] + sizes[i - 1] + gap + between;
    }
    return (origins: origins, extent: extent);
  }

  /// Resolved track geometry for [constraints] — placement, track sizes, origins
  /// (after content-distribution), and the grid size. **Pure** (no `child.layout`,
  /// no parent-data mutation): it uses only child intrinsics, so it is reused by
  /// [performLayout], the intrinsic-size queries, and [computeDryLayout].
  ({
    List<({int col, int row})> cells,
    List<double> colSizes,
    List<double> colOrigins,
    List<double> rowSizes,
    List<double> rowOrigins,
    Size size,
  })
  _computeTracks(BoxConstraints constraints, List<RenderBox> children) {
    final colCount = _columns.length;
    final placement = _place(children, colCount);
    final cells = placement.cells;

    final colSizes = _resolveAxis(
      tracks: _columns,
      available: constraints.maxWidth,
      gap: _columnGap,
      intrinsic: (i) => _colIntrinsic(children, cells, i),
    );
    final colDist = _distribute(
      colSizes,
      _columnGap,
      constraints.maxWidth,
      _justifyContent,
      _axisHasFlex(_columns),
    );
    final colOrigins = colDist.origins;

    // Cell width for child i: last spanned col's right minus first col's origin
    // (folds in gaps + any distribution spacing).
    double cellWidthOf(int i) {
      final pd = children[i].parentData! as FwGridParentData;
      final span = pd.columnSpan.clamp(1, colCount);
      final col = cells[i].col;
      return colOrigins[col + span - 1] + colSizes[col + span - 1] - colOrigins[col];
    }

    final rowTracks = _rowTracks(placement.rowCount);
    final rowSizes = _resolveAxis(
      tracks: rowTracks,
      available: constraints.maxHeight,
      gap: _rowGap,
      intrinsic: (r) => _rowIntrinsic(children, cells, rowTracks, r, cellWidthOf),
    );
    final rowDist = _distribute(
      rowSizes,
      _rowGap,
      constraints.maxHeight,
      _alignContent,
      _axisHasFlex(rowTracks),
    );

    return (
      cells: cells,
      colSizes: colSizes,
      colOrigins: colOrigins,
      rowSizes: rowSizes,
      rowOrigins: rowDist.origins,
      size: constraints.constrain(Size(colDist.extent, rowDist.extent)),
    );
  }

  @override
  void performLayout() {
    final children = getChildrenAsList();
    if (children.isEmpty) {
      size = constraints.constrain(Size.zero);
      return;
    }
    final colCount = _columns.length;
    final g = _computeTracks(constraints, children);
    size = g.size;

    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final pd = child.parentData! as FwGridParentData;
      final col = g.cells[i].col;
      final row = g.cells[i].row;
      final colSpan = pd.columnSpan.clamp(1, colCount);
      final rowSpan = pd.rowSpan.clamp(1, g.rowSizes.length - row);
      final lastCol = col + colSpan - 1;
      final lastRow = row + rowSpan - 1;

      final cellLeftLtr = g.colOrigins[col];
      final cellW = g.colOrigins[lastCol] + g.colSizes[lastCol] - cellLeftLtr;
      final cellTop = g.rowOrigins[row];
      final cellH = g.rowOrigins[lastRow] + g.rowSizes[lastRow] - cellTop;

      final justify = pd.justifySelf ?? _justifyItems;
      final alignV = pd.alignSelf ?? _alignItems;
      final tightW = justify == FwGridAlign.stretch;
      final tightH = alignV == FwGridAlign.stretch;

      child.layout(
        BoxConstraints(
          minWidth: tightW ? cellW : 0,
          maxWidth: cellW,
          minHeight: tightH ? cellH : 0,
          maxHeight: cellH,
        ),
        parentUsesSize: true,
      );
      final cs = child.size;
      final dx = tightW ? 0.0 : _inlineDelta(justify, cellW - cs.width);
      final dy = tightH ? 0.0 : _blockDelta(alignV, cellH - cs.height);

      // Mirror the cell to the right edge under RTL, then place within it.
      final cellLeft =
          _textDirection == TextDirection.rtl ? size.width - cellLeftLtr - cellW : cellLeftLtr;
      pd.offset = Offset(cellLeft + dx, cellTop + dy);
    }
  }

  /// Max-content contribution to **column** track [index]: a span-1 item gives its
  /// full max-intrinsic width; a spanning item gives its width **minus the fixed
  /// (`px`) tracks in its span**, split across the span's non-fixed tracks (CSS
  /// §11.5 / grid spec §2.2 step 3 — corrected — audit; the previous even `/span`
  /// split ignored fixed tracks).
  double _colIntrinsic(List<RenderBox> children, List<({int col, int row})> cells, int index) {
    var best = 0.0;
    for (var i = 0; i < children.length; i++) {
      final pd = children[i].parentData! as FwGridParentData;
      final span = pd.columnSpan.clamp(1, _columns.length);
      final start = cells[i].col;
      if (index < start || index >= start + span) continue;
      final intrinsic = children[i].getMaxIntrinsicWidth(double.infinity);
      if (span == 1) {
        if (intrinsic > best) best = intrinsic;
        continue;
      }
      final excess = _spanExcess(intrinsic, _columns, start, span);
      if (excess != null && excess > best) best = excess;
    }
    return best;
  }

  /// Max-content contribution to **row** track [r], measuring each occupying
  /// child's height at its resolved cell width. Span-1 → full height; spanning →
  /// height minus fixed (`px`) rows in the span, split across the non-fixed rows
  /// (so a row-spanning item DOES size the auto rows it covers — corrected —
  /// audit; the previous code ignored every `rowSpan > 1` item).
  double _rowIntrinsic(
    List<RenderBox> children,
    List<({int col, int row})> cells,
    List<FwGridTrack> rowTracks,
    int r,
    double Function(int i) cellWidthOf,
  ) {
    var best = 0.0;
    for (var i = 0; i < children.length; i++) {
      final pd = children[i].parentData! as FwGridParentData;
      final span = pd.rowSpan;
      final start = cells[i].row;
      if (r < start || r >= start + span) continue;
      final h = children[i].getMaxIntrinsicHeight(cellWidthOf(i));
      if (span == 1) {
        if (h > best) best = h;
        continue;
      }
      final excess = _spanExcess(h, rowTracks, start, span);
      if (excess != null && excess > best) best = excess;
    }
    return best;
  }

  /// The per-non-fixed-track share of a spanning item's [intrinsic] size: subtract
  /// the fixed (`px` / `minmax(_, px)`) tracks in `[start, start+span)` and divide
  /// the remainder across the non-fixed tracks. Returns `null` if the span has no
  /// non-fixed track (a spanning item over only fixed tracks sizes none of them).
  double? _spanExcess(double intrinsic, List<FwGridTrack> tracks, int start, int span) {
    var fixed = 0.0;
    var nonFixed = 0;
    for (var t = start; t < start + span && t < tracks.length; t++) {
      final track = tracks[t];
      final px =
          track is FwPx
              ? track.size
              : (track is FwMinMax && track.max is FwPx ? (track.max as FwPx).size : null);
      if (px != null) {
        fixed += px;
      } else {
        nonFixed++;
      }
    }
    if (nonFixed == 0) return null;
    return (intrinsic - fixed) / nonFixed;
  }

  double _inlineDelta(FwGridAlign a, double free) {
    final start = switch (a) {
      FwGridAlign.start => _textDirection == TextDirection.rtl ? _End.right : _End.left,
      FwGridAlign.end => _textDirection == TextDirection.rtl ? _End.left : _End.right,
      FwGridAlign.center => _End.center,
      FwGridAlign.stretch => _End.left,
    };
    return switch (start) {
      _End.left => 0,
      _End.center => free / 2,
      _End.right => free,
    };
  }

  double _blockDelta(FwGridAlign a, double free) => switch (a) {
    FwGridAlign.start || FwGridAlign.stretch => 0,
    FwGridAlign.center => free / 2,
    FwGridAlign.end => free,
  };

  // Intrinsics + dry layout, all derived from the pure `_computeTracks` so they
  // are consistent with `performLayout` and side-effect-free (corrected — audit:
  // the old `_intrinsicWidth` mutated child parent data, and there were no height
  // intrinsics or dry layout — so the grid mislaid under `IntrinsicHeight` and
  // threw on `getDryLayout`).
  @override
  double computeMinIntrinsicWidth(double height) => _natural().width;

  @override
  double computeMaxIntrinsicWidth(double height) => _natural().width;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _natural(maxWidth: width.isFinite ? width : double.infinity).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _natural(maxWidth: width.isFinite ? width : double.infinity).height;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final children = getChildrenAsList();
    if (children.isEmpty) return constraints.constrain(Size.zero);
    return _computeTracks(constraints, children).size;
  }

  /// The grid's natural (content) size at an optional bounded [maxWidth].
  Size _natural({double maxWidth = double.infinity}) {
    final children = getChildrenAsList();
    if (children.isEmpty) return Size.zero;
    return _computeTracks(BoxConstraints(maxWidth: maxWidth), children).size;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}

/// A resolved physical end for inline alignment (internal to [RenderFwGrid]).
enum _End { left, center, right }

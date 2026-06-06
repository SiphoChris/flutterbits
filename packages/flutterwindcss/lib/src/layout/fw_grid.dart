import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../tokens/scales.dart';
import 'fw_responsive.dart';

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
/// **Known limitation:** `subgrid` is **not** supported — a deliberate v1
/// de-scope (negligible real-world usage), *not* a Flutter limitation (grid
/// engine spec §2.4 / AGENTS.md §11b).
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
       assert(
         columnStart == null || columnStart >= 1,
         'flutterwindcss: columnStart is a 1-based line (got $columnStart).',
       ),
       assert(
         rowStart == null || rowStart >= 1,
         'flutterwindcss: rowStart is a 1-based line (got $rowStart).',
       );

  /// 1-based column line to start at, or `null` to auto-place.
  final int? columnStart;

  /// Number of columns to span (default 1).
  final int columnSpan;

  /// 1-based row line to start at, or `null` to auto-place.
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

  /// Resolved 0-based column index (set during layout).
  int resolvedColumn = 0;

  /// Resolved 0-based row index (set during layout).
  int resolvedRow = 0;
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

  /// Row-major auto-placement (sparse) honoring explicit lines + spans. Returns
  /// the total row count. Each child's parent data gets resolvedColumn/Row.
  int _place(List<RenderBox> children, int colCount) {
    // Occupancy as a growable list of row bitsets (List<bool> per row).
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

    var cursorRow = 0;
    var cursorCol = 0;

    for (final child in children) {
      final pd = child.parentData! as FwGridParentData;
      final colSpan = pd.columnSpan.clamp(1, colCount);
      final rowSpan = pd.rowSpan;

      int r;
      int c;
      if (pd.columnStart != null && pd.rowStart != null) {
        // Fully explicit.
        c = (pd.columnStart! - 1).clamp(0, colCount - colSpan);
        r = pd.rowStart! - 1;
      } else if (pd.columnStart != null) {
        // Fixed column, find the first free row at that column.
        c = (pd.columnStart! - 1).clamp(0, colCount - colSpan);
        r = 0;
        while (!fits(r, c, colSpan, rowSpan)) {
          r++;
        }
      } else if (pd.rowStart != null) {
        // Fixed row, advance columns within it.
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
        // Dense: first-fit scan from the origin (backfills earlier holes).
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
        // Fully auto (sparse): advance the cursor row-major.
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
      pd.resolvedColumn = c;
      pd.resolvedRow = r;
    }
    return occupancy.length;
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
              sizes[i] = intrinsic(i) < minPx ? minPx : intrinsic(i);
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
      var repinned = false;
      for (var i = 0; i < tracks.length; i++) {
        if (!isFlex[i] || pinned[i]) continue;
        final share = remaining * flexOf(i) / totalFlex;
        if (share < floors[i]) {
          sizes[i] = floors[i];
          remaining -= floors[i];
          pinned[i] = true;
          repinned = true;
        }
      }
      if (!repinned) {
        // No more floor violations: assign final shares to the unpinned tracks.
        for (var i = 0; i < tracks.length; i++) {
          if (isFlex[i] && !pinned[i]) {
            sizes[i] = remaining * flexOf(i) / totalFlex;
          }
        }
        break;
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

  @override
  void performLayout() {
    final children = getChildrenAsList();
    final colCount = _columns.length;

    if (children.isEmpty) {
      size = constraints.constrain(Size.zero);
      return;
    }

    final rowCount = _place(children, colCount);

    // Column sizing — content size of a column = max max-intrinsic width of the
    // single-column items in it; spanning items distribute across their columns.
    final colSizes = _resolveAxis(
      tracks: _columns,
      available: constraints.maxWidth,
      gap: _columnGap,
      intrinsic: (i) => _axisIntrinsic(children, i, horizontal: true, colSizesSoFar: null),
    );

    // Column origins + grid width (after inline content-distribution).
    final colDist = _distribute(
      colSizes,
      _columnGap,
      constraints.maxWidth,
      _justifyContent,
      _axisHasFlex(_columns),
    );
    final colOrigins = colDist.origins;

    // Per-child cell width (origin of last spanned col + its size − origin of
    // first spanned col — naturally folds in gaps and any distribution spacing).
    double cellWidthOf(FwGridParentData pd) {
      final span = pd.columnSpan.clamp(1, colCount);
      final last = pd.resolvedColumn + span - 1;
      return colOrigins[last] + colSizes[last] - colOrigins[pd.resolvedColumn];
    }

    // Row sizing — content height of a row = max child height at its cell width.
    final rowTracks = _rowTracks(rowCount);
    final rowSizes = _resolveAxis(
      tracks: rowTracks,
      available: constraints.maxHeight,
      gap: _rowGap,
      intrinsic: (r) {
        var h = 0.0;
        for (final child in children) {
          final pd = child.parentData! as FwGridParentData;
          if (pd.rowSpan == 1 && pd.resolvedRow == r) {
            final ch = child.getMaxIntrinsicHeight(cellWidthOf(pd));
            if (ch > h) h = ch;
          }
        }
        return h;
      },
    );

    // Row origins + grid height (after block content-distribution).
    final rowDist = _distribute(
      rowSizes,
      _rowGap,
      constraints.maxHeight,
      _alignContent,
      _axisHasFlex(rowTracks),
    );
    final rowOrigins = rowDist.origins;

    size = constraints.constrain(Size(colDist.extent, rowDist.extent));

    // Position + final layout.
    for (final child in children) {
      final pd = child.parentData! as FwGridParentData;
      final colSpan = pd.columnSpan.clamp(1, colCount);
      final rowSpan = pd.rowSpan.clamp(1, rowCount - pd.resolvedRow);
      final lastCol = pd.resolvedColumn + colSpan - 1;
      final lastRow = pd.resolvedRow + rowSpan - 1;

      final cellLeftLtr = colOrigins[pd.resolvedColumn];
      final cellW = colOrigins[lastCol] + colSizes[lastCol] - cellLeftLtr;
      final cellTop = rowOrigins[pd.resolvedRow];
      final cellH = rowOrigins[lastRow] + rowSizes[lastRow] - cellTop;

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

  /// Max-content size of [index] along the axis: the largest single-track item's
  /// max-intrinsic main size; spanning items distribute evenly across the tracks
  /// they span (grid engine spec §2.2 step 3).
  double _axisIntrinsic(
    List<RenderBox> children,
    int index, {
    required bool horizontal,
    required List<double>? colSizesSoFar,
  }) {
    var best = 0.0;
    for (final child in children) {
      final pd = child.parentData! as FwGridParentData;
      final span = horizontal ? pd.columnSpan.clamp(1, _columns.length) : pd.rowSpan;
      final start = horizontal ? pd.resolvedColumn : pd.resolvedRow;
      if (index < start || index >= start + span) continue;
      final intrinsic =
          horizontal
              ? child.getMaxIntrinsicWidth(double.infinity)
              : child.getMaxIntrinsicHeight(double.infinity);
      final contribution = intrinsic / span; // even distribution across the span
      if (contribution > best) best = contribution;
    }
    return best;
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

  @override
  double computeMinIntrinsicWidth(double height) => _intrinsicWidth();

  @override
  double computeMaxIntrinsicWidth(double height) => _intrinsicWidth();

  double _intrinsicWidth() {
    // Sum of column intrinsics + gaps (fixed tracks use their size).
    final children = getChildrenAsList();
    if (children.isEmpty) return 0;
    _place(children, _columns.length);
    var total = 0.0;
    for (var i = 0; i < _columns.length; i++) {
      total += switch (_columns[i]) {
        FwPx(:final size) => size,
        FwMinMax(:final minPx) => minPx,
        _ => _axisIntrinsic(children, i, horizontal: true, colSizesSoFar: null),
      };
    }
    return total + _columnGap * (_columns.length - 1);
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

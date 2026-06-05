import 'package:flutter/widgets.dart' show WidgetState, immutable;

import '../tokens/scales.dart';

/// A nesting condition under which a layer's `FwStyle` applies (spec §6.1).
///
/// Sealed so the resolver can reason exhaustively without a `default:`. Matching
/// takes **both** the viewport width and the container width separately: a
/// viewport condition (`md:`) must key off the screen size, a container
/// condition (`containerMd:`) off the enclosing box's constraint — conflating
/// them would let one satisfy the other (spec §6.2, §6.3).
@immutable
sealed class FwCondition {
  /// Const base constructor.
  const FwCondition();

  /// Whether this condition holds given the active interaction [states], the
  /// [viewportWidth] (screen size, `null` if unknown), and the [containerWidth]
  /// (enclosing constraint, `null` if no `LayoutBuilder` is in play).
  bool matches(Set<WidgetState> states, double? viewportWidth, double? containerWidth);

  /// True for a state condition. Used to decide whether a
  /// `FocusableActionDetector` is needed over the flattened layer set.
  bool get isState => this is FwStateCondition;

  /// True for a viewport condition.
  bool get isViewport => this is FwViewportCondition;

  /// True for a container condition. Used to decide whether a `LayoutBuilder`
  /// is needed over the flattened layer set.
  bool get isContainer => this is FwContainerCondition;
}

/// Matches when [state] is in the active interaction set (widths irrelevant).
@immutable
final class FwStateCondition extends FwCondition {
  /// Creates a state condition for [state].
  const FwStateCondition(this.state);

  /// The interaction state to match.
  final WidgetState state;

  @override
  bool matches(Set<WidgetState> states, double? viewportWidth, double? containerWidth) =>
      states.contains(state);

  @override
  bool operator ==(Object other) => other is FwStateCondition && other.state == state;

  @override
  int get hashCode => state.hashCode;
}

/// Matches when the **viewport** width is at least [breakpoint]'s min-width.
@immutable
final class FwViewportCondition extends FwCondition {
  /// Creates a viewport condition for [breakpoint].
  const FwViewportCondition(this.breakpoint);

  /// The breakpoint whose min-width gates this layer.
  final FwBreakpoint breakpoint;

  @override
  bool matches(Set<WidgetState> states, double? viewportWidth, double? containerWidth) =>
      viewportWidth != null && viewportWidth >= breakpoint.minWidth;

  @override
  bool operator ==(Object other) => other is FwViewportCondition && other.breakpoint == breakpoint;

  @override
  int get hashCode => breakpoint.hashCode;
}

/// Matches when the **container** constraint width is at least [breakpoint]'s
/// min-width (keyed off the `FwStyled` `LayoutBuilder`, spec §6.2).
@immutable
final class FwContainerCondition extends FwCondition {
  /// Creates a container condition for [breakpoint].
  const FwContainerCondition(this.breakpoint);

  /// The breakpoint whose min-width gates this layer.
  final FwBreakpoint breakpoint;

  @override
  bool matches(Set<WidgetState> states, double? viewportWidth, double? containerWidth) =>
      containerWidth != null && containerWidth >= breakpoint.minWidth;

  @override
  bool operator ==(Object other) => other is FwContainerCondition && other.breakpoint == breakpoint;

  @override
  int get hashCode => breakpoint.hashCode;
}

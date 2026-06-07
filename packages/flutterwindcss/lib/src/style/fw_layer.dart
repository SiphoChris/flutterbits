import 'package:flutter/widgets.dart' show WidgetState, immutable;

import '../tokens/scales.dart';

/// A nesting condition under which a layer's `FwStyle` applies (spec §6.1).
///
/// Sealed so the resolver can reason exhaustively without a `default:`. Matching
/// takes **both** the viewport width and the container width separately: a
/// viewport condition (`md:`) must key off the screen size, a container
/// condition (`containerMd:`) off the enclosing box's constraint — conflating
/// them would let one satisfy the other (spec §6.2, §6.3).
///
/// Matching only decides *whether* a layer applies; **precedence** among the
/// matching ones is the cascade in `FwStyle.resolve` — breakpoints ordered by
/// min-width (container over viewport at the same width), then state conditions
/// above all breakpoints, with declaration order as the tie-break. It is *not*
/// raw declaration order.
@immutable
sealed class FwCondition {
  /// Const base constructor.
  const FwCondition();

  /// Whether this condition holds given the active interaction [states], the
  /// [viewportWidth] (screen size, `null` if unknown), the [containerWidth]
  /// (enclosing constraint, `null` if no `LayoutBuilder` is in play), and the
  /// ancestor/sibling state channels [groupStates]/[peerStates] (`null` when no
  /// `FwGroup` scope is in play). The two channel maps are name-keyed (`null` =
  /// the default/unnamed channel) and only ever read by [FwGroupCondition] —
  /// every other condition ignores them (module 14).
  bool matches(
    Set<WidgetState> states,
    double? viewportWidth,
    double? containerWidth, {
    Map<String?, Set<WidgetState>>? groupStates,
    Map<String?, Set<WidgetState>>? peerStates,
  });

  /// True for a state condition. Part of deciding whether live interaction
  /// sourcing (`MouseRegion` + non-traversable `Focus` + `Listener`) is needed
  /// over the flattened layer set (`FwStyled._needsLiveStateSourcing`). The
  /// engine sources visual-only states with those primitives — never a
  /// `FocusableActionDetector` (it can't be made non-traversable; §6.2).
  ///
  /// A [FwGroupCondition] is **not** a state condition: its state is sourced by
  /// the ancestor `FwGroup`/`FwPeer`, never by the reacting `FwStyled` itself, so
  /// it must not trigger that box's own live sourcing (module 14).
  bool get isState => this is FwStateCondition;

  /// True for a viewport condition.
  bool get isViewport => this is FwViewportCondition;

  /// True for a container condition. Used to decide whether a `LayoutBuilder`
  /// is needed over the flattened layer set.
  bool get isContainer => this is FwContainerCondition;

  /// True for a group/peer condition. Used to decide whether the reacting
  /// `FwStyled` must read the nearest `FwGroup` scope from context (module 14).
  bool get isRelation => this is FwGroupCondition;
}

/// Which relationship a [FwGroupCondition] reads (Tailwind `group-*` vs `peer-*`).
///
/// - [group] — a **descendant** reacts to an **ancestor** `FwGroup`'s state.
/// - [peer] — a widget reacts to a **sibling** `FwPeer`'s state, shared through
///   the enclosing `FwGroup` scope (Flutter has no implicit sibling relationship,
///   so the scope is explicit; module 14 design spec § Limitations).
enum FwRelation {
  /// Ancestor → descendant propagation (`group-*`).
  group,

  /// Sibling → sibling propagation through the shared scope (`peer-*`).
  peer,
}

/// Matches when a named ancestor (`group-*`) or sibling (`peer-*`) channel holds
/// [state] (spec §6; module 14). The channel is selected by [relation]; the
/// in-channel slot by [name] (`null` = the default/unnamed channel — for
/// `group-*` that resolves to the *nearest* `FwGroup`).
///
/// Sealed-family member so the resolver stays exhaustive without a `default:`.
@immutable
final class FwGroupCondition extends FwCondition {
  /// Creates a group/peer condition for [relation] + [state], optionally [name]d.
  const FwGroupCondition(this.relation, this.state, {this.name});

  /// Whether this reads the group (ancestor) or peer (sibling) channel.
  final FwRelation relation;

  /// The interaction state to match within the selected channel.
  final WidgetState state;

  /// The named group/peer to read (`null` = the default/unnamed channel).
  final String? name;

  @override
  bool matches(
    Set<WidgetState> states,
    double? viewportWidth,
    double? containerWidth, {
    Map<String?, Set<WidgetState>>? groupStates,
    Map<String?, Set<WidgetState>>? peerStates,
  }) {
    final channel = relation == FwRelation.group ? groupStates : peerStates;
    final set = channel?[name];
    return set != null && set.contains(state);
  }

  @override
  bool operator ==(Object other) =>
      other is FwGroupCondition &&
      other.relation == relation &&
      other.state == state &&
      other.name == name;

  @override
  int get hashCode => Object.hash(relation, state, name);
}

/// Matches when [state] is in the active interaction set (widths irrelevant).
@immutable
final class FwStateCondition extends FwCondition {
  /// Creates a state condition for [state].
  const FwStateCondition(this.state);

  /// The interaction state to match.
  final WidgetState state;

  @override
  bool matches(
    Set<WidgetState> states,
    double? viewportWidth,
    double? containerWidth, {
    Map<String?, Set<WidgetState>>? groupStates,
    Map<String?, Set<WidgetState>>? peerStates,
  }) => states.contains(state);

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
  bool matches(
    Set<WidgetState> states,
    double? viewportWidth,
    double? containerWidth, {
    Map<String?, Set<WidgetState>>? groupStates,
    Map<String?, Set<WidgetState>>? peerStates,
  }) => viewportWidth != null && viewportWidth >= breakpoint.minWidth;

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
  bool matches(
    Set<WidgetState> states,
    double? viewportWidth,
    double? containerWidth, {
    Map<String?, Set<WidgetState>>? groupStates,
    Map<String?, Set<WidgetState>>? peerStates,
  }) => containerWidth != null && containerWidth >= breakpoint.minWidth;

  @override
  bool operator ==(Object other) => other is FwContainerCondition && other.breakpoint == breakpoint;

  @override
  int get hashCode => breakpoint.hashCode;
}

import 'package:flutter/widgets.dart';

import '../theme/context_fw.dart';
import 'fw_group.dart';
import 'fw_layer.dart';
import 'fw_style.dart';
import 'fw_style_ops.dart';
import 'resolve.dart';
import 'resolved_style.dart';
import 'resolved_style_build.dart';

/// Extension entry point: begin a style chain on any widget (spec §6.2).
extension TwExtension on Widget {
  /// Wraps this widget in an [FwStyled] so `.tw`-utilities can style the box.
  FwStyled get tw => FwStyled(style: const FwStyle(), child: this);
}

/// The widget that applies an [FwStyle] to a single [child] (spec §6.2).
///
/// Exposes the builder utilities via [FwStyleOps] (each returns a new `FwStyled`
/// with the same child and an updated style) and conditionally inserts the
/// ancestors resolution needs — never more than required:
/// - a `LayoutBuilder` only when the flattened layer set has a container layer;
/// - a `MediaQuery` read only when it has a viewport layer;
/// - live interaction sourcing (`MouseRegion`/`Focus`/`Listener`) only when a
///   layer is keyed on a live-sourced state (hover/focus/pressed). Visual-only
///   state styling uses a non-traversable `Focus`, so a `hover:`-only box never
///   becomes a tab stop (Finding #9, §7). Component-managed states (`selected`,
///   `disabled`, …) arrive via [states] and resolve without any of these.
///
/// `FwStyled` is semantics-transparent: it wraps, never replaces, the child's
/// `Semantics` (spec §7).
class FwStyled extends StatelessWidget with FwStyleOps<FwStyled> {
  /// Creates a styled box. Prefer the `.tw` getter ([TwExtension.tw]) over
  /// calling this directly.
  const FwStyled({required this.child, required this.style, this.states, super.key});

  /// The single child being styled.
  final Widget child;

  /// The accumulated style.
  final FwStyle style;

  /// Optional externally-injected interaction states (component-managed states
  /// such as `selected`, merged with detector-sourced states, §6.5).
  final Set<WidgetState>? states;

  @override
  FwStyle get fwStyle => style;

  @override
  FwStyled fwRebuild(FwStyle next) => FwStyled(style: next, states: states, key: key, child: child);

  /// The interaction states the engine sources on its own. A layer keyed on one
  /// of these needs a live detector; component-managed states (`selected`,
  /// `disabled`, …) are injected via [states] and resolve without one (§6.5).
  static const Set<WidgetState> _liveStates = <WidgetState>{
    WidgetState.hovered,
    WidgetState.focused,
    WidgetState.pressed,
  };

  bool _anyCondition(bool Function(FwCondition) test) {
    bool walk(FwStyle s) {
      for (final (cond, nested) in s.layers) {
        if (test(cond) || walk(nested)) {
          return true;
        }
      }
      return false;
    }

    return walk(style);
  }

  /// Whether any layer (at any depth) is keyed on a live-sourced state, which is
  /// the only thing that requires the `MouseRegion`/`Focus`/`Listener` wrappers.
  bool get _needsLiveStateSourcing =>
      _anyCondition((c) => c is FwStateCondition && _liveStates.contains(c.state));

  /// Whether any layer (at any depth) is a group/peer condition — the only thing
  /// that requires reading the nearest `FwGroup` scope (module 14). Group/peer
  /// state is sourced by the ancestor `FwGroup`/`FwPeer`, never by this box, so it
  /// does NOT trigger this box's own live sourcing.
  bool get _needsRelationStates => _anyCondition((c) => c.isRelation);

  /// Whether any style node (base or nested layer) carries a radius/shadow *step*
  /// (module 15 named-scale sugar). The only thing that makes `FwStyled` read the
  /// theme (`context.fw`) — gated so a non-sugar box stays theme-agnostic.
  bool get _needsTokenSteps {
    bool walk(FwStyle s) {
      if (s.radiusStep != null || s.shadowStep != null) return true;
      for (final (_, nested) in s.layers) {
        if (walk(nested)) return true;
      }
      return false;
    }

    return walk(style);
  }

  @override
  Widget build(BuildContext context) {
    // Container layers need the enclosing constraint width via a LayoutBuilder.
    if (_anyCondition((c) => c.isContainer)) {
      return LayoutBuilder(
        builder:
            (context, constraints) =>
                _build(context, constraints.maxWidth.isFinite ? constraints.maxWidth : null),
      );
    }
    return _build(context, null);
  }

  Widget _build(BuildContext context, double? containerWidth) {
    final viewportWidth =
        _anyCondition((c) => c.isViewport) ? MediaQuery.maybeOf(context)?.size.width : null;

    // Named-scale sugar (module 15): resolve radius/shadow steps against the
    // active theme into concrete values BEFORE resolve(), which stays
    // context-free. Gated so a non-sugar box never reads the theme. Conditions
    // are unchanged by this pass, so the *needs* checks below read the original.
    final effectiveStyle = _needsTokenSteps ? style.resolveTokenSteps(context.fw) : style;

    // Read the nearest FwGroup scope only when a group/peer layer is present
    // (otherwise no dependency is created). Sourcing is the FwGroup/FwPeer's job;
    // this box is a pure reader that rebuilds via its scope dependency.
    final relation =
        _needsRelationStates
            ? fwReadRelationStates(context)
            : const (groupStates: null, peerStates: null);

    // Interactive path only when a layer is keyed on a live-sourced state.
    // Component-managed states arrive via [states] and resolve statelessly.
    if (_needsLiveStateSourcing) {
      return _FwStyledInteractive(
        style: effectiveStyle,
        injected: states ?? const <WidgetState>{},
        viewportWidth: viewportWidth,
        containerWidth: containerWidth,
        groupStates: relation.groupStates,
        peerStates: relation.peerStates,
        child: child,
      );
    }

    final ResolvedStyle resolved = effectiveStyle.resolve(
      states ?? const <WidgetState>{},
      viewportWidth: viewportWidth,
      containerWidth: containerWidth,
      groupStates: relation.groupStates,
      peerStates: relation.peerStates,
    );
    return resolved.build(child);
  }
}

/// Sources live hovered/focused/pressed for an [FwStyled] that declares state
/// layers, merges them with [injected] states, resolves, and builds. Private:
/// only `FwStyled._build` constructs it.
class _FwStyledInteractive extends StatefulWidget {
  const _FwStyledInteractive({
    required this.style,
    required this.injected,
    required this.viewportWidth,
    required this.containerWidth,
    required this.groupStates,
    required this.peerStates,
    required this.child,
  });

  final FwStyle style;
  final Set<WidgetState> injected;
  final double? viewportWidth;
  final double? containerWidth;
  final Map<String?, Set<WidgetState>>? groupStates;
  final Map<String?, Set<WidgetState>>? peerStates;
  final Widget child;

  @override
  State<_FwStyledInteractive> createState() => _FwStyledInteractiveState();
}

class _FwStyledInteractiveState extends State<_FwStyledInteractive> {
  // Visual-only in M3 (no action): the node never requests focus and is skipped
  // by traversal, so a hover-only box adds no tab stop (Finding #9, §7). A
  // component that wires an action makes its box focusable + adds a ring later.
  late final FocusNode _focusNode = FocusNode(
    skipTraversal: true,
    canRequestFocus: false,
    debugLabel: 'FwStyled(visual-only)',
  );

  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get _disabled => widget.injected.contains(WidgetState.disabled);

  Set<WidgetState> get _activeStates => <WidgetState>{
    ...widget.injected,
    // Disabled suppresses the live states (resolve also suppresses, but
    // gating here keeps the press recognizer from re-adding pressed).
    if (!_disabled && _hovered) WidgetState.hovered,
    if (!_disabled && _focused) WidgetState.focused,
    if (!_disabled && _pressed) WidgetState.pressed,
  };

  void _setHovered(bool value) {
    if (_hovered != value) {
      setState(() => _hovered = value);
    }
  }

  void _setFocused(bool value) {
    if (_focused != value) {
      setState(() => _focused = value);
    }
  }

  void _setPressed(bool value) {
    if (_disabled) {
      return; // disabled cannot be pressed
    }
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolved = widget.style.resolve(
      _activeStates,
      viewportWidth: widget.viewportWidth,
      containerWidth: widget.containerWidth,
      groupStates: widget.groupStates,
      peerStates: widget.peerStates,
    );

    // MouseRegion sources hover; the non-traversable Focus reflects focus
    // (without ever becoming a tab stop); Listener sources press. None of these
    // replace the child's semantics — they wrap it (spec §7).
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Focus(
        focusNode: _focusNode,
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: _setFocused,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _setPressed(true),
          onPointerUp: (_) => _setPressed(false),
          onPointerCancel: (_) => _setPressed(false),
          child: resolved.build(widget.child),
        ),
      ),
    );
  }
}

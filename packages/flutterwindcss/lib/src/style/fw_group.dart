import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Group / peer state propagation — the Flutter mapping of Tailwind's `group-*`
/// and `peer-*` variants (module 14; design spec
/// `2026-06-07-flutterwindcss-m14-group-peer-design.md`).
///
/// Flutter has no DOM and no sibling selectors, so a widget cannot implicitly
/// observe another widget's interaction state. The faithful idiom is an explicit
/// **scope**: [FwGroup] sources its own hover/focus/pressed and broadcasts a
/// `Set<WidgetState>` to its descendants (the `group-*` channel), and also hosts a
/// *peer channel* that descendant [FwPeer] markers publish into so a peer's
/// **sibling** reactors (also descendants of the same [FwGroup]) can read it (the
/// `peer-*` channel). One widget, two channels.
///
/// Reactors are ordinary `.tw` chains using `groupHover`/`peerHover`/… ; they read
/// the nearest scope through the private [_FwStateScope] `InheritedWidget` and
/// resolve against the channel maps. Reading is dependency-based, so a reactor
/// rebuilds when the scope's state changes.

// ---------------------------------------------------------------------------
// Scope plumbing (private).
// ---------------------------------------------------------------------------

/// Immutable snapshot of a scope's state, handed to descendant reactors. Carries
/// the scope [name], this group's own [groupStates], the aggregated [peerStates]
/// (name → union of all peers under this scope publishing that name), and the
/// enclosing scope's [parent] model (so named-group lookups can walk ancestors).
@immutable
class _FwScopeModel {
  const _FwScopeModel({
    required this.name,
    required this.groupStates,
    required this.peerStates,
    required this.parent,
  });

  final String? name;
  final Set<WidgetState> groupStates;
  final Map<String?, Set<WidgetState>> peerStates;
  final _FwScopeModel? parent;

  @override
  bool operator ==(Object other) =>
      other is _FwScopeModel &&
      other.name == name &&
      setEquals(other.groupStates, groupStates) &&
      _peerMapEquals(other.peerStates, peerStates) &&
      other.parent == parent;

  @override
  int get hashCode => Object.hash(
    name,
    Object.hashAllUnordered(groupStates),
    // Hash peer keys AND values so hashCode is consistent with `==` (which
    // compares the per-name state sets), not just the key set.
    Object.hashAllUnordered(<int>[
      for (final MapEntry(:key, :value) in peerStates.entries)
        Object.hash(key, Object.hashAllUnordered(value)),
    ]),
    parent,
  );

  static bool _peerMapEquals(Map<String?, Set<WidgetState>> a, Map<String?, Set<WidgetState>> b) {
    if (a.length != b.length) return false;
    for (final MapEntry(:key, :value) in a.entries) {
      final other = b[key];
      if (other == null || !setEquals(value, other)) return false;
    }
    return true;
  }
}

/// Stable controller (lives for the [FwGroup]'s lifetime) that owns the peer
/// registry and triggers a rebuild when the aggregated peer state changes. Kept
/// separate from the immutable [_FwScopeModel] so descendant [FwPeer]s have a
/// stable write target across rebuilds.
class _FwScopeController {
  _FwScopeController(this._onChanged);

  final VoidCallback _onChanged;

  /// Per-peer published state, keyed by the peer's identity so multiple peers
  /// (even sharing a name) aggregate by union rather than clobbering.
  final Map<Object, ({String? name, Set<WidgetState> states})> _peers =
      <Object, ({String? name, Set<WidgetState> states})>{};

  /// The current name → union-of-states aggregate (rebuilt on every mutation).
  Map<String?, Set<WidgetState>> peerStates = const <String?, Set<WidgetState>>{};

  void setPeer(Object id, String? name, Set<WidgetState> states) {
    final existing = _peers[id];
    if (existing != null && existing.name == name && setEquals(existing.states, states)) {
      return; // no change
    }
    _peers[id] = (name: name, states: states);
    _recompute();
  }

  void removePeer(Object id) {
    if (_peers.remove(id) != null) _recompute();
  }

  void _recompute() {
    final map = <String?, Set<WidgetState>>{};
    for (final (:name, :states) in _peers.values) {
      (map[name] ??= <WidgetState>{}).addAll(states);
    }
    peerStates = map;
    _notify();
  }

  /// Triggers the rebuild, deferring to after the frame if we are *inside* a
  /// build/layout/paint phase (a descendant publishing during its own
  /// `didChangeDependencies`/`dispose` would otherwise `setState` the ancestor
  /// mid-build). Pointer-driven changes run between frames and fire immediately.
  void _notify() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _onChanged());
    } else {
      _onChanged();
    }
  }
}

/// The `InheritedWidget` carrying a scope's [model] (for reactors to read) and
/// its stable [controller] (for descendant [FwPeer]s to write).
class _FwStateScope extends InheritedWidget {
  const _FwStateScope({required this.model, required this.controller, required super.child});

  final _FwScopeModel model;
  final _FwScopeController controller;

  /// Reads + depends on the nearest scope (reactors: rebuild when state changes).
  static _FwStateScope? dependOn(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FwStateScope>();

  /// Reads the nearest scope WITHOUT creating a dependency ([FwPeer] writers, and
  /// [FwGroup] capturing its parent for the model chain).
  static _FwStateScope? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_FwStateScope>();

  @override
  bool updateShouldNotify(_FwStateScope oldWidget) => model != oldWidget.model;
}

// ---------------------------------------------------------------------------
// Public widgets.
// ---------------------------------------------------------------------------

/// Marks a subtree as a Tailwind **group** *and* as the **peer scope** for the
/// peers inside it (module 14).
///
/// `FwGroup` sources its own hover/focus/pressed with the engine's visual-only
/// primitives — `MouseRegion` + a **non-traversable** `Focus` + `Listener`, never
/// a `FocusableActionDetector` (it owns no action, so it must not become a tab
/// stop; engine spec §6.2) — and broadcasts the result to descendants. A `.tw`
/// chain inside reacts with `groupHover`/`groupFocus`/`groupPressed`/
/// `groupDisabled`/`groupState`.
///
/// It also hosts the peer channel: a descendant [FwPeer] publishes its state here
/// so the peer's sibling reactors (`peerHover`/…) can read it. To use peers
/// *without* a visual group, wrap the region in `FwGroup` purely as a scope and
/// simply don't add any `group-*` reactors. (In that peer-only case the group
/// still sources its own hover/focus/pressed and inserts a `MouseRegion`/`Focus`/
/// `Listener` — a small, harmless cost; unlike [FwStyled] it cannot introspect its
/// descendants to skip them.)
///
/// - [name] keys a **named** group (Tailwind `group/sidebar`), so a nested group
///   doesn't shadow it: `groupHover(…, name: 'sidebar')` targets this group even
///   from inside a closer `FwGroup`. `null` (the default) is matched by unnamed
///   `group-*`, which always binds to the *nearest* `FwGroup`.
/// - [states] injects component-managed states (`disabled`, `selected`, …) merged
///   with the live-sourced ones — this is how `groupDisabled`/`groupState` fire.
class FwGroup extends StatefulWidget {
  /// Creates a group/peer scope around [child].
  const FwGroup({required this.child, this.name, this.states, super.key});

  /// The scoped subtree.
  final Widget child;

  /// Optional name for a Tailwind named group (`group/name`).
  final String? name;

  /// Optional injected component-managed states (merged with hover/focus/pressed).
  final Set<WidgetState>? states;

  @override
  State<FwGroup> createState() => _FwGroupState();
}

class _FwGroupState extends State<FwGroup> {
  late final _FwScopeController _controller = _FwScopeController(_handleControllerChange);

  // Visual-only sourcing (engine spec §6.2): never a tab stop.
  late final FocusNode _focusNode = FocusNode(
    skipTraversal: true,
    canRequestFocus: false,
    debugLabel: 'FwGroup(visual-only)',
  );

  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (mounted) setState(() {});
  }

  bool get _disabled => widget.states?.contains(WidgetState.disabled) ?? false;

  Set<WidgetState> get _ownStates => <WidgetState>{
    ...?widget.states,
    // Disabled gates the live states (resolve also suppresses, but gating keeps
    // a stuck `pressed` from re-arming — mirrors `_FwStyledInteractive`).
    if (!_disabled && _hovered) WidgetState.hovered,
    if (!_disabled && _focused) WidgetState.focused,
    if (!_disabled && _pressed) WidgetState.pressed,
  };

  void _setHovered(bool value) {
    if (_hovered != value) setState(() => _hovered = value);
  }

  void _setFocused(bool value) {
    if (_focused != value) setState(() => _focused = value);
  }

  void _setPressed(bool value) {
    if (_disabled) return;
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    // Capturing the parent scope (without depending) would miss ancestor state
    // changes; depend so a named-ancestor group change rebuilds this nested scope
    // and, in turn, its reactors.
    final parent = _FwStateScope.dependOn(context)?.model;
    final model = _FwScopeModel(
      name: widget.name,
      groupStates: _ownStates,
      peerStates: _controller.peerStates,
      parent: parent,
    );

    return _FwStateScope(
      model: model,
      controller: _controller,
      child: MouseRegion(
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
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Marks a widget as a Tailwind **peer**: it sources its own interaction state
/// and publishes it to the enclosing [FwGroup] scope so the peer's **sibling**
/// reactors can style themselves with `peerHover`/`peerFocus`/… (module 14).
///
/// `FwPeer` MUST be placed inside an [FwGroup] (the shared scope through which a
/// sibling reads the peer — Flutter has no implicit sibling relationship); it
/// asserts otherwise. The peer itself renders no styling from its own state
/// (that is what a plain `.tw` `hover` is for); it only *broadcasts*.
///
/// - [name] keys a named peer (Tailwind `peer/email`), read by `peerHover(…,
///   name: 'email')`. Multiple peers sharing a name aggregate by **union**.
/// - [states] injects component-managed states (e.g. a form field's `error`/
///   `disabled`) merged with the live-sourced ones — how `peerState` fires.
class FwPeer extends StatefulWidget {
  /// Creates a peer marker around [child].
  const FwPeer({required this.child, this.name, this.states, super.key});

  /// The peer widget (its interaction state is what siblings react to).
  final Widget child;

  /// Optional name for a Tailwind named peer (`peer/name`).
  final String? name;

  /// Optional injected component-managed states (merged with hover/focus/pressed).
  final Set<WidgetState>? states;

  @override
  State<FwPeer> createState() => _FwPeerState();
}

class _FwPeerState extends State<FwPeer> {
  /// Identity for this peer in the scope registry (so peers don't clobber).
  final Object _id = Object();

  _FwScopeController? _scope;

  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _disabled => widget.states?.contains(WidgetState.disabled) ?? false;

  Set<WidgetState> get _states => <WidgetState>{
    ...?widget.states,
    if (!_disabled && _hovered) WidgetState.hovered,
    if (!_disabled && _focused) WidgetState.focused,
    if (!_disabled && _pressed) WidgetState.pressed,
  };

  void _publish() => _scope?.setPeer(_id, widget.name, _states);

  /// Resolves the nearest scope and, if it changed (mount or a GlobalKey
  /// reparent — `didChangeDependencies` does NOT fire on reparent because an
  /// `FwPeer` holds no inherited dependency, but `build` always re-runs), leaves
  /// the old scope before joining the new one. Returns false if there is no scope.
  bool _syncScope() {
    final scope = _FwStateScope.read(context)?.controller;
    if (!identical(scope, _scope)) {
      _scope?.removePeer(_id);
      _scope = scope;
    }
    return scope != null;
  }

  @override
  void dispose() {
    _scope?.removePeer(_id);
    super.dispose();
  }

  void _setHovered(bool value) {
    if (_hovered != value) {
      _hovered = value;
      _publish();
    }
  }

  void _setFocused(bool value) {
    if (_focused != value) {
      _focused = value;
      _publish();
    }
  }

  void _setPressed(bool value) {
    if (_disabled) return;
    if (_pressed != value) {
      _pressed = value;
      _publish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasScope = _syncScope();
    assert(
      hasScope,
      'flutterwindcss: FwPeer must be placed inside an FwGroup scope — peer state '
      'is shared with siblings through the enclosing FwGroup (Flutter has no '
      'implicit sibling relationship). Wrap the peer and its reactors in an FwGroup.',
    );
    // Publish the current state to the (possibly new) scope. Idempotent: setPeer
    // early-returns on no change, so steady-state rebuilds do no work; a real
    // change defers its notify past the build phase (see _FwScopeController).
    _publish();

    // Visual-only sourcing, like FwGroup — the peer owns no action.
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: _setFocused,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _setPressed(true),
          onPointerUp: (_) => _setPressed(false),
          onPointerCancel: (_) => _setPressed(false),
          child: widget.child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reactor-side reading (used by FwStyled).
// ---------------------------------------------------------------------------

/// The group/peer channel maps the resolver needs, read from the nearest scope.
typedef FwRelationStates =
    ({Map<String?, Set<WidgetState>>? groupStates, Map<String?, Set<WidgetState>>? peerStates});

/// Reads the nearest scope and builds the group/peer channel maps for `resolve`
/// (module 14). Returns `(null, null)` when there is no scope — group/peer
/// reactors then simply never match (Tailwind-faithful: `group-*`/`peer-*` with no
/// scope is inert, like a Tailwind variant with no matching ancestor/sibling).
/// Note the asymmetry: an [FwPeer] *widget* with no scope asserts (its state would
/// go nowhere — a clear misconfiguration), but a `peer-*`/`group-*` *reactor* with
/// no scope is silently inert (a missing optional ancestor is legitimate). Creates
/// a dependency so the reactor rebuilds on change.
///
/// The group map keys `null` to the **nearest** group (so unnamed `group-*` binds
/// nearest) and every ancestor's `name` to that ancestor's state (nearest-wins on
/// duplicate names). The peer map is the nearest scope's aggregate verbatim.
FwRelationStates fwReadRelationStates(BuildContext context) {
  final scope = _FwStateScope.dependOn(context);
  if (scope == null) {
    return (groupStates: null, peerStates: null);
  }
  final model = scope.model;
  final groups = <String?, Set<WidgetState>>{null: model.groupStates};
  for (_FwScopeModel? m = model; m != null; m = m.parent) {
    groups.putIfAbsent(m.name, () => m!.groupStates);
  }
  return (groupStates: groups, peerStates: model.peerStates);
}

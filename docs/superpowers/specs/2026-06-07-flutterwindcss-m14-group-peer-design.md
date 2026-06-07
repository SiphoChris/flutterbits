# flutterwindcss — Module 14: `group-*` / `peer-*` state propagation (design)

**Status:** design → implementation · **Date:** 2026-06-07 · **Module:** 14 ·
**Audience:** engine maintainers. Builds on the core engine design spec
(`2026-06-05-flutterwindcss-core-engine-design.md`, §6 resolver/states) and the
coverage roadmap (`2026-06-07-flutterwindcss-coverage-and-roadmap.md`, Tier 2 #1).

## What this ships

Tailwind's parent/sibling state variants, faithfully mapped to Flutter:

- **`group-*`** — a descendant styles itself from an **ancestor's** interaction
  state (`group-hover:`, `group-focus:`, `group-active:`, `group-disabled:`, plus
  component-managed states and **named** groups `group-hover/name:`).
- **`peer-*`** — a widget styles itself from a **sibling's** interaction state
  (`peer-hover:`, …, named `peer-hover/email:`).

This is the **#1 highest-value not-built item** on the roadmap ("the most-used
missing interactivity feature").

## Feasibility verdict (AGENTS.md §12 "Verdict before won't")

**Buildable in full — neither half is a §11a impossibility.**

- **group** maps 1:1 to Flutter: an ancestor widget sources its own
  hover/focus/pressed and broadcasts a `Set<WidgetState>` to descendants via an
  `InheritedWidget`; a new resolver condition matches against it. This is exactly
  the mechanism the roadmap names.
- **peer** is the only real design question, because **Flutter has no DOM and no
  sibling selectors** — a widget cannot implicitly observe a sibling. This is *not*
  an impossibility (cost/structure, not "can't"): the faithful idiom is an
  **explicit shared ancestor scope** through which a marked sibling's state reaches
  the reactors. CSS gets the scope implicitly from the DOM; we make it explicit.
  Documented as a known, necessary CSS-vs-Flutter difference (§ "Limitations").

## Decision: unified scope (signed off 2026-06-07)

The genuine user-facing trade-off was *how* to model the peer scope. Options
considered: (A) one unified scope widget; (B) a separate `FwPeerScope` + `FwPeer`
pair; (C) group-only now, defer peer. **Chosen: (A) unified scope** — minimal new
public surface, both halves ship in full, no later deprecation cycle (§3.6).

**`FwGroup` is the single broadcast/scope widget.** It does two jobs:

1. Sources **its own** interaction state (hover/focus/pressed) and exposes it on
   the *group channel* for `group-*` reactors among its descendants.
2. Hosts a *peer channel* that descendant `FwPeer` markers publish into, so a
   peer's sibling reactors (also descendants of the same `FwGroup`) can read it via
   `peer-*`.

Peer-without-group is therefore expressed by using `FwGroup` purely as a scope (add
`FwPeer` + `peer-*` reactors inside it; just don't use `group-*`). `FwPeer` **must**
sit inside an `FwGroup`; without one it asserts with a clear message.

## Public surface (frozen once shipped — §3.6)

Widgets (exported from the barrel):

```dart
FwGroup({String? name, Set<WidgetState>? states, required Widget child})
FwPeer ({String? name, Set<WidgetState>? states, required Widget child})
```

- `name` keys a **named** group/peer (Tailwind `group/sidebar`, `peer/email`) so
  nested groups and multiple peers disambiguate. `null` = the default channel.
- `states` injects **component-managed** states (e.g. `disabled`, `selected`,
  `checked`) the same way `FwStyled.states` does — merged with the live-sourced
  hover/focus/pressed. This makes `group-disabled:` / `peer-checked:` work.

`.tw` setters (added to `FwStyleOps`, so usable on both `FwStyled` and in nested
layer callbacks):

```dart
groupHover(build, {name}) groupFocus(…) groupPressed(…) groupDisabled(…)
groupState(WidgetState, build, {name})            // escape hatch (group-selected, …)
peerHover (build, {name}) peerFocus (…) peerPressed (…) peerDisabled (…)
peerState (WidgetState, build, {name})
```

Naming note: Tailwind's `group-active:` ↔ **`groupPressed`** (we match the engine's
existing `pressed` setter name, not CSS `active`; the Tailwind name is in the
doc-comment). Same for `peerPressed`.

The reactor-side plumbing (`fwReadRelationStates`, `FwRelationStates`) is **not**
part of the public surface: it is `hide`-n from the barrel (`export … hide
fwReadRelationStates, FwRelationStates;`) and consumed by `FwStyled` via a direct
`src` import, exactly like `resolve`/`ResolvedStyle` (audit 2026-06-07).

## Mechanism

### Scope: callback-up, immutable-model-down (idiomatic Flutter)

`FwGroup` is a `StatefulWidget` that sources hover/focus/pressed with the engine's
**visual-only** sourcing primitives — `MouseRegion` + a **non-traversable** `Focus`
+ `Listener` — *not* a `FocusableActionDetector` (engine spec §6.2: a group box owns
no action, so it must not become a tab stop). On any change it `setState`s and
rebuilds an immutable `_FwScopeModel` exposed to descendants through a private
`_FwStateScope extends InheritedWidget`.

`_FwScopeModel` carries:

- `name` — this scope's name.
- `groupStates` — this group's own (sourced + injected, disabled-suppressed) set.
- `peerStates: Map<String?, Set<WidgetState>>` — published by descendant `FwPeer`s,
  keyed by peer name.
- `parent: _FwScopeModel?` — the enclosing scope's model (captured at build).

`FwPeer` resolves the nearest scope's stable controller **in `build`** (not
`didChangeDependencies` — that does not fire on a GlobalKey reparent, because an
`FwPeer` holds no inherited dependency, whereas `build` always re-runs; audit
2026-06-07) and **publishes up** via `setPeer(id, name, states)`, keyed by a
per-peer identity so multiple same-named peers **union** rather than clobber. When
the resolved controller changes (mount or reparent), the peer first deregisters
from the old scope. The `FwGroup` `setState`s, rebuilding the model with the
updated `peerStates`, so reactors rebuild. Pointer-driven changes publish
immediately (between frames); a publish that runs during the build phase defers its
`setState` to the post-frame via a `SchedulerPhase` guard in the controller. Peer
state is **nearest-scope only** (siblings share the nearest scope) — no chain walk.
Named-ancestor **group** lookup walks `model.parent`; cross-scope live updates come
for free because an ancestor `FwGroup`'s `setState` rebuilds nested `FwGroup`s,
which produce a new model (`parent` changed) → `updateShouldNotify` true → reactors
rebuild. **No `ChangeNotifier`, no listener bookkeeping.**

### Resolver

A new sealed-family member:

```dart
enum FwRelation { group, peer }

final class FwGroupCondition extends FwCondition {
  const FwGroupCondition(this.relation, this.state, {this.name});
  // matches against the group/peer state maps (below); == / hashCode on the triple
}
```

`FwCondition.matches` gains two optional params — `groupStates` and `peerStates`
(`Map<String?, Set<WidgetState>>?`). The three existing conditions ignore them;
`FwGroupCondition` reads the map for its `relation` at key `name`. `resolve()` gains
the same two optional maps and forwards them to `matches`.

**Map shape built by `FwStyled`** (only when the style declares a group/peer
condition — otherwise nothing is read and no scope dependency is created):

- `groupStates`: key `null` → the **nearest** group's set (so unnamed `group-*`
  binds to the nearest `FwGroup`, Tailwind-faithful); plus key `name` → that named
  ancestor's set for every ancestor (nearest-wins on duplicate names).
- `peerStates`: the nearest scope's `peerStates` map verbatim (already name-keyed;
  `null` = the default/unnamed peer).

**Suppression** mirrors the box's own states (spec §6.3 Finding #7): if a channel's
set contains `disabled`, hover/focus/pressed are stripped from *that channel* before
matching — a disabled group/peer doesn't fire hover. Applied per channel in
`resolve`.

**Precedence:** `FwGroupCondition` ranks in the **state tier** (tier 1), the same as
`FwStateCondition` — a pseudo-class-like variant above all breakpoints, with
declaration order breaking ties. `_precedence` adds the case.

### `FwStyled` integration

`FwStyled` (both the static path and `_FwStyledInteractive`) reads the nearest
`_FwStateScope` **only when** the flattened layer set contains a group/peer
condition, builds the two maps, and passes them to `resolve`. Group/peer never make
`FwStyled` source its *own* state (`_needsLiveStateSourcing` is unchanged) — sourcing
is the `FwGroup`/`FwPeer`'s job; `FwStyled` is a pure reader and rebuilds via its
inherited dependency on the scope.

## Limitations (documented, honest)

- **Peer requires an explicit `FwGroup` scope ancestor** (Flutter has no implicit
  sibling relationship). `FwPeer` asserts if used outside one. This is the faithful
  Flutter idiom, not a missing capability.
- **Group/peer sourcing is visual-only** (no tab stop), like the engine's `.tw`
  state sourcing. A `group-focus:` only lights when something inside actually takes
  focus or focus is injected via `states` — consistent with the engine's
  non-traversable focus policy (§6.2).
- **Layers are additive/override-only** (unchanged accumulator semantics): a
  `group-hover:` layer can set fields but cannot unset base fields.

## Tests (mandatory — §9)

- **Unit (`fw_layer`)**: `FwGroupCondition.matches` for group/peer × named/unnamed;
  `==`/`hashCode`.
- **Unit (`resolve`)**: a group/peer layer applies when the channel holds the state;
  disabled suppression per channel; named lookup picks the right ancestor; precedence
  above a breakpoint; declaration-order tie-break vs own `hover`.
- **Widget (`fw_group`)**: live — `FwGroup` hover drives a descendant's resolved
  style (pump + `WidgetTester` pointer; assert the rendered `DecoratedBox` color
  flips). `FwPeer` publish drives a *sibling* reactor. Nested **named** groups: inner
  reactor targets the outer group by name. `FwPeer` outside a scope asserts. Injected
  `states` drive `group-disabled:`. RTL parity (a directional field in a group layer).
- **Golden (`group_slice`)**: deterministic via **injected** `states` (e.g.
  `FwGroup(states: {hovered})`) so the hovered visual is captured without a live
  pointer; light + dark.

## Example app

A new `GroupPeerSection` + `ShowcaseCategory.groupPeer` tab with live demos (a card
whose children react to `group-hover`; an input-and-label `peer-focus` pair; a named
nested group). The smoke test iterates `ShowcaseCategory.values`, so the section is
covered automatically in light/dark × LTR/RTL.

## No-drift updates (same PR — §12)

- Roadmap: mark group/peer **✅ module 14**; drop it from the "highest-value
  NOT-BUILT" list and renumber; update the coverage snapshot Interactivity row and
  the "Built since" / sequencing notes.
- Core engine design spec: add the group/peer condition + scope mechanism to the
  resolver/states section.
- README: coverage + the documented peer-scope limitation.

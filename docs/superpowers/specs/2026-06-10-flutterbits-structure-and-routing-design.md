# flutterbits — structure layer & routing (design)

**Status:** design · **Date:** 2026-06-10 · **Audience:** implementers of the flutterbits structure layer.
**Parent:** `2026-06-10-flutterbits-charter.md`. **Sibling:** `2026-06-10-flutterbits-registry-cli-design.md`.

This spec designs the **differentiator**: the opinionated, intention-revealing app skeleton (`Layout`, `Screen`) and the routing that wraps `go_router`. All names are unprefixed *components* the dev composes; `Fw`-prefixed types are routing/engine **library** types (charter §5).

---

## 1. Philosophy recap (the bar this design must clear)

- **Intention-revealing** — `Layout`, `Screen`, `header`/`body`/`footer` read like the rendered artifact (charter §1.1).
- **Composition, not inheritance** — components are **widgets you return**, never base classes you extend. This is the single most important API decision in this spec (§2.1).
- **Feels good** — one concept expressed one way; a sheet is "a `Screen` mounted differently," not a separate API (§4).
- **Material-free** — built on `package:flutter/widgets.dart` + `context.fw`; never `Scaffold`/`MaterialApp`/`Navigator` directly in component code (the router wrapping is the one place `go_router` — itself Material-free-capable — is touched).

---

## 2. The vocabulary

```
Layout      ← app root. Holds config: theme, router, global providers.
            ← "the better MaterialApp." Also nestable (a section Layout =
            ← persistent chrome: bottom nav / sidebar).
  └─ Screen ← a routable destination. Owns screen-level concerns: safe area,
            ← status-bar style, header/footer regions, scroll ownership,
            ← background. "the better Scaffold." This is what the router targets.
       └─ blocks → primitives
```

`Page` was considered and **dropped**: a universal `Screen` covers mobile/desktop/web ("everyone knows what a screen is"), and a sub-`Screen` concept was unnecessary surface.

### 2.1 Composition, not inheritance — the decision that dissolves `ScreenSpec`

An earlier sketch had `Screen` as a **base class** whose `build` returned a *description* object (`ScreenSpec`). That forces a non-widget return type — the smell that made the name feel wrong. **Rejected.**

`Screen` and `Layout` are **composed widgets you return**:

- `Screen` is "the better `Scaffold`" — screen-level concerns are **intention-revealing named slots** (`header`/`body`/`footer`) plus props (`statusBar`, `background`).
- `Layout` is "the better `MaterialApp`" — you return `Layout(theme:, routes:, shell:)`; there is no `LayoutConfig` return object.
- A screen's **identity** comes from its file + its route, **not** a base class. So there is no `ScreenSpec`, no `extends Screen`, nothing un-Flutter.

**Why this is the strongest design:** zero new return-type concepts; plays with `const`; the slots read like semantic HTML; defaults are semantic-token-aware; `Screen`s stay plain widgets droppable anywhere (the root `Layout` is the one exception — it hosts the app + router, see §3.1). The "framework feel" comes from the *vocabulary*, not from inheritance.

No base class is introduced in v1 (no lifecycle hooks, no view-model binding — that is the deferred state-management decision, charter §9). A screen is an ordinary `StatelessWidget`/`StatefulWidget` that returns a `Screen`.

---

## 3. `Layout` and `Screen` — the API

### 3.1 `Layout` (root)

```dart
/// The app root. Config lives here; everything renders inside it.
class AppLayout extends StatelessWidget {
  const AppLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Layout(
      theme: appTheme,                 // generated FwTokens (light/dark) — see charter
      title: 'Tunes',
      // A nested layout: a persistent shell across the screens inside it.
      shell: TabsLayout(
        destinations: const [
          NavDestination(icon: LucideIcons.house, label: 'Home',    route: HomeRoute.pattern),
          NavDestination(icon: LucideIcons.user,  label: 'Profile', route: ProfileRoute.pattern),
        ],
      ),
      routes: const [HomeRoute.pattern, ProfileRoute.pattern],  // the table, in plain sight
      redirect: _authRedirect,         // optional global guard (§5.2)
    );
  }
}
```

- `theme` — the `FwTokens` light/dark bundle; `Layout` owns the light↔dark swap and drives the engine's `FwAnimatedTheme` so a toggle crossfades every `context.fw`-styled descendant.
- `shell` — an optional nested `Layout` (`TabsLayout`/`SidebarLayout`) providing persistent chrome. Maps to `go_router`'s `ShellRoute`.
- `routes` — the explicit route table (a plain `const` list of `FwRoutePattern`s; no codegen).
- **Root `Layout`** constructs the `go_router` configuration **and** the root `WidgetsApp.router`-family widget (Material-free). `runApp(const AppLayout())` works directly — the root `Layout` *is* the app.
- **Nested `Layout`** (one passed as `shell:`) is a **different role**: it compiles to a `go_router` `ShellRoute`/`StatefulShellRoute` **builder** that wraps the routed child with persistent chrome. It **must not** re-host a router or app widget. (The `shell:` value is a `Layout`-typed *description* the root translates into a `ShellRoute` builder; it is not itself a second app.)
- **Invariant (MUST):** exactly **one** root `Layout` hosts the app + router; every other `Layout` is a shell builder. The shared `Layout` name is deliberate vocabulary, but the two roles are distinct and the implementation keeps them separate. A `Layout` is therefore *not* "droppable anywhere" — it is either the root or a shell; only `Screen`s and below are freely composable. (Resolves the earlier ambiguity flagged in review — a returned widget that *is* the root router cannot also be an arbitrary child.)

### 3.2 `Screen` (destination) — slots

```dart
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Screen(
      statusBar: FwStatusBar.lightIcons,
      background: context.fw.colors.background,
      header: TopBar(title: const Text('Home')),     // <header>
      body:   FwColumn(gap: 4, children: [...]),       // <main>
      footer: null,                                    // <footer> (e.g. a CTA bar)
    );
  }
}
```

| Slot/prop | Role | Maps to |
|---|---|---|
| `header` | top region (title, actions, back) | `<header>` — a `TopBar`, or any widget |
| `body` | the screen's main content | `<main>` |
| `footer` | bottom region (CTA bar, nav) | `<footer>` |
| `statusBar` | `FwStatusBar` style enum | system-UI overlay style via `services.dart` (a flutterbits concern, Material-free) |
| `background` | screen fill (semantic token) | the page background |

`Screen` owns **safe-area insets**, scroll ownership conventions, and status-bar styling so the dev declares intent, not plumbing.

### 3.3 Naming pass (the types a dev sees most)

| Concept | Name | Why not the obvious |
|---|---|---|
| App root / nestable shell | `Layout` | — |
| Routable destination | `Screen` | — |
| Top bar widget | `TopBar` | not `AppBar` (Material-loaded) |
| Persistent bottom-nav shell | `TabsLayout` (a `Layout`) | nested layout = persistent chrome |
| Sidebar shell (by-demand) | `SidebarLayout` (a `Layout`) | desktop/web; charter §4 |
| Slots | `header` / `body` / `footer` | web-native; reads as the artifact |
| Status-bar style | `FwStatusBar` | flutterbits structure value type (`Fw`, like `FwPresentation`); wraps `services.dart` `SystemUiOverlayStyle` — flutterbits's, **not** the engine's |
| Back affordance | `BackButton` | unprefixed; typed `pop`. *Clashes with Material's `BackButton` under interop → resolve via the barrel namespace (charter §5.1).* |
| Sheet grabber | `SheetHandle` | used by sheet-presented screens |

---

## 4. Routing

**Decision: wrap `go_router` (do not build a router).** **Decision: typed route objects, hand-written, NO codegen** (the rejected codegen alternative is recorded in charter §9). The router engine is a trusted `pubDep`; flutterbits owns only the thin typed face.

### 4.1 The two route types

The route concept is split for ergonomics — the **navigation token** stays dead-simple; the **definition** holds every route fact in one obvious place.

```dart
// Navigation token: just typed args + where it lives.
class ProfileRoute extends FwRoute {
  const ProfileRoute({required this.userId});
  final int userId;

  @override
  String get location => '/profile/$userId';     // concrete path (navigation side)

  // The definition: path pattern + builder + presentation/transition/guard.
  static final pattern = FwRoutePattern(
    '/profile/:userId',
    builder: (s) => ProfileScreen(userId: int.parse(s.params['userId']!)),
  );
}
```

- `FwRoute` (instance) = the typed navigation token. Carries args, exposes `location`, and the navigation verbs (§4.2).
- `FwRoutePattern` (static `pattern`) = the registration-time definition: `path`, `builder` (parses `FwRouteState` → `Screen` widget), the optional `present` / `transition` / `guard` (§4.3–§4.5), and `children:` for **nested** routes (§4.3.1 — required for sheets that layer over a parent). One home for route facts; no redundancy between instance and definition.
- The hand-written cost is honest: ~3 lines per screen (`location` + `pattern` + the param-parse). In exchange: **zero build step**, a **self-contained copy-paste unit** (the `Screen` and its route in one file), a **readable route table**, and a **visible param-parse** you can customize. (The trade vs codegen is recorded in the charter; this is the chosen side.)

### 4.2 Navigation verbs

```dart
ProfileRoute(userId: 42).go(context);       // replace location (go_router `go`)
ProfileRoute(userId: 42).push(context);     // push on the stack
final picked = await ContactPickerRoute().push<Contact>(context);  // typed result back
context.pop();                              // BackButton calls this; auto-hidden if can't pop
```

`push<T>` returns a typed `Future<T?>`; a presented screen returns a value with `context.pop(result)`.

**Wiring:** the verbs are thin typed wrappers over `go_router` — `route.go(context)` ≡ `context.go(route.location)`, `route.push<T>(context)` ≡ `context.push<T>(route.location)`. The instance only needs its `location`; the matching `FwRoutePattern` (and its `present`/`transition`) is resolved by **path-match in the router**, not by the instance. **Web caveat (a genuine limitation, not effort):** a typed `push<T>` result requires a live in-app push that the user returns *from*. A cold deep-link, a browser refresh, or browser-back to a route has no pusher, so `await …push<T>()` may complete `null` on web — design result-bearing flows to also work without a result.

### 4.3 Presentations — "a sheet is a `Screen` mounted differently" (the feel-good core)

A single `present` knob on the definition decides how the screen is mounted. **One `Screen` concept** serves pages, sheets, dialogs, and full-screen covers — the dev never learns a separate "sheet API."

```dart
class EditProfileRoute extends FwRoute {
  const EditProfileRoute({required this.userId});
  final int userId;

  @override
  String get location => '/profile/$userId/edit';

  static final pattern = FwRoutePattern(
    '/profile/:userId/edit',
    present: FwPresentation.sheet,        // page | sheet | dialog | fullScreen
    transition: FwTransition.slideUp,     // optional; a sensible default per presentation
    builder: (s) => EditProfileScreen(userId: int.parse(s.params['userId']!)),
  );
}
```

```dart
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key, required this.userId});
  final int userId;

  @override
  Widget build(BuildContext context) {
    // Identical Screen API. Because the route mounts it as a sheet, the sheet
    // PRESENTATION (a custom Material-free PopupRoute — see below) supplies the
    // grabber, scrim, safe-area insets, rounded top & drag-to-dismiss.
    return Screen(
      header: const SheetHandle(),
      body: EditProfileForm(userId: userId),
      footer: FwRow(gap: 3, children: [
        Button.ghost(onPressed: () => context.pop(false), child: const Text('Cancel')),
        Button(
          onPressed: () async {
            await profiles.save(userId);
            if (context.mounted) context.pop(true);   // typed result back
          },
          child: const Text('Save'),
        ),
      ]),
    );
  }
}
```

Call site reads like a sentence:

```dart
final saved = await EditProfileRoute(userId: 7).push<bool>(context);
if (saved ?? false) showToast(context, 'Profile updated');
```

> Navigating to `/profile/7/edit` — from a link, the browser bar, or a push notification — opens the profile screen with the edit sheet **over** it, and system/browser **back closes the sheet** (the route pops). For the parent to render *underneath* on a cold deep-link, the sheet route MUST be a **child** of the parent route (§4.3.1), not a sibling.

**`FwPresentation`** values: `page` (default, full destination), `sheet` (bottom sheet), `dialog` (centered modal), `fullScreen` (full-screen cover, e.g. iOS modal).

**Honest scope (not "free"):** `go_router` ships only `MaterialPage`/`CupertinoPage`/`NoTransitionPage`. flutterbits is Material-free, so it **authors custom Material-free `Page`s** — `FwSheetPage` / `FwDialogPage` / `FwFullScreenPage`, each returning a custom `PopupRoute` returned from `go_router`'s `pageBuilder`. Those custom routes **own the scrim, safe-area insets, rounded top, the `SheetHandle` grabber, and drag-to-dismiss** — real, scheduled work (feasible — §11b "feasible, scoped" — **not** free). What *is* free from `go_router`: the route **pop** on back and the URL addressability. The gesture/scrim/chrome is flutterbits's to build.

#### 4.3.1 Deep-linkable sheets require nested routes

For `/profile/7/edit` to open the sheet *over* the profile screen on a **cold** deep-link, `EditProfileRoute` must be registered as a **child** of `ProfileRoute`, so the router builds the parent beneath the sheet page:

```dart
FwRoutePattern(
  '/profile/:userId',
  builder: (s) => ProfileScreen(userId: int.parse(s.params['userId']!)),
  children: [
    FwRoutePattern('edit',                       // → '/profile/:userId/edit'
      present: FwPresentation.sheet,
      builder: (s) => EditProfileScreen(userId: int.parse(s.params['userId']!))),
  ],
);
```

A flat *sibling* registration would **replace** the profile screen instead of layering the sheet over it. `FwRoutePattern.children` maps to `go_router`'s nested `routes:`. (The `EditProfileRoute` navigation token in §4.3 is unchanged; only the registration nests.)

### 4.4 Imperative overlays — for ephemera not worth a URL

Routable presentation (§4.3) is for screens that deserve a URL/deep link. For throwaway popups, **imperative helpers** (lib utils — see registry spec) avoid route ceremony:

```dart
final ok = await showConfirm(context,
  title: 'Delete track?', message: 'This can’t be undone.',
  confirm: 'Delete', tone: Tone.destructive);   // Tone = the shared normal/destructive intent enum

final picked = await showSheet<Color>(context, (_) => const ColorPickerSheet());
showToast(context, 'Saved');   // via the Toaster overlay host
```

Both worlds coexist by design: **routable** when it deserves a URL, **imperative** when it doesn't.

### 4.5 Guards / auth

Two ergonomic levels, both intention-revealing. A guard is `FutureOr<String?> Function(BuildContext, FwRouteState)` — it returns a redirect target, or `null` to allow. It is **async-capable** (so token checks / silent refreshes work), mapping directly onto `go_router`'s async `redirect`:

```dart
// Per-route (async-capable):
static final pattern = FwRoutePattern(
  '/dashboard',
  guard: (c, s) async => (await auth.isLoggedIn) ? null : LoginRoute(next: s.location).location,
  builder: (_) => const DashboardScreen(),
);

// Or global, on Layout (cross-cutting):
FutureOr<String?> _authRedirect(BuildContext c, FwRouteState s) =>
    (!auth.isLoggedIn && s.location.startsWith('/app')) ? LoginRoute().location : null;
```

Both map to `go_router`'s route-level and top-level `redirect` (both `FutureOr<String?>`).

### 4.6 Transitions

`FwTransition` — sensible Material-free defaults, overridable per route:
`slide` · `fade` · `scale` · `slideUp` · `none` · `custom`. Each presentation has a sensible default (e.g. `sheet` → `slideUp`). Bespoke motion composes `flutter_animate` inside the screen's body — the engine ships no element-animation subsystem (AGENTS.md §11b).

### 4.7 Deep links / web URLs — free

Because each route's `location` getter **is** a real path and its `pattern` parses it back, web URLs (correct address bar, refreshable) and mobile deep links work with no extra effort — typed navigation *and* shareable URLs from one declaration. This is a genuine selling point and falls out of `go_router`.

---

## 5. Nested shells (persistent chrome)

`TabsLayout` (and the by-demand `SidebarLayout`) are `Layout`s used as a `shell:` — they persist across the `Screen`s routed inside them, mapping to `go_router`'s `ShellRoute`. A tabbed home is one `TabsLayout` shell whose tabs route to sibling `Screen`s; switching tabs swaps the routed screen while the shell (and its state) persists.

```dart
TabsLayout(
  destinations: const [
    NavDestination(icon: LucideIcons.house, label: 'Home',    route: HomeRoute.pattern),
    NavDestination(icon: LucideIcons.disc,  label: 'Library', route: LibraryRoute.pattern),
    NavDestination(icon: LucideIcons.user,  label: 'Profile', route: ProfileRoute.pattern),
  ],
)
```

---

## 6. Accessibility & platform (inherited rules)

- Every interactive structure component meets AGENTS.md §6: `Semantics` roles/labels, keyboard activation (`ActivateIntent` → `CallbackAction`), a visible focus ring using `context.fw.colors.ring`, directional layout. This holds on mobile **and** web/desktop (charter §4).
- Mobile-first defaults: ≥44px touch targets, safe areas honored by `Screen`, `TabsLayout`/`BottomNav` + sheets as the primary idioms. Hover is enhancement-only.

---

## 7. Where it lives & deps

- All of the above are **flutterbits copy-paste source** (registry tier `structure`), importing `flutterwindcss` for styling.
- `pubDeps`: `go_router` (routing), `lucide_icons_flutter` (nav icons), `flutter_animate` (transitions/micro-motion). Declared on the structure components' manifests (charter §6).
- `flutterwindcss` is **untouched** — it never learns routing exists (charter §7).

---

## 8. Done criteria (this layer)

A structure component is done only when: composed (not inherited); slots/props are intention-revealing; routing is typed with a readable table; presentations work including deep-link + back-to-dismiss; accessible per §6; goldens cover the relevant states/brightness; and it is rendered in `apps/gallery` (the flutterbits component target — separate from the engine's `apps/example`) so CI compiles it. First slice: `Layout` + `Screen` + routing + `Button` + `ThemeToggle` (charter §8).

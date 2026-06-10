# flutterwindcss showcase

The engine showcase for [`flutterwindcss`](https://pub.dev/packages/flutterwindcss) — a Material-free
Flutter app that exercises **every** capability of the styling engine: tokens, the full `.tw` utility
surface, the layout widgets (flex/grid/stack/scroll), interaction states, group/peer, responsive +
container variants, transforms, filters, and animated theming.

It runs on the **pure path** (`WidgetsApp` + `FwAnimatedTheme`) and includes a live **Host: Pure ⇄
Material** toggle that re-resolves the whole showcase through the `FwThemeExtension` interop bridge,
plus light/dark and LTR/RTL switches.

## Run

```sh
flutter run        # any device, e.g. -d chrome / -d windows / -d macos
```

For a minimal copy-paste quickstart instead, see the package's own
[`example/`](../../packages/flutterwindcss/example). Full docs:
[flutterbits.vercel.app/docs/flutterwindcss](https://flutterbits.vercel.app/docs/flutterwindcss).

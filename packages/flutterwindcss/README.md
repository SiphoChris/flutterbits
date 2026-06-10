# flutterwindcss

**[Tailwind CSS](https://tailwindcss.com) v4's design system and styling vocabulary, for Flutter.**

📖 **[Documentation](https://flutterbits.vercel.app/docs/flutterwindcss)** · 🎨 **[Theme generator](https://flutterbits.vercel.app/theme-generator)** · 📦 **[pub.dev](https://pub.dev/packages/flutterwindcss)**

flutterwindcss gives you Tailwind's design tokens (spacing, radius, semantic colors, shadows, type)
and a chainable, typed utility API — `.tw` — over Flutter's **primitive** widgets. It's Material-free
(it never imports `package:flutter/material.dart`) and themes by **semantic indirection**, exactly
like [shadcn/ui](https://ui.shadcn.com): components reference roles (`primary`, `muted`, `border`),
and swapping the theme reskins everything.

```dart
import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

class Badge extends StatelessWidget {
  const Badge(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    return Text(label)
        .tw
        .px(3)
        .py(1)
        .bg(t.colors.primary)
        .text(t.colors.primaryForeground)
        .rounded(t.radii.full)
        .textSize(FwFontSize.sm.px);
  }
}
```

## Install

```yaml
dependencies:
  flutterwindcss: ^1.0.0
```

## Provide a theme

Wrap your app once; read tokens via `context.fw`. Works on a bare `WidgetsApp` (pure path) or inside
a `MaterialApp`:

```dart
// Pure path
FwTheme(tokens: FwTokens.light, child: const HomeScreen());

// Material interop
MaterialApp(
  theme: ThemeData(extensions: const [FwThemeExtension(tokens: FwTokens.light)]),
  home: const HomeScreen(),
);
```

Use `FwAnimatedTheme` instead of `FwTheme` to crossfade on theme/brightness changes.

## Theme portability

Paste any [tweakcn](https://tweakcn.com)/shadcn theme into the web **theme generator** at
**[flutterbits.vercel.app/theme-generator](https://flutterbits.vercel.app/theme-generator)** and copy
a ready-to-use `theme.dart` (two `const FwTokens`) — colors, radius, shadows and fonts, nothing
dropped.

## Documentation

📖 **Full docs: [flutterbits.vercel.app/docs/flutterwindcss](https://flutterbits.vercel.app/docs/flutterwindcss)**
— installation, the `.tw` utility reference, theming, layout, breakpoints, and the theme generator.

- **API reference** — the full dartdoc for every public type is on the
  [pub.dev package page](https://pub.dev/documentation/flutterwindcss/latest/).
- **A runnable example** is in [`example/`](example/) (and a larger showcase in
  [`apps/example`](https://github.com/SiphoChris/flutterbits/tree/main/apps/example)).

## License

MIT © Sipho Nkebe

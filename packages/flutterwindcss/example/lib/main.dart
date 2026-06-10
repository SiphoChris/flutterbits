// A minimal, Material-free flutterwindcss app.
//
// It shows the three things every flutterwindcss app uses: a theme provided once
// (`FwAnimatedTheme`), tokens read via `context.fw`, and styling expressed with
// the `.tw` utility chain plus the directional layout widgets. Toggling the theme
// crossfades every token. Run with `flutter run` (any device, e.g. `-d chrome`).
import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    // WidgetsApp is the pure-path (Material-free) host. FwAnimatedTheme provides
    // the tokens and crossfades them (FwTokens.lerp) whenever they change.
    return WidgetsApp(
      color: const Color(0xFF000000),
      debugShowCheckedModeBanner: false,
      builder: (context, _) {
        return FwAnimatedTheme(
          tokens: _dark ? FwTokens.dark : FwTokens.light,
          child: _Home(dark: _dark, onToggle: () => setState(() => _dark = !_dark)),
        );
      },
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({required this.dark, required this.onToggle});

  final bool dark;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    // The whole screen is a single styled box; FwColumn lays out the children
    // (directional + responsive, with a gap between them).
    return FwColumn(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      gap: 6,
      children: [
        const _Badge('flutterwindcss'),
        Text(
          'Tailwind tokens + the .tw chain, Material-free.',
        ).tw.text(t.colors.mutedForeground).textSize(FwFontSize.sm.px),
        // A button-like styled box. Tapping it toggles light/dark.
        GestureDetector(
          onTap: onToggle,
          child: Text(dark ? 'Switch to light' : 'Switch to dark').tw
              .px(4)
              .py(2)
              .bg(t.colors.primary)
              .text(t.colors.primaryForeground)
              .textSize(FwFontSize.sm.px)
              .rounded(t.radii.md),
        ),
      ],
    ).tw.bg(t.colors.background).wFull.hFull;
  }
}

/// A pill badge — the README quickstart, styled entirely through tokens.
class _Badge extends StatelessWidget {
  const _Badge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    return Text(label).tw
        .px(3)
        .py(1)
        .bg(t.colors.primary)
        .text(t.colors.primaryForeground)
        .rounded(t.radii.full)
        .textSize(FwFontSize.sm.px);
  }
}

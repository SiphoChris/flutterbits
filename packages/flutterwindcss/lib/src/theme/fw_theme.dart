import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';

/// The Material-free theme provider: carries the active [FwTokens] down the tree
/// (spec §5.1) **and** applies the theme's body (`sans`) font family as the
/// subtree's default text style. This is the **pure path** — it works in a bare
/// `WidgetsApp` with no Material dependency.
///
/// Applying `typography.sans` as the default means a pasted/generated theme's
/// fonts take effect automatically (you still *register* the font — bundle it in
/// `pubspec.yaml` or wire `google_fonts`; flutterwindcss ships none). The default
/// is *merged*, so any ambient text color/size is preserved — only the family is
/// set — and `.tw.fontSerif`/`.fontMono` switch to the theme's other families.
/// (On the interop path the host's `MaterialApp` owns the default text theme, so
/// there is no `FwTheme` wrapper to apply this — set the family on your
/// `ThemeData` `textTheme` there.)
///
/// Light/dark switching is the host app's job (AGENTS.md §5): the host rebuilds
/// with whichever [FwTokens] instance is active. For animated transitions the
/// later `FwAnimatedTheme` feeds interpolated tokens through this same widget.
///
/// Components never read this directly; they use `context.fw`, which resolves
/// [FwTheme] first and falls back to the Material `FwThemeExtension`
/// (AGENTS.md §3.4).
class FwTheme extends StatelessWidget {
  /// Provides [tokens] to [child] and its descendants, and sets the theme's
  /// `sans` family as the default text family for the subtree.
  const FwTheme({required this.tokens, required this.child, super.key});

  /// The active token bundle for this subtree.
  final FwTokens tokens;

  /// The subtree that reads the tokens via `context.fw`.
  final Widget child;

  /// The nearest [FwTheme]'s [tokens], or `null` if there is none above
  /// [context]. Registers [context] as a dependent, so it rebuilds when the
  /// provided tokens change.
  static FwTokens? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FwThemeScope>()?.tokens;

  @override
  Widget build(BuildContext context) {
    return _FwThemeScope(
      tokens: tokens,
      // Merge so only the family is set — ambient color/size/alignment are kept.
      child: DefaultTextStyle.merge(
        style: TextStyle(fontFamily: tokens.typography.sans),
        child: child,
      ),
    );
  }
}

/// The `InheritedWidget` that actually carries [FwTokens]; private so the lookup
/// goes through [FwTheme.maybeOf] / `context.fw` (the supported surface).
class _FwThemeScope extends InheritedWidget {
  const _FwThemeScope({required this.tokens, required super.child});

  final FwTokens tokens;

  @override
  bool updateShouldNotify(_FwThemeScope oldWidget) => oldWidget.tokens != tokens;
}

import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';

/// The Material-free theme provider: an [InheritedWidget] carrying the active
/// [FwTokens] down the tree (spec §5.1). This is the **pure path** — it works
/// in a bare `WidgetsApp` with no Material dependency.
///
/// Light/dark switching is the host app's job (AGENTS.md §5): the host rebuilds
/// with whichever [FwTokens] instance is active. For animated transitions the
/// later `FwAnimatedTheme` feeds interpolated tokens through this same widget.
///
/// Components never read this directly; they use `context.fw`, which resolves
/// [FwTheme] first and falls back to the Material `FwThemeExtension`
/// (AGENTS.md §3.4).
class FwTheme extends InheritedWidget {
  /// Provides [tokens] to [child] and its descendants.
  const FwTheme({required this.tokens, required super.child, super.key});

  /// The active token bundle for this subtree.
  final FwTokens tokens;

  /// The nearest [FwTheme]'s [tokens], or `null` if there is none above
  /// [context]. Registers [context] as a dependent, so it rebuilds when the
  /// provided tokens change.
  static FwTokens? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FwTheme>()?.tokens;

  @override
  bool updateShouldNotify(FwTheme oldWidget) => oldWidget.tokens != tokens;
}

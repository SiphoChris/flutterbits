import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// The **interop path**: a [ThemeExtension] that carries [FwTokens] on a
/// Material `ThemeData`, so identical component code works inside a
/// `MaterialApp` (spec §5.2). Host apps add it via
/// `ThemeData(extensions: [FwThemeExtension(tokens: ...)])`; `context.fw` reads
/// it when no Material-free [FwTheme] (the pure path) is present.
///
/// **This is the single sanctioned `package:flutter/material.dart` import in
/// the entire repo** (AGENTS.md §3.5). No other engine or component file may
/// import Material. The Material dependency is intentional and isolated here:
/// [lerp] lets Material's own theme-transition animation drive
/// [FwTokens.lerp], so a Material app's light/dark crossfade reskins
/// flutterwindcss components for free.
@immutable
class FwThemeExtension extends ThemeExtension<FwThemeExtension> {
  /// Wraps [tokens] as a Material theme extension.
  const FwThemeExtension({required this.tokens});

  /// The active token bundle this extension provides.
  final FwTokens tokens;

  /// The [FwTokens] carried by an [FwThemeExtension] on the ambient Material
  /// theme, or `null` if there is no Material theme or it has no such
  /// extension. Registers a dependency on the Material theme so callers rebuild
  /// when it changes.
  ///
  /// This indirection keeps the Material `Theme.of` lookup confined to this
  /// file — `context.fw` calls here rather than importing Material itself,
  /// preserving the single-Material-import rule (AGENTS.md §3.5).
  static FwTokens? maybeOf(BuildContext context) =>
      Theme.of(context).extension<FwThemeExtension>()?.tokens;

  @override
  FwThemeExtension copyWith({FwTokens? tokens}) => FwThemeExtension(tokens: tokens ?? this.tokens);

  @override
  FwThemeExtension lerp(ThemeExtension<FwThemeExtension>? other, double t) {
    if (other is! FwThemeExtension) {
      return this;
    }
    return FwThemeExtension(tokens: FwTokens.lerp(tokens, other.tokens, t));
  }

  @override
  bool operator ==(Object other) => other is FwThemeExtension && other.tokens == tokens;

  @override
  int get hashCode => tokens.hashCode;
}

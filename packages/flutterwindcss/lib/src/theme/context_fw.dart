import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';
import 'fw_theme.dart';
import 'fw_theme_extension.dart';

/// Provider-agnostic token access (spec §5.3). Components read tokens **only**
/// through `context.fw` (AGENTS.md §3.4) — never `Theme.of` directly — so the
/// same component works on the pure path (a bare `WidgetsApp` wrapped in
/// [FwTheme]) and the interop path (inside a `MaterialApp` carrying an
/// `FwThemeExtension`).
extension FwContext on BuildContext {
  /// The active [FwTokens] for this location in the tree.
  ///
  /// Resolution order:
  /// 1. The nearest [FwTheme] (pure path) — its tokens, if any.
  /// 2. else an `FwThemeExtension` on the ambient Material theme (interop path).
  /// 3. else throw a clear [FlutterError] explaining how to provide a theme.
  ///
  /// Both lookups register this context as a dependent, so it rebuilds when the
  /// active tokens change.
  FwTokens get fw {
    final FwTokens? pure = FwTheme.maybeOf(this);
    if (pure != null) {
      return pure;
    }
    final FwTokens? interop = FwThemeExtension.maybeOf(this);
    if (interop != null) {
      return interop;
    }
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('No FwTheme or FwThemeExtension found in the widget tree.'),
      ErrorHint(
        'Wrap your app in FwTheme(...) or add FwThemeExtension to your '
        'ThemeData.extensions.',
      ),
    ]);
  }

  /// Like [fw] but returns `null` instead of throwing when no theme is present.
  ///
  /// Use this when a theme is *optional* — e.g. reading tokens in a widget that
  /// must also work with the raw palette and no `FwTheme`. (The engine uses it so
  /// the `fontSans`/`roundedMd`/`shadowMd` sugars fall back to [FwTokens.light]'s
  /// stock values rather than crash when there is no theme.)
  FwTokens? get fwOrNull => FwTheme.maybeOf(this) ?? FwThemeExtension.maybeOf(this);
}

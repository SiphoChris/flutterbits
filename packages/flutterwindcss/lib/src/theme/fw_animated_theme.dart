import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';
import 'fw_theme.dart';

/// Implicitly animates between [FwTokens] bundles (spec §12, module 10).
///
/// A Material-free [ImplicitlyAnimatedWidget]: whenever the [tokens] it is given
/// change, it tweens from the old bundle to the new one over [duration] /
/// [curve] using [FwTokens.lerp] (which interpolates colors, radii, shadows, and
/// typography together), and provides the interpolated tokens down the tree via
/// an [FwTheme]. So a host app's light↔dark switch (or any theme swap) crossfades
/// every `context.fw`-styled descendant — without riding Material's `ThemeData`
/// animation (the pure path has none).
///
/// Drop-in for [FwTheme]: replace `FwTheme(tokens: …)` with
/// `FwAnimatedTheme(tokens: …)` to make theme changes animate. Components read
/// `context.fw` exactly as before.
class FwAnimatedTheme extends ImplicitlyAnimatedWidget {
  /// Creates an animated theme provider. [duration] defaults to 200ms; pass
  /// [Duration.zero] to disable the animation (an immediate swap).
  const FwAnimatedTheme({
    required this.tokens,
    required this.child,
    super.duration = const Duration(milliseconds: 200),
    super.curve,
    super.key,
  });

  /// The target token bundle. Changing it animates from the current value.
  final FwTokens tokens;

  /// The subtree that reads the (animated) tokens via `context.fw`.
  final Widget child;

  @override
  AnimatedWidgetBaseState<FwAnimatedTheme> createState() => _FwAnimatedThemeState();
}

class _FwAnimatedThemeState extends AnimatedWidgetBaseState<FwAnimatedTheme> {
  _FwTokensTween? _tokens;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _tokens =
        visitor(_tokens, widget.tokens, (dynamic value) => _FwTokensTween(begin: value as FwTokens))
            as _FwTokensTween?;
  }

  @override
  Widget build(BuildContext context) =>
      FwTheme(tokens: _tokens!.evaluate(animation), child: widget.child);
}

/// Tweens two [FwTokens] via [FwTokens.lerp] (whole-bundle interpolation). Only
/// `begin` is constructed; the framework assigns `end` when the target changes.
class _FwTokensTween extends Tween<FwTokens> {
  _FwTokensTween({super.begin});

  @override
  FwTokens lerp(double t) => FwTokens.lerp(begin!, end!, t);
}

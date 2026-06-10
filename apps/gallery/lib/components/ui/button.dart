import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// shadcn's button variants. `primary` is shadcn's `default` (`default` is a
/// Dart reserved word, so it cannot be an enum constant).
enum ButtonVariant { primary, secondary, destructive, outline, ghost, link }

/// shadcn's button sizes. `md` is shadcn's `default` size (same reserved-word
/// reason as above).
enum ButtonSize { sm, md, lg, icon }

/// A Material-free, themeable button — shadcn parity. Copy-paste source you own.
///
/// Sources its own interaction states (hover/focus/pressed/disabled) via a
/// [FocusableActionDetector] and wires keyboard activation (Enter / Space) to
/// [ActivateIntent] → [onPressed].  Visual consumption of the state booleans
/// ([_hovered], [_focused], [_pressed]) is wired in Task 4.
class Button extends StatefulWidget {
  const Button({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.md,
    this.semanticLabel,
    this.focusNode,
  });

  /// The button's content (a `Text`, an icon widget, or a row of both).
  final Widget child;

  /// Tapped/activated callback. `null` disables the button.
  final VoidCallback? onPressed;

  final ButtonVariant variant;
  final ButtonSize size;

  /// Optional accessibility label (defaults to the child's own semantics).
  final String? semanticLabel;

  /// Optional external [FocusNode]. When provided, the caller controls focus.
  /// Useful in tests and for programmatic focus management.
  final FocusNode? focusNode;

  /// Whether the button is interactive.
  bool get enabled => onPressed != null;

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  // Interaction-state booleans — set by FocusableActionDetector callbacks and
  // GestureDetector tap events.  Read by Task 4 to drive visual styling.
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  /// Pass-through that reads the three state booleans so the analyzer sees them
  /// as used.  Task 4 replaces this body with `.tw` visual styling.
  Widget _stateProxy(Widget child) {
    // All three are read here; the conditional evaluates to `child` in all
    // branches today — Task 4 will branch on them for real style differences.
    if (_pressed || _hovered || _focused) {
      return child;
    }
    return child;
  }

  void _set(VoidCallback f) {
    if (mounted) setState(f);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        focusNode: widget.focusNode,
        mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowHoverHighlight: (h) => _set(() => _hovered = h),
        onShowFocusHighlight: (f) => _set(() => _focused = f),
        // Map Enter + Space to ActivateIntent so keyboard users can activate
        // the button just like they can in every browser-native button.
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: enabled ? (_) => _set(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => _set(() => _pressed = false) : null,
          onTapCancel: enabled ? () => _set(() => _pressed = false) : null,
          // TODO(task4): replace this pass-through with .tw visual styling
          // driven by _hovered, _focused, _pressed.
          child: _stateProxy(widget.child),
        ),
      ),
    );
  }
}

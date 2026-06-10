import 'package:flutter/widgets.dart';

/// shadcn's button variants. `primary` is shadcn's `default` (`default` is a
/// Dart reserved word, so it cannot be an enum constant).
enum ButtonVariant { primary, secondary, destructive, outline, ghost, link }

/// shadcn's button sizes. `md` is shadcn's `default` size (same reserved-word
/// reason as above).
enum ButtonSize { sm, md, lg, icon }

/// A Material-free, themeable button — shadcn parity. Copy-paste source you own.
///
/// Sources its own interaction states (hover/focus/pressed/disabled) and styles a
/// single box through `.tw` using semantic tokens only (AGENTS.md §3.1/§6).
class Button extends StatefulWidget {
  const Button({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.md,
    this.semanticLabel,
  });

  /// The button's content (a `Text`, an icon widget, or a row of both).
  final Widget child;

  /// Tapped/activated callback. `null` disables the button.
  final VoidCallback? onPressed;

  final ButtonVariant variant;
  final ButtonSize size;

  /// Optional accessibility label (defaults to the child's own semantics).
  final String? semanticLabel;

  /// Whether the button is interactive.
  bool get enabled => onPressed != null;

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed, // null when disabled → inert
        child: widget.child,
      ),
    );
  }
}

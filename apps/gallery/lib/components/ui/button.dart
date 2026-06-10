import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

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
/// [ActivateIntent] → [onPressed].  Visual styling of all variant/size/state
/// combinations is applied through a single `.tw` chain in [_ButtonState._styled].
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
  // GestureDetector tap events.  Read by [_styled] to drive visual styling.
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  /// The single styled box: resolves (variant, size, states) → one `.tw` chain.
  Widget _styled(BuildContext context) {
    final c = context.fw.colors;
    final enabled = widget.enabled;

    // Base treatment per variant (transparent fill uses the one allowed literal,
    // Color(0x00000000), per AGENTS.md §3.1).
    const transparent = Color(0x00000000);
    late Color baseBg;
    late Color baseFg;
    Color? borderColor;
    var isLink = false;
    switch (widget.variant) {
      case ButtonVariant.primary:
        baseBg = c.primary;
        baseFg = c.primaryForeground;
      case ButtonVariant.secondary:
        baseBg = c.secondary;
        baseFg = c.secondaryForeground;
      case ButtonVariant.destructive:
        baseBg = c.destructive;
        baseFg = c.destructiveForeground;
      case ButtonVariant.outline:
        baseBg = transparent;
        baseFg = c.foreground;
        borderColor = c.border;
      case ButtonVariant.ghost:
        baseBg = transparent;
        baseFg = c.foreground;
      case ButtonVariant.link:
        baseBg = transparent;
        baseFg = c.primary;
        isLink = true;
    }

    // Hover/press treatment (shadcn: filled → /90 (secondary /80); outline/ghost
    // → accent; link → underline).
    var bg = baseBg;
    var fg = baseFg;
    final interacting = enabled && (_hovered || _pressed);
    if (interacting) {
      switch (widget.variant) {
        case ButtonVariant.primary:
        case ButtonVariant.destructive:
          bg = baseBg.withValues(alpha: 0.9);
        case ButtonVariant.secondary:
          bg = baseBg.withValues(alpha: 0.8);
        case ButtonVariant.outline:
        case ButtonVariant.ghost:
          bg = c.accent;
          fg = c.accentForeground;
        case ButtonVariant.link:
          break; // underline handled below
      }
    }
    final underlineNow = isLink && enabled && (_hovered || _focused);

    // Content: shrink-wrap width, center vertically within the fixed height.
    final inner =
        widget.size == ButtonSize.icon
            ? Center(child: widget.child)
            : Center(widthFactor: 1.0, child: widget.child);

    var box =
        inner.tw.bg(bg).text(fg).textSize(FwFontSize.sm.px).weight(FwFontWeight.medium).roundedMd;

    box = switch (widget.size) {
      ButtonSize.sm => box.h(9).px(3),
      ButtonSize.md => box.h(10).px(4),
      ButtonSize.lg => box.h(11).px(8),
      ButtonSize.icon => box.size(10),
    };

    if (borderColor != null) box = box.border(1, color: borderColor);
    if (underlineNow) box = box.underline;
    if (_focused && enabled) {
      box = box.ring(2, color: c.ring, offset: 2, offsetColor: c.background);
    }
    if (!enabled) box = box.opacity(0.5);

    return box;
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
          child: _styled(context),
        ),
      ),
    );
  }
}

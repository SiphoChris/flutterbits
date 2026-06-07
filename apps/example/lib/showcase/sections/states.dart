// States section: interaction-state styling, Material-free.
//
// - hover / pressed are **auto-sourced** by FwStyled (MouseRegion + Listener);
//   no extra wiring needed on a non-interactive box.
// - focus needs a real focusable control: the engine's auto focus node is
//   non-traversable (it never steals a tab stop), so an action-bearing button
//   owns a FocusableActionDetector and injects WidgetState.focused into the
//   FwStyled `states`, lighting a ring via whenState(focused).
// - disabled / selected are component-managed states, injected the same way.
import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

import '../common.dart';

/// Demonstrates hover/pressed/focus/disabled/selected styling.
class StatesSection extends StatelessWidget {
  const StatesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    return FwColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      gap: 4,
      children: <Widget>[
        ShowcaseSection(
          title: 'Auto-sourced hover & pressed',
          description: 'On a plain box — hover with a pointer, press and hold. No detector wiring.',
          children: <Widget>[
            FwWrap(
              gap: 6,
              runGap: 6,
              children: <Widget>[
                Text('hover me').tw
                    .px(4)
                    .py(3)
                    .weight(FwFontWeight.semibold)
                    .rounded(t.radii.md)
                    .bg(t.colors.secondary)
                    .text(t.colors.secondaryForeground)
                    .hover(
                      (s) => s.bg(t.colors.primary).text(t.colors.primaryForeground).scale(1.05),
                    ),
                Text('press me').tw
                    .px(4)
                    .py(3)
                    .weight(FwFontWeight.semibold)
                    .rounded(t.radii.md)
                    .bg(t.colors.accent)
                    .text(t.colors.accentForeground)
                    .pressed((s) => s.scale(0.94).opacity(0.85)),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'Focusable button',
          description:
              'Tab to it for the focus ring; Enter/Space activates. Hover & press also styled. The right one is disabled.',
          children: <Widget>[
            FwWrap(
              gap: 6,
              runGap: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                const FocusableButton(label: 'Enabled'),
                const FocusableButton(label: 'Disabled', enabled: false),
              ],
            ),
          ],
        ),
        ShowcaseSection(
          title: 'whenState — selected (component-managed)',
          description:
              'Tap to toggle a selected WidgetState injected into the FwStyled — resolves statelessly (no live detector).',
          children: <Widget>[
            FwWrap(
              gap: 4,
              runGap: 4,
              children: <Widget>[
                for (final label in const <String>['Daily', 'Weekly', 'Monthly'])
                  SelectableChip(label: label),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// An action-bearing button (AGENTS §6 pattern): FocusableActionDetector owns
/// focus + keyboard activation; the visible ring/hover/press come from `.tw`.
class FocusableButton extends StatefulWidget {
  const FocusableButton({required this.label, this.enabled = true, super.key});

  final String label;
  final bool enabled;

  @override
  State<FocusableButton> createState() => _FocusableButtonState();
}

class _FocusableButtonState extends State<FocusableButton> {
  bool _focused = false;
  int _activations = 0;

  void _activate() {
    if (widget.enabled) {
      setState(() => _activations++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    final label = _activations == 0 ? widget.label : '${widget.label} ($_activations)';

    final injected = <WidgetState>{
      if (!widget.enabled) WidgetState.disabled,
      if (_focused) WidgetState.focused,
    };

    final styled = FwStyled(
      states: injected,
      style: const FwStyle()
          .px(4)
          .py(2)
          .weight(FwFontWeight.semibold)
          .rounded(t.radii.md)
          .bg(t.colors.primary)
          .text(t.colors.primaryForeground)
          .hover((s) => s.opacity(0.9))
          .pressed((s) => s.scale(0.96))
          .whenState(WidgetState.focused, (s) => s.border(2, color: t.colors.ring))
          .disabled((s) => s.bg(t.colors.muted).text(t.colors.mutedForeground)),
      child: Text(label),
    );

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        mouseCursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? _activate : null,
          child: styled,
        ),
      ),
    );
  }
}

/// A tappable chip that toggles a `selected` WidgetState injected into FwStyled.
class SelectableChip extends StatefulWidget {
  const SelectableChip({required this.label, super.key});

  final String label;

  @override
  State<SelectableChip> createState() => _SelectableChipState();
}

class _SelectableChipState extends State<SelectableChip> {
  bool _selected = false;

  @override
  Widget build(BuildContext context) {
    final t = context.fw;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selected = !_selected),
      child: FwStyled(
        states: <WidgetState>{if (_selected) WidgetState.selected},
        style: const FwStyle()
            .px(4)
            .py(2)
            .weight(FwFontWeight.semibold)
            .roundedFull
            .bg(t.colors.secondary)
            .text(t.colors.secondaryForeground)
            .border(1, color: t.colors.border)
            .whenState(
              WidgetState.selected,
              (s) => s.bg(t.colors.primary).text(t.colors.primaryForeground),
            ),
        child: Text(widget.label),
      ),
    );
  }
}

import 'package:flutter/widgets.dart' show WidgetState;

/// One utility spacing unit in logical pixels. Tailwind v4 base is `0.25rem`;
/// at the 16px root that is 4 logical pixels (spec §4.6). Fractional units
/// (e.g. `0.5`) are supported.
const double fwSpaceUnit = 4.0;

/// Converts a count of utility spacing [units] to logical pixels.
double fwSpace(double units) => units * fwSpaceUnit;

/// Tailwind v4 viewport breakpoints (min-width, mobile-first). Values are the
/// `40/48/64/80/96rem` defaults at a 16px root (spec §4.6).
enum FwBreakpoint {
  /// `>= 640` logical px.
  sm(640),

  /// `>= 768` logical px.
  md(768),

  /// `>= 1024` logical px.
  lg(1024),

  /// `>= 1280` logical px.
  xl(1280),

  /// `>= 1536` logical px.
  xl2(1536);

  const FwBreakpoint(this.minWidth);

  /// The inclusive minimum width at which this breakpoint is active.
  final double minWidth;
}

/// The interaction states the engine sources on its own (spec §6.5). Frozen
/// API contract — exhaustive `switch`es depend on this set (spec §12).
/// Component-managed states (e.g. selected) are fed as raw [WidgetState]s via
/// `whenState`, not added here.
enum FwState {
  /// Pointer is over the box.
  hovered,

  /// Box has input focus.
  focused,

  /// Box is being pressed/activated.
  pressed,

  /// Box is disabled; suppresses the other three (spec §6.3).
  disabled;

  /// The framework [WidgetState] this maps to.
  WidgetState get widgetState => switch (this) {
    FwState.hovered => WidgetState.hovered,
    FwState.focused => WidgetState.focused,
    FwState.pressed => WidgetState.pressed,
    FwState.disabled => WidgetState.disabled,
  };
}

/// Tailwind v4 opacity scale step (`0..100`) as a 0..1 double.
double fwOpacity(int step) => (step.clamp(0, 100)) / 100.0;

/// Tailwind v4 border-width scale (logical px): 0, 1, 2, 4, 8.
const List<double> fwBorderWidths = <double>[0, 1, 2, 4, 8];

/// Tailwind v4 z-index scale, consumed by FwStack/FwPositioned (spec §4.6).
const List<int> fwZIndices = <int>[0, 10, 20, 30, 40, 50];

/// Tailwind v4 blur scale (sigma in logical px): `xs`..`xl3` (Tailwind's
/// `blur-xs`..`blur-3xl`; `xl2`/`xl3` map to `2xl`/`3xl` since Dart
/// identifiers cannot start with a digit).
enum FwBlur {
  /// 4px.
  xs(4),

  /// 8px.
  sm(8),

  /// 12px.
  md(12),

  /// 16px.
  lg(16),

  /// 24px.
  xl(24),

  /// 40px.
  xl2(40),

  /// 64px.
  xl3(64);

  const FwBlur(this.sigma);

  /// Gaussian blur sigma in logical pixels.
  final double sigma;
}

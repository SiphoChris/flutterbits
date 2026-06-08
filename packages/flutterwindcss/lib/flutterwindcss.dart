/// flutterwindcss — Tailwind CSS v4's design system and styling vocabulary
/// for Flutter.
///
/// This barrel is the entire supported public surface. Consumers import only
/// this file; importing from `src/` is unsupported (AGENTS.md §3.6).
library;

// Exports are sorted alphabetically by path to satisfy `directives_ordering`;
// the grouping comments describe modules, not ordering. Module 1 = tokens,
// Module 2 = theme access.

// Layout widgets (Module 8) — multi-child structure the single-box `.tw` chain
// cannot express (spec §6.0/§6.6).
export 'src/layout/fw_flex.dart';
export 'src/layout/fw_grid.dart';
export 'src/layout/fw_scroll.dart';
export 'src/layout/fw_stack.dart';
export 'src/layout/fw_wrap.dart';

// Styling engine (Module 3). resolve/ResolvedStyle/the render chain are engine
// internals (consumers never call them directly), so they are not exported.
export 'src/style/fw_blend_mode.dart';
export 'src/style/fw_border_spec.dart';
// FwGroup/FwPeer are public; `fwReadRelationStates`/`FwRelationStates` are
// reactor-side resolver plumbing (consumed by FwStyled via a direct import, not
// the barrel) — hidden so they stay off the supported surface, like resolve/
// ResolvedStyle (module 14 audit).
export 'src/style/fw_group.dart' hide fwReadRelationStates, FwRelationStates;
export 'src/style/fw_layer.dart';
// FwRing + the named-scale step enums (FwRadiusStep/FwShadowStep) are the types of
// public FwStyle fields (ringSpec/radiusStep/shadowStep), so they are part of the
// supported surface — like FwBorderSpec (module 15). The FwDashedBorderPainter
// CustomPainter is pure impl (no public field references it), so it stays
// unexported. (Sorted alphabetically by path for directives_ordering.)
export 'src/style/fw_ring.dart';
export 'src/style/fw_style.dart';
export 'src/style/fw_style_ops.dart';
export 'src/style/fw_styled.dart';
export 'src/style/fw_token_steps.dart';

// Theme access (Module 2) + animated theming (Module 10).
export 'src/theme/context_fw.dart';
export 'src/theme/fw_animated_theme.dart';
export 'src/theme/fw_theme.dart';
export 'src/theme/fw_theme_extension.dart';

// Token system (Module 1).
export 'src/tokens/colors.dart';
export 'src/tokens/palette.dart';
export 'src/tokens/radii.dart';
export 'src/tokens/scales.dart';
export 'src/tokens/shadows.dart';
export 'src/tokens/tokens.dart';
export 'src/tokens/typography.dart';

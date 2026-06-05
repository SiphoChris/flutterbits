/// flutterwindcss — Tailwind CSS v4's design system and styling vocabulary
/// for Flutter.
///
/// This barrel is the entire supported public surface. Consumers import only
/// this file; importing from `src/` is unsupported (AGENTS.md §3.6).
library;

// Exports are sorted alphabetically by path to satisfy `directives_ordering`;
// the grouping comments describe modules, not ordering. Module 1 = tokens,
// Module 2 = theme access.

// Styling engine (Module 3). resolve/ResolvedStyle/the render chain are engine
// internals (consumers never call them directly), so they are not exported.
export 'src/style/fw_layer.dart';
export 'src/style/fw_style.dart';
export 'src/style/fw_style_ops.dart';
export 'src/style/fw_styled.dart';

// Theme access (Module 2).
export 'src/theme/context_fw.dart';
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

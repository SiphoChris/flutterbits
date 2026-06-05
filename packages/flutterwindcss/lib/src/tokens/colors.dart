import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show immutable;

/// The 19 shadcn semantic color tokens — the contract the theme generator
/// targets (spec §4.2, §5). Components reference these, never raw swatches.
@immutable
class FwColors {
  /// Creates a semantic color set. All fields are required; a theme defines
  /// every role.
  const FwColors({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.popoverForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.input,
    required this.ring,
  });

  /// App background.
  final Color background;

  /// Default foreground/text on [background].
  final Color foreground;

  /// Card surface.
  final Color card;

  /// Foreground on [card].
  final Color cardForeground;

  /// Popover/overlay surface.
  final Color popover;

  /// Foreground on [popover].
  final Color popoverForeground;

  /// Primary action color.
  final Color primary;

  /// Foreground on [primary].
  final Color primaryForeground;

  /// Secondary action color.
  final Color secondary;

  /// Foreground on [secondary].
  final Color secondaryForeground;

  /// Muted surface.
  final Color muted;

  /// Foreground on [muted].
  final Color mutedForeground;

  /// Accent surface.
  final Color accent;

  /// Foreground on [accent].
  final Color accentForeground;

  /// Destructive/danger color.
  final Color destructive;

  /// Foreground on [destructive].
  final Color destructiveForeground;

  /// Default border color.
  final Color border;

  /// Form input border color.
  final Color input;

  /// Focus-ring color.
  final Color ring;

  /// Returns a copy with the given fields replaced.
  FwColors copyWith({
    Color? background,
    Color? foreground,
    Color? card,
    Color? cardForeground,
    Color? popover,
    Color? popoverForeground,
    Color? primary,
    Color? primaryForeground,
    Color? secondary,
    Color? secondaryForeground,
    Color? muted,
    Color? mutedForeground,
    Color? accent,
    Color? accentForeground,
    Color? destructive,
    Color? destructiveForeground,
    Color? border,
    Color? input,
    Color? ring,
  }) {
    return FwColors(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      cardForeground: cardForeground ?? this.cardForeground,
      popover: popover ?? this.popover,
      popoverForeground: popoverForeground ?? this.popoverForeground,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      secondary: secondary ?? this.secondary,
      secondaryForeground: secondaryForeground ?? this.secondaryForeground,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      destructive: destructive ?? this.destructive,
      destructiveForeground: destructiveForeground ?? this.destructiveForeground,
      border: border ?? this.border,
      input: input ?? this.input,
      ring: ring ?? this.ring,
    );
  }

  /// Linearly interpolates every token between [a] and [b] at [t].
  static FwColors lerp(FwColors a, FwColors b, double t) {
    Color l(Color x, Color y) => Color.lerp(x, y, t)!;
    return FwColors(
      background: l(a.background, b.background),
      foreground: l(a.foreground, b.foreground),
      card: l(a.card, b.card),
      cardForeground: l(a.cardForeground, b.cardForeground),
      popover: l(a.popover, b.popover),
      popoverForeground: l(a.popoverForeground, b.popoverForeground),
      primary: l(a.primary, b.primary),
      primaryForeground: l(a.primaryForeground, b.primaryForeground),
      secondary: l(a.secondary, b.secondary),
      secondaryForeground: l(a.secondaryForeground, b.secondaryForeground),
      muted: l(a.muted, b.muted),
      mutedForeground: l(a.mutedForeground, b.mutedForeground),
      accent: l(a.accent, b.accent),
      accentForeground: l(a.accentForeground, b.accentForeground),
      destructive: l(a.destructive, b.destructive),
      destructiveForeground: l(a.destructiveForeground, b.destructiveForeground),
      border: l(a.border, b.border),
      input: l(a.input, b.input),
      ring: l(a.ring, b.ring),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FwColors &&
      other.background == background &&
      other.foreground == foreground &&
      other.card == card &&
      other.cardForeground == cardForeground &&
      other.popover == popover &&
      other.popoverForeground == popoverForeground &&
      other.primary == primary &&
      other.primaryForeground == primaryForeground &&
      other.secondary == secondary &&
      other.secondaryForeground == secondaryForeground &&
      other.muted == muted &&
      other.mutedForeground == mutedForeground &&
      other.accent == accent &&
      other.accentForeground == accentForeground &&
      other.destructive == destructive &&
      other.destructiveForeground == destructiveForeground &&
      other.border == border &&
      other.input == input &&
      other.ring == ring;

  @override
  int get hashCode => Object.hashAll(<Object>[
    background,
    foreground,
    card,
    cardForeground,
    popover,
    popoverForeground,
    primary,
    primaryForeground,
    secondary,
    secondaryForeground,
    muted,
    mutedForeground,
    accent,
    accentForeground,
    destructive,
    destructiveForeground,
    border,
    input,
    ring,
  ]);
}

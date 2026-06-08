import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show immutable;

/// The 32 shadcn semantic color tokens — the contract the theme generator
/// targets (spec §4.2, §5): the 19 core roles plus the 5 `chart-*` data-viz
/// colors and the 8 `sidebar-*` tokens. Every current shadcn/tweakcn theme
/// ships all of them, so flutterwindcss bakes the full vocabulary in (a pasted
/// theme round-trips with nothing dropped). Components reference these semantic
/// roles, never raw palette swatches. (The raw Tailwind palette lives on the
/// theme-independent [FwPalette]; these are the theme-resolved layer.)
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
    required this.chart1,
    required this.chart2,
    required this.chart3,
    required this.chart4,
    required this.chart5,
    required this.sidebar,
    required this.sidebarForeground,
    required this.sidebarPrimary,
    required this.sidebarPrimaryForeground,
    required this.sidebarAccent,
    required this.sidebarAccentForeground,
    required this.sidebarBorder,
    required this.sidebarRing,
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

  /// Categorical data-viz color 1 (shadcn `chart-1`), for charts/graphs.
  final Color chart1;

  /// Categorical data-viz color 2 (shadcn `chart-2`).
  final Color chart2;

  /// Categorical data-viz color 3 (shadcn `chart-3`).
  final Color chart3;

  /// Categorical data-viz color 4 (shadcn `chart-4`).
  final Color chart4;

  /// Categorical data-viz color 5 (shadcn `chart-5`).
  final Color chart5;

  /// Sidebar surface (shadcn `sidebar`) — the sidebar component's own sub-theme.
  final Color sidebar;

  /// Foreground on [sidebar].
  final Color sidebarForeground;

  /// Primary action color within the sidebar.
  final Color sidebarPrimary;

  /// Foreground on [sidebarPrimary].
  final Color sidebarPrimaryForeground;

  /// Accent surface within the sidebar.
  final Color sidebarAccent;

  /// Foreground on [sidebarAccent].
  final Color sidebarAccentForeground;

  /// Border color within the sidebar.
  final Color sidebarBorder;

  /// Focus-ring color within the sidebar.
  final Color sidebarRing;

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
    Color? chart1,
    Color? chart2,
    Color? chart3,
    Color? chart4,
    Color? chart5,
    Color? sidebar,
    Color? sidebarForeground,
    Color? sidebarPrimary,
    Color? sidebarPrimaryForeground,
    Color? sidebarAccent,
    Color? sidebarAccentForeground,
    Color? sidebarBorder,
    Color? sidebarRing,
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
      chart1: chart1 ?? this.chart1,
      chart2: chart2 ?? this.chart2,
      chart3: chart3 ?? this.chart3,
      chart4: chart4 ?? this.chart4,
      chart5: chart5 ?? this.chart5,
      sidebar: sidebar ?? this.sidebar,
      sidebarForeground: sidebarForeground ?? this.sidebarForeground,
      sidebarPrimary: sidebarPrimary ?? this.sidebarPrimary,
      sidebarPrimaryForeground: sidebarPrimaryForeground ?? this.sidebarPrimaryForeground,
      sidebarAccent: sidebarAccent ?? this.sidebarAccent,
      sidebarAccentForeground: sidebarAccentForeground ?? this.sidebarAccentForeground,
      sidebarBorder: sidebarBorder ?? this.sidebarBorder,
      sidebarRing: sidebarRing ?? this.sidebarRing,
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
      chart1: l(a.chart1, b.chart1),
      chart2: l(a.chart2, b.chart2),
      chart3: l(a.chart3, b.chart3),
      chart4: l(a.chart4, b.chart4),
      chart5: l(a.chart5, b.chart5),
      sidebar: l(a.sidebar, b.sidebar),
      sidebarForeground: l(a.sidebarForeground, b.sidebarForeground),
      sidebarPrimary: l(a.sidebarPrimary, b.sidebarPrimary),
      sidebarPrimaryForeground: l(a.sidebarPrimaryForeground, b.sidebarPrimaryForeground),
      sidebarAccent: l(a.sidebarAccent, b.sidebarAccent),
      sidebarAccentForeground: l(a.sidebarAccentForeground, b.sidebarAccentForeground),
      sidebarBorder: l(a.sidebarBorder, b.sidebarBorder),
      sidebarRing: l(a.sidebarRing, b.sidebarRing),
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
      other.ring == ring &&
      other.chart1 == chart1 &&
      other.chart2 == chart2 &&
      other.chart3 == chart3 &&
      other.chart4 == chart4 &&
      other.chart5 == chart5 &&
      other.sidebar == sidebar &&
      other.sidebarForeground == sidebarForeground &&
      other.sidebarPrimary == sidebarPrimary &&
      other.sidebarPrimaryForeground == sidebarPrimaryForeground &&
      other.sidebarAccent == sidebarAccent &&
      other.sidebarAccentForeground == sidebarAccentForeground &&
      other.sidebarBorder == sidebarBorder &&
      other.sidebarRing == sidebarRing;

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
    chart1,
    chart2,
    chart3,
    chart4,
    chart5,
    sidebar,
    sidebarForeground,
    sidebarPrimary,
    sidebarPrimaryForeground,
    sidebarAccent,
    sidebarAccentForeground,
    sidebarBorder,
    sidebarRing,
  ]);
}

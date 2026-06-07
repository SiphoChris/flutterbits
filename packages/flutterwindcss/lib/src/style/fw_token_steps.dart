import 'package:flutter/painting.dart' show BoxShadow;

import '../tokens/tokens.dart';

/// Named radius steps for the `rounded{Sm,Md,Lg,Xl}` sugar (module 15). A step
/// resolves against the active theme's [FwRadii] at build time, so `roundedMd`
/// tracks the theme's `--radius` exactly like `rounded(context.fw.radii.md)`.
///
/// (`none`/`full` stay as the existing context-free `roundedNone`/`roundedFull`
/// getters — they need no theme.)
enum FwRadiusStep {
  /// `context.fw.radii.sm`.
  sm,

  /// `context.fw.radii.md`.
  md,

  /// `context.fw.radii.lg`.
  lg,

  /// `context.fw.radii.xl`.
  xl;

  /// The logical-px radius for this step under [tokens].
  double resolve(FwTokens tokens) => switch (this) {
    FwRadiusStep.sm => tokens.radii.sm,
    FwRadiusStep.md => tokens.radii.md,
    FwRadiusStep.lg => tokens.radii.lg,
    FwRadiusStep.xl => tokens.radii.xl,
  };
}

/// Named shadow steps for the `shadow{Xs2,Xs,Sm,Md,Lg,Xl,2xl}` / `shadowNone`
/// sugar (module 15). Resolves against the active theme's [FwShadows] at build.
enum FwShadowStep {
  /// `shadow-none` (no shadow).
  none,

  /// `shadow-2xs`.
  xs2,

  /// `shadow-xs`.
  xs,

  /// `shadow-sm`.
  sm,

  /// `shadow-md`.
  md,

  /// `shadow-lg`.
  lg,

  /// `shadow-xl`.
  xl,

  /// `shadow-2xl`.
  xl2;

  /// The resolved [BoxShadow] list for this step under [tokens] (`none` → empty).
  List<BoxShadow> resolve(FwTokens tokens) => switch (this) {
    FwShadowStep.none => const <BoxShadow>[],
    FwShadowStep.xs2 => tokens.shadows.xs2,
    FwShadowStep.xs => tokens.shadows.xs,
    FwShadowStep.sm => tokens.shadows.sm,
    FwShadowStep.md => tokens.shadows.md,
    FwShadowStep.lg => tokens.shadows.lg,
    FwShadowStep.xl => tokens.shadows.xl,
    FwShadowStep.xl2 => tokens.shadows.xl2,
  };
}

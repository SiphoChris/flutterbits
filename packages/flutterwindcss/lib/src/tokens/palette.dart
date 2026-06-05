import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show immutable;

import 'palette.g.dart';

/// A single Tailwind hue with its 11 shades (`50`..`950`).
@immutable
class FwSwatch {
  /// Creates a swatch for [hue] (e.g. `'blue'`), reading baked values.
  const FwSwatch(this.hue);

  /// The hue name, e.g. `'blue'`.
  final String hue;

  Color _s(int shade) {
    final c = fwBakedPalette['$hue-$shade'];
    assert(c != null, 'Missing palette value $hue-$shade');
    return c ?? const Color(0xFF000000);
  }

  /// Lightest shade.
  Color get shade50 => _s(50);

  /// 100.
  Color get shade100 => _s(100);

  /// 200.
  Color get shade200 => _s(200);

  /// 300.
  Color get shade300 => _s(300);

  /// 400.
  Color get shade400 => _s(400);

  /// The base/DEFAULT shade.
  Color get shade500 => _s(500);

  /// 600.
  Color get shade600 => _s(600);

  /// 700.
  Color get shade700 => _s(700);

  /// 800.
  Color get shade800 => _s(800);

  /// 900.
  Color get shade900 => _s(900);

  /// Darkest shade.
  Color get shade950 => _s(950);

  /// Returns the swatch's [shade] (`50`,`100`,…,`950`).
  Color shade(int shade) => _s(shade);
}

/// The raw Tailwind v4 color palette. Used to build themes and for non-themeable
/// one-offs; components style with semantic tokens, not these (AGENTS.md §3.1).
abstract final class FwPalette {
  /// Pure black (`#000`).
  static const Color black = Color(0xFF000000);

  /// Pure white (`#fff`).
  static const Color white = Color(0xFFFFFFFF);

  /// Slate hue swatch.
  static const FwSwatch slate = FwSwatch('slate');

  /// Gray hue swatch.
  static const FwSwatch gray = FwSwatch('gray');

  /// Zinc hue swatch.
  static const FwSwatch zinc = FwSwatch('zinc');

  /// Neutral hue swatch.
  static const FwSwatch neutral = FwSwatch('neutral');

  /// Stone hue swatch.
  static const FwSwatch stone = FwSwatch('stone');

  /// Red hue swatch.
  static const FwSwatch red = FwSwatch('red');

  /// Orange hue swatch.
  static const FwSwatch orange = FwSwatch('orange');

  /// Amber hue swatch.
  static const FwSwatch amber = FwSwatch('amber');

  /// Yellow hue swatch.
  static const FwSwatch yellow = FwSwatch('yellow');

  /// Lime hue swatch.
  static const FwSwatch lime = FwSwatch('lime');

  /// Green hue swatch.
  static const FwSwatch green = FwSwatch('green');

  /// Emerald hue swatch.
  static const FwSwatch emerald = FwSwatch('emerald');

  /// Teal hue swatch.
  static const FwSwatch teal = FwSwatch('teal');

  /// Cyan hue swatch.
  static const FwSwatch cyan = FwSwatch('cyan');

  /// Sky hue swatch.
  static const FwSwatch sky = FwSwatch('sky');

  /// Blue hue swatch.
  static const FwSwatch blue = FwSwatch('blue');

  /// Indigo hue swatch.
  static const FwSwatch indigo = FwSwatch('indigo');

  /// Violet hue swatch.
  static const FwSwatch violet = FwSwatch('violet');

  /// Purple hue swatch.
  static const FwSwatch purple = FwSwatch('purple');

  /// Fuchsia hue swatch.
  static const FwSwatch fuchsia = FwSwatch('fuchsia');

  /// Pink hue swatch.
  static const FwSwatch pink = FwSwatch('pink');

  /// Rose hue swatch.
  static const FwSwatch rose = FwSwatch('rose');
}

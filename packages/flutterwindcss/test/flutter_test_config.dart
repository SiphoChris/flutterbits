import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Global test bootstrap, auto-discovered by `flutter test`.
///
/// Loads any bundled fixed fonts if present. The typography module (M6)
/// deliberately uses Flutter's built-in deterministic test font rather than a
/// bundled face, so text goldens are already CI-stable without committing a font
/// asset; this hook stays wired for a future real-font swap. CI (Linux) is the
/// authoritative golden platform; `--update-goldens` on a dev machine is NOT
/// authoritative (spec §10, R1).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Load fixed fonts from test/fonts/ if present. No-op until the typography
  // module adds a font; keeps the harness wired from Module 0.
  await _loadFixedFontsIfPresent();

  await testMain();
}

Future<void> _loadFixedFontsIfPresent() async {
  // Intentionally empty: M6 typography uses the deterministic built-in test
  // font; this hook remains for a future real-font swap (FontLoader here).
}

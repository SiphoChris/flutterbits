import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Global test bootstrap, auto-discovered by `flutter test`.
///
/// Loads any bundled fixed fonts (added when text first renders, in the
/// typography module) so text goldens are deterministic, and pins the golden
/// comparator. Non-text goldens (solid fills, borders) are deterministic
/// without a custom font. CI (Linux) is the authoritative golden platform;
/// `--update-goldens` on a dev machine is NOT authoritative (spec §10, R1).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Load fixed fonts from test/fonts/ if present. No-op until the typography
  // module adds a font; keeps the harness wired from Module 0.
  await _loadFixedFontsIfPresent();

  await testMain();
}

Future<void> _loadFixedFontsIfPresent() async {
  // Fonts are registered here as they are added. Intentionally empty in
  // Module 0; the typography module appends FontLoader registrations.
}

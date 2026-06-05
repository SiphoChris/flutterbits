import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

void main() {
  test('carries the given tokens', () {
    const ext = FwThemeExtension(tokens: FwTokens.light);
    expect(ext.tokens, same(FwTokens.light));
  });

  test('is a ThemeExtension keyed by its own type', () {
    const ext = FwThemeExtension(tokens: FwTokens.light);
    expect(ext, isA<ThemeExtension<FwThemeExtension>>());
    expect(ext.type, FwThemeExtension);
  });

  test('copyWith replaces the tokens', () {
    const ext = FwThemeExtension(tokens: FwTokens.light);
    final next = ext.copyWith(tokens: FwTokens.dark);
    expect(next.tokens, FwTokens.dark);
  });

  test('copyWith with no args preserves the tokens', () {
    const ext = FwThemeExtension(tokens: FwTokens.light);
    expect(ext.copyWith().tokens, FwTokens.light);
  });

  test('lerp drives FwTokens.lerp at t', () {
    const a = FwThemeExtension(tokens: FwTokens.light);
    const b = FwThemeExtension(tokens: FwTokens.dark);
    final mid = a.lerp(b, 0.5);
    expect(mid.tokens, FwTokens.lerp(FwTokens.light, FwTokens.dark, 0.5));
  });

  test('lerp at the boundaries returns the endpoint tokens', () {
    const a = FwThemeExtension(tokens: FwTokens.light);
    const b = FwThemeExtension(tokens: FwTokens.dark);
    expect(a.lerp(b, 0).tokens, FwTokens.light);
    expect(a.lerp(b, 1).tokens, FwTokens.dark);
  });

  test('lerp against null other returns this (Flutter contract)', () {
    const a = FwThemeExtension(tokens: FwTokens.light);
    expect(a.lerp(null, 0.5), same(a));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

void main() {
  testWidgets('pure path: resolves tokens from an FwTheme ancestor', (tester) async {
    late FwTokens got;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FwTheme(
          tokens: FwTokens.dark,
          child: Builder(
            builder: (context) {
              got = context.fw;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(got, FwTokens.dark);
  });

  testWidgets('interop path: resolves tokens from a MaterialApp FwThemeExtension', (tester) async {
    late FwTokens got;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[FwThemeExtension(tokens: FwTokens.light)],
        ),
        home: Builder(
          builder: (context) {
            got = context.fw;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(got, FwTokens.light);
  });

  testWidgets('the pure FwTheme takes precedence over the Material extension', (tester) async {
    late FwTokens got;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[FwThemeExtension(tokens: FwTokens.light)],
        ),
        home: FwTheme(
          tokens: FwTokens.dark,
          child: Builder(
            builder: (context) {
              got = context.fw;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(got, FwTokens.dark);
  });

  testWidgets('throws a clear, actionable error when neither provider is present', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            context.fw;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final error = tester.takeException();
    expect(error, isA<FlutterError>());
    expect(error.toString(), contains('No FwTheme or FwThemeExtension'));
  });
}

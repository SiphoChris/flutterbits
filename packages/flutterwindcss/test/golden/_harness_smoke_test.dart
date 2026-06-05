import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('golden harness renders a deterministic solid fill', (tester) async {
    await tester.pumpWidget(
      const Center(
        child: SizedBox(
          width: 64,
          height: 64,
          // Opaque fill: no anti-aliased edges, so it is byte-identical
          // across platforms — the safe smoke test for the pipeline itself.
          child: ColoredBox(color: Color(0xFF2563EB)),
        ),
      ),
    );

    await expectLater(find.byType(ColoredBox), matchesGoldenFile('goldens/harness_smoke.png'));
  });
}

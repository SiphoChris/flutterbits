// Adversarial audit probes for the flutterwindcss engine. These exercise edge
// cases beyond the existing suite: exact grid track math (fr/minmax/gap/RTL/
// distribution), token lerp identity/symmetry + mismatched shadow lists, the
// resolver's sharp edges (whole-field overlay, declaration-order breakpoint
// precedence), and input guards. Findings are recorded in the audit report; any
// test that documents a *sharp edge* (not a bug) is labelled as such.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/flutterwindcss.dart';
// resolve() is an engine-internal extension (not on the public barrel); the
// existing resolver tests import it from src/ the same way.
import 'package:flutterwindcss/src/style/resolve.dart';

void main() {
  // ------------------------------------------------------------------ grid math

  /// Pumps [grid] in a top-left W×H box with the given direction and returns the
  /// tester so callers can query child geometry relative to the grid origin.
  Future<void> pumpGrid(
    WidgetTester tester,
    Widget grid, {
    double width = 400,
    double height = 200,
    TextDirection dir = TextDirection.ltr,
  }) {
    return tester.pumpWidget(
      Directionality(
        textDirection: dir,
        child: FwTheme(
          tokens: FwTokens.light,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, height: height, child: grid),
          ),
        ),
      ),
    );
  }

  group('grid track sizing', () {
    testWidgets('fr tracks split free space exactly (1:1:2), no drift', (tester) async {
      await pumpGrid(
        tester,
        FwGrid(
          columnGap: 0,
          columns: const <FwGridTrack>[FwFr(), FwFr(), FwFr(2)],
          children: const <Widget>[
            SizedBox(key: Key('a'), height: 10),
            SizedBox(key: Key('b'), height: 10),
            SizedBox(key: Key('c'), height: 10),
          ],
        ),
        width: 400,
      );
      expect(tester.getSize(find.byKey(const Key('a'))).width, moreOrLessEquals(100));
      expect(tester.getSize(find.byKey(const Key('b'))).width, moreOrLessEquals(100));
      expect(tester.getSize(find.byKey(const Key('c'))).width, moreOrLessEquals(200));
      // Origins contiguous: a@0, b@100, c@200.
      expect(tester.getTopLeft(find.byKey(const Key('c'))).dx, moreOrLessEquals(200));
    });

    testWidgets('columnGap is utility units (×4 px) and subtracts from fr space', (tester) async {
      await pumpGrid(
        tester,
        FwGrid(
          columnGap: 2, // → 8 logical px
          columns: const <FwGridTrack>[FwFr(), FwFr()],
          children: const <Widget>[
            SizedBox(key: Key('a'), height: 10),
            SizedBox(key: Key('b'), height: 10),
          ],
        ),
        width: 408,
      );
      // (408 - 8) / 2 = 200 each; b starts at 200 + 8 = 208.
      expect(tester.getSize(find.byKey(const Key('a'))).width, moreOrLessEquals(200));
      expect(tester.getTopLeft(find.byKey(const Key('b'))).dx, moreOrLessEquals(208));
    });

    testWidgets('minmax(150, 1fr) floors track 0 under tight width', (tester) async {
      await pumpGrid(
        tester,
        FwGrid(
          columnGap: 0,
          columns: const <FwGridTrack>[FwMinMax(150, FwFr()), FwFr()],
          children: const <Widget>[
            SizedBox(key: Key('a'), height: 10),
            SizedBox(key: Key('b'), height: 10),
          ],
        ),
        width: 200,
      );
      // Equal flex would give 100/100, but track 0's floor is 150 → 150/50.
      expect(tester.getSize(find.byKey(const Key('a'))).width, moreOrLessEquals(150));
      expect(tester.getSize(find.byKey(const Key('b'))).width, moreOrLessEquals(50));
    });

    testWidgets('px track + fr track: fr absorbs the remainder', (tester) async {
      await pumpGrid(
        tester,
        FwGrid(
          columnGap: 0,
          columns: const <FwGridTrack>[FwPx(120), FwFr()],
          children: const <Widget>[
            SizedBox(key: Key('a'), height: 10),
            SizedBox(key: Key('b'), height: 10),
          ],
        ),
        width: 400,
      );
      expect(tester.getSize(find.byKey(const Key('a'))).width, moreOrLessEquals(120));
      expect(tester.getSize(find.byKey(const Key('b'))).width, moreOrLessEquals(280));
    });
  });

  group('grid distribution + RTL', () {
    testWidgets('justifyContent spaceBetween places fixed tracks at both edges', (tester) async {
      await pumpGrid(
        tester,
        FwGrid(
          columnGap: 0,
          justifyContent: FwGridDistribute.spaceBetween,
          columns: const <FwGridTrack>[FwPx(50), FwPx(50)],
          children: const <Widget>[
            SizedBox(key: Key('a'), height: 10),
            SizedBox(key: Key('b'), height: 10),
          ],
        ),
        width: 200,
      );
      // spare = 200 - 100 = 100, between = 100 → a@0, b@150.
      expect(tester.getTopLeft(find.byKey(const Key('a'))).dx, moreOrLessEquals(0));
      expect(tester.getTopLeft(find.byKey(const Key('b'))).dx, moreOrLessEquals(150));
    });

    testWidgets('RTL mirrors column placement to the right edge', (tester) async {
      await pumpGrid(
        tester,
        FwGrid(
          columnGap: 0,
          columns: const <FwGridTrack>[FwPx(50), FwPx(50)],
          children: const <Widget>[
            SizedBox(key: Key('a'), height: 10),
            SizedBox(key: Key('b'), height: 10),
          ],
        ),
        width: 200,
        dir: TextDirection.rtl,
      );
      // First (start) child sits at the right; second to its left.
      expect(tester.getTopLeft(find.byKey(const Key('a'))).dx, moreOrLessEquals(150));
      expect(tester.getTopLeft(find.byKey(const Key('b'))).dx, moreOrLessEquals(100));
    });
  });

  group('grid placement', () {
    testWidgets('columnSpan wider than the grid clamps instead of crashing', (tester) async {
      await pumpGrid(
        tester,
        FwGrid(
          columnGap: 0,
          columns: const <FwGridTrack>[FwFr(), FwFr()],
          children: const <Widget>[
            FwGridItem(columnSpan: 5, child: SizedBox(key: Key('wide'), height: 10)),
          ],
        ),
        width: 200,
      );
      expect(tester.takeException(), isNull);
      // Clamped to the full 2-column width.
      expect(tester.getSize(find.byKey(const Key('wide'))).width, moreOrLessEquals(200));
    });

    test('FwGridItem asserts against an absurd explicit line (typo backstop)', () {
      expect(() => FwGridItem(rowStart: 1000000, child: const SizedBox()), throwsAssertionError);
      expect(() => const FwGridItem(rowStart: 5, child: SizedBox()), returnsNormally);
    });

    testWidgets('auto row height comes from content (max-intrinsic)', (tester) async {
      await pumpGrid(
        tester,
        FwGrid(
          columnGap: 0,
          rowGap: 0,
          columns: const <FwGridTrack>[FwFr()],
          children: const <Widget>[SizedBox(key: Key('tall'), height: 64, width: 10)],
        ),
        width: 100,
        height: 500,
      );
      expect(tester.getSize(find.byKey(const Key('tall'))).height, moreOrLessEquals(64));
    });
  });

  // -------------------------------------------------------------------- lerp

  group('token lerp', () {
    test('FwTokens.lerp is identity at t=0 and t=1', () {
      const a = FwTokens.light;
      const b = FwTokens.dark;
      expect(FwTokens.lerp(a, b, 0), a);
      expect(FwTokens.lerp(a, b, 1), b);
    });

    test('FwColors.lerp midpoint is symmetric', () {
      final mid1 = FwColors.lerp(FwTokens.light.colors, FwTokens.dark.colors, 0.5);
      final mid2 = FwColors.lerp(FwTokens.dark.colors, FwTokens.light.colors, 0.5);
      expect(mid1, mid2);
    });

    test('FwShadows.lerp handles mismatched list lengths (none ↔ defaults)', () {
      final mid = FwShadows.lerp(FwShadows.none, FwShadows.defaults, 0.5);
      // Longest list wins the count; no crash; padded layers fade from transparent.
      expect(mid.sm.length, FwShadows.defaults.sm.length);
      // At t=0 the result is NOT structurally `none` — it is defaults-length with
      // fully transparent colours, so it renders identically to "no shadow" while
      // letting surplus layers fade in. (Visual identity, not structural identity.)
      final t0 = FwShadows.lerp(FwShadows.none, FwShadows.defaults, 0);
      expect(t0.sm.length, FwShadows.defaults.sm.length);
      expect(t0.sm.every((s) => s.color.a == 0), isTrue);
      // t=1 reproduces defaults exactly.
      expect(FwShadows.lerp(FwShadows.none, FwShadows.defaults, 1), FwShadows.defaults);
    });

    test('FwRadii.lerp interpolates every field independently', () {
      const a = FwRadii.fromBase(10);
      const b = FwRadii.fromBase(20);
      final mid = FwRadii.lerp(a, b, 0.5);
      expect(mid.base, moreOrLessEquals(15));
      expect(mid.lg, moreOrLessEquals(15));
      expect(mid.xl, moreOrLessEquals(21)); // 14 → 28, mid 21
    });
  });

  // ---------------------------------------------------------------- resolver

  group('resolver cascade & sharp edges (pinned)', () {
    const a = Color(0xFFAAAAAA);

    test('a state layer REPLACES the whole padding field (not per-edge merge)', () {
      // Base p(4) = 16 on all edges; hover sets only pt(8) = 32.
      final style = const FwStyle().p(4).hover((s) => s.pt(8));
      final hovered = style.resolve(<WidgetState>{WidgetState.hovered});
      // Sharp edge: the other edges are NOT preserved — overlay is whole-field.
      expect(hovered.padding, const EdgeInsetsDirectional.only(top: 32));
    });

    test('breakpoint precedence is by MAGNITUDE, order-independent', () {
      const sm = Color(0xFF111111);
      const md = Color(0xFFAAAAAA);
      // The larger breakpoint wins at large widths regardless of chain order.
      final mdThenSm = const FwStyle().md((s) => s.bg(md)).sm((s) => s.bg(sm));
      final smThenMd = const FwStyle().sm((s) => s.bg(sm)).md((s) => s.bg(md));
      expect(mdThenSm.resolve(const <WidgetState>{}, viewportWidth: 800).background, md);
      expect(smThenMd.resolve(const <WidgetState>{}, viewportWidth: 800).background, md);
      // Below md only sm matches.
      expect(mdThenSm.resolve(const <WidgetState>{}, viewportWidth: 700).background, sm);
    });

    test('a state layer outranks a breakpoint layer (pseudo-class specificity)', () {
      const bp = Color(0xFF111111);
      const st = Color(0xFFAAAAAA);
      // hover beats sm at >= sm, regardless of declaration order.
      final smThenHover = const FwStyle().sm((s) => s.bg(bp)).hover((s) => s.bg(st));
      final hoverThenSm = const FwStyle().hover((s) => s.bg(st)).sm((s) => s.bg(bp));
      final hovered = <WidgetState>{WidgetState.hovered};
      expect(smThenHover.resolve(hovered, viewportWidth: 800).background, st);
      expect(hoverThenSm.resolve(hovered, viewportWidth: 800).background, st);
    });

    test('container beats viewport at the same breakpoint, order-independent', () {
      const vp = Color(0xFF111111);
      const ct = Color(0xFFAAAAAA);
      // Container declared FIRST still wins (more specific context).
      final ctFirst = const FwStyle().containerMd((s) => s.bg(ct)).md((s) => s.bg(vp));
      final r = ctFirst.resolve(const <WidgetState>{}, viewportWidth: 800, containerWidth: 800);
      expect(r.background, ct);
    });

    test('disabled suppresses hover regardless of order', () {
      final style = const FwStyle().bg(const Color(0xFF111111)).hover((s) => s.bg(a));
      final r = style.resolve(<WidgetState>{WidgetState.hovered, WidgetState.disabled});
      expect(r.background, const Color(0xFF111111));
    });
  });

  // ------------------------------------------------------------------ guards

  group('input guards', () {
    test('weight throws (not asserts) on an invalid CSS step', () {
      expect(() => const FwStyle().weight(50), throwsArgumentError);
      expect(() => const FwStyle().weight(450), throwsArgumentError);
      expect(() => const FwStyle().weight(900), returnsNormally);
    });

    test('textSize / opacity / blur assert on out-of-range input', () {
      expect(() => const FwStyle().textSize(0), throwsAssertionError);
      expect(() => const FwStyle().opacity(1.5), throwsAssertionError);
      expect(() => const FwStyle().blur(-1), throwsAssertionError);
    });
  });
}

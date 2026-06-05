import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/fw_style.dart';
import 'package:flutterwindcss/src/style/resolve.dart';

const _a = Color(0xFFAAAAAA);
const _b = Color(0xFFBBBBBB);
const _c = Color(0xFFCCCCCC);

void main() {
  test('base fields pass through when no layers match', () {
    final r = const FwStyle().bg(_a).resolve(const <WidgetState>{});
    expect(r.background, _a);
  });

  test('a matching state layer overrides the base (last-wins)', () {
    final style = const FwStyle().bg(_a).hover((h) => h.bg(_b));
    expect(style.resolve(const <WidgetState>{}).background, _a);
    expect(style.resolve(<WidgetState>{WidgetState.hovered}).background, _b);
  });

  test('later matching layer wins among equals', () {
    final style = const FwStyle().hover((h) => h.bg(_a)).hover((h) => h.bg(_b));
    expect(style.resolve(<WidgetState>{WidgetState.hovered}).background, _b);
  });

  test('disabled suppresses hover/focus/pressed regardless of order', () {
    final style = const FwStyle().bg(_a).disabled((d) => d.bg(_c)).hover((h) => h.bg(_b));
    final r = style.resolve(<WidgetState>{WidgetState.disabled, WidgetState.hovered});
    expect(r.background, _c); // hover dropped; disabled applied
  });

  test('viewport layer matches only at/above its breakpoint width', () {
    final style = const FwStyle().bg(_a).md((m) => m.bg(_b));
    expect(style.resolve(const <WidgetState>{}, viewportWidth: 700).background, _a);
    expect(style.resolve(const <WidgetState>{}, viewportWidth: 768).background, _b);
  });

  test('container layer keys off containerWidth, not viewportWidth', () {
    final style = const FwStyle().bg(_a).containerMd((m) => m.bg(_b));
    // Wide viewport but narrow container => no match.
    expect(
      style.resolve(const <WidgetState>{}, viewportWidth: 9999, containerWidth: 100).background,
      _a,
    );
    // Wide container => match.
    expect(style.resolve(const <WidgetState>{}, containerWidth: 800).background, _b);
  });

  test('viewport and container layers resolve independently (two-width)', () {
    final style = const FwStyle()
        .bg(_a)
        .md((m) => m.bg(_b)) // viewport
        .containerMd((m) => m.bg(_c)); // container, declared later => wins if both
    // Viewport wide, container narrow => only md matches => _b.
    expect(
      style.resolve(const <WidgetState>{}, viewportWidth: 800, containerWidth: 100).background,
      _b,
    );
    // Both wide => container declared later wins => _c.
    expect(
      style.resolve(const <WidgetState>{}, viewportWidth: 800, containerWidth: 800).background,
      _c,
    );
    // Viewport narrow, container wide => only containerMd => _c.
    expect(
      style.resolve(const <WidgetState>{}, viewportWidth: 100, containerWidth: 800).background,
      _c,
    );
  });

  test('nested md:hover resolves jointly', () {
    final style = const FwStyle().bg(_a).md((m) => m.hover((h) => h.bg(_b)));
    // md but not hover -> base
    expect(style.resolve(const <WidgetState>{}, viewportWidth: 800).background, _a);
    // md and hover -> _b
    expect(style.resolve(<WidgetState>{WidgetState.hovered}, viewportWidth: 800).background, _b);
    // hover but not md -> base
    expect(style.resolve(<WidgetState>{WidgetState.hovered}, viewportWidth: 500).background, _a);
  });
}

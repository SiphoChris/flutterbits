import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwindcss/src/style/fw_border_spec.dart';
import 'package:flutterwindcss/src/style/fw_layer.dart';
import 'package:flutterwindcss/src/style/fw_ring.dart';
import 'package:flutterwindcss/src/style/fw_style.dart';
import 'package:flutterwindcss/src/style/fw_token_steps.dart';
import 'package:flutterwindcss/src/style/resolve.dart';
import 'package:flutterwindcss/src/tokens/tokens.dart';

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

  group('token-step resolution contract', () {
    test('resolve() asserts when a radius/shadow step is still unresolved', () {
      // A step set without its concrete value means resolveTokenSteps() never ran;
      // resolve() would silently drop it (ResolvedStyle carries no step).
      expect(
        () => const FwStyle(radiusStep: FwRadiusStep.md).resolve(const <WidgetState>{}),
        throwsAssertionError,
      );
      expect(
        () => const FwStyle(shadowStep: FwShadowStep.md).resolve(const <WidgetState>{}),
        throwsAssertionError,
      );
      // A nested layer's unresolved step is caught too.
      expect(
        () => const FwStyle()
            .hover((h) => const FwStyle(radiusStep: FwRadiusStep.lg))
            .resolve(const <WidgetState>{}),
        throwsAssertionError,
      );
    });

    test('resolveTokenSteps() first → resolve() succeeds and carries the value', () {
      final r = const FwStyle(
        radiusStep: FwRadiusStep.md,
      ).resolveTokenSteps(FwTokens.light).resolve(const <WidgetState>{});
      expect(r.borderRadius, isNotNull); // step resolved to the theme radii.md
    });
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

  test('the OTHER nesting order hover:md resolves jointly too', () {
    // hover((h) => h.md(...)) — a viewport condition nested under a state — must
    // also require BOTH (symmetry with md:hover above; the flatten recursion is
    // order-independent).
    final style = const FwStyle().bg(_a).hover((h) => h.md((m) => m.bg(_b)));
    expect(style.resolve(<WidgetState>{WidgetState.hovered}, viewportWidth: 800).background, _b);
    // hover but narrow viewport -> base (inner md unsatisfied)
    expect(style.resolve(<WidgetState>{WidgetState.hovered}, viewportWidth: 500).background, _a);
    // wide viewport but not hovered -> base (outer hover unsatisfied)
    expect(style.resolve(const <WidgetState>{}, viewportWidth: 800).background, _a);
  });

  test('container layer overrides a viewport layer at the same breakpoint+field', () {
    // Both md, same field; container is the more specific context and is applied
    // after viewport in resolution, so it wins when both match.
    final style = const FwStyle().bg(_a).md((m) => m.bg(_b)).containerMd((m) => m.bg(_c));
    expect(
      style.resolve(const <WidgetState>{}, viewportWidth: 800, containerWidth: 800).background,
      _c,
    );
  });

  // _overlay (resolve.dart) overlays ~28 fields; a regression that dropped any
  // single field from that list would otherwise pass the whole suite (the rest of
  // resolve_test exercises `background` only). This sets a distinct BASE and a
  // distinct hovered-layer OVERRIDE for every field, resolves hovered, and asserts
  // each field carried the override through — including the FwStyle→ResolvedStyle
  // name mapping (groupOpacity→opacity, contentBlur→blur, backdropBlurSigma→
  // backdropBlur).
  test('every _overlay field is carried through last-wins (no dropped field)', () {
    const baseColor = Color(0xFF111111);
    const overColor = Color(0xFF222222);
    final base = const FwStyle().copyWith(
      padding: const EdgeInsetsDirectional.all(4),
      margin: const EdgeInsetsDirectional.all(4),
      width: 10,
      height: 10,
      minWidth: 1,
      minHeight: 1,
      maxWidth: 100,
      maxHeight: 100,
      widthFactor: 0.5,
      heightFactor: 0.5,
      factorAlignment: AlignmentDirectional.centerStart,
      aspectRatio: 1,
      background: baseColor,
      gradient: const LinearGradient(colors: [baseColor, baseColor]),
      borderSpec: const FwBorderSpec(top: BorderSide(width: 1)),
      borderStyle: FwBorderStyle.solid,
      borderRadius: const BorderRadiusDirectional.all(Radius.circular(2)),
      boxShadow: const [BoxShadow(blurRadius: 1)],
      ringSpec: const FwRing(width: 1, color: baseColor),
      foreground: baseColor,
      fontSize: 10,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      lineHeight: 1.2,
      textAlign: TextAlign.start,
      textDecoration: TextDecoration.underline,
      groupOpacity: 0.5,
      contentBlur: 2,
      backdropBlurSigma: 2,
      scaleFactor: 1,
      rotation: 0.1,
      translation: const Offset(1, 1),
      clipBehavior: Clip.antiAlias,
    );
    final over = const FwStyle().copyWith(
      padding: const EdgeInsetsDirectional.all(8),
      margin: const EdgeInsetsDirectional.all(8),
      width: 20,
      height: 20,
      minWidth: 2,
      minHeight: 2,
      maxWidth: 200,
      maxHeight: 200,
      widthFactor: 0.25,
      heightFactor: 0.25,
      factorAlignment: AlignmentDirectional.bottomEnd,
      aspectRatio: 2,
      background: overColor,
      gradient: const LinearGradient(colors: [overColor, overColor]),
      borderSpec: const FwBorderSpec(top: BorderSide(width: 3)),
      borderStyle: FwBorderStyle.dashed,
      borderRadius: const BorderRadiusDirectional.all(Radius.circular(4)),
      boxShadow: const [BoxShadow(blurRadius: 9)],
      ringSpec: const FwRing(width: 3, color: overColor),
      foreground: overColor,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
      lineHeight: 1.5,
      textAlign: TextAlign.end,
      textDecoration: TextDecoration.lineThrough,
      groupOpacity: 0.25,
      contentBlur: 4,
      backdropBlurSigma: 4,
      scaleFactor: 2,
      rotation: 0.2,
      translation: const Offset(2, 2),
      clipBehavior: Clip.hardEdge,
    );
    final r = base.addLayer(const FwStateCondition(WidgetState.hovered), over).resolve(
      <WidgetState>{WidgetState.hovered},
    );

    expect(r.padding, const EdgeInsetsDirectional.all(8));
    expect(r.margin, const EdgeInsetsDirectional.all(8));
    expect(r.width, 20);
    expect(r.height, 20);
    expect(r.minWidth, 2);
    expect(r.minHeight, 2);
    expect(r.maxWidth, 200);
    expect(r.maxHeight, 200);
    expect(r.widthFactor, 0.25);
    expect(r.heightFactor, 0.25);
    expect(r.factorAlignment, AlignmentDirectional.bottomEnd);
    expect(r.aspectRatio, 2);
    expect(r.background, overColor);
    expect(r.gradient, const LinearGradient(colors: [overColor, overColor]));
    expect(r.border, const FwBorderSpec(top: BorderSide(width: 3)).resolve());
    expect(r.borderStyle, FwBorderStyle.dashed);
    expect(r.borderRadius, const BorderRadiusDirectional.all(Radius.circular(4)));
    expect(r.boxShadow, const [BoxShadow(blurRadius: 9)]);
    expect(r.ringSpec, const FwRing(width: 3, color: overColor));
    expect(r.foreground, overColor);
    expect(r.fontSize, 20);
    expect(r.fontWeight, FontWeight.w700);
    expect(r.letterSpacing, 1);
    expect(r.lineHeight, 1.5);
    expect(r.textAlign, TextAlign.end);
    expect(r.textDecoration, TextDecoration.lineThrough);
    expect(r.opacity, 0.25); // groupOpacity → opacity
    expect(r.blur, 4); // contentBlur → blur
    expect(r.backdropBlur, 4); // backdropBlurSigma → backdropBlur
    expect(r.scale, 2);
    expect(r.rotation, 0.2);
    expect(r.translate, const Offset(2, 2));
    expect(r.clipBehavior, Clip.hardEdge);
  });

  test('module 11/12/13 fields all carry through _overlay + projection', () {
    // Guards against a field added in a later module being dropped from _overlay
    // or the resolve() projection (the classic "works but one field silently
    // missing" bug). Sets each on a hover layer and asserts it projects.
    final style = const FwStyle().addLayer(
      const FwStateCondition(WidgetState.hovered),
      const FwStyle().copyWith(
        // module 11
        fontFamily: 'Inter',
        maxLineCount: 2,
        textOverflow: TextOverflow.ellipsis,
        softWrap: false,
        // module 12
        colorMatrix: <double>[1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0],
        boxFit: BoxFit.cover,
        // module 13
        fontStyle: FontStyle.italic,
        scaleXFactor: 2,
        scaleYFactor: 3,
        skewXAngle: 0.1,
        skewYAngle: 0.2,
        transformAlignment: AlignmentDirectional.topStart,
        mouseCursor: SystemMouseCursors.click,
        ignorePointer: true,
        isVisible: false,
      ),
    );
    final r = style.resolve(<WidgetState>{WidgetState.hovered});
    expect(r.fontFamily, 'Inter');
    expect(r.maxLines, 2);
    expect(r.textOverflow, TextOverflow.ellipsis);
    expect(r.softWrap, isFalse);
    expect(r.colorMatrix, isNotNull);
    expect(r.fit, BoxFit.cover);
    expect(r.fontStyle, FontStyle.italic);
    expect(r.scaleX, 2);
    expect(r.scaleY, 3);
    expect(r.skewX, 0.1);
    expect(r.skewY, 0.2);
    expect(r.transformAlignment, AlignmentDirectional.topStart);
    expect(r.mouseCursor, SystemMouseCursors.click);
    expect(r.ignorePointer, isTrue);
    expect(r.isVisible, isFalse);
  });

  test('module 17 fields carry through _overlay + projection', () {
    const shadows = <Shadow>[Shadow(color: Color(0xFF000000), blurRadius: 2)];
    const image = AssetImage('y');
    final style = const FwStyle().addLayer(
      const FwStateCondition(WidgetState.hovered),
      const FwStyle().copyWith(
        backgroundImage: const DecorationImage(image: image),
        textShadows: shadows,
        rotateXAngle: 0.5,
        rotateYAngle: 0.6,
        perspectiveDepth: 800,
        mixBlendMode: BlendMode.multiply,
      ),
    );
    final r = style.resolve(<WidgetState>{WidgetState.hovered});
    expect(r.backgroundImage, const DecorationImage(image: image));
    expect(r.textShadows, shadows);
    expect(r.rotateX, 0.5);
    expect(r.rotateY, 0.6);
    expect(r.perspective, 800);
    expect(r.blendMode, BlendMode.multiply);
  });

  test('a partial layer overrides only its fields and preserves the base rest', () {
    // hover sets background only; the base padding + fontSize must survive (the
    // copyWith null-means-keep contract that the accumulator model relies on).
    final style = const FwStyle().p(4).textSize(16).bg(_a).hover((h) => h.bg(_b));
    final r = style.resolve(<WidgetState>{WidgetState.hovered});
    expect(r.background, _b); // overridden
    expect(r.padding, const EdgeInsetsDirectional.all(16)); // preserved (p(4) = 16px)
    expect(r.fontSize, 16); // preserved
  });

  // ---- Module 14: group/peer channel resolution ----

  group('group/peer resolution', () {
    Set<WidgetState> hovered() => <WidgetState>{WidgetState.hovered};

    test('a group layer applies only when the group channel holds the state', () {
      final style = const FwStyle()
          .bg(_a)
          .addLayer(
            const FwGroupCondition(FwRelation.group, WidgetState.hovered),
            const FwStyle().bg(_b),
          );
      // No group channel → base.
      expect(style.resolve(const <WidgetState>{}).background, _a);
      // Group hovered → override.
      expect(
        style
            .resolve(
              const <WidgetState>{},
              groupStates: <String?, Set<WidgetState>>{null: hovered()},
            )
            .background,
        _b,
      );
      // Peer hovered must NOT satisfy a group layer.
      expect(
        style
            .resolve(
              const <WidgetState>{},
              peerStates: <String?, Set<WidgetState>>{null: hovered()},
            )
            .background,
        _a,
      );
    });

    test('a peer layer applies only when the peer channel holds the state', () {
      final style = const FwStyle()
          .bg(_a)
          .addLayer(
            const FwGroupCondition(FwRelation.peer, WidgetState.focused),
            const FwStyle().bg(_b),
          );
      expect(
        style
            .resolve(
              const <WidgetState>{},
              peerStates: <String?, Set<WidgetState>>{
                null: <WidgetState>{WidgetState.focused},
              },
            )
            .background,
        _b,
      );
      expect(
        style
            .resolve(
              const <WidgetState>{},
              groupStates: <String?, Set<WidgetState>>{
                null: <WidgetState>{WidgetState.focused},
              },
            )
            .background,
        _a,
      );
    });

    test('a named group layer reads its own channel key', () {
      final style = const FwStyle()
          .bg(_a)
          .addLayer(
            const FwGroupCondition(FwRelation.group, WidgetState.hovered, name: 'sidebar'),
            const FwStyle().bg(_b),
          );
      // Default channel hovered but not 'sidebar' → base.
      expect(
        style
            .resolve(
              const <WidgetState>{},
              groupStates: <String?, Set<WidgetState>>{null: hovered()},
            )
            .background,
        _a,
      );
      // 'sidebar' hovered → override.
      expect(
        style
            .resolve(
              const <WidgetState>{},
              groupStates: <String?, Set<WidgetState>>{'sidebar': hovered()},
            )
            .background,
        _b,
      );
    });

    test('disabled suppresses group-hover within the group channel', () {
      final style = const FwStyle()
          .bg(_a)
          .addLayer(
            const FwGroupCondition(FwRelation.group, WidgetState.hovered),
            const FwStyle().bg(_b),
          )
          .addLayer(
            const FwGroupCondition(FwRelation.group, WidgetState.disabled),
            const FwStyle().bg(_c),
          );
      final r = style.resolve(
        const <WidgetState>{},
        groupStates: <String?, Set<WidgetState>>{
          null: <WidgetState>{WidgetState.disabled, WidgetState.hovered},
        },
      );
      expect(r.background, _c); // group-hover dropped; group-disabled applied
    });

    test('a group-hover layer outranks a breakpoint layer (state tier)', () {
      final style = const FwStyle()
          .bg(_a)
          .md((m) => m.bg(_b)) // tier 0
          .addLayer(
            const FwGroupCondition(FwRelation.group, WidgetState.hovered),
            const FwStyle().bg(_c),
          );
      final r = style.resolve(
        const <WidgetState>{},
        viewportWidth: 800,
        groupStates: <String?, Set<WidgetState>>{null: hovered()},
      );
      expect(r.background, _c); // group state beats md, despite md declared first
    });

    test('the box own-states do not leak into the group channel', () {
      // A group-hover layer must NOT fire just because the box itself is hovered.
      final style = const FwStyle()
          .bg(_a)
          .addLayer(
            const FwGroupCondition(FwRelation.group, WidgetState.hovered),
            const FwStyle().bg(_b),
          );
      expect(style.resolve(<WidgetState>{WidgetState.hovered}).background, _a);
    });
  });
}

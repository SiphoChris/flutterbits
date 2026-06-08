import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Composites its [child] against the content already painted behind it using a
/// [blendMode] — the Flutter mapping of CSS `mix-blend-mode` (module 17). There is
/// no built-in widget for this, so it is a thin `RenderProxyBox` that wraps the
/// child's paint in a `saveLayer` carrying the blend mode (the layer composites
/// against the backdrop on restore).
///
/// Set via the `blendMode()` `.tw` setter. Best on leaf-ish visual content
/// (a fill, image, or text); like CSS it blends against whatever is *behind* it.
class FwBlendMode extends SingleChildRenderObjectWidget {
  /// Creates a blend-mode wrapper.
  const FwBlendMode({required this.blendMode, super.child, super.key});

  /// How the child composites against the backdrop.
  final BlendMode blendMode;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderBlendMode(blendMode);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderBlendMode).blendMode = blendMode;
  }
}

class _RenderBlendMode extends RenderProxyBox {
  _RenderBlendMode(this._blendMode);

  BlendMode _blendMode;
  BlendMode get blendMode => _blendMode;
  set blendMode(BlendMode value) {
    if (value == _blendMode) return;
    _blendMode = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderBox? child = this.child;
    if (child == null) return;
    context.canvas.saveLayer(offset & size, Paint()..blendMode = _blendMode);
    context.paintChild(child, offset);
    context.canvas.restore();
  }
}

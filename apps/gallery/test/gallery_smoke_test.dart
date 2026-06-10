import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbits_gallery/main.dart';

void main() {
  testWidgets('gallery builds and renders without exceptions', (t) async {
    await t.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(const GalleryApp());
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('primary'), findsWidgets);
  });
}

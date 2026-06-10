import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';

void main() => runApp(const GalleryApp());

/// TEMPORARY bootstrap root for the gallery. The structure plan REPLACES this
/// raw `WidgetsApp` with the flutterbits `Layout` (the gallery's intended root,
/// which it then demos). Do not entrench this — it is throwaway dev scaffolding.
class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FwTheme(
      tokens: FwTokens.light,
      child: WidgetsApp(
        title: 'flutterbits gallery',
        color: const Color(0xFF2563EB),
        debugShowCheckedModeBanner: false,
        pageRouteBuilder: <T extends Object?>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          );
        },
        home: Builder(
          builder:
              (context) => ColoredBox(
                color: context.fw.colors.background,
                child: const Center(child: Text('flutterbits gallery')),
              ),
        ),
      ),
    );
  }
}

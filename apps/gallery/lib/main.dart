import 'package:flutter/widgets.dart';
import 'package:flutterwindcss/flutterwindcss.dart';
import 'components/ui/button.dart';

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
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final v in ButtonVariant.values)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                for (final s in ButtonSize.values)
                                  Button(
                                    variant: v,
                                    size: s,
                                    onPressed: () {},
                                    child: s == ButtonSize.icon ? const Text('+') : Text(v.name),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}

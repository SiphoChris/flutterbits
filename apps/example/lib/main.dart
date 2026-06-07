// flutterwindcss engine showcase — example app #1.
//
// A Material-free Flutter app on the **pure path** (a bare `WidgetsApp` wrapped
// in `FwAnimatedTheme`) that demonstrates *every* capability of the
// flutterwindcss engine: tokens, the full palette + scales, every `.tw` setter
// family (spacing, sizing, color/border/radius, typography, effects,
// transforms), interaction states, responsive + container variants, and all
// the layout widgets including the real CSS-grid.
//
// It imports only `package:flutter/widgets.dart` (no Material) and the
// flutterwindcss barrel, so it doubles as proof the engine stands alone.
import 'package:flutter/widgets.dart';

import 'showcase/showcase_app.dart';

void main() => runApp(const ShowcaseApp());

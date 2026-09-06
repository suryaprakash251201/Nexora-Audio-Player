import 'package:flutter/widgets.dart';

/// Non-IO platforms (web): file:// artwork can't occur — show the fallback.
Widget buildFileArtworkImage({
  required String url,
  required double? width,
  required double? height,
  required BoxFit fit,
  required Widget errorWidget,
}) =>
    errorWidget;

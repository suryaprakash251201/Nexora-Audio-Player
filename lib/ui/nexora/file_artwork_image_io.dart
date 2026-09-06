import 'dart:io';

import 'package:flutter/widgets.dart';

/// Renders a file:// artwork URI via [Image.file] with a graceful
/// fallback to [errorWidget] (missing file, decode failure, …).
Widget buildFileArtworkImage({
  required String url,
  required double? width,
  required double? height,
  required BoxFit fit,
  required Widget errorWidget,
}) {
  late final File file;
  try {
    file = File.fromUri(Uri.parse(url));
  } catch (_) {
    return errorWidget;
  }
  return Image.file(
    file,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) => errorWidget,
  );
}

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Ensures a TTF is loaded into the engine so dart:ui ParagraphBuilder can use it.
class ArabicFontLoader {
  static final Map<String, Future<void>> _loading = {};

  /// family must match the 'family' in pubspec fonts section.
  /// assetPath is the .ttf path listed under assets.
  static Future<void> ensureLoaded({
    required String family,
    required String assetPath,
  }) {
    return _loading.putIfAbsent(family, () async {
      try {
        final loader = FontLoader(family);
        loader.addFont(rootBundle.load(assetPath));
        await loader.load();
        if (kDebugMode) {
          // ignore: avoid_print
          print('ArabicFontLoader: loaded font family=$family from $assetPath');
        }
      } catch (e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('ArabicFontLoader: failed to load $family: $e');
        }
      }
    });
  }
}

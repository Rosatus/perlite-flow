import 'package:flutter/services.dart';

/// Thin wrapper over the `io.material.plugins/dynamic_color` method
/// channel provided by `package:dynamic_color`'s Android host.
///
/// We bypass `DynamicColorBuilder` because its `builder` callback is
/// typed against `package:material_ui`'s parallel `ColorScheme`, not
/// `package:flutter/material.dart`'s — which makes the public API
/// unusable for theming a real app. Calling the channel directly lets
/// us re-seed through Flutter's own `ColorScheme.fromSeed`.
class DynamicColorService {
  static const _channel = OptionalMethodChannel(
    'io.material.plugins/dynamic_color',
  );

  /// Returns the Material You seed colour on Android 12+, or `null`
  /// on older devices / when dynamic colour is unavailable.
  ///
  /// The plugin returns a flat `IntArray` of 65 ARGB ints — five
  /// tonal palettes × 13 tones, ordered `primary, secondary,
  /// tertiary, neutral1, neutral2`. Within each palette the index
  /// maps to resource suffixes `1000,900,800,700,600,500,400,300,
  /// 200,100,50,10,0`. M3 names those suffixes by tone×10, so index
  /// `6` (`system_accent1_400`) is tone 40 — the canonical seed tone
  /// `ColorScheme.fromSeed` uses for `primary`.
  static Future<Color?> seedFromCorePalette() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getCorePalette',
      );
      if (result == null || result.length < 13) return null;
      final argb = result[6]; // primary tonal palette, tone 40
      if (argb is! int) return null;
      return Color(argb);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

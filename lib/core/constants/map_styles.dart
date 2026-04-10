import 'package:flutter/services.dart' show rootBundle;

abstract final class MapStyles {
  static Future<String> loadLight() {
    return rootBundle.loadString('assets/map_style.json');
  }
}

import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

/// Reproducible geometric app mark; no external assets or fonts.
void main() {
  final files = <String, int>{
    'web/icons/Icon-192.png': 192,
    'web/icons/Icon-512.png': 512,
    'web/icons/Icon-maskable-192.png': 192,
    'web/icons/Icon-maskable-512.png': 512,
    'web/favicon.png': 32,
    for (final entry in {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    }.entries)
      'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png':
          entry.value,
  };
  for (final entry in files.entries) {
    final size = entry.value;
    final image = img.Image(width: size, height: size);
    img.fill(image, color: img.ColorRgb8(250, 248, 242));
    final points = <img.Point>[];
    for (var i = 0; i < 120; i++) {
      final t = i * math.pi * 2 / 120;
      final x = 16 * math.pow(math.sin(t), 3);
      final y =
          13 * math.cos(t) -
          5 * math.cos(2 * t) -
          2 * math.cos(3 * t) -
          math.cos(4 * t);
      points.add(
        img.Point(size * .5 + x * size / 48, size * .47 - y * size / 48),
      );
    }
    img.fillPolygon(image, vertices: points, color: img.ColorRgb8(82, 104, 77));
    File(entry.key).writeAsBytesSync(img.encodePng(image));
  }
}

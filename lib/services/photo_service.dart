import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class PhotoService {
  static Future<Uint8List?> pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (file == null) return null;
    if (await file.length() > 20 * 1024 * 1024) {
      throw const FormatException('Wybierz zdjęcie mniejsze niż 20 MB.');
    }
    return compute(compressPhoto, await file.readAsBytes());
  }
}

// Encoding a fresh JPEG drops EXIF/location metadata and bounds storage usage.
Uint8List compressPhoto(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException(
      'Nie mogę odczytać zdjęcia. Wybierz JPG lub PNG.',
    );
  }
  var resized = img.bakeOrientation(decoded);
  if (resized.width > 1280 || resized.height > 1280) {
    resized = img.copyResize(
      resized,
      width: resized.width >= resized.height ? 1280 : null,
      height: resized.height > resized.width ? 1280 : null,
    );
  }
  final clean = img.Image(width: resized.width, height: resized.height);
  img.compositeImage(clean, resized);
  final encoded = Uint8List.fromList(img.encodeJpg(clean, quality: 78));
  if (encoded.length > 2 * 1024 * 1024) {
    throw const FormatException(
      'Zdjęcie jest zbyt duże. Wybierz mniejszy plik.',
    );
  }
  return encoded;
}

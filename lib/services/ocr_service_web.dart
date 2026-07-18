import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

@JS('recognizeRecipeImage')
external JSPromise<JSString> _recognizeRecipeImage(
  JSString imageDataUrl,
);

class OcrService {
  static bool get isSupported => true;

  static Future<String> recogniseText({
    required Uint8List imageBytes,
    required String imagePath,
  }) async {
    if (imageBytes.isEmpty) {
      throw ArgumentError(
        'The selected image is empty.',
      );
    }

    final String mimeType = _detectMimeType(
      imageBytes,
      imagePath,
    );

    final String imageDataUrl =
        'data:$mimeType;base64,${base64Encode(imageBytes)}';

    final JSString result = await _recognizeRecipeImage(
      imageDataUrl.toJS,
    ).toDart;

    return result.toDart.trim();
  }

  static String _detectMimeType(
    Uint8List bytes,
    String imagePath,
  ) {
    final String lowerPath = imagePath.toLowerCase();

    if (lowerPath.endsWith('.png') ||
        (bytes.length >= 8 &&
            bytes[0] == 0x89 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x4E &&
            bytes[3] == 0x47)) {
      return 'image/png';
    }

    if (lowerPath.endsWith('.webp') ||
        (bytes.length >= 12 &&
            bytes[0] == 0x52 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46 &&
            bytes[3] == 0x46 &&
            bytes[8] == 0x57 &&
            bytes[9] == 0x45 &&
            bytes[10] == 0x42 &&
            bytes[11] == 0x50)) {
      return 'image/webp';
    }

    return 'image/jpeg';
  }
}